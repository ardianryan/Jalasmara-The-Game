"""Validate the pixel contract of the four generated swim strips."""

from pathlib import Path
import json
import unittest

from PIL import Image

from build_swim_atlas import APPEARANCES, CELL, DEST, FIN_FLEX, ROOT, SOURCE_POSES, digest


class SwimAtlasTest(unittest.TestCase):
    def test_generated_strips(self) -> None:
        provenance = json.loads((DEST / "provenance.json").read_text())
        self.assertEqual(set(provenance["entries"]), set(APPEARANCES))
        self.assertEqual(provenance["sourcePoseOrder"], list(SOURCE_POSES))
        self.assertEqual(provenance["finTipFlexPx"], list(FIN_FLEX))
        for name, entry in provenance["entries"].items():
            source = ROOT / entry["source"]
            output = ROOT / entry["output"]
            self.assertEqual(digest(source), entry["sourceSha256"])
            self.assertEqual(digest(output), entry["outputSha256"])
            image = Image.open(output).convert("RGBA")
            self.assertEqual(image.size, (CELL * 8, CELL))
            distinct = set()
            for pose in range(8):
                frame = image.crop((pose * CELL, 0, (pose + 1) * CELL, CELL))
                distinct.add(frame.tobytes())
                self.assertEqual(set(frame.getchannel("A").getdata()), {0, 255})
                self.assertFalse(frame.crop((0, 0, CELL, 3)).getbbox())
                self.assertGreater(frame.getchannel("A").getbbox()[2], 90)
                # The mask is part of the sprite, so every appearance keeps a
                # cyan focal detail even when detachable gear is hidden.
                self.assertTrue(any(r < 100 and g > 130 and b > 130 and a == 255
                                    for r, g, b, a in frame.getdata()))
                opaque = {(x, y) for y in range(CELL) for x in range(CELL)
                          if frame.getpixel((x, y))[3] == 255}
                connected = {next(iter(opaque))}
                frontier = list(connected)
                while frontier:
                    x, y = frontier.pop()
                    for neighbor in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
                        if neighbor in opaque and neighbor not in connected:
                            connected.add(neighbor)
                            frontier.append(neighbor)
                self.assertEqual(connected, opaque, f"{name} frame {pose} has a detached limb")
            self.assertEqual(len(distinct), 8)
            for original, flexed in ((0, 1), (2, 3), (4, 5), (2, 6), (0, 7)):
                root = image.crop((original * CELL + 36, 0, (original + 1) * CELL, CELL))
                variant = image.crop((flexed * CELL + 36, 0, (flexed + 1) * CELL, CELL))
                self.assertEqual(root.tobytes(), variant.tobytes(), "Fin flex changed the body")


if __name__ == "__main__":
    unittest.main()
