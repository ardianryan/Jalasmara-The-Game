#!/usr/bin/env python3
"""Offline cutout preparation of original Jalasmara portraits, with explicit pilot masks."""
import hashlib
import json
import math
from pathlib import Path
from PIL import Image, ImageDraw

ROOT=Path(__file__).resolve().parents[2]
ART=ROOT/'client-godot/resources/art'
OUT=ART/'npc-rigs'
SCALE=100/512
CELL=64
SPECS={
 'ujang':{'name':'Mang Ujang','source':'village-residents-v1.png','box':[1024,0,1536,512],'feet':[235,493],'hip':[236,300],
 'head':[[132,26],[190,5],[278,10],[285,73],[278,97],[278,119],[245,143],[185,126],[151,99]],
 'torso':[[170,143],[272,136],[312,165],[319,292],[266,311],[204,300],[173,260],[151,191]],
 'patches':[([[154,210],[201,219],[221,265],[201,285],[164,265]], [217,173,258,230])],
 'shoulders':[[173,185],[310,171]],'arms':[[[169,201],[180,237],[211,270]],[[323,163],[340,188],[343,146]]],
 'legjoints':[[[204,305],[183,385],[178,463]],[[281,304],[291,386],[299,463]]],'widths':[54,38],
 'footboxes':[[141,454,209,496],[266,452,339,497]],'neck':[235,139],'cloth':'816348','hair':'697079'},
 'darmi':{'name':'Bu Darmi','source':'npc-atlas.png','box':[0,627,627,1254],'feet':[275,493],'hip':[274,330],
 'head':[[188,48],[227,24],[286,20],[332,40],[342,88],[326,126],[285,149],[233,137],[202,111]],
 'torso':[[202,137],[250,133],[299,142],[328,167],[337,210],[347,274],[334,327],[243,333],[219,288],[178,268],[148,232],[151,177]],
 'patches':[([[235,218],[351,218],[348,258],[232,260]], [248,163,288,207])],
 'shoulders':[[228,179],[315,174]],'arms':[[[232,192],[252,232],[336,235]],[[320,184],[339,216],[367,232]]],
 'legjoints':[[[253,331],[238,397],[229,461]],[[300,329],[311,397],[310,459]]],'widths':[69,57],
 'footboxes':[[199,452,258,497],[278,450,352,493]],'neck':[278,144],'cloth':'b7aa7a','hair':'45414a'},
 'sari':{'name':'Yu Sari','source':'village-residents-v1.png','box':[512,512,1024,1024],'feet':[232,504],'hip':[242,347],
 'head':[[140,47],[179,17],[231,16],[278,33],[298,73],[292,113],[268,138],[231,150],[190,130],[157,115]],
 'torso':[[177,145],[224,138],[279,145],[312,170],[320,242],[316,352],[290,439],[208,453],[156,435],[174,352],[172,281],[157,210]],
 'patches':[([[168,217],[232,219],[260,251],[221,275],[166,259]], [229,164,270,209]),([[166,278],[242,275],[244,340],[172,348]], [249,304,288,367])],
 'shoulders':[[171,183],[306,171]],'arms':[[[162,205],[193,234],[247,253]],[[323,181],[338,218],[350,155]]],
 'legjoints':[[[211,347],[197,421],[180,477]],[[277,347],[269,420],[267,478]]],'widths':[58,44],
 'footboxes':[[147,470,212,510],[234,472,297,510]],'neck':[242,143],'cloth':'555d73','hair':'48444e'},
}


def patch_fill(im, polygon, sample):
    mask=Image.new('L',im.size); ImageDraw.Draw(mask).polygon(polygon,fill=255)
    tile=im.crop(sample)
    fill=Image.new('RGBA',im.size)
    for y in range(0,512,tile.height):
        for x in range(0,512,tile.width): fill.alpha_composite(tile,(x,y))
    im.paste(fill,(0,0),mask)


def crop_part(im, polygon):
    mask=Image.new('L',im.size); ImageDraw.Draw(mask).polygon(polygon,fill=255)
    result=im.copy();result.putalpha(Image.composite(im.getchannel('A'),Image.new('L',im.size),mask))
    box=result.getbbox()
    if not box: raise ValueError('Empty part')
    crop=result.crop(box)
    crop=crop.resize((max(1,round(crop.width*SCALE)),max(1,round(crop.height*SCALE))),Image.Resampling.NEAREST)
    return crop,[(box[0]+box[2])/2,(box[1]+box[3])/2]


def bone(im,a,b,width,solid=False):
    dx,dy=b[0]-a[0],b[1]-a[1];length=math.hypot(dx,dy);ux,uy=dx/length,dy/length
    w=max(3,round(width*SCALE));h=max(4,round(length*SCALE))
    part=Image.new('RGBA',(w,h))
    for y in range(h):
        for x in range(w):
            along=(y+.5)/SCALE;cross=(x+.5-w/2)/SCALE
            sx,sy=round(a[0]+ux*along-uy*cross),round(a[1]+uy*along+ux*cross)
            if 0<=sx<512 and 0<=sy<512:
                pixel=im.getpixel((sx,sy))
                if pixel[3]>=128: part.putpixel((x,y),pixel)
    if solid:
        original=part.copy()
        opaque=[(x,y,original.getpixel((x,y))) for y in range(h) for x in range(w) if original.getpixel((x,y))[3]>=128]
        for y in range(h):
            half=max(1.2,w*(.46-.10*y/max(1,h-1)))
            for x in range(w):
                if abs(x-(w-1)/2)>half:
                    part.putpixel((x,y),(0,0,0,0));continue
                if part.getpixel((x,y))[3]<128 and opaque:
                    nearest=min(opaque,key=lambda pixel:(pixel[0]-x)**2+(pixel[1]-y)**2)
                    part.putpixel((x,y),nearest[2])
    return part


def generate(key,spec):
    raw=Image.open(ART/spec['source']).convert('RGBA').crop(spec['box']).resize((512,512),Image.Resampling.NEAREST)
    raw.putalpha(raw.getchannel('A').point(lambda a:255 if a>=128 else 0))
    clean=raw.copy()
    for polygon,sample in spec['patches']: patch_fill(clean,polygon,sample)
    atlas=Image.new('RGBA',(320,256))
    metadata={'id':key,'name':spec['name'],'atlas':'res://resources/art/npc-rigs/'+key+'.png','cellSize':64,'grid':[5,4],'bodyHeight':100,'footPivot':[0,0],'parts':{},'joints':{},'source':spec['source'],'sourceSha256':hashlib.sha256((ART/spec['source']).read_bytes()).hexdigest(),'method':'original portrait cutouts; covered cloth patched from same portrait; back view simplified from sampled palette'}
    slot=0
    def add(name,im,center=None,pivot=None):
        nonlocal slot
        if im.width>62 or im.height>62: raise ValueError((name,im.size))
        x,y=(slot%5)*64,(slot//5)*64
        px,py=(64-im.width)//2,(64-im.height)//2
        atlas.alpha_composite(im,(x+px,y+py))
        entry={'cell':slot,'size':list(im.size),'origin':[px,py]}
        if center is not None:entry['center']=[(center[0]-spec['feet'][0])*SCALE,(center[1]-spec['feet'][1])*SCALE]
        if pivot is not None:entry['pivot']=pivot
        metadata['parts'][name]=entry
        slot+=1
    torso,center=crop_part(clean,spec['torso']);add('torso',torso,center)
    head,center=crop_part(raw,spec['head']);add('head',head,center)
    for i,side in enumerate(['left','right']):
        shoulder=spec['shoulders'][i]
        metadata['joints'][side+'Shoulder']=[(shoulder[0]-spec['feet'][0])*SCALE,(shoulder[1]-spec['feet'][1])*SCALE]
        a,b,c=spec['arms'][i]
        upper=bone(raw,a,b,37);lower=bone(raw,b,c,28)
        add('upper_arm_'+side,upper,pivot=[upper.width/2,0])
        add('lower_arm_'+side,lower,pivot=[lower.width/2,0])
        hand=raw.crop((c[0]-13,c[1]-9,c[0]+13,c[1]+16)).resize((5,5),Image.Resampling.NEAREST)
        add('hand_'+side,hand,pivot=[2.5,0])
    for i,side in enumerate(['left','right']):
        a,b,c=spec['legjoints'][i]
        metadata['joints'][side+'Hip']=[(a[0]-spec['feet'][0])*SCALE,(a[1]-spec['feet'][1])*SCALE]
        upper=bone(raw,a,b,spec['widths'][0],True);lower=bone(raw,b,c,spec['widths'][1],True)
        add('upper_leg_'+side,upper,pivot=[upper.width/2,0]);add('lower_leg_'+side,lower,pivot=[lower.width/2,0])
        box=spec['footboxes'][i];foot=raw.crop(box).resize((round((box[2]-box[0])*SCALE),round((box[3]-box[1])*SCALE)),Image.Resampling.NEAREST)
        add('foot_'+side,foot,pivot=[foot.width/2,0])
    # A single front portrait cannot supply a photographed rear view: these are explicit original palette constructions.
    for name,part,color in [('head_back',head,spec['hair']),('torso_back',torso,spec['cloth'])]:
        back=Image.new('RGBA',part.size)
        pix=part.load();dst=back.load();rgb=tuple(bytes.fromhex(color.lstrip('#')))
        for y in range(part.height):
            for x in range(part.width):
                if pix[x,y][3]:
                    shade=0.88+((x//3+y//5)%3)*.05
                    dst[x,y]=tuple(round(c*shade) for c in rgb)+(255,)
        draw=ImageDraw.Draw(back)
        if name=='head_back': draw.line((2,back.height*.6,back.width-3,back.height*.6),fill='#a58b59',width=2)
        else: draw.line((back.width//2,2,back.width//2,back.height-3),fill='#454944',width=1)
        add(name,back)
    metadata['neck']=[(spec['neck'][0]-spec['feet'][0])*SCALE,(spec['neck'][1]-spec['feet'][1])*SCALE]
    OUT.mkdir(parents=True,exist_ok=True);atlas.save(OUT/(key+'.png'))
    (OUT/(key+'.json')).write_text(json.dumps(metadata,indent=2)+'\n')

if __name__=='__main__':
    for key,spec in SPECS.items():generate(key,spec)
