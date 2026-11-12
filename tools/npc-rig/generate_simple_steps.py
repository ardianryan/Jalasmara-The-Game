#!/usr/bin/env python3
"""Reproducible short-step atlases derived from Jalasmara's original NPC portraits."""
import hashlib
import json
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
ART = ROOT / 'client-godot/resources/art'
OUT = ART / 'npc-simple-steps-v1'
CELL = 64
# Coordinates are per source cell, normalized to 512. Moving pieces stay under
# the original robe/trouser outline so the head and held props remain stable.
SPECS = {
    'Ki Lurah Wirabhumi': ('village-residents-v1.png', (3, 2), 0, [[(181, 438), (256, 438), (256, 502), (174, 502)], [(268, 440), (363, 440), (365, 502), (263, 502)]]),
    'Mbok Ratih': ('village-residents-v1.png', (3, 2), 1, [[(155, 443), (236, 443), (236, 504), (153, 504)], [(247, 440), (340, 440), (343, 504), (244, 504)]]),
    'Kang Tedi': ('village-residents-v1.png', (3, 2), 3, [[(177, 369), (256, 369), (257, 506), (167, 506)], [(258, 370), (376, 370), (379, 506), (252, 506)]]),
    'Saras': ('village-residents-v1.png', (3, 2), 5, [[(171, 376), (257, 376), (257, 506), (166, 506)], [(258, 376), (374, 376), (376, 506), (253, 506)]]),
    'Mbah Wira': ('npc-atlas.png', (2, 2), 0, [[(167, 411), (258, 411), (258, 505), (162, 505)], [(259, 411), (380, 411), (384, 505), (257, 505)]]),
    'Beno': ('npc-atlas.png', (2, 2), 1, [[(157, 397), (263, 397), (263, 505), (153, 505)], [(264, 397), (389, 397), (393, 505), (261, 505)]]),
    'Inspektur Raka': ('npc-atlas.png', (2, 2), 3, [[(184, 393), (264, 393), (265, 505), (181, 505)], [(265, 393), (382, 393), (384, 505), (262, 505)]]),
}
# Frame zero is exact original pixel art. Four walking phases keep at least one
# foot at the authored ground row, with a one-pixel passing lift.
OFFSETS = [((0, 0), (0, 0)), ((-2, 0), (2, -1)), ((0, -2), (0, 0)), ((2, -1), (-2, 0)), ((0, 0), (0, -2))]
BODY_OFFSETS = [(0, 0), (1, 0), (0, -1), (-1, 0), (0, -1)]


def cell_image(source, grid, index):
    atlas = Image.open(ART / source).convert('RGBA')
    w, h = atlas.width // grid[0], atlas.height // grid[1]
    crop = atlas.crop(((index % grid[0]) * w, (index // grid[0]) * h, (index % grid[0] + 1) * w, (index // grid[0] + 1) * h))
    return crop.resize((CELL, CELL), Image.Resampling.NEAREST)


def generate():
    OUT.mkdir(parents=True, exist_ok=True)
    people = {}
    for name, (source, grid, index, polygons) in SPECS.items():
        original = cell_image(source, grid, index)
        parts = []
        for polygon in polygons:
            mask = Image.new('L', (512, 512))
            ImageDraw.Draw(mask).polygon(polygon, fill=255)
            mask = mask.resize((CELL, CELL), Image.Resampling.NEAREST)
            alpha = Image.new('L', original.size)
            alpha.paste(original.getchannel('A'), mask=mask)
            part = original.copy()
            part.putalpha(alpha)
            parts.append(part)
        base = original.copy()
        leg_union = Image.new('L', original.size)
        for part in parts:
            leg_union = Image.frombytes('L', original.size, bytes(max(a, b) for a, b in zip(leg_union.tobytes(), part.getchannel('A').tobytes())))
        base_alpha = original.getchannel('A')
        base.putalpha(Image.frombytes('L', original.size, bytes(0 if m >= 128 else a for a, m in zip(base_alpha.tobytes(), leg_union.tobytes()))))
        strip = Image.new('RGBA', (CELL * len(OFFSETS), CELL))
        strip.alpha_composite(original, (0, 0))
        for frame, (left, right) in enumerate(OFFSETS[1:], 1):
            tile = Image.new('RGBA', original.size)
            for part, offset in zip(parts, (left, right)):
                tile.alpha_composite(part, offset)
            tile.alpha_composite(base, BODY_OFFSETS[frame])
            strip.alpha_composite(tile, (frame * CELL, 0))
        slug = name.lower().replace(' ', '_')
        strip.save(OUT / f'{slug}.png', optimize=True)
        people[name] = {'file': f'{slug}.png', 'source': source, 'sourceCell': index, 'sourceSha256': hashlib.sha256((ART/source).read_bytes()).hexdigest(), 'frames': 5, 'cellSize': CELL}
    (OUT / 'manifest.json').write_text(json.dumps({'method': 'original portrait cutouts and four short alternating foot-contact poses', 'people': people}, indent=2) + '\n')


if __name__ == '__main__':
    generate()
