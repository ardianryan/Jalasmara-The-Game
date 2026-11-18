"""Author two connected celebration arm poses from the approved village child atlas.

Run from the repository root. The script uses hard pixel masks and the source
palette; it never resamples the source artwork.
"""

from pathlib import Path
from collections import deque

from PIL import Image, ImageChops, ImageDraw


ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "client-godot/resources/art/village-expansion-v1/residents.png"
OUTPUT = ROOT / "client-godot/resources/art/cinematics-v2/victory-child-poses.png"
CELL = (96, 128)


def polygon(draw: ImageDraw.ImageDraw, points: list[tuple[int, int]], color: tuple[int, int, int, int]) -> None:
    draw.polygon(points, fill=color)


def make_pose(atlas: Image.Image, source_col: int, source_row: int, outfit: tuple[tuple[int, int, int, int], ...], open_arms: bool, y_shift: int) -> Image.Image:
    original = atlas.crop((source_col * CELL[0], source_row * CELL[1], (source_col + 1) * CELL[0], (source_row + 1) * CELL[1]))
    pose = original.copy()
    # These masks follow only the two dangling arms; shoulders and torso remain.
    erase = Image.new("L", CELL, 0)
    cut = ImageDraw.Draw(erase)
    polygon(cut, [(x, y + y_shift) for x, y in [(0, 50), (28, 46), (34, 49), (37, 61), (33, 71), (34, 88), (0, 88)]], 255)
    polygon(cut, [(x, y + y_shift) for x, y in [(62, 49), (68, 46), (95, 50), (95, 88), (65, 88), (62, 70), (60, 61)]], 255)
    pose.putalpha(ImageChops.subtract(pose.getchannel("A"), erase))
    draw = ImageDraw.Draw(pose)
    dark, cloth, cloth_light, skin, skin_light = outfit
    def arm(points: list[tuple[int, int]], color: tuple[int, int, int, int]) -> None:
        polygon(draw, [(x, y + y_shift) for x, y in points], color)
    if open_arms:
        # Pixel-connected sleeves rise from each original shoulder toward the hands.
        arm([(34, 47), (39, 50), (35, 57), (28, 52), (22, 43), (27, 39), (33, 47)], dark)
        arm([(34, 49), (38, 50), (34, 54), (29, 49), (26, 42), (29, 40)], cloth)
        arm([(29, 41), (32, 46), (34, 49), (31, 48), (26, 42)], cloth_light)
        arm([(21, 31), (27, 31), (30, 40), (25, 44), (19, 38)], dark)
        arm([(22, 32), (26, 32), (28, 39), (24, 42), (21, 38)], skin)
        arm([(22, 32), (25, 32), (26, 36), (22, 36)], skin_light)
        arm([(61, 47), (57, 50), (61, 57), (68, 52), (74, 43), (69, 39), (63, 47)], dark)
        arm([(61, 49), (58, 50), (62, 54), (67, 49), (70, 42), (67, 40)], cloth)
        arm([(67, 41), (64, 46), (62, 49), (65, 48), (70, 42)], cloth_light)
        arm([(75, 31), (69, 31), (66, 40), (71, 44), (77, 38)], dark)
        arm([(74, 32), (70, 32), (68, 39), (72, 42), (75, 38)], skin)
        arm([(71, 32), (74, 32), (74, 36), (70, 36)], skin_light)
    else:
        # Bent elbows face one another; both forearms end in a shared clap point.
        arm([(33, 47), (39, 49), (36, 58), (43, 54), (47, 58), (42, 62), (33, 62), (29, 55)], dark)
        arm([(34, 49), (38, 50), (35, 57), (42, 55), (44, 58), (40, 60), (34, 59)], cloth)
        arm([(34, 49), (37, 50), (35, 54), (32, 53)], cloth_light)
        arm([(42, 53), (48, 53), (49, 58), (44, 59), (41, 57)], dark)
        arm([(43, 54), (47, 54), (47, 57), (44, 58), (42, 56)], skin)
        arm([(43, 54), (46, 54), (46, 55), (43, 55)], skin_light)
        arm([(63, 47), (57, 49), (60, 58), (53, 54), (49, 58), (54, 62), (63, 62), (67, 55)], dark)
        arm([(62, 49), (58, 50), (61, 57), (54, 55), (52, 58), (56, 60), (62, 59)], cloth)
        arm([(59, 49), (62, 50), (64, 53), (61, 54)], cloth_light)
        arm([(54, 53), (48, 53), (47, 58), (52, 59), (55, 57)], dark)
        arm([(53, 54), (49, 54), (49, 57), (52, 58), (54, 56)], skin)
        arm([(50, 54), (53, 54), (53, 55), (50, 55)], skin_light)
    return pose


def main() -> None:
    atlas = Image.open(SOURCE).convert("RGBA")
    sheet = Image.new("RGBA", (CELL[0] * 2, CELL[1] * 2), (0, 0, 0, 0))
    actors = [
        (1, 0, 0, ((31, 17, 19, 255), (180, 105, 61, 255), (236, 162, 93, 255), (216, 136, 89, 255), (245, 190, 130, 255))),
        (1, 1, -8, ((34, 20, 20, 255), (170, 79, 46, 255), (219, 115, 60, 255), (209, 122, 84, 255), (245, 184, 130, 255))),
    ]
    for row, (source_col, source_row, y_shift, palette) in enumerate(actors):
        for col, open_arms in enumerate((False, True)):
            pose = make_pose(atlas, source_col, source_row, palette, open_arms, y_shift)
            alpha = pose.getchannel("A")
            seen: set[tuple[int, int]] = {(48, 68)}
            queue = deque(seen)
            assert alpha.getpixel((48, 68)) > 0
            while queue:
                x, y = queue.popleft()
                for point in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
                    px, py = point
                    if 0 <= px < CELL[0] and 0 <= py < CELL[1] and point not in seen and alpha.getpixel(point) > 0:
                        seen.add(point)
                        queue.append(point)
            assert len(seen) >= sum(1 for value in alpha.getdata() if value > 0) - 1, (row, col, "disconnected pose")
            sheet.alpha_composite(pose, (col * CELL[0], row * CELL[1]))
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(OUTPUT, optimize=True)


if __name__ == "__main__":
    main()
