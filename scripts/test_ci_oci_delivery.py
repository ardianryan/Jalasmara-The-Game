#!/usr/bin/env python3
"""CPU checks for the SHA-bound CI image handoff."""

import hashlib
import io
import json
from pathlib import Path
import shutil
import subprocess
import sys
import tarfile
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).parent))
import ci_oci_delivery as delivery


SOURCE = "a" * 40


def digest(data):
    return hashlib.sha256(data).hexdigest()


class ImageDeliveryTests(unittest.TestCase):
    def setUp(self):
        self.scratch = tempfile.TemporaryDirectory()
        self.addCleanup(self.scratch.cleanup)
        self.root = Path(self.scratch.name)
        self.bundle = self.root / "bundle"
        self.bundle.mkdir()
        self.context = self.root / "context-source"
        self.context.mkdir()
        files = {
            "Dockerfile": b"FROM scratch\n",
            "package.json": b"{}\n",
            "package-lock.json": b"{}\n",
            "apps/api/package.json": b"{}\n",
            "apps/web/package.json": b"{}\n",
            "apps/web/public/game/index.html": b"<html></html>",
            "apps/web/public/game/index.js": b"godot-loader",
            "apps/web/public/game/index.wasm": b"wasm",
            "apps/web/public/game/index.pck": b"one-part-pck",
        }
        pck = files["apps/web/public/game/index.pck"]
        files["apps/web/public/game/pck-manifest.json"] = json.dumps({
            "version": 1, "sha256": digest(pck), "bytes": len(pck),
            "partSize": 1024 * 1024, "hashes": [digest(pck)]}).encode()
        for name, data in files.items():
            path = self.context / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(data)
        self.repo = self.root / "compiled"
        for name, data in {
            "apps/api/dist/apps/api/src/index.js": b"compiled-api",
            "apps/web/dist/index.html": b"compiled-web",
            **{name.replace("apps/web/public/game/", "apps/web/dist/game/"): data
               for name, data in files.items() if name.startswith("apps/web/public/game/")},
            "apps/web/dist/game/.gitkeep": b"",
        }.items():
            path = self.repo / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(data)
        with tarfile.open(self.bundle / "context.tar", "w") as archive:
            for item in sorted(self.context.rglob("*")):
                archive.add(item, arcname=item.relative_to(self.context).as_posix(),
                            recursive=False)
        game = self.context / "apps/web/public/game"
        assets = [{"name": path.name, "bytes": path.stat().st_size,
                   "sha256": delivery.sha256(path)} for path in sorted(game.iterdir())]
        release = {"schemaVersion": 1, "source": SOURCE,
                   "declaredExportSource": SOURCE,
                   "context": {"name": "context.tar",
                               "bytes": (self.bundle / "context.tar").stat().st_size,
                               "sha256": delivery.sha256(self.bundle / "context.tar")},
                   "gameAssets": assets, "requiredReusedAssets": []}
        (self.bundle / "manifest.json").write_text(json.dumps(release))
        delivery.write_runtime_manifest(self.repo, self.bundle / "runtime-files.json", SOURCE)

    def test_prepare_accepts_exact_context_and_omits_placeholder(self):
        snapshot = delivery.runtime_manifest(self.bundle, SOURCE,
                                             delivery.release_manifest(self.bundle, SOURCE))
        self.assertNotIn("apps/web/dist/game/.gitkeep",
                         {item["name"] for item in snapshot["files"]})
        extracted = self.root / "extracted"
        delivery.prepare_context(self.bundle, extracted, SOURCE)
        self.assertEqual((extracted / "apps/web/public/game/index.pck").read_bytes(),
                         b"one-part-pck")
        with self.assertRaisesRegex(ValueError, "overwrite"):
            delivery.prepare_context(self.bundle, extracted, SOURCE)

    def test_rejects_wrong_source_and_changed_context_bytes(self):
        with self.assertRaisesRegex(ValueError, "Release source"):
            delivery.prepare_context(self.bundle, self.root / "wrong", "b" * 40)
        with (self.bundle / "context.tar").open("ab") as archive:
            archive.write(b"tamper")
        with self.assertRaisesRegex(ValueError, "Size mismatch"):
            delivery.prepare_context(self.bundle, self.root / "changed", SOURCE)

    def test_rejects_symlink_member_even_when_archive_hash_matches(self):
        context = self.bundle / "context.tar"
        replacement = self.bundle / "replacement.tar"
        with tarfile.open(context) as original, tarfile.open(replacement, "w") as target:
            for member in original.getmembers():
                target.addfile(member, original.extractfile(member) if member.isfile() else None)
            link = tarfile.TarInfo("apps/web/public/game/escape")
            link.type = tarfile.SYMTYPE
            link.linkname = "/etc/passwd"
            target.addfile(link)
        replacement.replace(context)
        release = json.loads((self.bundle / "manifest.json").read_text())
        release["context"].update(bytes=context.stat().st_size,
                                  sha256=delivery.sha256(context))
        (self.bundle / "manifest.json").write_text(json.dumps(release))
        with self.assertRaisesRegex(ValueError, "Unsafe or duplicate context member"):
            delivery.prepare_context(self.bundle, self.root / "unsafe", SOURCE)

    def test_image_check_detects_stale_api_and_wrong_label(self):
        image = {"Id": "sha256:" + "b" * 64, "Os": "linux", "Architecture": "amd64",
                 "Config": {"Labels": {"org.opencontainers.image.revision": SOURCE}}}

        def output(args, **_kwargs):
            return json.dumps([image]) if args[:3] == ["docker", "image", "inspect"] else "container-id\n"

        def run(args, **_kwargs):
            if args[1] == "cp":
                subtree = args[2].split(":/app/", 1)[1]
                shutil.copytree(self.repo / subtree, Path(args[3]))
                if subtree == "apps/api/dist":
                    (Path(args[3]) / "apps/api/src/index.js").write_text("stale-api")
            return subprocess.CompletedProcess(args, 0)

        with patch.object(delivery.subprocess, "check_output", side_effect=output), \
             patch.object(delivery.subprocess, "run", side_effect=run):
            with self.assertRaisesRegex(ValueError, "API/Web output differs"):
                delivery.verify_image("candidate", self.bundle, SOURCE)
            image["Config"]["Labels"]["org.opencontainers.image.revision"] = "c" * 40
            with self.assertRaisesRegex(ValueError, "source label differs"):
                delivery.verify_image("candidate", self.bundle, SOURCE)

    def test_sealed_image_artifact_detects_transfer_corruption(self):
        release = json.loads((self.bundle / "manifest.json").read_text())
        pck = next(item for item in release["gameAssets"] if item["name"] == "index.pck")
        proof = {"schemaVersion": 1, "source": SOURCE,
                 "imageId": "sha256:" + "b" * 64, "platform": "linux/amd64",
                 "contextSha256": release["context"]["sha256"],
                 "runtimeManifestSha256": delivery.sha256(self.bundle / "runtime-files.json"),
                 "pck": {"bytes": pck["bytes"], "sha256": pck["sha256"]}}
        proof_path = self.root / "image-proof.json"
        proof_path.write_text(json.dumps(proof))
        artifact = self.root / "artifact"
        artifact.mkdir()
        archive = artifact / "image.tar.gz"
        with tarfile.open(archive, "w:gz") as stream:
            archive_manifest = json.dumps([{
                "Config": "b" * 64 + ".json",
                "RepoTags": ["jalasmara:ci-" + SOURCE], "Layers": []}]).encode()
            member = tarfile.TarInfo("manifest.json")
            member.size = len(archive_manifest)
            stream.addfile(member, io.BytesIO(archive_manifest))
        shutil.copy2(self.bundle / "manifest.json", artifact / "release-manifest.json")
        shutil.copy2(self.bundle / "runtime-files.json", artifact / "runtime-files.json")
        shutil.copy2(proof_path, artifact / "image-proof.json")
        delivery.seal_image(self.bundle, proof_path, archive,
                            artifact / "oci-manifest.json", SOURCE)
        delivery.verify_bundle(artifact, SOURCE)
        proof["imageId"] = "sha256:" + "c" * 64
        proof_path.write_text(json.dumps(proof))
        with self.assertRaisesRegex(ValueError, "Saved image ID"):
            delivery.seal_image(self.bundle, proof_path, archive,
                                artifact / "wrong-image.json", SOURCE)
        with archive.open("ab") as stream:
            stream.write(b"changed")
        with self.assertRaisesRegex(ValueError, "Size mismatch"):
            delivery.verify_bundle(artifact, SOURCE)

    def test_modern_docker_archive_binds_oci_descriptor_to_image_id(self):
        descriptor = b'{"schemaVersion":2,"mediaType":"application/vnd.oci.image.manifest.v1+json"}'
        digest = hashlib.sha256(descriptor).hexdigest()
        archive = self.root / "modern-image.tar.gz"
        with tarfile.open(archive, "w:gz") as stream:
            items = {
                "manifest.json": json.dumps([{
                    "Config": "blobs/sha256/" + "a" * 64,
                    "RepoTags": ["jalasmara:ci-" + SOURCE], "Layers": []}]).encode(),
                "index.json": json.dumps({"schemaVersion": 2, "manifests": [{"digest": "sha256:" + digest}]}).encode(),
                "blobs/sha256/" + digest: descriptor,
            }
            for name, data in items.items():
                member = tarfile.TarInfo(name)
                member.size = len(data)
                stream.addfile(member, io.BytesIO(data))
        delivery.verify_archive_identity(archive, "sha256:" + digest, SOURCE)
        with self.assertRaisesRegex(ValueError, "OCI image digest"):
            delivery.verify_archive_identity(archive, "sha256:" + "b" * 64, SOURCE)


if __name__ == "__main__":
    unittest.main()
