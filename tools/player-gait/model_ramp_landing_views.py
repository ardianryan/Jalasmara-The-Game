#!/usr/bin/env python3
"""Replay one frozen dock landing with different immutable original shoe views."""
import argparse
import json
import math
from pathlib import Path

from PIL import Image
from model_ramp_sole import add, cross, vector


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--world", type=Path, required=True)
    parser.add_argument("--rejected", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[2]
    run = json.loads(args.rejected.read_text())
    contacts = run["pose"]["contacts"]
    side, rejected = next((side, foot) for side, foot in contacts["feet"].items()
                          if not foot.get("landingGeometryValid", True))
    previous = run["recentTrace"][-2]["pose"]
    original = run["recentTrace"][0]["pose"]["contacts"]["feet"][side]["footDirection"]
    changed = previous["contacts"]["feet"][side]["footDirection"]
    q = previous["contacts"]["feet"][side]["footPlane"]["rotation"]
    data = json.loads((root / "client-godot/resources/art/player-lower-body/male-nusantara-daily-v1.json").read_text())
    image = Image.open(root / "client-godot" / data["source"].removeprefix("res://")).convert("RGBA")
    hub = json.loads(args.world.read_text())["landMaps"]["hub"]
    ramp = next(row for row in hub["stairs"] if row["id"] == "dock_gangway")
    levels = {row["id"]: row["elevation"] * 48 for row in hub["terraces"]}
    tilt = math.radians(55)
    endpoints = [(-ramp["path"][i][1] / math.cos(tilt) - levels[ramp[k]] * math.tan(tilt), levels[ramp[k]])
                 for i, k in enumerate(["from", "to"])]
    center = vector(rejected["toWorld"])
    right = (math.sqrt(.5), -math.sqrt(.5), 0)

    def ground_height(y):
        (a, low), (b, high) = endpoints
        return low + (high - low) * min(1, max(0, (y - a) / (b - a)))

    results = []
    for direction in [original, changed]:
        view = data["views"][direction]
        leg = view["legs"][side]
        rect, sole = leg["parts"]["foot"], leg["solePixel"]
        pixels = set()
        for y in range(rect[3]):
            for x in range(rect[2]):
                if image.getpixel((view["sourceColumn"] * 128 + rect[0] + x, rect[1] + y))[3] >= 128:
                    pixels.update([(x, y), (x + 1, y), (x + 1, y + 1), (x, y + 1)])
        rows = []
        for x, y in pixels:
            value = add(tuple(v * (x - sole[0]) for v in right), (0, 0, previous["calibration"]), sole[1] - y)
            offset = add(value, cross(q[:3], add(cross(q[:3], value), value, q[3])), 2)
            world = add(center, offset)
            assert abs(world[0] - ramp["path"][0][0]) < ramp["width"] / 2
            rows.append({"pixel": [x, y], "world": world, "ground": ground_height(world[1]),
                         "gap": world[2] - ground_height(world[1]), "bottom": abs(y - sole[1]) < .0001})
        worst_bottom = max((row for row in rows if row["bottom"]), key=lambda row: abs(row["gap"]))
        minimum = min(rows, key=lambda row: row["gap"])
        results.append({"direction": direction, "originalAlphaCorners": len(rows), "worstBottom": worst_bottom,
                        "minimumGap": minimum["gap"], "validHeight": minimum["gap"] >= -.02 and abs(worst_bottom["gap"]) <= .02})
    assert results[0]["validHeight"] and not results[1]["validHeight"]
    assert center == vector(previous["contacts"]["feet"][side]["toWorld"])
    result = {"scope": "Frozen original-alpha landing across the dock crest only; no runtime, legal-floor or full gait acceptance",
              "source": str(args.rejected), "side": side, "fixedTargetWorld": center, "rotation": q,
              "existingContactTolerance": .02, "sourceViewComparisons": results,
              "capturedPhysicsSecondsPerObservation": contacts["visualSettlement"]["rawSeconds"],
              "notProven": ["eventual facing recovery", "live ankle continuity", "other terrain or outfits", "native walking"]}
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, indent=2) + "\n")
    print("RAMP LANDING VIEW MODEL: original landing valid, changed original mask invalid at identical frozen target")


if __name__ == "__main__":
    main()
