#!/usr/bin/env python3
"""CPU-only original NORTH daily/explorer elbow-loop proposals, independent of contact phase."""
import argparse
import hashlib
import importlib.util
import json
import math
from pathlib import Path

from PIL import Image, ImageDraw

ROOT=Path(__file__).resolve().parents[2]
SPEC=Path(__file__).with_suffix('.json')
loader=importlib.util.spec_from_file_location('north_loop_rig',Path(__file__).with_name('north-upper-rig.py'))
rig=importlib.util.module_from_spec(loader)
loader.loader.exec_module(rig)
require=rig.require


def digest(data):
    return hashlib.sha256(data).hexdigest()


def validate(spec):
    require(spec.get('schemaVersion')==1 and spec.get('identity')=='male_nusantara'
            and spec.get('view')=='north' and type(spec.get('frameCount')) is int and spec['frameCount']==8
            and spec.get('rigSpecSha256')==digest(rig.SPEC.read_bytes()),'Reviewed original NORTH rig pin/scope changed')
    require(spec.get('sourceMeasurement')=={'anatomicalSide':'unknown','wrist':None,'grip':None}
            and spec.get('contactPhase') is None and 'AUTHORED' in spec.get('phaseStatus','')
            and 'not an accepted runtime/contact event' in spec.get('sourceFrameStatus',''),
            'Source anatomical side/joints/grip/contact remain unknown')
    require(type(spec.get('previewFrameMs')) is int and 60<=spec['previewFrameMs']<=200
            and spec.get('newOutputPixels')==[] and spec.get('newGearPixels')==0,
            'Preview cadence or newly authored pixel/gear scope changed')
    require(set(spec.get('cases',{}))=={'daily','explorer'},'Two independent original NORTH outfits only')
    for case in spec['cases'].values():
        require(type(case.get('originalSourceFrame')) is int and case['originalSourceFrame']==0
                and case.get('upperDeg')==0 and case.get('behindTorso')==['right']
                and case.get('motion')=={'left':{'foreMeanDeg':12,'foreCosDeg':12},
                                       'right':{'foreMeanDeg':9,'foreCosDeg':-9}},
                'Loop must preserve each reviewed fixed-shoulder/depth endpoint envelope')


def pose_at(spec,outfit,frame):
    validate(spec)
    require(outfit in ('daily','explorer') and type(frame) is int,'Explicit original outfit and integer authoring frame required')
    angle=math.tau*((frame%8)/8);case=spec['cases'][outfit]
    pose={'name':f'authored-{outfit}-north-{frame%8}','behindTorso':list(case['behindTorso'])}
    for side in ('left','right'):
        m=case['motion'][side]
        pose[side]={'upperDeg':0,'foreRelativeDeg':round(m['foreMeanDeg']+m['foreCosDeg']*math.cos(angle),8)}
    return pose


def point(m,p):
    a,b,c,d,e,f=m
    return[a*p[0]+b*p[1]+c,d*p[0]+e*p[1]+f]


def changed_pixels(a,b):
    return sum(p!=q for p,q in zip(a.getdata(),b.getdata()))


def render(spec,outfit,frame,images=None):
    validate(spec)
    authored_pose=pose_at(spec,outfit,frame)
    base=json.loads(rig.SPEC.read_text());base['cases'][outfit]['poses'][1]=authored_pose
    source,plate,arms,garments,body,repairs,poses=rig.prepare_case(base,outfit,images)
    pose=poses[1];case=base['cases'][outfit];joints={}
    for side in ('left','right'):
        authored=case['joints'][side];matrices=pose['matrices'][side]
        joints[side]={'status':case['jointsStatus'],'shoulder':point(matrices['upper'],authored['shoulder']),
                      'elbowFromUpper':point(matrices['upper'],authored['elbow']),
                      'elbowFromFore':point(matrices['fore'],authored['elbow']),
                      'wristDesignAnchor':point(matrices['fore'],authored['wrist']),'grip':None}
    meta={'authoringFrame':frame%8,'originalSourceFrame':0,'authoredPhase':(frame%8)/8,
          'angles':base['cases'][outfit]['poses'][1],'joints':joints,'matrices':pose['matrices'],
          'armComponents':{side:[len(c) for c in rig.components(im)] for side,im in pose['arms'].items()},
          'rgbaSha256':digest(pose['image'].tobytes())}
    return source,body,pose['image'],pose['arms'],meta


def export(spec,output):
    validate(spec);output=output.resolve()
    require(output.is_relative_to(ROOT/'artifacts') and not output.exists(),'Fresh ignored offline authoring output required')
    base=json.loads(rig.SPEC.read_text());images=rig.load_sources(base)
    frames={outfit:[render(spec,outfit,f,images) for f in range(8)] for outfit in ('daily','explorer')}
    output.mkdir(parents=True)
    manifest={'status':spec['status'],'phaseStatus':spec['phaseStatus'],'sourceFrameStatus':spec['sourceFrameStatus'],
              'rigSpecSha256':spec['rigSpecSha256'],'rigToolSha256':digest(Path(rig.__file__).read_bytes()),
              'loopSpecSha256':digest(SPEC.read_bytes()),'loopToolSha256':digest(Path(__file__).read_bytes()),
              'originalSources':base['sources'],'sourceMeasurement':spec['sourceMeasurement'],
              'previewFrameMs':spec['previewFrameMs'],'previewCadenceStatus':'Authoring preview only, not locomotion timing',
              'runtimeIntegration':False,'cases':{}}
    for outfit in ('daily','explorer'):
        rows=frames[outfit];rasters=[r[2] for r in rows];case=base['cases'][outfit]
        rasters[0].save(output/f'{outfit}-north-upper-loop-preview.png',save_all=True,append_images=rasters[1:],
                        duration=spec['previewFrameMs'],loop=0,disposal=0,blend=0)
        for f,im in enumerate(rasters):im.save(output/f'{outfit}-frame-{f}.png')
        labels=[f'AUTHORED NORTH {outfit} {f}/8' for f in range(8)]
        rig.sheet(rasters,labels,8,(42,0,86,76),3).save(output/f'{outfit}-north-upper-eight-strip.png')
        rig.sheet(rasters,labels,4).save(output/f'{outfit}-north-upper-eight-detail.png')
        rig.sheet([rasters[f] for f in (6,7,0,1)],[f'WRAP authoring frame{f}' for f in (6,7,0,1)],4).save(output/f'{outfit}-north-upper-wrap-7-0.png')
        extreme_images=[];names=[];anchor_images=[]
        for f in (0,4):
            source,body,image,arms,metadata=rows[f]
            extreme_images.extend([body,arms['left'],arms['right'],image])
            names.extend([f'{f}: fixed original head/body',f'{f}: authored LEFT/A',f'{f}: authored RIGHT/B',f'{f}: composite'])
        rig.sheet(extreme_images,names,4).save(output/f'{outfit}-north-upper-extremes.png')
        for source,body,image,arms,metadata in rows:
            overlay=image.copy();draw=ImageDraw.Draw(overlay)
            for side,color in [('left',(246,196,74)),('right',(149,115,229))]:
                joints=metadata['joints'][side];pts=[tuple(joints[k]) for k in ('shoulder','elbowFromUpper','wristDesignAnchor')]
                draw.line(pts,fill=color,width=1)
                for x,y in pts:draw.ellipse((x-1,y-1,x+1,y+1),outline=color)
            anchor_images.append(overlay)
        rig.sheet(anchor_images,[f'{f}: AUTHORED anchors, no grip/contact' for f in range(8)],4).save(output/f'{outfit}-north-upper-authored-anchors.png')
        source,plate,arms,garments,body,repairs,neutral=rig.prepare_case(base,outfit,images)
        manifest['cases'][outfit]={'originalSourceFrame':0,'sourceUpperRgbaSha256':digest(source.tobytes()),
            'sourceHeadRgbaSha256':digest(source.crop((0,0,128,43)).tobytes()),
            'originalSourceRuns':{k:rig.ops.row_runs(im) for k,im in {**arms,**garments}.items()},
            'authoredConvention':case['authoredConvention'],'jointsStatus':case['jointsStatus'],'joints':case['joints'],
            'jointDesignRationale':case['jointDesignRationale'],'plateBoundaryAssignments':case['plateBoundaryAssignments'],
            'authoredJointOverlap':case['authoredJointOverlap'],'authoredHiddenFill':repairs,
            'bodyContour':case['bodyContour'],'gearContract':case['gearContract'],
            'neutralReferenceExact':neutral[0]['image'].tobytes()==source.tobytes(),'frames':[r[4] for r in rows],
            'adjacentChangedPixelsIncludingWrap':[changed_pixels(rasters[f],rasters[(f+1)%8]) for f in range(8)]}
    (output/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
    print('NORTH DAILY/EXPLORER LOOP PROPOSALS EXPORTED; original source and authored/contact phases remain distinct')


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--output',type=Path,required=True)
    args=parser.parse_args();export(json.loads(SPEC.read_text()),args.output)
