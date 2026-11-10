#!/usr/bin/env python3
"""Check two original NORTH outfit loops' source integrity and authored boundaries, not gait quality."""
import copy
import importlib.util
import json
import math
from pathlib import Path
import tempfile
import unittest

from PIL import Image

loader=importlib.util.spec_from_file_location('north_upper_loop',Path(__file__).with_name('north-upper-loop.py'))
tool=importlib.util.module_from_spec(loader)
loader.loader.exec_module(tool)


class NorthLoops(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.spec=json.loads(tool.SPEC.read_text());cls.base=json.loads(tool.rig.SPEC.read_text())
        cls.images=tool.rig.load_sources(cls.base)
        cls.reference={o:tool.rig.prepare_case(cls.base,o,cls.images) for o in ('daily','explorer')}
        cls.frames={o:[tool.render(cls.spec,o,f,cls.images) for f in range(8)] for o in ('daily','explorer')}

    def test_distinct_outfit_masks_and_original_exclusive_ownership_with_exact_neutral(self):
        self.assertNotEqual(self.base['cases']['daily']['sourceRuns'],self.base['cases']['explorer']['sourceRuns'])
        for outfit,(source,plate,arms,garments,body,repairs,neutral) in self.reference.items():
            self.assertEqual(neutral[0]['image'].tobytes(),source.tobytes())
            for y in range(76):
                for x in range(128):
                    owners=[im.getpixel((x,y)) for im in [*arms.values(),*garments.values()] if im.getpixel((x,y))[3]]
                    self.assertEqual(len(owners),int(source.getpixel((x,y))[3]>0))
                    if owners:self.assertEqual(owners[0],source.getpixel((x,y)))
            self.assertEqual(repairs,[])

    def test_fixed_body_head_original_palette_and_torso_contour_all_sixteen_frames(self):
        for outfit,rows in self.frames.items():
            original=self.reference[outfit][0];body=self.reference[outfit][4];palette=set(original.getdata())
            for source,fixed,image,arms,metadata in rows:
                self.assertEqual(source.tobytes(),original.tobytes())
                self.assertEqual(fixed.tobytes(),body.tobytes())
                self.assertEqual(image.crop((0,0,128,43)).tobytes(),original.crop((0,0,128,43)).tobytes())
                self.assertTrue(all(c in palette for c in image.getdata() if c[3]))
                self.assertEqual([len(c) for c in tool.rig.components(fixed)],[629 if outfit=='daily' else 609])
                for y,x0,x1 in self.base['cases'][outfit]['bodyContour']:
                    for x in range(x0,x1):self.assertEqual(fixed.getpixel((x,y))[3],255)

    def test_all_seven_ambiguous_original_boundaries_remain_fixed_without_new_clothing_or_overlap(self):
        for outfit,rows in self.frames.items():
            case=self.base['cases'][outfit]
            self.assertEqual(len(case['plateBoundaryAssignments']),4 if outfit=='daily' else 3)
            self.assertEqual(len(case['authoredJointOverlap']),0 if outfit=='daily' else 1)
            for record in case['plateBoundaryAssignments']:
                p=tuple(record['pixel']);self.assertIn('AMBIGUOUS',record['status'])
                for source,body,image,arms,metadata in rows:self.assertEqual(body.getpixel(p),tuple(record['rgba']))
            self.assertEqual(case['gearContract'],{'newNodes':0,'newPixels':0,'garmentMeshEnabled':False})
        self.assertEqual(self.base['cases']['explorer']['authoredJointOverlap'][0]['pixel'],[55,59])
        self.assertEqual(self.base['cases']['explorer']['authoredJointOverlap'][0]['rgba'],[140,103,73,255])

    def test_all_arms_connected_and_authored_hinges_rigid_without_stretch(self):
        for outfit,rows in self.frames.items():
            for source,body,image,arms,metadata in rows:
                for side in ('left','right'):
                    self.assertEqual(len(tool.rig.components(arms[side])),1)
                    joint=metadata['joints'][side]
                    self.assertLess(math.dist(joint['elbowFromUpper'],joint['elbowFromFore']),1e-10)
                    self.assertEqual(joint['shoulder'],self.base['cases'][outfit]['joints'][side]['shoulder'])
                    for a,b,c,d,e,f in metadata['matrices'][side].values():
                        self.assertAlmostEqual(a*e-b*d,1);self.assertAlmostEqual(math.hypot(a,d),1);self.assertAlmostEqual(math.hypot(b,e),1)

    def test_authored_outward_inward_amounts_opposed_but_not_anatomical_contact_phase(self):
        for outfit,rows in self.frames.items():
            angles=[r[4]['angles'] for r in rows]
            self.assertEqual((angles[0]['left']['foreRelativeDeg'],angles[0]['right']['foreRelativeDeg']),(24,0))
            self.assertEqual((angles[4]['left']['foreRelativeDeg'],angles[4]['right']['foreRelativeDeg']),(0,18))
            for f in range(1,5):
                self.assertLess(angles[f]['left']['foreRelativeDeg'],angles[f-1]['left']['foreRelativeDeg'])
                self.assertGreater(angles[f]['right']['foreRelativeDeg'],angles[f-1]['right']['foreRelativeDeg'])
            for metadata in [r[4] for r in rows]:
                self.assertEqual(metadata['originalSourceFrame'],0)
                for joint in metadata['joints'].values():self.assertIn('AUTHORED',joint['status']);self.assertIsNone(joint['grip'])
        self.assertEqual(self.spec['sourceMeasurement'],{'anatomicalSide':'unknown','wrist':None,'grip':None})
        self.assertIsNone(self.spec['contactPhase'])

    def test_periodic_wrap_exact_and_no_extra_raster_or_authored_anchor_jump(self):
        for outfit,rows in self.frames.items():
            for f in range(8):self.assertEqual(tool.render(self.spec,outfit,f+8,self.images)[2].tobytes(),rows[f][2].tobytes())
            changes=[tool.changed_pixels(rows[f][2],rows[(f+1)%8][2]) for f in range(8)]
            self.assertGreater(min(changes),0);self.assertLessEqual(changes[-1],max(changes[:-1]))
            self.assertEqual(len(set(r[4]['rgbaSha256'] for r in rows)),5)
            for side in ('left','right'):
                wrists=[r[4]['joints'][side]['wristDesignAnchor'] for r in rows]
                jumps=[math.dist(wrists[f],wrists[(f+1)%8]) for f in range(8)]
                self.assertLessEqual(jumps[-1],max(jumps[:-1])+1e-10)

    def test_pose_scope_and_provenance_reject_wrong_outfit_direction_pin_or_invented_source_phase(self):
        for change in ('view','pin','count','outfits','motion','depth','shoulder','frame','wrist','contact','phaseclaim','cadence','pixels','gear'):
            spec=copy.deepcopy(self.spec)
            if change=='view':spec['view']='north_west'
            if change=='pin':spec['rigSpecSha256']='0'*64
            if change=='count':spec['frameCount']=9
            if change=='outfits':spec['cases']['diving']=spec['cases']['daily']
            if change=='motion':spec['cases']['daily']['motion']['left']['foreMeanDeg']=80
            if change=='depth':spec['cases']['explorer']['behindTorso']=[]
            if change=='shoulder':spec['cases']['daily']['upperDeg']=1
            if change=='frame':spec['cases']['daily']['originalSourceFrame']=4
            if change=='wrist':spec['sourceMeasurement']['wrist']=[50,68]
            if change=='contact':spec['contactPhase']='left'
            if change=='phaseclaim':spec['sourceFrameStatus']='Original source frame0 proves contact event0'
            if change=='cadence':spec['previewFrameMs']=0
            if change=='pixels':spec['newOutputPixels']=[[55,60]]
            if change=='gear':spec['newGearPixels']=1
            with self.assertRaises(ValueError,msg=change):tool.render(spec,'daily',0,self.images)
        with self.assertRaises(ValueError):tool.render(self.spec,'diving',0,self.images)
        with self.assertRaises(ValueError):tool.pose_at(self.spec,'daily',0.5)

    def test_actual_apngs_decode_all_eight_frames_exact_and_manifest_keeps_each_case_contract(self):
        with tempfile.TemporaryDirectory(prefix='north-loop-test-',dir=tool.ROOT/'artifacts') as parent:
            output=Path(parent)/'candidate';tool.export(self.spec,output)
            manifest=json.loads((output/'manifest.json').read_text())
            self.assertFalse(manifest['runtimeIntegration'])
            self.assertEqual(manifest['originalSources'],self.base['sources'])
            for outfit,rows in self.frames.items():
                with Image.open(output/f'{outfit}-north-upper-loop-preview.png') as im:
                    self.assertEqual(im.n_frames,8);self.assertEqual(im.info['loop'],0)
                    for f in range(8):
                        im.seek(f);self.assertEqual(im.convert('RGBA').tobytes(),rows[f][2].tobytes());self.assertEqual(im.info['duration'],100)
                case=manifest['cases'][outfit];original=self.base['cases'][outfit]
                self.assertTrue(case['neutralReferenceExact'])
                self.assertEqual(case['originalSourceFrame'],0)
                self.assertEqual(case['plateBoundaryAssignments'],original['plateBoundaryAssignments'])
                self.assertEqual(case['authoredJointOverlap'],original['authoredJointOverlap'])
                self.assertEqual(case['authoredHiddenFill'],[])
                self.assertEqual(case['jointDesignRationale'],original['jointDesignRationale'])
                self.assertEqual(case['originalSourceRuns'],{k:tool.rig.ops.row_runs(im) for k,im in {**self.reference[outfit][2],**self.reference[outfit][3]}.items()})
                self.assertTrue(all(m['authoringFrame']==f and m['originalSourceFrame']==0 for f,m in enumerate(case['frames'])))

    def test_original_specs_and_pngs_immutable_and_runtime_destination_refused(self):
        before=copy.deepcopy(self.spec);tool.render(self.spec,'daily',0,self.images);self.assertEqual(self.spec,before)
        self.assertEqual(json.loads(tool.rig.SPEC.read_text()),self.base)
        for sources in self.base['sources'].values():
            for record in sources.values():self.assertEqual(tool.digest((tool.ROOT/record['path']).read_bytes()),record['sha256'])
        with self.assertRaises(ValueError):tool.export(self.spec,tool.ROOT/'client-godot')


if __name__=='__main__':unittest.main()
