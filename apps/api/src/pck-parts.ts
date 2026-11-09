import { createHash } from "node:crypto";
import { createReadStream, existsSync } from "node:fs";
import { readFile, stat } from "node:fs/promises";
import { resolve } from "node:path";
import type { FastifyInstance } from "fastify";
import { z } from "zod";

const manifestSchema = z
  .object({
    version: z.literal(1),
    sha256: z.string().regex(/^[a-f0-9]{64}$/),
    bytes: z
      .number()
      .int()
      .min(1)
      .max(512 * 1024 * 1024),
    partSize: z.literal(1024 * 1024),
    hashes: z
      .array(z.string().regex(/^[a-f0-9]{64}$/))
      .min(1)
      .max(512),
  })
  .strict();

export async function registerPckParts(app: FastifyInstance, root: string) {
  const manifestPath = resolve(root, "game/pck-manifest.json");
  if (!existsSync(manifestPath)) return;
  if ((await stat(manifestPath)).size > 40 * 1024)
    throw new Error("PCK manifest exceeds its bounded size");
  const manifest = manifestSchema.parse(
    JSON.parse(await readFile(manifestPath, "utf8")),
  );
  const file = resolve(root, "game/index.pck");
  if (
    (await stat(file)).size !== manifest.bytes ||
    manifest.hashes.length !== Math.ceil(manifest.bytes / manifest.partSize)
  )
    throw new Error("PCK manifest length does not match its file");
  const hash = createHash("sha256");
  for await (const chunk of createReadStream(file)) hash.update(chunk);
  if (hash.digest("hex") !== manifest.sha256)
    throw new Error("PCK manifest checksum does not match its file");

  app.get<{ Params: { sha: string; index: string } }>(
    "/game/pck/:sha/:index",
    {
      config: { rateLimit: { max: 1200, timeWindow: "1 minute" } },
    },
    async (request, reply) => {
      const { sha, index } = request.params;
      if (sha !== manifest.sha256 || !/^(0|[1-9][0-9]{0,2})$/.test(index))
        return reply.code(404).send();
      const start = Number(index) * manifest.partSize;
      if (start >= manifest.bytes) return reply.code(404).send();
      const end = Math.min(start + manifest.partSize, manifest.bytes) - 1;
      return reply
        .type("application/octet-stream")
        .header("Cache-Control", "public, max-age=31536000, immutable")
        .header("Content-Length", end - start + 1)
        .header("X-Pck-Offset", start)
        .header("X-Pck-Length", manifest.bytes)
        .header("ETag", `"${manifest.hashes[Number(index)]}"`)
        .send(createReadStream(file, { start, end }));
    },
  );
}
