"""Rebuild the approved Jala Muara SVG identity from the supplied font and mark."""
from pathlib import Path
from fontTools.ttLib import TTFont
from fontTools.pens.svgPathPen import SVGPathPen
import re, base64, json
out=Path('assets/brand');out.mkdir(parents=True,exist_ok=True)
source=Path('assets/brand/concepts-v2/jala-muara.svg').read_text()
mark=source.replace('Jala Muara','Jalasmara · Jala Muara')
(out/'symbol.svg').write_text(mark)
(out/'symbol-white.svg').write_text(mark.replace('#173f43','#f5ebd4'))
(out/'symbol-black.svg').write_text(mark.replace('#173f43','#111111'))
(out/'symbol-small.svg').write_text('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256"><title>Jalasmara</title><g fill="none" stroke="#173f43" stroke-width="22" stroke-linecap="round" stroke-linejoin="round"><path d="M43 74c25-32 63-40 84-26 23 14 51 14 85-8-9 48-24 91-50 126-27 38-72 55-94 28-21-26-3-57 24-59 22-2 29 18 17 31"/><path d="M47 77c41 26 89 35 145 9M88 63c-2 32 8 59 34 85"/></g></svg>')
font=TTFont('node_modules/@fontsource/lora/files/lora-latin-500-normal.woff')
glyphs=font.getGlyphSet();cmap=font.getBestCmap();units=font['head'].unitsPerEm

def word_paths(text,size=110):
    scale=size/units;x=0;parts=[]
    for char in text:
        name=cmap.get(ord(char),'space');pen=SVGPathPen(glyphs);glyphs[name].draw(pen)
        parts.append(f'<path d="{pen.getCommands()}" transform="translate({x:.3f},0) scale({scale:.6f},-{scale:.6f})"/>')
        x+=font['hmtx'][name][0]*scale
    return ''.join(parts),x
paths,width=word_paths('Jalasmara')
inner=re.search(r'<svg[^>]*>(.*)</svg>',mark,re.S).group(1)
for name,color in [('horizontal','#173f43'),('horizontal-white','#f5ebd4'),('horizontal-black','#111111')]:
    asset=f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {int(width+321)} 256"><title>Jalasmara</title><g>{inner.replace("#173f43",color)}</g><g fill="{color}" transform="translate(280,161)">{paths}</g></svg>'
    (out/f'{name}.svg').write_text(asset)
word=f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {int(width+8)} 150"><title>Jalasmara</title><g fill="#173f43" transform="translate(4,115)">{paths}</g></svg>'
(out/'wordmark.svg').write_text(word)
stack=f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {int(width+30)} 430"><title>Jalasmara</title><g transform="translate({(width-256)/2+15:.2f},0)">{inner}</g><g fill="#173f43" transform="translate(15,365)">{paths}</g></svg>'
(out/'stacked.svg').write_text(stack)
art=base64.b64encode(Path('apps/web/public/art/muara-sungsang.png').read_bytes()).decode()
logo=(out/'horizontal-white.svg').read_text(); logo_inner=re.search(r'<svg[^>]*>(.*)</svg>',logo,re.S).group(1)
banner=f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1280 640"><defs><clipPath id="art"><rect x="640" y="0" width="640" height="640"/></clipPath></defs><rect width="1280" height="640" fill="#082e35"/><image href="data:image/png;base64,{art}" x="470" y="-90" width="1150" height="768" clip-path="url(#art)"/><g transform="translate(28,75) scale(.67)">{logo_inner}</g><text x="62" y="330" fill="#edd3a3" font-family="Georgia,serif" font-size="45">Menjaring Ingatan</text><text x="64" y="388" fill="#f5ebd4" font-family="sans-serif" font-size="22">Petualangan di Bandar Hujung</text><text x="64" y="423" fill="#b8cfc1" font-family="sans-serif" font-size="18">Jelajahi laut. Temukan ilmu. Pulihkan palung.</text><text x="64" y="570" fill="#b8cfc1" font-family="sans-serif" font-size="15">Dunia fiksi Nusantara · Godot 2D · Web</text></svg>'''
(out/'repository-cover.svg').write_text(banner)
tokens={'name':'Jala Muara','colors':{'palung':'#082e35','ink':'#173f43','sea':'#0b555b','lamun':'#8db9a2','sand':'#edd3a3','paper':'#f4f6f2','warning':'#963c30'},'typography':{'display':'Lora Medium','interface':'Nunito Sans','game':'Godot fallback font'},'logo':{'clearSpace':'1/6 tinggi simbol','minimumSymbolPixels':24,'minimumSmallSymbolPixels':16}}
(out/'tokens.json').write_text(json.dumps(tokens,indent=2))
print('SVG logo, lockups, repository cover, and tokens generated.')
