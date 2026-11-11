#!/usr/bin/env python3
"""Replay a captured fixed-view dock restart and compare frozen-target durations."""
import argparse
import hashlib
import json
import math
from pathlib import Path

import numpy as np
from PIL import Image
from model_ramp_sole import vector


def line_sphere_interval(origin, velocity, center, radius, lower, upper):
    difference = np.array(origin) - np.array(center)
    velocity = np.array(velocity)
    a = float(velocity @ velocity)
    b = 2 * float(difference @ velocity)
    c = float(difference @ difference) - radius * radius
    if a < 1e-12:
        return [(lower, upper)] if c <= 0 else []
    discriminant = b * b - 4 * a * c
    if discriminant < 0:
        return []
    first = max(lower, (-b - math.sqrt(discriminant)) / (2 * a))
    last = min(upper, (-b + math.sqrt(discriminant)) / (2 * a))
    return [(first, last)] if first <= last else []


def intersection(first, second):
    pieces = sorted((max(a, c), min(b, d)) for a, b in first for c, d in second if max(a, c) <= min(b, d))
    merged = []
    for lower, upper in pieces:
        if merged and lower <= merged[-1][1]:
            merged[-1] = (merged[-1][0], max(merged[-1][1], upper))
        else:
            merged.append((lower, upper))
    return merged


def common_hip_intervals(hip_xy, ankles, radii, lower, upper):
    allowed = [(lower, upper)]
    for side, xy in hip_xy.items():
        ankle = np.array(ankles[side])
        horizontal = float(np.sum((np.array(xy) - ankle[:2]) ** 2))
        inner, outer = radii[side]
        if horizontal >= outer * outer:
            return []
        vertical = math.sqrt(max(0, outer * outer - horizontal))
        allowed = intersection(allowed, [(ankle[2] - vertical, ankle[2] + vertical)])
        if horizontal < inner * inner:
            forbidden = math.sqrt(inner * inner - horizontal)
            allowed = intersection(allowed, [(-math.inf, ankle[2] - forbidden), (ankle[2] + forbidden, math.inf)])
    return allowed


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--run", type=Path, required=True)
    parser.add_argument("--world", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[2]
    rejected = json.loads((args.run / "rejected.json").read_text())
    source = json.loads((args.run / "source.json").read_text())
    assert hashlib.sha256(args.world.read_bytes()).hexdigest() == source["fixtureWorldSha256"]
    paused = next(row for row in reversed(rejected["recentTrace"]) if "paused-on-connector" in row["case"])
    rows = [row for row in rejected["recentTrace"] if row["case"].endswith(" travel")
            and row["pose"]["contacts"]["acceptedDistance"] > paused["pose"]["contacts"]["acceptedDistance"]]
    initial = paused["pose"]
    contacts = rejected["pose"]["contacts"]
    assert initial["direction"] == rejected["pose"]["direction"] == "south_east"
    entry = contacts["feet"]["right"]
    plan = entry["rampCurvePlan"]
    data = json.loads((root / "client-godot/resources/art/player-lower-body/male-nusantara-daily-v1.json").read_text())
    image = Image.open(root / "client-godot" / data["source"].removeprefix("res://")).convert("RGBA")
    hub = json.loads(args.world.read_text())["landMaps"]["hub"]
    ramp = next(profile for profile in hub["stairs"] if profile["id"] == "dock_gangway")
    levels = {terrace["id"]: terrace["elevation"] * 48 for terrace in hub["terraces"]}
    tilt = math.radians(55)
    low, high = levels[ramp["from"]], levels[ramp["to"]]
    y0, y1 = [-ramp["path"][i][1] / math.cos(tilt) - levels[ramp[key]] * math.tan(tilt)
              for i, key in enumerate(["from", "to"])]
    right = np.array([math.sqrt(.5), -math.sqrt(.5), 0])
    scale = initial["calibration"]

    def ground_z(y):
        return low + (high - low) * np.clip((y - y0) / (y1 - y0), 0, 1)

    def rotate(q, values):
        return values + 2 * np.cross(q[:3], np.cross(q[:3], values) + q[3] * values)

    def source_geometry(direction, side):
        view = data["views"][direction]
        leg = view["legs"][side]
        rect = leg["parts"]["foot"]
        source_ankle = np.array(leg["ankle"]) - np.array(rect[:2])
        pixels = set(tuple(pixel) for pixel in leg["soleEdgePixels"])
        for y in range(rect[3]):
            for x in range(rect[2]):
                if image.getpixel((view["sourceColumn"] * 128 + rect[0] + x, rect[1] + y))[3] >= 128:
                    pixels.update([(x, y), (x + 1, y), (x + 1, y + 1), (x, y + 1)])
        pixels = np.array(sorted(pixels))
        offsets = (pixels[:, :1] - source_ankle[0]) * right
        offsets[:, 2] = (source_ankle[1] - pixels[:, 1]) * scale
        ankle_offset = right * (source_ankle[0] - leg["solePixel"][0])
        ankle_offset[2] = (leg["solePixel"][1] - source_ankle[1]) * scale
        radius = max(math.hypot(x - source_ankle[0], (y - source_ankle[1]) * scale)
                     for x, y in [(0, 0), (rect[2], 0), (0, rect[3]), (rect[2], rect[3])])
        return offsets, ankle_offset, radius

    offsets, ankle_offset, radius = source_geometry("south_east", "right")
    marker_leg = data["views"]["south_east"]["legs"]["right"]
    marker_ankle = np.array(marker_leg["ankle"]) - np.array(marker_leg["parts"]["foot"][:2])
    markers = np.array(marker_leg["soleEdgePixels"])
    marker_offsets = (markers[:, :1] - marker_ankle[0]) * right
    marker_offsets[:, 2] = (marker_ankle[1] - markers[:, 1]) * scale
    left = initial["contacts"]["feet"]["left"]
    left_offsets, _, _ = source_geometry(left["footDirection"], "left")
    left_ankle = np.array(left["ankleWorld"])
    left_points = left_ankle + rotate(np.array(left["footPlane"]["rotation"]), left_offsets)
    left_height = float(np.min(ground_z(left_points[:, 1])))
    knots = np.array([vector(knot["world"]) for knot in plan["groundKnots"]])
    lengths = np.linalg.norm(np.diff(knots[:, :2], axis=0), axis=1)
    total = float(np.sum(lengths))
    assert abs(total - plan["fixedPathWorldXY"]) < .002
    root_start = paused["position"]
    root_z = low + (high - low) * np.clip((ramp["path"][0][1] - root_start[1]) / (ramp["path"][0][1] - ramp["path"][1][1]), 0, 1)
    root_xy = np.array([root_start[0], -root_start[1] / math.cos(tilt) - root_z * math.tan(tilt), 0])
    initial_q = np.array(initial["contacts"]["feet"]["right"]["footPlane"]["rotation"])
    initial_q /= np.linalg.norm(initial_q)
    initial_angle = 2 * math.acos(initial_q[3])
    axis = initial_q[:3] / math.sin(initial_angle / 2)
    rate = float(contacts["bodyTransferRate"])
    legs = data["views"]["south_east"]["legs"]
    lengths_by_side = {side: [math.dist(leg["hip"], leg["knee"]) * scale,
                              math.dist(leg["knee"], leg["ankle"]) * scale] for side, leg in legs.items()}

    def path(fraction):
        distance = fraction * total
        for index, length in enumerate(lengths):
            if distance <= length or index == len(lengths) - 1:
                return knots[index] + (knots[index + 1] - knots[index]) * (distance / length)
            distance -= length

    def replay(duration, phases, estimator_offsets=None):
        q = initial_q.copy()
        correction = np.array(initial["contacts"]["feet"]["right"]["pivotCorrectionWorld"])
        body = float(initial["contacts"]["bodyHeight"])
        previous = 0.0
        previous_ankle = np.array(initial["contacts"]["feet"]["right"]["ankleWorld"])
        output = []
        for phase in phases:
            delta = phase - previous
            correction *= max(0, duration - phase) / max(.000001, duration - previous)
            u = min(1, phase / duration)
            smooth = u * u * (3 - 2 * u)
            raw = path(smooth)
            actual_ankle = raw + correction + rotate(q, ankle_offset)
            angle = max(0, 2 * math.acos(min(1, q[3])) - delta / radius)
            rotation_budget_valid = radius * (2 * math.acos(min(1, q[3])) - angle) <= delta + .000001
            next_q = np.r_[axis * math.sin(angle / 2), math.cos(angle / 2)]
            rotated = rotate(next_q, offsets)
            points = actual_ankle + rotated
            support_rotated = rotated if estimator_offsets is None else rotate(next_q, estimator_offsets)
            support_points = actual_ankle + support_rotated
            h = float(np.max(ground_z(support_points[:, 1]) - support_rotated[:, 2]))
            actual_ankle[2] = h + max(.02, 3 * math.sin(u * math.pi) + plan["fromSupportOffset"] * (1 - smooth))
            correction += rotate(q, ankle_offset) - rotate(next_q, ankle_offset)
            q = next_q
            if phase == duration:
                actual_ankle = np.array(vector(entry["toWorld"])) + rotate(q, ankle_offset)
            points = actual_ankle + rotated
            assert np.max(np.abs(points[:, 0] - ramp["path"][0][0])) < ramp["width"] / 2
            target = min(left_height, float(np.min(ground_z(points[:, 1]))))
            body += max(-delta * rate, min(delta * rate, target - body))
            actor = root_xy - np.array([0, phase, 0])
            hips = {side: actor + right * (leg["hip"][0] - 64) for side, leg in legs.items()}
            for hip in hips.values():
                hip[2] = body + 28 * scale
            ankles = {"left": left_ankle, "right": actual_ankle}
            drop = 0.0
            horizontal_failure = False
            for side, hip in hips.items():
                reach = sum(lengths_by_side[side]) - .1
                xy = float(np.sum((hip[:2] - ankles[side][:2]) ** 2))
                horizontal_failure |= xy >= reach * reach
                drop = max(drop, hip[2] - ankles[side][2] - math.sqrt(max(.001, reach * reach - xy)))
            annuli = {}
            for side, hip in hips.items():
                hip[2] -= min(max(0, drop), 8 * scale)
                distance = float(np.linalg.norm(hip - ankles[side]))
                annuli[side] = {"distance": distance, "inner": abs(lengths_by_side[side][0] - lengths_by_side[side][1]),
                                 "outer": sum(lengths_by_side[side])}
            ankle_travel = float(np.linalg.norm(actual_ankle - previous_ankle))
            ankle_valid = ankle_travel <= delta * 5 + .003
            contact_valid = True
            if phase == duration:
                gaps = points[:, 2] - ground_z(points[:, 1])
                bottom = np.abs(offsets[:, 2] + ankle_offset[2]) < .00001
                contact_valid = angle < .001 and float(np.min(gaps)) >= -.02 and bool(np.any(bottom)) and bool(np.all(np.abs(gaps[bottom]) <= .02))
            valid = not horizontal_failure and drop / scale <= 8 and all(row["inner"] <= row["distance"] <= row["outer"] for row in annuli.values()) and ankle_valid and rotation_budget_valid and contact_valid
            output.append({"phase": phase, "body": body, "ankle": actual_ankle.tolist(), "dropPixels": drop / scale,
                           "fixedOriginalAnnuli": annuli, "ankleTravel": ankle_travel, "acceptedDelta": delta,
                           "ankleGuardValid": ankle_valid, "rotationBudgetValid": rotation_budget_valid,
                           "contactValid": bool(contact_valid), "valid": bool(valid)})
            previous = phase
            previous_ankle = actual_ankle.copy()
        return output

    phases = [row["pose"]["contacts"]["swingDistance"] for row in rows]
    actual = replay(plan["distance"], phases)
    predicted = actual[-1]
    assert abs(predicted["body"] - contacts["bodyHeight"]) < .003
    assert abs(predicted["dropPixels"] - rejected["pose"]["requestedDropPixels"]) < .03
    assert predicted["dropPixels"] > 8
    # Freeze A(u) once for a conditional duration preview. Actual Q/C/H and
    # target-following are replayed separately.
    base_duration = plan["distance"]
    sample_phases = [base_duration * index / 32 for index in range(1, 33)]
    sampled_base = replay(base_duration, sample_phases)
    sampled_markers = replay(base_duration, sample_phases, marker_offsets)
    assert all(a["ankle"][2] >= b["ankle"][2] - 1e-9 and np.linalg.norm(np.array(a["ankle"][:2]) - b["ankle"][:2]) < 1e-9
               for a, b in zip(sampled_base, sampled_markers))
    floor = low
    split = max(0, (float(initial["contacts"]["bodyHeight"]) - floor) / rate)
    def estimate(sequence):
        allowed = [(base_duration, 32.0)]
        for pose in sequence:
            u = pose["phase"] / base_duration
            for side in ["left", "right"]:
                center = np.array(pose["ankle"] if side == "right" else left_ankle)
                origin = root_xy + right * (legs[side]["hip"][0] - 64)
                origin[2] = float(initial["contacts"]["bodyHeight"]) + (28 - 8) * scale
                linear = line_sphere_interval(origin, [0, -1, -rate], center, sum(lengths_by_side[side]) - .1, 0, split)
                origin[2] = floor + (28 - 8) * scale
                linear += line_sphere_interval(origin, [0, -1, 0], center, sum(lengths_by_side[side]) - .1, split, 32)
                allowed = intersection(allowed, [(a / u, b / u) for a, b in linear])
        rounded = [math.ceil(a * 4) / 4 for a, b in allowed if math.ceil(a * 4) / 4 <= b]
        return allowed, min(rounded) if rounded else None

    allowed, suggested = estimate(sampled_base)
    marker_allowed, marker_suggested = estimate(sampled_markers)
    radii = {side: (abs(values[0] - values[1]), sum(values) - .1) for side, values in lengths_by_side.items()}

    def common_preview(sequence, duration):
        for pose in sequence:
            d = duration * pose["phase"] / base_duration
            actor = root_xy - np.array([0, d, 0])
            hip_xy = {side: (actor + right * (leg["hip"][0] - 64))[:2] for side, leg in legs.items()}
            optimistic_body = max(floor, float(initial["contacts"]["bodyHeight"]) - rate * d)
            if not common_hip_intervals(hip_xy, {"left": left_ankle, "right": pose["ankle"]}, radii,
                                        optimistic_body + (28 - 8) * scale, optimistic_body + 28 * scale):
                return False
        return True

    preview_durations = [quarter / 4 for quarter in range(math.ceil(base_duration * 4), math.ceil(base_duration * 4) + 65)
                         if common_preview(sampled_markers, quarter / 4)]
    end_actor = root_xy - np.array([0, 17.5, 0])
    end_xy = {side: (end_actor + right * (leg["hip"][0] - 64))[:2] for side, leg in legs.items()}
    end_right = np.array(vector(entry["toWorld"])) + ankle_offset
    common = common_hip_intervals(end_xy, {"left": left_ankle, "right": end_right}, radii, (28 - 8) * scale, 28 * scale)
    assert any(lower <= (28 - 2) * scale <= upper for lower, upper in common)
    assert np.linalg.norm(np.r_[end_xy["left"], (28 - 8) * scale] - left_ankle) > radii["left"][1]
    candidates = []
    for quarter in range(40, 89):
        duration = quarter / 4
        schedules = {str(hz) + "Hz": sorted(set(min(duration, index * 100 / hz) for index in range(1, math.ceil(duration / (100 / hz)) + 1)))
                     for hz in [30, 60, 120, 2000]}
        schedules["recorded-prefix-and-60Hz"] = sorted(set([min(duration, phase) for phase in phases if phase < duration] + schedules["60Hz"]))
        summaries = []
        for name, schedule in schedules.items():
            sequence = replay(duration, schedule)
            summaries.append({"schedule": name, "maximumDropPixels": max(row["dropPixels"] for row in sequence),
                              "maximumObservedAnkleRatio": max(row["ankleTravel"] / row["acceptedDelta"] for row in sequence),
                              "allFrozenGeometryValid": all(row["valid"] for row in sequence), "terminal": sequence[-1]})
        candidates.append({"duration": duration, "allFrozenGeometryValid": all(row["allFrozenGeometryValid"] for row in summaries),
                           "schedules": summaries})
    result = {"scope": "Frozen SE body/right shoe and planted SOUTH left shoe, actual dock profile, original pixels and retained landing only; no coupled runtime proof",
              "source": str(args.run), "capturedDropPixels": rejected["pose"]["requestedDropPixels"],
              "fixtureWorldSha256": source["fixtureWorldSha256"],
              "supersededFixedMaxDropIntervals": allowed, "supersededFixedMaxDropQuarterGrid": suggested,
              "supersededFixedMaxDropMarkerIntervals": marker_allowed, "supersededFixedMaxDropMarkerQuarterGrid": marker_suggested,
              "commonHipMarkerPreviewDurations": preview_durations,
              "commonHipPreviewFirstQuarter": min(preview_durations) if preview_durations else None,
              "fixedMaxDropCounterexample": {"duration": 17.5, "common2pxHipHeight": (28 - 2) * scale,
                                               "commonHipIntervals": common, "fixed8pxWronglyRejected": True},
              "soleMarkerPointQueryCount": len(markers) * len(sample_phases),
              "fullMaskVersusMarkerMaximumAnkleHeight": max(a["ankle"][2] - b["ankle"][2] for a, b in zip(sampled_base, sampled_markers)),
              "previewScope": "32 cached marker A(u), optimistic body baseline, common variable pelvis drop and original inner/outer radii; not a global necessity/sufficiency proof because Q/C/H/body target change",
              "replayedActual": actual, "frozenTargetDurationCandidates": candidates,
              "notProven": ["changing source views", "new actual stop/resume trajectory", "full-mask angle backtracking",
                            "actual accepted-input schedule", "all terrain or native naturalness"]}
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, indent=2) + "\n")
    print(json.dumps({"actualDrop": predicted["dropPixels"], "capturedDrop": rejected["pose"]["requestedDropPixels"],
                      "commonHipMarkerPreviewFirstQuarter": min(preview_durations) if preview_durations else None,
                      "commonHipMarkerPreviewDurations": preview_durations,
                      "validCandidateDurations": [row["duration"] for row in candidates if row["allFrozenGeometryValid"]]}, indent=2))


if __name__ == "__main__":
    main()
