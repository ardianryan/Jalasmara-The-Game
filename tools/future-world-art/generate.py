#!/usr/bin/env python3
"""Draw Jalasmara's phase-gated field props on a fixed pixel grid."""
from __future__ import annotations

import hashlib
import json
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'client-godot/resources/art/future-world-v1'
PREVIEW = ROOT / 'docs/visual/future-world-props-v1-20261115.png'

P = {
    'ink': '#332c32', 'deep': '#49393c', 'wood': '#91694f', 'wood_light': '#c29465',
    'wood_dark': '#604837', 'brass': '#d8ad5f', 'brass_hi': '#f2d391',
    'steel': '#747e83', 'steel_dark': '#45565e', 'steel_light': '#b4b9ad',
    'sea': '#276b73', 'sea_hi': '#6ab3aa', 'sea_dark': '#244955',
    'blue': '#326477', 'blue_dark': '#1d394c', 'blue_hi': '#7ebfc2',
    'sand': '#d8be88', 'canvas': '#cbbb91', 'canvas_hi': '#e5d3a3',
    'canvas_dark': '#8e8b68', 'leaf': '#347965', 'leaf_mid': '#4c9c6a',
    'leaf_hi': '#8cbb79', 'leaf_dark': '#29504b', 'palm': '#468052',
    'palm_hi': '#8baa59', 'palm_dark': '#2b5646', 'fruit': '#bc743f',
    'fruit_hi': '#e8a753', 'screen': '#77d7bb', 'danger': '#b65154',
    'ember': '#f6bf61', 'flame': '#e88145', 'flame_dark': '#a84d48',
    'smoke': '#8b8190', 'smoke_light': '#b1a8aa',
}


def sheet(size):
    im = Image.new('RGBA', size, (0, 0, 0, 0))
    return im, ImageDraw.Draw(im)


def poly(d, pts, fill, line=P['ink'], width=1):
    d.polygon(pts, fill=fill)
    if line:
        d.line(pts + [pts[0]], fill=line, width=width, joint='curve')


def rect(d, xy, fill, line=P['ink'], width=1):
    d.rectangle(xy, fill=fill, outline=line, width=width)


def line(d, pts, fill, width=1):
    d.line(pts, fill=fill, width=width, joint='curve')


def solar_panel():
    im,d=sheet((64,32))
    # A tilted copper-railed module, viewed from the village's three-quarter camera.
    poly(d,[(14,20),(18,15),(21,17),(17,23)],P['steel_dark'])
    poly(d,[(47,14),(51,11),(54,13),(50,17)],P['steel_dark'])
    poly(d,[(5,15),(42,3),(61,10),(24,23)],P['brass'])
    poly(d,[(8,15),(42,5),(58,10),(24,21)],P['blue_dark'],P['sea_dark'])
    for j in range(1,4):
        a=8+j*4; b=24+j*4
        line(d,[(a,15-j),(b,21-j)],P['sea_hi'])
    for j in range(1,5):
        x=8+j*8
        line(d,[(x,15-j*2),(x+16,21-j*2)],P['blue_hi'])
    line(d,[(8,14),(42,4),(58,9)],P['brass_hi'])
    for x,y in [(6,15),(42,4),(59,10),(24,22)]: d.point((x,y),fill=P['brass_hi'])
    return im


def generator():
    im,d=sheet((64,48))
    # Compact diesel-electric set; dark vents and a separate copper exhaust.
    poly(d,[(10,17),(38,10),(56,18),(28,26)],P['steel_light'])
    poly(d,[(10,17),(28,26),(28,39),(10,31)],P['steel_dark'])
    poly(d,[(28,26),(56,18),(56,32),(28,39)],P['steel'])
    line(d,[(12,19),(27,26),(27,37)],P['steel_light'])
    line(d,[(30,27),(54,20)],P['steel_light'])
    rect(d,(32,27,49,33),P['deep'],P['steel_dark'])
    for x in (35,39,43,47): line(d,[(x,27),(x,33)],P['steel'])
    rect(d,(13,24,22,28),P['sea_dark'],P['brass'])
    d.point((17,26),fill=P['sea_hi'])
    line(d,[(46,12),(46,5),(50,5),(50,14)],P['brass'],2)
    line(d,[(8,34),(9,39),(22,42),(55,33)],P['wood_dark'],2)
    for x,y in [(17,39),(47,36)]:
        rect(d,(x-3,y-2,x+3,y+2),P['ink'],P['steel_dark'])
        d.point((x,y),fill=P['steel_light'])
    return im


def inspector_container():
    im,d=sheet((128,96))
    # Independent inspector's quarters; this is not the director's RV or Raka's office.
    poly(d,[(13,38),(52,21),(112,30),(73,48)],P['steel_light'])
    poly(d,[(13,38),(73,48),(73,80),(13,69)],P['canvas_dark'])
    poly(d,[(73,48),(112,30),(112,62),(73,80)],P['steel'])
    poly(d,[(15,37),(52,23),(110,31),(73,45)],P['steel_dark'])
    line(d,[(17,36),(52,25),(106,32)],P['steel_light'],2)
    # Ribbing follows each receding plane.
    for x in range(22,72,10):
        line(d,[(x,41+(x-13)//6),(x,68+(x-13)//6)],P['wood_dark'])
    for x in range(80,109,8):
        line(d,[(x,45-(x-73)//2),(x,74-(x-73)//2)],P['steel_dark'])
    # Warm window and canopy; door below the long roof plane.
    poly(d,[(25,45),(41,48),(41,60),(25,57)],P['blue_dark'])
    poly(d,[(27,47),(39,49),(39,57),(27,55)],P['brass'])
    line(d,[(33,48),(33,56)],P['deep'])
    poly(d,[(84,48),(101,41),(101,55),(84,62)],P['wood_dark'])
    poly(d,[(86,50),(98,46),(98,54),(86,59)],P['blue_dark'])
    line(d,[(91,48),(91,57)],P['steel_light'])
    poly(d,[(49,51),(63,54),(63,76),(49,73)],P['wood_dark'])
    line(d,[(51,53),(61,55),(61,74)],P['brass'])
    d.ellipse((58,64,60,66),fill=P['brass_hi'])
    poly(d,[(46,74),(66,78),(71,81),(50,78)],P['wood_light'])
    line(d,[(12,70),(73,82),(113,64)],P['ink'],2)
    # Repeating copper attachment points accept separate solar modules.
    for x,y in [(28,35),(53,30),(85,34)]: rect(d,(x,y,x+2,y+2),P['brass_hi'],P['brass'])
    return im


def tent():
    im,d=sheet((128,96))
    # A field shelter with asymmetric canvas, pitched toward the lower-right camera.
    poly(d,[(19,72),(52,21),(79,25),(111,72),(79,82)],P['canvas_dark'])
    poly(d,[(19,72),(52,21),(79,25),(67,74)],P['canvas_hi'])
    poly(d,[(67,74),(79,25),(111,72),(79,82)],P['canvas'])
    line(d,[(52,22),(67,74)],P['wood_dark'],2)
    line(d,[(79,26),(79,82)],P['wood_dark'],2)
    # Seamed door with a dark interior; folded flaps create volume.
    poly(d,[(43,71),(58,41),(68,74)],P['deep'])
    poly(d,[(43,71),(58,42),(56,73)],P['canvas_dark'])
    poly(d,[(58,42),(68,74),(57,73)],P['wood_light'])
    line(d,[(23,70),(47,29),(53,23)],P['sand'])
    line(d,[(82,27),(106,69)],P['canvas_hi'])
    # Teal weather strip and stitched seams distinguish this from a generic teepee.
    line(d,[(24,66),(49,27),(76,30),(105,66)],P['sea_dark'],2)
    for x,y in [(38,47),(44,37),(58,35),(84,43),(91,54)]:
        d.point((x,y),fill=P['wood_dark'])
    line(d,[(67,73),(79,79),(105,70)],P['sea_hi'])
    line(d,[(19,72),(8,82)],P['wood_dark'])
    line(d,[(111,72),(120,84)],P['wood_dark'])
    line(d,[(8,82),(11,84)],P['steel_dark'],2)
    line(d,[(120,84),(123,84)],P['steel_dark'],2)
    for x,y in [(30,72),(78,79),(105,72)]:
        rect(d,(x,y,x+3,y+3),P['brass'],P['wood_dark'])
    return im


def satellite():
    im,d=sheet((64,64))
    # A generic field satellite terminal; no brand mark or proprietary shape traced.
    line(d,[(29,50),(29,32)],P['steel_dark'],3)
    line(d,[(28,48),(19,58)],P['steel_dark'],2)
    line(d,[(30,48),(40,58)],P['steel_dark'],2)
    line(d,[(19,58),(40,58)],P['wood_dark'])
    poly(d,[(11,22),(23,12),(48,18),(53,31),(43,38),(19,34)],P['steel_dark'])
    poly(d,[(14,21),(23,15),(46,20),(49,30),(42,35),(20,31)],P['canvas_hi'])
    poly(d,[(22,17),(44,21),(46,29),(37,33),(21,29)],P['steel_light'],None)
    line(d,[(14,22),(21,30),(42,35)],P['steel'])
    line(d,[(38,21),(43,16),(48,16)],P['steel_dark'],2)
    d.ellipse((47,13,51,17),fill=P['brass_hi'],outline=P['wood_dark'])
    rect(d,(26,40,34,46),P['sea_dark'],P['brass'])
    d.point((31,42),fill=P['screen'])
    return im


def worktable():
    im,d=sheet((64,48))
    poly(d,[(5,19),(36,13),(59,19),(28,26)],P['wood_light'])
    poly(d,[(5,19),(28,26),(28,31),(5,24)],P['wood_dark'])
    poly(d,[(28,26),(59,19),(59,24),(28,31)],P['wood'])
    for a,b in [((10,25),(10,41)),((24,29),(24,45)),((52,25),(52,39))]: line(d,[a,b],P['wood_dark'],3)
    line(d,[(10,41),(24,45)],P['ink'],2)
    line(d,[(24,45),(52,39)],P['ink'],2)
    # map, not a real-world brand label
    poly(d,[(17,17),(30,15),(40,18),(28,21)],P['sand'],P['brass'])
    line(d,[(21,18),(28,17),(34,19)],P['sea'])
    return im


def laptop():
    im,d=sheet((32,32))
    poly(d,[(6,8),(23,7),(24,20),(7,22)],P['steel_dark'])
    poly(d,[(8,10),(21,9),(22,18),(9,20)],P['blue_dark'],P['brass'])
    line(d,[(10,16),(14,13),(18,15),(20,12)],P['screen'])
    poly(d,[(7,22),(24,20),(29,24),(12,27)],P['steel_light'])
    poly(d,[(12,24),(23,22),(26,24),(14,26)],P['steel_dark'],None)
    return im


def evidence_case():
    im,d=sheet((32,32))
    poly(d,[(5,12),(21,10),(28,15),(12,17)],P['steel_light'])
    poly(d,[(5,12),(12,17),(12,27),(5,23)],P['steel_dark'])
    poly(d,[(12,17),(28,15),(28,24),(12,27)],P['wood'])
    line(d,[(15,18),(25,16)],P['brass'])
    rect(d,(16,19,21,23),P['brass'],P['wood_dark'])
    rect(d,(12,6,20,11),None,P['wood_dark'],2)
    return im


def antenna():
    im,d=sheet((32,48))
    line(d,[(16,38),(16,8)],P['steel_dark'],2)
    line(d,[(16,19),(7,14)],P['steel_dark'])
    line(d,[(16,19),(25,14)],P['steel_dark'])
    line(d,[(16,8),(12,4)],P['brass'])
    line(d,[(16,8),(20,4)],P['brass'])
    d.point((16,3),fill=P['sea_hi'])
    for x,y in [(7,14),(25,14)]: d.ellipse((x-2,y-2,x+2,y+2),fill=P['brass_hi'],outline=P['wood_dark'])
    poly(d,[(8,42),(16,38),(25,42),(17,46)],P['steel_dark'])
    line(d,[(16,38),(8,42)],P['steel_light'])
    return im


def palm():
    im,d=sheet((96,128))
    # Oil palm has stout scarred trunk, drooping radial fronds and orange fruit clusters.
    poly(d,[(43,119),(47,111),(48,88),(50,69),(47,48),(53,34),(62,36),(57,57),(57,78),(55,108),(58,119)],P['wood_dark'])
    for y,x in [(49,52),(60,51),(71,52),(82,52),(93,51),(104,50)]:
        line(d,[(x-4,y),(x+3,y+4)],P['wood_light'],2)
        line(d,[(x+2,y),(x-3,y+5)],P['deep'])
    # Drooping feather fronds; varied planes make crown legible at 1x.
    fronds=[
        ([(55,37),(32,27),(13,36),(3,51),(11,45),(23,43),(38,41),(53,45)],'leaf_dark'),
        ([(55,36),(28,18),(14,19),(3,31),(17,27),(30,28),(51,45)],'leaf'),
        ([(55,35),(35,11),(21,7),(14,12),(28,14),(47,32)],'leaf_mid'),
        ([(55,33),(52,8),(58,2),(64,11),(59,24),(62,38)],'leaf_hi'),
        ([(55,34),(73,10),(85,10),(90,17),(79,19),(62,40)],'leaf'),
        ([(57,36),(77,25),(93,29),(95,43),(86,36),(72,37),(60,44)],'leaf_mid'),
        ([(56,39),(75,46),(88,58),(92,71),(83,63),(70,55),(54,46)],'leaf_dark'),
        ([(55,40),(33,51),(17,65),(14,78),(23,69),(38,59),(57,47)],'leaf'),
        ([(53,37),(38,5),(31,2),(32,10),(42,24),(48,42)],'leaf'),
        ([(56,36),(65,3),(71,2),(71,11),(63,27),(61,43)],'leaf_mid'),
        ([(54,40),(25,39),(7,49),(3,60),(13,54),(31,49),(55,47)],'leaf_dark'),
        ([(57,40),(80,38),(94,49),(94,60),(85,53),(72,48),(55,46)],'leaf'),
    ]
    for pts,key in fronds: poly(d,pts,P[key],P['palm_dark'])
    # Short alternating pinnae make this a feather-leaf oil palm, not a coconut.
    pinnae=[
        [(16,39),(12,45),(19,40)],[(25,35),(20,41),(28,37)],[(36,34),(30,40),(39,36)],
        [(24,23),(17,25),(25,27)],[(35,24),(29,28),(37,29)],
        [(71,25),(78,22),(74,28)],[(80,30),(88,30),(83,34)],
        [(70,46),(76,51),(69,49)],[(77,53),(84,61),(75,56)],
        [(30,55),(23,64),(34,58)],[(24,64),(19,73),(27,67)],
        [(48,18),(44,11),(51,21)],[(59,18),(65,10),(59,23)],
    ]
    for j,pts in enumerate(pinnae):
        poly(d,pts,P['palm_hi'] if j%3==0 else P['palm'],None)
    for pts in [[(16,25),(28,25),(42,32)],[(67,21),(80,17)],[(10,39),(23,35)],[(68,47),(81,55)],[(35,49),(24,62)]]:
        line(d,pts,P['palm_hi'])
    # Two dense orange-red oil-fruit bunches visibly hang below the frond bases.
    for cx,cy in [(43,52),(64,51)]:
        poly(d,[(cx-7,cy-4),(cx+3,cy-6),(cx+8,cy),(cx+5,cy+9),(cx-4,cy+8),(cx-8,cy+2)],P['wood_dark'])
        for ox,oy in [(-4,-2),(0,-4),(4,-3),(-6,1),(-2,1),(3,1),(6,2),(-4,5),(0,5),(4,6)]:
            rect(d,(cx+ox-1,cy+oy-1,cx+ox+1,cy+oy+1),P['fruit'],P['wood_dark'])
            d.point((cx+ox,cy+oy-1),fill=P['fruit_hi'])
        line(d,[(cx-3,cy-5),(cx,cy-8)],P['palm_dark'])
    return im


def charred_trunk():
    im,d=sheet((64,96))
    poly(d,[(24,92),(25,72),(23,54),(28,28),(32,13),(37,14),(35,30),(40,49),(37,73),(42,92)],P['deep'])
    poly(d,[(29,91),(28,60),(32,28),(34,18),(36,26),(34,62),(38,91)],P['wood_dark'],None)
    poly(d,[(28,50),(17,41),(12,29),(15,27),(22,39),(30,42)],P['deep'])
    poly(d,[(36,47),(47,35),(53,19),(55,21),(52,37),(38,55)],P['deep'])
    line(d,[(29,79),(36,72),(31,66)],P['flame_dark'])
    line(d,[(31,40),(36,32)],P['smoke'])
    line(d,[(18,41),(27,47)],P['wood_dark'])
    return im


def flame_sheet():
    out=Image.new('RGBA',(4*64,64),(0,0,0,0))
    for i in range(4):
        im,d=sheet((64,64))
        sway=[-2,0,2,0][i]; height=[34,39,36,42][i]
        poly(d,[(15,58),(20,45),(18,37),(27,45),(29,64-height),(35,32),(39,45),(49,40),(47,53),(52,60),(40,61),(20,61)],P['flame_dark'],None)
        poly(d,[(19,57),(25+sway,40),(25,50),(31+sway,64-height),(37,43),(41,52),(47,49),(46,58)],P['flame'],None)
        poly(d,[(25,57),(29+sway,44),(32,49),(35+sway,64-height+10),(38,51),(42,56)],P['ember'],None)
        for x,y in [(18+i,47),(48-i,45),(39+i,37)]: d.point((x,y),fill=P['brass_hi'])
        out.paste(im,(i*64,0),im)
    return out


def smoke_sheet():
    out=Image.new('RGBA',(4*64,64),(0,0,0,0))
    for i in range(4):
        im,d=sheet((64,64))
        off=[0,2,4,1][i]
        for cx,cy,r,col in [(29,53,7,P['smoke']),(36+off,44,10,P['smoke_light']),(27-off,33,10,P['smoke']),(38+off,22,9,P['smoke_light']),(26+off,13,7,P['smoke'])]:
            d.ellipse((cx-r,cy-r,cx+r,cy+r),fill=col)
            d.rectangle((cx-r+2,cy+r-2,cx+r-2,cy+r),fill=col)
        # Internal short highlight planes; no full opaque cell/backdrop.
        line(d,[(28-off,42),(34+off,38)],'#d0c8ba',2)
        out.paste(im,(i*64,0),im)
    return out


def validate(name, im, size):
    assert im.mode=='RGBA' and im.size==size,(name,im.mode,im.size)
    assert im.getbbox(),name
    alpha=im.getchannel('A')
    opaque=sum(1 for v in alpha.getdata() if v>0)
    assert 0.03 < opaque/(size[0]*size[1]) < 0.77,(name,opaque,size)
    assert alpha.getpixel((0,0))==0 and alpha.getpixel((size[0]-1,0))==0,name
    # Strictly pixel-drawn assets; no interpolation or soft alpha contamination.
    assert set(alpha.getdata()) <= {0,255},name


def main():
    OUT.mkdir(parents=True,exist_ok=True)
    art={
        'solar_panel_roof':(solar_panel(),(64,32),[32,31],'director_rv_and_inspector_quarters','phase_1_or_later'),
        'generator_set':(generator(),(64,48),[32,47],'director_rv_and_inspector_quarters','phase_1_or_later'),
        'inspector_bunk_container':(inspector_container(),(128,96),[64,95],'future_inspector_quarters','later'),
        'saras_field_tent':(tent(),(128,96),[64,95],'saras_north_field_camp','later'),
        'saras_satellite_terminal':(satellite(),(64,64),[32,63],'saras_north_field_camp','later'),
        'saras_worktable':(worktable(),(64,48),[32,47],'saras_north_field_camp','later'),
        'saras_rugged_laptop':(laptop(),(32,32),[16,31],'saras_north_field_camp','later'),
        'saras_evidence_case':(evidence_case(),(32,32),[16,31],'saras_north_field_camp','later'),
        'saras_antenna':(antenna(),(32,48),[16,47],'saras_north_field_camp','later'),
        'oil_palm_mature':(palm(),(96,128),[48,127],'north_forest_future_plantation','future_only'),
        'forest_charred_trunk':(charred_trunk(),(64,96),[32,95],'north_forest_future_fire','future_only'),
        'forest_fire_sheet':(flame_sheet(),(256,64),[32,63],'north_forest_future_fire','future_only'),
        'forest_smoke_sheet':(smoke_sheet(),(256,64),[32,63],'north_forest_future_fire','future_only'),
    }
    manifest={'schemaVersion':1,'source':'Code-authored by Jalasmara project; no AI/image pack pixels','license':'Jalasmara LICENSE section 2 (project art, all rights reserved)','pixelGrid':'one source pixel per drawn pixel; nearest texture filter','runtimePlacement':'none; all sprites are phase-gated authoring assets','assets':{}}
    for name,(im,size,pivot,site,gate) in art.items():
        validate(name,im,size)
        path=OUT/f'{name}.png'; im.save(path,optimize=True)
        rec={'path':f'res://resources/art/future-world-v1/{name}.png','sizePx':list(size),'pivotPx':pivot,'site':site,'phaseGate':gate,'frames':4 if name.endswith('_sheet') else 1,'sha256':hashlib.sha256(path.read_bytes()).hexdigest()}
        if name.endswith('_sheet'): rec['frameSizePx']=[64,64]
        manifest['assets'][name]=rec
    (OUT/'manifest.json').write_text(json.dumps(manifest,indent=2,ensure_ascii=False)+'\n')
    # Curated proof sheet only; checkerboard exists in this preview, never in runtime PNGs.
    cardw,cardh=216,210
    rows=(len(art)+3)//4
    contact=Image.new('RGB',(cardw*4,cardh*rows),'#e6dcc2')
    d=ImageDraw.Draw(contact)
    for n,(name,(im,size,_,site,gate)) in enumerate(art.items()):
        gx=(n%4)*cardw; gy=(n//4)*cardh
        d.rectangle((gx+5,gy+5,gx+cardw-5,gy+cardh-5),fill='#f3ead5',outline='#7f684d',width=2)
        for yy in range(gy+20,gy+177,12):
            for xx in range(gx+18,gx+198,12):
                if ((xx-gx)//12+(yy-gy)//12)%2==0:d.rectangle((xx,yy,xx+11,yy+11),fill='#e3dbc7')
        if name.endswith('_sheet'):
            sample=im.crop((0,0,64,64))
        else: sample=im
        zoom=min(2,(170//max(sample.size)))
        zoom=max(1,zoom)
        sample=sample.resize((sample.width*zoom,sample.height*zoom),Image.Resampling.NEAREST)
        contact.paste(sample,(gx+(cardw-sample.width)//2,gy+26+(152-sample.height)//2),sample)
        d.text((gx+13,gy+185),name,fill='#332c32')
    PREVIEW.parent.mkdir(parents=True,exist_ok=True)
    contact.save(PREVIEW,optimize=True)
    print(json.dumps({'assets':len(art),'proof':str(PREVIEW),'bytes':sum((OUT/f'{x}.png').stat().st_size for x in art)},indent=2))

if __name__=='__main__':main()
