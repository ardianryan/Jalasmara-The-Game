"""Author Beno's connected Jala pose and a small SmaraPedia prop on pixel grids."""

from hashlib import sha256
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "client-godot/resources/art/npc-facing-v2/beno-front.png"
OUT = ROOT / "client-godot/resources/art/cinematics-v2/close-pose"
SOURCE_SHA = "539c4831184a15d2a611354904875c35ab881d41d8f748e2d874de479d22003f"


def beno_empty() -> Image.Image:
    if sha256(SOURCE.read_bytes()).hexdigest() != SOURCE_SHA:
        raise ValueError("Beno source changed; inspect its pixels before rebuilding")
    source = Image.open(SOURCE).convert("RGBA")
    assert source.size == (320, 64)
    pose = source.crop((0, 0, 64, 64)).copy()
    # Replace only the grey wrench head. Its handle and the two fingers remain
    # at the original coordinates; the new brass ferrule meets that grip.
    for y in range(11, 21):
        for x in range(36, 47):
            r, g, b, alpha = pose.getpixel((x, y))
            if alpha and max(r, g, b) - min(r, g, b) < 45 and r > 70:
                pose.putpixel((x, y), (0, 0, 0, 0))
    return pose


def jala_tool() -> Image.Image:
    tool = Image.new("RGBA", (20, 20))
    d = ImageDraw.Draw(tool)
    dark = (44, 37, 35, 255)
    copper = (155, 91, 49, 255)
    brass = (224, 177, 88, 255)
    cyan = (73, 214, 211, 255)
    d.line([(6, 19), (7, 13)], fill=dark, width=3)
    d.line([(6, 19), (7, 13)], fill=copper, width=1)
    # The hoop uses a closed, stepped pixel contour rather than a blurred oval.
    hoop = [(2, 5), (4, 2), (10, 1), (15, 3), (17, 7), (16, 12),
            (12, 15), (6, 15), (2, 12), (1, 8), (2, 5)]
    d.line(hoop, fill=dark, width=3, joint="curve")
    d.line(hoop, fill=brass, width=1, joint="curve")
    for x1, y1, x2, y2 in [(4, 4, 14, 12), (3, 8, 11, 14),
                           (8, 2, 16, 9), (14, 4, 4, 13), (10, 2, 2, 9)]:
        d.line([(x1, y1), (x2, y2)], fill=cyan, width=1)
    return tool


def beno_jala() -> Image.Image:
    pose = beno_empty()
    pose.alpha_composite(jala_tool(), (36, 6))
    # Fingers stay in front of the ferrule, so the handle has a visible grip.
    source = Image.open(SOURCE).convert("RGBA")
    hand = source.crop((40, 20, 46, 29))
    pose.alpha_composite(hand, (40, 20))
    return pose


def smarapedia() -> Image.Image:
    image = Image.new("RGBA", (48, 32))
    d = ImageDraw.Draw(image)
    edge = (49, 31, 24, 255)
    wood = (94, 53, 37, 255)
    copper = (180, 112, 56, 255)
    parchment = (239, 209, 150, 255)
    ink = (59, 57, 45, 255)
    d.rectangle((4, 5, 44, 29), fill=edge)
    d.rectangle((6, 7, 42, 27), fill=wood)
    d.rectangle((8, 9, 40, 25), fill=parchment)
    d.line([(24, 8), (24, 26)], fill=edge, width=2)
    d.line([(9, 11), (20, 11)], fill=ink, width=1)
    d.line([(9, 14), (19, 14)], fill=ink, width=1)
    d.line([(28, 11), (39, 11)], fill=ink, width=1)
    d.line([(29, 14), (38, 14)], fill=ink, width=1)
    d.polygon([(17, 20), (22, 17), (25, 20), (21, 23)], fill=copper)
    for x in [5, 40]:
        d.rectangle((x, 5, x + 4, 8), fill=copper)
        d.rectangle((x, 26, x + 4, 29), fill=copper)
    return image


if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    for name, art in [("beno-jala-offer.png", beno_jala()),
                      ("beno-empty-offer.png", beno_empty()),
                      ("jala-tool.png", jala_tool()),
                      ("smarapedia-open.png", smarapedia())]:
        path = OUT / name
        art.save(path, optimize=False)
        print(name, sha256(path.read_bytes()).hexdigest())
