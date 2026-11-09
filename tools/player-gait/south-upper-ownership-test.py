#!/usr/bin/env python3
"""Check source ownership/recomposition, not anatomical correctness or natural gait."""
import copy
import hashlib
import importlib.util
import json
import math
from pathlib import Path
import unittest

path=Path(__file__).with_name('south-upper-ownership.py')
module_spec=importlib.util.spec_from_file_location('south_ownership',path)
tool=importlib.util.module_from_spec(module_spec);module_spec.loader.exec_module(tool)

class Ownership(unittest.TestCase):
	@classmethod
	def setUpClass(cls):
		cls.spec=json.loads(tool.SPEC.read_text())
		cls.cases=[(c,tool.split(c)) for c in cls.spec['cases']]

	def test_four_original_recompositions_are_exact(self):
		self.assertEqual({(c['outfit'],c['frame']) for c,_ in self.cases},{('daily',0),('daily',4),('explorer',0),('explorer',4)})
		for case,(source,plate,layers,rebuilt) in self.cases:
			self.assertEqual(source.tobytes(),rebuilt.tobytes())
			for y in range(76):
				for x in range(128):
					owned=[im.getpixel((x,y)) for im in [plate]+list(layers.values()) if im.getpixel((x,y))[3]]
					self.assertEqual(len(owned),int(source.getpixel((x,y))[3]>0))
					if owned:self.assertEqual(owned[0],source.getpixel((x,y)))

	def test_head_and_source_dimensions_are_unchanged(self):
		for case,(source,plate,layers,_) in self.cases:
			self.assertEqual(source.size,(128,76))
			self.assertEqual(plate.crop((0,0,128,43)).tobytes(),source.crop((0,0,128,43)).tobytes())
			for layer in layers.values():self.assertIsNone(layer.crop((0,0,128,43)).getbbox())

	def test_existing_palm_marks_belong_to_correct_palm_cutouts(self):
		marks=json.loads(tool.anchors.SPEC.read_text())['entries']
		for case,(source,plate,layers,_) in self.cases:
			for side in ('left','right'):
				entry=next(e for e in marks if (e['outfit'],e['frame'],e['side'])==(case['outfit'],case['frame'],side))
				point=tuple(entry['palm']['pixel'])
				self.assertEqual(list(layers[side+'/palm'].getpixel(point)),entry['palm']['rgba'])

	def test_authored_repair_is_explicit_source_palette_and_occluded_at_rest(self):
		_,(source,plate,layers,_)=self.cases[0]
		repaired,repair,records,rest=tool.authored_plate(self.spec,source,plate,layers)
		self.assertEqual(len(records),54)
		self.assertEqual(rest.tobytes(),source.tobytes())
		palette=set(source.getdata())
		body={y:(x0,x1) for y,x0,x1 in self.spec['daily0AuthoredProposal']['torsoOnlyRunsYX0X1']}
		donor_points={tuple(r['pixel']) for r in self.spec['daily0AuthoredProposal']['visibleClothRowDonorCandidates']}
		for r in records:
			x,y=r['destination'];dx,dy=r['donor']
			self.assertEqual(r['status'],'newly-authored-hidden-cloth')
			self.assertIn((dx,dy),donor_points)
			self.assertEqual(dy,y)
			self.assertTrue(plate.getpixel((dx,dy))[3])
			self.assertTrue(y in body and body[y][0]<=x<body[y][1])
			self.assertEqual(tuple(r['rgba']),source.getpixel((dx,dy)))
			self.assertIn(repaired.getpixel((x,y)),palette)
			self.assertTrue(any(im.getpixel((x,y))[3] for im in layers.values()))
			self.assertEqual(plate.getpixel((x,y))[3],0)
		self.assertEqual(len({r['donor'][1] for r in records}),18)
		self.assertGreater(len({tuple(r['rgba']) for r in records}),10)
		for point in [(76,65),(75,66),(55,57),(55,61),(76,49)]:
			self.assertEqual(repaired.getpixel(point)[3],0,'Old hand fringe/sleeve cap must stay outside neutral torso')
		for y in range(76):
			for x in range(128):
				if repaired.getpixel((x,y))!=plate.getpixel((x,y)):
					self.assertTrue(y in body and body[y][0]<=x<body[y][1])

	def test_authored_extremes_preserve_head_palette_and_rigid_source_scale(self):
		_,(source,plate,layers,_)=self.cases[0]
		repaired,repair,records,rest=tool.authored_plate(self.spec,source,plate,layers)
		poses=tool.authored_extremes(self.spec,repaired,layers)
		self.assertEqual(poses[0][1].tobytes(),source.tobytes())
		self.assertNotEqual(poses[1][1].tobytes(),source.tobytes())
		palette=set(source.getdata())
		for name,image,transforms in poses:
			self.assertEqual(image.crop((0,0,128,43)).tobytes(),source.crop((0,0,128,43)).tobytes())
			self.assertTrue(all(c in palette for c in image.getdata() if c[3]))
			for parts in transforms.values():
				for a,b,c,d,e,f in parts.values():
					self.assertAlmostEqual(a*e-b*d,1)
					self.assertAlmostEqual(math.hypot(a,d),1)
					self.assertAlmostEqual(math.hypot(b,e),1)
					self.assertAlmostEqual(a*b+d*e,0)

	def test_corrupt_donor_is_rejected(self):
		spec=copy.deepcopy(self.spec);spec['daily0AuthoredProposal']['verifiedClothDonorRect']=[0,0,128,76]
		_,(source,plate,layers,_)=self.cases[0]
		with self.assertRaises(ValueError):tool.authored_plate(spec,source,plate,layers)

	def test_source_coordinate_and_frame_scope_rejected(self):
		for frame in [1,8,-1,True]:
			with self.assertRaises(ValueError):tool.source_cell('daily',frame)
		for points in [[[0,0],[1,43],[2,44]],[[128,43],[1,44],[2,45]]]:
			with self.assertRaises(ValueError):tool.polygon(points)

	def test_new_design_joints_never_relabel_existing_wrist_annotations(self):
		self.assertIn('Newly authored',self.spec['daily0AuthoredProposal']['status'])
		anchors=json.loads(tool.anchors.SPEC.read_text())
		self.assertTrue(all(e['wrist']['status']=='ambiguous' and e['wrist']['pixel'] is None and e['grip']['origin'] is None for e in anchors['entries']))
		for outfit,(relative,sha) in tool.anchors.SOURCES.items():
			self.assertEqual(hashlib.sha256((tool.ROOT/relative).read_bytes()).hexdigest(),sha)

if __name__=='__main__':unittest.main()
