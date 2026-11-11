#!/usr/bin/env python3
"""Float32 replay of a captured original shoe corner at the authored dock crest."""
import argparse
import json
import math
from pathlib import Path

import numpy as np
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
    side = contacts["swingSide"]
    foot = contacts["feet"][side]
    prior = run["recentTrace"][-2]["pose"]
    previous = prior["contacts"]["feet"][side]
    switch = foot["viewRotationPivot"]
    data = json.loads((root / "client-godot/resources/art/player-lower-body/male-nusantara-daily-v1.json").read_text())
    image = Image.open(root / "client-godot" / data["source"].removeprefix("res://")).convert("RGBA")
    leg = data["views"][switch["nextDirection"]]["legs"][side]
    rect = leg["parts"]["foot"]
    ankle = [leg["ankle"][i] - rect[i] for i in range(2)]
    radius = max(math.hypot(x - ankle[0], (y - ankle[1]) * prior["calibration"])
                 for x, y in [(0, 0), (rect[2], 0), (0, rect[3]), (rect[2], rect[3])])
    original_q = previous["footPlane"]["rotation"]
    angle = 2 * math.acos(original_q[3])
    allowance = contacts["acceptedDistance"] - prior["contacts"]["acceptedDistance"]
    next_angle = max(0, angle - allowance / radius)
    factor = math.sin(next_angle / 2) / math.sin(angle / 2)
    q = [v * factor for v in original_q[:3]] + [math.cos(next_angle / 2)]
    old_view = data["views"][switch["previousDirection"]]
    leg = old_view["legs"][side]
    rect = leg["parts"]["foot"]
    ankle = [leg["ankle"][i] - rect[i] for i in range(2)]
    pixels = set(tuple(p) for p in leg["soleEdgePixels"])
    for y in range(rect[3]):
        for x in range(rect[2]):
            if image.getpixel((old_view["sourceColumn"] * 128 + rect[0] + x, rect[1] + y))[3] >= 128:
                pixels.update([(x, y), (x + 1, y), (x + 1, y + 1), (x, y + 1)])
    hub = json.loads(args.world.read_text())["landMaps"]["hub"]
    ramp = next(row for row in hub["stairs"] if row["id"] == "dock_gangway")
    levels = {row["id"]: row["elevation"] * 48 for row in hub["terraces"]}
    low, high = levels[ramp["from"]], levels[ramp["to"]]
    a, b = ramp["path"]
    assert a[0] == b[0] and a[1] > b[1]

    def ground(point):
        x, y = map(float, point)
        z = low + (high - low) * min(1, max(0, (a[1] - y) / (a[1] - b[1])))
        return np.array([x, -y / math.cos(math.radians(55)) - z * math.tan(math.radians(55)), z], dtype=np.float32)

    def inverse(world, damped):
        point = np.array(vector(foot["logical"]), dtype=np.float32)
        trace = []
        for iteration in range(8):
            floor = ground(point)
            error = world[:2] - floor[:2]
            norm = float(np.linalg.norm(error))
            trace.append({"logical": point.tolist(), "residual": norm})
            if norm < .005:
                return True, trace
            x = ground(point + np.array([.125, 0], dtype=np.float32)) - floor
            y = ground(point + np.array([0, .125], dtype=np.float32)) - floor
            determinant = x[0] * y[1] - y[0] * x[1]
            if abs(determinant) < .000001:
                break
            step = np.array([(error[0] * y[1] - y[0] * error[1]) / determinant,
                             (x[0] * error[1] - error[0] * x[1]) / determinant], dtype=np.float32)
            step *= min(1, 128 / float(np.linalg.norm(step))) * .125
            if not damped:
                point += step
                continue
            for backtrack in range(9):
                candidate = point + step
                if float(np.linalg.norm(world[:2] - ground(candidate)[:2])) < norm:
                    point = candidate
                    break
                step *= .5
            else:
                break
        return False, trace

    right = (math.sqrt(.5), -math.sqrt(.5), 0)
    failures = []
    maximum = 0
    for pixel in sorted(pixels):
        local = add(tuple(v * (pixel[0] - ankle[0]) for v in right), (0, 0, prior["calibration"]), ankle[1] - pixel[1])
        offset = add(local, cross(q[:3], add(cross(q[:3], local), local, q[3])), 2)
        world = np.array(add(foot["rotationAnchorWorld"], offset), dtype=np.float32)
        assert abs(float(world[0]) - a[0]) < ramp["width"] / 2
        old_ok, old_trace = inverse(world, False)
        new_ok, new_trace = inverse(world, True)
        assert new_ok
        maximum = max(maximum, len(new_trace))
        if not old_ok:
            failures.append({"pixel": pixel, "world": world.tolist(), "old": old_trace, "damped": new_trace})
    assert failures
    result = {"scope": "Captured old-shoe mask at candidate Q over continuous authored dock crest; not general inverse or runtime proof",
              "source": str(args.rejected), "candidateRotation": q, "originalMaskPoints": len(pixels),
              "iterationLimitUnchanged": 8, "residualToleranceUnchanged": .005, "dampedMaximumObservations": maximum,
              "oldFailedCorners": failures, "newAllCornersPass": True}
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, indent=2) + "\n")
    print("RAMP INVERSE MODEL: captured float32 crest oscillation rejects old solver; all original corners pass error-decreasing steps")


if __name__ == "__main__":
    main()
