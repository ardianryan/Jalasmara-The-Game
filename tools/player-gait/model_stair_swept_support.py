#!/usr/bin/env python3
"""Frozen original-foot per-riser path comparison; not a runtime gait proof."""
import argparse
import hashlib
import json
import math
from pathlib import Path

import numpy as np
from PIL import Image
from model_ramp_sole import vector


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--run', type=Path, required=True)
    parser.add_argument('--world', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[2]
    rejected = json.loads((args.run / 'rejected.json').read_text())
    pins = json.loads((args.run / 'source.json').read_text())
    assert hashlib.sha256(args.world.read_bytes()).hexdigest() == pins['fixtureWorldSha256']
    c = rejected['pose']['contacts']
    assert c['swingSide'] == 'right' and rejected['pose']['direction'] == 'north_west'
    entry = c['feet']['right']
    data = json.loads((root / 'client-godot/resources/art/player-lower-body/male-nusantara-daily-v1.json').read_text())
    image_path = root / 'client-godot' / data['source'].removeprefix('res://')
    image = Image.open(image_path).convert('RGBA')
    leg = data['views']['north_west']['legs']['right']
    rect = leg['parts']['foot']
    sole = np.array(leg['solePixel'])
    pixels = set(tuple(pixel) for pixel in leg['soleEdgePixels'])
    for y in range(rect[3]):
        for x in range(rect[2]):
            if image.getpixel((data['views']['north_west']['sourceColumn'] * 128 + rect[0] + x, rect[1] + y))[3] >= 128:
                pixels.update([(x, y), (x + 1, y), (x + 1, y + 1), (x, y + 1)])
    pixels = np.array(sorted(pixels))
    vertical = math.cos(math.radians(35))
    right = np.array([math.sqrt(.5), -math.sqrt(.5), 0])
    offsets = (pixels[:, :1] - sole[0]) * right
    offsets[:, 2] = (sole[1] - pixels[:, 1]) / vertical
    assert np.min(offsets[:, 2]) >= 0
    ankle_pixel = np.array(leg['ankle']) - np.array(rect[:2])
    ankle_offset = (ankle_pixel[0] - sole[0]) * right
    ankle_offset[2] = (sole[1] - ankle_pixel[1]) / vertical
    hub = json.loads(args.world.read_text())['landMaps']['hub']
    profile = next(s for s in hub['stairs'] if s['id'] == entry['treadPlan']['connectorId'])
    levels = {s['id']: s['elevation'] * 48 for s in hub['terraces']}
    a, b = profile['path']
    start_z, end_z = levels[profile['from']], levels[profile['to']]
    tilt = math.radians(55)
    slope = -1 / math.cos(tilt) - (end_z - start_z) / (b[1] - a[1]) * math.tan(tilt)
    constant = -(start_z - (end_z - start_z) * a[1] / (b[1] - a[1])) * math.tan(tilt)

    def world_y(y):
        return slope * y + constant

    def ground(y):
        logical = (y - constant) / slope
        progress = (logical - a[1]) / (b[1] - a[1])
        assert np.min(progress) >= 0 and np.max(progress) <= 1
        return start_z + (end_z - start_z) * (np.clip(np.floor(progress * profile['steps']), 0, profile['steps'] - 1) + 1) / profile['steps']

    start = np.array(vector(entry['fromWorld']))
    target = np.array(vector(entry['toWorld']))
    x, y = rejected['position']
    origin = np.array([x, world_y(y) - c['swingDistance'], 0])
    legs = data['views']['north_west']['legs']
    left_ankle = np.array(next(row['pose']['contacts']['feet']['left']['ankleWorld']
                              for row in reversed(rejected['recentTrace'])
                              if 'ankleWorld' in row['pose']['contacts']['feet']['left']))
    radii = {side: (abs(math.dist(l['hip'], l['knee']) - math.dist(l['knee'], l['ankle'])) / vertical,
                   (math.dist(l['hip'], l['knee']) + math.dist(l['knee'], l['ankle'])) / vertical - .1)
             for side, l in legs.items()}
    total_xy = float(np.linalg.norm(target[:2] - start[:2]))
    tangent = (target - start) / total_xy
    tangent[2] = 0
    knots = [start]
    for step in range(1, profile['steps']):
        edge_y = world_y(a[1] + (b[1] - a[1]) * step / profile['steps'])
        distance = (edge_y - float(np.max(offsets[:, 1])) - .02 - start[1]) / tangent[1]
        if 0 < distance < total_xy:
            knot = start + tangent * distance
            knot[2] = start_z + (end_z - start_z) * (step + 1) / profile['steps']
            knots.append(knot)
    knots.append(target)
    lengths = np.linalg.norm(np.diff(knots, axis=0), axis=1)
    arc = float(np.sum(lengths))

    def point(fraction):
        distance = fraction * arc
        for index, length in enumerate(lengths):
            if distance <= length or index == len(lengths) - 1:
                return knots[index] + (knots[index + 1] - knots[index]) * np.clip(distance / length, 0, 1)
            distance -= length

    results = []
    for duration in [16.0, 16.25, 16.5, 16.75, 16.919934, float(entry['treadPlan']['treadDistance'])]:
        maximum_drop = 0
        minimum_gap = math.inf
        minimum_inner_slack = math.inf
        maximum_outer_excess = -math.inf
        maximum_original_outer_excess = -math.inf
        horizontal_rejections = 0
        maximum_ankle_ratio = 0
        old_ankle = start + ankle_offset
        for index in range(1, 10001):
            u = index / 10000
            phase = duration * u
            p = point(u * u * (3 - 2 * u))
            p[2] += 3 * math.sin(u * math.pi)
            ankle = p + ankle_offset
            minimum_gap = min(minimum_gap, float(np.min((p + offsets)[:, 2] - ground((p + offsets)[:, 1]))))
            body = 72 + min(12, phase)
            hips = {side: origin + np.array([0, phase, body + 28 / vertical]) + right * (l['hip'][0] - 64) for side, l in legs.items()}
            ankles = {'left': left_ankle, 'right': ankle}
            drop = 0
            for side, hip in hips.items():
                h = float(np.sum((hip[:2] - ankles[side][:2]) ** 2))
                horizontal_rejections += int(h >= radii[side][1] ** 2)
                drop = max(drop, hip[2] - ankles[side][2] - math.sqrt(max(.001, radii[side][1] ** 2 - h)))
            maximum_drop = max(maximum_drop, drop * vertical)
            for side, hip in hips.items():
                distance = float(np.linalg.norm(hip - np.array([0, 0, min(8 / vertical, drop)]) - ankles[side]))
                minimum_inner_slack = min(minimum_inner_slack, distance - radii[side][0])
                maximum_outer_excess = max(maximum_outer_excess, distance - radii[side][1])
                maximum_original_outer_excess = max(maximum_original_outer_excess, distance - (radii[side][1] + .1))
            maximum_ankle_ratio = max(maximum_ankle_ratio, float(np.linalg.norm(ankle - old_ankle)) / (duration / 10000))
            old_ankle = ankle.copy()
        bound = (1.5 * arc + 3 * math.pi) / duration
        schedules = []
        for hz in [30, 60, 120, 2000]:
            phases = sorted(set(min(duration, index * 100 / hz) for index in range(1, math.ceil(duration / (100 / hz)) + 1)))
            old = start + ankle_offset
            previous = 0
            peak = 0
            minimum_airborne_gap = math.inf
            ankle_valid = True
            composed_drop = 0
            composed_inner = math.inf
            composed_outer = -math.inf
            composed_horizontal = 0
            maximum_support_adjustment = 0
            for phase in phases:
                u = phase / duration
                p = point(u * u * (3 - 2 * u))
                h = float(np.max(ground((p + offsets)[:, 1]) - offsets[:, 2]))
                planned_z = p[2] + 3 * math.sin(u * math.pi)
                p[2] = max(planned_z, h + .02) if phase < duration else target[2]
                maximum_support_adjustment = max(maximum_support_adjustment, p[2] - planned_z)
                ankle = p + ankle_offset
                travel = float(np.linalg.norm(ankle - old))
                delta = phase - previous
                peak = max(peak, travel / delta)
                ankle_valid &= travel <= delta * 5 + .003
                if phase < duration:
                    minimum_airborne_gap = min(minimum_airborne_gap, float(np.min((p + offsets)[:, 2] - ground((p + offsets)[:, 1]))))
                body = 72 + min(12, phase)
                hips = {side: origin + np.array([0, phase, body + 28 / vertical]) + right * (l['hip'][0] - 64) for side, l in legs.items()}
                ankles = {'left': left_ankle, 'right': ankle}
                drop = 0
                for side, hip in hips.items():
                    horizontal = float(np.sum((hip[:2] - ankles[side][:2]) ** 2))
                    composed_horizontal += int(horizontal >= radii[side][1] ** 2)
                    drop = max(drop, hip[2] - ankles[side][2] - math.sqrt(max(.001, radii[side][1] ** 2 - horizontal)))
                composed_drop = max(composed_drop, drop * vertical)
                for side, hip in hips.items():
                    distance = float(np.linalg.norm(hip - np.array([0, 0, min(8 / vertical, drop)]) - ankles[side]))
                    composed_inner = min(composed_inner, distance - radii[side][0])
                    composed_outer = max(composed_outer, distance - (radii[side][1] + .1))
                old, previous = ankle, phase
            schedules.append({'hz': hz, 'supportAdjustment': 'max(plannedBase+3sin, originalMaskSupport+.02), forced true contact at endpoint',
                              'maximumObservedAnkleRatio': peak, 'actual5GuardValid': bool(ankle_valid),
                              'minimumAirborneGap': minimum_airborne_gap, 'maximumSupportAdjustmentBeyondPlannedLift': maximum_support_adjustment,
                              'maximumDropPixels': composed_drop, 'minimumInnerSlack': composed_inner,
                              'maximumOriginalOuterExcess': composed_outer, 'horizontalRejections': composed_horizontal,
                              'samePoseAnatomyValid': bool(composed_drop <= 8 and composed_inner >= 0 and composed_outer <= 0 and composed_horizontal == 0),
                              'continuumCertificate': False})
        results.append({'duration': duration, 'analyticBaseSpeedBound': bound, 'maximumObservedAnkleRatio': maximum_ankle_ratio,
                        'maximumDropPixels': maximum_drop, 'minimumInnerSlack': minimum_inner_slack, 'minimumOriginalCornerGroundGap': minimum_gap,
                        'maximumOuterExcess': maximum_outer_excess, 'horizontalRejections': horizontal_rejections,
                        'maximumOriginalOuterExcess': maximum_original_outer_excess,
                        'nonpenetrationAndStancePreview': bool(bound <= 4.9 and maximum_drop <= 8 and minimum_inner_slack >= 0 and maximum_original_outer_excess <= 0 and horizontal_rejections == 0 and minimum_gap >= 0),
                        'composedSupportFiniteSchedules': schedules})
    # Geometry-only reverse uses the same original mask, not an invented DOWN controller/body state.
    reverse_gap = math.inf
    for index in range(1, 10000):
        u = index / 10000
        p = point(1 - u * u * (3 - 2 * u))
        p[2] += 3 * math.sin(u * math.pi)
        reverse_gap = min(reverse_gap, float(np.min((p + offsets)[:, 2] - ground((p + offsets)[:, 1]))))
    result = {'scope': 'Frozen NW original-source/Qidentity/C0 up-step only; same old body transfer, no runtime or natural acceptance',
              'worldSha256': pins['fixtureWorldSha256'], 'sourceAtlasSha256': hashlib.sha256(image_path.read_bytes()).hexdigest(),
              'originalPoints': len(pixels), 'knots': [k.tolist() for k in knots], 'arcXYZ': arc, 'durationUnits': 'accepted ACTOR world XY, never foot arc',
              'contacts': 'Only fixed final96 landing; intermediate84 waypoint is NOT a contact', 'results': results,
              'reverseGeometryOnlyMinimumGap': reverse_gap, 'reverseAnatomyVerified': False,
              'fullAirborneMarginVerified': False,
              'limitations': ['frozen source view and original mask', 'no changing Q/pivot', 'no real triangle/native/controller proof', 'reversed geometry is not actual DOWN anatomy', 'duration below nominal changes cadence and needs explicit review']}
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, indent=2) + '\n')
    print(json.dumps(result, indent=2))


if __name__ == '__main__':
    main()
