#!/usr/bin/env python3
"""Verify original daily source preservation and scoped authored endpoint provenance."""
import copy
import importlib.util
import json
import math
from pathlib import Path
import tempfile
import unittest

from PIL import Image

loader=importlib.util.spec_from_file_location('daily_nw_rig',Path(__file__).with_name('nw-daily-upper-rig.py'))
tool=importlib.util.module_from_spec(loader)
loader.loader.exec_module(tool)


class DailyNW(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.spec=json.loads(tool.SPEC.read_text())
        cls.data=tool.prepare(cls.spec)

    def test_original_daily_frame4_and_exact_exclusive_rest(self):
        source,plate,arms,garments,body,repairs,poses=self.data
        original=Image.open(tool.ROOT/self.spec['sourceAtlas']['path']).convert('RGBA').crop((512,640,640,716))
        self.assertEqual(source.tobytes(),original.tobytes())
        self.assertEqual(poses[0]['image'].tobytes(),original.tobytes())
        for y in range(76):
            for x in range(128):
                owners=[im.getpixel((x,y)) for im in [*arms.values(),*garments.values()] if im.getpixel((x,y))[3]]
                self.assertEqual(len(owners),int(source.getpixel((x,y))[3]>0))
                if owners:self.assertEqual(owners[0],source.getpixel((x,y)))

    def test_hidden_fill_is_original_daily_same_row_owned_shirt_and_neutral_occluded(self):
        source,plate,arms,garments,body,repairs,poses=self.data
        self.assertEqual(len(repairs),11)
        self.assertEqual(len(self.spec['donors']),11)
        for record in repairs:
            p,q=tuple(record['destination']),tuple(record['donor'])
            self.assertEqual(p[1],q[1])
            self.assertEqual(body.getpixel(p),source.getpixel(q))
            self.assertEqual(garments['shirt'].getpixel(q),source.getpixel(q))
            self.assertEqual(plate.getpixel(p)[3],0)
            self.assertTrue(any(im.getpixel(p)[3] for im in arms.values()))
            self.assertIn('AUTHORED',record['status'])
        self.assertEqual([len(c) for c in tool.components(body)],[486])
        for y,x0,x1 in self.spec['bodyContour']:
            for x in range(x0,x1):self.assertEqual(body.getpixel((x,y))[3],255)

    def test_hand_edge_reassignment_is_exact_original_rgba_not_cloth_fill(self):
        source,plate,arms,garments,body,repairs,poses=self.data
        expected={(57,64):(51,36,26,255),(58,64):(48,43,35,255),(57,65):(51,39,33,255),
                  (58,65):(51,43,33,255),(58,66):(61,50,40,255)}
        for p,rgba in expected.items():
            self.assertEqual(source.getpixel(p),rgba)
            self.assertEqual(arms['left/hand'].getpixel(p),rgba)
            self.assertEqual(body.getpixel(p)[3],0)
        self.assertEqual(body.getpixel((59,67)),source.getpixel((59,67)))

    def test_head_palette_and_garments_remain_original_in_both_poses(self):
        source,plate,arms,garments,body,repairs,poses=self.data
        palette=set(source.getdata())
        for pose in poses:
            self.assertEqual(pose['image'].crop((0,0,128,43)).tobytes(),source.crop((0,0,128,43)).tobytes())
            self.assertTrue(all(c in palette for c in pose['image'].getdata() if c[3]))
            for q in ((68,48),(68,57),(68,65),(68,72)):
                self.assertEqual(pose['image'].getpixel(q),source.getpixel(q))
                self.assertTrue(all(im.getpixel(q)[3]==0 for im in pose['arms'].values()))

    def test_connected_arm_endpoints_and_rigid_authored_hinges(self):
        source,plate,arms,garments,body,repairs,poses=self.data
        def point(m,p):a,b,c,d,e,f=m;return [a*p[0]+b*p[1]+c,d*p[0]+e*p[1]+f]
        for pose in poses:
            for side in ('left','right'):
                self.assertEqual(len(tool.components(pose['arms'][side])),1)
                m=pose['matrices'][side];elbow=self.spec['joints'][side]['elbow']
                self.assertLess(math.dist(point(m['upper'],elbow),point(m['fore'],elbow)),1e-10)
                for a,b,c,d,e,f in m.values():
                    self.assertAlmostEqual(a*e-b*d,1)
                    self.assertAlmostEqual(math.hypot(a,d),1)
                    self.assertAlmostEqual(math.hypot(b,e),1)
        self.assertEqual(self.spec['joints']['left']['elbow'],[60,59])
        self.assertNotEqual(poses[0]['image'].tobytes(),poses[1]['image'].tobytes())

    def test_earlier_notch_reproduced_with_original_initial_authored_axis(self):
        spec=copy.deepcopy(self.spec);spec['joints']['left']['elbow']=[57,59]
        old=tool.prepare(spec)
        source,plate,arms,garments,body,repairs,poses=self.data
        self.assertEqual(old[0].tobytes(),source.tobytes())
        self.assertEqual(old[4].tobytes(),body.tobytes())
        self.assertEqual(old[5],repairs)
        self.assertEqual(old[-1][0]['image'].tobytes(),poses[0]['image'].tobytes())
        self.assertTrue(all(im.tobytes()==old[2][name].tobytes() for name,im in arms.items()))
        # Exact hinge region: initial cut/axis leaves an inward transparent square.
        gaps=[(x,y) for y in range(56,62) for x in range(59,64)
              if old[-1][1]['arms']['left'].getpixel((x,y))[3]==0 and poses[1]['arms']['left'].getpixel((x,y))[3]>0]
        self.assertTrue(gaps)

    def test_unknown_source_and_zero_gear_are_not_promoted(self):
        self.assertEqual(self.spec['sourceMeasurement'],{'anatomicalSide':'unknown','wrist':None,'grip':None})
        self.assertIsNone(self.spec['authoredConvention']['contactPhase'])
        self.assertIn('AUTHORED',self.spec['jointsStatus'])
        self.assertEqual(self.spec['gearContract'],{'newNodes':0,'newPixels':0,'garmentMeshEnabled':False})

    def test_corrupt_or_wrong_source_scope_measurements_masks_donors_and_motion_rejected(self):
        for change in ('outfit','frame','source','headpin','wrist','contact','duplicate','headmask','donor','gear','anchor','motion'):
            spec=copy.deepcopy(self.spec)
            if change=='outfit':spec['outfit']='explorer'
            if change=='frame':spec['sourceFrame']=0
            if change=='source':spec['sourceAtlas']['sha256']='0'*64
            if change=='headpin':spec['sourceUpperRgbaSha256']='0'*64
            if change=='wrist':spec['sourceMeasurement']['wrist']=[51,65]
            if change=='contact':spec['authoredConvention']['contactPhase']='left'
            if change=='duplicate':spec['sourceRuns']['left']['hand'].append([65,50,51])
            if change=='headmask':spec['sourceRuns']['left']['cap'].append([42,60,61])
            if change=='donor':spec['donors'][0]['rgba'][0]^=1
            if change=='gear':spec['gearContract']['garmentMeshEnabled']=True
            if change=='anchor':spec['joints']['left']['elbow']=[20,20]
            if change=='motion':spec['poses'][1]['left']['foreRelativeDeg']=float('nan')
            with self.assertRaises(ValueError,msg=change):tool.prepare(spec)

    def test_actual_export_preserves_original_bandana_tail_not_a_new_island(self):
        with tempfile.TemporaryDirectory(prefix='nw-daily-rig-test-',dir=tool.ROOT/'artifacts') as parent:
            output=Path(parent)/'candidate';tool.export(self.spec,output)
            manifest=json.loads((output/'manifest.json').read_text())
            self.assertEqual(manifest['sourceHeadComponents'],[620])
            self.assertEqual(manifest['sourceFrame0HeadComponents'],[627])
            self.assertEqual([(r['pixel'],r['rgba']) for r in manifest['originalBandanaTail']],
                             [([79,42],[73,52,43,255]),([80,42],[80,45,36,255]),([81,42],[79,44,36,255])])
            self.assertTrue(all(r['connectedAboveRgba'][3]==255 for r in manifest['originalBandanaTail']))
            self.assertEqual(manifest['sourceFrame'],4)
            self.assertFalse(manifest['runtimeIntegration'])
            self.assertEqual(manifest['sourceAtlas'],self.spec['sourceAtlas'])
            self.assertEqual(len(manifest['authoredHiddenFill']),11)

    def test_inputs_and_original_png_unchanged_runtime_output_refused(self):
        before=copy.deepcopy(self.spec);tool.prepare(self.spec);self.assertEqual(self.spec,before)
        record=self.spec['sourceAtlas']
        self.assertEqual(tool.digest((tool.ROOT/record['path']).read_bytes()),record['sha256'])
        with self.assertRaises(ValueError):tool.export(self.spec,tool.ROOT/'client-godot')


if __name__=='__main__':unittest.main()
