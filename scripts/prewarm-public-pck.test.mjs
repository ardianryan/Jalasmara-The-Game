import test from "node:test";
import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import { verifyPublicPck } from "./prewarm-public-pck.mjs";

const digest = (bytes) => createHash("sha256").update(bytes).digest("hex");
const first = Buffer.alloc(1024 * 1024, 17);
const last = Buffer.from("verified tail");
const sha = digest(Buffer.concat([first, last]));
const manifest = {
  version: 1, sha256: sha, bytes: first.length + last.length,
  partSize: 1024 * 1024, hashes: [digest(first), digest(last)],
};

function endpoint({ corrupt = false, stale = false, fullSha = sha } = {}) {
  const calls = [];
  const fetcher = async (url) => {
    const pathname = new URL(url).pathname;
    calls.push(pathname);
    if (pathname.endsWith("pck-manifest.json"))
      return Response.json(stale ? { ...manifest, sha256: "0".repeat(64) } : { ...manifest, sha256: fullSha });
    const index = Number(pathname.split("/").at(-1));
    const bytes = index === 0 ? first : (corrupt ? Buffer.from("bad tail") : last);
    return new Response(bytes, {
      headers: {
        "content-length": String(index === 0 ? first.length : last.length),
        "x-pck-offset": String(index * first.length),
        "x-pck-length": String(manifest.bytes),
      },
    });
  };
  return { fetcher, calls };
}

test("verifies every public part against pinned manifest, including the short tail", async () => {
  const { fetcher, calls } = endpoint();
  const result = await verifyPublicPck("https://game.test", sha, fetcher);
  assert.equal(result.bytes, manifest.bytes);
  assert.equal(result.parts, 2);
  assert.equal(result.retriedParts, 0);
  assert.deepEqual(calls.map((path) => path.split("/").at(-1)),
    ["pck-manifest.json", "0", "1"]);
});

test("rejects stale release manifest before transferring any part", async () => {
  const { fetcher, calls } = endpoint({ stale: true });
  await assert.rejects(verifyPublicPck("https://game.test", sha, fetcher), /pinned release/);
  assert.equal(calls.length, 1);
});

test("retries a corrupt part once and never reports a verified warm-up", async () => {
  const { fetcher, calls } = endpoint({ corrupt: true });
  await assert.rejects(verifyPublicPck("https://game.test", sha, fetcher), /checksum mismatch/);
  assert.equal(calls.filter((path) => path.endsWith("/1")).length, 2);
});

test("rejects a manifest whose part hashes pass but full PCK SHA is false", async () => {
  const falseSha = "1".repeat(64);
  const { fetcher } = endpoint({ fullSha: falseSha });
  await assert.rejects(verifyPublicPck("https://game.test", falseSha, fetcher), /full checksum mismatch/);
});
