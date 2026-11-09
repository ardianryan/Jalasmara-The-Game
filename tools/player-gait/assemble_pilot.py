"""Assemble reviewed eight-direction artwork without mirroring or warping body parts."""
import argparse,json,subprocess,sys,hashlib
from pathlib import Path
from PIL import Image
ROOT=Path(__file__).resolve().parents[2]
p=argparse.ArgumentParser();p.add_argument('--out',type=Path,required=True);a=p.parse_args();a.out.mkdir(parents=True,exist_ok=True)
source=ROOT/'assets/source-2d/nala-daily-eightway';manifest=json.loads((source/'source.json').read_text());atlas=Image.new('RGBA',(1024,1024));clips=[]
for row,item in enumerate(manifest['directions']):
 folder=a.out/('preview-'+item['id'])
 subprocess.run([sys.executable,str(Path(__file__).with_name('prepare_clip.py')),str(source/item['source']),'--out',str(folder)],check=True,stdout=subprocess.DEVNULL)
 strip=Image.open(folder/'atlas.png');atlas.alpha_composite(strip,(0,row*128));details=json.loads((folder/'metadata.json').read_text());clips.append({'id':item['id'],'row':row,'sourceSha256':item['sha256'],'scale':details['scale'],'sourceBaseline':details['sourceBaseline']})
atlas.save(a.out/'male-default-daily-walk-8way-v1.png')
idle=ROOT/'client-godot/resources/art/player-gait/male-default-daily-idle-8way-v1.png';Image.open(idle).save(a.out/'male-default-daily-idle-8way-v1.png')
meta={'identity':'male_default','outfit':'daily','directions':[d['id'] for d in manifest['directions']],'frames':8,'cell':[128,128],'pivot':[64,104],'stride':64,'contacts':[0,4],'posePhases':['contact','down','passing','up']*2,'drawnDirections':8,'mirroredDirections':0,'clips':clips,'method':'Original generated frames, threshold128 alpha, nearest normalization with shared per-clip baseline/headline, no cutout deformation'}
(a.out/'male-default-daily-8way-v1.json').write_text(json.dumps(meta,indent=2)+'\n')
print('ORIGINAL EIGHT-WAY PILOT ASSEMBLED:8 drawn viewpoints ×8 frames; one identity/daily outfit')
