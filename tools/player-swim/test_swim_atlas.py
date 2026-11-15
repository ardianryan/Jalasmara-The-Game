"""Validate the pixel contract of the four generated swim strips."""

from pathlib import Path
import json
import unittest

from PIL import Image

from build_swim_atlas import APPEARANCES, CELL, DEST, ROOT, digest


class SwimAtlasTest(unittest.TestCase):
    def test_generated_strips(self) -> None:
        provenance = json.loads((DEST / "provenance.json").read_text())
        self.assertEqual(set(provenance["entries"]), set(APPEARANCES))
        for name, entry in provenance["entries"].items():
            source = ROOT / entry["source"]
            output = ROOT / entry["output"]
            self.assertEqual(digest(source), entry["sourceSha256"])
            self.assertEqual(digest(output), entry["outputSha256"])
            image = Image.open(output).convert("RGBA")
            self.assertEqual(image.size, (CELL * 3, CELL))
            for pose in range(3):
                frame = image.crop((pose * CELL, 0, (pose + 1) * CELL, CELL))
                self.assertEqual(set(frame.getchannel("A").getdata()), {0, 255})
                self.assertFalse(frame.crop((0, 0, CELL, 3)).getbbox())
                self.assertGreater(frame.getchannel("A").getbbox()[2], 90)
                # The mask is part of the sprite, so every appearance keeps a
                # cyan focal detail even when detachable gear is hidden.
                self.assertTrue(any(r < 100 and g > 130 and b > 130 and a == 255
                                    for r, g, b, a in frame.getdata()))


if __name__ == "__main__":
    unittest.main()
