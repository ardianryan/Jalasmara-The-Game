"""Check HUD alpha holes, button states, aliases, source hashes and deterministic rebuild."""
import hashlib,json,subprocess,tempfile
from pathlib import Path
from PIL import Image
ROOT=Path(__file__).resolve().parents[2];ART=ROOT/'client-godot/resources/art/hud-bahari-v1';SOURCE=ROOT/'assets/source-2d/hud-bahari-v1'
meta=json.loads((ART/'atlas.json').read_text());assert len(meta['assets'])==48
for record in meta['assets']:
 path=ART/(record['name']+'.png');assert hashlib.sha256(path.read_bytes()).hexdigest()==record['sha256']
 image=Image.open(path).convert('RGBA');assert list(image.size)==record['size']
 assert image.getbbox() and set(image.getchannel('A').getdata())=={0,255},record['name']
 if record['name'].startswith('icon-'):
  assert image.getpixel((0,0))[3]==0
  assert len(set(image.getdata()))>16,'Full-color shaded glyph, not one-color outline'
for name in ['portrait-frame','minimap-rim','joystick-ring','bar-frame']:
 image=Image.open(ART/(name+'.png')).convert('RGBA');assert image.getpixel((image.width//2,image.height//2))[3]==0,(name,'Center must stay truly transparent')
for name in ['panel-dark','panel-parchment','inventory-slot','button-normal']:
 image=Image.open(ART/(name+'.png')).convert('RGBA');assert image.getpixel((image.width//2,image.height//2))[3]==255
assert len({hashlib.sha256((ART/('button-'+state+'.png')).read_bytes()).hexdigest() for state in ['normal','hover','pressed','selected']})==4
for alias,original in meta['aliases'].items():assert (ART/(alias+'.png')).read_bytes()==(ART/(original+'.png')).read_bytes()
manifest=json.loads((SOURCE/'source.json').read_text())
for record in manifest['sources']:assert hashlib.sha256((SOURCE/record['path']).read_bytes()).hexdigest()==record['sha256']
with tempfile.TemporaryDirectory(prefix='jalasmara-hud-') as temp:
 subprocess.run(['python3',str(ROOT/'tools/hud-bahari/prepare.py'),'--out',temp],check=True)
 for record in meta['assets']:assert hashlib.sha256((Path(temp)/(record['name']+'.png')).read_bytes()).hexdigest()==record['sha256']
print('HUD BAHARI PASS:48 raster sprites, real alpha holes, fullcolor32/48px glyphs,4 unique states,4 aliases, source hashes, deterministic clean-source rebuild')
