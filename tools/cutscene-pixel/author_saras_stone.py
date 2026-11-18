"""Author Saras's connected stone-reveal poses from the approved facing tile."""

from hashlib import sha256
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "client-godot/resources/art/npc-facing-v2/saras-front.png"
OUTPUT = ROOT / "client-godot/resources/art/cinematics-v2/close-pose/saras-stone-reveal.png"
SOURCE_SHA = "eaa224b71c3919381cc605956d583fc543792d98854fe00e17274b67f8ca57e2"


def build() -> Image.Image:
    source_bytes = SOURCE.read_bytes()
    if SOURCE_SHA and sha256(source_bytes).hexdigest() != SOURCE_SHA:
        raise ValueError("Saras facing art changed; inspect it before rebuilding the pose")
    source = Image.open(SOURCE).convert("RGBA")
    if source.size != (320, 64):
        raise ValueError(f"Unexpected Saras facing atlas: {source.size}")
    base = source.crop((0, 0, 64, 64))
    frames = []
    for extended in (False, True):
        pose = base.copy()
        d = ImageDraw.Draw(pose)
        # Replace the old raised hand and its indistinct scroll with an arm
        # attached to the coat. The wrist is underneath the stone's lower rim.
        d.polygon([(35, 16), (42, 14), (49, 17), (50, 23), (45, 27), (37, 26),
                   (34, 23)], fill=(0, 0, 0, 0))
        edge = (43, 37, 43, 255)
        coat = (177, 154, 127, 255)
        coat_shadow = (124, 104, 93, 255)
        skin = (202, 139, 93, 255)
        skin_light = (236, 181, 126, 255)
        stone_edge = (49, 47, 57, 255)
        stone = (105, 109, 111, 255)
        stone_light = (168, 175, 158, 255)
        quartz = (111, 222, 208, 255)
        if extended:
            # Sleeve bends at the elbow before the hand turns palm-up.
            d.polygon([(32, 20), (37, 20), (41, 26), (47, 25), (49, 29),
                       (45, 32), (38, 31), (34, 27)], fill=edge)
            d.polygon([(33, 21), (37, 21), (40, 27), (44, 27), (45, 30),
                       (39, 29), (35, 26)], fill=coat_shadow)
            d.line([(34, 21), (38, 24), (40, 27)], fill=coat, width=2)
            d.polygon([(45, 25), (49, 23), (53, 25), (54, 29), (50, 31),
                       (46, 30)], fill=edge)
            d.polygon([(46, 26), (49, 24), (52, 26), (52, 29), (48, 30)], fill=skin)
            d.line([(48, 25), (51, 26)], fill=skin_light, width=1)
            stone_box = [(45, 16), (52, 14), (57, 18), (56, 25), (50, 27), (44, 23)]
            stone_inset = [(46, 17), (52, 16), (55, 19), (54, 24), (50, 25), (46, 22)]
            crack = [(48, 17), (50, 20), (49, 22), (52, 24)]
            acid_stain = [(54, 20), (55, 20), (54, 21)]
        else:
            d.polygon([(32, 19), (38, 19), (44, 22), (46, 27), (42, 31),
                       (36, 28), (33, 24)], fill=edge)
            d.polygon([(33, 20), (37, 20), (42, 23), (44, 27), (41, 29),
                       (36, 27)], fill=coat_shadow)
            d.line([(34, 21), (39, 23), (42, 26)], fill=coat, width=2)
            d.polygon([(42, 25), (46, 24), (49, 27), (48, 30), (44, 30)], fill=skin)
            stone_box = [(40, 16), (47, 15), (51, 18), (50, 25), (45, 27), (40, 23)]
            stone_inset = [(41, 17), (47, 16), (49, 19), (49, 23), (45, 25), (41, 22)]
            crack = [(43, 17), (45, 20), (44, 22), (47, 24)]
            acid_stain = [(48, 19), (49, 20), (48, 21)]
        d.polygon(stone_box, fill=stone_edge)
        d.polygon(stone_inset, fill=stone)
        d.line([(stone_inset[0][0] + 1, stone_inset[0][1]), stone_inset[1]], fill=stone_light, width=1)
        d.line(crack, fill=quartz, width=1)
        for point in acid_stain:
            d.point(point, fill=(162, 90, 154, 255))
        d.point((crack[-1][0] + 1, crack[-1][1] - 1), fill=(214, 246, 195, 255))
        frames.append(pose)
    sheet = Image.new("RGBA", (128, 64))
    sheet.paste(frames[0], (0, 0))
    sheet.paste(frames[1], (64, 0))
    return sheet


if __name__ == "__main__":
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    build().save(OUTPUT, optimize=False)
    print(sha256(OUTPUT.read_bytes()).hexdigest())
