#!/usr/bin/env python3
"""Bound standalone Godot timing and reject error logs even when Godot exits0."""

import argparse
from pathlib import Path
import re
import subprocess
import sys


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--godot", required=True)
    parser.add_argument("--project-dir", default="client-godot")
    parser.add_argument("--log", required=True)
    args = parser.parse_args()
    log = Path(args.log).resolve()
    log.parent.mkdir(parents=True, exist_ok=True)
    command = [
        str(Path(args.godot).resolve()),
        "--headless",
        "--path",
        str(Path(args.project_dir).resolve()),
        "--script",
        str(Path(__file__).resolve().with_name("benchmark-ground-consumers.gd")),
    ]
    with log.open("x", encoding="utf8") as output:
        try:
            result = subprocess.run(
                command,
                stdout=output,
                stderr=subprocess.STDOUT,
                timeout=20,
                check=False,
            )
        except subprocess.TimeoutExpired:
            print(f"Benchmark exceeded20s; child stopped and reaped. Log: {log}")
            return 124
    text = log.read_text(encoding="utf8")
    if (
        result.returncode != 0
        or re.search(r"SCRIPT ERROR|^ERROR:", text, re.MULTILINE)
        or "GROUND CONSUMER BENCHMARK COMPLETE" not in text
    ):
        print(f"Benchmark failed (exit{result.returncode}); inspect {log}")
        return 1
    print(text, end="")
    return 0


if __name__ == "__main__":
    sys.exit(main())
