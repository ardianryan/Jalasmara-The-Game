#!/usr/bin/env python3
"""Offline eight-frame authored NW daily upper preview from original WALK4 cutouts."""
import argparse
import hashlib
import importlib.util
import json
import math
from pathlib import Path

from PIL import Image, ImageDraw

ROOT=Path(__file__).resolve().parents[2]
SPEC=Path(__file__).with_suffix('.json')
loader=importlib.util.spec_from_file_location('daily_loop_rig',Path(__file__).with_name('nw-daily-upper-rig.py'))
rig=importlib.util.module_from_spec(loader)
loader.loader.exec_module(rig)
require=rig.require


def digest(data):
    return hashlib.sha256(data).hexdigest()


def validate(spec):
    require(spec.get('schemaVersion')==1 and spec.get('identity')=='male_nusantara'
            and spec.get('outfit')=='daily' and spec.get('view')=='north_west'
            and type(spec.get('sourceFrame')) is int and spec['sourceFrame']==4
            and type(spec.get('frameCount')) is int and spec['frameCount']==8,
            'Only original NW daily WALK4-derived eight-pose authoring is supported')
    require(spec.get('rigSpecSha256')==digest(rig.SPEC.read_bytes()),'Reviewed daily rig changed')
    require(spec.get('motion')=={'left':{'foreMeanDeg':14,'foreCosDeg':14},
                               'right':{'foreMeanDeg':-10,'foreCosDeg':10}}
            and spec.get('upperDeg')==0 and spec.get('behindTorso')==['right'],
            'Motion must stay inside reviewed fixed-shoulder endpoints/depth')
    require(spec.get('sourceMeasurement')=={'anatomicalSide':'unknown','wrist':None,'grip':None}
            and spec.get('contactPhase') is None and 'AUTHORED' in spec.get('phaseStatus','')
            and 'not runtime phase4' in spec.get('sourceFrameStatus',''),
            'Source frame, authored phase and contact phase must stay distinct')
    require(type(spec.get('previewFrameMs')) is int and 60<=spec['previewFrameMs']<=200
            and spec.get('newOutputPixels')==[] and spec.get('newGearPixels')==0,
            'Preview cadence or output/gear scope changed')


def pose_at(spec,frame):
    validate(spec)
    require(type(frame) is int,'Frame must be an integer')
    angle=math.tau*((frame%8)/8)
    pose={'name':f'authored-daily-loop-{frame%8}','behindTorso':list(spec['behindTorso'])}
    for side in ('left','right'):
        motion=spec['motion'][side]
        pose[side]={'upperDeg':0,'foreRelativeDeg':round(motion['foreMeanDeg']+motion['foreCosDeg']*math.cos(angle),8)}
    return pose


def point(m,p):
    a,b,c,d,e,f=m
    return [a*p[0]+b*p[1]+c,d*p[0]+e*p[1]+f]


def changed_pixels(a,b):
    return sum(p!=q for p,q in zip(a.getdata(),b.getdata()))


def render(spec,frame):
    validate(spec)
    base=json.loads(rig.SPEC.read_text())
    base['poses'][1]=pose_at(spec,frame)
    source,plate,arms,garments,body,repairs,poses=rig.prepare(base)
    pose=poses[1]
    joints={}
    for side in ('left','right'):
        anchors=base['joints'][side]
        matrices=pose['matrices'][side]
        joints[side]={'status':base['jointsStatus'],
                      'shoulder':point(matrices['upper'],anchors['shoulder']),
                      'elbowFromUpper':point(matrices['upper'],anchors['elbow']),
                      'elbowFromFore':point(matrices['fore'],anchors['elbow']),
                      'wristDesignAnchor':point(matrices['fore'],anchors['wrist']),'grip':None}
    meta={'authoringFrame':frame%8,'authoredPhase':(frame%8)/8,'originalSourceFrame':4,
          'angles':base['poses'][1],'joints':joints,'matrices':pose['matrices'],
          'armComponents':{side:[len(c) for c in rig.components(im)] for side,im in pose['arms'].items()},
          'rgbaSha256':digest(pose['image'].tobytes())}
    return source,body,pose['image'],pose['arms'],meta


def export(spec,output):
    validate(spec)
    output=output.resolve()
    require(output.is_relative_to(ROOT/'artifacts') and not output.exists(),'Fresh ignored authoring output required')
    frames=[render(spec,f) for f in range(8)]
    images=[f[2] for f in frames]
    output.mkdir(parents=True)
    images[0].save(output/'nw-daily-upper-loop-preview.png',save_all=True,append_images=images[1:],
                   duration=spec['previewFrameMs'],loop=0,disposal=0,blend=0)
    for f,im in enumerate(images):
        im.save(output/f'frame-{f}.png')
    labels=[f'AUTHORED NW daily {f}/8; source4' for f in range(8)]
    rig.sheet(images,labels,8,(42,0,88,76),3).save(output/'nw-daily-upper-eight-strip.png')
    rig.sheet(images,labels,4).save(output/'nw-daily-upper-eight-detail.png')
    rig.sheet([images[f] for f in (6,7,0,1)],[f'WRAP authoring frame{f}' for f in (6,7,0,1)],4).save(output/'nw-daily-upper-wrap-7-0.png')
    joint_images=[]
    for source,body,image,arms,metadata in frames:
        overlay=image.copy()
        draw=ImageDraw.Draw(overlay)
        for side,color in [('left',(246,196,74)),('right',(149,115,229))]:
            joints=metadata['joints'][side]
            pts=[tuple(joints[k]) for k in ('shoulder','elbowFromUpper','wristDesignAnchor')]
            draw.line(pts,fill=color,width=1)
            for x,y in pts:
                draw.ellipse((x-1,y-1,x+1,y+1),outline=color)
        joint_images.append(overlay)
    rig.sheet(joint_images,[f'{f}: AUTHORED joints, no grip/contact' for f in range(8)],4).save(output/'nw-daily-upper-authored-anchors.png')
    extremes=[];names=[]
    for f in (0,4):
        source,body,image,arms,metadata=frames[f]
        extremes.extend([body,arms['left'],arms['right'],image])
        names.extend([f'{f}: fixed original head/body',f'{f}: authored LEFT/A',f'{f}: authored RIGHT/B',f'{f}: composite'])
    rig.sheet(extremes,names,4).save(output/'nw-daily-upper-extremes.png')
    base=json.loads(rig.SPEC.read_text())
    source,plate,arms,garments,body,repairs,neutral=rig.prepare(base)
    edge_coordinates=[(57,64),(58,64),(57,65),(58,65),(58,66)]
    edge_records=[{'pixel':list(q),'rgba':list(source.getpixel(q)),
                   'status':'Preserved AUTHORED original dark hand-edge ownership from reviewed daily rig, not new pixels'} for q in edge_coordinates]
    edge_overlay=source.copy()
    for q in edge_coordinates:
        edge_overlay.putpixel(q,(246,196,74,255))
    fill_overlay=source.copy()
    for record in repairs:
        fill_overlay.putpixel(tuple(record['destination']),(235,65,181,255))
    anchor_overlay=images[0].copy()
    draw=ImageDraw.Draw(anchor_overlay)
    for x,color in [(57,(235,65,181)),(60,(66,218,213))]:
        draw.line((x-1,59,x+1,59),fill=color,width=1)
        draw.line((x,58,x,60),fill=color,width=1)
    rig.sheet([edge_overlay,fill_overlay,anchor_overlay],
              ['Gold: 5 ORIGINAL hand edge texels','Magenta: 11 AUTHORED hidden fills','AUTHORED elbow57->60; no phase claim'],3).save(output/'nw-daily-upper-source-decisions.png')
    manifest={'status':spec['status'],'sourceFrameStatus':spec['sourceFrameStatus'],'phaseStatus':spec['phaseStatus'],
              'sourceAtlas':base['sourceAtlas'],'originalSourceFrame':4,
              'sourceUpperRgbaSha256':digest(source.tobytes()),'sourceHeadRgbaSha256':digest(source.crop((0,0,128,43)).tobytes()),
              'rigSpecSha256':spec['rigSpecSha256'],'rigToolSha256':digest(Path(rig.__file__).read_bytes()),
              'loopSpecSha256':digest(SPEC.read_bytes()),'loopToolSha256':digest(Path(__file__).read_bytes()),
              'originalSourceRuns':{k:rig.ops.row_runs(im) for k,im in {**arms,**garments}.items()},
              'sourceMeasurement':base['sourceMeasurement'],'authoredConvention':base['authoredConvention'],
              'jointsStatus':base['jointsStatus'],'joints':base['joints'],'jointDesignRationale':base['jointDesignRationale'],
              'additionalOutlineStatus':base['additionalOutlineStatus'],'preservedHandEdgeAssignments':edge_records,
              'authoredElbowRevision':{'side':'left','initial':[57,59],'current':[60,59],'status':'AUTHORED three-pixel axis revision before loop; not measured source joint'},
              'authoredHiddenFill':repairs,
              'neutralReferenceExact':neutral[0]['image'].tobytes()==source.tobytes(),
              'gearContract':base['gearContract'],'frames':[f[4] for f in frames],
              'adjacentChangedPixelsIncludingWrap':[changed_pixels(images[f],images[(f+1)%8]) for f in range(8)],
              'previewFrameMs':spec['previewFrameMs'],'previewCadenceStatus':'Independent art preview, not locomotion cadence',
              'runtimeIntegration':False}
    (output/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
    print('NW DAILY AUTHORED LOOP EXPORTED: source4 distinct from authoring/contact phase; no runtime adoption')


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output',type=Path,required=True)
    args=parser.parse_args()
    export(json.loads(SPEC.read_text()),args.output)
