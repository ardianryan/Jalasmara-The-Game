#!/usr/bin/env python3
"""Validate read-only source scope and preserve unknown anatomy in the NW audit."""
import copy
import importlib.util
import json
from pathlib import Path
import unittest

path=Path(__file__).with_name('nw-upper-source-audit.py')
loader=importlib.util.spec_from_file_location('nw_source',path)
tool=importlib.util.module_from_spec(loader)
loader.loader.exec_module(tool)


class NWSourceAudit(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.spec=json.loads(tool.SPEC.read_text())
        cls.images=tool.sources(cls.spec)

    def test_original_sixteen_crops_match_exact_row5_source(self):
        for outfit in ('daily','explorer'):
            values=[]
            for f in range(8):
                crop=tool.cell(self.images,outfit,f)
                expected=self.images[outfit]['walk'].crop((f*128,640,(f+1)*128,716))
                self.assertEqual(crop.tobytes(),expected.tobytes())
                values.append(crop.tobytes())
            self.assertEqual(len(set(values)),8)

    def test_inspection_patch_provenance_contains_only_exact_original_pixels(self):
        patches=tool.patch_inventory(self.spec,self.images)
        self.assertEqual(len(patches),12)
        for p in patches:
            original=tool.cell(self.images,p['outfit'],p['frame']).crop(tuple(p['rect']))
            self.assertEqual(p['rgbaSha256'],tool.digest(original.tobytes()))
            self.assertEqual(sum(x1-x0 for y,x0,x1 in p['opaqueSourceRunsLocalYX0X1']),sum(a>0 for a in original.getchannel('A').getdata()))
            self.assertEqual(p['anatomicalSide'],'unknown')
            self.assertIsNone(p['wrist'])
            self.assertIsNone(p['grip'])

    def test_wrong_row_view_source_and_invented_anatomy_rejected(self):
        for kind in ('row','view','source','side','wrist'):
            spec=copy.deepcopy(self.spec)
            if kind=='row':spec['walkRow']=7
            if kind=='view':spec['view']='north_east'
            if kind=='source':spec['sources']['daily']['walk']['sha256']='0'*64
            if kind=='side':spec['anatomicalSide']='left'
            if kind=='wrist':spec['wrist']=[63,65]
            with self.assertRaises(ValueError):tool.sources(spec)
        for frame in (-1,8,True):
            with self.assertRaises(ValueError):tool.cell(self.images,'daily',frame)

    def test_original_lower_evidence_remains_idle_data_not_upper_mapping(self):
        for outfit in ('daily','explorer'):
            record=self.spec['lowerAnnotationEvidence'][outfit]
            self.assertEqual(record['northWestData']['sourceColumn'],5)
            self.assertEqual(record['northWestData']['legs']['left']['hip'],[59,76])
            self.assertEqual(record['northWestData']['legs']['right']['hip'],[70,76])
            self.assertEqual(record['sourceSha256'],self.spec['sources'][outfit]['idle']['sha256'])
            self.assertIn('DATA',record['scope'])
            self.assertNotIn('upperSide',record)

    def test_bad_patch_and_runtime_output_rejected_without_input_mutation(self):
        before=copy.deepcopy(self.spec)
        tool.patch_inventory(self.spec,self.images)
        self.assertEqual(self.spec,before)
        spec=copy.deepcopy(self.spec)
        spec['boundaryPatches']['daily'][0]['regions']['visibleSleeve']=[0,0,128,128]
        with self.assertRaises(ValueError):tool.patch_inventory(spec,self.images)
        with self.assertRaises(ValueError):tool.export(self.spec,tool.ROOT/'client-godot')


if __name__=='__main__':unittest.main()
