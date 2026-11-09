"""Check original directional art and assembled pilot without claiming automated anatomy review."""
import hashlib,json
from pathlib import Path
from PIL import Image
ROOT=Path(__file__).resolve().parents[2];ART=ROOT/'client-godot/resources/art/player-gait';SOURCE=ROOT/'assets/source-2d/nala-daily-eightway'
meta=json.loads((ART/'male-default-daily-8way-v1.json').read_text());source=json.loads((SOURCE/'source.json').read_text());im=Image.open(ART/'male-default-daily-walk-8way-v1.png');idle=Image.open(ART/'male-default-daily-idle-8way-v1.png')
assert meta['drawnDirections']==8 and meta['mirroredDirections']==0 and meta['pivot']==[64,104]
assert im.size==(1024,1024) and idle.size==(1024,128)
all_hashes=set();ranges=[]
for row,item in enumerate(source['directions']):
 assert hashlib.sha256((SOURCE/item['source']).read_bytes()).hexdigest()==item['sha256']
 bottoms=[]
 for f in range(8):
  cell=im.crop((f*128,row*128,(f+1)*128,(row+1)*128));bbox=cell.getbbox();assert bbox and bbox[0]>0 and bbox[2]<128 and bbox[1]>0 and bbox[3]<128
  assert 80<=bbox[3]-bbox[1]<=92
  pixels={(x,y) for y in range(128) for x in range(128) if cell.getpixel((x,y))[3]}
  remaining=set(pixels);largest=0
  while remaining:
   pending=[remaining.pop()];count=0
   while pending:
    x,y=pending.pop();count+=1
    for dx,dy in [(-1,-1),(0,-1),(1,-1),(-1,0),(1,0),(-1,1),(0,1),(1,1)]:
     q=(x+dx,y+dy)
     if q in remaining:remaining.remove(q);pending.append(q)
   largest=max(largest,count)
  assert largest/len(pixels)>.96,'Body/legs cannot fragment into disconnected cutouts'
  all_hashes.add(hashlib.sha256(cell.tobytes()).hexdigest());bottoms.append(bbox[3])
 ranges.append(max(bottoms)-min(bottoms))
assert len(all_hashes)==64
print('EIGHT-WAY ART PASS:8 reviewed drawn viewpoints,64 unique connected silhouettes, no clipping, source hashes, foot-bottom variation',ranges)
manifest=json.loads((ROOT/'assets/source-2d/nala-eightway-batch/manifest.json').read_text())
assert len(manifest['sets'])==11
for item in manifest['sets']:
 for record in item['sources']+item['outputs']:
  assert hashlib.sha256((ROOT/record['path']).read_bytes()).hexdigest()==record['sha256'],record['path']
 name=item['identity'].replace('_','-')+'-'+item['outfit']
 assert item['drawnDirections']==8 and item['mirroredDirections']==0 and item['equipmentBaked'] is False
 assert item['directions']==meta['directions'] and item['pivot']==[64,104]
 sheet=Image.open(ART/(name+'-walk-8way-v1.png')).convert('RGBA');neutral=Image.open(ART/(name+'-idle-8way-v1.png')).convert('RGBA')
 assert sheet.size==(1024,1024) and neutral.size==(1024,128)
 unique=set()
 for row in range(8):
  for frame in range(8):
   cell=sheet.crop((frame*128,row*128,(frame+1)*128,(row+1)*128));box=cell.getbbox()
   assert box and box[0]>0 and box[1]>0 and box[2]<128 and box[3]<128,(name,row,frame,box)
   unique.add(hashlib.sha256(cell.tobytes()).hexdigest())
   pixels={(x,y) for y in range(128) for x in range(128) if cell.getpixel((x,y))[3]};remaining=set(pixels);largest=0
   while remaining:
    pending=[remaining.pop()];count=0
    while pending:
     x,y=pending.pop();count+=1
     for dx,dy in [(-1,-1),(0,-1),(1,-1),(-1,0),(1,0),(-1,1),(0,1),(1,1)]:
      q=(x+dx,y+dy)
      if q in remaining:remaining.remove(q);pending.append(q)
    largest=max(largest,count)
   assert largest/len(pixels)>.96,(name,row,frame,'fragmented body')
 assert len(unique)==64,(name,len(unique))
 for direction in range(8):assert neutral.crop((direction*128,0,(direction+1)*128,128)).getbbox()
print('FULL BATCH PASS:12 identity/outfit sets,768 unique-per-set connected walk frames,96 neutral views,tracked source/output SHA256, no mirrored directional substitution. Anatomy/direction quality also manually reviewed; hashes alone do not establish it.')
