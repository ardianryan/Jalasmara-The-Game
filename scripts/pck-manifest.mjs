import { createHash } from "node:crypto";

export const PCK_PART_BYTES = 1024 * 1024;

export function pckManifest(bytes) {
  if (
    !Buffer.isBuffer(bytes) ||
    !bytes.length ||
    bytes.length > 512 * PCK_PART_BYTES
  )
    throw new Error("PCK must contain between one byte and 512 MiB");
  const hashes = [];
  for (let offset = 0; offset < bytes.length; offset += PCK_PART_BYTES)
    hashes.push(
      createHash("sha256")
        .update(bytes.subarray(offset, offset + PCK_PART_BYTES))
        .digest("hex"),
    );
  return {
    version: 1,
    sha256: createHash("sha256").update(bytes).digest("hex"),
    bytes: bytes.length,
    partSize: PCK_PART_BYTES,
    hashes,
  };
}
