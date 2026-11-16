#!/usr/bin/env python3
"""CPU checks for the restored Gajah Mina atlas and its provenance."""

import hashlib
import json
from collections import deque
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
ART = ROOT / "client-godot/resources/art/gajah-mina-motion-v2-healed"
ORIGINAL = ROOT / "client-godot/resources/art/gajah-mina.png"
CELL = (224, 160)
FRAMES = 12


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def count_components(alpha: Image.Image) -> tuple[int, int]:
    width, height = alpha.size
    values = alpha.load()
    seen = bytearray(width * height)
    components = []
    for y in range(height):
        for x in range(width):
            idx = y * width + x
            if seen[idx] or values[x, y] < 128:
                continue
            seen[idx] = 1
            queue = deque([(x, y)])
            count = 0
            while queue:
                px, py = queue.popleft()
                count += 1
                for ny in range(max(0, py - 1), min(height, py + 2)):
                    for nx in range(max(0, px - 1), min(width, px + 2)):
                        ni = ny * width + nx
                        if not seen[ni] and values[nx, ny] >= 128:
                            seen[ni] = 1
                            queue.append((nx, ny))
            components.append(count)
    return len(components), max(components, default=0)


def purple_pixels(image: Image.Image) -> int:
    return sum(
        1 for red, green, blue, alpha in image.getdata()
        if alpha > 127 and red > green * 1.15 and blue > green * 1.22 and blue > red * .70
    )


def main() -> None:
    manifest = json.loads((ART / "manifest.json").read_text())
    source = ROOT / manifest["healedStillSource"]
    base = ROOT / manifest["healedBase"]
    assert manifest["sourceSha256"] == sha256(ORIGINAL)
    assert manifest["healedStillSourceSha256"] == sha256(source)
    assert manifest["healedBaseSha256"] == sha256(base)
    assert manifest["swimSha256"] == sha256(ART / "swim.png")
    assert manifest["cellSize"] == list(CELL) and manifest["frames"] == FRAMES

    old = Image.open(ORIGINAL).convert("RGBA").resize((192, 128), Image.Resampling.NEAREST)
    new = Image.open(base).convert("RGBA")
    old_alpha = [alpha >= 128 for alpha in old.getchannel("A").getdata()]
    new_alpha = [alpha >= 128 for alpha in new.getchannel("A").getdata()]
    union = sum(a or b for a, b in zip(old_alpha, new_alpha))
    iou = sum(a and b for a, b in zip(old_alpha, new_alpha)) / union
    assert iou >= .95, f"silhouette drift: {iou:.3f}"
    purple_old, purple_new = purple_pixels(old), purple_pixels(new)
    assert purple_new <= purple_old * .1, f"purple residue remains: {purple_new}/{purple_old}"

    atlas = Image.open(ART / "swim.png").convert("RGBA")
    assert atlas.size == (CELL[0] * FRAMES, CELL[1])
    alpha_frames = []
    areas = []
    for frame in range(FRAMES):
        crop = atlas.crop((frame * CELL[0], 0, (frame + 1) * CELL[0], CELL[1]))
        alpha = crop.getchannel("A")
        count, area = count_components(alpha)
        assert count == 1, f"detached body fragment at frame {frame}: {count} components"
        assert area > 12000, f"missing anatomy at frame {frame}: {area} pixels"
        alpha_frames.append([pixel >= 128 for pixel in alpha.getdata()])
        areas.append(area)
    step_diffs = [sum(a != b for a, b in zip(alpha_frames[i], alpha_frames[(i + 1) % FRAMES])) for i in range(FRAMES)]
    seam_ratio = step_diffs[-1] / (sum(step_diffs[:-1]) / (FRAMES - 1))
    assert seam_ratio < 1.6, f"loop seam jump: {seam_ratio:.2f}x"
    assert max(areas) - min(areas) < 180, f"frame-area jump: {min(areas)}..{max(areas)}"
    print(json.dumps({
        "status": "PASS", "source": manifest["healedStillSource"],
        "sourceSha256": manifest["healedStillSourceSha256"],
        "atlasSha256": manifest["swimSha256"], "alphaIoU": round(iou, 4),
        "purplePixels": {"original": purple_old, "healed": purple_new},
        "componentsEveryFrame": 1, "frameAreaRange": [min(areas), max(areas)],
        "stepAlphaDifferences": step_diffs, "loopSeamRatio": round(seam_ratio, 3),
    }, indent=2))


if __name__ == "__main__":
    main()
