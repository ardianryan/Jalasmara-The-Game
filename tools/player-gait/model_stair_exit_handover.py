#!/usr/bin/env python3
"""Frozen original two-leg stair-exit and next-flat-step geometry, not runtime proof."""
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
    args = parser.parse_args(); root = Path(__file__).resolve().parents[2]
    rejected = json.loads((args.run / 'rejected.json').read_text()); pose = rejected['pose']; contacts = pose['contacts']
    assert pose['direction'] == 'north_west' and contacts['swingSide'] == 'right'
    data = json.loads((root / 'client-godot/resources/art/player-lower-body/male-nusantara-daily-v1.json').read_text())
    image = Image.open(root / 'client-godot' / data['source'].removeprefix('res://')).convert('RGBA')
    view = data['views']['north_west']; v = math.cos(math.radians(35)); right = np.array([2**-.5, -2**-.5, 0])
    offsets = {}; ankle_offsets = {}; radii = {}; sole_offsets = {}
    for side, leg in view['legs'].items():
        rect = leg['parts']['foot']; sole = np.array(leg['solePixel']); pixels = set(map(tuple, leg['soleEdgePixels']))
        for y in range(rect[3]):
            for x in range(rect[2]):
                if image.getpixel((view['sourceColumn'] * 128 + rect[0] + x, rect[1] + y))[3] >= 128:
                    pixels.update([(x,y),(x+1,y),(x,y+1),(x+1,y+1)])
        pixels = np.array(sorted(pixels)); points = (pixels[:, :1] - sole[0]) * right
        points[:, 2] = (sole[1] - pixels[:, 1]) / v; offsets[side] = points
        ankle = np.array(leg['ankle']) - np.array(rect[:2]); local = right * (ankle[0] - sole[0]); local[2] = (sole[1] - ankle[1]) / v
        ankle_offsets[side] = local
        radii[side] = (abs(math.dist(leg['hip'], leg['knee']) - math.dist(leg['knee'], leg['ankle'])) / v,
                       (math.dist(leg['hip'], leg['knee']) + math.dist(leg['knee'], leg['ankle'])) / v - .1)
        sole_offsets[side] = rect[0] + sole[0] - 64
    hub = json.loads(args.world.read_text())['landMaps']['hub']; levels = {t['id']: t['elevation'] * 48 for t in hub['terraces']}
    profile = next(p for p in hub['stairs'] if p['id'] == contacts['feet']['right']['treadPlan']['connectorId'])
    a,b = profile['path']; z0,z1 = levels[profile['from']], levels[profile['to']]
    world_y = lambda y,z: -y / math.cos(math.radians(55)) - z * math.tan(math.radians(55))
    wy0, wy1 = world_y(a[1],z0), world_y(b[1],z1)
    def ground(y):
        progress = (y-wy0)/(wy1-wy0)
        return np.where(progress<0,z0,np.where(progress>1,z1,z0+(z1-z0)*(np.clip(np.floor(progress*profile['steps']),0,profile['steps']-1)+1)/profile['steps']))
    at = rejected['position']; root_y = world_y(at[1],z1)-contacts['swingDistance']; x=at[0]
    event_rows = [json.loads(line) for line in (args.run / 'samples.jsonl').read_text().splitlines()]
    initial_event = next(event for row in event_rows for event in row['pose'].get('contactTrace',{}).get('events',[]) if event['side']=='left' and abs(event['acceptedDistance']-(contacts['acceptedDistance']-contacts['swingDistance']))<.003 and event.get('actualSupport',{}).get('id')==profile['id'])
    initial_body = float(initial_event['bodyHeight'])
    plants = {s:np.array(vector(f['plant'])) for s,f in contacts['feet'].items()}
    start = np.array(vector(contacts['feet']['right']['fromWorld'])); old_target=np.array(vector(contacts['feet']['right']['toWorld']))
    inside_depth=(wy1-wy0)/profile['steps']; qs=[0,inside_depth*.5,inside_depth,float(old_target[1]-wy1)]

    def metrics(side,points,actor_y,body,support):
        n=len(body); ankles={side:points+ankle_offsets[side], 'left' if side=='right' else 'right':np.repeat((support+ankle_offsets['left' if side=='right' else 'right'])[None,:],n,axis=0)}
        hips={s:np.column_stack([np.full(n,x),actor_y,body+28/v])+right*(leg['hip'][0]-64) for s,leg in view['legs'].items()}
        drop=np.zeros(n); bad=0
        for s in hips:
            h=np.sum((hips[s][:,:2]-ankles[s][:,:2])**2,axis=1);bad+=int(np.sum(h>=radii[s][1]**2));drop=np.maximum(drop,hips[s][:,2]-ankles[s][:,2]-np.sqrt(np.maximum(.001,radii[s][1]**2-h)))
        inner=math.inf;outer=-math.inf
        for s in hips:
            hip=hips[s].copy();hip[:,2]-=np.clip(drop,0,8/v);length=np.linalg.norm(hip-ankles[s],axis=1);inner=min(inner,float(np.min(length-radii[s][0])));outer=max(outer,float(np.max(length-radii[s][1])))
        mask=points[:,None,:]+offsets[side];gap=float(np.min(mask[...,2]-ground(mask[...,1])))
        return {'maximumDropPixels':float(np.max(drop)*v),'innerSlack':inner,'outerExcess':outer,'horizontalInvalidSamples':bad,'minimumOpaqueGroundGap':gap}

    pin=json.loads((args.run/'source.json').read_text());assert hashlib.sha256(args.world.read_bytes()).hexdigest()==pin['fixtureWorldSha256']
    results=[];replay=None
    for q in qs:
        target=old_target.copy();target[1]=wy1+q
        span=np.linalg.norm(target[:2]-start[:2]);tangent=(target[:2]-start[:2])/span;knots=[start]
        for step in range(profile['steps']):
            height=z0+(z1-z0)*(step+1)/profile['steps']
            if height<=start[2] or height>target[2]:continue
            edge=wy0+step/profile['steps']*(wy1-wy0);distance=(edge-max(offsets['right'][:,1])-.02-start[1])/tangent[1]
            if 0<distance<span:
                point=start.copy();point[:2]+=tangent*distance;point[2]=height;knots.append(point)
        knots.append(target);knots=np.array(knots);lengths=np.linalg.norm(np.diff(knots,axis=0),axis=1);arc=float(np.sum(lengths));duration=max(10,math.ceil((1.5*arc+3*math.pi+.08)/4.9*4)/4)
        u=np.linspace(0,1,10001);phase=u*duration;s=u*u*(3-2*u);points=np.column_stack([np.interp(s*arc,np.r_[0,np.cumsum(lengths)],knots[:,i]) for i in range(3)]);points[:,2]+=3*np.sin(u*math.pi);points[:,2]=np.maximum(points[:,2],ground(points[:,1])+.08*u*(1-u));points[-1]=target
        body=np.minimum(z1,initial_body+phase);first=metrics('right',points,root_y+phase,body,plants['left']);first['baseCurveBound']=(1.5*arc+3*math.pi+.08)/duration
        first['maximumAnkleRatio']=float(np.max(np.linalg.norm(np.diff(points,axis=0),axis=1)/np.diff(phase)))
        if abs(q-float(old_target[1]-wy1))<1e-8:
            actual_phase=float(contacts['swingDistance']);fraction=actual_phase/duration;arc_at=fraction*fraction*(3-2*fraction)*arc
            point=np.array([np.interp(arc_at,np.r_[0,np.cumsum(lengths)],knots[:,i]) for i in range(3)]);point[2]+=3*math.sin(fraction*math.pi)
            replay=metrics('right',point[None,:],np.array([root_y+actual_phase]),np.array([min(z1,initial_body+actual_phase)]),plants['left'])
            replay['actualDrop']=pose['requestedDropPixels'];replay['absoluteDropError']=abs(replay['maximumDropPixels']-pose['requestedDropPixels']);assert replay['absoluteDropError']<.001
        for policy in ['steady32','existing_short_handover']:
            origin_y=root_y+duration;body0=float(body[-1]);base_y=origin_y+right[1]*sole_offsets['left'];projection=plants['left'][1]-base_y
            next_d=32.0 if policy=='steady32' else max(10,math.ceil(1.5*(16-projection)/2.5))
            next_target=np.array([x,origin_y,z1])+right*sole_offsets['left']+np.array([0,next_d+16,0])
            u=np.linspace(0,1,10001);phase2=u*next_d;s=u*u*(3-2*u);p=plants['left'][None,:]+(next_target-plants['left'])[None,:]*s[:,None];p[:,2]+=3*np.sin(u*math.pi);p[:,2]=np.maximum(p[:,2],ground(p[:,1])+.08*u*(1-u));p[-1]=next_target
            second=metrics('left',p,origin_y+phase2,np.minimum(z1,body0+phase2),target);second['maximumAnkleRatio']=float(np.max(np.linalg.norm(np.diff(p,axis=0),axis=1)/np.diff(phase2)))
            third_origin=origin_y+next_d;third_d=32.0;third_target=np.array([x,third_origin,z1])+right*sole_offsets['right']+np.array([0,third_d+16,0])
            third_phase=u*third_d;third_points=target[None,:]+(third_target-target)[None,:]*s[:,None];third_points[:,2]+=3*np.sin(u*math.pi);third_points[:,2]=np.maximum(third_points[:,2],ground(third_points[:,1])+.08*u*(1-u));third_points[-1]=third_target
            third=metrics('right',third_points,third_origin+third_phase,np.full(len(u),z1),next_target);third['maximumAnkleRatio']=float(np.max(np.linalg.norm(np.diff(third_points,axis=0),axis=1)/np.diff(third_phase)))
            results.append({'targetBeyondBoundaryWorldXY':q,'insideTreadDepth':inside_depth,'firstDuration':duration,'firstArcXYZ':arc,'firstTarget':target.tolist(),'first':first,'nextPolicy':policy,'nextDuration':next_d,'nextTarget':next_target.tolist(),'next':second,'thirdNormal32':third,'bothUseContinuousTaperForGeometryStudy':True,'runtimeAccepted':False})
    chosen=next(r for r in results if abs(r['targetBeyondBoundaryWorldXY']-inside_depth)<1e-8 and r['nextPolicy']=='existing_short_handover')
    for stage in ['first','next','thirdNormal32']:
        m=chosen[stage];assert m['maximumDropPixels']<=8 and m['innerSlack']>0 and m['outerExcess']<1e-10 and m['horizontalInvalidSamples']==0 and m['minimumOpaqueGroundGap']>=0 and m['maximumAnkleRatio']<5
    args.output.write_text(json.dumps({'originalFailureReplay':replay,'worldSha256':pin['fixtureWorldSha256'],'rawInputHashes':{name:hashlib.sha256((args.run/name).read_bytes()).hexdigest() for name in ['source.json','rejected.json','samples.jsonl']},'source':'6b6a7e3','case':'frozen NW identity plane/zero C upper exit plus next flat contact','results':results,'runtimeAccepted':False},indent=2,allow_nan=False)+'\n')
    for r in results:print(r['targetBeyondBoundaryWorldXY'],r['firstDuration'],r['first']['maximumDropPixels'],r['nextPolicy'],r['nextDuration'],r['next']['maximumDropPixels'],r['next']['horizontalInvalidSamples'])


if __name__=='__main__':main()
