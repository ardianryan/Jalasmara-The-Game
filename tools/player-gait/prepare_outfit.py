"""Review/normalize an 8x8 original outfit candidate; default output is caller-selected staging."""
import argparse,hashlib,json,statistics
from pathlib import Path
from PIL import Image
DIRECTIONS=['east','south_east','south','south_west','west','north_west','north','north_east']
p=argparse.ArgumentParser();p.add_argument('source',type=Path);p.add_argument('--identity',required=True);p.add_argument('--outfit',required=True,choices=['daily','explorer','diving']);p.add_argument('--out',type=Path,required=True);a=p.parse_args();a.out.mkdir(parents=True,exist_ok=True)
im=Image.open(a.source).convert('RGBA');atlas=Image.new('RGBA',(1024,1024));rows=[];hashes=[];border=[];connections=[]
for row,direction in enumerate(DIRECTIONS):
 cells=[];boxes=[]
 for col in range(8):
  cell=im.crop((round(col*im.width/8),round(row*im.height/8),round((col+1)*im.width/8),round((row+1)*im.height/8)))
  cell.putalpha(cell.getchannel('A').point(lambda alpha:255 if alpha>=128 else 0));box=cell.getbbox()
  if not box:raise ValueError(f'EMPTY row{row} col{col}')
  if box[0]==0 or box[1]==0 or box[2]==cell.width or box[3]==cell.height:border.append([row,col])
  cells.append(cell);boxes.append(box)
 scale=86/statistics.median([box[3]-box[1] for box in boxes]);baseline=statistics.median(box[3] for box in boxes)
 for col,cell in enumerate(cells):
  box=boxes[col];centers=[]
  for y in range(box[1]+max(1,round((box[3]-box[1])*.02)),box[1]+max(2,round((box[3]-box[1])*.07))):
   xs=[x for x in range(cell.width) if cell.getpixel((x,y))[3]]
   if xs:centers.append((min(xs)+max(xs))/2)
  center=statistics.median(centers)
  small=cell.resize((round(cell.width*scale),round(cell.height*scale)),Image.Resampling.NEAREST);canvas=Image.new('RGBA',(128,128));canvas.alpha_composite(small,(round(64-center*scale),round(104-baseline*scale)))
  atlas.alpha_composite(canvas,(col*128,row*128));hashes.append(hashlib.sha256(canvas.tobytes()).hexdigest())
  pixels={(x,y) for y in range(128) for x in range(128) if canvas.getpixel((x,y))[3]};remaining=set(pixels);largest=0
  while remaining:
   pending=[remaining.pop()];n=0
   while pending:
    x,y=pending.pop();n+=1
    for dx,dy in [(-1,-1),(0,-1),(1,-1),(-1,0),(1,0),(-1,1),(0,1),(1,1)]:
     q=(x+dx,y+dy)
     if q in remaining:remaining.remove(q);pending.append(q)
   largest=max(largest,n)
  connections.append(round(largest/max(1,len(pixels)),4))
 rows.append({'direction':direction,'scale':scale,'baseline':baseline,'sourceBoxes':boxes})
name=a.identity.replace('_','-')+'-'+a.outfit+'-walk-8way-candidate';atlas.save(a.out/(name+'.png'))
meta={'identity':a.identity,'outfit':a.outfit,'source':str(a.source),'sourceSha256':hashlib.sha256(a.source.read_bytes()).hexdigest(),'directions':DIRECTIONS,'frames':8,'cell':[128,128],'pivot':[64,104],'stride':64,'uniqueFrames':len(set(hashes)),'sourceBorderTouches':border,'minimumBodyConnectivity':min(connections),'rows':rows,'status':'REQUIRES VISUAL DIRECTION/OUTFIT/ANATOMY REVIEW','equipmentBaked':None}
(a.out/(name+'.json')).write_text(json.dumps(meta,indent=2)+'\n');print(json.dumps({k:meta[k] for k in ['identity','outfit','uniqueFrames','sourceBorderTouches','minimumBodyConnectivity','status']}))
