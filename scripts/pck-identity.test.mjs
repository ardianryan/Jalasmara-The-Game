import test from "node:test";
import assert from "node:assert/strict";
import { webcrypto } from "node:crypto";
import { createPckFetch } from "./pck-stream.mjs";
import { pckManifest, PCK_PART_BYTES } from "./pck-manifest.mjs";

const source = Buffer.alloc(PCK_PART_BYTES + 23, 41);
const original = pckManifest(source);
const baseUrl = "https://game.test/game/index.html";
function fixture(extra = {}) {
  const target = extra.target ?? {};
  const manifest = structuredClone(original);
  const fetch = createPckFetch(
    manifest,
    extra.fetch ??
      ((url) => {
        const index = Number(new URL(url).pathname.split("/").at(-1));
        const bytes = source.subarray(
          index * PCK_PART_BYTES,
          (index + 1) * PCK_PART_BYTES,
        );
        return new Response(bytes, {
          headers: {
            "Content-Length": String(bytes.length),
            "X-Pck-Offset": String(index * PCK_PART_BYTES),
            "X-Pck-Length": String(source.length),
          },
        });
      }),
    { baseUrl, subtle: webcrypto.subtle, identityTarget: target },
  );
  return { target, manifest, fetch };
}

test("identity is absent until the final verified part reaches the consumer", async () => {
  const { target, fetch, manifest } = fixture();
  assert.equal(target.jalasmaraPckIdentity, null);
  const response = await fetch("index.pck");
  const reader = response.body.getReader();
  await reader.read();
  assert.equal(target.jalasmaraPckIdentity, null);
  await reader.read();
  assert.deepEqual(target.jalasmaraPckIdentity, {
    schemaVersion: 1,
    pckSha256: manifest.sha256,
    pckBytes: source.length,
    partCount: 2,
    verification: "all-parts-verified-manifest",
  });
  assert(Object.isFrozen(target.jalasmaraPckIdentity));
  assert.equal((await reader.read()).done, true);
  assert.throws(() => {
    target.jalasmaraPckIdentity = {};
  }, TypeError);
});

test("cancelled partial reads and bad hashes never publish a loader pin", async () => {
  const partial = fixture();
  const reader = (await partial.fetch("index.pck")).body.getReader();
  await reader.read();
  await reader.cancel();
  assert.equal(partial.target.jalasmaraPckIdentity, null);
  const broken = fixture({ fetch: () => new Response("wrong") });
  await assert.rejects((await broken.fetch("index.pck")).arrayBuffer());
  assert.equal(broken.target.jalasmaraPckIdentity, null);
});

test("a newer partial attempt cannot acquire a stale completion pin from an older stream", async () => {
  const { target, fetch } = fixture();
  const older = await fetch("index.pck");
  const newer = await fetch("index.pck");
  await older.arrayBuffer();
  assert.equal(target.jalasmaraPckIdentity, null);
  await newer.body.cancel();
  assert.equal(target.jalasmaraPckIdentity, null);
});

test("manifest mutation after adapter creation cannot rewrite delivered bytes or provenance", async () => {
  const { target, fetch, manifest } = fixture();
  manifest.sha256 = "f".repeat(64);
  manifest.hashes.fill("0".repeat(64));
  const bytes = Buffer.from(await (await fetch("index.pck")).arrayBuffer());
  assert.deepEqual(bytes, source);
  assert.equal(target.jalasmaraPckIdentity.pckSha256, original.sha256);
});

test("nonextensible targets and optional metadata traps do not break valid PCK delivery", async () => {
  const throwing = new Proxy(
    {},
    {
      defineProperty() {
        throw new Error("blocked metadata");
      },
    },
  );
  for (const target of [Object.preventExtensions({}), throwing]) {
    const { fetch } = fixture({ target });
    assert.deepEqual(
      Buffer.from(await (await fetch("index.pck")).arrayBuffer()),
      source,
    );
    assert.equal(target.jalasmaraPckIdentity, undefined);
  }
});
