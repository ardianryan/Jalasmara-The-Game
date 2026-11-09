import test from "node:test";
import assert from "node:assert/strict";
import { startLoaderBodyFault } from "./loader-body-fault.mjs";
for (const extension of ["pck", "wasm"]) {
  test(`real HTTP200 ${extension} body truncates after bytes and errors its reader`, async () => {
    const prefix = Buffer.from(
      Array.from({ length: 128 }, (_, index) => index),
    );
    const server = await startLoaderBodyFault({
      path: `/game/index.${extension}`,
      origin: "http://localhost:3101",
      totalBytes: 4096,
      prefix,
      chunkBytes: 32,
      chunkDelayMs: 5,
      abortDelayMs: 30,
    });
    try {
      const response = await fetch(server.url);
      assert.equal(response.status, 200);
      assert.equal(response.headers.get("content-length"), "4096");
      const reader = response.body.getReader(),
        chunks = [];
      let rejected = false;
      try {
        while (true) {
          const chunk = await reader.read();
          if (chunk.done) break;
          chunks.push(Buffer.from(chunk.value));
        }
      } catch {
        rejected = true;
      }
      assert(
        rejected,
        "This must fail while reading an already-started HTTP body, not before response headers",
      );
      assert.deepEqual(Buffer.concat(chunks), prefix);
      assert.equal(server.requests.length, 1);
      assert.equal(server.requests[0].writtenBytes, prefix.length);
      assert(server.requests[0].destroyedAt);
    } finally {
      await server.close();
    }
  });
}
test("fault server refuses public origins, nonasset paths and nontruncated bodies", async () => {
  const valid = {
    path: "/game/index.pck",
    origin: "http://localhost:3101",
    totalBytes: 1024,
    prefix: Buffer.alloc(128),
  };
  await assert.rejects(
    startLoaderBodyFault({
      ...valid,
      origin: "https://staging-jalasmara.ardianryan.com",
    }),
  );
  await assert.rejects(
    startLoaderBodyFault({ ...valid, path: "/api/auth/session" }),
  );
  await assert.rejects(startLoaderBodyFault({ ...valid, totalBytes: 128 }));
});

test("versioned part2 passes production metadata checks, then fails an already-started body reader", async () => {
  const bytes = 1024 * 1024,
    packBytes = 4 * bytes;
  const prefix = Buffer.alloc(128, 37);
  const server = await startLoaderBodyFault({
    path: "/game/pck/" + "a".repeat(64) + "/2",
    origin: "http://localhost:3111",
    totalBytes: bytes,
    packBytes,
    prefix,
    chunkBytes: 32,
    chunkDelayMs: 5,
    abortDelayMs: 30,
  });
  try {
    const response = await fetch(server.url);
    assert.equal(response.status, 200);
    assert.equal(response.headers.get("content-length"), String(bytes));
    assert.equal(response.headers.get("x-pck-offset"), String(2 * bytes));
    assert.equal(response.headers.get("x-pck-length"), String(packBytes));
    assert.equal(
      response.headers.get("access-control-allow-origin"),
      "http://localhost:3111",
    );
    const exposed = response.headers
      .get("access-control-expose-headers")
      .toLowerCase();
    for (const name of ["content-length", "x-pck-offset", "x-pck-length"])
      assert(exposed.includes(name));
    const chunks = [],
      reader = response.body.getReader();
    let rejected = false;
    try {
      while (true) {
        const chunk = await reader.read();
        if (chunk.done) break;
        chunks.push(Buffer.from(chunk.value));
      }
    } catch {
      rejected = true;
    }
    assert(rejected);
    assert.deepEqual(Buffer.concat(chunks), prefix);
    assert.equal(server.requests[0].offset, 2 * bytes);
    assert.equal(server.requests[0].packBytes, packBytes);
    assert(server.requests[0].destroyedAt);
  } finally {
    await server.close();
  }
});

test("part faults reject mismatched metadata, oversized indexes and metadata on a legacy asset", async () => {
  const valid = {
    path: "/game/pck/" + "a".repeat(64) + "/2",
    origin: "http://localhost:3111",
    totalBytes: 1024 * 1024,
    packBytes: 4 * 1024 * 1024,
    prefix: Buffer.alloc(128),
  };
  await assert.rejects(
    startLoaderBodyFault({ ...valid, packBytes: 1024 * 1024 }),
  );
  await assert.rejects(startLoaderBodyFault({ ...valid, totalBytes: 4096 }));
  await assert.rejects(
    startLoaderBodyFault({
      ...valid,
      path: "/game/pck/" + "a".repeat(64) + "/1000",
    }),
  );
  await assert.rejects(
    startLoaderBodyFault({ ...valid, path: "/game/index.pck" }),
  );
});
