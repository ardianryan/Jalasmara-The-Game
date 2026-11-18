"""Build two transparent, bounded pixel poses from project-owned source art.

Run with Pillow 11.3.0 from the repository root. These are authoring outputs,
not runtime dependencies. Coordinates are source pixels, never screen pixels.
"""

from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[5]
OUT = Path(__file__).resolve().parent


def lurah_point() -> None:
    image = Image.open(OUT / "ki-lurah-teaching.png").convert("RGBA")
    draw = ImageDraw.Draw(image)
    # Remove the hand resting on his belt; keep the shoulder and elbow.
    # Restore the painted belt/robe pattern from an adjacent source-pixel
    # strip rather than covering the old fist with a flat rectangle.
    mask = Image.new("L", image.size)
    ImageDraw.Draw(mask).polygon([(49, 59), (61, 59), (63, 68), (54, 73), (48, 68)], fill=255)
    original = image.copy()
    for y in range(59, 74):
        for x in range(48, 64):
            if mask.getpixel((x, y)):
                image.putpixel((x, y), original.getpixel((x + 13, y)))
    draw = ImageDraw.Draw(image)
    # Lift the free forearm beside the shoulder. A single raised finger is
    # kept within the 124-pixel close-stage silhouette and stays attached.
    draw.line([(42, 57), (38, 40)], fill=(21, 18, 29, 255), width=8)
    draw.line([(42, 56), (38, 41)], fill=(49, 53, 76, 255), width=5)
    draw.line([(41, 50), (38, 42)], fill=(191, 135, 75, 255), width=1)
    draw.polygon([(34, 37), (41, 35), (44, 41), (37, 44)], fill=(222, 211, 186, 255))
    draw.polygon([(34, 31), (41, 30), (44, 36), (41, 40), (35, 39)], fill=(29, 20, 23, 255))
    draw.polygon([(35, 32), (40, 31), (42, 35), (39, 38), (35, 37)], fill=(230, 166, 110, 255))
    draw.line([(39, 31), (39, 24)], fill=(29, 20, 23, 255), width=4)
    draw.line([(39, 30), (39, 25)], fill=(230, 166, 110, 255), width=2)
    image.save(OUT / "ki-lurah-teaching-point.png")


def gito_release() -> None:
    source = Image.open(ROOT / "client-godot/resources/art/village-expansion-v1/residents.png").convert("RGBA")
    image = source.crop((96, 128, 192, 256))
    draw = ImageDraw.Draw(image)
    # Repose only the right forearm below the existing shoulder. The lower
    # arm's old pixels are removed so it cannot appear as a second limb.
    draw.polygon([(66, 58), (72, 59), (82, 76), (80, 83), (68, 82), (64, 65)], fill=(0, 0, 0, 0))
    draw.line([(65, 57), (72, 51), (78, 43)], fill=(54, 38, 33, 255), width=8)
    draw.line([(65, 57), (71, 51), (78, 43)], fill=(222, 132, 83, 255), width=5)
    draw.line([(67, 55), (74, 48)], fill=(241, 162, 101, 255), width=2)
    draw.ellipse((74, 38, 82, 46), fill=(59, 37, 31, 255))
    draw.ellipse((75, 39, 81, 44), fill=(238, 157, 99, 255))
    # The sling remains in GDScript so the pouch can track each release.
    image.save(OUT / "gito-sling-release.png")


if __name__ == "__main__":
    lurah_point()
    gito_release()
