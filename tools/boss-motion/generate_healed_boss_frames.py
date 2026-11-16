#!/usr/bin/env python3
"""Turn the curated healed Gajah Mina still into a jointed 12-frame pixel atlas."""

import hashlib
import json
import math
from collections import deque
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

import generate_boss_frames as motion

ROOT = Path(__file__).resolve().parents[2]
ORIGINAL = ROOT / "client-godot/resources/art/gajah-mina.png"
HEALED_SOURCE = ROOT / "assets/source-2d/gajah-mina-healed/healed-still-source.png"
BASE = ROOT / "assets/source-2d/gajah-mina-healed/healed-base-native.png"
OUT = ROOT / "client-godot/resources/art/gajah-mina-motion-v2-healed"
SIZE = motion.SIZE
PADDING = motion.PADDING


def healed_art() -> Image.Image:
    """Point-sample one curated still; alpha cleanup remains on the native grid."""
    art = Image.open(HEALED_SOURCE).convert("RGBA").resize(motion.ART_SIZE, Image.Resampling.NEAREST)
    pixels = art.load()
    for y in range(art.height):
        for x in range(art.width):
            red, green, blue, alpha = pixels[x, y]
            # Keep the new alpha silhouette crisp and prevent dark partial-alpha
            # pixels from becoming a rectangular halo on the teal boss plate.
            pixels[x, y] = (red, green, blue, 0 if alpha < 128 else 255)
    return art


def make_strip(art: Image.Image) -> Image.Image:
    original = Image.new("RGBA", SIZE)
    original.alpha_composite(art, (PADDING, PADDING))
    masks = Image.new("L", SIZE)
    parts = []
    for name, polygon, pivot, amount in motion.PARTS:
        padded_polygon = [(x + PADDING, y + PADDING) for x, y in polygon]
        padded_pivot = (pivot[0] + PADDING, pivot[1] + PADDING)
        part, part_mask = motion.layer(original, padded_polygon)
        parts.append((name, part, padded_pivot, amount))
        masks = Image.frombytes("L", SIZE, bytes(max(a, b) for a, b in zip(masks.tobytes(), part_mask.tobytes())))
    body = original.copy()
    body.putalpha(Image.frombytes("L", SIZE, bytes(0 if m else a for a, m in zip(original.getchannel("A").tobytes(), masks.tobytes()))))
    seam = masks.filter(ImageFilter.MaxFilter(9))
    underlay = original.copy()
    underlay.putalpha(Image.frombytes("L", SIZE, bytes(a if s and not m else 0 for a, s, m in zip(original.getchannel("A").tobytes(), seam.tobytes(), masks.tobytes()))))
    hinge = Image.new("RGBA", SIZE)
    for name, part, pivot, _ in parts:
        radius = 15 if name in {"tail", "front_fin"} else 11
        hinge_mask = Image.new("L", SIZE)
        ImageDraw.Draw(hinge_mask).ellipse((pivot[0] - radius, pivot[1] - radius, pivot[0] + radius, pivot[1] + radius), fill=255)
        joint = part.copy()
        joint.putalpha(Image.frombytes("L", SIZE, bytes(min(a, b) for a, b in zip(part.getchannel("A").tobytes(), hinge_mask.tobytes()))))
        hinge.alpha_composite(joint)
    strip = Image.new("RGBA", (SIZE[0] * motion.FRAME_COUNT, SIZE[1]))
    for frame in range(motion.FRAME_COUNT):
        phase = frame * math.tau / motion.FRAME_COUNT
        canvas = Image.new("RGBA", SIZE)
        canvas.alpha_composite(underlay)
        canvas.alpha_composite(body)
        canvas.alpha_composite(hinge)
        for name, part, pivot, amount in parts:
            offset = {"tail": 0.0, "front_fin": 1.3, "rear_fin": 2.1, "upper_fin": 0.6, "head": 0.2}[name]
            canvas.alpha_composite(motion.rotated(part, pivot, math.sin(phase + offset) * amount))
        _drop_isolated_fragments(canvas)
        strip.alpha_composite(canvas, (frame * SIZE[0], 0))
    return strip


def _drop_isolated_fragments(frame: Image.Image) -> None:
    alpha = frame.getchannel("A")
    pixels = alpha.load()
    seen = bytearray(frame.width * frame.height)
    for y in range(frame.height):
        for x in range(frame.width):
            idx = y * frame.width + x
            if seen[idx] or pixels[x, y] < 128:
                continue
            seen[idx] = 1
            component = [(x, y)]
            queue = deque(component)
            while queue:
                px, py = queue.popleft()
                for ny in range(max(0, py - 1), min(frame.height, py + 2)):
                    for nx in range(max(0, px - 1), min(frame.width, px + 2)):
                        ni = ny * frame.width + nx
                        if not seen[ni] and pixels[nx, ny] >= 128:
                            seen[ni] = 1
                            queue.append((nx, ny))
                            component.append((nx, ny))
            if len(component) < 64:
                for px, py in component:
                    pixels[px, py] = 0
    frame.putalpha(alpha)


def generate() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    art = healed_art()
    art.save(BASE, optimize=True)
    make_strip(art).save(OUT / "swim.png", optimize=True)
    (OUT / "manifest.json").write_text(json.dumps({
        "source": str(ORIGINAL.relative_to(ROOT)),
        "sourceSha256": hashlib.sha256(ORIGINAL.read_bytes()).hexdigest(),
        "healedStillSource": str(HEALED_SOURCE.relative_to(ROOT)),
        "healedStillSourceSha256": hashlib.sha256(HEALED_SOURCE.read_bytes()).hexdigest(),
        "healedBase": str(BASE.relative_to(ROOT)),
        "method": "curated single-still edit, native-grid alpha cleanup, original hinged cutouts and nearest-neighbor sinusoidal motion",
        "cellSize": list(SIZE), "artSize": list(motion.ART_SIZE), "frames": motion.FRAME_COUNT,
        "parts": [part[0] for part in motion.PARTS],
        "healedBaseSha256": hashlib.sha256(BASE.read_bytes()).hexdigest(),
        "swimSha256": hashlib.sha256((OUT / "swim.png").read_bytes()).hexdigest(),
    }, indent=2) + "\n")


if __name__ == "__main__":
    generate()
