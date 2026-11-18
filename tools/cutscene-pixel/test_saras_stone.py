"""CPU checks for Saras's connected prasasti reveal."""

import hashlib
import unittest

from PIL import Image

from author_saras_stone import OUTPUT, SOURCE, SOURCE_SHA, build


class SarasStonePoseTests(unittest.TestCase):
    def test_source_pin_and_regeneration(self):
        self.assertEqual(hashlib.sha256(SOURCE.read_bytes()).hexdigest(), SOURCE_SHA)
        actual = build()
        self.assertEqual(actual.size, (128, 64))
        self.assertEqual(actual.mode, "RGBA")
        self.assertEqual(actual.tobytes(), Image.open(OUTPUT).convert("RGBA").tobytes())

    def test_stone_is_connected_to_body_in_both_poses(self):
        sheet = build()
        for frame in range(2):
            alpha = sheet.crop((frame * 64, 0, frame * 64 + 64, 64)).getchannel("A")
            start = (29, 23)
            stone = (47, 20) if frame == 0 else (52, 20)
            self.assertGreater(alpha.getpixel(start), 128)
            self.assertGreater(alpha.getpixel(stone), 128)
            seen = {start}
            todo = [start]
            while todo:
                x, y = todo.pop()
                for point in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
                    if 0 <= point[0] < 64 and 0 <= point[1] < 64 and point not in seen and alpha.getpixel(point) >= 128:
                        seen.add(point)
                        todo.append(point)
            self.assertIn(stone, seen)

    def test_unedited_lower_body_is_preserved(self):
        base = Image.open(SOURCE).convert("RGBA").crop((0, 0, 64, 64))
        sheet = build()
        for frame in range(2):
            pose = sheet.crop((frame * 64, 0, frame * 64 + 64, 64))
            for y in range(33, 64):
                for x in range(64):
                    self.assertEqual(pose.getpixel((x, y)), base.getpixel((x, y)))

    def test_acid_stain_and_inscription_are_both_present(self):
        sheet = build()
        for frame in range(2):
            pose = sheet.crop((frame * 64, 0, frame * 64 + 64, 64))
            colors = [pose.getpixel((x, y))[:3] for y in range(14, 28) for x in range(40, 58)]
            self.assertIn((162, 90, 154), colors)
            self.assertIn((111, 222, 208), colors)


if __name__ == "__main__":
    unittest.main()
