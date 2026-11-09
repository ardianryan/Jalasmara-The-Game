import gzip
import hashlib
import json
from pathlib import Path
import runpy
import subprocess
import tarfile
import tempfile
import unittest


API = runpy.run_path(str(Path(__file__).with_name("package-web-release.py")))


class ReleasePackageTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        self.output = self.root / "bundle"
        for scope in API["SCOPES"]:
            path = self.root / scope
            if scope in {"apps", "packages"}:
                path /= "source.txt"
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text("tracked source\n")
        self.git("init", "-q")
        self.git("add", ".")
        self.git("-c", "user.name=Fixture", "-c", "user.email=fixture@test.invalid",
                 "commit", "-qm", "fixture")
        self.game = self.root / "apps/web/public/game"
        self.game.mkdir(parents=True)
        for name, content in {"index.html": b"html", "index.js": b"loader",
                              "index.wasm": b"wasm", "index.pck": b"pck"}.items():
            (self.game / name).write_bytes(content)
        (self.game / "index.wasm.gz").write_bytes(gzip.compress(b"wasm"))
        digest = hashlib.sha256(b"pck").hexdigest()
        self.manifest = {"version": 1, "bytes": 3, "sha256": digest,
                         "partSize": 1024 * 1024, "hashes": [digest]}
        self.write_manifest()

    def tearDown(self):
        self.temporary.cleanup()

    def git(self, *args):
        subprocess.run(["git", *args], cwd=self.root, check=True,
                       stdout=subprocess.PIPE, stderr=subprocess.PIPE)

    def write_manifest(self):
        (self.game / "pck-manifest.json").write_text(json.dumps(self.manifest))

    def test_reused_wasm_is_omitted_and_both_hashes_required(self):
        (self.root / ".env").write_text("fixture sentinel, never package\n")
        result = API["package"](self.root, self.output, True)
        with tarfile.open(self.output / "context.tar") as context:
            names = context.getnames()
        self.assertIn("apps/web/public/game/index.pck", names)
        self.assertNotIn("apps/web/public/game/index.wasm", names)
        self.assertFalse(any(".env" in name or "node_modules" in name for name in names))
        self.assertEqual({x["name"] for x in result["requiredReusedAssets"]},
                         {"index.wasm", "index.wasm.gz"})
        self.assertEqual(result["context"]["sha256"], API["sha256"](self.output / "context.tar"))

    def test_stale_part_manifest_rejected_before_output(self):
        self.manifest["hashes"] = ["0" * 64]
        self.write_manifest()
        with self.assertRaisesRegex(ValueError, "part hashes"):
            API["package"](self.root, self.output)
        self.assertFalse(self.output.exists())

    def test_secret_filename_and_symlink_in_export_rejected(self):
        secret = self.game / ".env"
        secret.write_text("fixture sentinel")
        with self.assertRaisesRegex(ValueError, "Unexpected file"):
            API["asset_records"](self.game)
        secret.unlink()
        (self.game / "index.wasm").unlink()
        (self.game / "index.wasm").symlink_to(self.root / "Dockerfile")
        with self.assertRaisesRegex(ValueError, "regular game asset"):
            API["asset_records"](self.game)

    def test_tracked_env_and_dirty_source_are_rejected(self):
        secret = self.root / "apps/.env"
        secret.write_text("fixture sentinel")
        self.git("add", "apps/.env")
        self.git("-c", "user.name=Fixture", "-c", "user.email=fixture@test.invalid",
                 "commit", "-qm", "unsafe fixture")
        with self.assertRaisesRegex(ValueError, "secret-bearing"):
            API["package"](self.root, self.output)
        (self.root / "apps/source.txt").write_text("uncommitted change")
        with self.assertRaises(subprocess.CalledProcessError):
            API["package"](self.root, self.output)

    def test_wrong_gzip_and_existing_output_are_rejected(self):
        (self.game / "index.wasm.gz").write_bytes(gzip.compress(b"bad!"))
        with self.assertRaisesRegex(ValueError, "does not match"):
            API["asset_records"](self.game)
        self.output.mkdir()
        sentinel = self.output / "preserve.txt"
        sentinel.write_text("evidence")
        with self.assertRaisesRegex(ValueError, "Output already exists"):
            API["package"](self.root, self.output)
        self.assertEqual(sentinel.read_text(), "evidence")


if __name__ == "__main__":
    unittest.main()
