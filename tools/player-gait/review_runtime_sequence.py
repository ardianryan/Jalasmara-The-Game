"""Build review sheets from actual NALA_GAIT_CAPTURE frames; never changes game assets."""
import argparse
import hashlib
import json
import math
from pathlib import Path

from PIL import Image, ImageDraw


def choose(records, outfit, tag):
    seen = set()
    selected = []
    for item in records:
        if item['outfit'] != outfit or item['reduced'] or item['tag'] != tag:
            continue
        state = item['state']
        key = (state['artworkDirection'], state['frame'], state['poseWalking'])
        if key not in seen:
            selected.append(item)
            seen.add(key)
    return selected[:6]


def render(records, folder, target):
    columns = 6
    sheet = Image.new('RGB', (columns * 240, math.ceil(len(records) / columns) * 270), '#263b40')
    draw = ImageDraw.Draw(sheet)
    frames = []
    for offset, item in enumerate(records):
        path = folder / f'{item["index"]:04d}.png'
        with Image.open(path) as image:
            if image.size != (960, 540):
                raise ValueError(f'{path}: expected native fixture960x540; inspect framing before cropping')
            crop = image.convert('RGB').crop((200, 186, 440, 406))
        x, y = offset % columns * 240, offset // columns * 270
        sheet.paste(crop, (x, y + 50))
        state = item['state']
        draw.text((x + 8, y + 4), f'{item["outfit"]} #{item["index"]} {item["tag"]}', fill='white')
        draw.text((x + 8, y + 19), f'{state["artworkDirection"]} / {state["frame"]} / '
                  + ('walk' if state['poseWalking'] else 'neutral'), fill='#d0ad66')
        draw.text((x + 8, y + 34), f'accepted distance {state["distance"]:.2f}', fill='white')
        frames.append({'index': item['index'], 'tag': item['tag'], 'sha256': hashlib.sha256(path.read_bytes()).hexdigest()})
    sheet.save(target)
    return {'image': target.name, 'frames': frames}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('folder', type=Path, help='Native artifact folder containing results.json and numbered PNGs')
    args = parser.parse_args()
    path = args.folder / 'results.json'
    records = json.loads(path.read_text())
    if not records:
        raise ValueError('No recorded runtime frames; do not substitute source atlas poses')
    groups = ['stop-from-3', 'stop-from-7', 'reverse-180', 'turn-90',
              'stress-turn-0.033', 'stress-turn-0.100']
    selected = [item for outfit in ['daily', 'explorer'] for tag in groups
                for item in choose(records, outfit, tag)]
    outputs = [render(selected, args.folder, args.folder / 'transition-contact-sheet.png')]
    daily = [item for item in records if item['outfit'] == 'daily' and not item['reduced']]
    stops = [item for item in daily if item['tag'] == 'stop-from-3']
    if stops:
        last_stop = stops[-1]
        restart = [item for item in daily if item['index'] > last_stop['index']
                   and item['tag'] == 'walk-to-7'][:4]
        outputs.append(render([last_stop] + restart, args.folder, args.folder / 'restart-pop-contact-sheet.png'))
    pilot = []
    for outfit in ['daily', 'explorer']:
        for reduced in [False, True]:
            subset = [item for item in records if item['outfit'] == outfit and item['reduced'] == reduced]
            for tag in ['restart-low-0.017', 'restart-low-0.033']:
                run = [item for item in subset if item['tag'] == tag]
                if not run:
                    continue
                neutral = [item for item in subset if item['tag'] == 'restart-settled' and item['index'] < run[0]['index']][-1]
                pilot.extend([neutral] + run[:5] + ([run[-1]] if len(run) > 5 else []))
    if pilot:
        outputs.append(render(pilot, args.folder, args.folder / 'restart-pilot-contact-sheet.png'))
    manifest = {'runtimeFrames': len(records), 'resultsSha256': hashlib.sha256(path.read_bytes()).hexdigest(),
                'method': 'Crop actual native rendered pixels, add review captions; no generated/repainted pose',
                'outputs': outputs}
    (args.folder / 'contact-sheet-manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    print(f'Native review sheets: {len(records)} recorded frames; {len(selected)} selected transition poses')


if __name__ == '__main__':
    main()
