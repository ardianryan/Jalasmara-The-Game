"""CPU checks for the source-pixel counter gesture."""

import hashlib
import unittest

from PIL import Image

from author_wira_tea import OUTPUT, SIZE, SOURCE, SOURCE_SHA, build


class WiraTeaPoseTests(unittest.TestCase):
    def test_regenerates_exact_bytes(self):
        self.assertEqual(hashlib.sha256(SOURCE.read_bytes()).hexdigest(), SOURCE_SHA)
        image = build()
        self.assertEqual(image.size, (SIZE, SIZE))
        self.assertEqual(image.mode, "RGBA")
        self.assertEqual(image.tobytes(), Image.open(OUTPUT).convert("RGBA").tobytes())

    def test_mug_and_glove_connect_to_source_body(self):
        image = build()
        opaque = image.getchannel("A")
        start = (111, 88)
        cup = (160, 80)
        self.assertGreaterEqual(opaque.getpixel(start), 128)
        self.assertGreaterEqual(opaque.getpixel(cup), 128)
        reached = {start}
        todo = [start]
        while todo:
            x, y = todo.pop()
            for p in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
                if 0 <= p[0] < SIZE and 0 <= p[1] < SIZE and p not in reached and opaque.getpixel(p) >= 128:
                    reached.add(p)
                    todo.append(p)
        self.assertIn(cup, reached)

    def test_lower_source_pixels_remain(self):
        original = Image.open(SOURCE).convert("RGBA").crop((0, 0, 627, 627)).resize((SIZE, SIZE), Image.Resampling.NEAREST)
        actual = build()
        for y in range(140, SIZE):
            for x in range(130):
                self.assertEqual(actual.getpixel((x, y)), original.getpixel((x, y)))


if __name__ == "__main__":
    unittest.main()
