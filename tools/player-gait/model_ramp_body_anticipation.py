#!/usr/bin/env python3
"""Replay one frozen reversal's body preparation from its original shoe footprint."""
import argparse
import hashlib
import json
import math
import re
from pathlib import Path

from PIL import Image


def vector(value):
    if isinstance(value, str):
        return tuple(map(float, re.findall(r'[-+]?\d+(?:\.\d+)?(?:[eE][-+]?\d+)?', value)))
    return tuple(value)


def add(a, b):
    return tuple(x + y for x, y in zip(a, b))


def scale(a, k):
    return tuple(x * k for x in a)


def cross(a, b):
    return (a[1]*b[2]-a[2]*b[1], a[2]*b[0]-a[0]*b[2], a[0]*b[1]-a[1]*b[0])


def rotate(q, point):
    return add(point, scale(cross(q[:3], add(cross(q[:3], point), scale(point, q[3]))), 2))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--character-root', type=Path, required=True)
    parser.add_argument('--run', type=Path, required=True)
    parser.add_argument('--world', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    rejected = json.loads((args.run/'rejected.json').read_text())
    source = json.loads((args.run/'source.json').read_text())
    assert hashlib.sha256(args.world.read_bytes()).hexdigest() == source['fixtureWorldSha256']
    rows = [json.loads(line) for line in (args.run/'samples.jsonl').read_text().splitlines()]
    label = rejected['recentTrace'][-1]['case'].split(' ')[0]
    previous = [row for row in rows if row['case'].startswith(label+' travel')][-1]
    foot = rejected['pose']['contacts']['feet']['right']
    old_foot = previous['pose']['contacts']['feet']['right']
    assert rejected['pose']['direction'] == previous['pose']['direction'] == 'north_west'
    assert foot['footPlane']['rotation'] == old_foot['footPlane']['rotation']
    assert foot['fixedRampTarget'] and foot['rampCurvePlan']['valid']
    phase0 = previous['pose']['contacts']['swingDistance']
    phase_end = rejected['pose']['contacts']['swingDistance']
    duration = rejected['pose']['contacts']['landingDistance']
    q = foot['footPlane']['rotation']
    vertical_scale = 1/math.cos(math.radians(35))
    right = (math.sqrt(.5), -math.sqrt(.5), 0)
    data_path = args.character_root/'client-godot/resources/art/player-lower-body/male-nusantara-daily-v1.json'
    data = json.loads(data_path.read_text())
    view = data['views']['north_west']
    leg = view['legs']['right']
    rect, sole = leg['parts']['foot'], leg['solePixel']
    ankle_local = (leg['ankle'][0]-rect[0], leg['ankle'][1]-rect[1])
    image_path = args.character_root/'client-godot'/data['source'].removeprefix('res://')
    image = Image.open(image_path).convert('RGBA')
    corners = set()
    for y in range(rect[3]):
        for x in range(rect[2]):
            if image.getpixel((view['sourceColumn']*128+rect[0]+x, rect[1]+y))[3] >= 128:
                corners.update([(x,y), (x+1,y), (x+1,y+1), (x,y+1)])
    original = corners | {tuple(p) for p in leg['soleEdgePixels']}
    def offset(point):
        x,y = point
        return rotate(q, add(scale(right,x-ankle_local[0]), (0,0,(ankle_local[1]-y)*vertical_scale)))
    ankle_offset = rotate(q, add(scale(right,ankle_local[0]-sole[0]), (0,0,(sole[1]-ankle_local[1])*vertical_scale)))
    start = vector(foot['fromWorld'])
    path_xy = foot['rampCurvePlan']['fixedPathWorldXY']
    hub = json.loads(args.world.read_text())['landMaps']['hub']
    ramp = next(row for row in hub['stairs'] if row['id']=='dock_gangway')
    levels = {row['id']: row['elevation']*48 for row in hub['terraces']}
    low, high = levels[ramp['from']], levels[ramp['to']]
    tilt = math.radians(55)
    low_y = -ramp['path'][0][1]/math.cos(tilt)-low*math.tan(tilt)
    crest_y = -ramp['path'][1][1]/math.cos(tilt)-high*math.tan(tilt)
    slope = (high-low)/(crest_y-low_y)
    def ground_y(y):
        return min(high,max(low,low+(y-low_y)*slope))
    assert slope>0
    extrema={}
    for points in [corners,original]:
        offsets=[offset(point) for point in points]
        extrema[id(points)]=(min(p[0] for p in offsets),max(p[0] for p in offsets),min(p[1] for p in offsets))
    def shadow(phase, points):
        u = phase/duration
        smooth = u*u*(3-2*u)
        correction = scale(old_foot['pivotCorrectionWorld'],(duration-phase)/(duration-phase0))
        ankle_xy = add((start[0],start[1]-path_xy*smooth,0), add(correction,ankle_offset))
        min_x,max_x,min_y=extrema[id(points)]
        assert all(abs(ankle_xy[0]+x-ramp['path'][0][0]) < ramp['width']/2 for x in [min_x,max_x])
        leading_y=ankle_xy[1]+min_y
        return leading_y,ground_y(leading_y)
    def integrate(points, step):
        body = high
        phase = phase0
        while phase < phase_end:
            nxt = min(phase_end,phase+step)
            target = min(high,shadow(nxt,points)[1])
            body = max(target,body-(nxt-phase)) if body>target else min(target,body+(nxt-phase))
            phase=nxt
        return body
    def crossing(points):
        lo,hi = phase0,phase_end
        for _ in range(60):
            p=(lo+hi)/2
            if shadow(p,points)[0]>crest_y: lo=p
            else: hi=p
        return (lo+hi)/2
    def center_crossing():
        lo,hi=0.0,duration
        for _ in range(60):
            p=(lo+hi)/2
            u=p/duration
            if start[1]-path_xy*u*u*(3-2*u)>crest_y: lo=p
            else: hi=p
        return (lo+hi)/2
    body_old = rejected['pose']['contacts']['bodyHeight']
    required_body = body_old-(rejected['pose']['requestedDropPixels']-8)*vertical_scale
    body = integrate(original,.0005)
    finer = integrate(original,.00025)
    assert abs(body-finer)<.001
    candidate_drop = rejected['pose']['requestedDropPixels']-(body_old-body)/vertical_scale
    annuli={}
    actor=rejected['position']
    world_xy=(actor[0],-actor[1]/math.cos(tilt)-high*math.tan(tilt))
    for side in ['left','right']:
        entry=rejected['pose']['contacts']['feet'][side]
        source_leg=view['legs'][side]
        if side=='right': ankle=entry['supportPlanTranslation']['after']
        else:
            source_ankle=(source_leg['ankle'][0]-source_leg['parts']['foot'][0],source_leg['ankle'][1]-source_leg['parts']['foot'][1])
            point=add(scale(right,source_ankle[0]-source_leg['solePixel'][0]),(0,0,(source_leg['solePixel'][1]-source_ankle[1])*vertical_scale))
            ankle=add(vector(entry['sole']),rotate(entry['footPlane']['rotation'],point))
        hip=(world_xy[0]+right[0]*(source_leg['hip'][0]-64),world_xy[1]+right[1]*(source_leg['hip'][0]-64),body+28*vertical_scale-max(0,candidate_drop)*vertical_scale)
        first=math.dist(source_leg['hip'],source_leg['knee'])*vertical_scale
        second=math.dist(source_leg['knee'],source_leg['ankle'])*vertical_scale
        distance=math.dist(hip,ankle)
        assert abs(first-second)<=distance<=first+second
        annuli[side]={'hipToAnkle':distance,'originalInner':abs(first-second),'originalOuter':first+second}
    offsets_original=[offset(point) for point in original]
    left_entry=rejected['pose']['contacts']['feet']['left']
    left_leg=view['legs']['left']
    left_ankle=add(vector(left_entry['sole']),(0,0,(left_leg['solePixel'][1]-(left_leg['ankle'][1]-left_leg['parts']['foot'][1]))*vertical_scale))
    def frozen_pose(phase,baseline):
        u=phase/duration
        smooth=u*u*(3-2*u)
        correction=scale(old_foot['pivotCorrectionWorld'],(duration-phase)/(duration-phase0))
        axy=add((start[0],start[1]-path_xy*smooth,0),add(correction,ankle_offset))
        support=max(ground_y(axy[1]+point[1])-point[2] for point in offsets_original)
        ankle=(axy[0],axy[1],support+3*math.sin(math.pi*u)+foot['rampCurvePlan']['fromSupportOffset']*(1-smooth))
        # Actor remains on the captured upper flat throughout this interval.
        actor_x=previous['position'][0]
        actor_y=previous['position'][1]+(phase-phase0)*math.cos(tilt)
        ground=(actor_x,-actor_y/math.cos(tilt)-high*math.tan(tilt),high)
        lower=0.0
        limbs=[]
        for side,actual in [('left',left_ankle),('right',ankle)]:
            limb=view['legs'][side]
            hip=add(ground,add(scale(right,limb['hip'][0]-64),(0,0,baseline-high+28*vertical_scale)))
            first=math.dist(limb['hip'],limb['knee'])*vertical_scale
            second=math.dist(limb['knee'],limb['ankle'])*vertical_scale
            horizontal=(hip[0]-actual[0])**2+(hip[1]-actual[1])**2
            assert horizontal<(first+second-.1)**2
            lower=max(lower,hip[2]-actual[2]-math.sqrt((first+second-.1)**2-horizontal))
            limbs.append((side,hip,actual,first,second))
        measured={}
        for side,hip,actual,first,second in limbs:
            hip=add(hip,(0,0,-lower))
            length=math.dist(hip,actual)
            assert abs(first-second)<=length<=first+second
            measured[side]={'distance':length,'inner':abs(first-second),'outer':first+second}
        return {'dropPixels':lower/vertical_scale,'rightAnkle':ankle,'effectiveHipZ':baseline+28*vertical_scale-lower,'limbs':measured}
    endpoint_modes={}
    for label,steps in [('60hz',[100/60]),('30hz',[100/30]),('mixed',[100/60,100/30,100*.133333333333333]),('capturedMerged',[phase_end-phase0])]:
        phase=phase0
        baseline=high
        count=0
        peak=frozen_pose(phase,baseline)['dropPixels']
        rate_peak=0.0
        while phase<phase_end:
            nxt=min(phase_end,phase+steps[count%len(steps)])
            target=shadow(nxt,original)[1]
            before=baseline
            baseline=max(target,baseline-(nxt-phase)) if baseline>target else min(target,baseline+(nxt-phase))
            rate_peak=max(rate_peak,abs(baseline-before)/(nxt-phase))
            peak=max(peak,frozen_pose(nxt,baseline)['dropPixels'])
            phase=nxt
            count+=1
        assert rate_peak<=1.00000001
        endpoint_modes[label]={'observations':count,'terminalBaseline':baseline,'maxBaselineRate':rate_peak,
                               'maxFrozenNWDropPixelsAtEndpoints':peak,'terminalFrozenNWDropPixels':frozen_pose(phase,baseline)['dropPixels'],
                               'terminalEffectiveHipZAfterDrop':frozen_pose(phase,baseline)['effectiveHipZ'],
                               'terminalOriginalAnnuli':frozen_pose(phase,baseline)['limbs']}
    actual_modeled=frozen_pose(phase_end,body_old)['rightAnkle']
    actual_recorded=foot['supportPlanTranslation']['after']
    assert math.dist(actual_modeled,actual_recorded)<.005
    result = {
        'scope':'Conditional captured constantQ/C-decay footprint replay, not changed body/view/landing feedback or runtime acceptance',
        'sourceRun':str(args.run), 'worldSha256':source['fixtureWorldSha256'],
        'sourceAtlasSha256':hashlib.sha256(image_path.read_bytes()).hexdigest(),
        'alphaVertices':len(corners), 'alphaPlusMarkers':len(original),
        'phaseStart':phase0, 'phaseEnd':phase_end, 'duration':duration,
        'soleCenterCrestPhase':center_crossing(), 'alphaLeadingCrestPhase':crossing(corners),
        'alphaPlusMarkersLeadingCrestPhase':crossing(original),
        'centerOnlyMaximumContinuousDescent':phase_end-center_crossing(),
        'actualBody':body_old, 'bodyRequiredAtUnchanged8px':required_body,
        'requiredTotalDescent':high-required_body,
        'alphaOnlyRate1Body':integrate(corners,.0005), 'alphaPlusMarkersRate1Body':body,
        'finerStepRate1Body':finer, 'bodyIntegrationStep':.0005,
        'conditionalDropFrozenFeet':candidate_drop,
        'bodyMarginTo8px':required_body-body,
        'conditionalFinalOriginalBoneAnnuliFrozenNW':annuli,
        'currentLeadingGroundHeightAtEnd':shadow(phase_end,original)[1],
        'frozenCurrentRightAnkleReplayError':math.dist(actual_modeled,actual_recorded),
        'endpointTimingComparisons':endpoint_modes,
        'timingModeScope':'Frozen NW/Q/C original footprint; reduced motion has no additional change in this CPU formula, not actual reduced fixture proof',
        'sampleOrder':'Hypothetical body target queries original current footprint AFTER current chunk logical/Q/C; old before-chunk query not modeled as fixed',
        'groundScope':'Authored dock continuous bare physical profile, not painted triangle clearance or global floors',
        'notProven':['body and original foot view changes','Q/H/clearance feedback','both-leg annulus across unrecorded frames','discrete runtime chunk scheduling','six-pixel admission','full ascent-descent runtime or native gait']}
    args.output.parent.mkdir(parents=True,exist_ok=True)
    args.output.write_text(json.dumps(result,indent=2)+'\n')
    print(json.dumps(result,indent=2))

if __name__=='__main__':
    main()
