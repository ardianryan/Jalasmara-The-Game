#!/usr/bin/env python3
"""Check authored source provenance, topology and cycle bounds, not natural gait."""
import copy
import importlib.util
import json
import math
from pathlib import Path
import tempfile
import unittest

path = Path(__file__).with_name('south-upper-loop.py')
loader = importlib.util.spec_from_file_location('south_upper_loop', path)
tool = importlib.util.module_from_spec(loader)
loader.loader.exec_module(tool)


class SouthLoop(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.spec = json.loads(tool.SPEC.read_text())
        cls.frames = [tool.render(cls.spec, f) for f in range(8)]
        cls.source = tool.ownership.source_cell('daily', 0)

    def test_scope_and_ownership_pin_fail_closed(self):
        for key, bad in [('outfit', 'explorer'), ('view', 'west'), ('sourceFrame', 4),
                         ('sourceFrame', False), ('frameCount', 9), ('ownershipSpecSha256', '0'*64)]:
            spec = copy.deepcopy(self.spec)
            spec[key] = bad
            with self.assertRaises(ValueError): tool.render(spec, 0)

    def test_eight_original_palette_frames_preserve_head_and_body(self):
        palette = set(self.source.getdata())
        self.assertEqual(len({r[0].tobytes() for r in self.frames}), 8)
        for final, raw, body, arms, metadata in self.frames:
            self.assertEqual(final.size, (128, 76))
            self.assertEqual(final.crop((0, 0, 128, 43)).tobytes(), self.source.crop((0, 0, 128, 43)).tobytes())
            self.assertEqual(body.tobytes(), self.frames[0][2].tobytes())
            self.assertTrue(all(c in palette for c in final.getdata() if c[3]))
            self.assertTrue(all(arm.crop((0, 0, 128, 43)).getbbox() is None for arm in arms.values()))
            self.assertEqual(metadata['hiddenBodyRepairTexels'], 93)

    def test_cycle_wrap_is_periodic_without_duplicate_export_frame(self):
        wrapped = tool.render(self.spec, 8)
        self.assertEqual(wrapped[0].tobytes(), self.frames[0][0].tobytes())
        self.assertEqual(wrapped[4], self.frames[0][4])
        for side in ('left', 'right'):
            points = [r[4]['joints'][side]['wristDesignAnchor'] for r in self.frames]
            steps = [math.dist(points[f], points[(f+1) % 8]) for f in range(8)]
            self.assertLessEqual(steps[7], max(steps[:7]))
        changes = [sum(a != b for a, b in zip(self.frames[f][0].getdata(), self.frames[(f+1) % 8][0].getdata())) for f in range(8)]
        self.assertLessEqual(changes[7], max(changes[:7]))

    def test_rigid_joint_chain_stays_attached_and_no_contact_or_grip_is_claimed(self):
        for final, raw, body, arms, metadata in self.frames:
            self.assertIn('No Lower', self.spec['phaseStatus'])
            for side in ('left', 'right'):
                joints = metadata['joints'][side]
                self.assertLess(math.dist(joints['elbowFromUpper'], joints['elbowFromFore']), 1e-10)
                self.assertIn('AUTHORED', joints['status'])
                self.assertIsNone(joints['grip'])
                for a, b, c, d, e, f in metadata['transforms'][side].values():
                    self.assertAlmostEqual(a*e-b*d, 1)
                    self.assertAlmostEqual(math.hypot(a, d), 1)
                    self.assertAlmostEqual(math.hypot(b, e), 1)
                    self.assertAlmostEqual(a*b+d*e, 0)

    def test_opposing_authored_extremes_use_actual_source_palm_markers(self):
        low, high = self.frames[0][4]['joints'], self.frames[4][4]['joints']
        self.assertEqual(low['left']['sourcePalmMarker']['pixel'], [74, 62])
        self.assertEqual(low['right']['sourcePalmMarker']['pixel'], [49, 65])
        self.assertGreater(low['left']['palmMarkerProjection'][1], high['left']['palmMarkerProjection'][1])
        self.assertLess(low['right']['palmMarkerProjection'][1], high['right']['palmMarkerProjection'][1])
        self.assertIn('not joint/grip', low['left']['palmProjectionStatus'])

    def test_explicit_original_boundary_assignment_closes_arms_without_new_pixels(self):
        expected = {(54,59),(55,59),(54,60),(55,62),(55,63),(55,64)}
        self.assertEqual({tuple(r['pixel']) for r in self.spec['armBoundaryOwnershipProposal']}, expected)
        self.assertEqual(self.spec['authoredOutputPixels'], [])
        base, source, body, layers, repairs = tool.prepare(self.spec)
        reconstructed = body.copy()
        for layer in layers.values(): reconstructed.alpha_composite(layer)
        self.assertEqual(reconstructed.tobytes(), source.tobytes())
        for point in expected:
            self.assertEqual(layers['right/fore'].getpixel(point), source.getpixel(point))
            self.assertEqual(body.getpixel(point)[3], 0)
        for final, raw, body, arms, metadata in self.frames:
            self.assertTrue(all(len(parts) == 1 for parts in metadata['finalArmComponents'].values()))
            self.assertEqual(metadata['authoredOutputPixels'], [])
            self.assertEqual(final.tobytes(), raw.tobytes())
        original = copy.deepcopy(self.spec)
        original['armBoundaryOwnershipProposal'] = []
        self.assertEqual(tool.render(original, 4)[4]['finalArmComponents']['right'], [176, 1])

    def test_reserved_cloth_never_returns_to_moving_source_cutouts(self):
        ownership_spec = json.loads(tool.ownership.SPEC.read_text())
        source, plate, layers, _ = tool.ownership.split(ownership_spec['cases'][0])
        self.assertEqual(len(ownership_spec['cases'][0]['plateOwnedPixels']), 11)
        for record in ownership_spec['cases'][0]['plateOwnedPixels']:
            point = tuple(record['pixel'])
            self.assertEqual(plate.getpixel(point), source.getpixel(point))
            self.assertTrue(all(layer.getpixel(point)[3] == 0 for layer in layers.values()))

    def test_changed_duplicate_or_cloth_boundary_and_unsafe_motion_rejected(self):
        for mutation in ('rgba', 'cloth', 'duplicate', 'motion'):
            spec = copy.deepcopy(self.spec)
            if mutation == 'rgba': spec['armBoundaryOwnershipProposal'][0]['rgba'][0] ^= 1
            if mutation == 'cloth':
                spec['armBoundaryOwnershipProposal'][0]['pixel'] = [70, 58]
                spec['armBoundaryOwnershipProposal'][0]['rgba'] = [91, 109, 107, 255]
            if mutation == 'duplicate': spec['armBoundaryOwnershipProposal'].append(copy.deepcopy(spec['armBoundaryOwnershipProposal'][0]))
            if mutation == 'motion': spec['motion']['left']['upperSinDeg'] = 10
            with self.assertRaises(ValueError): tool.render(spec, 0)

    def test_source_input_and_output_guards(self):
        before = copy.deepcopy(self.spec)
        tool.render(self.spec, 0)
        self.assertEqual(before, self.spec)
        with tempfile.TemporaryDirectory() as output:
            with self.assertRaises(ValueError): tool.export(self.spec, Path(output) / 'outside')
        with self.assertRaises(ValueError): tool.export(self.spec, tool.ROOT / 'client-godot')


if __name__ == '__main__': unittest.main()
