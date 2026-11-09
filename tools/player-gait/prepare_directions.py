"""Normalize the inspected original Nala eight-direction source without inventing viewpoints."""
import hashlib,json
from pathlib import Path
from PIL import Image
ROOT=Path(__file__).resolve().parents[2];ART=ROOT/'client-godot/resources/art'
source=ROOT/'assets/source-2d/nala-daily-eightway/directions-idle.png'
im=Image.open(source).convert('RGBA');atlas=Image.new('RGBA',(1024,128));info=[]
for direction,name in enumerate(['east','south_east','south','south_west','west','north_west','north','north_east']):
 box=(round(direction%4*im.width/4),round(direction//4*im.height/2),round((direction%4+1)*im.width/4),round((direction//4+1)*im.height/2))
 cell=im.crop(box);cell.putalpha(cell.getchannel('A').point(lambda a:255 if a>=128 else 0));bbox=cell.getbbox();cut=cell.crop(bbox)
 width=round(cut.width*86/cut.height);cut=cut.resize((width,86),Image.Resampling.NEAREST)
 canvas=Image.new('RGBA',(128,128));canvas.alpha_composite(cut,(64-width//2,18));atlas.alpha_composite(canvas,(direction*128,0));info.append({'id':name,'sourceCell':box,'opaqueBox':bbox,'footPivot':[64,104]})
out=ART/'player-gait';out.mkdir(exist_ok=True)
atlas.save(out/'male-default-daily-idle-8way-v1.png')
(ROOT/'assets/source-2d/nala-daily-eightway/idle-normalization.json').write_text(json.dumps({'identity':'male_default','outfit':'daily','source':source.name,'sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'cell':[128,128],'scale':1,'directions':info,'method':'original built-in imagegen views; nearest normalization; threshold128 alpha'},indent=2)+'\n')
print('EIGHT VIEW SOURCE PREPARED: distinct inspected front, rear, profiles and diagonals')
