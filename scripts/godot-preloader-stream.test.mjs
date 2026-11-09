import test from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import vm from "node:vm";
import { spawnSync } from "node:child_process";
import { withTrackedStreamErrors } from "./godot-preloader-stream.mjs";

const fixture = readFileSync(
  new URL("./fixtures/godot-4.7.2-preloader.js", import.meta.url),
  "utf8",
);

function loadPreloader(fetch) {
  const retryDelays = [];
  const context = {
    fetch,
    Response,
    ReadableStream,
    ArrayBuffer,
    Uint8Array,
    requestAnimationFrame: () => {},
    setTimeout: (callback, delay) => {
      retryDelays.push(delay);
      queueMicrotask(callback);
      return 0;
    },
  };
  const Preloader = vm.runInNewContext(
    `${withTrackedStreamErrors(fixture)}\nPreloader;`,
    context,
  );
  return { loader: new Preloader(), retryDelays };
}

function bodyResponse({ fail = false, marker = 1 } = {}) {
  let pulls = 0;
  return new Response(
    new ReadableStream({
      pull(controller) {
        if (pulls++ === 0) {
          controller.enqueue(new Uint8Array([marker, marker, marker, marker]));
        } else if (fail) {
          controller.error(new TypeError("injected response-body read failure"));
        } else {
          controller.close();
        }
      },
    }),
    {
      headers: {
        "content-type": "application/wasm",
        // A browser fetch exposes decoded chunks despite compressed wire headers.
        "content-encoding": "gzip",
        "content-length": "2",
      },
    },
  );
}

function withinDeadline(promise) {
  let timeout;
  const limit = new Promise((_, reject) => {
    timeout = setTimeout(() => reject(new Error("loader remained pending")), 500);
  });
  return Promise.race([promise, limit]).finally(() => clearTimeout(timeout));
}

test("the exact unpatched upstream fixture strands a failed body", () => {
  const child = spawnSync(
    process.execPath,
    [
      "--input-type=module",
      "-e",
      `import { readFileSync } from 'node:fs';
       import vm from 'node:vm';
       const source=readFileSync(process.argv[1],'utf8');
       const unhandled=[];
       process.on('unhandledRejection', error=>unhandled.push(error.message));
       const bodyResponse=${bodyResponse.toString()};
       let requests=0;
       const Preloader=vm.runInNewContext(source+'; Preloader;',{
         fetch:async()=>{requests++;return bodyResponse({fail:true});},
         Response,ReadableStream,ArrayBuffer,Uint8Array,setTimeout
       });
       const outcome=await Promise.race([
         new Preloader().loadPromise('index.pck',8).then(()=> 'resolved',()=> 'rejected'),
         new Promise(resolve=>setTimeout(()=>resolve('pending'),50))
       ]);
       console.log(JSON.stringify({outcome,requests,unhandled}));`,
      new URL("./fixtures/godot-4.7.2-preloader.js", import.meta.url).pathname,
    ],
    { encoding: "utf8", timeout: 5000 },
  );
  assert.equal(child.status, 0, child.stderr || child.error?.message);
  assert.deepEqual(JSON.parse(child.stdout), {
    outcome: "pending",
    requests: 1,
    unhandled: ["injected response-body read failure"],
  });
});

test("successful decoded stream keeps bytes, progress and raw response headers", async () => {
  let requests = 0;
  const { loader, retryDelays } = loadPreloader(async () => {
    requests++;
    return bodyResponse();
  });
  const progress = [];
  loader.setProgressFunc((loaded, total) => progress.push([loaded, total]));
  const result = await withinDeadline(loader.loadPromise("index.pck", 4));
  loader.animateProgress();
  assert.deepEqual([...new Uint8Array(result)], [1, 1, 1, 1]);
  assert.deepEqual(progress, [[4, 4]]);
  assert.equal(requests, 1);
  assert.deepEqual(retryDelays, []);

  const raw = await withinDeadline(loader.loadPromise("index.wasm", 4, true));
  assert.equal(raw.headers.get("content-type"), "application/wasm");
  assert.equal(raw.headers.get("content-encoding"), "gzip");
  assert.equal((await raw.arrayBuffer()).byteLength, 4);
});

test("a partial-body failure retries then resolves only the successful attempt", async () => {
  let requests = 0;
  const { loader, retryDelays } = loadPreloader(async () => {
    requests++;
    return bodyResponse({ fail: requests === 1, marker: requests });
  });
  const result = await withinDeadline(loader.loadPromise("index.pck", 4));
  assert.equal(requests, 2);
  assert.deepEqual(retryDelays, [1000]);
  assert.deepEqual([...new Uint8Array(result)], [2, 2, 2, 2]);
});

test("persistent partial-body errors reject after the existing four-attempt budget", async () => {
  let requests = 0;
  const { loader, retryDelays } = loadPreloader(async () => {
    requests++;
    return bodyResponse({ fail: true });
  });
  await assert.rejects(
    withinDeadline(loader.loadPromise("index.pck", 4)),
    /injected response-body read failure/,
  );
  assert.equal(requests, 4);
  assert.deepEqual(retryDelays, [1000, 1000, 1000]);
});

test("a raw WASM response errors its consumer instead of hanging its body", async () => {
  let requests = 0;
  const { loader } = loadPreloader(async () => {
    requests++;
    return bodyResponse({ fail: true });
  });
  const raw = await withinDeadline(loader.loadPromise("index.wasm", 4, true));
  await assert.rejects(
    withinDeadline(raw.arrayBuffer()),
    /injected response-body read failure/,
  );
  assert.equal(requests, 1, "raw headers resolve before body consumption; no invented retry");
});

test("patching is deterministic/idempotent and unknown upstream code fails closed", () => {
  const patched = withTrackedStreamErrors(fixture);
  assert.equal(withTrackedStreamErrors(patched), patched);
  assert.equal(withTrackedStreamErrors(fixture), patched);
  assert.throws(
    () => withTrackedStreamErrors(fixture.replace("controller.close();", "controller.close(0);")),
    /pattern changed/,
  );
  assert.throws(
    () => withTrackedStreamErrors(fixture.replace("DOWNLOAD_ATTEMPTS_MAX = 4", "DOWNLOAD_ATTEMPTS_MAX = 5")),
    /implementation changed/,
  );
  assert.throws(() => withTrackedStreamErrors(fixture + fixture), /pattern changed/);
  assert.throws(() => withTrackedStreamErrors("unrelated script"), /pattern changed/);
});
