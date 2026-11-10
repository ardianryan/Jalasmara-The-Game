#!/usr/bin/env python3
"""Render an original, review-only SOUTH explorer upper loop from pinned cutouts."""
import argparse
import copy
import hashlib
import importlib.util
import json
import math
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[3]
SPEC = Path(__file__).with_suffix('.json')
UPPER_SPEC = ROOT / 'tools' / 'player-gait' / 'south-explorer-upper.json'

loader = importlib.util.spec_from_file_location('south_explorer', ROOT / 'tools' / 'player-gait' / 'south-explorer-upper.py')
explorer = importlib.util.module_from_spec(loader)
loader.loader.exec_module(explorer)
require = explorer.require
ownership = explorer.ownership


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def validate(spec: dict) -> None:
    require(spec.get('schemaVersion') == 1 and spec.get('identity') == 'male_nusantara'
            and spec.get('outfit') == 'explorer' and spec.get('view') == 'south'
            and type(spec.get('sourceFrame')) is int and spec['sourceFrame'] == 0
            and type(spec.get('frameCount')) is int and spec['frameCount'] == 8,
            'Only eight SOUTH explorer0-derived upper frames are authored')
    require(spec.get('explorerUpperSpecSha256') == digest(UPPER_SPEC.read_bytes()),
            'Reviewed explorer upper spec changed')
    require(spec.get('behindTorso') == ['left'], 'Depth ordering requires separate authored review')
    require('AUTHORED' in spec.get('jointsStatus', '') and 'AUTHORED' in spec.get('phaseStatus', ''),
            'Do not promote authored joints or phase to source proof')
    for side in ('left', 'right'):
        motion = spec['motion'][side]
        require(set(motion) == {'upperSinDeg', 'foreMeanDeg', 'foreCosDeg'}
                and all(type(v) in (int, float) and math.isfinite(v) for v in motion.values())
                and abs(motion['upperSinDeg']) <= 3
                and -80 <= motion['foreMeanDeg'] - abs(motion['foreCosDeg'])
                and motion['foreMeanDeg'] + abs(motion['foreCosDeg']) <= 0,
                'Motion exceeds reviewed rigid-cutout authoring envelope')
    require(spec.get('authoredOutputPixels') == [], 'New output pixels require a separate authoring proposal')
    gear = spec.get('gearContract', {})
    require(gear.get('newNodes') == 0 and gear.get('newSatchelPixels') == 0
            and gear.get('atlasVestMeshEnabled') is False
            and gear.get('tankNetEnabled') is False,
            'Do not introduce duplicate garment/gear in loop proposal')


def pose_at(spec: dict, frame: int) -> dict:
    require(type(frame) is int, 'Frame must be an integer')
    phase = (frame % spec['frameCount']) / spec['frameCount']
    angle = math.tau * phase
    pose = {'name': f'authored-{frame % 8}', 'behindTorso': list(spec['behindTorso'])}
    for side in ('left', 'right'):
        motion = spec['motion'][side]
        pose[side] = {
            'upperDeg': round(motion['upperSinDeg'] * math.sin(angle), 8),
            'foreRelativeDeg': round(motion['foreMeanDeg'] + motion['foreCosDeg'] * math.cos(angle), 8)
        }
    return pose


def point(matrix, p):
    a, b, c, d, e, f = matrix
    return [a * p[0] + b * p[1] + c, d * p[0] + e * p[1] + f]


def components(image: Image.Image):
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


def prepare_loop(spec: dict):
    validate(spec)
    upper_base = json.loads(UPPER_SPEC.read_text())
    source, plate, arms, garments, body, repairs, _ = explorer.prepare(upper_base)
    return source, plate, arms, garments, body, repairs, upper_base['joints']


def render(spec: dict, frame: int):
    source, plate, layers, garments, body, repairs, joints = prepare_loop(spec)
    pose = pose_at(spec, frame)
    transforms = {}
    arms = {}
    raw_components = {}
    for side in ('left', 'right'):
        joint = joints[side]
        motion = pose[side]
        upper_matrix = ownership.joint_rotation(joint['shoulder'], motion['upperDeg'])
        fore_matrix = ownership.chain_transform(upper_matrix, ownership.joint_rotation(joint['elbow'], motion['foreRelativeDeg']))
        transforms[side] = {'upper': upper_matrix, 'fore': fore_matrix, 'palm': fore_matrix}
        arm = Image.new('RGBA', source.size)
        for part in ('upper', 'fore', 'palm'):
            transformed = ownership.moved_cutout(layers[f'{side}/{part}'], transforms[side][part])
            arm.alpha_composite(transformed)
        raw_components[side] = components(arm)
        arms[side] = arm

    final = Image.new('RGBA', source.size)
    for side in pose['behindTorso']:
        final.alpha_composite(arms[side])
    final.alpha_composite(body)
    for side in ('left', 'right'):
        if side not in pose['behindTorso']:
            final.alpha_composite(arms[side])

    raw = Image.new('RGBA', source.size)
    for side in ('left', 'right'):
        raw.alpha_composite(arms[side])
    raw.alpha_composite(body)

    joint_points = {}
    for side in ('left', 'right'):
        joint = joints[side]
        shoulder_proj = point(transforms[side]['upper'], joint['shoulder'])
        elbow_proj = point(transforms[side]['upper'], joint['elbow'])
        wrist_proj = point(transforms[side]['fore'], joint['wrist'])
        joint_points[side] = {
            'shoulder': shoulder_proj,
            'elbow': elbow_proj,
            'wristDesignAnchor': wrist_proj
        }

    metadata = {
        'frame': frame % 8,
        'authoredPhase': (frame % 8) / 8.0,
        'pose': pose,
        'transforms': transforms,
        'joints': joint_points,
        'rawArmComponents': raw_components,
        'finalArmComponents': {side: components(im) for side, im in arms.items()},
        'authoredOutputPixels': [],
        'hiddenBodyRepairTexels': len(repairs),
        'rgbaSha256': digest(final.tobytes()),
        'rawRgbaSha256': digest(raw.tobytes())
    }
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


def export(spec: dict, output: Path) -> None:
    output = output.resolve()
    require(output.is_relative_to(ROOT / 'artifacts') and not output.exists(),
            'Fresh ignored artifacts directory required')
    frames = [render(spec, f) for f in range(8)]
    output.mkdir(parents=True)
    labels = [f'AUTHORED SOUTH explorer {f}; phase {f}/8' for f in range(8)]
    images = [r[0] for r in frames]
    images[0].save(output / 'south-explorer-upper-loop-preview.png', save_all=True,
                   append_images=images[1:], duration=spec['previewFrameMs'], loop=0, disposal=0, blend=0)
    for f, (image, raw, body, arms, metadata) in enumerate(frames):
        image.save(output / f'frame-{f}.png')
    sheet(images, labels, 8, (40, 0, 92, 76), 3).save(output / 'south-explorer-upper-eight-strip.png')
    sheet(images, labels, 4, (40, 42, 92, 76), 8).save(output / 'south-explorer-upper-eight-detail.png')
    joint_images = []
    for final, raw, body, arms, metadata in frames:
        overlay = final.copy()
        draw = ImageDraw.Draw(overlay)
        for side, color in (('left', (246, 196, 74)), ('right', (66, 218, 213))):
            jts = metadata['joints'][side]
            points = [tuple(jts[k]) for k in ('shoulder', 'elbow', 'wristDesignAnchor')]
            draw.line(points, fill=color, width=1)
            for x, y in points:
                draw.ellipse((x-1, y-1, x+1, y+1), outline=color)
        joint_images.append(overlay)
    sheet(joint_images, [f'{f}: AUTHORED joints; no grip/contact' for f in range(8)], 4,
          (40, 42, 92, 76), 8).save(output / 'south-explorer-upper-authored-joints.png')
    sheet([images[f] for f in (6, 7, 0, 1)], [f'WRAP REVIEW frame {f}' for f in (6, 7, 0, 1)], 4,
          (40, 42, 92, 76), 8).save(output / 'south-explorer-upper-wrap-7-0.png')
    extremes, names = [], []
    for f in (0, 4):
        final, raw, body, arms, metadata = frames[f]
        extremes.extend([body, arms['left'], arms['right'], final])
        names.extend([f'frame{f} fixed body', f'frame{f} anatomical LEFT', f'frame{f} anatomical RIGHT', f'frame{f} composite'])
    sheet(extremes, names, 4, (40, 42, 92, 76), 8).save(output / 'south-explorer-upper-extremes-and-separate-arms.png')
    upper_base = json.loads(UPPER_SPEC.read_text())
    source = ownership.source_cell('explorer', 0)
    manifest = {
        'status': spec['status'],
        'phaseStatus': spec['phaseStatus'],
        'sourceAtlas': ownership.anchors.SOURCES['explorer'],
        'sourceUpperRgbaSha256': digest(source.tobytes()),
        'explorerUpperSpecSha256': spec['explorerUpperSpecSha256'],
        'loopSpecSha256': digest(SPEC.read_bytes()),
        'loopToolSha256': digest(Path(__file__).read_bytes()),
        'authoredHiddenGarmentTexels': 41,
        'gearContract': spec['gearContract'],
        'frames': [r[4] for r in frames]
    }
    (output / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    print('SOUTH EXPLORER UPPER LOOP AUTHORING EXPORTED: 8 frames; no runtime/contact/anatomy acceptance')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    export(json.loads(SPEC.read_text()), args.output)
