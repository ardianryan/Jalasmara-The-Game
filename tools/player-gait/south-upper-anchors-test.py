#!/usr/bin/env python3
"""Original SOUTH annotation/provenance tests; synthetic mutations are not authored marks."""
import copy
import hashlib
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

path = Path(__file__).with_name('south-upper-anchors.py')
module_spec = importlib.util.spec_from_file_location('south_upper_anchors', path)
tool = importlib.util.module_from_spec(module_spec)
module_spec.loader.exec_module(tool)


class SourceAnchors(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.spec = json.loads(tool.SPEC.read_text())
        cls.images = {outfit: tool.source_image(outfit) for outfit in tool.SOURCES}

    def entry(self, outfit='daily', frame=0, side='left'):
        return copy.deepcopy(next(e for e in self.spec['entries'] if (e['outfit'], e['frame'], e['side']) == (outfit, frame, side)))

    def test_all_32_original_palms_and_no_invented_wrists(self):
        before = {o: hashlib.sha256((tool.ROOT / p).read_bytes()).hexdigest() for o, (p, _) in tool.SOURCES.items()}
        tool.validate(self.spec)
        self.assertEqual(len(self.spec['entries']), 32)
        self.assertTrue(all(e['wrist']['pixel'] is None and e['grip']['origin'] is None and e['grip']['axis'] is None for e in self.spec['entries']))
        self.assertEqual(before, {o: hashlib.sha256((tool.ROOT / p).read_bytes()).hexdigest() for o, (p, _) in tool.SOURCES.items()})

    def test_preserves_all_eight_previously_reviewed_marks(self):
        originals = {
            ('daily', 0, 'left'): ([74, 62], [223, 165, 120, 255]),
            ('daily', 0, 'right'): ([49, 65], [206, 157, 113, 255]),
            ('daily', 4, 'left'): ([81, 66], [214, 159, 111, 255]),
            ('daily', 4, 'right'): ([55, 63], [222, 171, 120, 255]),
            ('explorer', 0, 'left'): ([74, 62], [229, 167, 113, 255]),
            ('explorer', 0, 'right'): ([49, 65], [224, 164, 114, 255]),
            ('explorer', 4, 'left'): ([81, 66], [226, 173, 123, 255]),
            ('explorer', 4, 'right'): ([55, 63], [227, 178, 125, 255]),
        }
        for key, (point, rgba) in originals.items():
            e = self.entry(*key)
            self.assertEqual(e['palm']['pixel'], point)
            self.assertEqual(e['palm']['rgba'], rgba)

    def test_wrong_outfit_frame_side_or_source_image_rejected(self):
        entry = self.entry()
        for outfit, frame, side, image in [
            ('explorer', 0, 'left', self.images['explorer']),
            ('daily', 1, 'left', self.images['daily']),
            ('daily', 0, 'right', self.images['daily']),
            ('daily', 0, 'left', self.images['explorer']),
        ]:
            with self.assertRaises(ValueError):
                tool.visible_palm(entry, outfit, frame, side, image)
        entry['frame'] = 1
        with self.assertRaisesRegex(ValueError, 'frame pin'):
            tool.visible_palm(entry, 'daily', 1, 'left', self.images['daily'])

    def test_outside_transparent_and_occluded_rejected(self):
        for point in [[128, 62], [74, 76], [-1, 62], [74.5, 62]]:
            entry = self.entry()
            entry['palm']['pixel'] = point
            with self.assertRaises(ValueError):
                tool.visible_palm(entry, 'daily', 0, 'left', self.images['daily'])
        entry = self.entry()
        entry['palm']['pixel'] = [100, 0]
        entry['palm']['rgba'] = [0, 0, 0, 0]
        with self.assertRaisesRegex(ValueError, 'transparent'):
            tool.visible_palm(entry, 'daily', 0, 'left', self.images['daily'])
        for visibility in ['occluded', 'unknown']:
            entry = self.entry()
            entry['palm']['visibility'] = visibility
            with self.assertRaisesRegex(ValueError, 'unknown or occluded'):
                tool.visible_palm(entry, 'daily', 0, 'left', self.images['daily'])

    def test_rgba_and_source_pin_must_match_original(self):
        for field, value in [('sourceSha256', '0' * 64), ('upperFrameRgbaSha256', '0' * 64)]:
            entry = self.entry()
            entry[field] = value
            with self.assertRaises(ValueError):
                tool.visible_palm(entry, 'daily', 0, 'left', self.images['daily'])
        entry = self.entry()
        entry['palm']['rgba'][0] += 1
        with self.assertRaisesRegex(ValueError, 'RGBA'):
            tool.visible_palm(entry, 'daily', 0, 'left', self.images['daily'])

    def test_duplicate_and_invented_socket_annotations_rejected(self):
        for change in [
            lambda d: d['entries'].__setitem__(1, copy.deepcopy(d['entries'][0])),
            lambda d: d['entries'][0]['wrist'].update(status='source-verified', pixel=[74, 62]),
            lambda d: d['entries'][0]['grip'].update(status='source-verified', origin=[74, 62], axis=[1, 0]),
        ]:
            spec = copy.deepcopy(self.spec)
            change(spec)
            with self.assertRaises(ValueError):
                tool.validate(spec)

    def test_output_cannot_modify_runtime_or_overwrite_review(self):
        with self.assertRaisesRegex(ValueError, 'ignored artifacts'):
            tool.review_sheet(self.spec, self.images, tool.ROOT / 'client-godot' / 'forbidden-source-test')
        (tool.ROOT / 'artifacts').mkdir(exist_ok=True)
        with tempfile.TemporaryDirectory(dir=tool.ROOT / 'artifacts', prefix='south-upper-guard-') as output:
            with self.assertRaisesRegex(ValueError, 'Preserve prior review'):
                tool.review_sheet(self.spec, self.images, Path(output))


if __name__ == '__main__':
    unittest.main()
