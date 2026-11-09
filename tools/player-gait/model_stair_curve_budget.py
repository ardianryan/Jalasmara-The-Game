#!/usr/bin/env python3
"""CPU curve comparison; this does not execute the Godot planner or prove feet."""
import argparse
import json
import math
from pathlib import Path


def derivative(u, span, rise, distance):
    window = min(.65, max(.25, abs(rise) / (distance * 3)))
    delay = window / 2
    advance = min(1, max(0, (u - delay) / (1 - delay) if rise > 0 else u / (1 - delay)))
    elevation = min(1, max(0, u / window if rise > 0 else (u - (1 - window)) / window))
    return (span * 6 * advance * (1 - advance) / (1 - delay),
            rise * 6 * elevation * (1 - elevation) / window + math.pi * 3 * math.cos(u * math.pi))


def bound(span, rise, distance):
    peak = max(math.hypot(*derivative(i / 1024, span, rise, distance)) for i in range(1025))
    window = min(.65, max(.25, abs(rise) / (distance * 3)))
    curvature = math.hypot(6 * span / (1 - window / 2) ** 2,
                           6 * abs(rise) / window ** 2 + math.pi ** 2 * 3)
    return (peak + curvature / 2048) / distance


def duration(span, rise, minimum):
    distance = max(10, minimum)
    for _ in range(257):
        upper = bound(span, rise, distance)
        if upper <= 4.9:
            return distance, upper
        distance += .25
    raise ValueError("No curve budget within bounded search")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--world", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    hub = json.loads(args.world.read_text())["hub"]
    heights = {t["id"]: t["elevation"] * 48 for t in hub["terraces"]}
    tilt = math.radians(55)
    rows = []
    for profile in hub["stairs"]:
        if profile["type"] != "stairs":
            continue
        start, end = profile["path"]
        count = profile["steps"]
        rise = (heights[profile["to"]] - heights[profile["from"]]) / count
        # Current authored stairs are Y-aligned. This is actual mesh XY embedding,
        # not logical tread length or discontinuous Z added to player travel.
        assert start[0] == end[0]
        depth = abs(-(end[1] - start[1]) / math.cos(tilt)
                    - (heights[profile["to"]] - heights[profile["from"]]) * math.tan(tilt)) / count
        for sign in [1, -1]:
            d, upper = duration(depth * 2, rise * 2 * sign, depth)
            dense = max(math.hypot(*derivative(i / 20000, depth * 2, rise * 2 * sign, d)) / d
                        for i in range(20001))
            assert dense <= upper <= 4.9
            rows.append({"profile": profile["id"], "ascending": sign > 0,
                         "treadWorldXY": depth, "alternatingFootRise": rise * 2 * sign,
                         "steadyPerFootXY": depth * 2, "candidateDistance": d,
                         "curveOnlyDerivativeBound": upper, "denseIndependentCheck": dense,
                         "expectedNewContactHeights": [heights[profile["from"]] + rise * i for i in
                                                       (range(1, count + 1) if sign > 0 else range(count - 1, -1, -1))]})
    old = {"span": 52.3552, "rise": 36, "distance": 20}
    old["curveOnlyDerivativeBound"] = bound(old["span"], old["rise"], old["distance"])
    result = {"scope": "CPU equations and authored tread dimensions only; not runtime/native acceptance",
              "rejectedOriginalThreeRiserPath": old, "oneNewTreadPerLanding": rows,
              "notProven": ["actual foot/pivot and opaque clearance", "support reach while actor advances",
                            "contact order at runtime", "cadence or natural appearance"]}
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, indent=2) + "\n")
    print(f"STAIR CURVE MODEL: {len(rows)} authored direction cases; curve-only bounds checked, runtime pending")


if __name__ == "__main__":
    main()
