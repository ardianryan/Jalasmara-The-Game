"""CPU checks for the source-grid rear-facing Gito study."""

from PIL import Image

from author_gito_rear_candidate import (
    COMPOSED,
    FOOT_LEFT,
    FOOT_RIGHT,
    OUTPUT,
    RUNTIME,
    SOURCE,
    author,
)


def main() -> None:
    original = Image.open(SOURCE).convert("RGBA").crop((96, 128, 192, 256))
    candidate = author()
    assert candidate.size == (96, 128)
    assert candidate.tobytes() == Image.open(OUTPUT).convert("RGBA").tobytes()
    assert candidate.crop((0, 82, 96, 128)).tobytes() == original.crop((0, 82, 96, 128)).tobytes()
    for x, y in ((34, 119), (62, 118)):
        assert original.getpixel((x, y)) == candidate.getpixel((x, y))
        assert candidate.getpixel((x, y))[3] != 0
    head = candidate.crop((31, 8, 61, 41))
    assert len({pixel for pixel in head.getdata() if pixel[3]}) >= 8
    assert original.getpixel((49, 25)) != candidate.getpixel((49, 25))
    upper = Image.open(RUNTIME).convert("RGBA")
    assert upper.size == (96, 128)
    assert upper.crop((0, 82, 96, 128)).getbbox() is None
    assert upper.getpixel((49, 25)) == candidate.getpixel((49, 25))
    composed = Image.open(COMPOSED).convert("RGBA")
    for path, bounds, original_sole in [
        (FOOT_LEFT, (27, 111, 40, 120), 34.0),
        (FOOT_RIGHT, (51, 111, 72, 119), 62.0),
    ]:
        foot = Image.open(path).convert("RGBA")
        assert foot.size == (bounds[2] - bounds[0], bounds[3] - bounds[1])
        assert composed.crop(bounds).tobytes() == foot.tobytes()
        bottom = foot.height - 1
        xs = [x + 0.5 for x in range(foot.width) if foot.getpixel((x, bottom))[3]]
        assert xs
        sole = bounds[0] + sum(xs) / len(xs)
        assert abs(sole - original_sole) <= 0.5
    print("Gito rear source-grid and unchanged foot contact: PASS")


if __name__ == "__main__":
    main()
