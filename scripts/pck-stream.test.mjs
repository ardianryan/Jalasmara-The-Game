import test from "node:test";
import assert from "node:assert/strict";
import { webcrypto } from "node:crypto";
import { readFileSync } from "node:fs";
import vm from "node:vm";
import { pckManifest, PCK_PART_BYTES } from "./pck-manifest.mjs";
import { createPckFetch, withSegmentedPck } from "./pck-stream.mjs";
import { withTrackedStreamErrors } from "./godot-preloader-stream.mjs";
const source = Buffer.alloc(PCK_PART_BYTES * 5 + 37);
for (let index = 0; index < source.length; index++) source[index] = index % 251;
const manifest = pckManifest(source),
  baseUrl = "https://game.test/game/index.html";
const fixture = readFileSync(
  new URL("./fixtures/godot-4.7.2-preloader.js", import.meta.url),
  "utf8",
);
function endpoint(
  index,
  bytes = source.subarray(
    index * PCK_PART_BYTES,
    Math.min(source.length, (index + 1) * PCK_PART_BYTES),
  ),
  headers = {},
) {
  return new Response(bytes, {
    headers: {
      "Content-Length": String(bytes.length),
      "X-Pck-Offset": String(index * PCK_PART_BYTES),
      "X-Pck-Length": String(source.length),
      ...headers,
    },
  });
}
function adapter(fetch, extra = {}) {
  return createPckFetch(manifest, fetch, {
    baseUrl,
    subtle: webcrypto.subtle,
    ...extra,
  });
}
const partIndex = (url) => Number(new URL(url).pathname.split("/").at(-1));
const sameBytes = (bytes) => assert.deepEqual(Buffer.from(bytes), source);
const delay = (ms) => new Promise((resolve) => setTimeout(resolve, ms));
test("manifest pins complete bytes and each bounded part including the short tail", () => {
  assert.equal(manifest.hashes.length, 6);
  assert.equal(manifest.bytes, source.length);
  assert.throws(() => pckManifest(Buffer.alloc(0)));
  assert.throws(() => adapter(() => {}, { baseUrl: "invalid" }));
  assert.throws(() =>
    createPckFetch({ ...manifest, hashes: [] }, () => {}, { baseUrl }),
  );
});
test("out-of-order parallel responses are verified and yielded in original PCK order", async () => {
  const calls = [];
  const fetch = adapter(async (url) => {
    const index = partIndex(url);
    calls.push(index);
    await delay(index === 0 ? 10 : 1);
    return endpoint(index);
  });
  const response = await fetch("index.pck?cache=42");
  assert.equal(response.headers.get("Content-Length"), String(source.length));
  sameBytes(await response.arrayBuffer());
  assert.deepEqual([...calls].sort(), [0, 1, 2, 3, 4, 5]);
});
test("WASM and other assets keep the original fetch path and arguments", async () => {
  const calls = [];
  const original = () => new Response("wasm");
  const fetch = adapter((file) => {
    calls.push(file);
    return original();
  });
  assert.equal(await (await fetch("index.wasm")).text(), "wasm");
  assert.equal(
    await (await fetch("https://other.test/game/index.pck")).text(),
    "wasm",
  );
  assert.deepEqual(calls, ["index.wasm", "https://other.test/game/index.pck"]);
});
test("backpressure starts at most four requests and cancellation aborts all pending bodies", async () => {
  const calls = [],
    signals = [];
  const fetch = adapter((url, { signal }) => {
    calls.push(url);
    signals.push(signal);
    return new Promise((resolve, reject) => {
      signal.addEventListener("abort", () => reject(new Error("cancelled")), {
        once: true,
      });
    });
  });
  const response = await fetch("index.pck");
  await delay(5);
  assert.equal(calls.length, 4);
  await response.body.cancel();
  assert(signals.every((signal) => signal.aborted));
  await delay(5);
  assert.equal(calls.length, 4);
});
for (const kind of ["checksum", "short", "offset", "length", "status"])
  test(
    "rejects " + kind + " without delivering invalid part bytes",
    async () => {
      const fetch = adapter(async (url) => {
        const index = partIndex(url);
        if (index !== 0) return endpoint(index);
        if (kind === "checksum") {
          const bytes = Buffer.from(source.subarray(0, PCK_PART_BYTES));
          bytes[0] ^= 1;
          return endpoint(index, bytes);
        }
        if (kind === "short")
          return endpoint(index, source.subarray(0, 10), {
            "Content-Length": String(PCK_PART_BYTES),
          });
        if (kind === "offset")
          return endpoint(index, undefined, { "X-Pck-Offset": "1048576" });
        if (kind === "length")
          return endpoint(index, undefined, { "X-Pck-Length": "1" });
        return new Response("gone", { status: 404 });
      });
      await assert.rejects((await fetch("index.pck")).arrayBuffer());
    },
  );
test("stalled body has a bounded timeout and releases every speculative request", async () => {
  const signals = [];
  const fetch = adapter(
    (_url, { signal }) => {
      signals.push(signal);
      return new Promise((_resolve, reject) =>
        signal.addEventListener("abort", () => reject(new Error("timed out")), {
          once: true,
        }),
      );
    },
    { partTimeoutMs: 15 },
  );
  await assert.rejects((await fetch("index.pck")).arrayBuffer(), /timed out/);
  assert(signals.every((signal) => signal.aborted));
});
test("secure-context verification is required only for segmented PCK", async () => {
  const fetch = adapter(() => new Response("wasm"), { subtle: null });
  await assert.rejects(fetch("index.pck"), /HTTPS/);
  assert.equal(await (await fetch("index.wasm")).text(), "wasm");
});
test("pinned Godot loader consumes verified chunks and reports actual decoded bytes", async () => {
  const progress = [];
  const context = {
    fetch: async (url) => endpoint(partIndex(url)),
    Response,
    ReadableStream,
    ArrayBuffer,
    Uint8Array,
    Map,
    URL,
    AbortController,
    setTimeout,
    clearTimeout,
    requestAnimationFrame: () => {},
    location: { href: baseUrl },
    crypto: webcrypto,
  };
  context.globalThis = context;
  const code = withSegmentedPck(withTrackedStreamErrors(fixture), manifest);
  assert.equal(
    withTrackedStreamErrors(code),
    code,
    "The actual exported loader remains verifiable after its reviewed PCK substitution",
  );
  assert.throws(
    () =>
      withTrackedStreamErrors(
        code.replace("DOWNLOAD_ATTEMPTS_MAX = 4", "DOWNLOAD_ATTEMPTS_MAX = 5"),
      ),
    /implementation changed/,
  );
  const Loader = vm.runInNewContext(code + "\nPreloader;", context),
    loader = new Loader();
  loader.setProgressFunc((loaded, total) => progress.push([loaded, total]));
  sameBytes(await loader.loadPromise("index.pck", source.length));
  loader.animateProgress();
  assert.deepEqual(progress.at(-1), [source.length, source.length]);
  assert.equal(context.jalasmaraPckIdentity.pckSha256, manifest.sha256);
  assert.equal(context.jalasmaraPckIdentity.pckBytes, source.length);
  assert.equal(
    context.jalasmaraPckIdentity.verification,
    "all-parts-verified-manifest",
  );
  assert.throws(() => withSegmentedPck(code, manifest), /pattern changed/);
  assert.throws(
    () => withSegmentedPck("changed upstream", manifest),
    /pattern changed/,
  );
});
