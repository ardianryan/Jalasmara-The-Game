#!/usr/bin/env python3
"""Pack reviewed resident rear portraits and code-driven five-frame foot cycles."""

import hashlib
import json
from pathlib import Path
from shutil import copyfile

from PIL import Image


ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "assets/source-2d/resident-back-v2"
FRONTS = ROOT / "client-godot/resources/art/npc-simple-steps-v1"
OUTPUT = ROOT / "client-godot/resources/art/npc-facing-v2"
CELL = 64
OFFSETS = [((0, 0), (0, 0)), ((-2, 0), (2, -1)), ((0, -2), (0, 0)), ((2, -1), (-2, 0)), ((0, 0), (0, -2))]
LEG_TOP = {
    "ki_lurah_wirabhumi": 55,
    "mbok_ratih": 54,
    "kang_tedi": 43,
    "saras": 43,
    "mbah_wira": 54,
    "beno": 43,
    "inspektur_raka": 51,
}


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def normalized_rear(path):
    raw = Image.open(path).convert("RGBA")
    visible = raw.getchannel("A").point(lambda alpha: 255 if alpha >= 128 else 0).getbbox()
    if visible is None:
        raise ValueError(f"Empty rear source: {path}")
    raw = raw.crop(visible)
    raw.thumbnail((CELL, CELL - 2), Image.Resampling.NEAREST)
    tile = Image.new("RGBA", (CELL, CELL))
    tile.alpha_composite(raw, ((CELL - raw.width) // 2, CELL - 2 - raw.height))
    tile.putalpha(tile.getchannel("A").point(lambda alpha: 255 if alpha >= 128 else 0))
    return tile


def rear_steps(idle, slug):
    split = CELL // 2
    top = LEG_TOP[slug]
    legs = [Image.new("RGBA", idle.size), Image.new("RGBA", idle.size)]
    body = idle.copy()
    for y in range(top, CELL):
        for x in range(CELL):
            pixel = idle.getpixel((x, y))
            if pixel[3] == 0:
                continue
            legs[0 if x < split else 1].putpixel((x, y), pixel)
            body.putpixel((x, y), (0, 0, 0, 0))
    strip = Image.new("RGBA", (CELL * 5, CELL))
    strip.alpha_composite(idle, (0, 0))
    for frame, (left, right) in enumerate(OFFSETS[1:], 1):
        tile = Image.new("RGBA", idle.size)
        for part, offset in zip(legs, (left, right)):
            tile.alpha_composite(part, offset)
        tile.alpha_composite(body)
        strip.alpha_composite(tile, (frame * CELL, 0))
    return strip


def pack():
    OUTPUT.mkdir(parents=True, exist_ok=True)
    manifest = {"method": "source-preserved front/three-quarter side and original rear portraits with code-driven short foot cycles",
                "releaseStatus": "visual_candidate_not_staged", "people": {}}
    old = json.loads((FRONTS / "manifest.json").read_text())
    for name, prior in old["people"].items():
        slug = name.lower().replace(" ", "_")
        front_path = FRONTS / prior["file"]
        source_path = SOURCE / f"{slug}-rear-source.png"
        if not source_path.exists():
            raise FileNotFoundError(source_path)
        for view in ("front", "side"):
            copyfile(front_path, OUTPUT / f"{slug}-{view}.png")
        rear = rear_steps(normalized_rear(source_path), slug)
        rear.save(OUTPUT / f"{slug}-rear.png", optimize=True)
        manifest["people"][name] = {
            "file": f"{slug}-front.png", "side": f"{slug}-side.png", "rear": f"{slug}-rear.png",
            "source": str(source_path.relative_to(ROOT)), "sourceSha256": sha(source_path),
            "frontSha256": sha(front_path), "rearSha256": sha(OUTPUT / f"{slug}-rear.png"),
            "frames": 5, "cellSize": CELL, "legTop": LEG_TOP[slug],
        }
    (OUTPUT / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")


if __name__ == "__main__":
    pack()
