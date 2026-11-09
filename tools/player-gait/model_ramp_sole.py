#!/usr/bin/env python3
"""Check original foot geometry under a rigid ramp-plane rotation; no runtime proof."""
import argparse
import json
import math
from pathlib import Path


def dot(a, b):
    return sum(x * y for x, y in zip(a, b))


def cross(a, b):
    return (a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0])


def unit(v):
    return tuple(x / math.hypot(*v) for x in v)


def add(a, b, factor=1):
    return tuple(x + factor * y for x, y in zip(a, b))


def vector(value):
    return tuple(map(float, value.strip("()").split(","))) if isinstance(value, str) else tuple(value)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--world", type=Path, required=True)
    parser.add_argument("--rejected", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[2]
    hub = json.loads(args.world.read_text())["landMaps"]["hub"]
    ramp = next(p for p in hub["stairs"] if p["id"] == "dock_gangway")
    levels = {t["id"]: t["elevation"] * 48 for t in hub["terraces"]}
    tilt = math.radians(55)
    world = lambda p, h: (p[0], -p[1] / math.cos(tilt) - h * math.tan(tilt), h)
    a, b = (world(ramp["path"][i], levels[ramp[k]]) for i, k in enumerate(["from", "to"]))
    along = add(b, a, -1)
    normal = unit(cross((1, 0, 0), along))
    if normal[2] < 0:
        normal = tuple(-v for v in normal)
    right = (math.sqrt(.5), -math.sqrt(.5), 0)
    support = unit(add(right, normal, -dot(right, normal)))
    angle = math.acos(dot(right, support))
    axis = unit(cross(right, support))

    def rotate(v, theta=angle):
        return tuple(v[i] * math.cos(theta) + cross(axis, v)[i] * math.sin(theta)
                     + axis[i] * dot(axis, v) * (1 - math.cos(theta)) for i in range(3))

    up = (0, 0, 1 / math.cos(math.radians(35)))
    rows = []
    for outfit in ["daily", "explorer"]:
        data = json.loads((root / f"client-godot/resources/art/player-lower-body/male-nusantara-{outfit}-v1.json").read_text())
        for direction, view in data["views"].items():
            for side, leg in view["legs"].items():
                rect, sole = leg["parts"]["foot"], leg["solePixel"]
                ankle = [leg["ankle"][0] - rect[0], leg["ankle"][1] - rect[1]]
                local = lambda p: add(tuple(v * (p[0] - sole[0]) for v in right), up, sole[1] - p[1])
                old_offset = local(ankle)
                new_offset = rotate(old_offset)
                correction = add(old_offset, new_offset, -1)
                assert math.dist(add(correction, new_offset), old_offset) < 1e-12
                assert abs(math.hypot(*new_offset) - math.hypot(*old_offset)) < 1e-12
                edges = [local(p) for p in leg["soleEdgePixels"]]
                turned = list(map(rotate, edges))
                assert all(abs(dot(p, normal)) < 1e-12 for p in turned)
                assert abs(math.dist(*turned) - math.dist(*edges)) < 1e-12
                corners = [local(p) for p in [[0, 0], [rect[2], 0], [0, rect[3]], [rect[2], rect[3]]]]
                radius = max(math.dist(p, old_offset) for p in corners)
                # R*theta bounds each source corner's motion about the actual ankle.
                step = .1 / radius
                assert max(math.dist(p, rotate(p, step)) for p in [add(q, old_offset, -1) for q in corners]) <= .1 + 1e-12
                rows.append({"outfit": outfit, "direction": direction, "side": side,
                             "originalSoleWidth": math.dist(*edges), "ankleSoleCorrection": correction,
                             "maximumQuadRadiusAboutAnkle": radius})
    rejected = json.loads(args.rejected.read_text())
    entry = rejected["pose"]["contacts"]["feet"]["left"]
    daily = json.loads((root / "client-godot/resources/art/player-lower-body/male-nusantara-daily-v1.json").read_text())
    leg = daily["views"][entry["footDirection"]]["legs"]["left"]
    original_edges = []
    for p in leg["soleEdgePixels"]:
        point = add(vector(entry["sole"]), right, p[0] - leg["solePixel"][0])
        plane_z = a[2] - (normal[0] * (point[0] - a[0]) + normal[1] * (point[1] - a[1])) / normal[2]
        original_edges.append({"pixel": p, "globalVertex": point, "inclineHeight": plane_z,
                               "penetration": plane_z - point[2]})
    result = {"scope": "CPU original-pixel rigid geometry only; not a gait or runtime acceptance",
              "normalFromAuthoredTreadPlane": normal, "supportAxis": support,
              "rotationDegrees": math.degrees(angle), "rotationAxis": axis,
              "originalFailure": rejected["message"], "originalGlobalOpaqueEdges": original_edges,
              "originalFootChecks": rows,
              "notProven": ["airborne support clearance", "ankle continuity across moving rig",
                            "same-source flat/stair/ramp matrix", "native appearance or natural gait"]}
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, indent=2) + "\n")
    print(f"RIGID SOLE MODEL: {len(rows)} original feet preserve lengths/plane support; runtime pending")


if __name__ == "__main__":
    main()
