#!/usr/bin/env python3
"""Test source preservation, loop boundaries and authored provenance, not natural gait."""
import copy
import importlib.util
import json
import math
from pathlib import Path
import tempfile
import unittest

from PIL import Image

loader = importlib.util.spec_from_file_location('nw_upper_loop', Path(__file__).with_name('nw-explorer-upper-loop.py'))
tool = importlib.util.module_from_spec(loader)
loader.loader.exec_module(tool)


class NWUpperLoop(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.spec = json.loads(tool.SPEC.read_text())
        cls.base = json.loads(tool.rig.SPEC.read_text())
        cls.reference = tool.rig.prepare(cls.base)
        cls.frames = [tool.render(cls.spec, f) for f in range(8)]

    def test_pinned_reference_and_all_source_ownership_reconstruct_original(self):
        source, plate, arms, garments, body, repairs, poses = self.reference
        self.assertEqual(poses[0]['image'].tobytes(), source.tobytes())
        self.assertEqual(len(repairs), 8)
        self.assertEqual([r['pixel'] for r in self.base['authoredJointOverlap']], [[55,58],[56,58]])
        for y in range(76):
            for x in range(128):
                owners = [im.getpixel((x,y)) for im in [*arms.values(), *garments.values()] if im.getpixel((x,y))[3]]
                self.assertEqual(len(owners), int(source.getpixel((x,y))[3] > 0))
                if owners:
                    self.assertEqual(owners[0], source.getpixel((x,y)))
        for data in self.frames:
            self.assertEqual(data[0].tobytes(), source.tobytes())
            self.assertEqual(data[1].tobytes(), body.tobytes())

    def test_all_heads_identity_palette_body_contour_and_source_garment_anchors_fixed(self):
        source, plate, arms, garments, body, repairs, poses = self.reference
        palette = set(source.getdata())
        for original, fixed, image, moved, meta in self.frames:
            self.assertEqual(image.crop((0,0,128,43)).tobytes(), source.crop((0,0,128,43)).tobytes())
            self.assertTrue(all(c in palette for c in image.getdata() if c[3]))
            self.assertEqual([len(c) for c in tool.rig.components(fixed)], [535])
            for y, x0, x1 in self.base['bodyContour']:
                for x in range(x0, x1):
                    self.assertEqual(fixed.getpixel((x,y))[3], 255)
            for p in [(63,50),(68,56),(65,62)]:
                self.assertEqual(image.getpixel(p), source.getpixel(p))
                self.assertTrue(all(im.getpixel(p)[3] == 0 for im in moved.values()))

    def test_all_isolated_arms_connected_and_hinges_rigid_without_stretch(self):
        for original, body, image, arms, meta in self.frames:
            for side in ('left','right'):
                self.assertEqual(len(tool.rig.components(arms[side])), 1)
                joint = meta['joints'][side]
                self.assertLess(math.dist(joint['elbowFromUpper'], joint['elbowFromFore']), 1e-10)
                for a,b,c,d,e,f in meta['matrices'][side].values():
                    self.assertAlmostEqual(a*e-b*d, 1)
                    self.assertAlmostEqual(math.hypot(a,d), 1)
                    self.assertAlmostEqual(math.hypot(b,e), 1)

    def test_authored_counterpart_extremes_are_opposed_not_source_contact_inference(self):
        # Compare each chain against its own neutral pose, not the other chain's screen-X.
        angles = [d[4]['angles'] for d in self.frames]
        self.assertEqual((angles[0]['left']['foreRelativeDeg'], angles[0]['right']['foreRelativeDeg']), (32,0))
        self.assertEqual((angles[4]['left']['foreRelativeDeg'], angles[4]['right']['foreRelativeDeg']), (0,-24))
        for f in range(1,5):
            self.assertLess(angles[f]['left']['foreRelativeDeg'], angles[f-1]['left']['foreRelativeDeg'])
            self.assertLess(angles[f]['right']['foreRelativeDeg'], angles[f-1]['right']['foreRelativeDeg'])
        left0, left4 = [self.frames[f][4]['joints']['left']['wristDesignAnchor'] for f in (0,4)]
        right0, right4 = [self.frames[f][4]['joints']['right']['wristDesignAnchor'] for f in (0,4)]
        self.assertLess(left0[1], left4[1])
        self.assertGreater(right0[1], right4[1])
        self.assertIsNone(self.spec['contactPhase'])

    def test_periodic_wrap_exact_with_no_extra_pixel_or_anchor_jump(self):
        for f in range(8):
            self.assertEqual(tool.render(self.spec, f+8)[2].tobytes(), self.frames[f][2].tobytes())
        changes = [tool.changed_pixels(self.frames[f][2], self.frames[(f+1)%8][2]) for f in range(8)]
        self.assertGreater(min(changes), 0)
        self.assertLessEqual(changes[-1], max(changes[:-1]))
        for side in ('left','right'):
            wrists = [d[4]['joints'][side]['wristDesignAnchor'] for d in self.frames]
            jumps = [math.dist(wrists[f], wrists[(f+1)%8]) for f in range(8)]
            self.assertLessEqual(jumps[-1], max(jumps[:-1])+1e-10)

    def test_unknown_source_anatomy_and_zero_gear_contract_retained(self):
        self.assertEqual(self.spec['sourceMeasurement'], {'anatomicalSide':'unknown','wrist':None,'grip':None})
        self.assertEqual(self.base['authoredConvention']['contactPhase'], None)
        self.assertEqual(self.base['gearContract']['newNodes'], 0)
        self.assertFalse(self.base['gearContract']['atlasVestMeshEnabled'])
        for data in self.frames:
            self.assertEqual(data[4]['angles']['behindTorso'], ['right'])
            for joint in data[4]['joints'].values():
                self.assertIn('AUTHORED', joint['status'])
                self.assertIsNone(joint['grip'])

    def test_reject_changed_scope_sources_depth_joints_motion_or_added_pixels(self):
        for change in ('outfit','view','pin','motion','depth','shoulder','wrist','contact','pixels','gear','count','cadence'):
            spec = copy.deepcopy(self.spec)
            if change == 'outfit': spec['outfit'] = 'daily'
            if change == 'view': spec['view'] = 'south'
            if change == 'pin': spec['rigSpecSha256'] = '0'*64
            if change == 'motion': spec['motion']['left']['foreMeanDeg'] = 80
            if change == 'depth': spec['behindTorso'] = []
            if change == 'shoulder': spec['upperDeg'] = 2
            if change == 'wrist': spec['sourceMeasurement']['wrist'] = [51,68]
            if change == 'contact': spec['contactPhase'] = 'left'
            if change == 'pixels': spec['newOutputPixels'] = [[55,59]]
            if change == 'gear': spec['newGearPixels'] = 1
            if change == 'count': spec['frameCount'] = 9
            if change == 'cadence': spec['previewFrameMs'] = 0
            with self.assertRaises(ValueError, msg=change): tool.render(spec, 0)
        with self.assertRaises(ValueError): tool.render(self.spec, 1.5)

    def test_source_and_specs_immutable_and_runtime_destination_refused(self):
        before = copy.deepcopy(self.spec)
        tool.render(self.spec, 0)
        self.assertEqual(self.spec, before)
        self.assertEqual(json.loads(tool.rig.SPEC.read_text()), self.base)
        for outfit in ('daily','explorer'):
            for record in json.loads(tool.rig.orientation.audit.SPEC.read_text())['sources'][outfit].values():
                self.assertEqual(tool.digest((tool.ROOT/record['path']).read_bytes()), record['sha256'])
        with self.assertRaises(ValueError): tool.export(self.spec, tool.ROOT/'client-godot')

    def test_actual_eight_frame_apng_decodes_exact_and_manifest_labels_authored_overlap(self):
        with tempfile.TemporaryDirectory(prefix='nw-upper-loop-test-', dir=tool.ROOT/'artifacts') as parent:
            output = Path(parent)/'candidate'
            tool.export(self.spec, output)
            with Image.open(output/'nw-explorer-upper-loop-preview.png') as preview:
                self.assertEqual(preview.n_frames, 8)
                self.assertEqual(preview.info['loop'], 0)
                for f in range(8):
                    preview.seek(f)
                    self.assertEqual(preview.convert('RGBA').tobytes(), self.frames[f][2].tobytes())
                    self.assertEqual(preview.info['duration'], self.spec['previewFrameMs'])
            manifest = json.loads((output/'manifest.json').read_text())
            self.assertEqual(manifest['authoredJointOverlap'], self.base['authoredJointOverlap'])
            self.assertEqual(manifest['sourceBoundaryAssignments'], self.base['sourceBoundaryAssignments'])
            self.assertTrue(manifest['neutralReferenceExact'])
            self.assertFalse(manifest['runtimeIntegration'])
            self.assertEqual(len(manifest['authoredHiddenFill']), 8)
            self.assertEqual(manifest['rigSpecSha256'], tool.digest(tool.rig.SPEC.read_bytes()))
            self.assertEqual(manifest['originalAtlasSources'], json.loads(tool.rig.orientation.audit.SPEC.read_text())['sources'])


if __name__ == '__main__':
    unittest.main()
