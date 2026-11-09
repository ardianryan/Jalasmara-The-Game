#!/usr/bin/env python3
"""Replay one captured profile-view support discontinuity using immutable foot pixels."""
import argparse
import json
import math
import re
from pathlib import Path
from PIL import Image
from model_ramp_sole import add, cross


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--world", type=Path, required=True)
    parser.add_argument("--rejected", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[2]
    run = json.loads(args.rejected.read_text())
    side = re.search(r"side=(left|right)", run["message"]).group(1)
    pose = run["pose"]
    contacts = pose["contacts"]
    current = contacts["feet"][side]
    previous_row = next(row for row in reversed(run["recentTrace"])
                        if row["pose"]["contacts"]["acceptedDistance"] < contacts["acceptedDistance"] - .00001)
    previous = previous_row["pose"]["contacts"]["feet"][side]
    assert previous["footDirection"] != current["footDirection"]
    assert math.dist(previous["footPlane"]["rotation"], current["footPlane"]["rotation"]) < .00001
    data = json.loads((root / f'client-godot/resources/art/player-lower-body/male-nusantara-{pose["outfit"]}-v1.json').read_text())
    image = Image.open(root / "client-godot" / data["source"].removeprefix("res://")).convert("RGBA")
    hub = json.loads(args.world.read_text())["landMaps"]["hub"]
    ramp = next(row for row in hub["stairs"] if row["id"] == "dock_gangway")
    heights = {row["id"]: row["elevation"] * 48 for row in hub["terraces"]}
    tilt = math.radians(55)
    def world_y(index, terrace):
        return -ramp["path"][index][1] / math.cos(tilt) - heights[terrace] * math.tan(tilt)
    low, high = world_y(0, ramp["from"]), world_y(1, ramp["to"])
    q = current["footPlane"]["rotation"]
    right = (math.sqrt(.5), -math.sqrt(.5), 0)
    def support(direction):
        view = data["views"][direction]
        leg = view["legs"][side]
        rect = leg["parts"]["foot"]
        ankle = [leg["ankle"][i] - rect[i] for i in range(2)]
        pixels = set(tuple(row) for row in leg["soleEdgePixels"])
        for y in range(rect[3]):
            for x in range(rect[2]):
                if image.getpixel((view["sourceColumn"] * 128 + rect[0] + x, rect[1] + y))[3] >= 128:
                    pixels.update([(x, y), (x + 1, y), (x + 1, y + 1), (x, y + 1)])
        values = []
        for x, y in pixels:
            value = add(tuple(v * (x - ankle[0]) for v in right), (0, 0, pose["calibration"]), ankle[1] - y)
            offset = add(value, cross(q[:3], add(cross(q[:3], value), value, q[3])), 2)
            point = add(current["ankleWorld"], offset)
            assert low < point[1] < high and abs(point[0] - ramp["path"][0][0]) < ramp["width"] / 2
            z = heights[ramp["from"]] + (point[1] - low) / (high - low) * (heights[ramp["to"]] - heights[ramp["from"]])
            values.append(z - offset[2])
        return max(values)
    old_h, new_h = support(previous["footDirection"]), support(current["footDirection"])
    assert abs(new_h - current["supportEnvelope"]["ankleSupportHeight"]) < .005
    correction = old_h - new_h
    proposed = add(current["ankleWorld"], (0, 0, correction))
    accepted = contacts["acceptedDistance"] - previous_row["pose"]["contacts"]["acceptedDistance"]
    before = math.dist(current["ankleWorld"], previous["ankleWorld"])
    after = math.dist(proposed, previous["ankleWorld"])
    allowed = accepted * 5 + .003
    inner = abs(current["lengths"][0] - current["lengths"][1])
    outer = sum(current["lengths"])
    assert before > allowed and after <= allowed
    assert inner <= math.dist(proposed, current["hipWorld"]) <= outer
    u = contacts["swingDistance"] / contacts["landingDistance"]
    progress = u * u * (3 - 2 * u)
    a0 = current["rampCurvePlan"]["fromSupportOffset"]
    carried = a0 + correction / (1 - progress)
    assert abs(new_h + carried * (1 - progress) - old_h - a0 * (1 - progress)) < 1e-10
    result = {"scope": "One captured constant-plane shoe-view switch; actual other frames, changed body feedback and full gait unproved",
              "source": str(args.rejected), "side": side, "previousView": previous["footDirection"],
              "nextView": current["footDirection"], "sameXYAndQPreviousMaskH": old_h, "sameXYAndQNextMaskH": new_h,
              "runtimeNextMaskH": current["supportEnvelope"]["ankleSupportHeight"],
              "cpuRuntimeGroundInverseDifference": new_h-current["supportEnvelope"]["ankleSupportHeight"],
              "supportShapeCorrection": correction, "capturedAnkleDelta": before, "proposedAnkleDelta": after,
              "allowedUnchanged": allowed, "frozenHipReachAfter": math.dist(proposed, current["hipWorld"]),
              "innerReach": inner, "outerReach": outer, "normalizedStartOffsetBefore": a0, "normalizedStartOffsetAfter": carried}
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, indent=2) + "\n")
    print("RAMP VIEW SUPPORT MODEL: original old/new masks cancel captured support-height switch; actual ankle and reach guards retained")


if __name__ == "__main__":
    main()
