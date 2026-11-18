"""CPU checks for Bagas's 96x128 source-grid rear travel view."""

from PIL import Image

from author_bagas_rear_candidate import OUTPUT_DIR, RUNTIME_DIR, SOURCE, author, diagonal


def main() -> None:
    original = Image.open(SOURCE).convert("RGBA").crop((96, 0, 192, 128))
    study = Image.open(OUTPUT_DIR / "bagas-rear-study.png").convert("RGBA")
    candidate = author()
    assert study.size == (96, 128)
    assert candidate.tobytes() == study.tobytes()
    assert candidate.crop((0, 82, 96, 128)).tobytes() == original.crop((0, 82, 96, 128)).tobytes()
    assert original.getpixel((48, 25)) != candidate.getpixel((48, 25))
    assert len({pixel for pixel in candidate.crop((30, 8, 64, 41)).getdata() if pixel[3]}) >= 6
    upper = Image.open(RUNTIME_DIR / "bagas-rear-upper.png").convert("RGBA")
    assert upper.size == (96, 128)
    assert upper.crop((0, 82, 96, 128)).getbbox() is None
    assert upper.getpixel((48, 25)) == candidate.getpixel((48, 25))
    for side in ("nw", "ne"):
        saved = Image.open(OUTPUT_DIR / f"bagas-rear-{side}-study.png").convert("RGBA")
        assert saved.tobytes() == diagonal(candidate, side).tobytes()
        assert saved.crop((0, 82, 96, 128)).tobytes() == original.crop((0, 82, 96, 128)).tobytes()
        variant = Image.open(RUNTIME_DIR / f"bagas-rear-{side}-upper.png").convert("RGBA")
        assert variant.size == (96, 128)
        assert variant.crop((0, 82, 96, 128)).getbbox() is None
        assert variant.getpixel((48, 25)) == saved.getpixel((48, 25))
    assert (OUTPUT_DIR / "bagas-rear-nw-study.png").read_bytes() != (OUTPUT_DIR / "bagas-rear-ne-study.png").read_bytes()
    composed = Image.open(OUTPUT_DIR / "bagas-rear-composed-study.png").convert("RGBA")
    for side, bounds, source_sole in [
        ("left", (30, 111, 45, 120), 37.5),
        ("right", (49, 110, 68, 119), 58.5),
    ]:
        foot = Image.open(RUNTIME_DIR / f"bagas-rear-foot-{side}.png").convert("RGBA")
        assert foot.size == (bounds[2] - bounds[0], bounds[3] - bounds[1])
        assert composed.crop(bounds).tobytes() == foot.tobytes()
        bottom = foot.height - 1
        xs = [x + 0.5 for x in range(foot.width) if foot.getpixel((x, bottom))[3]]
        assert xs
        assert abs(bounds[0] + sum(xs) / len(xs) - source_sole) < 0.001
    print("Bagas north/NW/NE rear grid, original lower-body reference and heel anchors: PASS")


if __name__ == "__main__":
    main()
