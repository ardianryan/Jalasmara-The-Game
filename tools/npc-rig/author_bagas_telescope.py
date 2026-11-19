"""Author Bagas's optical-inspection pose on the original 96x128 grid."""

import hashlib
import json
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "assets/source-2d/village-expansion-v1/cutouts/residents.png"
RIG_DIR = ROOT / "client-godot/resources/art/resident-rigs-v1"
OUTPUT = RIG_DIR / "bagas-telescope.png"
SOURCE_SHA = "6dc5fbb107327c97205660817cf245661bea838d50be606735fe2c6a247d413e"


def author() -> Image.Image:
    assert hashlib.sha256(SOURCE.read_bytes()).hexdigest() == SOURCE_SHA
    source = Image.open(SOURCE).convert("RGBA")
    assert source.size == (288, 256)
    pose = source.crop((96, 0, 192, 128))
    atlas = Image.open(RIG_DIR / "atlas.png").convert("RGBA")
    rig = json.loads((RIG_DIR / "rigs.json").read_text())
    assert rig["sourceSha256"] == SOURCE_SHA
    parts = rig["people"]["npc_kid_bagas"]["parts"]

    # Remove exactly the original arm-part pixels, preserving the trouser edge.
    for name in ("upper_arm_right", "lower_arm_right", "hand_right"):
        bounds = parts[name]["sourceBounds"]
        x, y, width, height = parts[name]["rect"]
        mask = atlas.crop((x, y, x + width, y + height))
        for row in range(mask.height):
            for col in range(mask.width):
                if mask.getpixel((col, row))[3]:
                    pose.putpixel((col + bounds[0], row + bounds[1]), (0, 0, 0, 0))

    draw = ImageDraw.Draw(pose)
    edge = (50, 31, 24, 255)
    skin_shadow = (142, 83, 55, 255)
    skin = (190, 126, 82, 255)
    skin_light = (234, 160, 105, 255)
    sleeve = (183, 105, 58, 255)
    sleeve_light = (242, 166, 85, 255)
    brass = (155, 108, 56, 255)
    brass_light = (231, 185, 105, 255)
    glass = (92, 177, 182, 255)

    draw.polygon([(58, 48), (64, 48), (70, 51), (75, 49), (77, 38),
                  (76, 31), (80, 30), (82, 36), (81, 47), (78, 55),
                  (72, 58), (64, 55), (59, 54)], fill=edge)
    draw.polygon([(59, 49), (63, 49), (68, 52), (73, 52), (76, 48),
                  (77, 42), (79, 41), (79, 50), (76, 54), (70, 56),
                  (63, 53)], fill=sleeve)
    draw.polygon([(60, 49), (64, 50), (68, 52), (65, 52), (60, 51)],
                 fill=sleeve_light)
    draw.polygon([(75, 48), (77, 31), (79, 31), (81, 36), (80, 45),
                  (78, 50)], fill=skin_shadow)
    draw.polygon([(77, 47), (78, 33), (79, 32), (80, 37), (79, 45)], fill=skin)
    draw.polygon([(76, 34), (71, 32), (64, 32), (61, 28), (65, 26),
                  (71, 27), (74, 25), (79, 27), (79, 34)], fill=edge)
    draw.polygon([(75, 32), (69, 31), (65, 31), (63, 28), (68, 27),
                  (72, 28), (75, 27), (78, 29)], fill=skin)
    draw.line([(66, 27), (72, 28)], fill=skin_light, width=1)

    # The telescope is one held prop in this pose, aligned to his eye.
    draw.rectangle((57, 23, 78, 28), fill=edge)
    draw.rectangle((60, 24, 77, 26), fill=brass)
    draw.line([(61, 23), (75, 23)], fill=brass_light, width=1)
    draw.rectangle((76, 21, 83, 29), fill=edge)
    draw.rectangle((78, 22, 82, 28), fill=brass)
    draw.rectangle((80, 22, 82, 25), fill=glass)
    draw.rectangle((55, 22, 58, 29), fill=edge)
    draw.rectangle((56, 24, 58, 27), fill=brass_light)
    # Pillow 9.4 and 11.3 disagree on this polygon edge pixel.
    pose.putpixel((76, 47), skin_shadow)
    return pose


if __name__ == "__main__":
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    author().save(OUTPUT, optimize=False)
    print(hashlib.sha256(OUTPUT.read_bytes()).hexdigest())
