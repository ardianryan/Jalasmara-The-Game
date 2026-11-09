#!/usr/bin/env python3
"""Author one eight-frame review-only WEST upper-body loop; never modify game resources."""
import argparse
from collections import Counter
import hashlib
import json
import math
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
SIZE = 128
IDENTITY = (1., 0., 0., 0., 1., 0.)


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def point(matrix, p):
    a, b, c, d, e, f = matrix
    return a*p[0]+b*p[1]+c, d*p[0]+e*p[1]+f


def compose(first, second):
    a,b,c,d,e,f = first
    g,h,i,j,k,l = second
    return (a*g+b*j,a*h+b*k,a*i+b*l+c,d*g+e*j,d*h+e*k,d*i+e*l+f)


def rotation(pivot, degrees):
    a = math.radians(degrees)
    c,s = math.cos(a),math.sin(a)
    x,y = pivot
    return (c,-s,x-c*x+s*y,s,c,y-s*x-c*y)


def transformed(image, matrix):
    a,b,c,d,e,f = matrix
    det = a*e-b*d
    inv = (e/det,-b/det,(b*f-e*c)/det,-d/det,a/det,(d*c-a*f)/det)
    return image.transform((SIZE,SIZE),Image.Transform.AFFINE,inv,resample=Image.Resampling.NEAREST)


def polygon_mask(points):
    mask = Image.new('L',(SIZE,SIZE))
    ImageDraw.Draw(mask).polygon([tuple(p) for p in points],fill=255)
    return mask


def opaque_mask(image):
    return image.getchannel('A').point(lambda v:255 if v else 0)


def runs(mask):
    result = []
    for y in range(SIZE):
        start = None
        for x in range(SIZE+1):
            occupied = x<SIZE and mask.getpixel((x,y)) != 0
            if occupied and start is None: start=x
            if not occupied and start is not None:
                result.append([y,start,x]);start=None
    return result


def composite(base, semantic, layer, tag):
    base.alpha_composite(layer)
    semantic.paste(tag,(0,0),opaque_mask(layer))


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--spec',type=Path,default=ROOT/'tools/player-gait/west-upper-prototype.json')
    parser.add_argument('--output',type=Path,required=True)
    args=parser.parse_args()
    output_path = args.output.resolve()
    if output_path.is_relative_to(ROOT/'client-godot') or output_path.is_relative_to(ROOT/'apps'):
        raise ValueError('Review-only output must stay outside runtime/application directories')
    if args.output.exists(): raise ValueError('Use a fresh output directory; preserve prior review')
    spec=json.loads(args.spec.read_text())
    source_path=ROOT/spec['source']
    assert sha(source_path)==spec['sourceSha256']
    atlas=Image.open(source_path).convert('RGBA')
    row,col=spec['sourceCell']['row'],spec['sourceCell']['column']
    source=atlas.crop((col*SIZE,row*SIZE,(col+1)*SIZE,(row+1)*SIZE))
    palette={name:source.getpixel(tuple(p)) for name,p in spec['paletteSamples'].items()}
    assert all(color[3]==255 for color in palette.values())
    source_parts={}
    # Priority makes every original source pixel belong to at most one part.
    occupied=set()
    for arm in ('near','far'):
        for part in ('palm','fore','upper'):
            mask=polygon_mask(spec['arms'][arm]['parts'][part])
            layer=Image.new('RGBA',(SIZE,SIZE))
            for y in range(SIZE):
                for x in range(SIZE):
                    if mask.getpixel((x,y)) and source.getpixel((x,y))[3] and (x,y) not in occupied:
                        layer.putpixel((x,y),source.getpixel((x,y)));occupied.add((x,y))
            source_parts[arm+'/'+part]=layer
    plate=source.copy(); repair=Image.new('RGBA',(SIZE,SIZE))
    envelope=polygon_mask(spec['torsoRepairEnvelope'])
    repair_provenance=[]
    x0,y0,x1,y1=spec['verifiedClothDonor']
    for x,y in occupied:
        plate.putpixel((x,y),(0,0,0,0))
        if envelope.getpixel((x,y)):
            donor=(min(x1-1,x0+max(0,x-59)//5),max(y0,min(y1-1,y)))
            repair.putpixel((x,y),source.getpixel(donor))
            repair_provenance.append({'destination':[x,y],'paletteDonor':list(donor),'authored':True})
    plate.alpha_composite(repair)
    far_extension=Image.new('RGBA',(SIZE,SIZE));draw=ImageDraw.Draw(far_extension)
    draw.polygon([tuple(p) for p in spec['arms']['far']['authoredUpperGap']],fill=palette['skinShadow'])
    # Keep the hidden far shoulder beneath the shirt, rather than adding a second cap.
    near_sleeve=Image.new('RGBA',(SIZE,SIZE));d=ImageDraw.Draw(near_sleeve)
    for key,color in [('authoredSleeve','sleeve'),('authoredSleeveHighlight','shirtShadow'),('authoredCuff','sleeve')]:
        d.polygon([tuple(p) for p in spec['arms']['near'][key]],fill=palette[color])
    args.output.mkdir(parents=True)
    source.save(args.output/'original-west-frame0.png')
    plate.save(args.output/'torso-plate-authored-repair.png')
    repair.save(args.output/'authored-torso-repair-mask.png')
    source_parts_manifest={}
    for name,layer in source_parts.items():
        filename='source-'+name.replace('/','-')+'.png';layer.save(args.output/filename)
        source_parts_manifest[name]={'file':filename,'sourceCellRunsYX0X1':runs(opaque_mask(layer)),
                                      'opaquePixels':sum(v!=0 for v in layer.getchannel('A').getdata())}
    far_extension.save(args.output/'authored-far-shoulder-extension.png')
    near_sleeve.save(args.output/'authored-near-sleeve.png')
    panels=[];pose_manifest=[]
    for pose in spec['poses']:
        rendered=Image.new('RGBA',(SIZE,SIZE));semantic=Image.new('L',(SIZE,SIZE))
        transforms={}
        for arm in ('near','far'):
            arm_spec=spec['arms'][arm];angles=pose[arm]
            upper=rotation(arm_spec['shoulder'],angles['upperDeg'])
            fore=compose(upper,rotation(arm_spec['elbow'],angles['foreRelativeDeg']))
            palm=compose(fore,rotation(arm_spec['wrist'],angles['palmRelativeDeg']))
            transforms[arm]={'upper':upper,'fore':fore,'palm':palm}
        # Far arm is behind the original shirt plate; near arm is in front.
        composite(rendered,semantic,transformed(far_extension,transforms['far']['upper']),3)
        far_palm=transformed(source_parts['far/palm'],transforms['far']['palm'])
        far_palm_hidden=sum(bool(far_palm.getpixel((x,y))[3] and plate.getpixel((x,y))[3]) for y in range(SIZE) for x in range(SIZE))
        for part in ('upper','fore','palm'):
            composite(rendered,semantic,transformed(source_parts['far/'+part],transforms['far'][part]),20)
        composite(rendered,semantic,plate,1)
        semantic.paste(2,(0,0),opaque_mask(repair))
        # One-pixel joint seals are authored, not recovered pixels beneath overlap.
        joint_seals=Image.new('RGBA',(SIZE,SIZE));d=ImageDraw.Draw(joint_seals)
        for name,matrix in [('elbow',transforms['near']['upper']),('wrist',transforms['near']['fore'])]:
            x,y=point(matrix,spec['arms']['near'][name]);x,y=round(x),round(y)
            d.ellipse((x-1,y-1,x+1,y+1),fill=palette['skinShadow'])
        composite(rendered,semantic,joint_seals,4)
        composite(rendered,semantic,transformed(near_sleeve,transforms['near']['upper']),5)
        for part in ('fore','palm'):
            composite(rendered,semantic,transformed(source_parts['near/'+part],transforms['near'][part]),10)
        # Do not include the unmodified lower body in the actual prototype texture.
        rendered=rendered.crop((0,0,SIZE,spec['upperCutY']))
        sem=semantic.crop((0,0,SIZE,spec['upperCutY']))
        filename=f"proposal-west-{pose['frame']}.png";rendered.save(args.output/filename)
        colors={1:(84,99,102,255),2:(242,62,188,255),3:(242,62,188,255),4:(242,62,188,255),5:(242,62,188,255),10:(44,216,215,255),20:(250,191,70,255)}
        mask=Image.new('RGBA',rendered.size)
        for y in range(rendered.height):
            for x in range(rendered.width):
                if rendered.getpixel((x,y))[3]:mask.putpixel((x,y),colors.get(sem.getpixel((x,y)),(255,0,0,255)))
        mask.save(args.output/f"provenance-west-{pose['frame']}.png")
        palms={}
        for arm in ('near','far'):
            palms[arm]=list(point(transforms[arm]['palm'],spec['arms'][arm]['wrist']))
        counts=Counter(sem.getdata())
        pose_manifest.append({'frame':pose['frame'],'label':pose['label'],'texture':filename,
                              'jointTransforms':transforms,'transformedWristAnchors':palms,
                              'transformedShoulderAnchors':{a:list(point(transforms[a]['upper'],spec['arms'][a]['shoulder'])) for a in ('near','far')},
                              'transformedElbowAnchors':{a:list(point(transforms[a]['upper'],spec['arms'][a]['elbow'])) for a in ('near','far')},
                              'farPalmTexelsOccludedByShirt':far_palm_hidden,
                              'visibleAuthoredPixels':sum(counts[k] for k in (2,3,4,5)),
                              'visibleNearSourcePixels':counts[10],'visibleFarSourcePixels':counts[20],
                              'semanticMask':f"provenance-west-{pose['frame']}.png"})
        original=atlas.crop((pose['frame']*SIZE,row*SIZE,(pose['frame']+1)*SIZE,(row+1)*SIZE))
        proposed=original.copy();proposed.paste((0,0,0,0),(0,0,SIZE,spec['upperCutY']));proposed.paste(rendered,(0,0))
        fullmask=Image.new('RGBA',(SIZE,SIZE));fullmask.paste(mask,(0,0))
        panels.append((original,proposed,fullmask))
    # Each frame has original/proposal/provenance at an identical integer scale.
    scale=2;cell=SIZE*scale;header=28;gap=12;block=3*(cell+gap)
    sheet=Image.new('RGB',(2*block+gap,4*(cell+header+gap)+gap),(23,39,43));d=ImageDraw.Draw(sheet)
    strip=Image.new('RGBA',(SIZE*8,SIZE))
    upper_strip=Image.new('RGBA',(SIZE*8,spec['upperCutY']))
    for index,(original,proposed,mask) in enumerate(panels):
        strip.paste(proposed,(index*SIZE,0))
        upper_strip.paste(proposed.crop((0,0,SIZE,spec['upperCutY'])),(index*SIZE,0))
        row_index,column_index=divmod(index,2)
        for column,(im,label) in enumerate(zip((original,proposed,mask),('ORIGINAL','PROPOSAL','PROVENANCE'))):
            x=gap+column_index*block+column*(cell+gap);y=gap+row_index*(cell+header+gap)
            d.text((x,y),f"{label} WEST {spec['poses'][index]['frame']}",fill=(244,227,189))
            scaled=im.resize((cell,cell),Image.Resampling.NEAREST)
            sheet.paste(scaled,(x,y+header),scaled)
    sheet.save(args.output/'west-upper-before-after.png')
    strip.save(args.output/'west-upper-eight-frame-strip.png')
    upper_strip.save(args.output/'west-upper-eight-frame-textures.png')
    manifest={'status':spec['status'],'sourceSha256':sha(source_path),'specSha256':sha(args.spec),
              'scriptSha256':sha(Path(__file__)),'sourceParts':source_parts_manifest,
              'authoredTorsoRepairPixels':repair_provenance,'poses':pose_manifest,
              'anatomicalMapping':spec['anatomicalMapping'],'occlusion':spec['occlusion'],
              'authoredNearSleeveRunsYX0X1':runs(opaque_mask(near_sleeve)),
              'omittedSourceParts':['near/upper (replaced by authored sleeve)'],
              'cycle':spec['cycle'],'paletteSourceSamples':spec['paletteSamples'],'originalSourceUnchanged':sha(source_path)==spec['sourceSha256'],
              'limits':['One WEST daily eight-frame arm proposal; not full eight-view gait or runtime',
                        'Hidden torso/far sleeve pixels are authored, not recovered',
                        'Near-left/far-right is intended cross-view convention; no independent WEST anatomical marker or actual foot phase proof',
                        'No native/play-size/terrain/props/arm-to-foot cadence acceptance']}
    (args.output/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
    print(json.dumps({'output':str(args.output),'poses':pose_manifest,'originalUnchanged':manifest['originalSourceUnchanged']},indent=2))


if __name__=='__main__':main()
