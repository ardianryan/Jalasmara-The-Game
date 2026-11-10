#!/usr/bin/env python3
"""Check source integrity and authored ownership/hinge provenance, not anatomical acceptance."""
import copy
import importlib.util
import json
import math
from pathlib import Path
import tempfile
import unittest

from PIL import Image

loader=importlib.util.spec_from_file_location('north_upper',Path(__file__).with_name('north-upper-rig.py'))
tool=importlib.util.module_from_spec(loader)
loader.loader.exec_module(tool)


class NorthUpper(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.spec=json.loads(tool.SPEC.read_text())
        cls.images=tool.load_sources(cls.spec)
        cls.data={outfit:tool.prepare_case(cls.spec,outfit,cls.images) for outfit in ('daily','explorer')}

    def test_all_original_walk_frames_and_idle_read_without_mirror_or_remap(self):
        for outfit in ('daily','explorer'):
            atlas=self.images[outfit]['walk']
            for f in range(8):
                im=tool.source_cell(self.images,outfit,f)
                self.assertEqual(im.tobytes(),atlas.crop((f*128,768,(f+1)*128,844)).tobytes())
            record=self.spec['sources'][outfit]['idle']
            original=Image.open(tool.ROOT/record['path']).convert('RGBA')
            self.assertEqual(self.images[outfit]['idle'].crop((768,0,896,76)).tobytes(),original.crop((768,0,896,76)).tobytes())
        with self.assertRaises(ValueError):tool.source_cell(self.images,'daily',8)
        with self.assertRaises(ValueError):tool.source_cell(self.images,'diving',0)

    def test_source_specific_exclusive_ownership_and_original_neutral_both_outfits(self):
        for outfit,(source,plate,arms,garments,body,repairs,poses) in self.data.items():
            self.assertEqual(poses[0]['image'].tobytes(),source.tobytes())
            self.assertEqual(tool.digest(source.tobytes()),self.spec['cases'][outfit]['sourceUpperRgbaSha256'])
            for y in range(76):
                for x in range(128):
                    owners=[im.getpixel((x,y)) for im in [*arms.values(),*garments.values()] if im.getpixel((x,y))[3]]
                    self.assertEqual(len(owners),int(source.getpixel((x,y))[3]>0))
                    if owners:self.assertEqual(owners[0],source.getpixel((x,y)))
            self.assertEqual(repairs,[])
        self.assertNotEqual(self.spec['cases']['daily']['sourceRuns'],self.spec['cases']['explorer']['sourceRuns'])
        self.assertNotEqual(self.spec['cases']['daily']['joints'],self.spec['cases']['explorer']['joints'])

    def test_body_contours_are_opaque_without_detached_original_arm_edge_islands(self):
        for outfit,(source,plate,arms,garments,body,repairs,poses) in self.data.items():
            self.assertEqual([len(c) for c in tool.components(body)],[629 if outfit=='daily' else 609])
            for y,x0,x1 in self.spec['cases'][outfit]['bodyContour']:
                for x in range(x0,x1):self.assertEqual(body.getpixel((x,y))[3],255)
        daily=self.data['daily'];explorer=self.data['explorer']
        for p in [(51,43),(51,44),(50,45),(50,46),(50,47),(49,48),(49,49)]:
            self.assertEqual(daily[2]['left/cap'].getpixel(p),daily[0].getpixel(p))
            self.assertEqual(daily[4].getpixel(p)[3],0)
        self.assertEqual(explorer[2]['left/upper'].getpixel((49,59)),explorer[0].getpixel((49,59)))
        for side,x in [('left',47),('right',81)]:
            for y in range(68,72):self.assertEqual(explorer[2][side+'/hand'].getpixel((x,y)),explorer[0].getpixel((x,y)))

    def test_ambiguous_boundary_remains_fixed_not_colored_or_moved_with_hand(self):
        expected={'daily':[(53,66),(53,67),(74,66),(74,67)],'explorer':[(54,69),(54,70),(74,70)]}
        for outfit,points in expected.items():
            source,plate,arms,garments,body,repairs,poses=self.data[outfit]
            records=self.spec['cases'][outfit]['plateBoundaryAssignments']
            self.assertEqual([r['pixel'] for r in records],[list(p) for p in points])
            for p,record in zip(points,records):
                self.assertIn('AMBIGUOUS',record['status'])
                self.assertEqual(list(source.getpixel(p)),record['rgba'])
                self.assertEqual(body.getpixel(p),source.getpixel(p))
                self.assertEqual(garments['other'].getpixel(p),source.getpixel(p))
                self.assertTrue(all(im.getpixel(p)[3]==0 for im in arms.values()))

    def test_original_head_palette_and_fixed_clothing_anchors_unchanged(self):
        for outfit,(source,plate,arms,garments,body,repairs,poses) in self.data.items():
            palette=set(source.getdata())
            for pose in poses:
                self.assertEqual(pose['image'].crop((0,0,128,43)).tobytes(),source.crop((0,0,128,43)).tobytes())
                self.assertTrue(all(c in palette for c in pose['image'].getdata() if c[3]))
                for p in [(64,48),(64,56),(64,62),(64,68)]:
                    self.assertEqual(pose['image'].getpixel(p),source.getpixel(p))
                    self.assertTrue(all(im.getpixel(p)[3]==0 for im in pose['arms'].values()))

    def test_arms_connected_and_authored_hinges_rigid(self):
        def point(m,p):a,b,c,d,e,f=m;return[a*p[0]+b*p[1]+c,d*p[0]+e*p[1]+f]
        for outfit,data in self.data.items():
            case=self.spec['cases'][outfit]
            for pose in data[-1]:
                for side in ('left','right'):
                    self.assertEqual(len(tool.components(pose['arms'][side])),1)
                    joints=case['joints'][side];mats=pose['matrices'][side]
                    self.assertLess(math.dist(point(mats['upper'],joints['elbow']),point(mats['fore'],joints['elbow'])),1e-10)
                    for a,b,c,d,e,f in mats.values():
                        self.assertAlmostEqual(a*e-b*d,1);self.assertAlmostEqual(math.hypot(a,d),1);self.assertAlmostEqual(math.hypot(b,e),1)
            self.assertEqual(case['sourceMeasurement'],{'anatomicalSide':'unknown','wrist':None,'grip':None})
            self.assertIn('AUTHORED',case['jointsStatus'])
            self.assertIsNone(case['authoredConvention']['contactPhase'])
            self.assertEqual(case['gearContract'],{'newNodes':0,'newPixels':0,'garmentMeshEnabled':False})

    def test_single_authored_overlap_fills_exact_old_alpha_gap_without_source_reassignment(self):
        spec=copy.deepcopy(self.spec);spec['cases']['explorer']['authoredJointOverlap']=[]
        old=tool.prepare_case(spec,'explorer',self.images);new=self.data['explorer']
        for i in (0,1,4):self.assertEqual(old[i].tobytes(),new[i].tobytes())
        for key,im in old[2].items():self.assertEqual(im.tobytes(),new[2][key].tobytes())
        self.assertEqual(old[-1][0]['image'].tobytes(),new[-1][0]['image'].tobytes())
        before,after=old[-1][1]['image'],new[-1][1]['image']
        changes={(x,y) for y in range(76) for x in range(128) if before.getpixel((x,y))!=after.getpixel((x,y))}
        self.assertEqual(changes,{(55,60)})
        self.assertEqual(before.getpixel((55,60))[3],0)
        self.assertEqual(after.getpixel((55,60)),(140,103,73,255))
        self.assertEqual(new[2]['left/upper'].getpixel((55,59)),(140,103,73,255))
        self.assertEqual(new[2]['left/fore'].getpixel((55,59))[3],0)
        self.assertEqual(old[-1][1]['matrices'],new[-1][1]['matrices'])

    def test_wrong_scope_sources_anatomy_source_masks_boundary_overlap_or_gear_rejected(self):
        for change in ('view','row','path','source','case','wrist','contact','mask','head','boundary','overlap','gear','anchor','motion'):
            spec=copy.deepcopy(self.spec);case=spec['cases']['explorer']
            if change=='view':spec['view']='north_west'
            if change=='row':spec['walkRow']=5
            if change=='path':spec['sources']['explorer']['walk']['path']=spec['sources']['daily']['walk']['path']
            if change=='source':spec['sources']['daily']['walk']['sha256']='0'*64
            if change=='case':case['sourceFrame']=4
            if change=='wrist':case['sourceMeasurement']['wrist']=[51,68]
            if change=='contact':case['authoredConvention']['contactPhase']='left'
            if change=='mask':case['sourceRuns']['left']['upper'].append([56,51,52])
            if change=='head':case['sourceRuns']['left']['cap'].append([42,60,61])
            if change=='boundary':case['plateBoundaryAssignments'][0]['rgba'][0]^=1
            if change=='overlap':case['authoredJointOverlap'][0]['rgba'][0]^=1
            if change=='gear':case['gearContract']['garmentMeshEnabled']=True
            if change=='anchor':case['joints']['left']['elbow']=[10,10]
            if change=='motion':case['poses'][1]['left']['foreRelativeDeg']=float('nan')
            with self.assertRaises(ValueError,msg=change):tool.prepare_case(spec,'explorer')

    def test_actual_export_inventory_source_pixels_and_provenance(self):
        with tempfile.TemporaryDirectory(prefix='north-upper-test-',dir=tool.ROOT/'artifacts') as parent:
            output=Path(parent)/'candidate';tool.export(self.spec,output)
            manifest=json.loads((output/'manifest.json').read_text())
            self.assertFalse(manifest['runtimeIntegration'])
            self.assertEqual((manifest['walkRow'],manifest['idleColumn']),(6,6))
            for outfit in ('daily','explorer'):
                c=manifest['cases'][outfit]
                self.assertEqual(c['sourceFrame'],0);self.assertEqual(len(c['originalFrameInventory']),8)
                for f,record in enumerate(c['originalFrameInventory']):
                    self.assertEqual(record['rgbaSha256'],tool.digest(tool.source_cell(self.images,outfit,f).tobytes()))
                self.assertEqual(c['authoredHiddenFill'],[])
                self.assertEqual(c['plateBoundaryAssignments'],self.spec['cases'][outfit]['plateBoundaryAssignments'])
                self.assertEqual(c['authoredJointOverlap'],self.spec['cases'][outfit]['authoredJointOverlap'])
                self.assertEqual(len(c['inspectionRegions']),4)
            self.assertTrue((output/'explorer-north-overlap-before-after.png').is_file())

    def test_inputs_and_all_original_atlases_unchanged_and_runtime_output_refused(self):
        before=copy.deepcopy(self.spec);tool.prepare_case(self.spec,'daily');self.assertEqual(self.spec,before)
        for sources in self.spec['sources'].values():
            for record in sources.values():self.assertEqual(tool.digest((tool.ROOT/record['path']).read_bytes()),record['sha256'])
        with self.assertRaises(ValueError):tool.export(self.spec,tool.ROOT/'client-godot')


if __name__=='__main__':unittest.main()
