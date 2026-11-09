#!/usr/bin/env python3
"""Derive flat-floor speed units from the current controller and camera sources."""
import hashlib
import json
import math
from pathlib import Path
import re

root = Path(__file__).resolve().parents[2]
paths = {
    'renderer': root / 'client-godot/scripts/land/LandWorld3D.gd',
    'controller': root / 'client-godot/scripts/Player.gd',
    'planner': root / 'client-godot/scripts/NalaFootPlant.gd',
    'projection': root / 'client-godot/scripts/land/LandViewProjection.gd',
    'camera': root / 'client-godot/scripts/land/LandCameraPose.gd',
}
sources = {name: path.read_text() for name, path in paths.items()}


def number(name, pattern):
    match = re.search(pattern, sources[name])
    if not match:
        raise SystemExit(f'Unsupported source pattern: {name}: {pattern}')
    return float(match[1])


tilt = math.radians(number('renderer', r'const TILT := deg_to_rad\(([\d.]+)\)'))
azimuth = math.radians(number('renderer', r'var camera_azimuth := (-?[\d.]+)'))
elevation = math.radians(number('renderer', r'var camera_elevation := ([\d.]+)'))
speed = number('controller', r'const LAND_WALK_SPEED := ([\d.]+)')
step = number('planner', r'const STEP_DISTANCE := ([\d.]+)')
outward = (math.sin(azimuth) * math.cos(elevation), -math.cos(azimuth) * math.cos(elevation), math.sin(elevation))
forward = tuple(-value for value in outward)
right = (forward[1], -forward[0], 0)
length = math.hypot(*right)
right = tuple(value / length for value in right)
up = (right[1] * forward[2], -right[0] * forward[2], right[0] * forward[1] - right[1] * forward[0])
cos_tilt = math.cos(tilt)
matrix = ((right[0], -right[1] / cos_tilt), (-up[0], up[1] / cos_tilt))
determinant = matrix[0][0] * matrix[1][1] - matrix[1][0] * matrix[0][1]
assert abs(determinant) > 1e-6
rows = []
for heading in range(8):
    screen = (math.cos(heading * math.pi / 4), math.sin(heading * math.pi / 4))
    logical = ((screen[0] * matrix[1][1] - matrix[0][1] * screen[1]) / determinant,
               (matrix[0][0] * screen[1] - screen[0] * matrix[1][0]) / determinant)
    factor = speed / math.hypot(*logical)
    logical = tuple(value * factor for value in logical)
    physical = math.hypot(logical[0], logical[1] / cos_tilt)
    projected = (matrix[0][0] * logical[0] + matrix[0][1] * logical[1],
                 matrix[1][0] * logical[0] + matrix[1][1] * logical[1])
    assert abs(projected[0] * screen[1] - projected[1] * screen[0]) < 1e-6
    rows.append({'screenHeading': heading, 'logicalVelocity': logical, 'worldXYSpeed': physical,
                 'projectedViewSpeed': math.hypot(*projected), 'plannerContactsPerSecond': physical / step})

print(json.dumps({
    'scope': 'Independent CPU derivation, steady flat floor. Not a measured engine/native result.',
    'sourceHashes': {str(path.relative_to(root)): hashlib.sha256(path.read_bytes()).hexdigest() for path in paths.values()},
    'logicalSpeed': speed, 'stepWorldDistance': step, 'right': right, 'up': up,
    'logicalHeadingWorldSpeedBounds': [speed, speed / cos_tilt], 'screenHeadings': rows,
}, indent=2))
