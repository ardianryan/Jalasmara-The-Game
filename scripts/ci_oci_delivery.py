#!/usr/bin/env python3
"""Verify a CI release context and the complete OCI image built from it."""

import argparse
import hashlib
import json
from pathlib import Path, PurePosixPath
import re
import shutil
import subprocess
import tarfile
import tempfile


SHA256 = re.compile(r"[a-f0-9]{64}\Z")
COMMIT = re.compile(r"[a-f0-9]{40}\Z")
RUNTIME_ROOTS = ("apps/api/dist", "apps/web/dist")
REQUIRED_RUNTIME = {
    "apps/api/dist/apps/api/src/index.js",
    "apps/web/dist/index.html",
    "apps/web/dist/game/index.pck",
    "apps/web/dist/game/index.wasm",
}
REQUIRED_CONTEXT = {
    "Dockerfile", "package.json", "package-lock.json",
    "apps/api/package.json", "apps/web/package.json",
}
BLOCKED_COMPONENTS = {".git", "node_modules", ".runtime"}


def require(condition, message):
    if not condition:
        raise ValueError(message)


def sha256(path):
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def regular_file(path):
    require(path.is_file() and not path.is_symlink(), f"Expected regular file: {path}")


def read_json(path):
    regular_file(path)
    return json.loads(path.read_text())


def valid_record(record):
    return (isinstance(record, dict) and isinstance(record.get("bytes"), int)
            and not isinstance(record["bytes"], bool) and record["bytes"] >= 0
            and isinstance(record.get("sha256"), str)
            and SHA256.fullmatch(record["sha256"]) is not None)


def verify_record(path, record):
    require(valid_record(record), f"Invalid file record: {path}")
    regular_file(path)
    require(path.stat().st_size == record["bytes"], f"Size mismatch: {path}")
    require(sha256(path) == record["sha256"], f"SHA-256 mismatch: {path}")


def safe_relative(name):
    if not isinstance(name, str) or not name or "\\" in name:
        return False
    path = PurePosixPath(name)
    return (not path.is_absolute() and path.as_posix() == name
            and all(part not in {"", ".", ".."} and part not in BLOCKED_COMPONENTS
                    and not part.startswith(".env") for part in path.parts))


def validate_release_metadata(manifest, expected_source):
    require(COMMIT.fullmatch(expected_source) is not None, "Expected full source commit")
    require(manifest.get("schemaVersion") == 1, "Unknown release manifest schema")
    require(manifest.get("source") == expected_source, "Release source differs from CI checkout")
    require(manifest.get("declaredExportSource") == expected_source,
            "Godot export source differs from CI checkout")
    require(manifest.get("requiredReusedAssets") == [],
            "Full-source image requires a bundle with all game assets")
    context = manifest.get("context")
    require(isinstance(context, dict) and context.get("name") == "context.tar"
            and valid_record(context) and 0 < context["bytes"] <= 1024**3,
            "Invalid release context record")
    assets = manifest.get("gameAssets")
    require(isinstance(assets, list) and assets, "Missing game assets")
    names = set()
    for asset in assets:
        require(valid_record(asset), "Invalid game asset record")
        name = asset.get("name")
        require(isinstance(name, str) and name == PurePosixPath(name).name
                and safe_relative(name) and name not in names, "Unsafe or duplicate game asset")
        names.add(name)
    require({"index.html", "index.js", "index.wasm", "index.pck", "pck-manifest.json"}
            <= names, "Missing required game assets")
    return manifest


def release_manifest(bundle, expected_source):
    manifest = validate_release_metadata(read_json(bundle / "manifest.json"),
                                         expected_source)
    verify_record(bundle / "context.tar", manifest["context"])
    return manifest


def runtime_files(repo):
    records = []
    for root_name in RUNTIME_ROOTS:
        root = repo / root_name
        require(root.is_dir() and not root.is_symlink(), f"Missing compiled runtime: {root_name}")
        for path in sorted(root.rglob("*")):
            relative = path.relative_to(repo).as_posix()
            require(safe_relative(relative), f"Unsafe runtime path: {relative}")
            require(not path.is_symlink(), f"Symlink in compiled runtime: {relative}")
            if path.is_dir():
                continue
            regular_file(path)
            # The tracked placeholder exists in the verifier checkout but is
            # deliberately excluded from the release context by the packager.
            if relative == "apps/web/dist/game/.gitkeep":
                require(path.stat().st_size == 0, "Nonempty game export placeholder")
                continue
            records.append({"name": relative, "bytes": path.stat().st_size,
                            "sha256": sha256(path)})
    require(REQUIRED_RUNTIME <= {record["name"] for record in records},
            "Compiled API, web entry or game export missing")
    return records


def write_runtime_manifest(repo, output, source):
    require(COMMIT.fullmatch(source) is not None, "Expected full source commit")
    record = {"schemaVersion": 1, "source": source, "files": runtime_files(repo)}
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(record, indent=2) + "\n")
    return record


def runtime_manifest(bundle, source, release):
    record = read_json(bundle / "runtime-files.json")
    require(record.get("schemaVersion") == 1 and record.get("source") == source,
            "Compiled runtime source differs from release source")
    files = record.get("files")
    require(isinstance(files, list) and files, "Missing compiled runtime records")
    names = set()
    by_name = {}
    for entry in files:
        require(valid_record(entry), "Invalid compiled runtime record")
        name = entry.get("name")
        require(safe_relative(name) and any(name.startswith(root + "/") for root in RUNTIME_ROOTS)
                and name not in names, "Unsafe or duplicate compiled runtime path")
        names.add(name)
        by_name[name] = entry
    require(REQUIRED_RUNTIME <= names, "Compiled API, web entry or game export missing")
    game_names = {name for name in names if name.startswith("apps/web/dist/game/")}
    expected_game_names = {"apps/web/dist/game/" + asset["name"]
                           for asset in release["gameAssets"]}
    require(game_names == expected_game_names,
            "Compiled game assets differ from the release manifest")
    for asset in release["gameAssets"]:
        runtime_asset = by_name["apps/web/dist/game/" + asset["name"]]
        require(runtime_asset["bytes"] == asset["bytes"]
                and runtime_asset["sha256"] == asset["sha256"],
                f"Compiled game asset differs from release: {asset['name']}")
    return record


def prepare_context(bundle, output, source):
    release = release_manifest(bundle, source)
    runtime_manifest(bundle, source, release)
    require(not output.exists(), "Refusing to overwrite an existing build context")
    with tarfile.open(bundle / "context.tar", "r:") as archive:
        members = archive.getmembers()
        seen = set()
        files = set()
        total = 0
        for member in members:
            name = member.name.rstrip("/")
            require(safe_relative(name) and (member.isfile() or member.isdir())
                    and name not in seen, "Unsafe or duplicate context member")
            seen.add(name)
            if member.isfile():
                files.add(name)
                total += member.size
                require(total <= 1024**3, "Context files exceed size limit")
        require(REQUIRED_CONTEXT <= files, "Missing Docker build inputs")
        output.mkdir(parents=True)
        for member in members:
            path = output / member.name
            if member.isdir():
                path.mkdir(parents=True, exist_ok=True)
                continue
            path.parent.mkdir(parents=True, exist_ok=True)
            with archive.extractfile(member) as source_file, path.open("xb") as target:
                shutil.copyfileobj(source_file, target)
    game = output / "apps/web/public/game"
    actual_assets = {path.name for path in game.iterdir() if path.is_file()}
    expected_assets = {asset["name"] for asset in release["gameAssets"]}
    require(actual_assets == expected_assets, "Extracted game asset set differs from manifest")
    for asset in release["gameAssets"]:
        verify_record(game / asset["name"], asset)
    pck = next(asset for asset in release["gameAssets"] if asset["name"] == "index.pck")
    part_manifest = read_json(game / "pck-manifest.json")
    require(part_manifest.get("version") == 1 and part_manifest.get("sha256") == pck["sha256"]
            and part_manifest.get("bytes") == pck["bytes"]
            and part_manifest.get("partSize") == 1024 * 1024,
            "PCK part manifest differs from release")
    with (game / "index.pck").open("rb") as stream:
        part_hashes = [hashlib.sha256(block).hexdigest()
                       for block in iter(lambda: stream.read(1024 * 1024), b"")]
    require(part_manifest.get("hashes") == part_hashes, "PCK part hashes differ from release")
    return release


def verify_image(image, bundle, source):
    release = release_manifest(bundle, source)
    expected = runtime_manifest(bundle, source, release)
    inspection = json.loads(subprocess.check_output(
        ["docker", "image", "inspect", image], text=True))[0]
    image_id = inspection.get("Id")
    require(isinstance(image_id, str) and image_id.startswith("sha256:")
            and SHA256.fullmatch(image_id[7:]) is not None, "Invalid image ID")
    require(inspection.get("Os") == "linux" and inspection.get("Architecture") == "amd64",
            "OCI image must be linux/amd64")
    require(inspection.get("Config", {}).get("Labels", {}).get(
        "org.opencontainers.image.revision") == source, "OCI image source label differs")
    container = subprocess.check_output(["docker", "create", image], text=True).strip()
    try:
        with tempfile.TemporaryDirectory(prefix="jalasmara-oci-check-") as scratch:
            root = Path(scratch)
            for subtree in RUNTIME_ROOTS:
                destination = root / subtree
                destination.parent.mkdir(parents=True, exist_ok=True)
                subprocess.run(["docker", "cp", f"{container}:/app/{subtree}", str(destination)],
                               check=True, capture_output=True)
            actual = runtime_files(root)
            require(actual == expected["files"],
                    "OCI image API/Web output differs from the verified CI build")
    finally:
        subprocess.run(["docker", "rm", "-f", container], check=True,
                       capture_output=True)
    pck = next(asset for asset in release["gameAssets"] if asset["name"] == "index.pck")
    return {"schemaVersion": 1, "source": source, "imageId": image_id,
            "platform": "linux/amd64", "contextSha256": release["context"]["sha256"],
            "runtimeManifestSha256": sha256(bundle / "runtime-files.json"),
            "runtimeFileCount": len(expected["files"]),
            "gameAssetCount": len(release["gameAssets"]),
            "pck": {"bytes": pck["bytes"], "sha256": pck["sha256"]}}


def verify_archive_identity(archive_path, image_id, source):
    """Bind the saved Docker archive to the image inspected before saving."""
    require(isinstance(image_id, str) and image_id.startswith("sha256:")
            and SHA256.fullmatch(image_id[7:]) is not None, "Invalid image ID")
    found = None
    expanded = 0
    with tarfile.open(archive_path, "r|gz") as archive:
        for member in archive:
            expanded += member.size
            require(expanded <= 6 * 1024**3, "Image archive exceeds expanded size limit")
            if member.name != "manifest.json":
                continue
            require(found is None and member.isfile() and member.size <= 1024 * 1024,
                    "Invalid Docker image archive manifest")
            found = json.load(archive.extractfile(member))
    require(isinstance(found, list) and len(found) == 1
            and isinstance(found[0], dict)
            and found[0].get("Config") == image_id[7:] + ".json"
            and f"jalasmara:ci-{source}" in found[0].get("RepoTags", []),
            "Saved image ID or source tag differs from inspected OCI image")


def seal_image(bundle, proof_path, archive, output, source):
    release = release_manifest(bundle, source)
    runtime_manifest(bundle, source, release)
    proof = read_json(proof_path)
    pck = next(asset for asset in release["gameAssets"] if asset["name"] == "index.pck")
    require(proof.get("source") == source and proof.get("schemaVersion") == 1
            and proof.get("contextSha256") == release["context"]["sha256"]
            and proof.get("runtimeManifestSha256") == sha256(bundle / "runtime-files.json")
            and proof.get("pck") == {"bytes": pck["bytes"], "sha256": pck["sha256"]}
            and proof.get("platform") == "linux/amd64", "Image proof differs from CI release")
    regular_file(archive)
    require(archive.name == "image.tar.gz" and 0 < archive.stat().st_size <= 8 * 1024**3,
            "Invalid compressed image archive")
    verify_archive_identity(archive, proof["imageId"], source)
    manifest = {"schemaVersion": 1, "source": source, "imageId": proof["imageId"],
                "platform": proof["platform"], "contextSha256": proof["contextSha256"],
                "releaseManifestSha256": sha256(bundle / "manifest.json"),
                "runtimeManifestSha256": proof["runtimeManifestSha256"],
                "imageProofSha256": sha256(proof_path),
                "pck": proof["pck"],
                "archive": {"name": archive.name, "bytes": archive.stat().st_size,
                            "sha256": sha256(archive)}}
    output.write_text(json.dumps(manifest, indent=2) + "\n")
    return manifest


def verify_bundle(directory, source):
    manifest = read_json(directory / "oci-manifest.json")
    require(manifest.get("schemaVersion") == 1 and manifest.get("source") == source,
            "OCI artifact source differs from requested commit")
    require(manifest.get("platform") == "linux/amd64", "Unexpected OCI platform")
    image_id = manifest.get("imageId")
    require(isinstance(image_id, str) and image_id.startswith("sha256:")
            and SHA256.fullmatch(image_id[7:]) is not None, "Invalid OCI image ID")
    release = (release_manifest(directory, source) if (directory / "context.tar").exists()
               else validate_release_metadata(read_json(directory / "release-manifest.json"), source))
    if (directory / "context.tar").exists():
        release_path = directory / "manifest.json"
    else:
        release_path = directory / "release-manifest.json"
        require(release.get("source") == source
                and release.get("declaredExportSource") == source,
                "Copied release manifest has different source")
    require(sha256(release_path) == manifest.get("releaseManifestSha256"),
            "Release manifest SHA-256 differs from OCI artifact")
    require(release.get("context", {}).get("sha256") == manifest.get("contextSha256"),
            "Release context SHA-256 differs from OCI artifact")
    runtime = read_json(directory / "runtime-files.json")
    require(runtime.get("source") == source
            and sha256(directory / "runtime-files.json") == manifest.get("runtimeManifestSha256"),
            "Compiled runtime manifest differs from OCI artifact")
    runtime_manifest(directory, source, release)
    proof_path = directory / "image-proof.json"
    require(sha256(proof_path) == manifest.get("imageProofSha256"),
            "Image proof SHA-256 differs from OCI artifact")
    proof = read_json(proof_path)
    require(proof.get("source") == source and proof.get("imageId") == image_id
            and proof.get("contextSha256") == manifest["contextSha256"]
            and proof.get("runtimeManifestSha256") == manifest["runtimeManifestSha256"]
            and proof.get("pck") == manifest.get("pck"),
            "Image proof differs from OCI artifact")
    pck = next((asset for asset in release.get("gameAssets", [])
                if asset.get("name") == "index.pck"), None)
    require(pck is not None and manifest.get("pck") == {"bytes": pck["bytes"],
            "sha256": pck["sha256"]}, "PCK identity differs from OCI artifact")
    archive = manifest.get("archive")
    require(isinstance(archive, dict) and archive.get("name") == "image.tar.gz",
            "Invalid OCI archive record")
    verify_record(directory / "image.tar.gz", archive)
    verify_archive_identity(directory / "image.tar.gz", image_id, source)
    return manifest


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    record = commands.add_parser("record-runtime")
    record.add_argument("--repo", type=Path, required=True)
    record.add_argument("--output", type=Path, required=True)
    prepare = commands.add_parser("prepare")
    prepare.add_argument("--bundle", type=Path, required=True)
    prepare.add_argument("--output", type=Path, required=True)
    inspect = commands.add_parser("verify-image")
    inspect.add_argument("--bundle", type=Path, required=True)
    inspect.add_argument("--image", required=True)
    inspect.add_argument("--output", type=Path, required=True)
    seal = commands.add_parser("seal")
    seal.add_argument("--bundle", type=Path, required=True)
    seal.add_argument("--proof", type=Path, required=True)
    seal.add_argument("--archive", type=Path, required=True)
    seal.add_argument("--output", type=Path, required=True)
    check = commands.add_parser("verify-bundle")
    check.add_argument("--directory", type=Path, required=True)
    for command in (record, prepare, inspect, seal, check):
        command.add_argument("--source", required=True)
    args = parser.parse_args()
    if args.command == "record-runtime":
        result = write_runtime_manifest(args.repo, args.output, args.source)
    elif args.command == "prepare":
        result = prepare_context(args.bundle, args.output, args.source)
    elif args.command == "verify-image":
        result = verify_image(args.image, args.bundle, args.source)
        args.output.write_text(json.dumps(result, indent=2) + "\n")
    elif args.command == "seal":
        result = seal_image(args.bundle, args.proof, args.archive, args.output, args.source)
    else:
        result = verify_bundle(args.directory, args.source)
    print(json.dumps({"command": args.command, "source": args.source,
                      "result": result if args.command == "verify-bundle" else "ok"}))


if __name__ == "__main__":
    main()
