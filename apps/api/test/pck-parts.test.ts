import test from "node:test";
import assert from "node:assert/strict";
import Fastify from "fastify";
import { createHash } from "node:crypto";
import { mkdtempSync, mkdirSync, writeFileSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { registerPckParts } from "../src/pck-parts.js";

const size = 1024 * 1024;
const source = Buffer.alloc(size * 2 + 317);
for (let index = 0; index < source.length; index++) source[index] = index % 251;
const digest = (bytes: Buffer) =>
  createHash("sha256").update(bytes).digest("hex");
const manifest = {
  version: 1,
  sha256: digest(source),
  bytes: source.length,
  partSize: size,
  hashes: [0, 1, 2].map((index) =>
    digest(source.subarray(index * size, (index + 1) * size)),
  ),
};

async function fixture(
  run: (app: ReturnType<typeof Fastify>, root: string) => Promise<void>,
  data: unknown = manifest,
) {
  const root = mkdtempSync(join(tmpdir(), "jalasmara-pck-"));
  const app = Fastify();
  try {
    mkdirSync(join(root, "game"));
    writeFileSync(join(root, "game/index.pck"), source);
    if (data !== null)
      writeFileSync(join(root, "game/pck-manifest.json"), JSON.stringify(data));
    await run(app, root);
  } finally {
    await app.close();
    rmSync(root, { recursive: true, force: true });
  }
}

test("PCK parts reconstruct exact bytes; tail, immutable version and HEAD stay bounded", async () => {
  await fixture(async (app, root) => {
    await registerPckParts(app, root);
    const parts: Buffer[] = [];
    for (let index = 0; index < 3; index++) {
      const response = await app.inject(
        `/game/pck/${manifest.sha256}/${index}`,
      );
      assert.equal(response.statusCode, 200);
      assert.equal(
        Number(response.headers["content-length"]),
        response.rawPayload.length,
      );
      assert.equal(Number(response.headers["x-pck-offset"]), index * size);
      assert.equal(Number(response.headers["x-pck-length"]), source.length);
      assert.equal(response.headers.etag, `"${manifest.hashes[index]}"`);
      assert.equal(response.headers["content-encoding"], undefined);
      assert.match(String(response.headers["cache-control"]), /immutable/);
      assert(response.rawPayload.length <= size);
      parts.push(response.rawPayload);
    }
    assert.deepEqual(Buffer.concat(parts), source);
    const head = await app.inject({
      method: "HEAD",
      url: `/game/pck/${manifest.sha256}/0`,
    });
    assert.equal(head.rawPayload.length, 0);
    assert.equal(head.headers["content-length"], String(size));
    for (const index of ["-1", "3", "01", "1.1", "1e0", "1000", "bad"])
      assert.equal(
        (await app.inject(`/game/pck/${manifest.sha256}/${index}`)).statusCode,
        404,
      );
    assert.equal(
      (await app.inject(`/game/pck/${"a".repeat(64)}/0`)).statusCode,
      404,
    );
    assert.equal(
      (await app.inject(`/game/pck/${manifest.sha256}/..%2Findex.pck`))
        .statusCode,
      404,
    );
  });
});

test("legacy exports without manifests do not install the segmented route", async () => {
  await fixture(async (app, root) => {
    await registerPckParts(app, root);
    assert.equal(
      (await app.inject(`/game/pck/${manifest.sha256}/0`)).statusCode,
      404,
    );
  }, null);
});

test("manifest reads accept the exact40KiB budget and reject the first excess byte", async () => {
  await fixture(async (app, root) => {
    writeFileSync(
      join(root, "game/pck-manifest.json"),
      JSON.stringify(manifest).padEnd(40 * 1024, " "),
    );
    await registerPckParts(app, root);
    assert.equal(
      (await app.inject(`/game/pck/${manifest.sha256}/0`)).statusCode,
      200,
    );
  });
  await fixture(async (app, root) => {
    writeFileSync(
      join(root, "game/pck-manifest.json"),
      JSON.stringify(manifest).padEnd(40 * 1024 + 1, " "),
    );
    await assert.rejects(
      registerPckParts(app, root),
      /exceeds its bounded size/,
    );
  });
});

for (const [name, invalid] of [
  ["source checksum", { ...manifest, sha256: "a".repeat(64) }],
  ["source length", { ...manifest, bytes: 12 }],
  ["part count", { ...manifest, hashes: [] }],
  ["part size", { ...manifest, partSize: 4 }],
  ["oversized source", { ...manifest, bytes: 513 * size }],
] as const)
  test(`PCK startup rejects mismatched ${name}`, async () => {
    await fixture(async (app, root) => {
      await assert.rejects(registerPckParts(app, root));
    }, invalid);
  });
