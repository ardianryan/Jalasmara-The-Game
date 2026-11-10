#!/usr/bin/env python3
"""Offline original NORTH source inventory and source-specific upper endpoints for two outfits."""
import argparse
import copy
import hashlib
import importlib.util
import json
import math
from pathlib import Path

from PIL import Image, ImageDraw

ROOT=Path(__file__).resolve().parents[2]
SPEC=Path(__file__).with_suffix('.json')
loader=importlib.util.spec_from_file_location('north_generic_pixels',Path(__file__).with_name('south-upper-ownership.py'))
ops=importlib.util.module_from_spec(loader)
loader.loader.exec_module(ops)
require=ops.anchors.require
COLORS={'left/cap':(227,164,69,255),'left/upper':(245,189,85,255),'left/fore':(250,216,114,255),'left/hand':(255,239,178,255),
        'right/cap':(112,80,177,255),'right/upper':(147,109,216,255),'right/fore':(184,143,239,255),'right/hand':(218,191,253,255),
        'shirt':(66,183,192,255),'vest':(217,181,87,255),'belt':(199,96,77,255),'other':(126,145,151,255)}


def digest(data):
    return hashlib.sha256(data).hexdigest()


def components(image,min_y=43):
    remaining={(x,y) for y in range(min_y,image.height) for x in range(image.width) if image.getpixel((x,y))[3]}
    result=[]
    while remaining:
        pending=[remaining.pop()];part=[]
        while pending:
            x,y=pending.pop();part.append([x,y])
            for dx in (-1,0,1):
                for dy in (-1,0,1):
                    q=x+dx,y+dy
                    if q in remaining:
                        remaining.remove(q);pending.append(q)
        result.append(part)
    return sorted(result,key=len,reverse=True)


def load_sources(spec):
    require(spec.get('schemaVersion')==1 and spec.get('identity')=='male_nusantara'
            and spec.get('view')=='north' and spec.get('walkRow')==6 and spec.get('idleColumn')==6
            and set(spec.get('cases',{}))=={'daily','explorer'}, 'Only original NORTH two-outfit source scope')
    images={}
    for outfit in ('daily','explorer'):
        images[outfit]={}
        for kind in ('walk','idle'):
            record=spec['sources'][outfit][kind]
            require(record['path']==f'client-godot/resources/art/player-gait/male-nusantara-{outfit}-{kind}-8way-v1.png',
                    'Original source paths only')
            path=ROOT/record['path']
            require(digest(path.read_bytes())==record['sha256'],'Original source bytes changed')
            image=Image.open(path).convert('RGBA')
            require(image.size==((1024,1024) if kind=='walk' else(1024,128)),'Original atlas dimensions changed')
            images[outfit][kind]=image
    return images


def source_cell(images,outfit,frame):
    require(outfit in ('daily','explorer') and type(frame) is int and frame in range(8),'Original NORTH frame required')
    return images[outfit]['walk'].crop((frame*128,768,(frame+1)*128,844))


def prepare_case(spec,outfit,images=None):
    images=load_sources(spec) if images is None else images
    require(outfit in ('daily','explorer'),'Original outfit required')
    case=spec['cases'][outfit]
    require(case.get('sourceFrame')==0 and type(case['sourceFrame']) is int
            and case['sourceMeasurement']=={'anatomicalSide':'unknown','wrist':None,'grip':None}
            and case['authoredConvention']['contactPhase'] is None and 'AUTHORED' in case['authoredConvention']['status']
            and 'AUTHORED' in case['jointsStatus'], 'Do not promote source pixels into measured anatomy/contact')
    require(case['gearContract']=={'newNodes':0,'newPixels':0,'garmentMeshEnabled':False},'No gear or duplicate clothing changes')
    source=source_cell(images,outfit,0)
    require(digest(source.tobytes())==case['sourceUpperRgbaSha256'],'Original NORTH source crop changed')
    arms={};used=set()
    for side in ('left','right'):
        for part in ('cap','upper','fore','hand'):
            im=Image.new('RGBA',source.size)
            for y,x0,x1 in case['sourceRuns'][side][part]:
                require(all(type(v) is int for v in (y,x0,x1)) and 43<=y<76 and 0<=x0<x1<=128,
                        'Source mask outside upper crop')
                for x in range(x0,x1):
                    q=x,y;rgba=source.getpixel(q)
                    if not rgba[3]:continue
                    require(q not in used,'Exclusive original source ownership overlaps')
                    im.putpixel(q,rgba);used.add(q)
            arms[side+'/'+part]=im
    plate=source.copy()
    for p in used:plate.putpixel(p,(0,0,0,0))
    for record in case['plateBoundaryAssignments']:
        q=tuple(record['pixel'])
        require(len(q)==2 and all(type(v) is int for v in q) and 0<=q[0]<128 and 43<=q[1]<76
                and plate.getpixel(q)==tuple(record['rgba']) and record['rgba'][3]==255
                and 'AMBIGUOUS' in record['status'], 'Ambiguous original boundary must stay fixed with exact RGBA')
    garment_masks={k:ops.polygon(v) for k,v in case['garmentPolygons'].items()}
    garments={k:Image.new('RGBA',source.size) for k in ('shirt','vest','belt','other')}
    def category(x,y):
        for kind in ('belt','vest','shirt'):
            if kind in garment_masks and garment_masks[kind].getpixel((x,y)):return kind
        return 'other'
    ambiguous={tuple(r['pixel']) for r in case['plateBoundaryAssignments']}
    for y in range(76):
        for x in range(128):
            if plate.getpixel((x,y))[3]:garments['other' if (x,y) in ambiguous else category(x,y)].putpixel((x,y),source.getpixel((x,y)))
    body=plate.copy();repairs=[]
    for record in case['hiddenRepair']:
        p,q=tuple(record['destination']),tuple(record['donor']);kind=record['garment']
        require(len(p)==len(q)==2 and all(type(v) is int for v in (*p,*q)) and 43<=p[1]<76
                and 0<=p[0]<128 and 0<=q[0]<128 and p[1]==q[1] and kind in garments
                and 'AUTHORED' in record['status'],'Hidden fill needs explicit same-row authored provenance')
        require(garments[kind].getpixel(q)==tuple(record['rgba']) and record['rgba'][3]==255
                and not plate.getpixel(p)[3] and any(im.getpixel(p)[3] for im in arms.values()),
                'Hidden donor must be owned original same-outfit cloth behind an original arm')
        body.putpixel(p,tuple(record['rgba']));repairs.append(record)
    for y,x0,x1 in case['bodyContour']:
        require(all(type(v) is int for v in(y,x0,x1)) and 43<=y<76 and 0<=x0<x1<=128
                and all(body.getpixel((x,y))[3]==255 for x in range(x0,x1)),
                'Intended fixed torso contour has an alpha hole')
    rest=body.copy()
    for im in arms.values():rest.alpha_composite(im)
    require(rest.tobytes()==source.tobytes(),'Original NORTH source rest must reconstruct byte-exactly')
    overlaps={};overlap_seen=set()
    for record in case['authoredJointOverlap']:
        q=tuple(record['pixel']);key=record['targetPart'];owner=record['originalOwner']
        require(key in arms and owner in arms and key!=owner and len(q)==2
                and all(type(v) is int for v in q) and 0<=q[0]<128 and 43<=q[1]<76
                and q not in overlap_seen and 'AUTHORED' in record['status'], 'Explicit unique original-coordinate hidden overlap required')
        require(arms[owner].getpixel(q)==tuple(record['rgba']) and record['rgba'][3]==255
                and source.getpixel(q)==tuple(record['rgba']) and not arms[key].getpixel(q)[3],
                'Overlap must copy original RGBA from another exclusive source owner')
        overlaps.setdefault(key,Image.new('RGBA',source.size)).putpixel(q,tuple(record['rgba']));overlap_seen.add(q)
    require(len(case['poses'])==2,'Only two authored endpoints are proposed')
    poses=[]
    for pose in case['poses']:
        require(pose['behindTorso']==['right'],'Depth change needs separate authored review')
        moved={};matrices={}
        for side in ('left','right'):
            joints=case['joints'][side]
            require(set(joints)=={'shoulder','elbow','wrist'},'Three authored anchors required')
            for p in joints.values():
                require(isinstance(p,list) and len(p)==2 and all(type(v) is int for v in p)
                        and 0<=p[0]<128 and 43<=p[1]<76 and source.getpixel(tuple(p))[3]==255,
                        'Authored anchor must lie on opaque original upper source')
            motion=pose[side]
            require(set(motion)=={'upperDeg','foreRelativeDeg'} and all(type(v) in (int,float) and math.isfinite(v) for v in motion.values())
                    and motion['upperDeg']==0 and -30<=motion['foreRelativeDeg']<=35,'Fixed shoulders and bounded fore endpoint required')
            upper=ops.joint_rotation(joints['shoulder'],motion['upperDeg'])
            fore=ops.chain_transform(upper,ops.joint_rotation(joints['elbow'],motion['foreRelativeDeg']))
            matrices[side]={'cap':upper,'upper':upper,'fore':fore,'hand':fore}
            arm=Image.new('RGBA',source.size)
            for part in ('cap','upper','fore','hand'):
                key=side+'/'+part;layer=arms[key]
                if key in overlaps:
                    layer=layer.copy();layer.alpha_composite(overlaps[key])
                arm.alpha_composite(ops.moved_cutout(layer,matrices[side][part]))
            moved[side]=arm
        image=Image.new('RGBA',source.size)
        for side in pose['behindTorso']:image.alpha_composite(moved[side])
        image.alpha_composite(body)
        for side in ('left','right'):
            if side not in pose['behindTorso']:image.alpha_composite(moved[side])
        poses.append({'name':pose['name'],'image':image,'arms':moved,'matrices':matrices})
    require(poses[0]['image'].tobytes()==source.tobytes(),'Neutral depth must preserve complete original source')
    return source,plate,arms,garments,body,repairs,poses


def sheet(images,labels,columns=3,crop=(44,40,84,76),scale=8):
    width,height=(crop[2]-crop[0])*scale,(crop[3]-crop[1])*scale
    result=Image.new('RGB',(columns*(width+32),((len(images)+columns-1)//columns)*(height+48)),(20,38,43))
    draw=ImageDraw.Draw(result)
    for i,(im,label) in enumerate(zip(images,labels)):
        x,y=i%columns*(width+32)+16,i//columns*(height+48)+32
        scaled=im.crop(crop).resize((width,height),Image.Resampling.NEAREST)
        result.paste(scaled,(x,y),scaled);draw.text((x,y-24),label,fill='white')
    return result


def export(spec,output):
    output=output.resolve();require(output.is_relative_to(ROOT/'artifacts') and not output.exists(),'Fresh ignored authoring output required')
    images=load_sources(spec)
    data={outfit:prepare_case(spec,outfit,images) for outfit in ('daily','explorer')}
    output.mkdir(parents=True);manifest={'status':spec['status'],'sources':spec['sources'],'walkRow':6,'idleColumn':6,
        'specSha256':digest(SPEC.read_bytes()),'toolSha256':digest(Path(__file__).read_bytes()),'cases':{},'runtimeIntegration':False}
    for outfit in ('daily','explorer'):
        source,plate,arms,garments,body,repairs,poses=data[outfit];case=spec['cases'][outfit]
        frames=[source_cell(images,outfit,f) for f in range(8)]
        idle=images[outfit]['idle'].crop((768,0,896,76))
        sheet(frames+[idle],[f'ORIGINAL {outfit} NORTH walk{f}' for f in range(8)]+[f'ORIGINAL {outfit} NORTH IDLE'],5,(40,8,88,76),4).save(output/f'{outfit}-north-eight-walk-idle.png')
        grid=Image.new('RGB',(920,800),(20,38,43));draw=ImageDraw.Draw(grid)
        tile=source.crop((44,40,84,76)).resize((800,720),Image.Resampling.NEAREST)
        grid.paste(tile,(40,36),tile)
        for x in range(44,84):
            sx=40+(x-44)*20;draw.line((sx,36,sx,756),fill=(45,66,68));draw.text((sx,18),str(x),fill='white')
        for y in range(40,76):
            sy=36+(y-40)*20;draw.line((40,sy,840,sy),fill=(45,66,68));draw.text((12,sy),str(y),fill='white')
        grid.save(output/f'{outfit}-north0-original-coordinate-grid.png')
        owners=Image.new('RGBA',source.size)
        for name,im in {**garments,**arms}.items():owners.paste(COLORS[name],(0,0),im.getchannel('A'))
        sheet([source,owners,body,garments['shirt'],garments['vest'],garments['belt']],
              [f'ORIGINAL {outfit} NORTH0','Original ownership PROPOSAL','Neutral fixed body','Fixed original shirt','Fixed original vest','Fixed original belt']).save(output/f'{outfit}-north-ownership-and-body.png')
        sheet([source,body,poses[0]['image'],poses[1]['image']],
              ['Original NORTH0','Fixed body plate','Exact original rest','AUTHORED A-out/B-inward'],2).save(output/f'{outfit}-north-two-endpoints.png')
        sheet([p['arms'][s] for s in ('left','right') for p in poses],[s+' '+p['name'] for s in ('left','right') for p in poses],2).save(output/f'{outfit}-north-isolated-arms.png')
        if case['authoredJointOverlap']:
            predecessor=copy.deepcopy(spec);predecessor['cases'][outfit]['authoredJointOverlap']=[]
            before=prepare_case(predecessor,outfit,images)[-1][1]['arms']['left']
            sheet([before,poses[1]['arms']['left']],['BEFORE: original-cut alpha gap','AFTER: 1 AUTHORED hidden copy'],2,(49,56,58,64),24).save(output/f'{outfit}-north-overlap-before-after.png')
        for p in poses:p['image'].save(output/(outfit+'-'+p['name']+'.png'))
        manifest['cases'][outfit]={'sourceFrame':0,'originalFrameInventory':[{'frame':f,'rgbaSha256':digest(im.tobytes()),'bbox':im.getbbox()} for f,im in enumerate(frames)],
            'originalIdleRgbaSha256':digest(idle.tobytes()),'sourceUpperRgbaSha256':digest(source.tobytes()),
            'sourceHeadRgbaSha256':digest(source.crop((0,0,128,43)).tobytes()),
            'sourceMeasurement':case['sourceMeasurement'],'authoredConvention':case['authoredConvention'],
            'jointsStatus':case['jointsStatus'],'joints':case['joints'],'jointDesignRationale':case['jointDesignRationale'],
            'authoredJointOverlap':case['authoredJointOverlap'],'plateBoundaryAssignments':case['plateBoundaryAssignments'],'originalSourceRuns':{k:ops.row_runs(im) for k,im in {**arms,**garments}.items()},
            'authoredHiddenFill':repairs,'bodyContour':case['bodyContour'],'bodyComponents43Plus':[len(c) for c in components(body)],'gearContract':case['gearContract'],
            'inspectionRegions':[{'name':r['name'],'rect':r['rect'],'status':'Original patch may mix skin/garment/outline; not a measured joint or exclusive arm mask',
                                  'rgbaSha256':digest(source.crop(tuple(r['rect'])).tobytes())} for r in case['inspectionRegions']],
            'poses':[{'name':p['name'],'matrices':p['matrices'],'rgbaSha256':digest(p['image'].tobytes()),
                      'armComponents':{s:[len(c) for c in components(im)] for s,im in p['arms'].items()}} for p in poses]}
    (output/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
    print('NORTH source-specific inventory/endpoints exported; no source anatomy, gait or runtime acceptance')


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--output',type=Path,required=True)
    args=parser.parse_args();export(json.loads(SPEC.read_text()),args.output)
