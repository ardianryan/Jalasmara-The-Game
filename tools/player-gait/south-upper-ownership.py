#!/usr/bin/env python3
"""Review SOUTH original pixel ownership and an explicitly authored hidden-cloth plate."""
import argparse
import hashlib
import importlib.util
import json
import math
from pathlib import Path
from PIL import Image, ImageDraw

ROOT=Path(__file__).resolve().parents[2]
SPEC=Path(__file__).with_suffix('.json')
anchor_spec=importlib.util.spec_from_file_location('south_palms',Path(__file__).with_name('south-upper-anchors.py'))
anchors=importlib.util.module_from_spec(anchor_spec)
anchor_spec.loader.exec_module(anchors)
COLORS={'plate':(94,111,115,255),'left/upper':(244,174,65,255),'left/fore':(248,214,94,255),'left/palm':(255,244,174,255),'right/upper':(27,153,164,255),'right/fore':(44,219,215,255),'right/palm':(166,255,245,255),'authored':(235,65,181,255)}

def digest(data): return hashlib.sha256(data).hexdigest()

def polygon(points):
	anchors.require(len(points)>=3 and all(isinstance(p,list) and len(p)==2 and all(type(v) is int for v in p) and 0<=p[0]<128 and 43<=p[1]<76 for p in points),'Ownership polygon outside original upper-body scope')
	mask=Image.new('L',(128,76))
	ImageDraw.Draw(mask).polygon([tuple(p) for p in points],fill=255)
	return mask

def source_cell(outfit,frame):
	anchors.require(type(frame) is int and frame in (0,4),'Only source frames0/4 are reviewed')
	image=anchors.source_image(outfit)
	return image.crop((frame*128,256,(frame+1)*128,332))

def split(case):
	source=source_cell(case['outfit'],case['frame'])
	layers={};used=set()
	for side in ('left','right'):
		for part in ('palm','fore','upper'):
			name=side+'/'+part
			mask=polygon(case['parts'][side][part]);layer=Image.new('RGBA',source.size)
			for y,x0,x1 in case.get('additionalOwnedRuns',{}).get(name,[]):
				anchors.require(43<=y<76 and 0<=x0<x1<=128,'Additional source run outside upper cell')
				ImageDraw.Draw(mask).line((x0,y,x1-1,y),fill=255)
			for y in range(43,76):
				for x in range(128):
					if mask.getpixel((x,y)) and source.getpixel((x,y))[3] and (x,y) not in used:
						layer.putpixel((x,y),source.getpixel((x,y)));used.add((x,y))
			layers[name]=layer
	plate=source.copy()
	for p in used: plate.putpixel(p,(0,0,0,0))
	rebuilt=plate.copy()
	for layer in layers.values(): rebuilt.alpha_composite(layer)
	if rebuilt.tobytes()!=source.tobytes(): raise ValueError('Original rest reconstruction differs')
	return source,plate,layers,rebuilt

def row_runs(layer):
	result=[]
	for y in range(layer.height):
		start=None
		for x in range(layer.width+1):
			occupied=x<layer.width and layer.getpixel((x,y))[3]>0
			if occupied and start is None: start=x
			if not occupied and start is not None: result.append([y,start,x]);start=None
	return result

def ownership(source,layers):
	result=Image.new('RGBA',source.size)
	for y in range(source.height):
		for x in range(source.width):
			if source.getpixel((x,y))[3]: result.putpixel((x,y),COLORS['plate'])
	for name,layer in layers.items():
		result.paste(COLORS[name],(0,0),layer.getchannel('A'))
	return result

def authored_plate(spec,source,plate,layers):
	proposal=spec['daily0AuthoredProposal'];envelope=Image.new('L',source.size)
	for y,x0,x1 in proposal['torsoOnlyRunsYX0X1']: ImageDraw.Draw(envelope).line((x0,y,x1-1,y),fill=255)
	x0,y0,x1,y1=proposal['verifiedClothDonorRect']
	anchors.require([x0,y0,x1,y1]==[62,48,68,58] and digest(source.crop((x0,y0,x1,y1)).tobytes())=='4b5bea858e140c0ab4b544c5ad76f0e91ac1132bfec4a23bf54d264572fbecc4','Verified visible cloth donor changed')
	repaired=plate.copy();repair=Image.new('RGBA',source.size);provenance=[]
	donors=[]
	for record in proposal['visibleClothRowDonorCandidates']:
		point=tuple(record['pixel']);rgba=source.getpixel(point)
		anchors.require(list(rgba)==record['rgba'] and rgba[3]==255,'Row cloth donor differs from original')
		if plate.getpixel(point)[3]: donors.append(point)
	for y in range(43,76):
		for x in range(128):
			if envelope.getpixel((x,y)) and any(layer.getpixel((x,y))[3] for layer in layers.values()):
				row_donors=[p for p in donors if p[1]==y]
				anchors.require(bool(row_donors),'No original owned-cloth donor on this row')
				donor=min(row_donors,key=lambda p:abs(p[0]-x));rgba=source.getpixel(donor)
				repair.putpixel((x,y),rgba);repaired.putpixel((x,y),rgba)
				provenance.append({'destination':[x,y],'donor':list(donor),'rgba':list(rgba),'status':'newly-authored-hidden-cloth'})
	rest=repaired.copy()
	for layer in layers.values(): rest.alpha_composite(layer)
	if rest.tobytes()!=source.tobytes(): raise ValueError('Hidden repair must stay occluded at original rest')
	return repaired,repair,provenance,rest

def joint_rotation(pivot,degrees):
	a=math.radians(degrees);c=math.cos(a);s=math.sin(a);x,y=pivot
	return (c,-s,x-c*x+s*y,s,c,y-s*x-c*y)

def chain_transform(a,b):
	x,y,z,u,v,w=a;p,q,r,s,t,j=b
	return (x*p+y*s,x*q+y*t,x*r+y*j+z,u*p+v*s,u*q+v*t,u*r+v*j+w)

def moved_cutout(layer,matrix):
	a,b,c,d,e,f=matrix;det=a*e-b*d
	return layer.transform(layer.size,Image.Transform.AFFINE,(e/det,-b/det,(b*f-e*c)/det,-d/det,a/det,(d*c-a*f)/det),resample=Image.Resampling.NEAREST)

def authored_extremes(spec,repaired,layers):
	proposal=spec['daily0AuthoredProposal'];results=[]
	for pose in proposal['newPoseProposal']['poses']:
		parts={};transforms={}
		for side in ('left','right'):
			joints=proposal['joints'][side];motion=pose[side]
			upper=joint_rotation(joints['shoulder'],motion['upperDeg']);fore=chain_transform(upper,joint_rotation(joints['elbow'],motion['foreRelativeDeg']))
			transforms[side]={'upper':upper,'fore':fore,'palm':fore}
			parts[side]=[moved_cutout(layers[side+'/'+part],transforms[side][part]) for part in ('upper','fore','palm')]
		result=Image.new('RGBA',repaired.size)
		for side in pose['behindTorso']:
			for layer in parts[side]:result.alpha_composite(layer)
		result.alpha_composite(repaired)
		for side in ('left','right'):
			if side not in pose['behindTorso']:
				for layer in parts[side]:result.alpha_composite(layer)
		results.append((pose['name'],result,transforms))
	return results

def repair_comparison(source,plate,repaired,repair,rest,spec):
	sheet=Image.new('RGB',(3*440,2*340),(20,38,43));draw=ImageDraw.Draw(sheet)
	provenance=source.copy();provenance.paste(COLORS['authored'],(0,0),repair.getchannel('A'))
	panels=[(source,'ORIGINAL SOUTH daily0'),(plate,'SOURCE PLATE: real ownership holes'),(repaired,'AUTHORED hidden cloth candidate'),(provenance,'MAGENTA: authored, not recovered'),(rest,'REST: byte-exact original'),(source,'AUTHORED joint design, not measured')]
	for i,(image,label) in enumerate(panels):
		x=(i%3)*440+8;y=(i//3)*340+8;draw.text((x,y),label,fill='white')
		crop=image.crop((40,42,92,76)).resize((416,272),Image.Resampling.NEAREST);sheet.paste(crop,(x,y+28),crop)
		if i==5:
			for side,joints in spec['daily0AuthoredProposal']['joints'].items():
				for name,point in joints.items():
					cx=x+(point[0]-40)*8+4;cy=y+28+(point[1]-42)*8+4;color=(246,196,74) if side=='left' else (66,218,213)
					draw.ellipse((cx-5,cy-5,cx+5,cy+5),outline=color,width=2);draw.text((cx+8,cy-5),name,fill=color)
	return sheet

def main():
	parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--output',type=Path,required=True);args=parser.parse_args()
	output=args.output.resolve()
	if not output.is_relative_to(ROOT/'artifacts') or output.exists(): raise ValueError('Fresh ignored artifacts output required')
	spec=json.loads(SPEC.read_text());output.mkdir(parents=True)
	sheet=Image.new('RGB',(4*400,4*280),(20,38,43));draw=ImageDraw.Draw(sheet);cases=[]
	for index,case in enumerate(spec['cases']):
		source,plate,layers,rebuilt=split(case);name=f"{case['outfit']}-{case['frame']}";panels=[(source,'ORIGINAL'),(rebuilt,'SOURCE RECOMPOSITION'),(ownership(source,layers),'OWNERSHIP PROPOSAL'),(plate,'REMOVED ARMS / NO HIDDEN CLOTH')]
		folder=output/name;folder.mkdir()
		plate.save(folder/'original-head-torso-remainder.png')
		parts={}
		for key,layer in layers.items():
			filename=key.replace('/','-')+'.png';layer.save(folder/filename)
			parts[key]={'file':filename,'sourceRunsYX0X1':row_runs(layer),'opaquePixels':sum(a>0 for a in layer.getchannel('A').getdata())}
		entry={'outfit':case['outfit'],'frame':case['frame'],'sourceUpperRgbaSha256':digest(source.tobytes()),'exactSourceRecomposition':source.tobytes()==rebuilt.tobytes(),'originalPlateRunsYX0X1':row_runs(plate),'parts':parts}
		if case['outfit']=='daily' and case['frame']==0:
			repaired,repair,provenance,rest=authored_plate(spec,source,plate,layers)
			repaired.save(folder/'authored-hidden-cloth-plate.png');repair.save(folder/'authored-hidden-cloth-only.png');rest.save(folder/'rest-with-authored-hidden-cloth.png')
			repair_comparison(source,plate,repaired,repair,rest,spec).save(output/'south-daily0-hidden-cloth-proposal.png')
			extremes=authored_extremes(spec,repaired,layers)
			extreme_sheet=Image.new('RGB',(2*440,340),(20,38,43));ed=ImageDraw.Draw(extreme_sheet)
			for i,(label,image,transforms) in enumerate(extremes):
				ed.text((i*440+8,8),'AUTHORED REVIEW: '+label,fill='white');crop=image.crop((40,42,92,76)).resize((416,272),Image.Resampling.NEAREST);extreme_sheet.paste(crop,(i*440+8,40),crop)
				image.save(folder/(label+'.png'))
			extreme_sheet.save(output/'south-daily0-authored-extremes.png')
			entry['authoredExtremes']=[{'name':n,'jointTransforms':t,'rgbaSha256':digest(i.tobytes())} for n,i,t in extremes]
			entry['authoredHiddenCloth']=provenance;entry['authoredJointProposal']=spec['daily0AuthoredProposal']['joints']
			preview=ownership(source,layers);preview.paste(COLORS['authored'],(0,0),repair.getchannel('A'));preview.save(folder/'authored-repair-provenance.png')
		cases.append(entry)
		for column,(image,label) in enumerate(panels):
			x=column*400+8;y=index*280+8;draw.text((x,y),f'{name} {label}',fill='white');scaled=image.resize((384,228),Image.Resampling.NEAREST);sheet.paste(scaled,(x,y+28),scaled)
	sheet.save(output/'south-upper-ownership-comparison.png')
	manifest={'status':'Original mask ownership draft and explicit authored repair/joints; not limb anatomy, grip or gait acceptance','sources':{o:{'path':p,'sha256':h} for o,(p,h) in anchors.SOURCES.items()},'specSha256':digest(SPEC.read_bytes()),'scriptSha256':digest(Path(__file__).read_bytes()),'anchorToolSha256':digest(Path(anchors.__file__).read_bytes()),'cases':cases}
	(output/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
	print('SOUTH OWNERSHIP SOURCE RECOMPOSITION PASS: 4originalcases; authored hidden cloth/joints are proposals only')

if __name__=='__main__': main()
