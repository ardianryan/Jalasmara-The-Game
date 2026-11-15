"""Build compact, source-matched swim poses from the project's modular portraits."""

from pathlib import Path
import hashlib
import json

from PIL import Image


ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "client-godot/resources/art"
DEST = SOURCE / "player-swim-v2"
APPEARANCES = ("male-default", "female-default", "male-nusantara", "female-nusantara")
CELL = 112


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def build_one(name: str) -> dict[str, str]:
    source = SOURCE / f"{name}-base-v1.png"
    original = Image.open(source).convert("RGBA")
    width = original.width // 3
    height = original.height // 3
    strip = Image.new("RGBA", (CELL * 3, CELL))
    for pose in range(3):
        crop = original.crop((pose * width, height, (pose + 1) * width, height * 2))
        strip.paste(crop.resize((CELL, CELL), Image.Resampling.LANCZOS), (pose * CELL, 0))
    alpha = strip.getchannel("A").point(lambda value: 255 if value >= 128 else 0)
    # One shared palette keeps adjacent poses from changing color during a kick.
    strip = strip.convert("RGB").quantize(colors=64, dither=Image.Dither.NONE).convert("RGBA")
    strip.putalpha(alpha)
    destination = DEST / f"{name}.png"
    strip.save(destination, optimize=True)
    return {"source": str(source.relative_to(ROOT)), "sourceSha256": digest(source),
            "output": str(destination.relative_to(ROOT)), "outputSha256": digest(destination)}


def main() -> None:
    DEST.mkdir(parents=True, exist_ok=True)
    entries = {name: build_one(name) for name in APPEARANCES}
    (DEST / "provenance.json").write_text(json.dumps({"kind": "project-source-downsample", "cell": CELL,
        "paletteColors": 64, "frames": 3, "entries": entries}, indent=2) + "\n")


if __name__ == "__main__":
    main()
