"""Partition reviewed original residents into independently posed masks.

No rear view or replacement pixel is synthesized. The unposed masks reconstruct
all original opaque pixels exactly; hidden joints have only original-pixel overlap.
"""
import argparse
import hashlib
import json
import math
from pathlib import Path
from PIL import Image, ImageDraw

SOURCE_SHA = "6dc5fbb107327c97205660817cf245661bea838d50be606735fe2c6a247d413e"
IDS = ["npc_direktur_cakrawala", "npc_kid_bagas", "npc_kid_kinasih", "npc_kid_danu", "npc_kid_gito", "npc_kid_cempaka"]
SPECS = [
 dict(head=[(31,8),(62,8),(63,31),(53,36),(34,34)], torso=[(32,32),(54,32),(62,40),(60,75),(36,78),(29,64),(28,43)], arms=[[(30,48),(28,64),(30,78)],[(62,48),(66,64),(70,78)]], legs=[[(41,76),(38,96),(37,114)],[(55,76),(54,96),(56,114)]], feet=[(29,111,46,121),(49,111,72,121)]),
 dict(head=[(28,8),(67,8),(68,32),(58,41),(35,39)], torso=[(34,39),(59,39),(63,49),(61,79),(34,80),(29,52)], arms=[[(35,49),(29,66),(25,81)],[(62,49),(67,66),(70,81)]], legs=[[(40,84),(39,100),(38,114)],[(55,84),(54,100),(54,114)]], feet=[(28,111,46,121),(47,110,69,121)]),
 dict(head=[(32,8),(67,8),(71,31),(66,44),(34,42)], torso=[(34,37),(62,37),(66,54),(65,106),(33,106),(30,53)], arms=[[(30,55),(26,69),(25,80)],[(67,55),(70,69),(72,80)]], legs=[[(43,90),(42,103),(42,115)],[(57,90),(58,103),(58,115)]], feet=[(33,112,49,121),(52,112,73,121)]),
 dict(head=[(23,8),(75,8),(74,26),(65,35),(61,43),(37,41),(33,32),(24,28)], torso=[(34,38),(60,38),(64,51),(61,78),(33,79),(29,52)], arms=[[(31,48),(29,64),(28,77)],[(63,48),(67,64),(69,77)]], legs=[[(41,80),(39,99),(38,114)],[(55,80),(54,99),(55,114)]], feet=[(28,111,45,121),(49,111,71,121)]),
 dict(head=[(29,8),(67,8),(68,33),(57,40),(33,37)], torso=[(33,37),(62,37),(66,52),(64,80),(34,82),(29,53)], arms=[[(33,47),(27,64),(25,78)],[(64,47),(70,64),(74,78)]], legs=[[(41,83),(40,100),(38,114)],[(57,83),(57,100),(57,115)]], feet=[(29,111,48,121),(51,111,73,121)]),
 dict(head=[(29,8),(68,8),(70,30),(60,39),(32,38)], torso=[(33,38),(62,38),(66,55),(69,104),(27,104),(28,56)], arms=[[(28,52),(24,64),(23,73)],[(65,52),(70,64),(75,73)]], legs=[[(41,92),(40,105),(39,115)],[(57,92),(57,105),(57,115)]], feet=[(30,112,49,121),(51,112,74,121)]),
]


def distance(p, a, b):
    dx, dy = b[0]-a[0], b[1]-a[1]
    t = max(0, min(1, ((p[0]-a[0])*dx+(p[1]-a[1])*dy)/max(.01, dx*dx+dy*dy)))
    return math.hypot(p[0]-a[0]-t*dx, p[1]-a[1]-t*dy)


def prepare(source: Path, output: Path):
    assert hashlib.sha256(source.read_bytes()).hexdigest() == SOURCE_SHA
    original = Image.open(source).convert("RGBA")
    assert original.size == (288, 256)
    output.mkdir(parents=True, exist_ok=False)
    atlas = Image.new("RGBA", (7*96, 12*128))
    people = {}
    slot = 0
    for index, (resident_id, spec) in enumerate(zip(IDS, SPECS)):
        raw = original.crop((index % 3*96, index//3*128, index % 3*96+96, index//3*128+128))
        split=(spec["legs"][0][2][0]+spec["legs"][1][2][0])/2
        feet=[(0,spec["feet"][0][1],split,128),(split,spec["feet"][1][1],96,128)]
        polygons = {}
        for name in ["head", "torso"]:
            mask = Image.new("L", raw.size)
            ImageDraw.Draw(mask).polygon(spec[name], fill=255)
            polygons[name] = mask
        parts = {name: Image.new("RGBA", raw.size) for name in ["head", "torso"]}
        bones = {}
        for side, arm, leg, foot in zip(["left", "right"], spec["arms"], spec["legs"], spec["feet"]):
            for kind, chain in [("arm", arm), ("leg", leg)]:
                for segment in range(2):
                    name = ("upper_" if segment == 0 else "lower_")+kind+"_"+side
                    bones[name] = (chain[segment], chain[segment+1])
                    parts[name] = Image.new("RGBA", raw.size)
            parts["hand_"+side] = Image.new("RGBA", raw.size)
            parts["foot_"+side] = Image.new("RGBA", raw.size)
        for y in range(128):
            for x in range(96):
                rgba = raw.getpixel((x, y))
                if not rgba[3]: continue
                target = None
                for side, box in zip(["left", "right"], feet):
                    if box[0] <= x < box[2] and box[1] <= y < box[3]: target = "foot_"+side
                if target is None:
                    if polygons["head"].getpixel((x, y)): target = "head"
                    elif polygons["torso"].getpixel((x, y)): target = "torso"
                    else:
                        target = min(bones, key=lambda name: distance((x+.5,y+.5), *bones[name]))
                        for side, arm in zip(["left", "right"], spec["arms"]):
                            dx,dy=arm[2][0]-arm[1][0],arm[2][1]-arm[1][1]
                            distal=((x+.5-arm[2][0])*dx+(y+.5-arm[2][1])*dy)/math.hypot(dx,dy)
                            if distal>=-4 and math.dist((x+.5,y+.5),arm[2])<9: target="hand_"+side
                parts[target].putpixel((x,y), rgba)
        for side, arm, leg in zip(["left","right"], spec["arms"], spec["legs"]):
            joins=[(arm[1],["upper_arm_"+side,"lower_arm_"+side]),(arm[2],["lower_arm_"+side,"hand_"+side]),(leg[1],["upper_leg_"+side,"lower_leg_"+side]),(leg[2],["lower_leg_"+side,"foot_"+side])]
            for joint,names in joins:
                for y in range(max(0,int(joint[1])-2),min(128,int(joint[1])+3)):
                    for x in range(max(0,int(joint[0])-2),min(96,int(joint[0])+3)):
                        rgba=raw.getpixel((x,y))
                        if rgba[3] and math.dist((x+.5,y+.5),joint)<=2:
                            for name in names: parts[name].putpixel((x,y),rgba)
        pivot = [(spec["legs"][0][0][0]+spec["legs"][1][0][0])/2, 120]
        entry = {"id":resident_id,"authoredViews":1,"view":"front_three_quarter","pivot":pivot,"sourceCell":[index%3*96,index//3*128,96,128],"parts":{},"joints":{},"legs":{}}
        for side, arm, leg in zip(["left","right"], spec["arms"], spec["legs"]):
            entry["joints"][side+"Shoulder"] = arm[0]
            entry["joints"][side+"Hip"] = leg[0]
            entry["legs"][side] = leg
        reconstructed = Image.new("RGBA", raw.size)
        for name, image in parts.items():
            bounds = image.getbbox()
            hidden = bounds is None
            if hidden:
                assert name.startswith("upper_leg_"), (resident_id,name)
                joint = bones[name][0]
                bounds = (joint[0],joint[1],joint[0]+1,joint[1]+1)
            cropped = image.crop(bounds)
            x,y = slot%7*96,slot//7*128
            atlas.alpha_composite(cropped,(x,y))
            meta = {"rect":[x,y,cropped.width,cropped.height],"sourceBounds":list(bounds),"hiddenByAuthoredClothing":hidden}
            if name in bones: meta["bone"] = [list(at) for at in bones[name]]
            if name.startswith("hand_"):
                opaque=[(xx+.5,yy+.5) for yy in range(cropped.height) for xx in range(cropped.width) if cropped.getpixel((xx,yy))[3]]
                centroid=(sum(p[0] for p in opaque)/len(opaque),sum(p[1] for p in opaque)/len(opaque))
                grip=min(opaque,key=lambda p:math.dist(p,centroid))
                meta["grip"]=[grip[0]+bounds[0],grip[1]+bounds[1]]
            if name.startswith("foot_"):
                bottom=cropped.height-1
                xs=[xx+.5 for xx in range(cropped.width) if cropped.getpixel((xx,bottom))[3]]
                meta["sole"]=[sum(xs)/len(xs)+bounds[0],bounds[3]]
            entry["parts"][name]=meta
            reconstructed.alpha_composite(cropped,(bounds[0],bounds[1]))
            slot += 1
        for y in range(128):
            for x in range(96):
                a,b=raw.getpixel((x,y)),reconstructed.getpixel((x,y))
                assert a[3]==b[3] and (not a[3] or a==b),(resident_id,x,y)
        entry["exactRestReconstruction"] = True
        people[resident_id] = entry
    atlas.save(output/"atlas.png",optimize=False)
    metadata={"atlas":"res://resources/art/resident-rigs-v1/atlas.png","sourceSha256":SOURCE_SHA,"authoredViews":1,"partsAreOriginalPixels":True,"people":people}
    (output/"rigs.json").write_text(json.dumps(metadata,indent=2)+"\n")
    print(json.dumps({"people":len(people),"parts":slot,"pngSha256":hashlib.sha256((output/"atlas.png").read_bytes()).hexdigest(),"exactRestReconstruction":True}))

if __name__ == "__main__":
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source",type=Path,required=True)
    parser.add_argument("--out",type=Path,required=True)
    args=parser.parse_args()
    prepare(args.source,args.out)
