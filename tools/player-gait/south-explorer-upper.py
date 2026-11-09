#!/usr/bin/env python3
"""Inspect source-specific SOUTH explorer garments and two authored upper poses."""
import argparse
import hashlib
import importlib.util
import json
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
SPEC = Path(__file__).with_suffix('.json')
loader = importlib.util.spec_from_file_location('south_ownership', Path(__file__).with_name('south-upper-ownership.py'))
ownership = importlib.util.module_from_spec(loader)
loader.loader.exec_module(ownership)
require = ownership.anchors.require
COLORS = {'belt': (208, 100, 80, 255), 'vest': (224, 189, 96, 255), 'shirt': (59, 176, 182, 255), 'other': (126, 142, 149, 255)}


def digest(data): return hashlib.sha256(data).hexdigest()


def prepare(spec):
    require(spec.get('schemaVersion') == 1 and spec.get('identity') == 'male_nusantara'
            and spec.get('outfit') == 'explorer' and spec.get('view') == 'south'
            and type(spec.get('sourceFrame')) is int and spec['sourceFrame'] == 0
            and spec.get('sourceSha256') == ownership.anchors.SOURCES['explorer'][1], 'Only original SOUTH explorer0 is reviewed')
    require(spec['case']['outfit'] == 'explorer' and spec['case']['frame'] == 0, 'Source case differs from explorer scope')
    require('AUTHORED' in spec.get('jointsStatus', '') and len(spec.get('poses', [])) == 2, 'Explorer endpoints/joints require explicit authored status')
    require(spec['gearContract']['newNodes'] == 0 and spec['gearContract']['newSatchelPixels'] == 0
            and spec['gearContract']['atlasVestMeshEnabled'] is False
            and spec['gearContract']['tankNetEnabled'] is False, 'Do not introduce duplicate garment/gear in authoring proposal')
    source, plate, arms, rebuilt = ownership.split(spec['case'])
    masks = {name: ownership.polygon(poly) for name, poly in spec['garmentPolygons'].items()}
    def category(x, y):
        for name in ('belt', 'vest', 'vestRight', 'shirt'):
            if masks[name].getpixel((x, y)):
                return 'vest' if name == 'vestRight' else name
        return 'other'
    garments = {name: Image.new('RGBA', source.size) for name in COLORS}
    for y in range(76):
        for x in range(128):
            if plate.getpixel((x, y))[3]: garments[category(x, y)].putpixel((x, y), plate.getpixel((x, y)))
    donors = []
    for record in spec['sourceRowDonorCandidates']:
        q = tuple(record['pixel'])
        require(list(source.getpixel(q)) == record['rgba'] and record['rgba'][3] == 255, 'Explorer row donor differs from source')
        if plate.getpixel(q)[3]: donors.append(q)
    body = plate.copy()
    repaired = []
    for y, x0, x1 in spec['bodyRuns']:
        require(43 <= y < 76 and 0 <= x0 < x1 <= 128, 'Body proposal outside original upper cell')
        for x in range(x0, x1):
            if not any(layer.getpixel((x, y))[3] for layer in arms.values()): continue
            kind = category(x, y)
            row = [q for q in donors if q[1] == y and category(*q) == kind]
            require(bool(row), f'No owned same-row same-garment source donor at {x},{y} ({kind})')
            q = min(row, key=lambda q: abs(q[0] - x))
            rgba = source.getpixel(q)
            body.putpixel((x, y), rgba)
            repaired.append({'destination': [x, y], 'donor': list(q), 'rgba': list(rgba), 'garment': kind,
                             'status': 'AUTHORED hidden explorer garment, not recovered original'})
    rest = body.copy()
    for layer in arms.values(): rest.alpha_composite(layer)
    require(rest.tobytes() == source.tobytes(), 'Original rest differs after explorer hidden garment proposal')
    pose_spec = {'daily0AuthoredProposal': {'joints': spec['joints'], 'newPoseProposal': {'poses': spec['poses']}}}
    poses = ownership.authored_extremes(pose_spec, body, arms)
    return source, plate, arms, garments, body, repaired, poses


def grid(images, labels, columns=3):
    sheet = Image.new('RGB', (columns*480, ((len(images)+columns-1)//columns)*350), (20, 38, 43))
    draw = ImageDraw.Draw(sheet)
    for i, (image, label) in enumerate(zip(images, labels)):
        x, y = i % columns*480+20, i//columns*350+40
        draw.text((x, y-25), label, fill='white')
        crop = image.crop((44, 42, 88, 76)).resize((440, 272), Image.Resampling.NEAREST)
        sheet.paste(crop, (x, y), crop)
    return sheet


def export(spec, output):
    output = output.resolve()
    require(output.is_relative_to(ROOT/'artifacts') and not output.exists(), 'Fresh ignored review output required')
    source, plate, arms, garments, body, repairs, poses = prepare(spec)
    output.mkdir(parents=True)
    owned = Image.new('RGBA', source.size)
    for name, im in garments.items(): owned.paste(COLORS[name], (0,0), im.getchannel('A'))
    for name, im in arms.items(): owned.paste(ownership.COLORS[name], (0,0), im.getchannel('A'))
    grid([source, owned, plate, garments['shirt'], garments['vest'], garments['belt']],
         ['Original explorer0', 'Exclusive ownership draft', 'Original remainder / holes', 'SOURCE shirt ownership proposal', 'SOURCE vest/pockets proposal', 'SOURCE belt ownership proposal']).save(output/'explorer0-source-garment-ownership.png')
    repaired_overlay = source.copy()
    for record in repairs: repaired_overlay.putpixel(tuple(record['destination']), (235,65,181,255))
    grid([source, body, repaired_overlay, poses[0][1], poses[1][1], ownership.ownership(source, arms)],
         ['Original explorer0', 'AUTHORED neutral garment plate', 'Magenta: AUTHORED hidden fill', 'Original-rest reconstruction', 'AUTHORED opposing endpoint', 'Source arm ownership draft']).save(output/'explorer0-two-endpoints-and-body.png')
    extremes, labels = [], []
    for side in ('left', 'right'):
        original = Image.new('RGBA', source.size)
        moved = Image.new('RGBA', source.size)
        for part in ('upper', 'fore', 'palm'):
            original.alpha_composite(arms[side+'/'+part])
            moved.alpha_composite(ownership.moved_cutout(arms[side+'/'+part], poses[1][2][side][part]))
        extremes.extend([original, moved]); labels.extend([side+' original cutout', side+' AUTHORED endpoint'])
    grid(extremes, labels, 2).save(output/'explorer0-separate-arm-endpoints.png')
    for name, image in garments.items(): image.save(output/f'original-garment-{name}.png')
    body.save(output/'authored-hidden-garment-plate.png')
    for name, image, transforms in poses: image.save(output/(name+'.png'))
    manifest = {'status': spec['status'], 'source': ownership.anchors.SOURCES['explorer'],
                'sourceUpperRgbaSha256': digest(source.tobytes()), 'specSha256': digest(SPEC.read_bytes()),
                'toolSha256': digest(Path(__file__).read_bytes()), 'ownershipToolSha256': digest(Path(ownership.__file__).read_bytes()),
                'sourceArms': {k: ownership.row_runs(v) for k,v in arms.items()},
                'sourceGarments': {k: ownership.row_runs(v) for k,v in garments.items()},
                'authoredHiddenGarment': repairs, 'jointsStatus': spec['jointsStatus'], 'joints': spec['joints'],
                'poses': [{'name': n, 'transforms': t, 'rgbaSha256': digest(im.tobytes())} for n, im, t in poses],
                'gearContract': spec['gearContract']}
    (output/'manifest.json').write_text(json.dumps(manifest, indent=2)+'\n')
    print('EXPLORER SOURCE/REST RECOMPOSITION PASS; garment/pose ownership remains authoring review')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    export(json.loads(SPEC.read_text()), args.output)
