"""Slice original HUD atlases into small nearest-filtered Godot PNG resources."""
import argparse,hashlib,json
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
ROOT=Path(__file__).resolve().parents[2]
ICONS=['map','journal','satchel','character','speaker-on','speaker-off','oxygen-tank','depth-anchor','coin','jala-net','interact-hand','quest-scroll','settings','fullscreen','close','compass']
FRAMES=[('button-normal',(64,64),8),('button-hover',(64,64),8),('button-pressed',(64,64),8),('button-selected',(64,64),8),('panel-dark',(128,128),16),('panel-parchment',(128,128),16),('inventory-slot',(64,64),8),('title-plaque',(256,64),16),('portrait-frame',(96,96),12),('minimap-rim',(128,128),16),('joystick-ring',(128,128),16),('joystick-thumb',(64,64),8),('bar-frame',(256,48),12),('bar-fill',(224,24),4),('coin-chip',(128,48),12),('dialogue-frame',(320,128),20)]
p=argparse.ArgumentParser();p.add_argument('--out',type=Path,default=ROOT/'client-godot/resources/art/hud-bahari-v1');a=p.parse_args();a.out.mkdir(parents=True,exist_ok=True)
source=ROOT/'assets/source-2d/hud-bahari-v1';records=[]
def cut(atlas,index,kind):
 col=index%4;row=index//4
 box=(round(col*atlas.width/4),round(row*atlas.height/4),round((col+1)*atlas.width/4),round((row+1)*atlas.height/4))
 if kind=='frames' and index in [7,15]:box=(round(atlas.width*.70),box[1],box[2],box[3])
 im=atlas.crop(box).convert('RGBA');im.putalpha(im.getchannel('A').point(lambda v:255 if v>=128 else 0))
 pixels=im.load();remaining={(x,y) for y in range(im.height) for x in range(im.width) if pixels[x,y][3]};parts=[]
 while remaining:
  start=remaining.pop();pending=[start];part=[start]
  while pending:
   x,y=pending.pop()
   for dx,dy in [(-1,-1),(0,-1),(1,-1),(-1,0),(1,0),(-1,1),(0,1),(1,1)]:
    q=(x+dx,y+dy)
    if q in remaining:remaining.remove(q);pending.append(q);part.append(q)
  parts.append(part)
 largest=max(len(part) for part in parts)
 for part in parts:
  xs=[q[0] for q in part];ys=[q[1] for q in part];cx=(min(xs)+max(xs))/2/im.width;cy=(min(ys)+max(ys))/2/im.height
  keep=len(part)==largest if kind=='frames' else len(part)>=max(5,largest*.002) and .06<cx<.94 and .06<cy<.94
  if not keep:
   for x,y in part:pixels[x,y]=(0,0,0,0)
 bounds=im.getbbox()
 if not bounds:raise ValueError(f'Empty atlas cell{index}')
 return im.crop(bounds),list(box),list(bounds)
def save(im,name,size,atlas_box,bounds,margin=0,padding=0):
 if padding:
  scale=min((size[0]-padding*2)/im.width,(size[1]-padding*2)/im.height);small=im.resize((max(1,round(im.width*scale)),max(1,round(im.height*scale))),Image.Resampling.NEAREST);result=Image.new('RGBA',size);result.alpha_composite(small,((size[0]-small.width)//2,(size[1]-small.height)//2))
 else:result=im.resize(size,Image.Resampling.NEAREST)
 result.save(a.out/(name+'.png'));records.append({'name':name,'size':list(size),'atlasRegion':atlas_box,'alphaBoundsWithinCell':bounds,'ninePatchMargins':[margin]*4 if margin else None,'sha256':hashlib.sha256((a.out/(name+'.png')).read_bytes()).hexdigest()})
 return result
for atlas_name,kind in [('icons-original.png','icons'),('frames-original.png','frames')]:
 atlas=Image.open(source/atlas_name).convert('RGBA')
 for index in range(16):
  cell,box,bounds=cut(atlas,index,kind)
  if kind=='icons':
   save(cell,'icon-'+ICONS[index],(48,48),box,bounds,padding=3)
   save(cell,'icon-'+ICONS[index]+'-32',(32,32),box,bounds,padding=2)
  else:
   name,size,margin=FRAMES[index];save(cell,name,size,box,bounds,margin)
for alias,original in {'panel-paper':'panel-parchment','slot':'inventory-slot','icon-bag':'icon-satchel','icon-oxygen':'icon-oxygen-tank'}.items():
 (a.out/(alias+'.png')).write_bytes((a.out/(original+'.png')).read_bytes())
meta={'grid':[4,4],'filter':'nearest','alphaThreshold':128,'artwork':'Original built-in image generation from verbal Jalasmara nautical/Nusantara art direction; no third-party pack image inputs.','assets':records,'aliases':{'panel-paper':'panel-parchment','slot':'inventory-slot','icon-bag':'icon-satchel','icon-oxygen':'icon-oxygen-tank'}}
(a.out/'atlas.json').write_text(json.dumps(meta,indent=2)+'\n')
preview=Image.new('RGB',(768,440),'#263d43');draw=ImageDraw.Draw(preview)
for i,name in enumerate(ICONS):
 x=(i%4)*192;y=(i//4)*110
 for offset,size in [(12,32),(66,48)]:preview.paste(Image.open(a.out/f'icon-{name}{"-32" if size==32 else ""}.png'),(x+offset,y+12),Image.open(a.out/f'icon-{name}{"-32" if size==32 else ""}.png'))
 draw.text((x+8,y+72),name,fill='#ead7b3')
preview.save(source/'icons-actual-size-preview.png')
print(f'Prepared{len(records)} primary PNGs and4 aliases; see atlas.json; review32/48px preview before use')
