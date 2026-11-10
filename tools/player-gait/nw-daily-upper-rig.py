#!/usr/bin/env python3
"""Original daily NW WALK4 upper ownership and two AUTHORED endpoint proposal."""
import argparse
import hashlib
import importlib.util
import json
import math
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
SPEC = Path(__file__).with_suffix('.json')
loader = importlib.util.spec_from_file_location('daily_nw_audit', Path(__file__).with_name('nw-upper-source-audit.py'))
audit = importlib.util.module_from_spec(loader)
loader.loader.exec_module(audit)
ops = audit.ownership
require = audit.require
COLORS = {'left/cap':(227,164,69,255),'left/upper':(245,189,85,255),'left/fore':(250,216,114,255),'left/hand':(255,239,178,255),
          'right/cap':(112,80,177,255),'right/upper':(147,109,216,255),'right/fore':(184,143,239,255),'right/hand':(218,191,253,255),
          'shirt':(66,183,192,255),'other':(126,145,151,255)}


def digest(data):
    return hashlib.sha256(data).hexdigest()


def components(image, min_y=43):
    points = {(x,y) for y in range(min_y,image.height) for x in range(image.width) if image.getpixel((x,y))[3]}
    result = []
    while points:
        pending = [points.pop()]
        part = []
        while pending:
            x,y = pending.pop()
            part.append([x,y])
            for dx in (-1,0,1):
                for dy in (-1,0,1):
                    q = x+dx,y+dy
                    if q in points:
                        points.remove(q)
                        pending.append(q)
        result.append(part)
    return sorted(result,key=len,reverse=True)


def prepare(spec):
    require(spec.get('schemaVersion') == 1 and spec.get('identity') == 'male_nusantara'
            and spec.get('outfit') == 'daily' and spec.get('view') == 'north_west'
            and type(spec.get('sourceFrame')) is int and spec['sourceFrame'] == 4,
            'Only source-specific original NW daily WALK4 is proposed')
    require(spec.get('sourceMeasurement') == {'anatomicalSide':'unknown','wrist':None,'grip':None}
            and spec['authoredConvention']['contactPhase'] is None and 'AUTHORED' in spec['authoredConvention']['status']
            and 'AUTHORED' in spec['jointsStatus'],
            'Do not promote authored side/joints into measured source anatomy/contact')
    require(len(spec['poses'])==2 and spec['poses'][0]['left']=={'upperDeg':0,'foreRelativeDeg':0}
            and spec['poses'][0]['right']=={'upperDeg':0,'foreRelativeDeg':0}, 'Two endpoints must retain original neutral')
    require(spec.get('gearContract') == {'newNodes':0,'newPixels':0,'garmentMeshEnabled':False}, 'No gear or duplicate shirt changes')
    source_spec = json.loads(audit.SPEC.read_text())
    record = source_spec['sources']['daily']['walk']
    require(spec['sourceAtlas'] == record, 'Original daily source pin changed')
    # Read only this daily source; no explorer mask, source body, joint or donor is loaded.
    raw = (ROOT/record['path']).read_bytes()
    require(digest(raw) == record['sha256'], 'Original daily atlas bytes changed')
    atlas = Image.open(ROOT/record['path']).convert('RGBA')
    require(atlas.size == (1024,1024), 'Original daily atlas dimensions changed')
    source = atlas.crop((512,640,640,716))
    require(digest(source.tobytes()) == spec['sourceUpperRgbaSha256'], 'Original daily NW4 upper source changed')
    for side in ('left','right'):
        require(set(spec['joints'][side])=={'shoulder','elbow','wrist'}, 'Three authored anchors required')
        for p in spec['joints'][side].values():
            require(isinstance(p,list) and len(p)==2 and all(type(v) is int for v in p)
                    and 0<=p[0]<128 and 43<=p[1]<76 and source.getpixel(tuple(p))[3]==255,
                    'Authored anchors must lie inside opaque original daily upper source')
    arms = {}
    used = set()
    for side in ('left','right'):
        for part in ('cap','upper','fore','hand'):
            im = Image.new('RGBA',source.size)
            for y,x0,x1 in spec['sourceRuns'][side][part]:
                require(type(y) is int and type(x0) is int and type(x1) is int
                        and 43<=y<76 and 0<=x0<x1<=128, 'Source row outside upper scope')
                for x in range(x0,x1):
                    q = x,y
                    if not source.getpixel(q)[3]:
                        continue
                    require(q not in used, 'Original source mask owners overlap')
                    im.putpixel(q,source.getpixel(q))
                    used.add(q)
            arms[side+'/'+part] = im
    plate = source.copy()
    for q in used:
        plate.putpixel(q,(0,0,0,0))
    garments = {'shirt':Image.new('RGBA',source.size),'other':Image.new('RGBA',source.size)}
    for y in range(76):
        for x in range(128):
            if plate.getpixel((x,y))[3]:
                kind = 'shirt' if 45<=y<=66 else 'other'
                garments[kind].putpixel((x,y),source.getpixel((x,y)))
    donors = {}
    for record in spec['donors']:
        q = tuple(record['pixel'])
        require(len(q)==2 and all(type(v) is int for v in q) and 0<=q[0]<128 and 45<=q[1]<=66
                and garments['shirt'].getpixel(q)==tuple(record['rgba']) and record['rgba'][3]==255,
                'Hidden fill donor must be owned original daily same-row shirt')
        donors[q[1]] = q
    body = plate.copy()
    repairs = []
    for y,x0,x1 in spec['bodyContour']:
        require(45<=y<=66 and 0<=x0<x1<=128, 'Hidden shirt contour outside scope')
        for x in range(x0,x1):
            q=x,y
            if not any(im.getpixel(q)[3] for im in arms.values()):
                continue
            require(y in donors, 'Missing original daily same-row donor')
            donor = donors[y]
            rgba = source.getpixel(donor)
            body.putpixel(q,rgba)
            repairs.append({'destination':list(q),'donor':list(donor),'rgba':list(rgba),
                            'status':'AUTHORED hidden daily shirt from original daily NW4 same-row cloth; not recovered source'})
    rest = body.copy()
    for im in arms.values():
        rest.alpha_composite(im)
    require(rest.tobytes()==source.tobytes(), 'Original daily rest must reconstruct exactly')
    poses = []
    for pose in spec['poses']:
        require(pose['behindTorso']==['right'], 'Depth changes require separate authored review')
        moved = {}
        matrices = {}
        for side in ('left','right'):
            joints = spec['joints'][side]
            motion = pose[side]
            require(set(motion)=={'upperDeg','foreRelativeDeg'}
                    and all(type(v) in (int,float) and math.isfinite(v) for v in motion.values())
                    and motion['upperDeg']==0 and -30<=motion['foreRelativeDeg']<=35,
                    'Two-pose proposal keeps shoulders fixed and fore rotation bounded')
            upper = ops.joint_rotation(joints['shoulder'],motion['upperDeg'])
            fore = ops.chain_transform(upper,ops.joint_rotation(joints['elbow'],motion['foreRelativeDeg']))
            matrices[side] = {'cap':upper,'upper':upper,'fore':fore,'hand':fore}
            arm = Image.new('RGBA',source.size)
            for part in ('cap','upper','fore','hand'):
                arm.alpha_composite(ops.moved_cutout(arms[side+'/'+part],matrices[side][part]))
            moved[side] = arm
        image = Image.new('RGBA',source.size)
        for side in pose['behindTorso']:
            image.alpha_composite(moved[side])
        image.alpha_composite(body)
        for side in ('left','right'):
            if side not in pose['behindTorso']:
                image.alpha_composite(moved[side])
        poses.append({'name':pose['name'],'image':image,'arms':moved,'matrices':matrices})
    require(poses[0]['image'].tobytes()==source.tobytes(), 'Neutral depth must retain original daily source')
    return source,plate,arms,garments,body,repairs,poses


def sheet(images, labels, columns=3, crop=(44,42,86,76), scale=8):
    width,height = (crop[2]-crop[0])*scale,(crop[3]-crop[1])*scale
    result = Image.new('RGB',(columns*(width+32),((len(images)+columns-1)//columns)*(height+48)),(20,38,43))
    draw = ImageDraw.Draw(result)
    for i,(im,label) in enumerate(zip(images,labels)):
        x,y = i%columns*(width+32)+16,i//columns*(height+48)+32
        scaled = im.crop(crop).resize((width,height),Image.Resampling.NEAREST)
        result.paste(scaled,(x,y),scaled)
        draw.text((x,y-24),label,fill='white')
    return result


def export(spec,output):
    output=output.resolve()
    require(output.is_relative_to(ROOT/'artifacts') and not output.exists(),'Fresh ignored authoring output required')
    source,plate,arms,garments,body,repairs,poses=prepare(spec)
    output.mkdir(parents=True)
    owners=Image.new('RGBA',source.size)
    for name,im in {**garments,**arms}.items():
        owners.paste(COLORS[name],(0,0),im.getchannel('A'))
    fill=source.copy()
    for r in repairs:
        fill.putpixel(tuple(r['destination']),(235,65,181,255))
    sheet([source,owners,body,garments['shirt'],garments['other'],fill],
          ['ORIGINAL daily NW WALK4','Source ownership PROPOSAL','AUTHORED neutral body','Original fixed shirt','Original head/remainder','Magenta AUTHORED hidden fill']).save(output/'nw-daily-ownership-and-body.png')
    sheet([source,body,poses[0]['image'],poses[1]['image']],
          ['Original NW4 source','Neutral body plate','Exact source rest','AUTHORED A/B endpoints'],2).save(output/'nw-daily-two-endpoints.png')
    sheet([p['arms'][s] for s in ('left','right') for p in poses],
          [s+' '+p['name'] for s in ('left','right') for p in poses],2).save(output/'nw-daily-isolated-arm-endpoints.png')
    head=source.crop((0,0,128,43))
    atlas=Image.open(ROOT/spec['sourceAtlas']['path']).convert('RGBA')
    original0=atlas.crop((0,640,128,716))
    tail=[{'sourceFrame':0,'pixel':[x,42],'atlasPixel':[x,682], 'rgba':list(original0.getpixel((x,42))),
           'connectedAbove':[x,41], 'connectedAboveRgba':list(original0.getpixel((x,41))),
           'status':'ORIGINAL NW0 bandana tail connected above crop row42; preserved in prior authored explorer head, not a new isolated pixel'} for x in (79,80,81)]
    sheet([original0,source,body,poses[1]['image']],
          ['ORIGINAL NW0 bandana tail','ORIGINAL daily NW4 head/tail','Original NW4 head preserved','Endpoint head preserved'],4,(52,32,88,48),10).save(output/'nw-daily-original-bandana-tail.png')
    for p in poses:
        p['image'].save(output/(p['name']+'.png'))
    body.save(output/'nw-daily-authored-body.png')
    manifest={'status':spec['status'],'sourceAtlas':spec['sourceAtlas'],'sourceFrame':4,
              'sourceUpperRgbaSha256':digest(source.tobytes()),'sourceHeadRgbaSha256':digest(head.tobytes()),
              'specSha256':digest(SPEC.read_bytes()),'toolSha256':digest(Path(__file__).read_bytes()),
              'originalSourceRuns':{k:ops.row_runs(im) for k,im in {**arms,**garments}.items()},
              'sourceMeasurement':spec['sourceMeasurement'],'authoredConvention':spec['authoredConvention'],
              'jointsStatus':spec['jointsStatus'],'joints':spec['joints'],'authoredHiddenFill':repairs,
              'bodyComponents43Plus':[len(c) for c in components(body)],'originalBandanaTail':tail,
              'sourceHeadComponents':[len(c) for c in components(head,0)],
              'sourceFrame0HeadComponents':[len(c) for c in components(original0.crop((0,0,128,43)),0)],
              'jointDesignRationale':spec['jointDesignRationale'],'additionalOutlineStatus':spec['additionalOutlineStatus'],
              'poses':[{'name':p['name'],'matrices':p['matrices'],'rgbaSha256':digest(p['image'].tobytes()),
                        'armComponents':{s:[len(c) for c in components(im)] for s,im in p['arms'].items()}} for p in poses],
              'gearContract':spec['gearContract'],'runtimeIntegration':False}
    (output/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
    print('NW DAILY TWO-ENDPOINT PROPOSAL EXPORTED; original source exact, visual/anatomy unaccepted')


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output',type=Path,required=True)
    args=parser.parse_args()
    export(json.loads(SPEC.read_text()),args.output)
