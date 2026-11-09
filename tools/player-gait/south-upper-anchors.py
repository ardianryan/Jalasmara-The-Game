#!/usr/bin/env python3
"""Check original SOUTH palm texels and make an optional review-only contact sheet."""
import argparse
import hashlib
import json
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
SPEC = Path(__file__).with_suffix('.json')
SOURCES = {
    'daily': ('client-godot/resources/art/player-gait/male-nusantara-daily-walk-8way-v1.png', '342724d1724490279cd0f65c0340c5b35cdf366ecc36a99af716c51f751b8fc3'),
    'explorer': ('client-godot/resources/art/player-gait/male-nusantara-explorer-walk-8way-v1.png', 'a429c378400bd5ac60a45124ac48672b4cb1360beb379cc83297b52ea48ae3b9'),
}


def digest(data):
    return hashlib.sha256(data).hexdigest()


def require(condition, message):
    if not condition:
        raise ValueError(message)


def source_image(outfit):
    require(outfit in SOURCES, 'Unsupported outfit')
    relative, expected = SOURCES[outfit]
    path = ROOT / relative
    require(digest(path.read_bytes()) == expected, 'Original source hash changed')
    image = Image.open(path).convert('RGBA')
    require(image.size == (1024, 1024), 'Original atlas dimensions changed')
    return image


def visible_palm(entry, outfit, frame, side, image):
    require(outfit in SOURCES and type(frame) is int and frame in range(8) and side in ('left', 'right'), 'Unsupported source cell')
    require(entry.get('outfit') == outfit and entry.get('frame') == frame and entry.get('side') == side, 'Outfit, frame or anatomical side mismatch')
    require(entry.get('sourceSha256') == SOURCES[outfit][1], 'Outfit source pin mismatch')
    cell = image.crop((frame * 128, 256, (frame + 1) * 128, 332))
    require(digest(cell.tobytes()) == entry.get('upperFrameRgbaSha256'), 'Source frame pin mismatch')
    palm = entry.get('palm', {})
    require(palm.get('visibility') == 'visible', 'Palm is unknown or occluded')
    point = palm.get('pixel')
    require(isinstance(point, list) and len(point) == 2 and all(type(v) is int for v in point), 'Invalid cell coordinate')
    x, y = point
    require(0 <= x < 128 and 0 <= y < 76, 'Palm outside original upper cell')
    require(x > 64 if side == 'left' else x < 64, 'Point contradicts reviewed SOUTH anatomical convention')
    actual = list(image.getpixel((frame * 128 + x, 256 + y)))
    require(actual[3] == 255, 'Palm texel is transparent')
    require(actual == palm.get('rgba'), 'Palm RGBA differs from original')
    return point, actual


def validate(spec):
    require(spec.get('schemaVersion') == 1 and spec.get('identity') == 'male_nusantara' and spec.get('view') == 'south' and spec.get('row') == 2 and spec.get('cell') == [128, 128], 'Unsupported annotation scope')
    require(spec.get('sources') == {outfit: {'path': path, 'sha256': sha} for outfit, (path, sha) in SOURCES.items()}, 'Source metadata mismatch')
    entries = spec.get('entries', [])
    require(len(entries) == 32, 'Expected 32 palm entries')
    images = {outfit: source_image(outfit) for outfit in SOURCES}
    seen = set()
    for entry in entries:
        key = (entry.get('outfit'), entry.get('frame'), entry.get('side'))
        require(key not in seen, 'Duplicate palm entry')
        seen.add(key)
        outfit, frame, side = key
        visible_palm(entry, outfit, frame, side, images.get(outfit))
        require(entry.get('wrist', {}).get('status') == 'ambiguous' and entry['wrist'].get('pixel') is None, 'This dataset has no source-verified wrist')
        require(entry.get('grip') == {'status': 'unknown', 'origin': None, 'axis': None}, 'No grip may be inferred from a palm')
    require(seen == {(o, f, s) for o in SOURCES for f in range(8) for s in ('left', 'right')}, 'Incomplete source coverage')
    return images


def review_sheet(spec, images, output):
    output = output.resolve()
    require(output.is_relative_to(ROOT / 'artifacts'), 'Review output must stay in ignored artifacts')
    require(not output.exists(), 'Preserve prior review; choose a fresh output directory')
    output.mkdir(parents=True)
    colors = {'left': (246, 196, 74), 'right': (66, 218, 213)}
    records = {(e['outfit'], e['frame'], e['side']): e for e in spec['entries']}
    files = []
    for outfit, image in images.items():
        sheet = Image.new('RGB', (4 * 480, 2 * 350), (20, 38, 43))
        draw = ImageDraw.Draw(sheet)
        for frame in range(8):
            x, y = frame % 4 * 480, frame // 4 * 350
            crop = image.crop((frame * 128 + 40, 298, frame * 128 + 92, 332))
            scaled = crop.resize((416, 272), Image.Resampling.NEAREST)
            sheet.paste(scaled, (x + 28, y + 46), scaled)
            draw.text((x + 8, y + 5), f'{outfit} SOUTH {frame}: original x40..91 / y42..75', fill='white')
            draw.text((x + 8, y + 20), 'Gold LEFT / cyan RIGHT; wrist/grip UNKNOWN', fill='white')
            for side in ('left', 'right'):
                entry = records[outfit, frame, side]
                px, py = entry['palm']['pixel']
                cx, cy = x + 28 + (px - 40) * 8 + 4, y + 46 + (py - 42) * 8 + 4
                draw.ellipse((cx - 6, cy - 6, cx + 6, cy + 6), outline=colors[side], width=2)
                rgba = ''.join(f'{v:02x}' for v in entry['palm']['rgba'])
                draw.text((x + 8, y + 322 + (12 if side == 'right' else 0)), f'{side} palm ({px},{py}) RGBA #{rgba}', fill=colors[side])
        path = output / (outfit + '-south-palms.png')
        sheet.save(path)
        files.append({'file': path.name, 'sha256': digest(path.read_bytes())})
    manifest = {'scope': 'Original SOUTH palm provenance only; wrists/grips unknown; no runtime phase acceptance', 'specSha256': digest(SPEC.read_bytes()), 'scriptSha256': digest(Path(__file__).read_bytes()), 'sources': spec['sources'], 'files': files, 'palmEntries': 32, 'sourceVerifiedWrists': 0, 'sourceVerifiedGrips': 0}
    (output / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path)
    args = parser.parse_args()
    spec = json.loads(SPEC.read_text())
    images = validate(spec)
    if args.output:
        review_sheet(spec, images, args.output)
    print('SOUTH UPPER ANCHORS SOURCE PASS: 32 visible original palm texels; 0 source-verified wrists/grips; no runtime phase acceptance')


if __name__ == '__main__':
    main()
