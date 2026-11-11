#!/usr/bin/env python3
"""Frozen ridge resume geometry with original source masks; no runtime proof."""
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
    rows = [json.loads(line) for line in (args.run / 'samples.jsonl').read_text().splitlines()]
    rejected = json.loads((args.run / 'rejected.json').read_text())
    pin = json.loads((args.run / 'source.json').read_text())
    assert hashlib.sha256(args.world.read_bytes()).hexdigest() == pin['fixtureWorldSha256']
    case = 'forest_ridge_steps/false/false'
    prior = next(row for row in reversed(rows) if row['case'] == case + ' paused-on-connector')
    resumed = next(row for row in rows if row['case'] == case + ' travel' and
                   row['physicsFrame'] > prior['physicsFrame'])
    p = prior['pose']; c = p['contacts']; foot = c['feet']['left']
    plan = resumed['pose']['contacts']['feet']['left']['treadPlan']
    assert p['direction'] == 'north_west' and foot['footDirection'] == 'north'
    assert foot['footPlane']['rotation'] == [0.0, 0.0, 0.0, 1.0]
    data_path = root / 'client-godot/resources/art/player-lower-body/male-nusantara-daily-v1.json'
    data = json.loads(data_path.read_text())
    atlas_path = root / 'client-godot' / data['source'].removeprefix('res://')
    image = Image.open(atlas_path).convert('RGBA')
    v = math.cos(math.radians(35)); right = np.array([math.sqrt(.5), -math.sqrt(.5), 0.0])

    def original(view, side):
        entry = data['views'][view]; leg = entry['legs'][side]; rect = leg['parts']['foot']
        sole = np.array(leg['solePixel']); pixels = set(map(tuple, leg['soleEdgePixels']))
        for y in range(rect[3]):
            for x in range(rect[2]):
                if image.getpixel((entry['sourceColumn'] * 128 + rect[0] + x, rect[1] + y))[3] >= 128:
                    pixels.update([(x, y), (x + 1, y), (x, y + 1), (x + 1, y + 1)])
        pixels = np.array(sorted(pixels)); offsets = (pixels[:, :1] - sole[0]) * right
        offsets[:, 2] = (sole[1] - pixels[:, 1]) / v
        ankle = np.array(leg['ankle']) - np.array(rect[:2])
        a = right * (ankle[0] - sole[0]); a[2] = (sole[1] - ankle[1]) / v
        return offsets, a

    current, current_a = original('north', 'left'); future, future_a = original('north_west', 'left')
    _, fixed_a = original('north_west', 'right')
    fixed = np.array(vector(c['feet']['right']['sole'])) + fixed_a
    pivot = np.array(foot['pivotCorrectionWorld'])
    start = np.array(vector(plan['fromWorld'])); target = np.array(vector(plan['toWorld']))
    assert np.linalg.norm(start + pivot + current_a - np.array(foot['ankleWorld'])) < .003
    hub = json.loads(args.world.read_text())['landMaps']['hub']
    profile = next(s for s in hub['stairs'] if s['id'] == plan['connectorId'])
    levels = {t['id']: t['elevation'] * 48 for t in hub['terraces']}
    a, b = profile['path']; z0, z1 = levels[profile['from']], levels[profile['to']]
    world_y = lambda y, z: -y / math.cos(math.radians(55)) - z * math.tan(math.radians(55))
    first_y, last_y = world_y(a[1], z0), world_y(b[1], z1)

    def ground(y):
        progress = (y - first_y) / (last_y - first_y)
        return np.where(progress < 0, z0, np.where(progress > 1, z1,
                        z0 + (z1 - z0) * (np.clip(np.floor(progress * profile['steps']), 0, profile['steps'] - 1) + 1) / profile['steps']))

    at = np.array(prior['position']); progress = (at[1] - a[1]) / (b[1] - a[1])
    actor_y = first_y + progress * (last_y - first_y)
    body_legs = data['views']['north_west']['legs']
    radii = {side: (abs(math.dist(l['hip'], l['knee']) - math.dist(l['knee'], l['ankle'])) / v,
                   (math.dist(l['hip'], l['knee']) + math.dist(l['knee'], l['ankle'])) / v - .1)
             for side, l in body_legs.items()}
    tangent = target[:2] - start[:2]; span = np.linalg.norm(tangent); tangent /= span
    candidates = []
    for shape in ['current_mask', 'current_then_future_envelope']:
        leading = max(current[:, 1]) + max(0, pivot[1])
        if shape != 'current_mask': leading = max(leading, max(future[:, 1]) + max(0, pivot[1]))
        knots = [start]
        for step in range(profile['steps']):
            height = z0 + (z1 - z0) * (step + 1) / profile['steps']
            if height <= start[2] or height > target[2]: continue
            edge = first_y + step / profile['steps'] * (last_y - first_y)
            distance = max(0, (edge - leading - .02 - start[1]) / tangent[1])
            if distance >= span: continue
            point = start.copy(); point[:2] += tangent * distance
            point[2] = height - min(0, pivot[2])
            knots.append(point)
        knots.append(target); knots = np.array(knots)
        lengths = np.linalg.norm(np.diff(knots, axis=0), axis=1); arc = float(np.sum(lengths))
        for stitch in ['legacy_constant', 'continuous_taper']:
            stitch_reserve = .08 + abs(float(pivot[2])) if stitch == 'continuous_taper' else 0.0
            duration = max(10, math.ceil((1.5 * arc + 3 * math.pi + np.linalg.norm(pivot) + stitch_reserve) / 4.9 * 4) / 4)
            def raw_point(fraction):
                distance = fraction * fraction * (3 - 2 * fraction) * arc
                point = np.array([np.interp(distance, np.r_[0, np.cumsum(lengths)], knots[:, i]) for i in range(3)])
                point[2] += 3 * math.sin(fraction * math.pi)
                return point

            floor_jumps = []
            for step in range(profile['steps']):
                edge = first_y + step / profile['steps'] * (last_y - first_y)
                if not start[1] < edge < target[1]: continue
                low, high = 0.0, 1.0
                for _ in range(60):
                    middle = (low + high) * .5
                    if raw_point(middle)[1] < edge: low = middle
                    else: high = middle
                fraction = (low + high) * .5
                checks = []
                for probe in [fraction - 1e-9, fraction + 1e-9]:
                    point = raw_point(probe)
                    margin = .02 if stitch == 'legacy_constant' else .08 * probe * (1 - probe)
                    compensate = 0 if stitch == 'legacy_constant' else max(0, -pivot[2] * (1 - probe))
                    floor = float(ground(point[1]))
                    slack = float(point[2] - floor - margin - compensate)
                    checks.append({'u': probe, 'floor': floor, 'unclampedSupportSlack': slack})
                assert min(check['unclampedSupportSlack'] for check in checks) > 0
                floor_jumps.append({'riserIndex': step, 'u': fraction, 'oneSided': checks, 'clampInactive': True})
            speed_inside = (last_y - first_y) / abs(b[1] - a[1]) * 80.0
            schedules = {'uniform_10000_phase': np.linspace(0, duration, 10001),
                             'endpoint_logarithmic': np.r_[np.linspace(0, .9 * duration, 1001), duration * (1 - 10.0 ** -np.arange(1, 10)), duration]}
            for hz in [30, 60, 120, 2000]:
                schedules[str(hz) + 'Hz_frozen_speed'] = np.r_[0, np.arange(speed_inside / hz, duration, speed_inside / hz), duration]
            observed = [float(row['pose']['contacts']['acceptedDistance']) - float(c['acceptedDistance']) for row in rows
                        if row['case'] == case + ' travel' and row['physicsFrame'] > prior['physicsFrame']]
            schedules['original_accepted_distance_schedule'] = np.r_[0, [d for d in observed if 0 < d < duration], duration]
            for schedule, phase in schedules.items():
                phase = np.unique(phase)
                assert np.all(np.diff(phase) > 0)
                u = phase / duration; smooth = u * u * (3 - 2 * u)
                positions = np.column_stack([np.interp(smooth * arc, np.r_[0, np.cumsum(lengths)], knots[:, i]) for i in range(3)])
                positions[:, 2] += 3 * np.sin(u * math.pi)
                margin = np.full(len(u), .02) if stitch == 'legacy_constant' else .08 * u * (1 - u)
                compensation = 0 if stitch == 'legacy_constant' else np.maximum(0, -pivot[2] * (1 - u))
                positions[:, 2] = np.maximum(positions[:, 2], ground(positions[:, 1]) + margin + compensation)
                positions[-1] = target
                for view_policy in ['hold_current_until_contact', 'earliest_clear_adjacent']:
                    correction = pivot[None, :] * (1 - u[:, None]); ankle = positions + correction + current_a
                    view_switched = None; terminal_coefficient = pivot.copy(); gaps = np.min((positions[:, None, :] + correction[:, None, :] + current)[..., 2] -
                                                   ground((positions[:, None, :] + correction[:, None, :] + current)[..., 1]), axis=1)
                    if view_policy == 'earliest_clear_adjacent':
                        trial_c = correction + current_a - future_a
                        trial_points = positions[:, None, :] + trial_c[:, None, :] + future
                        trial_gap = np.min(trial_points[..., 2] - ground(trial_points[..., 1]), axis=1)
                        eligible = np.flatnonzero((u > 0) & (u < .85) & (trial_gap >= .02))
                        if len(eligible):
                            index = int(eligible[0]); view_switched = float(u[index] * duration)
                            terminal_coefficient = pivot + (current_a - future_a) / (1 - u[index])
                            correction[index:] += (current_a - future_a) * ((1 - u[index:, None]) / (1 - u[index]))
                            ankle[index:] = positions[index:] + correction[index:] + future_a
                            points = positions[index:, None, :] + correction[index:, None, :] + future
                            gaps[index:] = np.min(points[..., 2] - ground(points[..., 1]), axis=1)
                    body = np.minimum(128, float(c['bodyHeight']) + phase)
                    hips = {side: np.array([at[0], actor_y, 28 / v]) + np.column_stack([np.zeros(len(u)), phase, body]) +
                            right * (leg['hip'][0] - 64) for side, leg in body_legs.items()}
                    ankles = {'left': ankle, 'right': np.repeat(fixed[None, :], len(u), axis=0)}
                    drop = np.zeros(len(u)); horizontal_invalid = 0
                    for side in hips:
                        h2 = np.sum((hips[side][:, :2] - ankles[side][:, :2]) ** 2, axis=1)
                        horizontal_invalid += int(np.sum(h2 >= radii[side][1] ** 2))
                        drop = np.maximum(drop, hips[side][:, 2] - ankles[side][:, 2] - np.sqrt(np.maximum(.001, radii[side][1] ** 2 - h2)))
                    inner_slack = math.inf; outer_excess = -math.inf
                    for side in hips:
                        actual_hip = hips[side].copy(); actual_hip[:, 2] -= np.clip(drop, 0, 8 / v)
                        dist = np.linalg.norm(actual_hip - ankles[side], axis=1)
                        inner_slack = min(inner_slack, float(np.min(dist - radii[side][0])))
                        outer_excess = max(outer_excess, float(np.max(dist - radii[side][1])))
                    changes = np.linalg.norm(np.diff(ankle, axis=0), axis=1)
                    speed = float(np.max(changes / np.diff(phase)))
                    ankle_violations = int(np.sum(changes > np.diff(phase) * 5 + .003))
                    candidates.append({'shape': shape, 'schedule': schedule, 'stitch': stitch, 'viewPolicy': view_policy, 'knots': knots.tolist(), 'arcXYZ': arc,
                                       'duration': duration, 'basePlusInitialPivotDerivativeBound': (1.5 * arc + 3 * math.pi + np.linalg.norm(pivot) + stitch_reserve) / duration,
                                       'maximumDropPixels': float(np.max(drop) * v), 'innerSlack': inner_slack,
                                       'outerExcess': outer_excess, 'horizontalInvalidSamples': horizontal_invalid,
                                       'minimumOpaqueGroundGap': float(np.min(gaps[1:-1])), 'maximumAnkleRatio': speed, 'ankleGuardViolationSamples': ankle_violations,
                                       'terminalContactError': float(np.linalg.norm(positions[-1] + correction[-1] - target)),
                                       'taperEndpointDerivativePerAccepted': float(np.linalg.norm(terminal_coefficient + np.array([0, 0, 3 * math.pi])) / duration),
                                       'initialPivotDerivativeNorm': float(np.linalg.norm(pivot) / duration),
                                       'terminalPivotDerivativeNorm': float(np.linalg.norm(terminal_coefficient) / duration),
                                   'stitchDerivativeReserve': stitch_reserve, 'centerFloorJumpChecks': floor_jumps,
                                       'sourceSwitchAtAcceptedDistance': view_switched,
                                       'terminalSource': 'north_west' if view_switched else 'north',
                                       'finiteFrozenGeometryOnly': True})
    terminal_gaps = {name: float(np.min((target + offsets)[:, 2] - ground((target + offsets)[:, 1]))) for name, offsets in [('north', current), ('north_west', future)]}
    assert min(terminal_gaps.values()) >= 0
    chosen = [item for item in candidates if item['shape'] == 'current_mask' and item['stitch'] == 'continuous_taper' and item['viewPolicy'] == 'earliest_clear_adjacent']
    assert len(chosen) == 7
    assert all(item['ankleGuardViolationSamples'] == 0 and item['maximumDropPixels'] <= 8 and item['innerSlack'] > 0 and item['outerExcess'] < 1e-10 and item['horizontalInvalidSamples'] == 0 and item['minimumOpaqueGroundGap'] >= 0 and item['terminalContactError'] == 0 and item['taperEndpointDerivativePerAccepted'] < 5 and item['basePlusInitialPivotDerivativeBound'] <= 4.9 for item in chosen)
    assert any(item['stitch'] == 'legacy_constant' and item['schedule'] == 'uniform_10000_phase' and item['ankleGuardViolationSamples'] > 0 for item in candidates)
    result = {'terminalFullMaskGroundGaps': terminal_gaps, 'sourceWorld': pin['fixtureWorldSha256'], 'dataSha256': hashlib.sha256(data_path.read_bytes()).hexdigest(),
              'atlasSha256': hashlib.sha256(atlas_path.read_bytes()).hexdigest(), 'prior': prior,
              'retainedTarget': target.tolist(), 'initialPivot': pivot.tolist(), 'candidates': candidates,
              'continuumProof': False, 'nextStepCouplingProof': False, 'runtimeAccepted': False}
    args.output.write_text(json.dumps(result, indent=2, allow_nan=False) + '\n')
    print(json.dumps(candidates, indent=2))


if __name__ == '__main__':
    main()
