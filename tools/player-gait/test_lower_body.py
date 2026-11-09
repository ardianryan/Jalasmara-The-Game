#!/usr/bin/env python3
"""Verify candidate annotations against immutable original eight-view pixels."""
import hashlib,json,tempfile
from pathlib import Path
from PIL import Image
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'client-godot/resources/art/player-lower-body'
checks=0
for outfit in ['daily','explorer']:
    data=json.loads((OUT/f'male-nusantara-{outfit}-v1.json').read_text())
    source=ROOT/'client-godot'/data['source'].removeprefix('res://')
    assert hashlib.sha256(source.read_bytes()).hexdigest()==data['sourceSha256']
    image=Image.open(source).convert('RGBA')
    assert len(data['views'])==8 and data['pivot']==[64,104]
    assert sorted(view['sourceColumn'] for view in data['views'].values())==list(range(8))
    for direction,view in data['views'].items():
        assert view['upperCutY']==76
        for side,leg in view['legs'].items():
            assert leg['hip'][1]<leg['knee'][1]<leg['ankle'][1]
            for name,rect in leg['parts'].items():
                x,y,w,h=rect
                assert 0<=x<x+w<=128 and 0<=y<y+h<=128
                crop=image.crop((view['sourceColumn']*128+x,y,view['sourceColumn']*128+x+w,y+h))
                assert crop.getbbox(),(outfit,direction,side,name)
                if name=='foot':
                    alpha=crop.getchannel('A');bottom=crop.getbbox()[3]
                    ankle=leg['ankle'];assert alpha.getpixel((ankle[0]-x,ankle[1]-y))>=128
                    samples=[x for x in range(w) if alpha.getpixel((x,bottom-1))>=128]
                    assert samples and abs(leg['solePixel'][0]-sum(x+.5 for x in samples)/len(samples))<1e-8
                    assert leg['solePixel'][1]==bottom
                    assert leg['soleEdgePixels']==[[min(samples)+.5,bottom],[max(samples)+.5,bottom]]
                checks+=1
    assert 'no fill, mirror, recolor or generated pixels' in data['method']
# The pilot remains off in normal runtime and cannot silently replace other identities.
actors=(ROOT/'client-godot/scripts/land/LandActors3D.gd').read_text()
rig=(ROOT/'client-godot/scripts/NalaLowerBody3D.gd').read_text()
assert 'get_meta("nala_lower_body_pilot",false)' in actors
assert '=="male_nusantara"' in rig and '["daily","explorer"]' in rig
assert 'consume_foot_contacts' not in rig
print(f'LOWER BODY SOURCE PASS: {checks} original opaque cutouts, eight authored views × two outfits, real source sole pixels, immutable hashes, opt-in identity scope')
