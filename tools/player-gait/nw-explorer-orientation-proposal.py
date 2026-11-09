#!/usr/bin/env python3
"""Review a separately authored rear-left explorer upper arrangement without atlas writes."""
import argparse
import hashlib
import importlib.util
import json
from pathlib import Path

from PIL import Image, ImageDraw

ROOT=Path(__file__).resolve().parents[2]
SPEC=Path(__file__).with_suffix('.json')
loader=importlib.util.spec_from_file_location('nw_audit',Path(__file__).with_name('nw-upper-source-audit.py'))
audit=importlib.util.module_from_spec(loader)
loader.loader.exec_module(audit)
require=audit.require


def digest(data):return hashlib.sha256(data).hexdigest()


def compose(spec):
    require(spec.get('schemaVersion')==1 and spec.get('identity')=='male_nusantara'
            and spec.get('targetOutfit')=='explorer' and spec.get('targetView')=='north_west'
            and spec.get('candidateFrameCoverage')==[0] and spec.get('unresolvedFrames')==list(range(1,8))
            and spec.get('splitY')==43 and spec.get('transform')=={'scale':1,'mirror':False,'offset':[0,0]},
            'Only the explicitly authored identity-transform NW0 arrangement is proposed')
    require(spec.get('sourceAnatomicalSides')=='unknown' and spec.get('wrist') is None
            and spec.get('grip') is None and spec.get('contactPhase') is None
            and spec.get('newGearPixels')==0 and spec.get('newRuntimeNodes')==0
            and 'AUTHORED' in spec.get('status',''),'Do not promote arrangement into anatomy/contact/gear acceptance')
    source_spec=json.loads(audit.SPEC.read_text())
    images=audit.sources(source_spec)
    daily=audit.cell(images,'daily',0)
    explorer_idle=images['explorer']['idle'].crop((640,0,768,76))
    defective=audit.cell(images,'explorer',0)
    result=Image.new('RGBA',(128,76))
    result.paste(daily.crop((0,0,128,43)),(0,0))
    result.paste(explorer_idle.crop((0,43,128,76)),(0,43))
    contacts=[[[x,42],[q,43]] for x in range(128) for q in range(max(0,x-1),min(128,x+2))
              if result.getpixel((x,42))[3] and result.getpixel((q,43))[3]]
    require(bool(contacts),'No opaque connection at the authored reference boundary')
    return result,daily,explorer_idle,defective,contacts,source_spec


def export(spec,output):
    output=output.resolve()
    require(output.is_relative_to(ROOT/'artifacts') and not output.exists(),'Fresh ignored authoring output required')
    result,daily,explorer_idle,defective,contacts,source_spec=compose(spec)
    output.mkdir(parents=True)
    result.save(output/'authored-explorer-NW0-upper.png')
    sheet=Image.new('RGB',(4*440,500),(20,38,43));draw=ImageDraw.Draw(sheet)
    for i,(image,label) in enumerate([(defective,'DEFECT: original explorer WALK NW0'),(daily,'REFERENCE: original daily WALK NW0'),(explorer_idle,'REFERENCE: original explorer IDLE NW'),(result,'AUTHORED head/body arrangement ONLY')]):
        crop=image.crop((40,12,92,76)).resize((416,448),Image.Resampling.NEAREST)
        sheet.paste(crop,(i*440+8,40),crop)
        draw.text((i*440+8,8),label,fill='white')
        draw.line((i*440+8,257,i*440+424,257),fill=(235,65,181),width=1)
    sheet.save(output/'nw-explorer-authored-orientation-comparison.png')
    neck=Image.new('RGB',(2*480,280),(20,38,43));draw=ImageDraw.Draw(neck)
    provenance=Image.new('RGBA',result.size)
    provenance.paste((246,196,74,255),(0,0,128,43),result.crop((0,0,128,43)).getchannel('A'))
    provenance.paste((66,218,213,255),(0,43,128,76),result.crop((0,43,128,76)).getchannel('A'))
    for i,(im,label) in enumerate([(result,'AUTHORED neck seam / exact source RGBA'),(provenance,'Gold daily head / cyan explorer IDLE body')]):
        crop=im.crop((49,34,81,50)).resize((448,224),Image.Resampling.NEAREST)
        neck.paste(crop,(i*480+16,40),crop);draw.text((i*480+16,8),label,fill='white')
    neck.save(output/'nw-explorer-authored-neck-and-provenance.png')
    manifest={'status':spec['status'],'sources':source_spec['sources'],'specSha256':digest(SPEC.read_bytes()),
              'toolSha256':digest(Path(__file__).read_bytes()),'resultRgbaSha256':digest(result.tobytes()),
              'headReferenceRgbaSha256':digest(daily.crop((0,0,128,43)).tobytes()),
              'bodyReferenceRgbaSha256':digest(explorer_idle.crop((0,43,128,76)).tobytes()),
              'headOriginalRuns':audit.ownership.row_runs(result.crop((0,0,128,43))),
              'bodyOriginalRunsLocal':audit.ownership.row_runs(result.crop((0,43,128,76))),
              'boundaryContacts':contacts,'scope':spec['authoredScope'],'candidateFrameCoverage':[0],
              'unresolvedFrames':list(range(1,8)),'anatomicalSide':'unknown','wrist':None,'grip':None,'contactPhase':None}
    (output/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
    print('AUTHORED NW0 ARRANGEMENT EXPORTED; source pieces exact, anatomy/loop/runtime unaccepted')


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--output',type=Path,required=True)
    args=parser.parse_args();export(json.loads(SPEC.read_text()),args.output)
