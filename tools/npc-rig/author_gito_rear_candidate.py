"""Author a rear-facing Gito study on the resident source's 96x128 pixel grid."""

import hashlib
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "assets/source-2d/village-expansion-v1/cutouts/residents.png"
OUTPUT = ROOT / "assets/source-2d/village-expansion-v1/directional/gito-rear-study.png"
COMPOSED = ROOT / "assets/source-2d/village-expansion-v1/directional/gito-rear-composed-study.png"
RUNTIME = ROOT / "client-godot/resources/art/resident-rigs-v1/gito-rear-upper.png"
FOOT_LEFT = ROOT / "client-godot/resources/art/resident-rigs-v1/gito-rear-foot-left.png"
FOOT_RIGHT = ROOT / "client-godot/resources/art/resident-rigs-v1/gito-rear-foot-right.png"
SOURCE_SHA = "6dc5fbb107327c97205660817cf245661bea838d50be606735fe2c6a247d413e"


def author() -> Image.Image:
    assert hashlib.sha256(SOURCE.read_bytes()).hexdigest() == SOURCE_SHA
    source = Image.open(SOURCE).convert("RGBA")
    pose = source.crop((96, 128, 192, 256))
    draw = ImageDraw.Draw(pose)

    # Remove front face, collar and vest only. The authored limb pixels and soles
    # remain the contact reference while the back silhouette is assessed.
    for y in range(8, 82):
        for x in range(29, 69):
            if y < 42 or (40 <= y <= 81 and 29 <= x <= 67):
                pose.putpixel((x, y), (0, 0, 0, 0))

    ink = (42, 25, 27, 255)
    hair_dark = (49, 32, 34, 255)
    hair_shadow = (68, 46, 47, 255)
    hair_mid = (91, 64, 61, 255)
    hair_light = (109, 81, 69, 255)
    ear_shadow = (159, 96, 62, 255)
    ear = (234, 152, 100, 255)
    vest_shadow = (115, 50, 33, 255)
    vest_mid = (183, 85, 51, 255)
    vest_light = (220, 104, 49, 255)
    cloth_shadow = (60, 73, 76, 255)
    cloth_mid = (93, 100, 96, 255)
    cloth_light = (163, 132, 102, 255)
    stitch = (220, 186, 147, 255)

    # Rear head: jagged original-size hair silhouette with an unbroken nape;
    # no front-facing eyes, nose or mouth survive this pixel layer.
    draw.polygon([(33, 14), (37, 10), (43, 9), (47, 11), (53, 8), (58, 12),
                  (61, 18), (60, 22), (64, 23), (60, 27), (59, 33),
                  (55, 37), (49, 40), (40, 38), (35, 33), (32, 27),
                  (28, 28), (32, 22), (30, 18)], fill=ink)
    draw.polygon([(35, 16), (39, 12), (46, 13), (51, 11), (56, 14),
                  (59, 19), (56, 25), (60, 27), (55, 33), (49, 37),
                  (41, 36), (36, 31), (33, 25)], fill=hair_shadow)
    draw.polygon([(36, 16), (41, 13), (46, 16), (52, 13), (56, 15),
                  (57, 19), (53, 24), (49, 22), (44, 26), (38, 23)], fill=hair_mid)
    draw.polygon([(37, 28), (43, 30), (48, 27), (53, 29), (58, 26),
                  (56, 33), (51, 35), (44, 35), (39, 33)], fill=hair_dark)
    for a, b in [((37, 15), (41, 14)), ((48, 14), (54, 13)),
                 ((35, 20), (39, 18)), ((42, 18), (46, 16)),
                 ((51, 20), (55, 18)), ((39, 29), (44, 31)),
                 ((48, 29), (53, 27)), ((44, 34), (50, 33))]:
        draw.line([a, b], fill=hair_light, width=1)
    for color, points in [
        ((78, 52, 50, 255), [(39, 16), (43, 21), (50, 15), (54, 22), (47, 30)]),
        ((79, 57, 56, 255), [(36, 24), (42, 17), (51, 20), (55, 31)]),
        ((105, 71, 62, 255), [(40, 14), (46, 17), (53, 16), (57, 23)]),
        ((61, 39, 40, 255), [(35, 26), (40, 25), (49, 24), (54, 33)]),
        ((44, 24, 22, 255), [(33, 21), (38, 31), (51, 34)]),
        ((29, 19, 20, 255), [(31, 24), (56, 35)]),
    ]:
        for point in points:
            draw.point(point, fill=color)
    draw.line([(32, 23), (34, 26), (32, 28)], fill=hair_dark, width=1)
    draw.line([(58, 20), (60, 23), (58, 26)], fill=hair_dark, width=1)
    draw.polygon([(42, 37), (48, 39), (53, 37), (52, 43), (42, 43)], fill=ear_shadow)
    draw.line([(44, 39), (50, 40)], fill=ear, width=2)

    # Rear of the orange vest: stitched hem, broad shoulder yoke and two
    # diagonal satchel straps, with source palette clusters instead of a fill.
    draw.polygon([(34, 40), (43, 42), (51, 43), (62, 41), (66, 48),
                  (65, 77), (60, 81), (35, 81), (30, 76), (31, 48)], fill=ink)
    draw.polygon([(35, 43), (45, 45), (51, 46), (61, 43), (64, 49),
                  (62, 77), (59, 80), (36, 79), (33, 74), (33, 49)], fill=vest_shadow)
    draw.polygon([(36, 45), (45, 47), (51, 48), (60, 45), (62, 50),
                  (60, 72), (55, 77), (39, 77), (35, 73), (35, 50)], fill=vest_mid)
    draw.polygon([(38, 49), (45, 50), (49, 53), (55, 49), (59, 50),
                  (58, 70), (53, 75), (41, 75), (37, 70)], fill=vest_light)
    draw.polygon([(35, 44), (41, 44), (47, 56), (52, 64), (59, 74),
                  (56, 77), (48, 66), (41, 55)], fill=cloth_shadow)
    draw.line([(39, 45), (46, 57), (52, 66), (58, 75)], fill=cloth_mid, width=2)
    draw.polygon([(61, 44), (64, 48), (55, 60), (48, 70), (41, 77),
                  (37, 75), (46, 66), (53, 55)], fill=cloth_shadow)
    draw.line([(61, 47), (55, 57), (48, 67), (42, 74)], fill=cloth_mid, width=2)
    draw.rectangle((44, 62, 52, 68), fill=cloth_shadow)
    draw.line([(46, 64), (50, 64)], fill=cloth_light, width=1)
    draw.line([(41, 50), (42, 53)], fill=stitch, width=1)
    draw.line([(57, 52), (58, 49)], fill=stitch, width=1)
    for x in (37, 41, 53, 57):
        draw.point((x, 77), fill=stitch)
    return pose


def rear_foot(width: int, height: int, sole_x: int) -> Image.Image:
    """Draw a rear heel and back strap, retaining the source sole anchor."""
    foot = Image.new("RGBA", (width, height))
    draw = ImageDraw.Draw(foot)
    ink = (42, 25, 27, 255)
    leather_dark = (68, 46, 47, 255)
    leather = (115, 50, 33, 255)
    leather_light = (151, 84, 56, 255)
    skin_shadow = (159, 96, 62, 255)
    skin = (234, 152, 100, 255)
    left = sole_x - 6
    right = sole_x + 6
    draw.polygon([(sole_x - 3, 0), (sole_x + 2, 0), (sole_x + 4, 3),
                  (right, height - 3), (right, height - 2),
                  (sole_x + 4, height - 1), (sole_x - 5, height - 1),
                  (left, height - 2), (left, height - 3), (sole_x - 4, 3)], fill=ink)
    draw.polygon([(sole_x - 3, 1), (sole_x + 2, 1), (sole_x + 3, 3),
                  (sole_x + 4, height - 4), (sole_x - 4, height - 4)], fill=skin_shadow)
    draw.line([(sole_x - 2, 1), (sole_x + 1, 1)], fill=skin, width=1)
    draw.rectangle((sole_x - 4, 3, sole_x + 4, 4), fill=leather_dark)
    draw.line([(sole_x - 3, 3), (sole_x + 3, 3)], fill=leather_light, width=1)
    draw.polygon([(sole_x - 4, height - 4), (sole_x + 4, height - 4),
                  (sole_x + 5, height - 2), (sole_x - 5, height - 2)], fill=leather)
    draw.line([(sole_x - 4, height - 3), (sole_x + 4, height - 3)], fill=leather_light, width=1)
    draw.line([(sole_x - 5, height - 1), (sole_x + 4, height - 1)], fill=ink, width=1)
    assert foot.getpixel((sole_x, height - 1))[3] != 0
    return foot


if __name__ == "__main__":
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    image = author()
    image.save(OUTPUT, optimize=False)
    upper = image.copy()
    for y in range(128):
        for x in range(96):
            if y >= 82 or (y >= 41 and not 29 <= x <= 67):
                upper.putpixel((x, y), (0, 0, 0, 0))
    RUNTIME.parent.mkdir(parents=True, exist_ok=True)
    upper.save(RUNTIME, optimize=False)
    left_heel = rear_foot(13, 9, 7)
    right_heel = rear_foot(21, 8, 11)
    left_heel.save(FOOT_LEFT, optimize=False)
    right_heel.save(FOOT_RIGHT, optimize=False)
    composed = image.copy()
    draw = ImageDraw.Draw(composed)
    draw.rectangle((27, 111, 39, 119), fill=(0, 0, 0, 0))
    draw.rectangle((51, 111, 71, 118), fill=(0, 0, 0, 0))
    composed.alpha_composite(left_heel, (27, 111))
    composed.alpha_composite(right_heel, (51, 111))
    composed.save(COMPOSED, optimize=False)
    print(hashlib.sha256(OUTPUT.read_bytes()).hexdigest())
    print(hashlib.sha256(RUNTIME.read_bytes()).hexdigest())
    print(hashlib.sha256(FOOT_LEFT.read_bytes()).hexdigest())
    print(hashlib.sha256(FOOT_RIGHT.read_bytes()).hexdigest())
    print(hashlib.sha256(COMPOSED.read_bytes()).hexdigest())
