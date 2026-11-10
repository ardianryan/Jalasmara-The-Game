#!/usr/bin/env python3
"""Unit tests for SOUTH explorer eight-pose upper loop authoring proposal."""
import copy
import hashlib
import json
from pathlib import Path
import shutil
import tempfile
import unittest

import importlib.util

HERE = Path(__file__).resolve().parent
SPEC = HERE / 'south-explorer-upper-loop.json'
TOOL = HERE / 'south-explorer-upper-loop.py'

loader = importlib.util.spec_from_file_location('south_explorer_loop', TOOL)
loop = importlib.util.module_from_spec(loader)
loader.loader.exec_module(loop)


class SouthExplorerUpperLoopTests(unittest.TestCase):
    def setUp(self):
        self.spec = json.loads(SPEC.read_text())

    def test_schema_and_spec_validation(self):
        loop.validate(self.spec)
        bad = copy.deepcopy(self.spec)
        bad['frameCount'] = 7
        with self.assertRaises(ValueError):
            loop.validate(bad)

        bad_motion = copy.deepcopy(self.spec)
        bad_motion['motion']['left']['upperSinDeg'] = 10
        with self.assertRaises(ValueError):
            loop.validate(bad_motion)

    def test_pose_angles_and_opposing_bounds(self):
        for f in range(8):
            pose = loop.pose_at(self.spec, f)
            self.assertEqual(pose['behindTorso'], ['left'])
            l_up = pose['left']['upperDeg']
            l_fore = pose['left']['foreRelativeDeg']
            r_up = pose['right']['upperDeg']
            r_fore = pose['right']['foreRelativeDeg']

            self.assertLessEqual(abs(l_up), 2.01)
            self.assertLessEqual(abs(r_up), 2.01)
            self.assertLessEqual(l_fore, 0.01)
            self.assertGreaterEqual(l_fore, -42.01)
            self.assertLessEqual(r_fore, 0.01)
            self.assertGreaterEqual(r_fore, -62.01)

        # Frame 0 and Frame 4 opposition check:
        # At frame 0, left is near rest (0) and right is near maximum forward swing (-62)
        p0 = loop.pose_at(self.spec, 0)
        self.assertAlmostEqual(p0['left']['foreRelativeDeg'], 0.0, places=1)
        self.assertAlmostEqual(p0['right']['foreRelativeDeg'], -62.0, places=1)

        # At frame 4, left is near maximum forward swing (-42) and right is near rest (0)
        p4 = loop.pose_at(self.spec, 4)
        self.assertAlmostEqual(p4['left']['foreRelativeDeg'], -42.0, places=1)
        self.assertAlmostEqual(p4['right']['foreRelativeDeg'], 0.0, places=1)

    def test_connected_components_across_all_frames(self):
        for f in range(8):
            final, raw, body, arms, metadata = loop.render(self.spec, f)
            self.assertEqual(len(metadata['rawArmComponents']['left']), 1)
            self.assertEqual(len(metadata['rawArmComponents']['right']), 1)
            self.assertEqual(metadata['finalArmComponents']['left'], [metadata['rawArmComponents']['left'][0]])
            self.assertEqual(metadata['finalArmComponents']['right'], [metadata['rawArmComponents']['right'][0]])
            # Left arm component size should remain ~150 pixels (+/- 5)
            self.assertGreaterEqual(metadata['rawArmComponents']['left'][0], 145)
            self.assertLessEqual(metadata['rawArmComponents']['left'][0], 155)
            # Right arm component size should remain ~145 pixels (+/- 5)
            self.assertGreaterEqual(metadata['rawArmComponents']['right'][0], 140)
            self.assertLessEqual(metadata['rawArmComponents']['right'][0], 150)

    def test_gear_contract_invariants(self):
        gear = self.spec['gearContract']
        self.assertEqual(gear['newNodes'], 0)
        self.assertEqual(gear['newSatchelPixels'], 0)
        self.assertFalse(gear['atlasVestMeshEnabled'])
        self.assertFalse(gear['tankNetEnabled'])

    def test_export_artifacts(self):
        run_dir = loop.ROOT / 'artifacts' / 'player-gait' / 'gemini-day01' / 'test-south-explorer-loop-export'
        if run_dir.exists():
            shutil.rmtree(run_dir)
        try:
            loop.export(self.spec, run_dir)
            self.assertTrue((run_dir / 'manifest.json').exists())
            self.assertTrue((run_dir / 'south-explorer-upper-loop-preview.png').exists())
            self.assertTrue((run_dir / 'south-explorer-upper-eight-strip.png').exists())
            self.assertTrue((run_dir / 'south-explorer-upper-eight-detail.png').exists())
            self.assertTrue((run_dir / 'south-explorer-upper-authored-joints.png').exists())
            self.assertTrue((run_dir / 'south-explorer-upper-wrap-7-0.png').exists())
            self.assertTrue((run_dir / 'south-explorer-upper-extremes-and-separate-arms.png').exists())
            for f in range(8):
                self.assertTrue((run_dir / f'frame-{f}.png').exists())
            manifest = json.loads((run_dir / 'manifest.json').read_text())
            self.assertEqual(len(manifest['frames']), 8)
            self.assertEqual(manifest['authoredHiddenGarmentTexels'], 41)
        finally:
            if run_dir.exists():
                shutil.rmtree(run_dir)


if __name__ == '__main__':
    unittest.main()
