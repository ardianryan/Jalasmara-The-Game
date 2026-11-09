#!/usr/bin/env python3
"""Render an original, review-only SOUTH daily upper loop from pinned v7 cutouts."""
import argparse
import copy
import hashlib
import importlib.util
import json
import math
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
SPEC = Path(__file__).with_suffix('.json')
loader = importlib.util.spec_from_file_location('south_ownership', Path(__file__).with_name('south-upper-ownership.py'))
ownership = importlib.util.module_from_spec(loader)
loader.loader.exec_module(ownership)
require = ownership.anchors.require


def digest(data):
    return hashlib.sha256(data).hexdigest()


def validate(spec):
    require(spec.get('schemaVersion') == 1 and spec.get('identity') == 'male_nusantara'
            and spec.get('outfit') == 'daily' and spec.get('view') == 'south'
            and type(spec.get('sourceFrame')) is int and spec['sourceFrame'] == 0
            and type(spec.get('frameCount')) is int and spec['frameCount'] == 8,
            'Only eight SOUTH daily0-derived upper frames are authored')
    require(spec.get('ownershipSpecSha256') == digest(ownership.SPEC.read_bytes()), 'Reviewed ownership spec changed')
    require(spec.get('behindTorso') == ['left'], 'Depth ordering requires separate authored review')
    require('AUTHORED' in spec.get('jointsStatus', '') and 'No Lower' in spec.get('phaseStatus', ''), 'Do not promote authored joints or phase to source proof')
    for side in ('left', 'right'):
        motion = spec['motion'][side]
        require(set(motion) == {'upperSinDeg', 'foreMeanDeg', 'foreCosDeg'}
                and all(type(v) in (int, float) and math.isfinite(v) for v in motion.values())
                and abs(motion['upperSinDeg']) <= 3
                and -80 <= motion['foreMeanDeg'] - abs(motion['foreCosDeg'])
                and motion['foreMeanDeg'] + abs(motion['foreCosDeg']) <= 0,
                'Motion exceeds reviewed rigid-cutout authoring envelope')
    require(spec.get('authoredOutputPixels') == [], 'New output pixels require a separate authoring proposal')


def pose_at(spec, frame):
    require(type(frame) is int, 'Frame must be an integer')
    phase = (frame % spec['frameCount']) / spec['frameCount']
    angle = math.tau * phase
    pose = {'name': f'authored-{frame % 8}', 'behindTorso': list(spec['behindTorso'])}
    for side in ('left', 'right'):
        motion = spec['motion'][side]
        pose[side] = {'upperDeg': round(motion['upperSinDeg'] * math.sin(angle), 8),
                      'foreRelativeDeg': round(motion['foreMeanDeg'] + motion['foreCosDeg'] * math.cos(angle), 8)}
    return pose


def point(matrix, p):
    a, b, c, d, e, f = matrix
    return [a * p[0] + b * p[1] + c, d * p[0] + e * p[1] + f]


def components(image):
    points = {(x, y) for y in range(image.height) for x in range(image.width) if image.getpixel((x, y))[3]}
    result = []
    while points:
        todo = [points.pop()]
        count = 0
        while todo:
            x, y = todo.pop()
            count += 1
            for dx in (-1, 0, 1):
                for dy in (-1, 0, 1):
                    neighbor = x + dx, y + dy
                    if neighbor in points:
                        points.remove(neighbor)
                        todo.append(neighbor)
        result.append(count)
    return sorted(result, reverse=True)


def prepare(spec):
    validate(spec)
    base = json.loads(ownership.SPEC.read_text())
    source, plate, layers, _ = ownership.split(base['cases'][0])
    body, repair, repair_records, _ = ownership.authored_plate(base, source, plate, layers)
    body_rows = {y: (x0, x1) for y, x0, x1 in base['daily0AuthoredProposal']['torsoOnlyRunsYX0X1']}
    seen = set()
    for record in spec.get('armBoundaryOwnershipProposal', []):
        p = record.get('pixel')
        require(isinstance(p, list) and len(p) == 2 and all(type(v) is int for v in p)
                and 0 <= p[0] < 128 and 43 <= p[1] < 76, 'Boundary ownership outside source upper scope')
        q = tuple(p)
        require(record.get('side') == 'right' and record.get('part') == 'fore'
                and 'AUTHORED' in record.get('status', '') and q not in seen,
                'Boundary ownership must remain explicit and unique')
        require(not (q[1] in body_rows and body_rows[q[1]][0] <= q[0] < body_rows[q[1]][1]),
                'Do not take original cloth from inside intended shirt contour')
        rgba = source.getpixel(q)
        require(list(rgba) == record.get('rgba') and rgba[3] == 255
                and plate.getpixel(q) == rgba and not any(im.getpixel(q)[3] for im in layers.values()),
                'Boundary must be unchanged original plate pixel, not already arm-owned')
        layers['right/fore'].putpixel(q, rgba)
        body.putpixel(q, (0, 0, 0, 0))
        plate.putpixel(q, (0, 0, 0, 0))
        seen.add(q)
    reconstructed = body.copy()
    for layer in layers.values():
        reconstructed.alpha_composite(layer)
    require(reconstructed.tobytes() == source.tobytes(), 'Loop boundary ownership must preserve original rest exactly')
    return base, source, body, layers, repair_records


def render(spec, frame):
    base, source, body, layers, repair_records = prepare(spec)
    pose = pose_at(spec, frame)
    base['daily0AuthoredProposal']['newPoseProposal']['poses'] = [pose]
    _, raw, transforms = ownership.authored_extremes(base, body, layers)[0]
    arms = {}
    raw_components = {}
    for side in ('left', 'right'):
        arm = Image.new('RGBA', source.size)
        for part in ('upper', 'fore', 'palm'):
            arm.alpha_composite(ownership.moved_cutout(layers[side + '/' + part], transforms[side][part]))
        raw_components[side] = components(arm)
        arms[side] = arm
    final = Image.new('RGBA', source.size)
    for side in spec['behindTorso']:
        final.alpha_composite(arms[side])
    final.alpha_composite(body)
    for side in ('left', 'right'):
        if side not in spec['behindTorso']:
            final.alpha_composite(arms[side])
    joints = {}
    for side in ('left', 'right'):
        authored = base['daily0AuthoredProposal']['joints'][side]
        original_marker = next(e for e in json.loads(ownership.anchors.SPEC.read_text())['entries']
                               if (e['outfit'], e['frame'], e['side']) == ('daily', 0, side))['palm']
        joints[side] = {'status': spec['jointsStatus'], 'shoulder': point(transforms[side]['upper'], authored['shoulder']),
                        'elbowFromUpper': point(transforms[side]['upper'], authored['elbow']),
                        'elbowFromFore': point(transforms[side]['fore'], authored['elbow']),
                        'wristDesignAnchor': point(transforms[side]['fore'], authored['wrist']), 'grip': None,
                        'sourcePalmMarker': original_marker,
                        'palmMarkerProjection': point(transforms[side]['fore'], original_marker['pixel']),
                        'palmProjectionStatus': 'Original representative skin texel under authored transform; not joint/grip or guaranteed composite visibility'}
    metadata = {'frame': frame % 8, 'authoredPhase': (frame % 8) / 8, 'pose': pose, 'transforms': transforms,
                'joints': joints, 'rawArmComponents': raw_components,
                'finalArmComponents': {side: components(im) for side, im in arms.items()},
                'authoredOutputPixels': [], 'hiddenBodyRepairTexels': len(repair_records),
                'rgbaSha256': digest(final.tobytes()), 'rawRgbaSha256': digest(raw.tobytes())}
    return final, raw, body, arms, metadata


def sheet(images, labels, columns, crop, scale):
    width, height = (crop[2] - crop[0]) * scale, (crop[3] - crop[1]) * scale
    cell_w, cell_h = width + 32, height + 48
    result = Image.new('RGB', (columns * cell_w, math.ceil(len(images) / columns) * cell_h), (20, 38, 43))
    draw = ImageDraw.Draw(result)
    for index, (image, label) in enumerate(zip(images, labels)):
        x, y = index % columns * cell_w + 16, index // columns * cell_h + 32
        draw.text((x, y - 24), label, fill='white')
        scaled = image.crop(crop).resize((width, height), Image.Resampling.NEAREST)
        result.paste(scaled, (x, y), scaled)
    return result


def export(spec, output):
    output = output.resolve()
    require(output.is_relative_to(ROOT / 'artifacts') and not output.exists(), 'Fresh ignored artifacts directory required')
    frames = [render(spec, f) for f in range(8)]
    output.mkdir(parents=True)
    labels = [f'AUTHORED SOUTH daily {f}; phase {f}/8' for f in range(8)]
    images = [r[0] for r in frames]
    images[0].save(output / 'south-daily-upper-loop-preview.png', save_all=True,
                   append_images=images[1:], duration=spec['previewFrameMs'], loop=0, disposal=0, blend=0)
    for f, (image, raw, body, arms, metadata) in enumerate(frames):
        image.save(output / f'frame-{f}.png')
    sheet(images, labels, 8, (40, 0, 92, 76), 3).save(output / 'south-daily-upper-eight-strip.png')
    sheet(images, labels, 4, (40, 42, 92, 76), 8).save(output / 'south-daily-upper-eight-detail.png')
    joint_images = []
    for final, raw, body, arms, metadata in frames:
        overlay = final.copy()
        draw = ImageDraw.Draw(overlay)
        for side, color in (('left', (246, 196, 74)), ('right', (66, 218, 213))):
            joints = metadata['joints'][side]
            points = [tuple(joints[k]) for k in ('shoulder', 'elbowFromUpper', 'wristDesignAnchor')]
            draw.line(points, fill=color, width=1)
            for x, y in points:
                draw.ellipse((x-1, y-1, x+1, y+1), outline=color)
        joint_images.append(overlay)
    sheet(joint_images, [f'{f}: AUTHORED joints; no grip/contact' for f in range(8)], 4,
          (40, 42, 92, 76), 8).save(output / 'south-daily-upper-authored-joints.png')
    sheet([images[f] for f in (6, 7, 0, 1)], [f'WRAP REVIEW frame {f}' for f in (6, 7, 0, 1)], 4, (40, 42, 92, 76), 8).save(output / 'south-daily-upper-wrap-7-0.png')
    extremes, names = [], []
    for f in (0, 4):
        final, raw, body, arms, metadata = frames[f]
        extremes.extend([body, arms['left'], arms['right'], final])
        names.extend([f'frame{f} fixed body', f'frame{f} anatomical LEFT', f'frame{f} anatomical RIGHT', f'frame{f} composite'])
    sheet(extremes, names, 4, (40, 42, 92, 76), 8).save(output / 'south-daily-upper-extremes-and-separate-arms.png')
    base = json.loads(ownership.SPEC.read_text())
    source = ownership.source_cell('daily', 0)
    manifest = {'status': spec['status'], 'phaseStatus': spec['phaseStatus'], 'sourceAtlas': ownership.anchors.SOURCES['daily'],
                'sourceUpperRgbaSha256': digest(source.tobytes()), 'ownershipSpecSha256': spec['ownershipSpecSha256'],
                'loopSpecSha256': digest(SPEC.read_bytes()), 'loopToolSha256': digest(Path(__file__).read_bytes()),
                'ownershipToolSha256': digest(Path(ownership.__file__).read_bytes()),
                'originalTorsoReservedTexels': base['cases'][0]['plateOwnedPixels'],
                'authoredOriginalBoundaryOwnership': spec.get('armBoundaryOwnershipProposal', []),
                'frames': [r[4] for r in frames]}
    (output / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    print('SOUTH UPPER LOOP AUTHORING EXPORTED: 8 frames; no runtime/contact/anatomy acceptance')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    export(json.loads(SPEC.read_text()), args.output)
