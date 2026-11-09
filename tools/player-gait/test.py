"""Semantic asset checks independent of Godot/import state."""
import hashlib,json
from pathlib import Path
from PIL import Image
ROOT=Path(__file__).resolve().parents[2]
ART=ROOT/'client-godot/resources/art'
for identity in ['male-default','male-nusantara','female-default','female-nusantara']:
 data=json.loads((ART/'player-gait'/f'{identity}.json').read_text())
 assert data['sha256']==hashlib.sha256((ART/data['source']).read_bytes()).hexdigest()
 assert data['directions']==['east','west'] and len(data['fallbackDirections'])==6
 image=Image.open(ART/'player-gait'/f'{identity}.png')
 assert image.size==(800,300) and image.mode=='RGBA'
 for outfit in range(3):
  clips=[f for f in data['clips'] if f['outfit']==outfit]
  assert len(clips)==8
  for side in [0,1]:
   planted=[]
   for frame in clips:
    foot=next(f for f in frame['feet'] if f['side']==side)
    if foot['support']:
     assert foot['sole']==98
     planted.append(foot['x']+frame['frame']/8*data['stride'])
   assert max(planted)-min(planted)<.001,'Stance foot slides in world coordinates'
  crops=[image.crop((f*100,outfit*100,(f+1)*100,(outfit+1)*100)).tobytes() for f in range(8)]
  assert len(set(crops))==8,'Every gait phase must change body pixels'
  for f in range(8):assert abs(image.crop((f*100,outfit*100,(f+1)*100,(outfit+1)*100)).getbbox()[3]-98)<=1,'Actual alpha sole must stay on ground'
print('PLAYER SIDE GAIT PASS:12 outfits,96 unique body poses, fixed support soles, no world-space stance sliding, source hashes, honest two-direction artwork')
