"""Author two close witnesses for Raka's confrontation from project-owned art."""

from hashlib import sha256
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "client-godot/resources/art/npc-atlas.png"
OUTPUT = ROOT / "client-godot/resources/art/cinematics-v2/close-pose"
SOURCE_SHA = "82d946a0df5ecb98eb5d4daa48856e8cf36644103b39f80d39d17e361ff56aec"
SIZE = 192


def build() -> dict[str, Image.Image]:
    if sha256(SOURCE.read_bytes()).hexdigest() != SOURCE_SHA:
        raise ValueError("NPC atlas changed; inspect before rebuilding witness art")
    atlas = Image.open(SOURCE).convert("RGBA")
    if atlas.size != (1254, 1254):
        raise ValueError("Unexpected NPC atlas grid")
    ratih = atlas.crop((0, 627, 627, 1254)).resize((SIZE, SIZE), Image.Resampling.NEAREST)
    tedi = atlas.crop((627, 0, 1254, 627)).resize((SIZE, SIZE), Image.Resampling.NEAREST)

    # Ratih's original potted plant is removed on the transparent side of her
    # torso. The shoulder and skirt pixels remain those of the source tile.
    for y in range(45, 96):
        for x in range(119, 166):
            ratih.putpixel((x, y), (0, 0, 0, 0))

    d = ImageDraw.Draw(ratih)
    edge = (56, 37, 30, 255)
    cloth = (231, 208, 169, 255)
    cloth_shadow = (156, 119, 89, 255)
    skin = (194, 112, 64, 255)
    brass = (205, 149, 69, 255)
    brass_light = (247, 197, 98, 255)

    # A bent sleeve and open hand connect the weighing scale to her body.
    d.polygon([(108, 69), (119, 68), (128, 73), (135, 65), (141, 66),
               (141, 75), (132, 83), (120, 83), (110, 78)], fill=edge)
    d.polygon([(111, 70), (119, 70), (128, 77), (135, 69), (138, 70),
               (137, 75), (129, 81), (121, 80), (113, 76)], fill=cloth_shadow)
    d.polygon([(112, 70), (119, 70), (127, 76), (122, 79), (114, 75)], fill=cloth)
    d.line([(116, 71), (124, 77)], fill=(120, 159, 157, 255), width=2)
    d.polygon([(134, 67), (140, 63), (145, 65), (146, 72), (140, 77),
               (135, 75)], fill=edge)
    d.polygon([(137, 68), (142, 66), (144, 68), (143, 72), (139, 74),
               (136, 72)], fill=skin)

    # The dacin hook, beam, two cords, and shallow copper pans are one pixel
    # assembly held at the hand. It replaces the source plant instead of
    # floating beside it.
    d.line([(144, 69), (148, 71), (148, 77)], fill=edge, width=3)
    d.line([(144, 69), (148, 71), (148, 77)], fill=brass_light, width=1)
    d.polygon([(130, 77), (163, 77), (164, 81), (129, 81)], fill=edge)
    d.line([(131, 78), (162, 78)], fill=brass_light, width=2)
    for x in (135, 158):
        d.line([(x, 81), (x - 4, 98)], fill=edge, width=2)
        d.line([(x + 3, 81), (x + 7, 98)], fill=brass, width=1)
        d.polygon([(x - 7, 99), (x + 9, 99), (x + 5, 103), (x - 4, 103)], fill=edge)
        d.line([(x - 6, 99), (x + 8, 99)], fill=brass_light, width=2)
    return {"mbok-ratih-dacin.png": ratih, "kang-tedi-wrench.png": tedi}


if __name__ == "__main__":
    OUTPUT.mkdir(parents=True, exist_ok=True)
    for name, art in build().items():
        target = OUTPUT / name
        art.save(target, optimize=False)
        print(name, sha256(target.read_bytes()).hexdigest())
