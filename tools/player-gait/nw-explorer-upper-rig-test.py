#!/usr/bin/env python3
"""Verify scoped source ownership/provenance of authored NW endpoints, not anatomical quality."""
import copy
import importlib.util
import json
import math
from pathlib import Path
import unittest

path=Path(__file__).with_name('nw-explorer-upper-rig.py')
loader=importlib.util.spec_from_file_location('nw_rig',path)
tool=importlib.util.module_from_spec(loader);loader.loader.exec_module(tool)


class NWRig(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.spec=json.loads(tool.SPEC.read_text());cls.data=tool.prepare(cls.spec)

    def test_each_reference_texel_has_one_original_owner_and_rest_is_exact(self):
        source,plate,arms,garments,body,repairs,poses=self.data
        for y in range(76):
            for x in range(128):
                colors=[im.getpixel((x,y)) for im in [*arms.values(),*garments.values()] if im.getpixel((x,y))[3]]
                self.assertEqual(len(colors),int(source.getpixel((x,y))[3]>0))
                if colors:self.assertEqual(colors[0],source.getpixel((x,y)))
        self.assertEqual(poses[0]['image'].tobytes(),source.tobytes())

    def test_actual_body_and_two_arm_endpoints_have_no_detached_alpha_islands(self):
        source,plate,arms,garments,body,repairs,poses=self.data
        self.assertEqual([len(c) for c in tool.components(body)],[535])
        self.assertEqual(arms['left/upper'].getpixel((51,56)),(35,29,21,255))
        self.assertEqual(body.getpixel((51,56))[3],0)
        self.assertEqual(arms['left/hand'].getpixel((51,74)),(182,138,89,255))
        self.assertEqual(body.getpixel((51,74))[3],0)
        for p in poses:
            self.assertTrue(all(len(tool.components(im))==1 for im in p['arms'].values()))
        for y,x0,x1 in self.spec['bodyContour']:
            for x in range(x0,x1):self.assertEqual(body.getpixel((x,y))[3],255)

    def test_hidden_garment_fill_uses_only_owned_same_idle_row_category(self):
        source,plate,arms,garments,body,repairs,poses=self.data
        self.assertEqual(len(repairs),8)
        self.assertEqual(sum(r['garment']=='vest' for r in repairs),3)
        self.assertEqual(sum(r['garment']=='belt' for r in repairs),5)
        self.assertEqual(len(self.spec['donorCandidates']),7)
        for r in repairs:
            p,q=tuple(r['destination']),tuple(r['donor'])
            self.assertEqual(p[1],q[1]);self.assertTrue(garments[r['garment']].getpixel(q)[3])
            self.assertEqual(body.getpixel(p),source.getpixel(q))
            self.assertEqual(plate.getpixel(p)[3],0)
            self.assertTrue(any(im.getpixel(p)[3] for im in arms.values()))
            self.assertIn('AUTHORED',r['status'])

    def test_vest_and_belt_do_not_rotate_with_source_sleeves_or_hands(self):
        source,plate,arms,garments,body,repairs,poses=self.data
        for p,kind in [((63,50),'vest'),((68,56),'vest'),((65,62),'belt')]:
            self.assertEqual(garments[kind].getpixel(p),source.getpixel(p))
            self.assertTrue(all(im.getpixel(p)[3]==0 for im in arms.values()))
        self.assertEqual(arms['left/cap'].getpixel((56,50)),source.getpixel((56,50)))
        self.assertEqual(arms['right/cap'].getpixel((74,50)),source.getpixel((74,50)))

    def test_authored_overlap_fills_only_three_actual_notch_pixels_and_keeps_source_ownership(self):
        source,plate,arms,garments,body,repairs,poses=self.data
        self.assertEqual([(r['pixel'],r['rgba']) for r in self.spec['authoredJointOverlap']],
                         [([55,58],[222,178,135,255]),([56,58],[217,171,128,255])])
        predecessor=copy.deepcopy(self.spec);predecessor['authoredJointOverlap']=[]
        old_source,old_plate,old_arms,old_garments,old_body,old_repairs,old_poses=tool.prepare(predecessor)
        self.assertEqual(source.tobytes(),old_source.tobytes());self.assertEqual(body.tobytes(),old_body.tobytes())
        self.assertEqual(repairs,old_repairs)
        self.assertTrue(all(im.tobytes()==old_arms[k].tobytes() for k,im in arms.items()))
        self.assertTrue(all(im.tobytes()==old_garments[k].tobytes() for k,im in garments.items()))
        self.assertEqual(poses[0]['image'].tobytes(),old_poses[0]['image'].tobytes())
        before,after=old_poses[1]['image'],poses[1]['image']
        changed={(x,y) for y in range(76) for x in range(128) if before.getpixel((x,y))!=after.getpixel((x,y))}
        self.assertEqual(changed,{(55,59),(56,59),(56,60)})
        for q in changed:self.assertEqual(before.getpixel(q)[3],0);self.assertEqual(after.getpixel(q)[3],255)
        self.assertEqual(poses[1]['matrices'],old_poses[1]['matrices'])
        self.assertEqual(self.spec['joints']['left']['elbow'],[54,59])
        for r in self.spec['authoredJointOverlap']:
            q=tuple(r['pixel']);self.assertEqual(arms['left/upper'].getpixel(q),tuple(r['rgba']))
            self.assertEqual(arms['left/fore'].getpixel(q)[3],0)

    def test_changed_duplicate_or_unlabelled_authored_overlap_is_rejected(self):
        for mutation in ('rgba','duplicate','status','owner'):
            spec=copy.deepcopy(self.spec)
            if mutation=='rgba':spec['authoredJointOverlap'][0]['rgba'][0]^=1
            if mutation=='duplicate':spec['authoredJointOverlap'].append(copy.deepcopy(spec['authoredJointOverlap'][0]))
            if mutation=='status':spec['authoredJointOverlap'][0]['status']='original measured forearm source'
            if mutation=='owner':spec['authoredJointOverlap'][0]['originalOwner']='left/cap'
            with self.assertRaises(ValueError):tool.prepare(spec)

    def test_authored_mapping_never_promotes_source_wrist_grip_or_contact(self):
        self.assertEqual(self.spec['sourceMeasurement'],{'anatomicalSide':'unknown','wrist':None,'grip':None})
        self.assertIn('AUTHORED',self.spec['authoredConvention']['status'])
        self.assertIsNone(self.spec['authoredConvention']['contactPhase'])
        self.assertIn('AUTHORED',self.spec['jointsStatus'])
        self.assertEqual(self.spec['gearContract']['newNodes'],0)
        self.assertFalse(self.spec['gearContract']['atlasVestMeshEnabled'])

    def test_endpoint_head_palette_and_rigid_shared_elbow(self):
        source,plate,arms,garments,body,repairs,poses=self.data
        palette=set(source.getdata());self.assertNotEqual(poses[0]['image'].tobytes(),poses[1]['image'].tobytes())
        def point(m,p):a,b,c,d,e,f=m;return a*p[0]+b*p[1]+c,d*p[0]+e*p[1]+f
        for p in poses:
            self.assertEqual(p['image'].crop((0,0,128,43)).tobytes(),source.crop((0,0,128,43)).tobytes())
            self.assertTrue(all(c in palette for c in p['image'].getdata() if c[3]))
            for side,mats in p['matrices'].items():
                self.assertLess(math.dist(point(mats['upper'],self.spec['joints'][side]['elbow']),point(mats['fore'],self.spec['joints'][side]['elbow'])),1e-10)
                for a,b,c,d,e,f in mats.values():self.assertAlmostEqual(a*e-b*d,1);self.assertAlmostEqual(math.hypot(a,d),1);self.assertAlmostEqual(math.hypot(b,e),1)

    def test_wrong_scope_duplicate_source_and_invented_measurement_rejected(self):
        for change in ('scope','source','boundary','duplicate','measurement','donor','gear'):
            spec=copy.deepcopy(self.spec)
            if change=='scope':spec['view']='south'
            if change=='source':spec['orientationSpecSha256']='0'*64
            if change=='boundary':spec['sourceBoundaryAssignments'][0]['rgba'][0]^=1
            if change=='duplicate':spec['sourceBoundaryAssignments'].append(copy.deepcopy(spec['sourceBoundaryAssignments'][0]))
            if change=='measurement':spec['sourceMeasurement']['wrist']=[51,68]
            if change=='donor':spec['donorCandidates'][0]['rgba'][0]^=1
            if change=='gear':spec['gearContract']['atlasVestMeshEnabled']=True
            with self.assertRaises(ValueError):tool.prepare(spec)

    def test_source_inputs_unchanged_and_runtime_output_refused(self):
        before=copy.deepcopy(self.spec);tool.prepare(self.spec);self.assertEqual(before,self.spec)
        audit=json.loads(tool.orientation.audit.SPEC.read_text())
        for outfit in ('daily','explorer'):
            for record in audit['sources'][outfit].values():self.assertEqual(tool.digest((tool.ROOT/record['path']).read_bytes()),record['sha256'])
        with self.assertRaises(ValueError):tool.export(self.spec,tool.ROOT/'client-godot')


if __name__=='__main__':unittest.main()
