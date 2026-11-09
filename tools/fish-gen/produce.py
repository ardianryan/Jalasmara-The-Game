"""Reproduce the bounded Fish Gen pilot from the pinned upstream source."""
import argparse
import hashlib
import importlib.metadata
import json
import os
from pathlib import Path
import subprocess
import sys

PIN = "0faa79003ca50a7d422b618cb59179d9834094f1"
STEM = "clownfish_48x32_1519"
DEPENDENCIES = {"numpy": "2.2.6", "Pillow": "11.3.0"}


def produce(source: Path, output: Path) -> dict:
    source = source.resolve(strict=True)
    revision = subprocess.check_output(
        ["git", "-C", str(source), "rev-parse", "HEAD"], text=True
    ).strip()
    if revision != PIN:
        raise ValueError("Fish Gen checkout does not match the reviewed pin")
    if subprocess.check_output(
        ["git", "-C", str(source), "status", "--porcelain", "--untracked-files=no"], text=True
    ).strip():
        raise ValueError("Fish Gen source has modified tracked files")
    versions = {name: importlib.metadata.version(name) for name in DEPENDENCIES}
    if versions != DEPENDENCIES:
        raise ValueError("Install the exact dependencies from requirements.txt")
    output.mkdir(parents=True, exist_ok=True)
    if any((output / (STEM + suffix)).exists() for suffix in [".png", ".json"]):
        raise FileExistsError("Choose a fresh output directory; existing artwork is preserved")
    args = [
        "-m", "fishgen", "generate", "--species", "Clownfish", "--seed", "1519",
        "--size", "48x32", "--style", "pixel", "--colors", "18",
        "--swim-frames", "8", "--turn-frames", "8", "--smoothness", "1",
        "--fps", "10", "--pitch", "0.25", "--formats", "sheet,godot", "--flat",
        "--out", str(output.resolve()),
    ]
    env = {**os.environ, "PYTHONPATH": str(source), "FISHGEN_NO_NATIVE": "1"}
    subprocess.run([sys.executable, *args], env=env, check=True, timeout=120)
    records = {}
    for suffix in [".png", ".json", ".tres"]:
        p = output / (STEM + suffix)
        records[p.name] = {"bytes": p.stat().st_size, "sha256": hashlib.sha256(p.read_bytes()).hexdigest()}
    result = {
        "generator": "Fish Gen", "upstream": "https://github.com/JacobKulberg/fish-gen",
        "revision": PIN, "python": ".".join(map(str, sys.version_info[:3])),
        "dependencies": versions, "nativeCompiler": False, "arguments": args[:-1] + ["<output>"],
        "license": "MIT software; generated sprites permitted for commercial use by pinned README",
        "files": records,
    }
    (output / "provenance.json").write_text(json.dumps(result, indent=2) + "\n")
    return result


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--out", type=Path, required=True)
    opts = parser.parse_args()
    print(json.dumps(produce(opts.source, opts.out), indent=2))
