#!/usr/bin/env python3
"""Bundle the Docker build inputs and verified game assets, without repo caches."""

import argparse
import gzip
import hashlib
import io
import json
from pathlib import Path, PurePosixPath
import subprocess
import tarfile
import re


SCOPES = [
    "Dockerfile", ".dockerignore", "package.json", "package-lock.json",
    "tsconfig.base.json", "apps", "packages",
    "client-godot/resources/art/hud-bahari-v1/button-normal.png",
]
REUSABLE = {"index.wasm", "index.wasm.gz"}
ASSET_NAMES = {
    "index.html", "index.js", "index.js.gz", "index.pck", "index.pck.gz",
    "index.wasm", "index.wasm.gz", "index.png", "pck-manifest.json",
    "index.audio.worklet.js", "index.audio.worklet.js.gz",
    "index.audio.position.worklet.js", "index.audio.position.worklet.js.gz",
}


def sha256(path):
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for block in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def asset_records(directory):
    records = []
    for path in sorted(directory.iterdir()):
        if path.name not in ASSET_NAMES and not re.fullmatch(r"bootstrap-[1-9][0-9]*\.js(?:\.gz)?", path.name):
            raise ValueError(f"Unexpected file in generated game export: {path.name}")
        if path.is_symlink() or not path.is_file():
            raise ValueError(f"Expected regular game asset: {path.name}")
        records.append({"name": path.name, "bytes": path.stat().st_size,
                        "sha256": sha256(path)})
    by_name = {record["name"]: record for record in records}
    for name in ["index.html", "index.js", "index.wasm", "index.pck", "pck-manifest.json"]:
        if name not in by_name:
            raise ValueError(f"Missing game asset: {name}")
    manifest = json.loads((directory / "pck-manifest.json").read_text())
    if (manifest.get("version") != 1
            or manifest.get("sha256") != by_name["index.pck"]["sha256"]
            or manifest.get("bytes") != by_name["index.pck"]["bytes"]
            or manifest.get("partSize") != 1024 * 1024):
        raise ValueError("Exported PCK does not match its manifest")
    with (directory / "index.pck").open("rb") as source:
        actual = [hashlib.sha256(block).hexdigest()
                  for block in iter(lambda: source.read(1024 * 1024), b"")]
    if manifest.get("hashes") != actual:
        raise ValueError("Exported PCK part hashes do not match its manifest")
    for record in records:
        if not record["name"].endswith(".gz"):
            continue
        original = by_name.get(record["name"][:-3])
        if original is None:
            raise ValueError("Orphan compressed game asset")
        digest, size = hashlib.sha256(), 0
        with gzip.open(directory / record["name"], "rb") as source:
            for block in iter(lambda: source.read(1024 * 1024), b""):
                size += len(block)
                if size > original["bytes"]:
                    raise ValueError("Compressed game asset exceeds its original")
                digest.update(block)
        if size != original["bytes"] or digest.hexdigest() != original["sha256"]:
            raise ValueError("Compressed game asset does not match its original")
    return records


def safe_member(member):
    path = PurePosixPath(member.name)
    return (not path.is_absolute() and ".." not in path.parts
            and (member.isfile() or member.isdir())
            and not any(part in {".git", "node_modules", ".runtime"}
                        or part.startswith(".env") for part in path.parts))


def package(root, output, reuse_wasm=False, export_source=None):
    if output.exists():
        raise ValueError("Output already exists; preserve previous release evidence")
    subprocess.run(["git", "diff", "--exit-code", "HEAD", "--", *SCOPES],
                   cwd=root, check=True, capture_output=True)
    source = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=root,
                                     text=True).strip()
    if export_source is not None:
        if not re.fullmatch(r"[a-f0-9]{40}", export_source):
            raise ValueError("Use the full declared export source commit")
        subprocess.run(["git", "cat-file", "-e", export_source + "^{commit}"],
                       cwd=root, check=True, capture_output=True)
    game = root / "apps/web/public/game"
    assets = asset_records(game)
    archive = subprocess.check_output(
        ["git", "archive", "--format=tar", "HEAD", "--", *SCOPES], cwd=root)
    with tarfile.open(fileobj=io.BytesIO(archive)) as tracked:
        members = tracked.getmembers()
        if not all(safe_member(member) for member in members):
            raise ValueError("Unsafe or secret-bearing tracked Docker input")
        if any(member.name.startswith("apps/web/public/game/") for member in members):
            raise ValueError("Generated game exports must not be tracked in Git")
        output.mkdir(parents=True)
        context = output / "context.tar"
        with tarfile.open(context, "x") as bundle:
            for member in members:
                bundle.addfile(member, tracked.extractfile(member) if member.isfile() else None)
            for asset in assets:
                if reuse_wasm and asset["name"] in REUSABLE:
                    continue
                bundle.add(game / asset["name"],
                           arcname="apps/web/public/game/" + asset["name"], recursive=False)
    manifest = {"schemaVersion": 1, "source": source,
                "declaredExportSource": export_source,
                "context": {"name": context.name, "bytes": context.stat().st_size,
                            "sha256": sha256(context)},
                "gameAssets": assets,
                "requiredReusedAssets": [asset for asset in assets
                                         if reuse_wasm and asset["name"] in REUSABLE],
                "reuseRequirement": "Verify each reused file's byte count and SHA-256 before copying it into the extracted build context. Verify all gameAssets before building.",
                "toolSha256": sha256(Path(__file__))}
    (output / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    return manifest


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--reuse-wasm", action="store_true")
    parser.add_argument("--export-source", required=True,
                        help="Full source commit declared when the Godot export began; separate from Docker source")
    args = parser.parse_args()
    root = Path(__file__).resolve().parent.parent
    manifest = package(root, args.output.resolve(), args.reuse_wasm, args.export_source)
    print(json.dumps({"source": manifest["source"], "context": manifest["context"],
                      "requiredReusedAssets": manifest["requiredReusedAssets"]}, indent=2))


if __name__ == "__main__":
    main()
