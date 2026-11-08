#!/usr/bin/env python3
"""Run the pinned, unmodified Kiln Studio GLB checker without installing its agent plugin."""
import argparse
import hashlib
import json
from pathlib import Path
import sys
from urllib.request import urlopen

ROOT = Path(__file__).resolve().parents[2]
SOURCE = json.loads((Path(__file__).parent / "source.json").read_text())
CACHE = ROOT / ".runtime/blender-kiln-source"
CACHE.mkdir(parents=True, exist_ok=True)
for name, entry in SOURCE["files"].items():
    target = CACHE / name
    if not target.is_file():
        url = "https://raw.githubusercontent.com/elithril/blender-kiln/" + SOURCE["revision"] + "/" + entry["path"]
        with urlopen(url, timeout=30) as response:
            content = response.read()
        if hashlib.sha256(content).hexdigest() != entry["sha256"]:
            raise RuntimeError("Pinned upstream source hash mismatch: " + name)
        target.write_bytes(content)
    if hashlib.sha256(target.read_bytes()).hexdigest() != entry["sha256"]:
        raise RuntimeError("Cached upstream source hash mismatch: " + name)
sys.path.insert(0, str(CACHE))
import checks  # Import only after verifying the pinned source hashes.
import studiolib

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("files", nargs="*", type=Path)
parser.add_argument("--output", type=Path, default=ROOT / ".runtime/kiln-asset-checks.json")
args = parser.parse_args()
args.output = args.output.resolve()
files = args.files or sorted((ROOT / "client-godot/resources/models").glob("*.glb"))
assert files, "No GLB files supplied"
project = studiolib.Project(ROOT)
reports = []
for candidate in files:
    path = candidate.resolve()
    relative = path.relative_to(ROOT).as_posix()
    assert path.suffix.lower() == ".glb" and path.is_file(), "Expected an existing project GLB"
    stat = path.stat()
    variant = studiolib.Variant("glb", path, relative, stat.st_size, stat.st_mtime)
    asset = studiolib.Asset(relative, path.stem, path.parent.relative_to(ROOT).as_posix(), False, [variant], [])
    stats = studiolib.variant_stats(variant)
    assert stats and "error" not in stats and stats["tris"] > 0, "Invalid GLB geometry: " + relative
    findings = checks.health(project, asset, variant, {"config": {"target": "web", "tier": "lightweight", "type": "prop"}, "sections": {}})
    reports.append({"file": relative, "sha256": hashlib.sha256(path.read_bytes()).hexdigest(), "stats": stats, "checks": findings})
    print(relative + ": " + str(stats["tris"]) + " triangles, " + str(sum(item["level"] == "warn" for item in findings)) + " upstream advisory warnings")
args.output.parent.mkdir(parents=True, exist_ok=True)
args.output.write_text(json.dumps({"upstream": SOURCE, "scope": "Original Kiln advisory findings are retained. Godot imports source GLBs offline; browser download packing is assessed separately. No geometry was generated or rewritten by this check.", "assets": reports}, indent=2) + "\n")
report_name = args.output.relative_to(ROOT) if ROOT in args.output.parents else args.output
print("PASS actual pinned Kiln inspection: " + str(len(reports)) + " readable GLBs; report " + str(report_name))
