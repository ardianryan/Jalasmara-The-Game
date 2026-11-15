#!/usr/bin/env python3
"""Reject alternate resident views that lose most of their source pixel detail.

This is an authoring gate, not a substitute for native-size visual review.
Run after generating side/rear strips; a nonzero exit means they must not be
selected by the runtime or delivered to staging.
"""

import argparse
import json
from pathlib import Path

from PIL import Image


DEFAULT_DIR = Path(__file__).resolve().parents[2] / "client-godot/resources/art/npc-simple-steps-v1"
CELL = 64
MIN_DETAIL_RATIO = 0.35
MIN_HEIGHT_RATIO = 0.85
MAX_HEIGHT_RATIO = 1.15
MIN_REAR_FRAME_CHANGE = 40


def measures(image):
    pixels = [rgba for rgba in image.getdata() if rgba[3] >= 160]
    colours = {(r // 16, g // 16, b // 16) for r, g, b, _ in pixels}
    bounds = image.getchannel("A").point(lambda alpha: 255 if alpha >= 160 else 0).getbbox()
    return len(colours), (bounds[3] - bounds[1]) if bounds else 0


def audit(directory):
    manifest = json.loads((directory / "manifest.json").read_text())
    results = []
    for name, person in manifest["people"].items():
        front = Image.open(directory / person["file"]).convert("RGBA")
        for view in ("side", "rear"):
            alternate = Image.open(directory / person[view]).convert("RGBA")
            if alternate.size != front.size or front.size != (5 * CELL, CELL):
                results.append({"name": name, "view": view, "pass": False, "reason": "invalid strip dimensions"})
                continue
            detail_ratios = []
            height_ratios = []
            frames = []
            for frame in range(5):
                box = (frame * CELL, 0, (frame + 1) * CELL, CELL)
                front_frame = front.crop(box)
                alternate_frame = alternate.crop(box)
                frames.append(alternate_frame)
                front_colours, front_height = measures(front_frame)
                alternate_colours, alternate_height = measures(alternate_frame)
                detail_ratios.append(alternate_colours / max(front_colours, 1))
                height_ratios.append(alternate_height / max(front_height, 1))
            detail = min(detail_ratios)
            height = min(height_ratios)
            max_height = max(height_ratios)
            changes = [sum(a != b for a, b in zip(first.getdata(), second.getdata()))
                       for first, second in zip(frames, frames[1:])]
            passed = (detail >= MIN_DETAIL_RATIO and height >= MIN_HEIGHT_RATIO and
                      max_height <= MAX_HEIGHT_RATIO and
                      (view != "rear" or min(changes) >= MIN_REAR_FRAME_CHANGE))
            results.append({"name": name, "view": view, "pass": passed,
                            "minDetailRatio": round(detail, 3),
                            "heightRatioRange": [round(height, 3), round(max_height, 3)],
                            "minAdjacentChangedPixels": min(changes)})
    return results


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--directory", type=Path, default=DEFAULT_DIR)
    args = parser.parse_args()
    results = audit(args.directory)
    for result in results:
        print(json.dumps(result, ensure_ascii=False))
    failures = sum(not result["pass"] for result in results)
    print(f"Resident facing detail: {len(results) - failures}/{len(results)} pass; {failures} rejected")
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
