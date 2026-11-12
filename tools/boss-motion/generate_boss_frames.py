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
SIZE = (192, 128)
# Parts overlap at natural armor/fin joints. The core is expanded two pixels
# underneath them so a moving joint cannot expose a hole in the silhouette.
PARTS = [
    ('upper_fin', [(70,19),(88,14),(119,19),(139,38),(135,61),(90,59),(70,51)], (78,47), 3.0),
    ('rear_fin', [(116,75),(139,68),(148,94),(146,120),(119,117),(108,94)], (119,83), 2.5),
    ('tail', [(139,38),(192,20),(192,121),(152,116),(133,87)], (140,73), 3.0),
    ('front_fin', [(40,76),(91,77),(111,128),(33,128)], (63,88), 2.7),
    ('head', [(0,0),(77,0),(84,31),(82,72),(70,101),(37,113),(0,118)], (76,62), 1.3),
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
    original = Image.open(SOURCE).convert('RGBA').resize(SIZE, Image.Resampling.NEAREST)
    masks = Image.new('L', SIZE)
    parts = []
    for name, poly, pivot, amount in PARTS:
        part, mask = layer(original, poly)
        parts.append((name, part, pivot, amount))
        masks = Image.frombytes('L', SIZE, bytes(max(x, y) for x, y in zip(masks.tobytes(), mask.tobytes())))
    body = original.copy()
    body.putalpha(Image.frombytes('L', SIZE, bytes(0 if m else a for a, m in zip(original.getchannel('A').tobytes(), masks.tobytes()))))
    # Retain an underlap only at the seams, where a rotating appendage opens 1–2px.
    seam = masks.filter(ImageFilter.MaxFilter(5))
    underlay = original.copy()
    underlay.putalpha(Image.frombytes('L', SIZE, bytes(a if s and not m else 0 for a, s, m in zip(original.getchannel('A').tobytes(), seam.tobytes(), masks.tobytes()))))
    strip = Image.new('RGBA', (SIZE[0] * 8, SIZE[1]))
    for frame in range(8):
        phase = frame * math.tau / 8
        if frame == 0:
            canvas = original.copy()
        else:
            canvas = Image.new('RGBA', SIZE)
            canvas.alpha_composite(underlay)
            canvas.alpha_composite(body)
            for name, part, pivot, amount in parts:
                offset = 1.3 if name == 'tail' else 2.1 if name == 'front_fin' else 0.0
                angle = math.sin(phase + offset) * amount
                canvas.alpha_composite(rotated(part, pivot, angle))
        strip.alpha_composite(canvas, (frame * SIZE[0], 0))
    strip.save(OUT / 'swim.png', optimize=True)
    (OUT / 'manifest.json').write_text(json.dumps({
        'source': str(SOURCE.relative_to(ROOT)),
        'sourceSha256': hashlib.sha256(SOURCE.read_bytes()).hexdigest(),
        'method': 'original transparent art, region cutouts, nearest-neighbor 192x128 frame atlas',
        'cellSize': list(SIZE), 'frames': 8, 'parts': [x[0] for x in PARTS],
    }, indent=2) + '\n')


if __name__ == '__main__':
    generate()
