#!/usr/bin/env python3
"""Source-specific, offline NW explorer ownership and authored two-pose rig proposal."""
import argparse
import copy
import hashlib
import importlib.util
import json
from pathlib import Path

from PIL import Image,ImageDraw

ROOT=Path(__file__).resolve().parents[2]
SPEC=Path(__file__).with_suffix('.json')
loader=importlib.util.spec_from_file_location('nw_orientation',Path(__file__).with_name('nw-explorer-orientation-proposal.py'))
orientation=importlib.util.module_from_spec(loader);loader.loader.exec_module(orientation)
ops=orientation.audit.ownership
require=orientation.require
COLORS={'vest':(221,184,89,255),'shirt':(56,182,190,255),'belt':(202,99,75,255),'other':(125,143,150,255),
        'left/cap':(245,176,68,255),'left/upper':(247,197,86,255),'left/fore':(252,219,113,255),'left/hand':(255,241,172,255),
        'right/cap':(109,84,183,255),'right/upper':(141,104,218,255),'right/fore':(177,139,237,255),'right/hand':(215,191,249,255)}


def digest(data):return hashlib.sha256(data).hexdigest()


def components(image,min_y=43):
    remaining={(x,y) for y in range(min_y,image.height) for x in range(image.width) if image.getpixel((x,y))[3]};result=[]
    while remaining:
        pending=[remaining.pop()];part=[]
        while pending:
            x,y=pending.pop();part.append([x,y])
            for dx in (-1,0,1):
                for dy in (-1,0,1):
                    q=x+dx,y+dy
                    if q in remaining:remaining.remove(q);pending.append(q)
        result.append(part)
    return sorted(result,key=len,reverse=True)


def prepare(spec):
    require(spec.get('schemaVersion')==1 and spec.get('identity')=='male_nusantara'
            and spec.get('outfit')=='explorer' and spec.get('view')=='north_west'
            and spec['orientationSpecSha256']==digest(orientation.SPEC.read_bytes()),'Coherent NW explorer source arrangement changed')
    require(spec['sourceMeasurement']=={'anatomicalSide':'unknown','wrist':None,'grip':None}
            and 'AUTHORED' in spec['authoredConvention']['status'] and spec['authoredConvention']['contactPhase'] is None
            and 'AUTHORED' in spec['jointsStatus'],'Do not promote authored skeleton to measured side/socket/contact')
    require(spec['gearContract']=={'newNodes':0,'newGearPixels':0,'atlasVestMeshEnabled':False,'sourceOriginalClothingOnly':True},'No duplicate garment/gear is permitted')
    require(len(spec['poses'])==2 and all(p['behindTorso']==['right'] for p in spec['poses']), 'Only two fixed-depth authored endpoints are proposed')
    source,*_=orientation.compose(json.loads(orientation.SPEC.read_text()))
    arms={};used=set()
    for side in ('left','right'):
        for part in ('hand','fore','upper','cap'):
            mask=ops.polygon(spec['parts'][side][part]);image=Image.new('RGBA',source.size)
            for y in range(43,76):
                for x in range(128):
                    if mask.getpixel((x,y)) and source.getpixel((x,y))[3] and (x,y) not in used:
                        image.putpixel((x,y),source.getpixel((x,y)));used.add((x,y))
            arms[side+'/'+part]=image
    for record in spec.get('sourceBoundaryAssignments',[]):
        p=record['pixel']
        require(isinstance(p,list) and len(p)==2 and all(type(v) is int for v in p)
                and 0<=p[0]<128 and 43<=p[1]<76 and record['part'] in arms,'Source boundary outside proposed upper part')
        q=tuple(p);rgba=source.getpixel(q)
        require(list(rgba)==record['rgba'] and rgba[3]==255
                and q not in used and 'AUTHORED' in record['status'],'Source boundary assignment differs or overlaps existing owner')
        arms[record['part']].putpixel(q,rgba);used.add(q)
    plate=source.copy()
    for p in used:plate.putpixel(p,(0,0,0,0))
    masks={name:ops.polygon(poly) for name,poly in spec['garmentPolygons'].items()}
    def category(x,y):
        for name in ('belt','vest','shirt'):
            if masks[name].getpixel((x,y)):return name
        return 'other'
    garments={name:Image.new('RGBA',source.size) for name in ('vest','shirt','belt','other')}
    for y in range(76):
        for x in range(128):
            if plate.getpixel((x,y))[3]:garments[category(x,y)].putpixel((x,y),source.getpixel((x,y)))
    donors=[]
    for record in spec['donorCandidates']:
        q=tuple(record['pixel']);rgba=source.getpixel(q)
        require(list(rgba)==record['rgba'] and rgba[3]==255,'NW explorer IDLE donor changed')
        if plate.getpixel(q)[3]:donors.append(q)
    body=plate.copy();repairs=[]
    for y,x0,x1 in spec['bodyContour']:
        require(43<=y<76 and 0<=x0<x1<=128,'Authored NW body contour outside upper crop')
        for x in range(x0,x1):
            if not any(im.getpixel((x,y))[3] for im in arms.values()):continue
            kind=category(x,y);row=[q for q in donors if q[1]==y and category(*q)==kind]
            require(bool(row),f'No same-IDLE-row/garment donor for {x},{y} {kind}')
            q=min(row,key=lambda q:abs(q[0]-x));rgba=source.getpixel(q);body.putpixel((x,y),rgba)
            repairs.append({'destination':[x,y],'donor':list(q),'rgba':list(rgba),'garment':kind,
                            'status':'AUTHORED hidden NW garment; original explorer IDLE donor, not recovered art'})
    rest=body.copy()
    for im in arms.values():rest.alpha_composite(im)
    require(rest.tobytes()==source.tobytes(),'Authored source arrangement rest must reconstruct exactly')
    overlaps={};overlap_points=set()
    for record in spec.get('authoredJointOverlap',[]):
        p=record['pixel']
        require(isinstance(p,list) and len(p)==2 and all(type(v) is int for v in p)
                and 0<=p[0]<128 and 43<=p[1]<76 and record['side']=='left'
                and record['targetPart']=='fore' and record['originalOwner']=='left/upper'
                and 'AUTHORED' in record['status'],'Unsupported authored fore-root overlap')
        q=tuple(p);rgba=source.getpixel(q);key='left/fore'
        require(q not in overlap_points and list(rgba)==record['rgba'] and rgba[3]==255
                and arms['left/upper'].getpixel(q)==rgba and not arms[key].getpixel(q)[3],
                'Overlap must copy unchanged upper-owned RGBA into an explicitly authored hidden surface')
        overlaps.setdefault(key,Image.new('RGBA',source.size)).putpixel(q,rgba);overlap_points.add(q)
    poses=[]
    for pose in spec['poses']:
        transformed={};matrices={}
        for side in ('left','right'):
            joints=spec['joints'][side];motion=pose[side]
            upper=ops.joint_rotation(joints['shoulder'],motion['upperDeg'])
            fore=ops.chain_transform(upper,ops.joint_rotation(joints['elbow'],motion['foreRelativeDeg']))
            matrices[side]={'cap':upper,'upper':upper,'fore':fore,'hand':fore}
            arm=Image.new('RGBA',source.size)
            for part in ('cap','upper','fore','hand'):
                key=side+'/'+part;layer=arms[key]
                if key in overlaps:
                    layer=layer.copy();layer.alpha_composite(overlaps[key])
                arm.alpha_composite(ops.moved_cutout(layer,matrices[side][part]))
            transformed[side]=arm
        final=Image.new('RGBA',source.size)
        for side in pose['behindTorso']:final.alpha_composite(transformed[side])
        final.alpha_composite(body)
        for side in ('left','right'):
            if side not in pose['behindTorso']:final.alpha_composite(transformed[side])
        poses.append({'name':pose['name'],'image':final,'arms':transformed,'matrices':matrices})
    require(poses[0]['image'].tobytes()==source.tobytes(),'Neutral depth ordering must preserve reference arrangement')
    return source,plate,arms,garments,body,repairs,poses


def sheet(images,labels,columns=3):
    result=Image.new('RGB',(columns*480,((len(images)+columns-1)//columns)*370),(20,38,43));draw=ImageDraw.Draw(result)
    for i,(im,label) in enumerate(zip(images,labels)):
        x,y=i%columns*480+20,i//columns*370+42
        crop=im.crop((44,42,84,76)).resize((440,306),Image.Resampling.NEAREST)
        result.paste(crop,(x,y),crop);draw.text((x,y-26),label,fill='white')
    return result


def export(spec,output):
    output=output.resolve();require(output.is_relative_to(ROOT/'artifacts') and not output.exists(),'Fresh ignored NW rig proposal output required')
    source,plate,arms,garments,body,repairs,poses=prepare(spec);output.mkdir(parents=True)
    ownership=Image.new('RGBA',source.size)
    for name,im in {**garments,**arms}.items():ownership.paste(COLORS[name],(0,0),im.getchannel('A'))
    repair_overlay=source.copy()
    for r in repairs:repair_overlay.putpixel(tuple(r['destination']),(235,65,181,255))
    sheet([source,ownership,body,garments['shirt'],garments['vest'],garments['belt']],
          ['AUTHORED coherent reference arrangement','Exclusive source ownership PROPOSAL','AUTHORED neutral body','Original shirt ownership','Original vest ownership','Original belt ownership']).save(output/'nw-explorer-ownership-and-body.png')
    sheet([source,body,repair_overlay,poses[0]['image'],poses[1]['image'],ownership],
          ['Reference arrangement','Neutral garment plate','Magenta: AUTHORED hidden fill','Neutral exact reconstruction','AUTHORED A-forward/B-back','Authored LEFT gold / RIGHT purple']).save(output/'nw-explorer-two-endpoints.png')
    im=[];labels=[]
    for side in ('left','right'):
        for pose in poses:im.append(pose['arms'][side]);labels.append(side+' '+pose['name'])
    sheet(im,labels,2).save(output/'nw-explorer-isolated-arm-endpoints.png')
    if spec.get('authoredJointOverlap'):
        predecessor=copy.deepcopy(spec);predecessor['authoredJointOverlap']=[]
        before=prepare(predecessor)[-1][1]['arms']['left']
        palette_patch=Image.new('RGBA',source.size)
        for r in spec['authoredJointOverlap']:palette_patch.putpixel(tuple(r['pixel']),tuple(r['rgba']))
        sheet([source,before,poses[1]['arms']['left'],palette_patch],
              ['Original upper-owned55/56,58 source','BEFORE: actual square elbow notch','AFTER: 2 AUTHORED hidden overlaps','AUTHORED overlap sourcecoords/RGBA'],2).save(output/'nw-explorer-elbow-overlap-before-after.png')
        labelled=Image.new('RGB',(3*350,330),(20,38,43));draw=ImageDraw.Draw(labelled)
        for i,(im,label) in enumerate([(source,'SOURCE upper-owned55/56,58'),(before,'BEFORE alpha gap55/56,59/60'),(poses[1]['arms']['left'],'AFTER authored overlap')]):
            x,y=i*350+40,44
            crop=im.crop((50,54,60,63)).resize((280,252),Image.Resampling.NEAREST)
            labelled.paste(crop,(x,y),crop);draw.text((i*350+8,8),label,fill='white')
            for px in range(50,60):
                sx=x+(px-50)*28;draw.line((sx,y,sx,y+252),fill=(68,82,82));draw.text((sx,y-14),str(px),fill='white')
            for py in range(54,63):
                sy=y+(py-54)*28;draw.line((x,sy,x+280,sy),fill=(68,82,82));draw.text((x-24,sy),str(py),fill='white')
        labelled.save(output/'nw-explorer-elbow-labelled-grid.png')
    body.save(output/'authored-neutral-body.png')
    for pose in poses:pose['image'].save(output/(pose['name']+'.png'))
    manifest={'status':spec['status'],'sourceArrangementRgbaSha256':digest(source.tobytes()),
              'specSha256':digest(SPEC.read_bytes()),'toolSha256':digest(Path(__file__).read_bytes()),
              'orientationSpecSha256':spec['orientationSpecSha256'],'sourceMeasurement':spec['sourceMeasurement'],
              'authoredConvention':spec['authoredConvention'],'jointsStatus':spec['jointsStatus'],'joints':spec['joints'],
              'sourceArms':{k:ops.row_runs(im) for k,im in arms.items()},'sourceGarments':{k:ops.row_runs(im) for k,im in garments.items()},
              'authoredHiddenFill':repairs,'poses':[{'name':p['name'],'matrices':p['matrices'],'rgbaSha256':digest(p['image'].tobytes())} for p in poses],
              'sourceBoundaryAssignments':spec.get('sourceBoundaryAssignments',[]),
              'authoredJointOverlap':spec.get('authoredJointOverlap',[]),
              'ownershipScope':'Original source partition remains exclusive; authoredJointOverlap deliberately adds separately labelled hidden surface copies, not original source ownership',
              'bodyComponents43Plus':[{'opaquePixels':len(c),'pixels':c if len(c)<12 else None} for c in components(body)],
              'armComponents':[{'pose':p['name'],'parts':{s:[len(c) for c in components(im)] for s,im in p['arms'].items()}} for p in poses],
              'gearContract':spec['gearContract']}
    (output/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
    print('NW EXPLORER SOURCE REST PASS; anatomy/pose/phase remains authoring proposal')


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--output',type=Path,required=True)
    args=parser.parse_args();export(json.loads(SPEC.read_text()),args.output)
