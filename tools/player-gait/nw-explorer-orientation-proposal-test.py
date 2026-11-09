#!/usr/bin/env python3
"""Check exact authored reference arrangement, not automatic heading/anatomy quality."""
import copy
import importlib.util
import json
from pathlib import Path
import unittest

path=Path(__file__).with_name('nw-explorer-orientation-proposal.py')
loader=importlib.util.spec_from_file_location('nw_proposal',path)
tool=importlib.util.module_from_spec(loader)
loader.loader.exec_module(tool)


class NWProposal(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.spec=json.loads(tool.SPEC.read_text())
        cls.result,cls.daily,cls.idle,cls.defective,cls.contacts,cls.sources=tool.compose(cls.spec)

    def test_original_reference_chunks_are_exact_without_mirror_scale_or_offset(self):
        self.assertEqual(self.result.size,(128,76))
        self.assertEqual(self.result.crop((0,0,128,43)).tobytes(),self.daily.crop((0,0,128,43)).tobytes())
        self.assertEqual(self.result.crop((0,43,128,76)).tobytes(),self.idle.crop((0,43,128,76)).tobytes())
        self.assertNotEqual(self.result.tobytes(),self.defective.tobytes())
        self.assertTrue(set(self.result.getdata())<=set(self.daily.getdata())|set(self.idle.getdata()))

    def test_source_neck_boundary_has_actual_opaque_contacts(self):
        self.assertEqual(len(self.contacts),42)
        for a,b in self.contacts:
            self.assertEqual(a[1],42);self.assertEqual(b[1],43)
            self.assertLessEqual(abs(a[0]-b[0]),1)
            self.assertEqual(self.result.getpixel(tuple(a))[3],255)
            self.assertEqual(self.result.getpixel(tuple(b))[3],255)

    def test_scope_does_not_invent_remaining_frames_side_or_contact(self):
        self.assertEqual(self.spec['candidateFrameCoverage'],[0])
        self.assertEqual(self.spec['unresolvedFrames'],list(range(1,8)))
        self.assertEqual(self.spec['sourceAnatomicalSides'],'unknown')
        for field in ('wrist','grip','contactPhase'):self.assertIsNone(self.spec[field])
        for kind in ('mirror','side','allframes','split'):
            spec=copy.deepcopy(self.spec)
            if kind=='mirror':spec['transform']['mirror']=True
            if kind=='side':spec['sourceAnatomicalSides']='left'
            if kind=='allframes':spec['candidateFrameCoverage']=list(range(8))
            if kind=='split':spec['splitY']=44
            with self.assertRaises(ValueError):tool.compose(spec)

    def test_no_source_input_mutation_or_runtime_output(self):
        before=copy.deepcopy(self.spec)
        tool.compose(self.spec)
        self.assertEqual(self.spec,before)
        for outfit in ('daily','explorer'):
            for kind in ('walk','idle'):
                r=self.sources['sources'][outfit][kind]
                self.assertEqual(tool.digest((tool.ROOT/r['path']).read_bytes()),r['sha256'])
        with self.assertRaises(ValueError):tool.export(self.spec,tool.ROOT/'client-godot')


if __name__=='__main__':unittest.main()
