#!/usr/bin/env python3
"""Independently assess recorded actual rig joints, including preserved rejections."""
import argparse,json,math
from pathlib import Path
parser=argparse.ArgumentParser()
parser.add_argument('record',type=Path)
parser.add_argument('--expect-rejected',action='store_true')
args=parser.parse_args()
record=json.loads(args.record.read_text())
pose=record['pose']
measurements={}
for side,foot in pose['contacts']['feet'].items():
    upper=math.dist(foot['hipWorld'],foot['kneeWorld'])
    lower=math.dist(foot['kneeWorld'],foot['ankleWorld'])
    length_error=max(abs(upper-foot['lengths'][0]),abs(lower-foot['lengths'][1]))
    direct=math.dist(foot['hipWorld'],foot['ankleWorld'])
    measurements[side]={'actualUpper':upper,'actualLower':lower,
                        'lengthError':length_error,'hipAnkleDistance':direct,
                        'authoredReach':sum(foot['lengths']),
                        'directBeyondReach':direct>sum(foot['lengths'])+.003}
rejected=not pose['reachValid'] or pose['requestedDropPixels']>8 or any(m['lengthError']>.003 for m in measurements.values())
assert rejected==args.expect_rejected,('Unexpected acceptance status',record.get('message'),measurements)
print(json.dumps({'status':'EXPECTED REJECTION' if rejected else 'JOINTS VALID ONLY; not full visual acceptance',
                  'position':record['position'],'direction':pose['direction'],
                  'requestedDropPixels':pose['requestedDropPixels'],'feet':measurements},indent=2))
