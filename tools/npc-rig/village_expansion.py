"""Prepare the original six-person portrait source for a separately reviewed rig.

This produces one authored view per person, not a directional walking atlas.
"""
import argparse
import hashlib
import json
from pathlib import Path
from PIL import Image, __version__ as pillow_version

SOURCE_SHA = "9e2c42cd06f3c438e4eae194edf5caa45d23a4fb8610f0e13fa2640078f27d95"
IDS = ["npc_direktur_cakrawala", "npc_kid_bagas", "npc_kid_kinasih",
       "npc_kid_danu", "npc_kid_gito", "npc_kid_cempaka"]


def prepare(source: Path, output: Path):
    assert hashlib.sha256(source.read_bytes()).hexdigest() == SOURCE_SHA
    original = Image.open(source).convert("RGBA")
    assert original.size == (1536, 1024)
    output.mkdir(parents=True, exist_ok=False)
    atlas = Image.new("RGBA", (288, 256))
    people = []
    for index, resident_id in enumerate(IDS):
        x, y = (index % 3) * 512, (index // 3) * 512
        image = original.crop((x, y, x + 512, y + 512))
        image.putalpha(image.getchannel("A").point(lambda alpha: 255 if alpha >= 230 else 0))
        bounds = image.getbbox()
        assert bounds and bounds[0] > 0 and bounds[2] < 512
        cutout = image.crop(bounds)
        scale = min(88 / cutout.width, 112 / cutout.height)
        cutout = cutout.resize((round(cutout.width * scale), round(cutout.height * scale)), Image.Resampling.NEAREST)
        at = ((96 - cutout.width) // 2, 120 - cutout.height)
        atlas.alpha_composite(cutout, ((index % 3) * 96 + at[0], (index // 3) * 128 + at[1]))
        bottom = [xx for xx in range(cutout.width) if cutout.getpixel((xx, cutout.height - 1))[3]]
        assert bottom
        people.append({"id": resident_id, "cell": [index % 3 * 96, index // 3 * 128, 96, 128],
                       "sourceBoundsInCell": list(bounds), "contentBounds": [*at, cutout.width, cutout.height],
                       "alphaBottomPivot": [round(at[0] + sum(xx + 0.5 for xx in bottom) / len(bottom), 4), 120],
                       "authoredViews": 1, "view": "front_three_quarter"})
    alpha = atlas.getchannel("A")
    atlas = atlas.convert("RGB").quantize(colors=64, dither=Image.Dither.NONE).convert("RGBA")
    atlas.putalpha(alpha)
    atlas.save(output / "residents.png", optimize=False)
    assert set(atlas.getchannel("A").getdata()) == {0, 255}
    metadata = {"sourceSha256": SOURCE_SHA, "pillowVersion": pillow_version,
                "image": "residents.png", "cellSize": [96, 128], "grid": [3, 2],
                "alphaThreshold": 230, "paletteColors": 64, "dither": False,
                "people": people, "status": "Source cutouts only; not installed as runtime gait or four-view art"}
    (output / "residents.json").write_text(json.dumps(metadata, indent=2) + "\n")
    print(json.dumps({"output": str(output), "pngBytes": (output / "residents.png").stat().st_size,
                      "pngSha256": hashlib.sha256((output / "residents.png").read_bytes()).hexdigest()}))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--out", type=Path, required=True)
    args = parser.parse_args()
    prepare(args.source, args.out)
