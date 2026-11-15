#!/usr/bin/env python3
"""Draw original 64 px side/rear resident poses with reproducible pixel primitives.

The portrait atlas supplies the south-facing view. These two views are authored
as small role-specific silhouettes; they do not transform or recolor a face.
"""

import json
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "client-godot/resources/art/npc-simple-steps-v1"
CELL = 64
INK = "#201c26"
LIGHT = "#f1d49b"
SKIN = "#bd7d52"
SKIN_LIT = "#e7aa75"

PEOPLE = {
    "ki_lurah_wirabhumi": dict(coat="#26344c", shade="#18233b", trim="#d5a45d", pants="#765b47", hair="#c8c5b3", hat="#292838", shoes="#765036", prop="staff", garment="robe"),
    "mbok_ratih": dict(coat="#b9605a", shade="#893b4d", trim="#e9b079", pants="#77534c", hair="#34303c", hat="", shoes="#a46d4c", prop="basket", garment="apron"),
    "kang_tedi": dict(coat="#e5d4b7", shade="#aaacac", trim="#6a818d", pants="#303b5a", hair="#292733", hat="#914751", shoes="#4a3432", prop="wrench", garment="pants"),
    "saras": dict(coat="#344765", shade="#253653", trim="#b0a2aa", pants="#855c46", hair="#2d2938", hat="", shoes="#8d5a42", prop="scroll", garment="robe"),
    "mbah_wira": dict(coat="#665041", shade="#3f302f", trim="#d6ae72", pants="#514044", hair="#d0ccc0", hat="#272637", shoes="#78503b", prop="apron", garment="apron"),
    "beno": dict(coat="#394c69", shade="#27344d", trim="#b88252", pants="#303e5b", hair="#241e2a", hat="#a8463a", shoes="#564036", prop="goggles", garment="pants"),
    "inspektur_raka": dict(coat="#ece6d8", shade="#b9b8b5", trim="#d5a85e", pants="#37343e", hair="#2e2734", hat="", shoes="#332b2f", prop="case", garment="coat"),
}


def polygon(draw, points, fill, outline=INK):
    draw.polygon(points, fill=fill)
    if outline:
        draw.line(points + [points[0]], fill=outline, width=1, joint="curve")


def box(draw, xy, fill, outline=INK):
    draw.rectangle(xy, fill=fill, outline=outline, width=1)


def hat_and_hair(draw, cfg, view, sway):
    hair = cfg["hair"]
    if view == "rear":
        draw.ellipse((20+sway, 4, 44+sway, 25), fill=hair, outline=INK, width=1)
        polygon(draw, [(22+sway, 17), (25+sway, 24), (27+sway, 26), (38+sway, 26), (42+sway, 19)], hair)
        polygon(draw, [(27+sway, 20), (38+sway, 20), (37+sway, 26), (28+sway, 26)], "#8c6654" if cfg["prop"] != "apron" else hair)
        for x in (25, 29, 35, 39):
            draw.point((x+sway, 11), fill="#635967" if hair != "#d0ccc0" else "#f2e4cd")
        for x in (23, 27, 32, 38, 42):
            draw.line([(x+sway, 15), (x+(-1 if x<32 else 1)+sway, 20)], fill="#4c4350" if hair != "#d0ccc0" else "#aaa69b", width=1)
        if cfg["prop"] in ("basket", "scroll"):
            box(draw, (19+sway, 12, 26+sway, 24), hair)
            box(draw, (38+sway, 12, 45+sway, 24), hair)
        if cfg["hat"]:
            polygon(draw, [(17+sway, 12), (22+sway, 5), (30+sway, 2), (42+sway, 5), (47+sway, 12), (43+sway, 16), (19+sway, 16)], cfg["hat"])
            draw.line([(20+sway, 11), (44+sway, 11)], fill=cfg["trim"], width=2)
            if cfg["prop"] == "goggles":
                for x in (25, 35): box(draw, (x+sway, 7, x+6+sway, 12), "#83bbc3", "#c9a962")
        return

    # East profile: nose, chin, rear hair and a single visible eye.
    polygon(draw, [(24+sway, 8), (38+sway, 7), (44+sway, 12), (46+sway, 17), (49+sway, 18), (46+sway, 21), (44+sway, 25), (30+sway, 25), (24+sway, 20)], SKIN)
    draw.ellipse((20+sway, 5, 43+sway, 25), fill=hair, outline=INK, width=1)
    polygon(draw, [(22+sway, 6), (36+sway, 4), (44+sway, 9), (37+sway, 14), (23+sway, 13)], hair)
    polygon(draw, [(31+sway, 14), (42+sway, 14), (47+sway, 17), (49+sway, 18), (46+sway, 21), (43+sway, 24), (32+sway, 23)], SKIN)
    draw.line([(37+sway, 15), (43+sway, 16)], fill=SKIN_LIT, width=2)
    box(draw, (39+sway, 15, 41+sway, 16), INK, None)
    draw.point((43+sway, 18), fill=SKIN_LIT)
    if cfg["hat"]:
        polygon(draw, [(19+sway, 12), (24+sway, 4), (36+sway, 2), (45+sway, 9), (48+sway, 13), (42+sway, 15), (20+sway, 15)], cfg["hat"])
        draw.line([(24+sway, 11), (44+sway, 12)], fill=cfg["trim"], width=2)
        if cfg["prop"] == "goggles": box(draw, (35+sway, 7, 43+sway, 12), "#7baab5", "#d4b569")
    if cfg["prop"] == "case": box(draw, (37+sway, 16, 44+sway, 18), "#a9484b")


def legs(draw, cfg, view, phase):
    offsets = ((0, 0, 0, 0), (-2, 0, 2, -1), (0, -1, 0, 0), (2, -1, -2, 0), (0, 0, 0, -1))
    lx, ly, rx, ry = offsets[phase]
    if view == "rear":
        for base, dx, dy in ((26, lx, ly), (37, rx, ry)):
            polygon(draw, [(base-4, 46), (base+3, 46), (base+dx+3, 56+dy), (base+dx-4, 56+dy)], cfg["pants"])
            polygon(draw, [(base+dx-4, 55+dy), (base+dx+3, 55+dy), (base+dx+5, 59+dy), (base+dx+4, 61+dy), (base+dx-5, 61+dy)], cfg["shoes"])
            draw.line([(base+dx-4, 59+dy), (base+dx+3, 59+dy)], fill=LIGHT, width=1)
    else:
        for base, dx, dy in ((29, lx, ly), (37, rx, ry)):
            polygon(draw, [(base-3, 45), (base+4, 45), (base+dx+4, 55+dy), (base+dx-3, 56+dy)], cfg["pants"])
            polygon(draw, [(base+dx-4, 55+dy), (base+dx+4, 55+dy), (base+dx+7, 59+dy), (base+dx+6, 61+dy), (base+dx-4, 61+dy)], cfg["shoes"])
            draw.line([(base+dx-3, 59+dy), (base+dx+5, 59+dy)], fill=LIGHT, width=1)


def clothing(draw, cfg, view, phase, sway):
    coat, shade, trim = cfg["coat"], cfg["shade"], cfg["trim"]
    garment, prop = cfg["garment"], cfg["prop"]
    if view == "rear":
        polygon(draw, [(22+sway, 23), (40+sway, 23), (47+sway, 28), (45+sway, 43), (50+sway, 50), (16+sway, 50), (19+sway, 43), (17+sway, 28)], coat)
        polygon(draw, [(18+sway, 28), (22+sway, 24), (25+sway, 37), (23+sway, 43), (17+sway, 40)], shade)
        polygon(draw, [(41+sway, 24), (46+sway, 28), (48+sway, 39), (43+sway, 42), (40+sway, 34)], shade)
        if garment in ("robe", "apron", "coat"):
            draw.line([(18+sway, 44), (45+sway, 44)], fill=trim, width=1)
            for x in range(21, 46, 7):
                draw.line([(x+sway, 28), (x+sway, 45)], fill=shade, width=2)
            if garment == "apron":
                box(draw, (25+sway, 31, 39+sway, 49), shade)
                draw.line([(26+sway, 46), (38+sway, 46)], fill=trim, width=2)
        else:
            box(draw, (22+sway, 41, 43+sway, 44), shade)
            box(draw, (30+sway, 41, 35+sway, 44), trim)
        if prop == "scroll":
            polygon(draw, [(19+sway, 20), (43+sway, 19), (45+sway, 26), (20+sway, 28)], "#427f88")
            box(draw, (18+sway, 20, 21+sway, 28), trim)
            box(draw, (42+sway, 19, 46+sway, 26), trim)
        elif prop == "basket":
            box(draw, (17+sway, 28, 24+sway, 39), "#b1844d")
            draw.arc((15+sway, 23, 27+sway, 35), 180, 355, fill=trim, width=2)
        elif prop == "staff":
            box(draw, (48+sway, 12, 50+sway, 60), "#9b6a38")
            box(draw, (47+sway, 8, 51+sway, 13), trim)
            draw.point((49+sway, 25), fill=LIGHT)
        elif prop == "wrench":
            box(draw, (48+sway, 38, 50+sway, 57), "#a2b0b0")
            draw.line([(46+sway, 38), (52+sway, 38)], fill=LIGHT, width=2)
        elif prop == "case":
            box(draw, (47+sway, 40, 55+sway, 53), "#686568")
            box(draw, (49+sway, 37, 53+sway, 40), trim)
        return

    polygon(draw, [(27+sway, 23), (39+sway, 24), (42+sway, 31), (42+sway, 43), (44+sway, 49), (22+sway, 49), (23+sway, 33)], coat)
    polygon(draw, [(23+sway, 28), (28+sway, 24), (30+sway, 40), (26+sway, 43), (21+sway, 39)], shade)
    draw.line([(25+sway, 43), (42+sway, 43)], fill=trim, width=2)
    draw.line([(34+sway, 26), (38+sway, 41)], fill=shade, width=2)
    if garment == "apron": box(draw, (31+sway, 32, 43+sway, 48), shade)
    elif garment == "coat": draw.line([(35+sway, 27), (44+sway, 48)], fill=trim, width=2)
    elif garment == "robe":
        for y in (45, 47): draw.line([(23+sway, y), (44+sway, y)], fill=shade, width=1)
    if prop == "staff":
        box(draw, (47+sway, 9, 49+sway, 60), "#9b6a38")
        box(draw, (46+sway, 7, 50+sway, 11), trim)
    elif prop == "scroll":
        box(draw, (25+sway, 22, 42+sway, 27), "#427f88")
        box(draw, (24+sway, 21, 27+sway, 28), trim)
    elif prop == "basket": box(draw, (20+sway, 34, 27+sway, 43), "#b1844d")
    elif prop == "wrench": box(draw, (46+sway, 31, 48+sway, 51), "#a2b0b0")
    elif prop == "case": box(draw, (45+sway, 41, 54+sway, 53), "#686568")


def details(draw, cfg, view, phase, sway):
    trim, prop = cfg["trim"], cfg["prop"]
    if view == "rear":
        if prop in ("staff", "apron"):
            for x in (27, 33, 39):
                for y in (31, 38): draw.point((x+sway, y), fill=trim)
        if prop == "goggles":
            box(draw, (24+sway, 29, 41+sway, 33), "#9b6249")
            box(draw, (30+sway, 29, 35+sway, 32), trim)
        if prop == "case":
            draw.line([(31+sway, 24), (32+sway, 45)], fill=trim, width=2)
        if prop == "scroll":
            draw.line([(24+sway, 28), (25+sway, 44)], fill=trim, width=2)
        if prop == "basket":
            for y in (31, 35): draw.line([(18+sway, y), (23+sway, y)], fill=trim, width=1)
        # Hands stay connected to the sleeves; rear arms alternate a single pixel.
        polygon(draw, [(17+sway, 37), (22+sway, 39), (22+sway, 45), (17+sway, 45)], SKIN)
        polygon(draw, [(43+sway, 39), (47+sway, 37), (48+sway, 45), (43+sway, 45)], SKIN)
    else:
        if prop == "goggles": box(draw, (36+sway, 8, 43+sway, 12), "#6ea6b4", trim)
        if prop == "case": draw.line([(40+sway, 27), (42+sway, 46)], fill=trim, width=1)
        polygon(draw, [(38+sway, 36), (43+sway, 36), (44+sway, 43), (40+sway, 44)], SKIN)
        draw.line([(40+sway, 37), (43+sway, 37)], fill=SKIN_LIT, width=1)
    # Pixel accents are deliberately sparse at actual display resolution.
    draw.point((31+sway, 34), fill=trim)


def fabric_pixels(image, cfg, view, phase):
    """Shade existing garment pixels and place a few character-specific motifs."""
    p = image.load()
    coat = tuple(bytes.fromhex(cfg["coat"][1:]))
    shade = tuple(bytes.fromhex(cfg["shade"][1:]))
    trim = tuple(bytes.fromhex(cfg["trim"][1:]))
    color = lambda rgb: (*rgb, 255)
    for y in range(25, 49):
        for x in range(17, 50):
            if p[x, y] != color(coat):
                continue
            seed = (x * 17 + y * 29 + x * y * 3) % 37
            if seed in (0, 1, 3, 8):
                p[x, y] = color(shade)
            elif seed == 12 or (x + 2*y) % 23 == 0:
                p[x, y] = color(trim)
    d = ImageDraw.Draw(image)
    prop = cfg["prop"]
    if prop == "staff":
        for x in (26, 34, 42):
            d.line([(x, 29), (x+1, 40)], fill=cfg["trim"], width=1)
        for y in (45, 48): d.line([(21, y), (45, y)], fill="#b48752", width=1)
    elif prop == "basket":
        for x, y in ((28, 31), (37, 35), (32, 40)):
            for dx, dy in ((0, 0), (1, -1), (-1, -1), (0, -2)):
                d.point((x+dx, y+dy), fill="#f0c389")
        for x in range(27, 40, 4): d.line([(x, 45), (x+2, 47)], fill="#c28a63", width=1)
    elif prop == "wrench":
        for x, y in ((30, 31), (38, 39), (27, 43)):
            d.line([(x, y), (x+2, y+2)], fill="#b6aca7", width=1)
        d.line([(24, 44), (42, 44)], fill="#7c5f53", width=2)
    elif prop == "scroll":
        for x, y in ((29, 34), (38, 37), (33, 42)):
            for dx, dy in ((0, 0), (2, 0), (1, -1), (1, 1)):
                d.point((x+dx, y+dy), fill="#87a5bc")
    elif prop == "apron":
        for x in (25, 31, 37):
            d.line([(x, 28), (x+1, 41)], fill="#a58a6d", width=1)
        for x in (28, 35): d.line([(x, 44), (x+3, 44)], fill="#8aa3a9", width=1)
    elif prop == "goggles":
        for x, y in ((28, 32), (39, 36), (30, 45)):
            d.line([(x, y), (x+3, y+1)], fill="#8c816b", width=1)
        d.rectangle((26, 43, 40, 44), fill="#a77659")
    elif prop == "case":
        d.line([(31, 28), (32, 43)], fill="#d7b978", width=1)
        for x, y in ((28, 32), (37, 36), (35, 44)):
            d.point((x, y), fill="#eae0ca")


def frame(cfg, view, phase):
    image = Image.new("RGBA", (CELL, CELL))
    draw = ImageDraw.Draw(image)
    sway = (0, 1, 0, -1, 0)[phase]
    legs(draw, cfg, view, phase)
    clothing(draw, cfg, view, phase, sway)
    hat_and_hair(draw, cfg, view, sway)
    details(draw, cfg, view, phase, sway)
    fabric_pixels(image, cfg, view, phase)
    return image


def generate():
    OUT.mkdir(parents=True, exist_ok=True)
    for slug, cfg in PEOPLE.items():
        for view in ("side", "rear"):
            strip = Image.new("RGBA", (CELL * 5, CELL))
            for index in range(5):
                strip.alpha_composite(frame(cfg, view, index), (CELL * index, 0))
            strip.save(OUT / f"{slug}-{view}.png", optimize=True)
    manifest_path = OUT / "manifest.json"
    manifest = json.loads(manifest_path.read_text())
    manifest["directionArt"] = "Original south 3/4 source portraits; pixel-authored east profile and rear silhouettes, mirrored for west"
    manifest["authoringTool"] = "tools/npc-rig/draw_facing_steps.py (Pillow pixel primitives; project original artwork, no external asset)"
    for name, person in manifest["people"].items():
        slug = name.lower().replace(" ", "_")
        person["side"] = f"{slug}-side.png"
        person["rear"] = f"{slug}-rear.png"
    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n")


if __name__ == "__main__":
    generate()
