#!/usr/bin/env python3
"""Cut and re-pose original transparent Gajah Mina art on a native pixel grid."""
import hashlib
import json
import math
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / 'client-godot/resources/art/gajah-mina.png'
OUT = ROOT / 'client-godot/resources/art/gajah-mina-motion-v1'
ART_SIZE = (192, 128)
PADDING = 16
SIZE = (ART_SIZE[0] + PADDING * 2, ART_SIZE[1] + PADDING * 2)
FRAME_COUNT = 12
# The tail fan and fins pivot behind their armor joints; the fixed hinge pixels
# keep the original silhouette connected at the widest stroke.
PARTS = [
    ('upper_fin', [(70,19),(88,14),(119,19),(139,38),(135,61),(90,59),(70,51)], (78,47), 4.5),
    ('rear_fin', [(116,75),(139,68),(148,94),(146,120),(119,117),(108,94)], (119,83), 5.5),
    ('tail', [(153,29),(192,20),(192,121),(152,116),(159,87)], (153,72), 10.0),
    ('front_fin', [(40,76),(91,77),(111,128),(33,128)], (63,88), 5.5),
    ('head', [(0,0),(77,0),(84,31),(82,72),(70,101),(37,113),(0,118)], (76,62), 2.2),
]


def layer(source, polygon):
    mask = Image.new('L', SIZE)
    ImageDraw.Draw(mask).polygon(polygon, fill=255)
    result = source.copy()
    a = source.getchannel('A')
    result.putalpha(Image.frombytes('L', SIZE, bytes(min(x, y) for x, y in zip(a.tobytes(), mask.tobytes()))))
    return result, mask


def rotated(im, center, degrees):
    # Pillow's center keeps each transparent layer aligned with the original art.
    return im.rotate(degrees, Image.Resampling.NEAREST, expand=False, center=center)


def generate():
    OUT.mkdir(parents=True, exist_ok=True)
    art = Image.open(SOURCE).convert('RGBA').resize(ART_SIZE, Image.Resampling.NEAREST)
    original = Image.new('RGBA', SIZE)
    original.alpha_composite(art, (PADDING, PADDING))
    masks = Image.new('L', SIZE)
    parts = []
    for name, poly, pivot, amount in PARTS:
        padded_poly = [(x + PADDING, y + PADDING) for x, y in poly]
        padded_pivot = (pivot[0] + PADDING, pivot[1] + PADDING)
        part, mask = layer(original, padded_poly)
        parts.append((name, part, padded_pivot, amount))
        masks = Image.frombytes('L', SIZE, bytes(max(x, y) for x, y in zip(masks.tobytes(), mask.tobytes())))
    body = original.copy()
    body.putalpha(Image.frombytes('L', SIZE, bytes(0 if m else a for a, m in zip(original.getchannel('A').tobytes(), masks.tobytes()))))
    # Retain an underlap only at the seams, where a rotating appendage opens 1–2px.
    seam = masks.filter(ImageFilter.MaxFilter(9))
    underlay = original.copy()
    underlay.putalpha(Image.frombytes('L', SIZE, bytes(a if s and not m else 0 for a, s, m in zip(original.getchannel('A').tobytes(), seam.tobytes(), masks.tobytes()))))
    hinge = Image.new('RGBA', SIZE)
    for name, part, pivot, _ in parts:
        radius = 15 if name in {'tail', 'front_fin'} else 11
        hinge_mask = Image.new('L', SIZE)
        ImageDraw.Draw(hinge_mask).ellipse((pivot[0]-radius,pivot[1]-radius,pivot[0]+radius,pivot[1]+radius),fill=255)
        joint = part.copy()
        joint.putalpha(Image.frombytes('L',SIZE,bytes(min(a,m) for a,m in zip(part.getchannel('A').tobytes(),hinge_mask.tobytes()))))
        hinge.alpha_composite(joint)
    strip = Image.new('RGBA', (SIZE[0] * FRAME_COUNT, SIZE[1]))
    for frame in range(FRAME_COUNT):
        phase = frame * math.tau / FRAME_COUNT
        canvas = Image.new('RGBA', SIZE)
        canvas.alpha_composite(underlay)
        canvas.alpha_composite(body)
        canvas.alpha_composite(hinge)
        for name, part, pivot, amount in parts:
            offset = 0.0 if name == 'tail' else 1.3 if name == 'front_fin' else 2.1 if name == 'rear_fin' else 0.6 if name == 'upper_fin' else 0.2
            angle = math.sin(phase + offset) * amount
            canvas.alpha_composite(rotated(part, pivot, angle))
        strip.alpha_composite(canvas, (frame * SIZE[0], 0))
    strip.save(OUT / 'swim.png', optimize=True)
    (OUT / 'manifest.json').write_text(json.dumps({
        'source': str(SOURCE.relative_to(ROOT)),
        'sourceSha256': hashlib.sha256(SOURCE.read_bytes()).hexdigest(),
        'method': 'original transparent art, padded jointed cutouts, nearest-neighbor frame atlas',
        'artSize': list(ART_SIZE), 'cellSize': list(SIZE), 'frames': FRAME_COUNT, 'parts': [x[0] for x in PARTS],
    }, indent=2) + '\n')


if __name__ == '__main__':
    generate()
