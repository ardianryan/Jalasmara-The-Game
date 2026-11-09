#!/usr/bin/env python3
"""Source-specific explorer ownership and authored endpoint checks, not gait acceptance."""
import copy
import importlib.util
import json
import math
from pathlib import Path
import unittest

path = Path(__file__).with_name('south-explorer-upper.py')
loader = importlib.util.spec_from_file_location('explorer_upper', path)
tool = importlib.util.module_from_spec(loader)
loader.loader.exec_module(tool)


class ExplorerUpper(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.spec = json.loads(tool.SPEC.read_text())
        cls.data = tool.prepare(cls.spec)

    def test_every_original_texel_has_one_exclusive_source_owner(self):
        source, plate, arms, garments, body, repairs, poses = self.data
        for y in range(76):
            for x in range(128):
                colors = [im.getpixel((x,y)) for im in [*arms.values(), *garments.values()] if im.getpixel((x,y))[3]]
                self.assertEqual(len(colors), int(source.getpixel((x,y))[3] > 0))
                if colors: self.assertEqual(colors[0], source.getpixel((x,y)))
        self.assertEqual(poses[0][1].tobytes(), source.tobytes())

    def test_vest_shoulders_do_not_follow_arm_and_teal_cap_does(self):
        source, plate, arms, garments, *_ = self.data
        for p in [(70,45),(73,47),(56,51),(56,52)]:
            self.assertEqual(garments['vest'].getpixel(p), source.getpixel(p))
            self.assertTrue(all(im.getpixel(p)[3] == 0 for im in arms.values()))
        self.assertEqual(arms['left/upper'].getpixel((75,46)), source.getpixel((75,46)))
        for p in [(74,62),(49,65)]:
            part = 'left/palm' if p[0] > 64 else 'right/palm'
            self.assertEqual(arms[part].getpixel(p), source.getpixel(p))

    def test_hidden_repairs_are_explorer_same_row_same_garment_and_occluded_at_rest(self):
        source, plate, arms, garments, body, repairs, poses = self.data
        self.assertEqual(len(repairs), 41)
        self.assertEqual(self.spec['sourceSha256'], tool.ownership.anchors.SOURCES['explorer'][1])
        self.assertNotEqual(self.spec['sourceSha256'], tool.ownership.anchors.SOURCES['daily'][1])
        for r in repairs:
            p, q = tuple(r['destination']), tuple(r['donor'])
            self.assertEqual(p[1], q[1])
            self.assertTrue(garments[r['garment']].getpixel(q)[3])
            self.assertEqual(body.getpixel(p), source.getpixel(q))
            self.assertEqual(plate.getpixel(p)[3], 0)
            self.assertTrue(any(im.getpixel(p)[3] for im in arms.values()))
            self.assertIn('AUTHORED', r['status'])
        self.assertEqual(poses[0][1].tobytes(), source.tobytes())

    def test_original_head_palette_and_rigid_two_endpoints(self):
        source, plate, arms, garments, body, repairs, poses = self.data
        palette = set(source.getdata())
        self.assertNotEqual(poses[0][1].tobytes(), poses[1][1].tobytes())
        for name, image, transforms in poses:
            self.assertEqual(image.crop((0,0,128,43)).tobytes(), source.crop((0,0,128,43)).tobytes())
            self.assertTrue(all(c in palette for c in image.getdata() if c[3]))
            for parts in transforms.values():
                for a,b,c,d,e,f in parts.values():
                    self.assertAlmostEqual(a*e-b*d, 1)
                    self.assertAlmostEqual(math.hypot(a,d), 1)
                    self.assertAlmostEqual(math.hypot(b,e), 1)

    def test_original_outline_specks_move_to_arms_without_deletion(self):
        source, plate, arms, garments, body, repairs, poses = self.data
        self.assertEqual([len(c) for c in tool.opaque_components(body)], [1258])
        for q, part, rgba in [((47,69),'right/palm',(60,43,32,255)), ((83,56),'left/fore',(68,47,30,255))]:
            self.assertEqual(source.getpixel(q), rgba)
            self.assertEqual(arms[part].getpixel(q), rgba)
            self.assertEqual(body.getpixel(q)[3], 0)
            self.assertTrue(all(im.getpixel(q)[3] == 0 for im in garments.values()))
        predecessor = copy.deepcopy(self.spec)
        predecessor['case'].pop('additionalOwnedRuns')
        predecessor['sourceBoundaryAssignments'] = []
        before = tool.prepare(predecessor)[4]
        parts = tool.opaque_components(before)
        self.assertEqual([len(c) for c in parts], [1258,1,1])
        self.assertEqual({tuple(c[0]) for c in parts if len(c) == 1}, {(47,69),(83,56)})

    def test_scope_source_donor_and_duplicate_gear_rejected(self):
        for mutation in ('outfit','source','donor','gear','status','boundary'):
            spec = copy.deepcopy(self.spec)
            if mutation == 'outfit': spec['outfit'] = 'daily'
            if mutation == 'source': spec['sourceSha256'] = '0'*64
            if mutation == 'donor': spec['sourceRowDonorCandidates'][0]['rgba'][0] ^= 1
            if mutation == 'gear': spec['gearContract']['atlasVestMeshEnabled'] = True
            if mutation == 'boundary': spec['sourceBoundaryAssignments'][0]['rgba'][0] ^= 1
            if mutation == 'status': spec['jointsStatus'] = 'measured original wrist'
            with self.assertRaises(ValueError): tool.prepare(spec)

    def test_no_source_or_input_mutation_and_runtime_output_refused(self):
        before = copy.deepcopy(self.spec)
        tool.prepare(self.spec)
        self.assertEqual(self.spec, before)
        for outfit,(relative, sha) in tool.ownership.anchors.SOURCES.items():
            self.assertEqual(tool.digest((tool.ROOT/relative).read_bytes()), sha)
        with self.assertRaises(ValueError): tool.export(self.spec, tool.ROOT/'client-godot')


if __name__ == '__main__': unittest.main()
