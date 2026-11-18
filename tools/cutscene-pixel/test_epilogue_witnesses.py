"""CPU checks for the authored witness portraits and held dacin."""

from hashlib import sha256

from PIL import Image

from author_epilogue_witnesses import OUTPUT, SOURCE, SOURCE_SHA, build


def test_source_pin() -> None:
    assert sha256(SOURCE.read_bytes()).hexdigest() == SOURCE_SHA


def test_outputs_rebuild_identically() -> None:
    for name, image in build().items():
        assert image.size == (192, 192)
        assert image.mode == "RGBA"
        assert image.tobytes() == Image.open(OUTPUT / name).convert("RGBA").tobytes()


def test_scale_touches_hand_and_beam() -> None:
    ratih = build()["mbok-ratih-dacin.png"]
    for point in [(137, 70), (144, 69), (148, 77), (137, 78), (135, 99), (158, 99)]:
        assert ratih.getpixel(point)[3] == 255, point
    assert ratih.getpixel((155, 56))[3] == 0  # removed plant tip
    assert ratih.getpixel((103, 72))[3] > 0  # source shoulder retained


if __name__ == "__main__":
    test_source_pin()
    test_outputs_rebuild_identically()
    test_scale_touches_hand_and_beam()
    print("EPILOGUE WITNESS ART PASS: source, deterministic outputs, hand-to-dacin pixels")
