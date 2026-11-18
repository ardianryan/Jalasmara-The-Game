"""Pixel-author Gito's dock lookout pose from the project-owned resident cutout."""

import hashlib
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "assets/source-2d/village-expansion-v1/cutouts/residents.png"
OUTPUT = ROOT / "client-godot/resources/art/resident-rigs-v1/gito-lookout.png"
SOURCE_SHA = "6dc5fbb107327c97205660817cf245661bea838d50be606735fe2c6a247d413e"


def author() -> Image.Image:
    assert hashlib.sha256(SOURCE.read_bytes()).hexdigest() == SOURCE_SHA
    source = Image.open(SOURCE).convert("RGBA")
    assert source.size == (288, 256)
    pose = source.crop((96, 128, 192, 256))

    # Remove only the visible distal right arm; the vest and shoulder remain.
    for y in range(58, 81):
        for x in range(68, 83):
            if pose.getpixel((x, y))[3]:
                pose.putpixel((x, y), (0, 0, 0, 0))

    draw = ImageDraw.Draw(pose)
    edge = (75, 45, 34, 255)
    skin_shadow = (159, 96, 62, 255)
    skin = (199, 139, 102, 255)
    skin_light = (227, 168, 119, 255)
    vest = (172, 76, 42, 255)
    vest_light = (220, 104, 49, 255)

    # Explicit clusters provide an unbroken elbow and forearm at the 1 px grid.
    draw.polygon([(61, 50), (66, 49), (72, 46), (75, 41), (76, 29),
                  (80, 28), (82, 35), (81, 44), (77, 51), (70, 56),
                  (65, 56)], fill=edge)
    draw.polygon([(62, 51), (67, 50), (72, 48), (75, 44), (76, 37),
                  (80, 36), (79, 46), (75, 51), (68, 54), (64, 54)],
                 fill=vest)
    draw.polygon([(64, 50), (69, 48), (72, 48), (75, 46), (74, 50),
                  (68, 53), (64, 52)], fill=vest_light)
    draw.polygon([(75, 43), (76, 29), (79, 28), (81, 33), (80, 42),
                  (78, 48)], fill=skin_shadow)
    draw.polygon([(76, 41), (77, 30), (79, 30), (80, 35), (79, 43)], fill=skin)
    draw.polygon([(74, 31), (71, 27), (65, 25), (65, 23), (71, 23),
                  (73, 21), (76, 23), (79, 27), (79, 31)], fill=edge)
    draw.polygon([(74, 29), (70, 26), (66, 25), (67, 24), (73, 24),
                  (74, 22), (76, 24), (77, 28)], fill=skin)
    draw.line([(67, 24), (72, 24)], fill=skin_light, width=1)
    return pose


if __name__ == "__main__":
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    author().save(OUTPUT, optimize=False)
    print(hashlib.sha256(OUTPUT.read_bytes()).hexdigest())
