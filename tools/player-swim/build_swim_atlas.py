"""Build compact, source-matched swim poses from the project's modular portraits."""

from pathlib import Path
import hashlib
import json

from PIL import Image, ImageDraw, ImageEnhance


ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "client-godot/resources/art"
DEST = SOURCE / "player-swim-v2"
APPEARANCES = ("male-default", "female-default", "male-nusantara", "female-nusantara")
CELL = 112
PALETTE_COLORS = 28
SOURCE_POSES = (0, 0, 1, 1, 2, 2, 1, 0)
FIN_FLEX = (0, -2, 0, 2, 0, -2, -2, 2)


def _flex_fin_tips(frame: Image.Image, amount: int) -> Image.Image:
    """Bend only the free end of the fins; the leg roots and body stay fixed."""
    if amount == 0:
        return frame.copy()
    bent = frame.copy()
    src = frame.load()
    dst = bent.load()
    for x in range(36):
        shift = round(amount * (36 - x) / 36)
        if shift == 0:
            continue
        for y in range(CELL):
            dst[x, y] = src[x, y - shift] if 0 <= y - shift < CELL else (0, 0, 0, 0)
    return bent


def _visor(frame: Image.Image, name: str, pose: int) -> None:
    """Draw a small, readable diving mask on the original face pixels."""
    # These anchors were measured from the four source portraits at 112 px.
    anchors = {
        "male-nusantara": (78, 39),
        "female-nusantara": (79, 39),
        "male-default": (78, 39),
        "female-default": (79, 39),
    }
    x, y = anchors[name]
    # The head shifts by at most a pixel among the three source swim poses.
    x += (0, 1, 0)[pose]
    draw = ImageDraw.Draw(frame)
    ink = (24, 42, 49, 255)
    copper = (172, 107, 61, 255)
    glass = (54, 170, 181, 255)
    shine = (167, 240, 221, 255)
    draw.line((x - 3, y + 1, x - 1, y + 1), fill=copper, width=1)
    draw.rectangle((x, y, x + 6, y + 3), fill=ink)
    draw.rectangle((x + 1, y + 1, x + 5, y + 2), fill=glass)
    draw.line((x + 2, y + 1, x + 3, y + 1), fill=shine, width=1)
    draw.point((x + 6, y + 3), fill=copper)


def _largest_silhouette(frame: Image.Image) -> Image.Image:
    """Discard isolated upscaling specks without eroding the character."""
    alpha = frame.getchannel("A")
    pixels = alpha.load()
    seen = set()
    components = []
    for y in range(CELL):
        for x in range(CELL):
            if pixels[x, y] == 0 or (x, y) in seen:
                continue
            component = set()
            queue = [(x, y)]
            seen.add((x, y))
            while queue:
                cx, cy = queue.pop()
                component.add((cx, cy))
                for nx, ny in ((cx - 1, cy), (cx + 1, cy), (cx, cy - 1), (cx, cy + 1)):
                    if 0 <= nx < CELL and 0 <= ny < CELL and pixels[nx, ny] and (nx, ny) not in seen:
                        seen.add((nx, ny))
                        queue.append((nx, ny))
            components.append(component)
    if not components:
        return frame
    keep = max(components, key=len)
    for y in range(CELL):
        for x in range(CELL):
            if (x, y) not in keep:
                pixels[x, y] = 0
    frame.putalpha(alpha)
    return frame


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def build_one(name: str) -> dict[str, str]:
    source = SOURCE / f"{name}-base-v1.png"
    original = Image.open(source).convert("RGBA")
    width = original.width // 3
    height = original.height // 3
    frames = []
    for pose in range(3):
        crop = original.crop((pose * width, height, (pose + 1) * width, height * 2))
        frames.append(crop.resize((CELL, CELL), Image.Resampling.LANCZOS))
    combined = Image.new("RGBA", (CELL * 3, CELL))
    for pose, frame in enumerate(frames):
        combined.paste(frame, (pose * CELL, 0))
    # A single compact palette prevents shirt/skin colors from shifting per pose.
    rgb = ImageEnhance.Contrast(combined.convert("RGB")).enhance(1.13)
    rgb = rgb.quantize(colors=PALETTE_COLORS, dither=Image.Dither.NONE).convert("RGBA")
    clean_frames = []
    for pose, frame in enumerate(frames):
        pixel = rgb.crop((pose * CELL, 0, (pose + 1) * CELL, CELL))
        alpha = frame.getchannel("A").point(lambda value: 255 if value >= 175 else 0)
        alpha.paste(0, (0, 0, CELL, 3))
        pixel.putalpha(alpha)
        pixel = _largest_silhouette(pixel)
        _visor(pixel, name, pose)
        clean_frames.append(pixel)
    strip = Image.new("RGBA", (CELL * len(SOURCE_POSES), CELL))
    for index, (pose, flex) in enumerate(zip(SOURCE_POSES, FIN_FLEX)):
        strip.paste(_flex_fin_tips(clean_frames[pose], flex), (index * CELL, 0))
    destination = DEST / f"{name}.png"
    strip.save(destination, optimize=True)
    return {"source": str(source.relative_to(ROOT)), "sourceSha256": digest(source),
            "output": str(destination.relative_to(ROOT)), "outputSha256": digest(destination)}


def main() -> None:
    DEST.mkdir(parents=True, exist_ok=True)
    entries = {name: build_one(name) for name in APPEARANCES}
    (DEST / "provenance.json").write_text(json.dumps({"kind": "project-source-pixel-cleanup", "cell": CELL,
        "paletteColors": PALETTE_COLORS, "alphaThreshold": 175,
        "artwork": "code-drawn diving visor; source silhouette retained",
        "frames": len(SOURCE_POSES), "sourcePoseOrder": SOURCE_POSES,
        "finTipFlexPx": FIN_FLEX, "entries": entries}, indent=2) + "\n")


if __name__ == "__main__":
    main()
