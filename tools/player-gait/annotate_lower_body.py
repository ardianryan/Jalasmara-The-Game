#!/usr/bin/env python3
"""Author cutout coordinates on existing eight-view idle art; never redraw pixels."""
import hashlib,json
from pathlib import Path
from PIL import Image
ROOT=Path(__file__).resolve().parents[2]
ART=ROOT/'client-godot/resources/art/player-gait'
OUT=ROOT/'client-godot/resources/art/player-lower-body'
DIRECTIONS=['east','south_east','south','south_west','west','north_west','north','north_east']
# Anatomical left/right, including the occluded profile leg. Profile legs reuse
# their own authored view; no east/west mirroring or replacement anatomy.
HIP_X=[(65,68),(70,59),(71,58),(68,58),(61,64),(59,70),(58,71),(61,71)]

def generate(outfit):
    source=ART/f'male-nusantara-{outfit}-idle-8way-v1.png'
    image=Image.open(source).convert('RGBA')
    views={}
    for index,direction in enumerate(DIRECTIONS):
        legs={}
        for side,x in zip(['left','right'],HIP_X[index]):
            specs={'thigh':[x-4,76,8,12],'shin':[x-4,88,8,11],
                   'foot':[x-6,98,14,6]}
            foot=image.crop((index*128+specs['foot'][0],98,index*128+specs['foot'][0]+14,104))
            bottom=foot.getbbox()[3] if foot.getbbox() else 0
            opaque=[px for px in range(foot.width) if bottom and foot.getpixel((px,bottom-1))[3]>=128]
            if not opaque: raise AssertionError((outfit,direction,side,'no original sole pixel'))
            legs[side]={'hip':[x,76],'knee':[x,88],'ankle':[x,99],
                        'parts':specs,'solePixel':[sum(px+.5 for px in opaque)/len(opaque),bottom],
                        'occludedReuse': direction in ['east','west']}
        views[direction]={'sourceColumn':index,'upperCutY':76,'legs':legs}
    result={'identity':'male_nusantara','outfit':outfit,'cell':[128,128],
            'pivot':[64,104],'source':'res://resources/art/player-gait/'+source.name,
            'sourceSha256':hashlib.sha256(source.read_bytes()).hexdigest(),
            'method':'explicit original idle rectangle cutouts; overlapping profile leg reused; no fill, mirror, recolor or generated pixels',
            'status':'opt-in articulation candidate, native review required','views':views}
    OUT.mkdir(parents=True,exist_ok=True)
    (OUT/f'male-nusantara-{outfit}-v1.json').write_text(json.dumps(result,indent=2)+'\n')
    return result

if __name__=='__main__':
    for outfit in ['daily','explorer']: generate(outfit)
