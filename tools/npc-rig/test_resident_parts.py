"""Original pixel preservation and deterministic packing; no image synthesis."""
import hashlib
import json
import tempfile
import unittest
from pathlib import Path
from PIL import Image
from resident_parts import prepare

ROOT=Path(__file__).resolve().parents[2]
SOURCE=ROOT/"assets/source-2d/village-expansion-v1/cutouts/residents.png"

class ResidentPartsTest(unittest.TestCase):
    def test_original_pixels_reconstruct_and_build_is_reproducible(self):
        with tempfile.TemporaryDirectory() as directory:
            first,second=Path(directory)/"first",Path(directory)/"second"
            prepare(SOURCE,first)
            prepare(SOURCE,second)
            for name in ["atlas.png","rigs.json"]:
                self.assertEqual((first/name).read_bytes(),(second/name).read_bytes())
            metadata=json.loads((first/"rigs.json").read_text())
            original=Image.open(SOURCE).convert("RGBA")
            packed=Image.open(first/"atlas.png").convert("RGBA")
            self.assertEqual(len(metadata["people"]),6)
            for person in metadata["people"].values():
                self.assertEqual(person["authoredViews"],1)
                self.assertEqual(len(person["parts"]),14)
                restored=Image.new("RGBA",(96,128))
                for part in person["parts"].values():
                    x,y,w,h=part["rect"]
                    bounds=part["sourceBounds"]
                    if "grip" in part:
                        xx,yy=part["grip"]
                        self.assertGreater(packed.getpixel((x+int(xx-bounds[0]),y+int(yy-bounds[1])))[3],0)
                    restored.alpha_composite(packed.crop((x,y,x+w,y+h)),bounds[:2])
                x,y,w,h=person["sourceCell"]
                expected=original.crop((x,y,x+w,y+h))
                self.assertEqual(restored.getchannel("A").tobytes(),expected.getchannel("A").tobytes())
                for yy in range(128):
                    for xx in range(96):
                        if expected.getpixel((xx,yy))[3]: self.assertEqual(restored.getpixel((xx,yy)),expected.getpixel((xx,yy)))

if __name__=="__main__": unittest.main()
