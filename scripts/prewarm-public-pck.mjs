import { createHash } from "node:crypto";
import { Agent, request } from "node:https";
import { pathToFileURL } from "node:url";

const SHA = /^[a-f0-9]{64}$/;
const PART_BYTES = 1024 * 1024;

export async function verifyPublicPck(origin, expectedSha, fetcher = fetch) {
  const base = new URL(origin);
  if (base.protocol !== "https:" && base.hostname !== "localhost" && base.hostname !== "127.0.0.1")
    throw new Error("Public PCK verification requires HTTPS or localhost");
  if (!SHA.test(expectedSha)) throw new Error("Expected PCK SHA-256 is required");
  const startedAt = Date.now();
  const overallDeadline = AbortSignal.timeout(5 * 60 * 1000);
  const manifestResponse = await fetcher(new URL("/game/pck-manifest.json", base), {
    cache: "no-store",
    signal: AbortSignal.any([overallDeadline, AbortSignal.timeout(30000)]),
  });
  if (!manifestResponse.ok) throw new Error(`PCK manifest HTTP ${manifestResponse.status}`);
  const manifest = await manifestResponse.json();
  if (
    manifest.version !== 1 || manifest.sha256 !== expectedSha ||
    !Number.isSafeInteger(manifest.bytes) || manifest.bytes < 1 ||
    manifest.bytes > 512 * 1024 * 1024 || manifest.partSize !== PART_BYTES ||
    !Array.isArray(manifest.hashes) ||
    manifest.hashes.length !== Math.ceil(manifest.bytes / PART_BYTES) ||
    !manifest.hashes.every((hash) => SHA.test(hash))
  ) throw new Error("Public PCK manifest does not match the pinned release");

  let next = 0;
  let completedBytes = 0;
  let failure;
  const attempts = new Array(manifest.hashes.length).fill(0);
  const worker = async () => {
    while (!failure && next < manifest.hashes.length) {
      const index = next++;
      const size = Math.min(PART_BYTES, manifest.bytes - index * PART_BYTES);
      const url = new URL(`/game/pck/${expectedSha}/${index}`, base);
      let verified = false;
      for (let attempt = 1; attempt <= 2 && !verified; attempt++) {
        attempts[index] = attempt;
        try {
          const response = await fetcher(url, {
            signal: AbortSignal.any([overallDeadline, AbortSignal.timeout(60000)]),
          });
          if (
            response.status !== 200 ||
            response.headers.get("content-length") !== String(size) ||
            response.headers.get("x-pck-offset") !== String(index * PART_BYTES) ||
            response.headers.get("x-pck-length") !== String(manifest.bytes)
          ) throw new Error(`part ${index}: response metadata mismatch`);
          const bytes = Buffer.from(await response.arrayBuffer());
          if (bytes.length !== size || createHash("sha256").update(bytes).digest("hex") !== manifest.hashes[index])
            throw new Error(`part ${index}: checksum mismatch`);
          completedBytes += bytes.length;
          verified = true;
        } catch (error) {
          if (attempt === 2) {
            failure = error;
            return;
          }
        }
      }
    }
  };
  await Promise.all(Array.from({ length: Math.min(6, manifest.hashes.length) }, worker));
  if (failure) throw failure;
  if (completedBytes !== manifest.bytes) throw new Error("Public PCK verification incomplete");
  return {
    origin: base.origin,
    sha256: expectedSha,
    bytes: completedBytes,
    parts: manifest.hashes.length,
    retriedParts: attempts.filter((count) => count > 1).length,
    elapsedMs: Date.now() - startedAt,
  };
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  const [origin, sha] = process.argv.slice(2);
  const agent = new Agent({ keepAlive: true, maxSockets: 6 });
  const sixSocketFetch = (url, { signal } = {}) => new Promise((resolve, reject) => {
    const call = request(url, { agent, signal }, (response) => {
      const chunks = [];
      const limit = new URL(url).pathname.endsWith("/pck-manifest.json") ? 40000 : PART_BYTES;
      let received = 0;
      response.on("data", (chunk) => {
        received += chunk.length;
        if (received > limit) call.destroy(new Error("Public PCK response exceeded byte limit"));
        else chunks.push(chunk);
      });
      response.on("end", () => resolve(new Response(Buffer.concat(chunks), {
        status: response.statusCode,
        headers: response.headers,
      })));
      response.on("error", reject);
    });
    call.on("error", reject);
    call.end();
  });
  try {
    const result = await verifyPublicPck(origin ?? "", sha ?? "", sixSocketFetch);
    console.log(JSON.stringify(result));
  } catch (error) {
    console.error(error.message);
    process.exitCode = 1;
  } finally {
    agent.destroy();
  }
}
