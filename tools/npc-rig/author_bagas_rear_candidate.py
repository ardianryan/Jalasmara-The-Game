"""Author Bagas's rear head, travel pack and heels on his original 96x128 grid."""

import hashlib
import json
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "assets/source-2d/village-expansion-v1/cutouts/residents.png"
OUTPUT_DIR = ROOT / "assets/source-2d/village-expansion-v1/directional"
RUNTIME_DIR = ROOT / "client-godot/resources/art/resident-rigs-v1"
SOURCE_SHA = "6dc5fbb107327c97205660817cf245661bea838d50be606735fe2c6a247d413e"


def author() -> Image.Image:
    assert hashlib.sha256(SOURCE.read_bytes()).hexdigest() == SOURCE_SHA
    source = Image.open(SOURCE).convert("RGBA")
    pose = source.crop((96, 0, 192, 128))
    draw = ImageDraw.Draw(pose)

    # The front-facing face and shirt are concealed by a new rear silhouette.
    # The limb partitions below the waist remain the original contact reference.
    ink = (29, 19, 20, 255)
    hair_shadow = (49, 32, 34, 255)
    hair_mid = (78, 52, 50, 255)
    hair_light = (105, 71, 62, 255)
    skin_shadow = (159, 96, 62, 255)
    skin = (234, 152, 100, 255)
    shirt_shadow = (188, 105, 64, 255)
    shirt_mid = (217, 136, 78, 255)
    shirt_light = (242, 166, 85, 255)
    fabric_dark = (56, 45, 46, 255)
    fabric_mid = (81, 63, 60, 255)
    fabric_light = (132, 86, 70, 255)
    brass = (155, 108, 56, 255)

    # Bagas keeps the ragged hair mass, with a nape instead of eyes/glasses.
    draw.polygon([(30, 18), (34, 12), (39, 14), (43, 8), (49, 10),
                  (55, 7), (59, 11), (63, 10), (64, 17), (68, 19),
                  (63, 22), (65, 28), (60, 31), (59, 36), (54, 41),
                  (40, 41), (35, 37), (30, 32), (27, 29), (31, 25),
                  (25, 22)], fill=ink)
    draw.polygon([(31, 20), (36, 13), (41, 16), (45, 11), (51, 14),
                  (56, 11), (61, 14), (62, 20), (59, 27), (61, 30),
                  (55, 37), (42, 38), (34, 33)], fill=hair_shadow)
    draw.polygon([(34, 17), (39, 13), (44, 15), (48, 11), (53, 16),
                  (58, 13), (60, 17), (56, 24), (50, 19), (45, 23),
                  (39, 20), (35, 25)], fill=hair_mid)
    for a, b in [((34, 17), (39, 15)), ((43, 13), (47, 12)),
                 ((52, 14), (56, 13)), ((38, 24), (43, 22)),
                 ((49, 20), (54, 19)), ((34, 30), (39, 34)),
                 ((48, 29), (53, 27)), ((55, 33), (59, 30))]:
        draw.line((a, b), fill=hair_light, width=1)
    draw.polygon([(41, 36), (53, 36), (54, 43), (41, 43)], fill=skin_shadow)
    draw.line([(43, 39), (51, 39)], fill=skin, width=2)

    # Rear shirt follows the source shoulders and waist; sleeves/arms stay
    # separately animated by the existing rig.
    draw.polygon([(35, 41), (43, 43), (52, 43), (62, 40), (65, 47),
                  (64, 78), (58, 81), (34, 81), (28, 77), (29, 48)], fill=ink)
    draw.polygon([(35, 43), (44, 46), (53, 46), (61, 43), (63, 49),
                  (61, 77), (57, 79), (35, 79), (31, 74), (31, 50)], fill=shirt_shadow)
    draw.polygon([(37, 46), (45, 48), (51, 49), (59, 46), (61, 50),
                  (59, 73), (55, 77), (38, 77), (34, 72), (34, 50)], fill=shirt_mid)
    draw.polygon([(38, 49), (45, 51), (53, 50), (57, 48), (59, 53),
                  (57, 69), (54, 74), (39, 74), (36, 69), (36, 52)], fill=shirt_light)

    # A compact, single back pack. Bagas's separate brass telescope remains
    # in the hand rig; drawing a second tube here would duplicate the prop.
    draw.polygon([(37, 47), (43, 44), (54, 45), (60, 49), (61, 67),
                  (57, 73), (38, 73), (34, 67), (35, 51)], fill=ink)
    draw.polygon([(39, 48), (44, 46), (53, 47), (58, 50), (59, 65),
                  (56, 70), (39, 70), (37, 65), (37, 51)], fill=fabric_dark)
    draw.polygon([(40, 49), (45, 47), (52, 48), (57, 51), (57, 62),
                  (54, 67), (41, 67), (39, 63), (39, 52)], fill=fabric_mid)
    draw.line([(40, 50), (42, 48), (52, 49)], fill=fabric_light, width=1)
    draw.line([(39, 65), (55, 65)], fill=fabric_light, width=2)
    draw.line([(40, 70), (55, 70)], fill=ink, width=2)
    draw.rectangle((46, 63, 51, 66), fill=brass)
    draw.line([(42, 44), (36, 55), (36, 66)], fill=fabric_dark, width=2)
    draw.line([(55, 45), (61, 55), (60, 66)], fill=fabric_dark, width=2)
    draw.line([(33, 78), (59, 78)], fill=fabric_dark, width=2)
    return pose


def rear_foot(width: int, height: int, sole_x: float) -> Image.Image:
    """Rear leather heel with source-matched bottom contact, no frontal toes."""
    foot = Image.new("RGBA", (width, height))
    draw = ImageDraw.Draw(foot)
    cx = int(sole_x)
    ink = (27, 10, 10, 255)
    leather_dark = (78, 41, 32, 255)
    leather = (121, 64, 47, 255)
    leather_light = (188, 105, 64, 255)
    skin = (234, 152, 100, 255)
    draw.polygon([(cx-4, 0), (cx+3, 0), (cx+5, 3), (cx+6, height-2),
                  (cx+5, height-1), (cx-5, height-1), (cx-6, height-2),
                  (cx-5, 3)], fill=ink)
    draw.polygon([(cx-3, 1), (cx+3, 1), (cx+4, 4), (cx-4, 4)], fill=skin)
    draw.line([(cx-4, 3), (cx+4, 3)], fill=leather_dark, width=2)
    draw.line([(cx-3, 4), (cx+3, 4)], fill=leather_light, width=1)
    draw.polygon([(cx-5, height-4), (cx+5, height-4), (cx+5, height-2),
                  (cx-5, height-2)], fill=leather)
    draw.line([(cx-4, height-2), (cx+4, height-2)], fill=leather_dark, width=1)
    draw.line([(cx-2, height-1), (cx+2, height-1)], fill=ink, width=1)
    return foot


def diagonal(base: Image.Image, side: str) -> Image.Image:
    """Hand-place a rear three-quarter cheek/pack edge, never flip pixels."""
    assert side in ("nw", "ne")
    pose = base.copy()
    draw = ImageDraw.Draw(pose)
    ink = (29, 19, 20, 255)
    hair_shadow = (49, 32, 34, 255)
    hair_mid = (78, 52, 50, 255)
    hair_light = (105, 71, 62, 255)
    skin_shadow = (159, 96, 62, 255)
    skin = (234, 152, 100, 255)
    fabric_dark = (56, 45, 46, 255)
    fabric_light = (132, 86, 70, 255)
    shirt_shadow = (188, 105, 64, 255)
    if side == "nw":
        draw.polygon([(29, 23), (33, 26), (34, 34), (31, 37),
                      (28, 34), (27, 29)], fill=ink)
        draw.polygon([(29, 28), (32, 29), (32, 35), (29, 33)], fill=skin_shadow)
        draw.line([(29, 29), (30, 31)], fill=skin, width=1)
        draw.polygon([(34, 19), (41, 22), (39, 28), (33, 29)], fill=hair_shadow)
        draw.line([(35, 22), (39, 24)], fill=hair_mid, width=1)
        draw.polygon([(34, 46), (39, 48), (37, 66), (33, 62)], fill=shirt_shadow)
        draw.line([(36, 48), (38, 64)], fill=fabric_dark, width=2)
        draw.line([(58, 52), (59, 65)], fill=fabric_light, width=2)
        draw.line([(47, 13), (52, 15)], fill=hair_light, width=1)
    else:
        draw.polygon([(60, 23), (64, 25), (67, 29), (64, 35),
                      (61, 37), (59, 34)], fill=ink)
        draw.polygon([(62, 28), (65, 30), (64, 34), (61, 35)], fill=skin_shadow)
        draw.line([(64, 30), (64, 32)], fill=skin, width=1)
        draw.polygon([(54, 21), (61, 18), (64, 27), (58, 29)], fill=hair_shadow)
        draw.line([(56, 23), (60, 21)], fill=hair_mid, width=1)
        draw.polygon([(59, 47), (64, 46), (65, 62), (60, 66)], fill=shirt_shadow)
        draw.line([(60, 48), (59, 64)], fill=fabric_dark, width=2)
        draw.line([(37, 52), (36, 65)], fill=fabric_light, width=2)
        draw.line([(40, 13), (45, 15)], fill=hair_light, width=1)
    return pose


def write() -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    RUNTIME_DIR.mkdir(parents=True, exist_ok=True)
    image = author()
    image.save(OUTPUT_DIR / "bagas-rear-study.png", optimize=False)
    upper = image.copy()
    for y in range(128):
        for x in range(96):
            if y >= 82 or (y >= 41 and not 28 <= x <= 65):
                upper.putpixel((x, y), (0, 0, 0, 0))
    upper.save(RUNTIME_DIR / "bagas-rear-upper.png", optimize=False)
    diagonals = {}
    for side in ("nw", "ne"):
        diag = diagonal(image, side)
        diagonals[side] = diag
        diag.save(OUTPUT_DIR / f"bagas-rear-{side}-study.png", optimize=False)
        diag_upper = diag.copy()
        for y in range(128):
            for x in range(96):
                if y >= 82 or (y >= 41 and not 28 <= x <= 67):
                    diag_upper.putpixel((x, y), (0, 0, 0, 0))
        diag_upper.save(RUNTIME_DIR / f"bagas-rear-{side}-upper.png", optimize=False)
    left = rear_foot(15, 9, 7.5)
    right = rear_foot(19, 9, 9.5)
    left.save(RUNTIME_DIR / "bagas-rear-foot-left.png", optimize=False)
    right.save(RUNTIME_DIR / "bagas-rear-foot-right.png", optimize=False)
    composed = image.copy()
    draw = ImageDraw.Draw(composed)
    draw.rectangle((30, 111, 44, 119), fill=(0, 0, 0, 0))
    draw.rectangle((49, 110, 67, 118), fill=(0, 0, 0, 0))
    composed.alpha_composite(left, (30, 111))
    composed.alpha_composite(right, (49, 110))
    composed.save(OUTPUT_DIR / "bagas-rear-composed-study.png", optimize=False)
    provenance = {
        "asset": "Bagas north/northwest/northeast rear head, pack and heels",
        "status": "bounded native review accepted locally; merge and release pending",
        "source": "../cutouts/residents.png",
        "sourceSha256": SOURCE_SHA,
        "authoring": "Project-owned 96x128 source-grid pixels drawn by tools/npc-rig/author_bagas_rear_candidate.py with Pillow; no moodboard or generated image pixels",
        "outputs": ["bagas-rear-study.png", "bagas-rear-composed-study.png",
                    "bagas-rear-nw-study.png", "bagas-rear-ne-study.png",
                    "../../../../client-godot/resources/art/resident-rigs-v1/bagas-rear-upper.png",
                    "../../../../client-godot/resources/art/resident-rigs-v1/bagas-rear-nw-upper.png",
                    "../../../../client-godot/resources/art/resident-rigs-v1/bagas-rear-ne-upper.png",
                    "../../../../client-godot/resources/art/resident-rigs-v1/bagas-rear-foot-left.png",
                    "../../../../client-godot/resources/art/resident-rigs-v1/bagas-rear-foot-right.png"],
        "license": "Original Jalasmara artwork under project LICENSE section 2",
        "limits": "Bagas three northward headings use authored back/three-quarter pixels; front-three-quarter inspect telescope and other headings remain unchanged",
    }
    (OUTPUT_DIR / "bagas-rear-provenance.json").write_text(json.dumps(provenance, indent=2) + "\n")


if __name__ == "__main__":
    write()
