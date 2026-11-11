#!/usr/bin/env python3
"""CPU comparison of one captured dock crest; not a Godot or general floor proof."""
import argparse
import json
import math
from pathlib import Path


def vector(value):
    return tuple(map(float, value.strip("()").split(",")))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--world", type=Path, required=True)
    parser.add_argument("--rejected", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    hub = json.loads(args.world.read_text())["landMaps"]["hub"]
    ramp = next(row for row in hub["stairs"] if row["id"] == "dock_gangway")
    heights = {row["id"]: row["elevation"] * 48 for row in hub["terraces"]}
    first, last = ramp["path"]
    assert first[0] == last[0] and first[1] > last[1]
    low, high = heights[ramp["from"]], heights[ramp["to"]]
    tilt = math.radians(55)
    def ground(point):
        fraction = min(1, max(0, (first[1] - point[1]) / (first[1] - last[1])))
        z = low + (high - low) * fraction
        return (point[0], -point[1] / math.cos(tilt) - z * math.tan(tilt), z)
    rejected = json.loads(args.rejected.read_text())
    contacts = rejected["pose"]["contacts"]
    foot = contacts["feet"]["right"]
    origin, target = vector(foot["from"]), vector(foot["to"])
    assert all(abs(point[0] - first[0]) < ramp["width"] / 2 for point in [origin, target])
    fractions = [0, 1]
    for y in [first[1], last[1]]:
        t = (y - origin[1]) / (target[1] - origin[1])
        if 0 < t < 1:
            fractions.append(t)
    fractions.sort()
    knots = [ground(tuple(origin[j] + (target[j] - origin[j]) * t for j in range(2))) for t in fractions]
    lengths = [math.dist(a[:2], b[:2]) for a, b in zip(knots, knots[1:])]
    total = sum(lengths)
    offset = vector(foot["fromWorld"])[2] - knots[0][2]
    effective = max([abs(offset)] + [abs((b[2] - a[2]) / length * total - offset)
                                    for a, b, length in zip(knots, knots[1:], lengths)])
    numerator = 1.5 * math.hypot(total, effective) + math.pi * 3
    distance = max(10, contacts["landingDistance"], math.ceil(numerator / 4.9 * 4) / 4)
    upper = numerator / distance
    def path(s):
        remaining = s * total
        for index, length in enumerate(lengths):
            if remaining <= length or index == len(lengths) - 1:
                t = remaining / length
                return tuple(knots[index][j] + (knots[index + 1][j] - knots[index][j]) * t for j in range(3))
            remaining -= length
    def pose(u):
        s = u * u * (3 - 2 * u)
        p = path(s)
        return (*p[:2], p[2] + offset * (1 - s) + 3 * math.sin(math.pi * u))
    samples = [pose(index / 20000) for index in range(20001)]
    dense = max(math.dist(a, b) * 20000 / distance for a, b in zip(samples, samples[1:]))
    assert dense <= upper <= 4.9
    u = contacts["swingDistance"] / contacts["landingDistance"]
    actual_raw = vector(foot["sole"])[2] - foot["pivotCorrectionWorld"][2]
    proposed = pose(u)
    assert proposed[2] > actual_raw
    result = {"scope": "Captured dock crest, real authored ramp and adjoining same-level floors only; no runtime/opaque/body acceptance",
              "source": str(args.rejected), "actualGroundKnots": knots, "pathWorldXY": total,
              "fromRawGroundOffset": offset, "distance": distance, "curveSpeedUpper": upper,
              "denseIndependentXYZSpeed": dense, "capturedPhase": u, "capturedRawHeight": actual_raw,
              "proposedRawWorldAtSamePhase": proposed, "increaseFromFollowingActualSupport": proposed[2] - actual_raw,
              "notProven": ["actual whole-foot clearance and Q backtracking", "pivot/body/ankle continuity", "full terrain/flat/native gait"]}
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, indent=2) + "\n")
    print("RAMP PROFILE MODEL: real crest knots + 20,001 dense XYZ samples within geometry-derived bound; runtime pending")


if __name__ == "__main__":
    main()
