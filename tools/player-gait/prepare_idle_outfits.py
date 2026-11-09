"""Normalize reviewed neutral eight-view/three-outfit artwork into staged per-outfit atlases."""
import argparse,json,hashlib
from pathlib import Path
from PIL import Image
p=argparse.ArgumentParser();p.add_argument('source',type=Path);p.add_argument('--identity',required=True);p.add_argument('--out',type=Path,required=True);a=p.parse_args();a.out.mkdir(parents=True,exist_ok=True)
im=Image.open(a.source).convert('RGBA');info=[]
for row,outfit in enumerate(['daily','explorer','diving']):
 atlas=Image.new('RGBA',(1024,128));frames=[]
 for col,direction in enumerate(['east','south_east','south','south_west','west','north_west','north','north_east']):
  cell=im.crop((round(col*im.width/8),round(row*im.height/3),round((col+1)*im.width/8),round((row+1)*im.height/3)));cell.putalpha(cell.getchannel('A').point(lambda alpha:255 if alpha>=128 else 0));box=cell.getbbox()
  if not box:raise ValueError('Missing neutral stance cell')
  cut=cell.crop(box);cut=cut.resize((round(cut.width*86/cut.height),86),Image.Resampling.NEAREST);canvas=Image.new('RGBA',(128,128));canvas.alpha_composite(cut,(64-cut.width//2,18));atlas.alpha_composite(canvas,(col*128,0));frames.append({'direction':direction,'sourceBox':box,'pivot':[64,104]})
 name=a.identity.replace('_','-')+'-'+outfit+'-idle-8way-candidate';atlas.save(a.out/(name+'.png'));info.append({'outfit':outfit,'frames':frames})
(a.out/(a.identity.replace('_','-')+'-idle-review.json')).write_text(json.dumps({'identity':a.identity,'source':str(a.source),'sha256':hashlib.sha256(a.source.read_bytes()).hexdigest(),'outfits':info,'status':'requires grounded-stance and identity review'},indent=2)+'\n')
print(a.identity,'24 neutral view cells normalized; not active runtime')
