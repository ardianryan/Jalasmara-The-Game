#!/usr/bin/env python3
"""Verify reviewed original front-hand pixels before assigning an upper gait phase."""
import hashlib
import json
from pathlib import Path
from PIL import Image

root = Path(__file__).resolve().parents[2]
data = json.loads(Path(__file__).with_name('upper_arm_annotations.json').read_text())
assert len(data['unverifiedViews']) == 7
marks = 0
for outfit, source in data['sources'].items():
    path = root / source['path']
    assert hashlib.sha256(path.read_bytes()).hexdigest() == source['sha256'], (outfit, 'Source changed; inspect again')
    image = Image.open(path).convert('RGBA')
    for frame, annotation in source['frames'].items():
        for side in ('left', 'right'):
            x, y = annotation[side + 'PalmPixel']
            actual = image.getpixel((int(frame) * 128 + x, source['row'] * 128 + y))
            assert list(actual) == annotation[side + 'PalmRgba'], (outfit, frame, side, actual)
            assert actual[3] == 255
            assert x > 64 if side == 'left' else x < 64
            marks += 1
    for contact, frame in data['proposedUpperFrameAtContact'].items():
        expected = 'right' if contact == 'left' else 'left'
        assert source['frames'][str(frame)]['forwardArm'] == expected
print(f'UPPER PHASE SOURCE PASS: {marks} original opaque palm marks; front only. Seven other views, runtime phase and native gait NOT accepted.')
