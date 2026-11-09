"""Rebuild eleven reviewed outfit sets from tracked original authoring sources.
The separately assembled male-default daily pilot is kept byte-for-byte unchanged.
"""
import argparse,hashlib,json,subprocess,tempfile
from pathlib import Path
from PIL import Image
ROOT=Path(__file__).resolve().parents[2]
p=argparse.ArgumentParser();p.add_argument('--out',type=Path,default=ROOT/'client-godot/resources/art/player-gait');a=p.parse_args();a.out.mkdir(parents=True,exist_ok=True)
source=ROOT/'assets/source-2d/nala-eightway-batch';manifest=json.loads((source/'manifest.json').read_text())
with tempfile.TemporaryDirectory(prefix='jalasmara-gait-') as temp:
 staging=Path(temp)
 for identity in ['male-default','male-nusantara','female-default','female-nusantara']:
  subprocess.run(['python3',str(ROOT/'tools/player-gait/prepare_idle_outfits.py'),str(source/(identity+'-idle24.png')),'--identity',identity.replace('-','_'),'--out',str(staging)],check=True)
 for meta in manifest['sets']:
  identity=meta['identity'].replace('_','-');name=identity+'-'+meta['outfit']
  subprocess.run(['python3',str(ROOT/'tools/player-gait/prepare_outfit.py'),str(source/(name+'-source.png')),'--identity',meta['identity'],'--outfit',meta['outfit'],'--out',str(staging)],check=True)
  atlas=Image.open(staging/(name+'-walk-8way-candidate.png')).convert('RGBA')
  repair=source/(name+'-north-repair.png')
  if repair.exists():
   target=staging/name
   subprocess.run(['python3',str(ROOT/'tools/player-gait/prepare_clip.py'),str(repair),'--out',str(target)],check=True)
   atlas.paste(Image.open(target/'atlas.png'),(0,768))
  atlas.save(a.out/(name+'-walk-8way-v1.png'))
  Image.open(staging/(name+'-idle-8way-candidate.png')).save(a.out/(name+'-idle-8way-v1.png'))
 print('Rebuilt11 eight-way outfit sets; separately reviewed daily pilot preserved')
