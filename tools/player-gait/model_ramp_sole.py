#!/usr/bin/env python3
"""Check original foot geometry under a rigid ramp-plane rotation; no runtime proof."""
import argparse
import json
import math
from pathlib import Path
from PIL import Image


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
    parser.add_argument("--rotation-rejected", type=Path)
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
    envelope_checks = []
    for outfit in ["daily", "explorer"]:
        data = json.loads((root / f"client-godot/resources/art/player-lower-body/male-nusantara-{outfit}-v1.json").read_text())
        source_image = Image.open(root / "client-godot" / data["source"].removeprefix("res://")).convert("RGBA")
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
                pixels = set(tuple(p) for p in leg["soleEdgePixels"])
                for y in range(rect[3]):
                    for x in range(rect[2]):
                        if source_image.getpixel((view["sourceColumn"] * 128 + rect[0] + x, rect[1] + y))[3] >= 128:
                            pixels.update([(x, y), (x + 1, y), (x + 1, y + 1), (x, y + 1)])
                ankle_xy = (1125, -2031)
                fields = {"flat": lambda x, y: 48,
                          "incline": lambda x, y: (y + 2074.70166) * 48 / (2074.70166 - 2029.92871),
                          "crest": lambda x, y: min(48, max(0, (y + 2074.70166) * 48 / (2074.70166 - 2029.92871)))}
                for fraction in [0, .5, 1]:
                    offsets = [rotate(add(local(pixel), old_offset, -1), angle * fraction) for pixel in pixels]
                    for field_name, field in fields.items():
                        required = [field(ankle_xy[0] + p[0], ankle_xy[1] + p[1]) - p[2] for p in offsets]
                        support = max(required)
                        gaps = [support - value for value in required]
                        assert min(gaps) >= -1e-12 and abs(min(gaps)) < 1e-12
                        start_height = support + 1.92587363
                        carried = start_height - support
                        assert abs((support + carried) - start_height) < 1e-12
                        envelope_checks.append({"outfit": outfit, "direction": direction, "side": side,
                                                "planeFraction": fraction, "terrain": field_name,
                                                "originalCornersAndMarkers": len(pixels), "ankleSupportHeight": support})
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
    source = root / "client-godot" / daily["source"].removeprefix("res://")
    image = Image.open(source).convert("RGBA")
    rect = leg["parts"]["foot"]
    vertices = set()
    column = daily["views"][entry["footDirection"]]["sourceColumn"]
    for y in range(rect[3]):
        for x in range(rect[2]):
            if image.getpixel((column * 128 + rect[0] + x, rect[1] + y))[3] < 128:
                continue
            vertices.update([(x, y), (x + 1, y), (x + 1, y + 1), (x, y + 1)])
    feasibility = []
    for logical_y, expected in [(1189.9, False), (1180, True), (1194, True)]:
        height = min(48, max(0, (1190 - logical_y) * 48 / 65))
        center = world((1116.464, logical_y), height)
        gaps = []
        for pixel in vertices:
            offset = add(tuple(v * (pixel[0] - leg["solePixel"][0]) for v in right), up,
                         leg["solePixel"][1] - pixel[1])
            point = add(center, rotate(offset) if 1125 <= logical_y <= 1190 else offset)
            actual = min(48, max(0, (point[1] - a[1]) * (b[2] - a[2]) / (b[1] - a[1])))
            gap = point[2] - actual
            gaps.append((pixel, gap))
        valid = all(gap >= -.02 and (pixel[1] != leg["solePixel"][1] or abs(gap) <= .02)
                    for pixel, gap in gaps)
        assert valid == expected
        feasibility.append({"logicalCenter": [1116.464, logical_y], "originalOpaqueVertexCount": len(vertices),
                            "validRigidContact": valid, "minimumGap": min(g for _, g in gaps)})
    raw, pivot, budget = 2.0, 2.6109640439537136, .4
    settlement_ticks = 0
    while raw + pivot > 1e-9:
        total = raw + pivot
        raw_step = min(raw, budget * raw / total)
        pivot_step = min(pivot, budget * pivot / total)
        assert raw_step + pivot_step <= budget + 1e-12
        raw -= raw_step
        pivot -= pivot_step
        settlement_ticks += 1
    result = {"scope": "CPU original-pixel rigid geometry only; not a gait or runtime acceptance",
              "normalFromAuthoredTreadPlane": normal, "supportAxis": support,
              "rotationDegrees": math.degrees(angle), "rotationAxis": axis,
              "originalFailure": rejected["message"], "originalGlobalOpaqueEdges": original_edges,
              "wholeOpaqueContactCounterexamples": feasibility,
              "fixedOrientationSettlementClock": {"ticks": settlement_ticks, "budgetPerTick": budget,
                                                   "rawAndPivotRemaining": [raw, pivot]},
              "originalFootChecks": rows,
              "supportEnvelopeOriginalFootChecks": envelope_checks,
              "notProven": ["airborne support clearance", "ankle continuity across moving rig",
                            "same-source flat/stair/ramp matrix", "native appearance or natural gait"]}
    if args.rotation_rejected:
        rotation_run = json.loads(args.rotation_rejected.read_text())
        foot = rotation_run["pose"]["contacts"]["feet"]["left"]
        assert foot["footDirection"] == entry["footDirection"] and rotation_run["pose"]["outfit"] == "daily"
        previous = [row["pose"]["contacts"]["feet"]["left"] for row in rotation_run["recentTrace"]
                    if row["pose"]["contacts"]["feet"]["left"]["grounded"]][-1]
        pivot = foot["ankleWorld"]
        leg = daily["views"][foot["footDirection"]]["legs"]["left"]
        ankle = [leg["ankle"][0] - leg["parts"]["foot"][0], leg["ankle"][1] - leg["parts"]["foot"][1]]
        failure = foot["failedOpaqueMaskVertex"]
        plane = failure["actualTriangleNormal"]
        anchor = [*failure["world"][:2], failure["actualTriangleHeight"]]
        def quaternion_point(q, value):
            return add(value, cross(q[:3], add(cross(q[:3], value), value, q[3])), 2)
        def minimum_gap(q):
            gaps = []
            for pixel in vertices:
                local = add(tuple(v * (pixel[0] - ankle[0]) for v in right), up, ankle[1] - pixel[1])
                point = add(pivot, quaternion_point(q, local))
                height = anchor[2] - (plane[0] * (point[0] - anchor[0]) + plane[1] * (point[1] - anchor[1])) / plane[2]
                gaps.append(point[2] - height)
            return min(gaps)
        old_gap = minimum_gap(previous["footPlane"]["rotation"])
        failed_gap = minimum_gap(foot["footPlane"]["rotation"])
        assert old_gap > .02 and failed_gap < -.3
        result["actualRotationReplay"] = {"ankleWorldHeld": pivot, "originalOpaqueVertices": len(vertices),
                                          "previousPlaneMinimumGap": old_gap, "failedPlaneMinimumGap": failed_gap,
                                          "source": str(args.rotation_rejected), "scope": "Same actual ankle and captured local triangle plane; runtime backtracking pending"}
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, indent=2) + "\n")
    print(f"RIGID SOLE MODEL: {len(rows)} original feet preserve lengths/plane support; runtime pending")


if __name__ == "__main__":
    main()
