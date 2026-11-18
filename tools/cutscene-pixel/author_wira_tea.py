"""Build Wira's counter gesture from Jalasmara's original character tile."""

from hashlib import sha256
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "client-godot/resources/art/npc-atlas.png"
OUTPUT = ROOT / "client-godot/resources/art/cinematics-v2/close-pose/mbah-wira-tea-offer.png"
SOURCE_SHA = "82d946a0df5ecb98eb5d4daa48856e8cf36644103b39f80d39d17e361ff56aec"
SIZE = 192


def build() -> Image.Image:
    if sha256(SOURCE.read_bytes()).hexdigest() != SOURCE_SHA:
        raise ValueError("Wira source art changed; inspect the new tile before rebuilding")
    atlas = Image.open(SOURCE).convert("RGBA")
    assert atlas.size == (1254, 1254)
    pose = atlas.crop((0, 0, 627, 627)).resize((SIZE, SIZE), Image.Resampling.NEAREST)

    # The hanging brass forearm is replaced by one connected, raised arm.
    # Body and cloth pixels on the left of this narrow cut remain untouched.
    for y in range(93, 140):
        for x in range(130, 151):
            if pose.getpixel((x, y))[3]:
                apron_edge = min(146, 140 + max(0, y - 105) // 6)
                replacement = pose.getpixel((123 + (x % 3), y)) if x <= apron_edge and y >= 102 else (0, 0, 0, 0)
                pose.putpixel((x, y), replacement)

    d = ImageDraw.Draw(pose)
    edge = (42, 30, 29, 255)
    cloth_shadow = (65, 53, 57, 255)
    cloth = (130, 103, 76, 255)
    cloth_light = (199, 159, 113, 255)
    brass_shadow = (101, 65, 34, 255)
    brass = (191, 139, 56, 255)
    brass_light = (248, 198, 92, 255)
    skin = (197, 117, 66, 255)
    tea = (75, 144, 105, 255)

    # The upper arm starts inside the existing striped sleeve; the elbow bends
    # toward the guest, and the open metal glove supports the cup from below.
    d.polygon([(126, 84), (136, 83), (143, 89), (147, 93), (153, 89),
               (158, 92), (158, 101), (150, 108), (139, 106), (130, 100)], fill=edge)
    d.polygon([(128, 85), (135, 85), (141, 91), (145, 97), (153, 94),
               (156, 95), (155, 101), (148, 105), (139, 103), (131, 97)], fill=cloth_shadow)
    d.polygon([(130, 86), (135, 86), (139, 91), (142, 95), (135, 96),
               (130, 92)], fill=cloth)
    d.line([(130, 86), (136, 87), (140, 91)], fill=cloth_light, width=2)
    d.polygon([(146, 95), (154, 91), (160, 90), (164, 95), (162, 104),
               (153, 108), (148, 105)], fill=brass_shadow)
    d.polygon([(151, 95), (159, 93), (162, 96), (160, 102), (154, 105),
               (150, 102)], fill=brass)
    d.line([(153, 95), (159, 94), (161, 97)], fill=brass_light, width=2)
    d.rectangle((157, 91, 159, 95), fill=skin)

    # Cup, rim, handle, tea surface, and two single-pixel steam curls are
    # authored on this grid. The base overlaps the hand so nothing floats.
    d.polygon([(153, 75), (171, 75), (170, 91), (166, 97), (158, 97),
               (154, 92)], fill=edge)
    d.polygon([(155, 78), (169, 78), (168, 90), (165, 94), (158, 94),
               (156, 90)], fill=(147, 96, 51, 255))
    d.rectangle((155, 76, 170, 79), fill=brass_light)
    d.line([(157, 77), (168, 77)], fill=tea, width=1)
    d.arc((166, 79, 179, 94), 270, 90, fill=brass_light, width=2)
    d.line([(160, 73), (159, 70), (161, 67), (160, 64)], fill=(216, 219, 174, 255), width=1)
    d.line([(166, 73), (167, 70), (165, 67)], fill=(216, 219, 174, 255), width=1)
    return pose


if __name__ == "__main__":
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    build().save(OUTPUT, optimize=False)
    print(sha256(OUTPUT.read_bytes()).hexdigest())
