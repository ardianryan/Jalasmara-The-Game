#!/usr/bin/env python3
"""Offline authored NW explorer eight-pose proposal; no locomotion/contact coupling."""
import argparse
import hashlib
import importlib.util
import json
import math
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
SPEC = Path(__file__).with_suffix('.json')
loader = importlib.util.spec_from_file_location('nw_loop_rig', Path(__file__).with_name('nw-explorer-upper-rig.py'))
rig = importlib.util.module_from_spec(loader)
loader.loader.exec_module(rig)
require = rig.require


def digest(data):
    return hashlib.sha256(data).hexdigest()


def validate(spec):
    require(spec.get('schemaVersion') == 1 and spec.get('identity') == 'male_nusantara'
            and spec.get('outfit') == 'explorer' and spec.get('view') == 'north_west'
            and spec.get('frameCount') == 8 and type(spec['frameCount']) is int,
            'Only eight authored NW explorer upper poses are supported')
    require(spec.get('rigSpecSha256') == digest(rig.SPEC.read_bytes()), 'Reviewed NW rig changed')
    require(spec.get('motion') == {'left': {'foreMeanDeg': 16, 'foreCosDeg': 16},
                                 'right': {'foreMeanDeg': -12, 'foreCosDeg': 12}},
            'Motion exceeds the separately reviewed fixed-shoulder endpoint envelope')
    require(spec.get('behindTorso') == ['right'] and spec.get('upperDeg') == 0,
            'Depth or shoulder changes need separate authoring review')
    require(spec.get('contactPhase') is None and spec.get('sourceMeasurement') == {
                'anatomicalSide': 'unknown', 'wrist': None, 'grip': None}
            and 'AUTHORED' in spec.get('phaseStatus', ''), 'Do not invent contact, source joints or grip')
    require(type(spec.get('previewFrameMs')) is int and 60 <= spec['previewFrameMs'] <= 200,
            'Preview cadence must remain explicitly non-runtime')
    require(spec.get('newOutputPixels') == [] and spec.get('newGearPixels') == 0,
            'Loop must preserve the reviewed repair and gear scope')


def pose_at(spec, frame):
    validate(spec)
    require(type(frame) is int, 'Frame must be an integer')
    angle = math.tau * ((frame % 8) / 8)
    pose = {'name': 'authored-loop-' + str(frame % 8), 'behindTorso': list(spec['behindTorso'])}
    for side in ('left', 'right'):
        motion = spec['motion'][side]
        pose[side] = {'upperDeg': 0, 'foreRelativeDeg': round(
            motion['foreMeanDeg'] + motion['foreCosDeg'] * math.cos(angle), 8)}
    return pose


def point(matrix, p):
    a, b, c, d, e, f = matrix
    return [a*p[0]+b*p[1]+c, d*p[0]+e*p[1]+f]


def render(spec, frame):
    validate(spec)
    base = json.loads(rig.SPEC.read_text())
    base['poses'][1] = pose_at(spec, frame)
    source, plate, arms, garments, body, repairs, poses = rig.prepare(base)
    posed = poses[1]
    joints = {}
    for side in ('left', 'right'):
        authored = base['joints'][side]
        mats = posed['matrices'][side]
        joints[side] = {'status': base['jointsStatus'], 'shoulder': point(mats['upper'], authored['shoulder']),
                        'elbowFromUpper': point(mats['upper'], authored['elbow']),
                        'elbowFromFore': point(mats['fore'], authored['elbow']),
                        'wristDesignAnchor': point(mats['fore'], authored['wrist']), 'grip': None}
    metadata = {'frame': frame % 8, 'authoredPhase': (frame % 8)/8, 'pose': posed['name'],
                'angles': base['poses'][1], 'matrices': posed['matrices'], 'joints': joints,
                'rawArmComponents': {side: [len(c) for c in rig.components(im)] for side, im in posed['arms'].items()},
                'rgbaSha256': digest(posed['image'].tobytes())}
    return source, body, posed['image'], posed['arms'], metadata


def sheet(images, labels, columns, crop=(44, 42, 84, 76), scale=8):
    width, height = (crop[2]-crop[0])*scale, (crop[3]-crop[1])*scale
    cell_w, cell_h = width+32, height+48
    result = Image.new('RGB', (columns*cell_w, math.ceil(len(images)/columns)*cell_h), (20, 38, 43))
    draw = ImageDraw.Draw(result)
    for i, (im, label) in enumerate(zip(images, labels)):
        x, y = (i % columns)*cell_w+16, (i//columns)*cell_h+32
        draw.text((x, y-24), label, fill='white')
        scaled = im.crop(crop).resize((width, height), Image.Resampling.NEAREST)
        result.paste(scaled, (x, y), scaled)
    return result


def changed_pixels(a, b):
    return sum(p != q for p, q in zip(a.getdata(), b.getdata()))


def export(spec, output):
    validate(spec)
    output = output.resolve()
    require(output.is_relative_to(ROOT/'artifacts') and not output.exists(), 'Fresh ignored artifact output required')
    frames = [render(spec, f) for f in range(8)]
    images = [f[2] for f in frames]
    output.mkdir(parents=True)
    images[0].save(output/'nw-explorer-upper-loop-preview.png', save_all=True, append_images=images[1:],
                   duration=spec['previewFrameMs'], loop=0, disposal=0, blend=0)
    for f, im in enumerate(images):
        im.save(output/f'frame-{f}.png')
    labels = [f'AUTHORED NW explorer {f}/8' for f in range(8)]
    sheet(images, labels, 8, (42, 0, 86, 76), 3).save(output/'nw-explorer-upper-eight-strip.png')
    sheet(images, labels, 4).save(output/'nw-explorer-upper-eight-detail.png')
    sheet([images[f] for f in (6, 7, 0, 1)], [f'WRAP frame {f}' for f in (6, 7, 0, 1)], 4).save(output/'nw-explorer-upper-wrap-7-0.png')
    joint_images = []
    for source, body, image, arms, metadata in frames:
        overlay = image.copy()
        draw = ImageDraw.Draw(overlay)
        for side, color in [('left', (246, 196, 74)), ('right', (149, 115, 229))]:
            joints = metadata['joints'][side]
            pts = [tuple(joints[k]) for k in ('shoulder', 'elbowFromUpper', 'wristDesignAnchor')]
            draw.line(pts, fill=color, width=1)
            for x, y in pts:
                draw.ellipse((x-1, y-1, x+1, y+1), outline=color)
        joint_images.append(overlay)
    sheet(joint_images, [f'{f}: AUTHORED anchors; no contact/grip' for f in range(8)], 4).save(output/'nw-explorer-upper-authored-anchors.png')
    extremes, names = [], []
    for f in (0, 4):
        source, body, image, arms, metadata = frames[f]
        extremes.extend([body, arms['left'], arms['right'], image])
        names.extend([f'{f}: fixed body', f'{f}: authored LEFT/A', f'{f}: authored RIGHT/B', f'{f}: composite'])
    sheet(extremes, names, 4).save(output/'nw-explorer-upper-extremes.png')
    base = json.loads(rig.SPEC.read_text())
    source, plate, arms, garments, body, repairs, neutral_poses = rig.prepare(base)
    adjacent = [changed_pixels(images[f], images[(f+1)%8]) for f in range(8)]
    manifest = {'status': spec['status'], 'phaseStatus': spec['phaseStatus'],
                'sourceArrangementRgbaSha256': digest(source.tobytes()),
                'originalAtlasSources': json.loads(rig.orientation.audit.SPEC.read_text())['sources'],
                'rigSpecSha256': spec['rigSpecSha256'], 'rigToolSha256': digest(Path(rig.__file__).read_bytes()),
                'loopSpecSha256': digest(SPEC.read_bytes()), 'loopToolSha256': digest(Path(__file__).read_bytes()),
                'sourceMeasurement': base['sourceMeasurement'], 'authoredConvention': base['authoredConvention'],
                'jointsStatus': base['jointsStatus'], 'joints': base['joints'],
                'originalSourceArms': {k: rig.ops.row_runs(im) for k, im in arms.items()},
                'originalSourceGarments': {k: rig.ops.row_runs(im) for k, im in garments.items()},
                'sourceBoundaryAssignments': base['sourceBoundaryAssignments'], 'authoredHiddenFill': repairs,
                'authoredJointOverlap': base['authoredJointOverlap'],
                'neutralReferenceExact': neutral_poses[0]['image'].tobytes() == source.tobytes(),
                'gearContract': base['gearContract'], 'frames': [f[4] for f in frames],
                'adjacentChangedPixelsIncludingWrap': adjacent,
                'previewFrameMs': spec['previewFrameMs'], 'previewCadenceStatus': 'Authoring preview only, not locomotion cadence',
                'runtimeIntegration': False}
    (output/'manifest.json').write_text(json.dumps(manifest, indent=2)+'\n')
    print('NW EXPLORER AUTHORED LOOP EXPORTED: eight poses; no runtime/contact/anatomy acceptance')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    export(json.loads(SPEC.read_text()), args.output)
