#!/usr/bin/env python3
"""Read-only NW upper source inventory; never infer anatomical side from screen X."""
import argparse
import hashlib
import importlib.util
import json
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
SPEC = Path(__file__).with_suffix('.json')
loader = importlib.util.spec_from_file_location('source_ownership', Path(__file__).with_name('south-upper-ownership.py'))
ownership = importlib.util.module_from_spec(loader)
loader.loader.exec_module(ownership)
require = ownership.anchors.require
DIRECTIONS = ['east','south_east','south','south_west','west','north_west','north','north_east']


def digest(data): return hashlib.sha256(data).hexdigest()


def sources(spec):
    require(spec.get('schemaVersion') == 1 and spec.get('view') == 'north_west'
            and spec.get('walkRow') == 5 and spec.get('idleColumn') == 5
            and spec.get('canonicalDirections') == DIRECTIONS, 'Canonical NW source layout mismatch')
    require(spec.get('anatomicalSide') == 'unknown' and spec.get('wrist') is None and spec.get('grip') is None,
            'This source audit does not establish anatomical side or sockets')
    images = {}
    for outfit in ('daily','explorer'):
        images[outfit] = {}
        for kind in ('walk','idle'):
            record = spec['sources'][outfit][kind]
            expected_path = f'client-godot/resources/art/player-gait/male-nusantara-{outfit}-{kind}-8way-v1.png'
            require(record['path'] == expected_path, 'Only original project source is audited')
            path = ROOT / record['path']
            require(digest(path.read_bytes()) == record['sha256'], 'Original source hash mismatch')
            im = Image.open(path).convert('RGBA')
            require(im.size == ((1024,1024) if kind == 'walk' else (1024,128)), 'Original atlas dimensions differ')
            images[outfit][kind] = im
    return images


def cell(images, outfit, frame):
    require(outfit in ('daily','explorer') and type(frame) is int and frame in range(8), 'Unsupported original NW cell')
    return images[outfit]['walk'].crop((frame*128,640,(frame+1)*128,716))


def patch_inventory(spec, images):
    records = []
    for outfit in ('daily','explorer'):
        for entry in spec['boundaryPatches'][outfit]:
            require(entry['frame'] in (0,4) and entry['anatomicalSide'] == 'unknown'
                    and entry['wrist'] is None and entry['grip'] is None, 'Do not promote inspection patch to measured anatomy')
            source = cell(images, outfit, entry['frame'])
            for name, rect in entry['regions'].items():
                require(len(rect) == 4 and all(type(v) is int for v in rect)
                        and 0 <= rect[0] < rect[2] <= 128 and 43 <= rect[1] < rect[3] <= 76,
                        'Inspection patch outside upper-body source')
                crop = source.crop(tuple(rect))
                records.append({'outfit': outfit, 'frame': entry['frame'], 'name': name, 'rect': rect,
                                'rgbaSha256': digest(crop.tobytes()), 'opaqueSourceRunsLocalYX0X1': ownership.row_runs(crop),
                                'status': entry['status'], 'anatomicalSide': 'unknown', 'wrist': None, 'grip': None})
    return records


def canonical_sheet(outfit, images):
    result = Image.new('RGB',(8*192,2*260),(20,38,43))
    draw = ImageDraw.Draw(result)
    for i, name in enumerate(DIRECTIONS):
        cells = [images['walk'].crop((0,i*128,128,i*128+76)), images['idle'].crop((i*128,0,(i+1)*128,76))]
        for row, image in enumerate(cells):
            x,y = i*192+6,row*260+38
            scaled = image.crop((36,12,96,76)).resize((180,192),Image.Resampling.NEAREST)
            result.paste(scaled,(x,y),scaled)
            draw.text((x,y-25),outfit+' '+name+' '+('walk0' if row == 0 else 'IDLE'),fill='white')
    return result


def export(spec, output):
    output = output.resolve()
    require(output.is_relative_to(ROOT/'artifacts') and not output.exists(), 'Fresh ignored source-audit output required')
    images = sources(spec)
    patches = patch_inventory(spec, images)
    output.mkdir(parents=True)
    frames = []
    for outfit in ('daily','explorer'):
        canonical_sheet(outfit, images[outfit]).save(output/f'{outfit}-canonical-eight-views-walk-idle.png')
        sheet = Image.new('RGB',(4*440,2*340),(20,38,43))
        draw = ImageDraw.Draw(sheet)
        for f in range(8):
            source = cell(images,outfit,f)
            x,y = f%4*440+12,f//4*340+32
            crop = source.crop((40,28,92,76)).resize((416,288),Image.Resampling.NEAREST)
            sheet.paste(crop,(x,y),crop)
            draw.text((x,y-23),f'{outfit} NW row5 frame{f}: original, sides UNKNOWN',fill='white')
            source.save(output/f'{outfit}-nw-original-upper-{f}.png')
            frames.append({'outfit':outfit,'frame':f,'rgbaSha256':digest(source.tobytes()),'bbox':source.getbbox(),
                           'anatomicalSide':'unknown','handPalmSurface':'Not measured; rear hand skin can be palm or back of hand',
                           'wrist':None,'grip':None})
        sheet.save(output/f'{outfit}-nw-eight-upper.png')
    boundary_sheet = Image.new('RGB',(2*540,2*400),(20,38,43))
    draw = ImageDraw.Draw(boundary_sheet)
    for i,(outfit,f) in enumerate((('daily',0),('daily',4),('explorer',0),('explorer',4))):
        x,y = i%2*540+30,i//2*400+44
        image = cell(images,outfit,f).crop((40,42,92,76)).resize((468,306),Image.Resampling.NEAREST)
        boundary_sheet.paste(image,(x,y),image)
        draw.text((x,y-28),f'{outfit} NW frame{f}: inspection regions, NOT limb masks',fill='white')
        entry = next(e for e in spec['boundaryPatches'][outfit] if e['frame'] == f)
        for (name,rect),color in zip(entry['regions'].items(),((78,225,228),(246,196,74),(237,123,193))):
            x0,y0,x1,y1 = rect
            draw.rectangle((x+(x0-40)*9,y+(y0-42)*9,x+(x1-40)*9,y+(y1-42)*9),outline=color,width=2)
        draw.text((x,y+320),'Cyan sleeve / gold arm-hand / pink secondary region; side UNKNOWN',fill='white')
    boundary_sheet.save(output/'nw-frame0-4-source-boundary-regions.png')
    manifest = {'status':spec['status'],'sources':spec['sources'],'findings':spec['findings'],
                'specSha256':digest(SPEC.read_bytes()),'toolSha256':digest(Path(__file__).read_bytes()),
                'lowerAnnotationEvidence':spec['lowerAnnotationEvidence'],'frames':frames,'boundaryPatches':patches,
                'scope':'Original source patches may overlap and contain garment/skin/outline; not segmented part ownership or reconstructed anatomy'}
    (output/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
    print('NW SOURCE INVENTORY EXPORTED: original16upperframes; explorer orientation mismatch OPEN; anatomical side unknown')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output',type=Path,required=True)
    args = parser.parse_args()
    export(json.loads(SPEC.read_text()),args.output)
