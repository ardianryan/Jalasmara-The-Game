"""Original pixel preservation and deterministic packing; no image synthesis."""
import hashlib
import json
import tempfile
import unittest
from collections import deque
from pathlib import Path
from PIL import Image
from author_bagas_telescope import author as author_bagas_telescope
from resident_parts import prepare

ROOT=Path(__file__).resolve().parents[2]
SOURCE=ROOT/"assets/source-2d/village-expansion-v1/cutouts/residents.png"

class ResidentPartsTest(unittest.TestCase):
    def test_bagas_telescope_keeps_lower_body_and_connected_raised_arm(self):
        pose=author_bagas_telescope()
        checked=Image.open(ROOT/"client-godot/resources/art/resident-rigs-v1/bagas-telescope.png").convert("RGBA")
        original=Image.open(SOURCE).convert("RGBA").crop((96,0,192,128))
        self.assertEqual(pose.tobytes(),checked.tobytes())
        self.assertEqual(pose.crop((0,89,96,128)).tobytes(),original.crop((0,89,96,128)).tobytes())
        opaque={(x,y) for y in range(128) for x in range(96) if pose.getpixel((x,y))[3]>127}
        queue=deque([(80,23)])
        visited=set(queue)
        while queue:
            x,y=queue.popleft()
            for dx,dy in ((1,0),(-1,0),(0,1),(0,-1)):
                point=(x+dx,y+dy)
                if point in opaque and point not in visited:
                    visited.add(point)
                    queue.append(point)
        self.assertIn((60,52),visited,"The telescope hand must connect to the shoulder")

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
            runtime=ROOT/"client-godot/resources/art/resident-rigs-v1"
            checked_in=Image.open(runtime/"atlas.png").convert("RGBA")
            self.assertEqual(packed.size,checked_in.size)
            self.assertEqual(packed.tobytes(),checked_in.tobytes(),"Runtime atlas must match the original-pixel generator")
            self.assertEqual(metadata,json.loads((runtime/"rigs.json").read_text()))
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
                    restored.alpha_composite(packed.crop((x,y,x+w,y+h)),tuple(bounds[:2]))
                x,y,w,h=person["sourceCell"]
                expected=original.crop((x,y,x+w,y+h))
                self.assertEqual(restored.getchannel("A").tobytes(),expected.getchannel("A").tobytes())
                for yy in range(128):
                    for xx in range(96):
                        if expected.getpixel((xx,yy))[3]: self.assertEqual(restored.getpixel((xx,yy)),expected.getpixel((xx,yy)))

if __name__=="__main__": unittest.main()
