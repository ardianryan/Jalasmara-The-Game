"""Author Kinasih's connected clue gesture from the project-owned child atlas.

The two 96x128 cells retain source pixels except the right arm and jar. All new
marks use hard integer pixels; no AI image or resampling step is involved.
"""

from collections import deque
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw


ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "client-godot/resources/art/village-expansion-v1/residents.png"
OUTPUT = ROOT / "client-godot/resources/art/cinematics-v2/garden-kinasih-clue.png"
CELL = (96, 128)


def pose(source: Image.Image, raised: bool) -> Image.Image:
    result = source.copy()
    erase = Image.new("L", CELL, 0)
    ImageDraw.Draw(erase).polygon(
        [(66, 48), (70, 48), (96, 57), (96, 93), (69, 93), (67, 69), (66, 58)],
        fill=255,
    )
    result.putalpha(ImageChops.subtract(result.getchannel("A"), erase))
    draw = ImageDraw.Draw(result)

    dark = (52, 45, 37, 255)
    cloth = (120, 123, 74, 255)
    cloth_light = (172, 160, 107, 255)
    skin = (193, 118, 79, 255)
    highlight = (243, 175, 118, 255)
    if raised:
        draw.polygon([(61, 49), (67, 50), (70, 54), (77, 53), (82, 47), (86, 51), (80, 60), (70, 62), (63, 58)], fill=dark)
        draw.polygon([(62, 50), (66, 50), (69, 55), (77, 54), (80, 56), (70, 60), (65, 56)], fill=cloth)
        draw.line([(64, 51), (69, 56), (76, 55)], fill=cloth_light, width=2)
        draw.polygon([(79, 53), (84, 47), (88, 48), (88, 54), (83, 58)], fill=skin)
        draw.line([(84, 48), (87, 49)], fill=highlight, width=2)
        jar_x, jar_y = 82, 30
    else:
        draw.polygon([(62, 49), (68, 50), (72, 58), (74, 68), (71, 74), (65, 70), (65, 61)], fill=dark)
        draw.polygon([(63, 50), (67, 51), (70, 60), (71, 67), (68, 69), (66, 62)], fill=cloth)
        draw.line([(65, 52), (69, 59), (69, 65)], fill=cloth_light, width=2)
        draw.polygon([(69, 68), (75, 68), (79, 73), (74, 78), (69, 75)], fill=skin)
        draw.line([(72, 69), (76, 72)], fill=highlight, width=2)
        jar_x, jar_y = 76, 56

    # The thumb physically overlaps the jar rim; the shell remains inside glass.
    draw.rectangle((jar_x - 7, jar_y + 1, jar_x + 6, jar_y + 19), fill=dark)
    draw.rectangle((jar_x - 5, jar_y + 3, jar_x + 4, jar_y + 16), fill=(47, 115, 111, 255))
    draw.rectangle((jar_x - 5, jar_y, jar_x + 4, jar_y + 3), fill=(141, 105, 62, 255))
    draw.line([(jar_x - 4, jar_y + 5), (jar_x - 4, jar_y + 12)], fill=(150, 218, 192, 255), width=2)
    draw.ellipse((jar_x - 2, jar_y + 8, jar_x + 3, jar_y + 13), fill=(136, 235, 197, 255))
    draw.point((jar_x + 1, jar_y + 10), fill=(47, 115, 111, 255))
    if raised:
        draw.rectangle((jar_x - 6, jar_y + 18, jar_x - 3, jar_y + 21), fill=skin)
    else:
        draw.rectangle((jar_x - 8, jar_y + 9, jar_x - 5, jar_y + 12), fill=skin)
    return result


def assert_connected(image: Image.Image) -> None:
    alpha = image.getchannel("A")
    occupied = {(x, y) for y in range(CELL[1]) for x in range(CELL[0]) if alpha.getpixel((x, y))}
    start = (48, 68)
    assert start in occupied
    seen = {start}
    pending = deque([start])
    while pending:
        x, y = pending.popleft()
        for point in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
            if point in occupied and point not in seen:
                seen.add(point)
                pending.append(point)
    # The source child has two intentionally isolated one-pixel hair glints.
    assert len(occupied - seen) <= 2, f"disconnected ink: {len(occupied - seen)} pixels"


def main() -> None:
    atlas = Image.open(SOURCE).convert("RGBA")
    source = atlas.crop((192, 0, 288, 128))
    sheet = Image.new("RGBA", (192, 128))
    for index, raised in enumerate((False, True)):
        frame = pose(source, raised)
        assert_connected(frame)
        sheet.alpha_composite(frame, (index * CELL[0], 0))
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(OUTPUT, optimize=True)


if __name__ == "__main__":
    main()
