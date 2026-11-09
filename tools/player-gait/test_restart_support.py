"""Compare annotated support displacement before handover; no runtime/anatomy certification."""
import argparse
import hashlib
import json
import math
import re
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
ART = ROOT / "client-godot/resources/art/player-gait"
META = json.loads(Path(__file__).with_name("restart-support-east.json").read_text())


def support_trace(points, initial, samples, frame, angle=0.0):
    positions = [(0.0, 0.0)]
    for distance in samples:
        point = points[str(frame)]
        positions.append((distance * math.cos(angle) + point[0] - initial[0], distance * math.sin(angle) + point[1] - initial[1]))
    steps = [math.dist(a, b) for a, b in zip(positions, positions[1:])]
    return {"maxStep": max(steps), "totalDrift": sum(steps)}


def camera_scale(azimuth=-45.0, elevation=35.0, angle=0.0):
    # LandCameraPose / LandViewProjection flat-plane inverse for screen-right input.
    az, el = math.radians(azimuth), math.radians(elevation)
    c = math.cos(math.radians(55.0))
    col_x = (math.cos(az), math.sin(az) * math.sin(el))
    col_y = (-math.sin(az) / c, math.cos(az) * math.sin(el) / c)
    determinant = col_x[0] * col_y[1] - col_x[1] * col_y[0]
    direction = (math.cos(angle), math.sin(angle))
    logical = ((direction[0] * col_y[1] - direction[1] * col_y[0]) / determinant,
               (col_x[0] * direction[1] - col_x[1] * direction[0]) / determinant)
    length = math.hypot(*logical)
    return math.hypot(col_x[0] * logical[0] + col_y[0] * logical[1], col_x[1] * logical[0] + col_y[1] * logical[1]) / length


def paths(start=24.0, scale=None):
    scale = camera_scale() if scale is None else scale
    for hz in (30, 60, 120):
        speed, travel, samples = 0.0, start, []
        while True:
            speed = min(175.0, speed + 850.0 / hz)
            travel += speed / hz
            if travel >= 32:
                break
            samples.append((travel - start) * scale)
        yield f"acceleration850/{hz}Hz", samples
    yield "component100/50Hz", [step * scale for step in (2, 4, 6) if start + step < 32]
    for first in (.125, .5, 1.0, 2.0, 3.0, 4.0):
        for later in (.125, .75, 2.0, 5.0):
            samples, distance = [], first
            while distance < (32 - start) * scale:
                samples.append(distance)
                distance += later
            yield f"view-step-{first}/{later}", samples


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    renderer = (ROOT / "client-godot/scripts/land/LandWorld3D.gd").read_text()
    azimuth = float(re.search(r"var camera_azimuth := (-?[\d.]+)", renderer)[1])
    elevation = float(re.search(r"var camera_elevation := ([\d.]+)", renderer)[1])
    assert (azimuth, elevation) == (-45.0, 35.0), "Review the source-mark projection when the gameplay camera changes"
    evidence = {"schemaVersion": 2, "kind": "CPU source-mark model; not runtime", "camera": {"azimuth": azimuth, "elevation": elevation, "embeddingTilt": 55}, "checks": [], "unchangedContactCrossings": 0}
    sheet = Image.new("RGB", (900, 460), "#263b40")
    draw = ImageDraw.Draw(sheet)
    for row, (outfit, spec) in enumerate(META["outfits"].items()):
        textures = {}
        for kind in ("idle", "walk"):
            path = ART / f"male-nusantara-{outfit}-{kind}-8way-v1.png"
            assert hashlib.sha256(path.read_bytes()).hexdigest() == spec[kind + "Sha256"]
            textures[kind] = Image.open(path).convert("RGBA")
        for column, (pose, marks) in enumerate(spec["poses"].items()):
            offset = 0 if pose == "idle" else int(pose) * 128
            image = textures["idle" if pose == "idle" else "walk"].crop((offset, 0, offset + 128, 128))
            crop = image.crop((38, 75, 92, 108)).resize((270, 165), Image.Resampling.NEAREST)
            x, y = column * 300, row * 230
            sheet.paste(crop, (x, y + 30), crop)
            draw.text((x + 5, y + 8), f"{outfit} {pose}: source east, physical L/R unassigned", fill="white")
            for name, point in marks.items():
                assert image.getpixel(tuple(point))[3] == 255, (outfit, pose, name, point)
                px, py = x + (point[0] - 38) * 5 + 2, y + 30 + (point[1] - 75) * 5 + 2
                color = "#72efcf" if name == "heel" else "#ffd56a"
                draw.line((px - 4, py, px + 4, py), fill=color)
                draw.line((px, py - 4, px, py + 4), fill=color)
                draw.text((x + 5, y + 200 + (12 if name == "toe" else 0)), f"{name} {point}", fill=color)
        for name in ("heel", "toe"):
            points = {pose: marks[name] for pose, marks in spec["poses"].items()}
            for start in (24, 24.125, 24.5, 25, 26, 27, 28, 29, 30, 31, 31.5, 31.875):
                for angle in (-math.asin(.01), 0.0, math.asin(.01)):
                    scale = camera_scale(azimuth, elevation, angle)
                    for label, samples in paths(start, scale):
                        if not samples:
                            # The first update already reaches contact32: runtime uses raw pose.
                            evidence["unchangedContactCrossings"] += 1
                            continue
                        assert samples[0] <= 4.0
                        assert samples[-1] < (32 - start) * scale
                        baseline = support_trace(points, points["idle"], samples, 3, angle)
                        candidate = support_trace(points, points["idle"], samples, 2, angle)
                        case = (outfit, name, start, angle, label)
                        assert candidate["maxStep"] <= baseline["maxStep"] + 1e-8, case
                        assert candidate["totalDrift"] <= baseline["totalDrift"] + 1e-8, case
                        evidence["checks"].append({"outfit": outfit, "mark": name, "startDistance": start, "viewAngle": angle, "path": label, "baseline": baseline, "candidate": candidate})
    if args.output:
        args.output.mkdir(parents=True, exist_ok=True)
        sheet.save(args.output / "annotated-support-east.png")
        (args.output / "support-model.json").write_text(json.dumps(evidence, indent=2) + "\n")
    print(f"RESTART SUPPORT MODEL PASS: {len(evidence['checks'])} toe/heel traces; camera{azimuth}/{elevation},12 stopped phases in raw3,3 near-east headings, first view step <=4, before raw32 handover; {evidence['unchangedContactCrossings']} unchanged crossings. No zero-slide/physical L-R assertion.")


if __name__ == "__main__":
    main()
