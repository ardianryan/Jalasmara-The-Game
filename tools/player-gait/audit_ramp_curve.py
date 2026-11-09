#!/usr/bin/env python3
"""CPU reconstruction of two recorded ramp poses; does not run or change Godot."""
import argparse
import hashlib
import json
import math
from pathlib import Path
from check_stair_contacts import vector, profile_definitions

COS = math.cos(math.radians(55))
TAN = math.tan(math.radians(55))


def length(v):
    return math.sqrt(sum(x*x for x in v))


def sub(a, b):
    return tuple(x-y for x, y in zip(a, b))


def lerp(a, b, t):
    return tuple(x + (y-x)*t for x, y in zip(a, b))


def inside(point, polygon):
    x, y = point
    result = False
    for a, b in zip(polygon, polygon[1:] + polygon[:1]):
        if (a[1] > y) != (b[1] > y) and x < (b[0]-a[0])*(y-a[1])/(b[1]-a[1])+a[0]:
            result = not result
    return result


class Ground:
    def __init__(self, world):
        self.hub = world['landMaps']['hub']
        self.profiles = profile_definitions(world)

    def point(self, p):
        height, priority = 0.0, -10000
        for surface in self.hub['surfaces']:
            if surface.get('priority', 0) >= priority and inside(p, surface['polygon']):
                height, priority = surface.get('elevation', 0)*48, surface.get('priority', 0)
        linear = height
        for profile in self.profiles.values():
            a, b = profile['path'][:2]
            delta, relative = sub(b, a), sub(p, a)
            t = sum(x*y for x, y in zip(relative, delta))/sum(x*x for x in delta)
            across = length(sub(p, lerp(a, b, max(0, min(1, t)))))
            if 0 <= t <= 1 and across <= profile['width']*.5:
                linear = profile['startHeight'] + (profile['endHeight']-profile['startHeight'])*t
                if profile['type'] == 'ramp':
                    height = linear
                else:
                    ordinal = min(profile['steps'], math.floor(t*profile['steps'])+1)
                    height = profile['startHeight'] + (profile['endHeight']-profile['startHeight'])*ordinal/profile['steps']
                break
        return p[0], -p[1]/COS-linear*TAN, height

    def cuts(self, a, b):
        fractions = {0.0, 1.0}
        delta = sub(b, a)
        for profile in self.profiles.values():
            start, end = profile['path'][:2]
            axis = sub(end, start)
            size = length(axis)
            tangent = tuple(v/size for v in axis)
            normal = (-tangent[1], tangent[0])
            local_a = [sum(x*y for x, y in zip(sub(a, start), basis)) for basis in (tangent, normal)]
            local_delta = [sum(x*y for x, y in zip(delta, basis)) for basis in (tangent, normal)]
            width = profile['width']*.5
            for axis_index, boundaries in enumerate(((0, size), (-width, width))):
                if local_delta[axis_index] == 0:
                    continue
                for boundary in boundaries:
                    t = (boundary-local_a[axis_index])/local_delta[axis_index]
                    other = 1-axis_index
                    q = local_a[other]+local_delta[other]*t
                    lower, upper = (-width, width) if other == 1 else (0, size)
                    if .00001 < t < .99999 and lower <= q <= upper:
                        fractions.add(t)
        return sorted(fractions)

    def metrics(self, a, b, cuts=True):
        fractions = self.cuts(a, b) if cuts else [0.0, 1.0]
        points = [self.point(lerp(a, b, t)) for t in fractions]
        spans = [length(sub(q[:2], p[:2])) for p, q in zip(points, points[1:])]
        return fractions, spans, sum(spans), sum(length(sub(q, p)) for p, q in zip(points, points[1:]))

    def inverse(self, a, b, distance, cuts=True):
        fractions, spans, total, _ = self.metrics(a, b, cuts)
        remaining = max(0, min(total, distance))
        for i, span in enumerate(spans):
            if remaining <= span or i == len(spans)-1:
                t = fractions[i]+(fractions[i+1]-fractions[i])*remaining/max(.00001, span)
                return lerp(a, b, t)
            remaining -= span
        return b

    def forward(self, base, distance, cuts):
        scale = length(sub(self.point((base[0], base[1]-1))[:2], self.point(base)[:2]))
        offset = distance/max(.001, scale)
        target = (base[0], base[1]-offset)
        _, _, total, _ = self.metrics(base, target, cuts)
        if abs(total-distance) < .001:
            return target
        for _ in range(8):
            if total >= distance:
                break
            offset *= 2
            target = (base[0], base[1]-offset)
            _, _, total, _ = self.metrics(base, target, cuts)
        return self.inverse(base, target, distance, cuts)


def curve(ground, record, cuts, target=None):
    contacts = record['pose']['contacts']
    foot = contacts['feet']['left']
    a, b = vector(foot['from']), target or vector(foot['to'])
    first, last = vector(foot['fromWorld']), ground.point(b)
    u = contacts['swingDistance']/contacts['landingDistance']
    rise = last[2]-first[2]
    window = max(.25, min(.65, abs(rise)/(contacts['landingDistance']*3)))
    advance = max(0, min(1, (u-window*.5)/(1-window*.5))) if rise > 0 else max(0, min(1, u/(1-window*.5)))
    elevation = max(0, min(1, u/window)) if rise > 0 else max(0, min(1, (u-(1-window))/window))
    smooth = advance*advance*(3-2*advance)
    rise_smooth = elevation*elevation*(3-2*elevation)
    _, _, total, arc_xyz = ground.metrics(a, b, cuts)
    logical = ground.inverse(a, b, smooth*total, cuts)
    floor = ground.point(logical)
    z = max(lerp(first, last, rise_smooth)[2] + math.sin(u*math.pi)*3, floor[2]+.02)
    correction = foot['pivotCorrectionWorld']
    sole = [floor[0]+correction[0], floor[1]+correction[1], z+correction[2]]
    return {'logical': logical, 'soleWithRecordedPivot': sole, 'arcXY': total, 'arcXYZ': arc_xyz,
            'chordXYZ': length(sub(last, first)), 'smooth': smooth}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--world', type=Path, required=True)
    parser.add_argument('--run', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--comparison-run', type=Path)
    args = parser.parse_args()
    raw = args.world.read_bytes()
    source = json.loads((args.run/'source.json').read_text())
    assert hashlib.sha256(raw).hexdigest() == source['fixtureWorldSha256']
    ground = Ground(json.loads(raw))
    previous = json.loads((args.run/'samples.jsonl').read_text().splitlines()[-1])
    rejected = json.loads((args.run/'rejected.json').read_text())
    poses = [previous, rejected]
    rows = []
    for record in poses:
        foot = record['pose']['contacts']['feet']['left']
        old = curve(ground, record, False)
        new = curve(ground, record, True)
        at = record['position']
        # This basis is inferred from the recorded after-entry target, not captured metadata.
        lateral = foot['lateralOffset']
        world_y = -lateral*math.sqrt(.5)
        derivative = ground.point((at[0], at[1]+1))[1]-ground.point(at)[1]
        base = (at[0]+lateral*math.sqrt(.5), at[1]+world_y/derivative)
        distance = record['pose']['contacts']['landingDistance']-record['pose']['contacts']['swingDistance']+record['pose']['contacts']['landingLead']
        forwards = {}
        for cuts in (False, True):
            target = ground.forward(base, distance, cuts)
            forwards['allCuts' if cuts else 'oldCuts'] = {'logical': target, 'world': ground.point(target)}
        rows.append({'actor': at, 'phaseDistance': record['pose']['contacts']['swingDistance'],
                     'capturedTarget': vector(foot['toWorld']), 'capturedLogicalTarget': vector(foot['to']),
                     'oldCurveFromCapturedTarget': old, 'allCutsCurveFromCapturedTarget': new,
                     'oldSoleReconstructionError': length(sub(old['soleWithRecordedPivot'], vector(foot['sole']))),
                     'provisionalBase': base, 'provisionalForward': forwards})
    delta_physical = rejected['pose']['contacts']['acceptedDistance']-previous['acceptedPhysical']
    comparison = {}
    for key in ('oldCurveFromCapturedTarget', 'allCutsCurveFromCapturedTarget'):
        comparison[key] = length(sub(rows[1][key]['soleWithRecordedPivot'], rows[0][key]['soleWithRecordedPivot']))
    fixed = [curve(ground, record, True, vector(previous['pose']['contacts']['feet']['left']['to'])) for record in poses]
    comparison['allCutsRetainedPriorTargetDiagnosticOnly'] = length(sub(fixed[1]['soleWithRecordedPivot'], fixed[0]['soleWithRecordedPivot']))
    assert max(row['oldSoleReconstructionError'] for row in rows) < .002, 'Old captured curve reconstruction differs beyond serialization rounding'
    result = {'worldSha256': source['fixtureWorldSha256'], 'originalRejection': rejected['message'], 'sourceFiles': source['files'],
              'acceptedPhysical': delta_physical, 'ankleGuard': delta_physical*5,
              'capturedAnkleDistance': length(sub(rejected['pose']['contacts']['feet']['left']['ankleWorld'], previous['pose']['contacts']['feet']['left']['ankleWorld'])),
              'capturedTargetDistance': length(sub(rows[1]['capturedTarget'], rows[0]['capturedTarget'])),
              'rows': rows, 'comparison': comparison,
              'limits': ['CPU scalar reconstruction; serialization introduces rounding; not a runtime pass',
                         'Captured targets isolate inverse-path changes; does not imply corrected forward targets',
                         'Provisional inferred camera basis fails to reproduce prior forward target; do not claim cuts alone fixes retarget',
                         'Retained target is diagnostic only; no runtime freeze proposed or installed']}
    if args.comparison_run:
        compare_source = json.loads((args.comparison_run/'source.json').read_text())
        assert compare_source['fixtureWorldSha256'] == source['fixtureWorldSha256']
        observations = [json.loads(line) for line in (args.comparison_run/'samples.jsonl').read_text().splitlines()]
        matched = []
        for original in poses:
            matches = [record for record in observations if length(sub(record['position'], original['position'])) < .00001]
            assert len(matches) == 1, 'Need exactly one actual matching actor position per comparison pose'
            record = matches[0]
            foot = record['pose']['contacts']['feet']['left']
            reconstructed = curve(ground, record, True)
            error = length(sub(reconstructed['soleWithRecordedPivot'], vector(foot['sole'])))
            assert error < .002, 'All-cuts captured curve differs beyond serialization rounding'
            matched.append({'record': record, 'reconstructionError': error})
        first, last = [entry['record'] for entry in matched]
        accepted = last['acceptedPhysical']-first['acceptedPhysical']
        delta = length(sub(last['pose']['contacts']['feet']['left']['ankleWorld'], first['pose']['contacts']['feet']['left']['ankleWorld']))
        result['actualAllCutsComparison'] = {
            'run': str(args.comparison_run), 'sourceFiles': compare_source['files'],
            'positions': [record['position'] for record in (first, last)],
            'targets': [vector(record['pose']['contacts']['feet']['left']['toWorld']) for record in (first, last)],
            'soleReconstructionErrors': [entry['reconstructionError'] for entry in matched],
            'acceptedPhysical': accepted, 'ankleDelta': delta, 'guard': accepted*5,
            'formerCrossingPass': delta <= accepted*5,
            'continuingRejection': json.loads((args.comparison_run/'rejected.json').read_text())['message'],
            'scope': 'Actual former failing pair only; continuing run is still rejected'}
    with args.output.open('x') as stream:
        json.dump(result, stream, indent=2)
        stream.write('\n')
    print(json.dumps({k: result[k] for k in ('acceptedPhysical', 'ankleGuard', 'capturedAnkleDistance', 'capturedTargetDistance', 'comparison')}, indent=2))


if __name__ == '__main__':
    main()
