#!/usr/bin/env python3
"""Source-grid and gating checks for the future-world art package."""
import hashlib
import json
import unittest
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
ASSETS = ROOT / 'client-godot/resources/art/future-world-v1'
MANIFEST = json.loads((ASSETS / 'manifest.json').read_text())


class FutureWorldArtTest(unittest.TestCase):
    def test_all_manifest_pixels_match_source_contract(self):
        self.assertEqual(len(MANIFEST['assets']), 13)
        for name, spec in MANIFEST['assets'].items():
            with self.subTest(name=name):
                path = ASSETS / f'{name}.png'
                self.assertEqual(hashlib.sha256(path.read_bytes()).hexdigest(), spec['sha256'])
                with Image.open(path) as image:
                    self.assertEqual(image.mode, 'RGBA')
                    self.assertEqual(list(image.size), spec['sizePx'])
                    self.assertEqual(set(image.getchannel('A').getdata()) <= {0, 255}, True)
                    self.assertIsNotNone(image.getbbox())
                    self.assertEqual(image.getpixel((0, 0))[3], 0)
                self.assertEqual(spec['pivotPx'][0], spec['sizePx'][0] // (8 if name.endswith('_sheet') else 2))
                self.assertEqual(spec['pivotPx'][1], spec['sizePx'][1] - 1)
                self.assertNotEqual(spec['phaseGate'], 'active')

    def test_future_fire_and_plantation_are_separate_assets(self):
        for name in ('oil_palm_mature', 'forest_charred_trunk', 'forest_fire_sheet', 'forest_smoke_sheet'):
            self.assertEqual(MANIFEST['assets'][name]['phaseGate'], 'future_only')
        for name in ('forest_fire_sheet', 'forest_smoke_sheet'):
            spec = MANIFEST['assets'][name]
            self.assertEqual(spec['frames'], 4)
            self.assertEqual(spec['frameSizePx'], [64, 64])
            with Image.open(ASSETS / f'{name}.png') as image:
                frames = [image.crop((i * 64, 0, (i + 1) * 64, 64)).tobytes() for i in range(4)]
                self.assertEqual(len(set(frames)), 4)


if __name__ == '__main__':
    unittest.main()
