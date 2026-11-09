#!/usr/bin/env python3
"""Pack the reviewed Ujang rear/grip artwork without changing other NPC atlases."""
import hashlib
import json
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / 'assets/source-2d/ujang-rear-grip-v1'
OUT = ROOT / 'client-godot/resources/art/npc-rigs'


def pack():
    raw = Image.open(SOURCE / 'generated.png').convert('RGBA')
    raw.putalpha(raw.getchannel('A').point(lambda a: 255 if a >= 128 else 0))
    atlas = Image.open(OUT / 'ujang.png').convert('RGBA')
    data = json.loads((OUT / 'ujang.json').read_text())
    palette = list({rgb[:3] for rgb in atlas.getdata() if rgb[3] >= 128})
    specs = [
        ('head_back', (180, 100, 600, 550), (29, 27), 14, [0, -81.5]),
        ('torso_back', None, (27, 34), 15, [0, -52.5]),
        ('hand_rod_west', (1710, 280, 1930, 470), (7, 7), 16, None),
        ('head_west', 'west', (29, 27), 17, [-1, -81.5]),
    ]
    for name, box, size, cell, center in specs:
        if box is None or box == 'west':
            part = Image.open(SOURCE / ('generated-west-head-v1.png' if box == 'west' else 'generated-torso-v2.png')).convert('RGBA')
            part.putalpha(part.getchannel('A').point(lambda a: 255 if a >= 128 else 0))
        else:
            part = raw.crop(box)
        part = part.crop(part.getbbox()).resize(size, Image.Resampling.NEAREST)
        # Quantize to Ujang's original portrait colours, including its dark outline.
        for y in range(part.height):
            for x in range(part.width):
                pixel = part.getpixel((x, y))
                if pixel[3]:
                    color = min(palette, key=lambda c: sum((a-b)**2 for a, b in zip(c, pixel)))
                    part.putpixel((x, y), (*color, 255))
        part.save(SOURCE / (name + '.png'))
        origin = [(64-size[0])//2, (64-size[1])//2]
        x, y = (cell % 5)*64, (cell // 5)*64
        atlas.paste((0, 0, 0, 0), (x, y, x+64, y+64))
        atlas.alpha_composite(part, (x+origin[0], y+origin[1]))
        entry = {'cell': cell, 'size': list(size), 'origin': origin}
        if center is not None:
            entry['center'] = center
        if name == 'hand_rod_west':
            entry.update({'wristPixel': [3.5, 6.0], 'gripPixel': [3.5, 3.5],
                          'rodAxis': [[1.0, 6.0], [6.0, 1.0]], 'facing': 'west'})
        data['parts'][name] = entry
    data['atlas'] = 'res://resources/art/npc-rigs/ujang-rear-grip-v1.png'
    data['method'] = 'Original portrait cutouts with original authored rear head/vest, west head and fishing fist override'
    data['rearGripSource'] = {
        'path': 'assets/source-2d/ujang-rear-grip-v1/generated.png',
        'sha256': hashlib.sha256((SOURCE / 'generated.png').read_bytes()).hexdigest(),
        'torsoRevisionSha256': hashlib.sha256((SOURCE / 'generated-torso-v2.png').read_bytes()).hexdigest(),
        'westHeadSha256': hashlib.sha256((SOURCE / 'generated-west-head-v1.png').read_bytes()).hexdigest(),
        'method': 'Built-in imagegen identity edit; inspected parts, nearest resize and original Ujang palette quantization',
        'directions': 'Rear head/torso, west head and west fishing fist only; other directional body art remains unmirrored original cutout pilot',
    }
    atlas.save(OUT / 'ujang-rear-grip-v1.png')
    (OUT / 'ujang.json').write_text(json.dumps(data, indent=2) + '\n')


if __name__ == '__main__':
    pack()
