#!/usr/bin/env python3
"""Label actual native lower-body captures without modifying source frames."""
import argparse
import hashlib
import json
from collections import defaultdict
from pathlib import Path
from PIL import Image, ImageDraw

parser = argparse.ArgumentParser()
parser.add_argument('directory', type=Path)
args = parser.parse_args()
folder = args.directory
results = folder / ('flat-results.json' if (folder / 'flat-results.json').exists() else 'results.json')
frames = json.loads(results.read_text())
groups = defaultdict(lambda: defaultdict(list))
records = []
for entry in frames:
    source = folder / f"{entry['frame']:04d}.png"
    image = Image.open(source).convert('RGB')
    assert image.size == (480, 270), ('Unexpected native viewport', source, image.size)
    case = entry['case'].split(' ', 1)[0].split('/')
    if len(case) != 3 or case[0] not in ('daily', 'explorer'):
        continue
    groups[(case[0], case[1])][int(case[2])].append(entry)
    records.append({'file': source.name, 'sha256': hashlib.sha256(source.read_bytes()).hexdigest(),
                    'case': entry['case'], 'direction': entry['pose']['direction']})
outputs = []
for (outfit, reduced), headings in groups.items():
    sheet = Image.new('RGB', (1200, 8 * 330 + 34), '#20212a')
    draw = ImageDraw.Draw(sheet)
    draw.text((12, 10), f'ACTUAL NATIVE CROPS | {outfit} reduced={reduced} | visual acceptance pending', fill='#f4e4c3')
    for heading in range(8):
        entries = headings[heading]
        assert entries, ('Missing actual movement heading', outfit, reduced, heading)
        selected = entries if len(entries) <= 4 else [entries[round(i * (len(entries) - 1) / 3)] for i in range(4)]
        for column, entry in enumerate(selected):
            image = Image.open(folder / f"{entry['frame']:04d}.png").convert('RGB')
            crop = image.crop((190, 48, 290, 148)).resize((300, 300), Image.Resampling.NEAREST)
            x, y = column * 300, heading * 330 + 34
            sheet.paste(crop, (x, y))
            pose = entry['pose']
            label = f"{entry['case']} | {pose['direction']}"
            draw.text((x + 4, y + 302), label, fill='#f4e4c3')
            draw.text((x + 4, y + 315), f"frame {entry['frame']} drop {pose['pelvisDropPixels']:.2f}px", fill='#b9dce1')
    target = folder / f'flat-{outfit}-reduced-{reduced}-review.png'
    sheet.save(target)
    outputs.append(target.name)
(folder / 'native-review.json').write_text(json.dumps({'scope': 'Actual captured frames only; no fabricated in-between poses.',
    'sourceManifest': 'source.json', 'frames': records, 'sheets': outputs,
    'acceptance': 'Pending human review; geometry passing does not establish natural gait.'}, indent=2) + '\n')
print(json.dumps({'capturedFrames': len(records), 'sheets': outputs}))
