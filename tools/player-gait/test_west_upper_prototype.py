import hashlib
import json
import math
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from PIL import Image

ROOT=Path(__file__).resolve().parents[2]
TOOL=ROOT/'tools/player-gait/prototype_west_upper.py'
SPEC=ROOT/'tools/player-gait/west-upper-prototype.json'


class WestUpperPrototypeTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temp=tempfile.TemporaryDirectory()
        cls.output=Path(cls.temp.name)/'fresh'
        cls.spec=json.loads(SPEC.read_text())
        cls.source_path=ROOT/cls.spec['source']
        cls.before=hashlib.sha256(cls.source_path.read_bytes()).hexdigest()
        run=subprocess.run([sys.executable,str(TOOL),'--output',str(cls.output)],capture_output=True,text=True)
        if run.returncode: raise AssertionError(run.stderr)
        cls.manifest=json.loads((cls.output/'manifest.json').read_text())
        cls.source=Image.open(cls.output/'original-west-frame0.png').convert('RGBA')

    @classmethod
    def tearDownClass(cls): cls.temp.cleanup()

    def test_source_pinned_unchanged_and_no_runtime_adoption(self):
        self.assertEqual(self.before,self.spec['sourceSha256'])
        self.assertEqual(hashlib.sha256(self.source_path.read_bytes()).hexdigest(),self.before)
        self.assertTrue(self.manifest['originalSourceUnchanged'])
        self.assertEqual([p['frame'] for p in self.manifest['poses']],[0,4])

    def test_six_cutouts_have_unique_exact_source_pixels_and_row_provenance(self):
        seen=set()
        self.assertEqual(len(self.manifest['sourceParts']),6)
        for part in self.manifest['sourceParts'].values():
            im=Image.open(self.output/part['file']).convert('RGBA')
            pixels={(x,y) for y,x0,x1 in part['sourceCellRunsYX0X1'] for x in range(x0,x1)}
            self.assertEqual(len(pixels),part['opaquePixels'])
            self.assertFalse(pixels & seen)
            seen.update(pixels)
            for point in pixels:
                self.assertEqual(im.getpixel(point),self.source.getpixel(point))
                self.assertEqual(im.getpixel(point)[3],255)

    def test_hidden_torso_is_explicitly_authored_from_verified_cloth_palette(self):
        repair=Image.open(self.output/'authored-torso-repair-mask.png').convert('RGBA')
        records=self.manifest['authoredTorsoRepairPixels']
        self.assertGreater(len(records),0)
        x0,y0,x1,y1=self.spec['verifiedClothDonor']
        for record in records:
            self.assertIs(record['authored'],True)
            x,y=record['paletteDonor']
            self.assertTrue(x0<=x<x1 and y0<=y<y1)
            self.assertEqual(repair.getpixel(tuple(record['destination'])),self.source.getpixel((x,y)))

    def test_both_upper_endpoints_preserve_original_head_and_original_palette(self):
        palette=set(self.source.getdata())
        for pose in self.manifest['poses']:
            image=Image.open(self.output/pose['texture']).convert('RGBA')
            self.assertEqual(image.size,(128,76))
            self.assertEqual(image.crop((0,0,128,43)).tobytes(),self.source.crop((0,0,128,43)).tobytes())
            self.assertTrue({pixel for pixel in image.getdata() if pixel[3]} <= palette)
            self.assertGreater(pose['visibleAuthoredPixels'],0)

    def test_independent_joint_transforms_are_rigid_and_arms_oppose(self):
        p0,p4=self.manifest['poses']
        self.assertLess(p0['transformedWristAnchors']['near'][0],62)
        self.assertGreater(p4['transformedWristAnchors']['near'][0],62)
        self.assertGreater(p0['transformedWristAnchors']['far'][0],74)
        self.assertLess(p4['transformedWristAnchors']['far'][0],74)
        for pose in (p0,p4):
            for arm in pose['jointTransforms'].values():
                for a,b,c,d,e,f in arm.values():
                    self.assertAlmostEqual(a*e-b*d,1)
                    self.assertAlmostEqual(math.hypot(a,d),1)
                    self.assertAlmostEqual(math.hypot(b,e),1)
                    self.assertAlmostEqual(a*b+d*e,0)

    def test_existing_output_and_runtime_directory_are_rejected(self):
        original=(self.output/'manifest.json').read_bytes()
        result=subprocess.run([sys.executable,str(TOOL),'--output',str(self.output)],capture_output=True)
        self.assertNotEqual(result.returncode,0)
        self.assertEqual((self.output/'manifest.json').read_bytes(),original)
        result=subprocess.run([sys.executable,str(TOOL),'--output',str(ROOT/'client-godot/upper-proposal-forbidden')],capture_output=True)
        self.assertNotEqual(result.returncode,0)
        self.assertFalse((ROOT/'client-godot/upper-proposal-forbidden').exists())


if __name__=='__main__': unittest.main()
