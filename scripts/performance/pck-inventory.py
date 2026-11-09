"""Read an unencrypted standalone PCK without running Godot or extracting files.

Field layout reference: Godot 4.7.2-stable, core/io/file_access_pack.cpp
(PackedSourcePCK::try_open_pack) and file_access_pack.h. This tool rejects
sparse/encrypted/delta packs rather than guessing at their payload offsets.
"""

from __future__ import annotations

import argparse
import collections
import hashlib
import json
import struct
from pathlib import Path


def inventory(path: Path, expected_sha256: str | None = None) -> dict:
    data = path.read_bytes()
    sha256 = hashlib.sha256(data).hexdigest()
    if expected_sha256 and sha256 != expected_sha256:
        raise ValueError("PCK SHA-256 does not match the requested candidate")
    if data[:4] != b"GDPC":
        raise ValueError("Only standalone PCK files are supported")

    def u32(offset):
        return struct.unpack_from("<I", data, offset)[0]

    def u64(offset):
        return struct.unpack_from("<Q", data, offset)[0]

    version, pack_flags, file_base = u32(4), u32(20), u64(24)
    if version not in (2, 3, 4) or pack_flags & ~2:
        raise ValueError("Unsupported pack version or flags")
    position = u64(32) if version in (3, 4) else 96
    directory_start = position
    file_count = u32(position)
    position += 4
    if file_count > 1_000_000:
        raise ValueError("Invalid directory count")
    entries, digests, names = [], collections.defaultdict(list), set()
    extensions = collections.defaultdict(lambda: {"count": 0, "bytes": 0})
    for _ in range(file_count):
        length = u32(position)
        position += 4
        if length > 65_536 or position + length + 36 > len(data):
            raise ValueError("Invalid directory entry length")
        name = data[position:position + length].split(b"\0", 1)[0].decode("utf-8")
        position += length
        offset, size = file_base + u64(position), u64(position + 8)
        expected_md5 = data[position + 16:position + 32]
        flags = u32(position + 32)
        position += 36
        if flags or offset + size > len(data) or name in names:
            raise ValueError(f"Invalid or unsupported entry: {name}")
        payload = data[offset:offset + size]
        if hashlib.md5(payload).digest() != expected_md5:
            raise ValueError(f"Payload MD5 mismatch: {name}")
        names.add(name)
        entries.append({"path": name, "bytes": size})
        digests[(size, hashlib.sha256(payload).hexdigest())].append(name)
        extension = Path(name).suffix
        extensions[extension]["count"] += 1
        extensions[extension]["bytes"] += size

    duplicate_groups = [
        {"bytes_each": size, "avoidable_bytes_if_references_reworked": size * (len(paths) - 1), "paths": paths}
        for (size, _), paths in digests.items() if len(paths) > 1
    ]
    payload_bytes = sum(entry["bytes"] for entry in entries)
    return {
        "sha256": sha256,
        "file_bytes": len(data),
        "format_version": version,
        "engine_version": [u32(8), u32(12), u32(16)],
        "pack_flags": pack_flags,
        "file_base": file_base,
        "directory_offset": directory_start,
        "directory_bytes": position - directory_start,
        "files": file_count,
        "md5_payloads_verified": len(entries),
        "payload_bytes": payload_bytes,
        "header_directory_alignment_bytes": len(data) - payload_bytes,
        "extensions": dict(sorted(extensions.items(), key=lambda item: item[1]["bytes"], reverse=True)),
        "largest_resources": sorted(entries, key=lambda entry: entry["bytes"], reverse=True)[:40],
        "duplicate_payload_bytes": sum(group["avoidable_bytes_if_references_reworked"] for group in duplicate_groups),
        "duplicate_groups": sorted(duplicate_groups, key=lambda group: group["bytes_each"], reverse=True),
        "limitations": "Stored resource bytes are not decoded GPU memory, network transfer, or proof that a resource is unused. No files were extracted or removed.",
    }


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("pck", type=Path)
    parser.add_argument("--expected-sha256")
    args = parser.parse_args()
    print(json.dumps(inventory(args.pck, args.expected_sha256), indent=2))
