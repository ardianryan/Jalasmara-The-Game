#!/usr/bin/env python3
"""Replay one captured rigid foot against the authored dock and captured paint crest."""
import argparse
import json
import math
from pathlib import Path
from PIL import Image
from model_ramp_sole import add, cross


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--rejected", type=Path, required=True)
    parser.add_argument("--world", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[2]
    failure = json.loads(args.rejected.read_text())
    pose = failure["pose"]
    contacts = pose["contacts"]
    foot = contacts["feet"]["right"]
    data = json.loads((root / f'client-godot/resources/art/player-lower-body/male-nusantara-{pose["outfit"]}-v1.json').read_text())
    view = data["views"][foot["footDirection"]]
    leg = view["legs"]["right"]
    rect = leg["parts"]["foot"]
    ankle = [leg["ankle"][i] - rect[i] for i in range(2)]
    atlas = Image.open(root / "client-godot" / data["source"].removeprefix("res://")).convert("RGBA")
    vertices = set()
    for y in range(rect[3]):
        for x in range(rect[2]):
            if atlas.getpixel((view["sourceColumn"] * 128 + rect[0] + x, rect[1] + y))[3] >= 128:
                vertices.update([(x, y), (x + 1, y), (x + 1, y + 1), (x, y + 1)])
    scale = pose["calibration"]
    right = (math.sqrt(.5), -math.sqrt(.5), 0)
    local = lambda pixel: add(tuple(v * (pixel[0] - ankle[0]) for v in right), (0, 0, scale), ankle[1] - pixel[1])
    q = foot["footPlane"]["rotation"]
    angle = 2 * math.acos(q[3])
    axis = [v / math.sin(angle / 2) for v in q[:3]]
    radius = max(math.hypot(x - ankle[0], (y - ankle[1]) * scale)
                 for x, y in [(0, 0), (rect[2], 0), (0, rect[3]), (rect[2], rect[3])])
    previous = next(row["pose"]["contacts"] for row in reversed(failure["recentTrace"])
                    if row["pose"]["contacts"]["acceptedDistance"] < contacts["acceptedDistance"] - .00001)
    accepted = contacts["acceptedDistance"] - previous["acceptedDistance"]
    next_angle = max(0, angle - accepted / radius)
    flat = [row for row in foot["measuredOpaqueVertices"] if row["actualTriangleNormal"][2] > .99]
    floor_upper = max(row["actualTriangleHeight"] for row in flat)
    paint_edge = min(v[1] for row in flat for v in row["actualTriangleVertices"])
    hub = json.loads(args.world.read_text())["landMaps"]["hub"]
    ramp = next(row for row in hub["stairs"] if row["id"] == "dock_gangway")
    heights = {row["id"]: row["elevation"] * 48 for row in hub["terraces"]}
    tilt = math.radians(55)
    def world_y(index, terrace):
        z = heights[terrace]
        return -ramp["path"][index][1] / math.cos(tilt) - z * math.tan(tilt)
    ramp_low, ramp_high = world_y(0, ramp["from"]), world_y(1, ramp["to"])
    def gap(theta):
        rotation = [*(v * math.sin(theta / 2) for v in axis), math.cos(theta / 2)]
        gaps = []
        for pixel in vertices:
            value = local(pixel)
            turned = add(value, cross(rotation[:3], add(cross(rotation[:3], value), value, rotation[3])), 2)
            world = add(foot["ankleWorld"], turned)
            support = min(heights[ramp["to"]], max(heights[ramp["from"]],
                          (world[1] - ramp_low) / (ramp_high - ramp_low) * (heights[ramp["to"]] - heights[ramp["from"]]) + heights[ramp["from"]]))
            if world[1] >= paint_edge:
                support = max(support, floor_upper)
            gaps.append(world[2] - support)
        return min(gaps)
    holding_gap, proposed_gap = gap(angle), gap(next_angle)
    assert holding_gap < -.3 and proposed_gap > .02
    assert radius * (angle - next_angle) <= accepted + 1e-12
    result = {"scope": "One captured ankle and original foot corners, authored dock ramp plus captured paint edge; not a swept-volume/runtime gait proof",
              "source": str(args.rejected), "originalOpaqueVertexCount": len(vertices),
              "actualAnkleHeld": foot["ankleWorld"], "localFloorUpper": floor_upper, "paintEdgeWorldY": paint_edge,
              "holdingAngle": angle, "holdingMinimumGap": holding_gap, "allowedAcceptedDistance": accepted,
              "originalQuadRadiusAboutAnkle": radius, "proposedAngle": next_angle,
              "proposedMinimumGap": proposed_gap,
              "notProven": ["orientation completion at contact", "stance reach for full curve", "flat/terrain/native gait matrix"]}
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, indent=2) + "\n")
    print("RAMP ORIENTATION MODEL: existing bounded step clears all original pixels at same actual ankle; runtime pending")


if __name__ == "__main__":
    main()
