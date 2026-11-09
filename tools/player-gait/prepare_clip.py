"""Stage a reviewed 4x2 directional walk sheet; never overwrites production art."""
import argparse,json,statistics
from pathlib import Path
from PIL import Image,ImageDraw
p=argparse.ArgumentParser();p.add_argument('source',type=Path);p.add_argument('--out',type=Path,required=True);a=p.parse_args();a.out.mkdir(parents=True,exist_ok=True)
im=Image.open(a.source).convert('RGBA');cells=[];boxes=[]
for frame in range(8):
 cell=im.crop((round(frame%4*im.width/4),round(frame//4*im.height/2),round((frame%4+1)*im.width/4),round((frame//4+1)*im.height/2)))
 cell.putalpha(cell.getchannel('A').point(lambda alpha:255 if alpha>=128 else 0));cells.append(cell);boxes.append(cell.getbbox())
scale=86/statistics.median([b[3]-b[1] for b in boxes]);baseline=statistics.median(b[3] for b in boxes)
atlas=Image.new('RGBA',(1024,128));frames=[]
for index,cell in enumerate(cells):
 bbox=boxes[index];centers=[]
 for y in range(bbox[1]+8,bbox[1]+28):
  xs=[x for x in range(cell.width) if cell.getpixel((x,y))[3]]
  if xs:centers.append((min(xs)+max(xs))/2)
 center=statistics.median(centers)
 canvas=Image.new('RGBA',(128,128));small=cell.resize((round(cell.width*scale),round(cell.height*scale)),Image.Resampling.NEAREST);canvas.alpha_composite(small,(round(64-center*scale),round(104-baseline*scale)));atlas.alpha_composite(canvas,(index*128,0));canvas.save(a.out/f'{index}.png')
 bg=Image.new('RGBA',(128,128),'#283b40');bg.alpha_composite(canvas);frames.append(bg.resize((384,384),Image.Resampling.NEAREST).convert('RGB'))
atlas.save(a.out/'atlas.png');frames[0].save(a.out/'preview.gif',save_all=True,append_images=frames[1:],duration=125,loop=0)
(a.out/'metadata.json').write_text(json.dumps({'source':str(a.source),'cell':[128,128],'footPivot':[64,104],'sourceBaseline':baseline,'scale':scale,'phaseNames':['contact','down','passing','up']*2,'reviewRequired':True},indent=2)+'\n')
print('Staged8-frame clip; no runtime change')
