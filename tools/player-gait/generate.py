#!/usr/bin/env python3
"""Original side-gait cutouts. Does not invent missing front/rear directional artwork."""
import hashlib,json,math
from pathlib import Path
from PIL import Image,ImageDraw
ROOT=Path(__file__).resolve().parents[2]
ART=ROOT/'client-godot/resources/art'
OUT=ART/'player-gait'
S=100/418
STRIDE=56.0

def maskcrop(im,polygon):
 mask=Image.new('L',im.size);ImageDraw.Draw(mask).polygon(polygon,fill=255)
 out=im.copy();out.putalpha(Image.composite(im.getchannel('A'),Image.new('L',im.size),mask));box=out.getbbox()
 cut=out.crop(box);cut=cut.resize((max(1,round(cut.width*S)),max(1,round(cut.height*S))),Image.Resampling.NEAREST)
 return cut,((box[0]+box[2])/2*S,(box[1]+box[3])/2*S)

def bone(im,a,b,width,solid=False):
 dx,dy=b[0]-a[0],b[1]-a[1];length=math.hypot(dx,dy);ux,uy=dx/length,dy/length
 w=max(3,round(width*S));h=max(4,round(length*S));part=Image.new('RGBA',(w,h))
 for y in range(h):
  for x in range(w):
   along=(y+.5)/S;cross=(x+.5-w/2)/S;sx,sy=round(a[0]+ux*along-uy*cross),round(a[1]+uy*along+ux*cross)
   if 0<=sx<418 and 0<=sy<418:part.putpixel((x,y),im.getpixel((sx,sy)))
 if solid:
  opaque=[(x,y,part.getpixel((x,y))) for y in range(h) for x in range(w) if part.getpixel((x,y))[3]>=128]
  for y in range(h):
   half=max(1.3,w*(.47-.08*y/max(1,h-1)))
   for x in range(w):
    if abs(x-(w-1)/2)>half:part.putpixel((x,y),(0,0,0,0))
    elif part.getpixel((x,y))[3]<128 and opaque:part.putpixel((x,y),min(opaque,key=lambda p:(p[0]-x)**2+(p[1]-y)**2)[2])
 return part

def place(canvas,im,center,angle=0):
 if angle:im=im.rotate(-math.degrees(angle),resample=Image.Resampling.NEAREST,expand=True)
 canvas.alpha_composite(im,(round(center[0]-im.width/2),round(center[1]-im.height/2)))

def drawbone(canvas,im,a,b):
 length=max(1,round(math.hypot(b[0]-a[0],b[1]-a[1])))
 if length!=im.height:im=im.resize((im.width,length),Image.Resampling.NEAREST)
 angle=math.atan2(b[1]-a[1],b[0]-a[0])-math.pi/2
 center=(a[0]+math.cos(angle+math.pi/2)*im.height/2,a[1]+math.sin(angle+math.pi/2)*im.height/2)
 place(canvas,im,center,angle)

def knee(a,b,l1,l2):
 dx,dy=b[0]-a[0],b[1]-a[1];d=min(math.hypot(dx,dy),l1+l2-.01);ux,uy=dx/max(.01,math.hypot(dx,dy)),dy/max(.01,math.hypot(dx,dy));v=(l1*l1-l2*l2+d*d)/(2*d);h=math.sqrt(max(0,l1*l1-v*v))
 return(a[0]+ux*v+uy*h,a[1]+uy*v-ux*h)

def generate(identity):
 path=ART/(identity+'-outfits-v1.png');source=Image.open(path).convert('RGBA');atlas=Image.new('RGBA',(800,300));metadata={'identity':identity,'source':path.name,'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'directions':['east','west'],'fallbackDirections':['north','south','north_east','north_west','south_east','south_west'],'frames':8,'cell':[100,100],'stride':STRIDE,'footPivot':[50,98],'outfits':['daily','explorer','diving'],'contacts':[0,4],'phases':['contact','down','passing','up','contact','down','passing','up'],'clips':[]}
 for row in range(3):
  im=source.crop((0,row*418,418,(row+1)*418));im.putalpha(im.getchannel('A').point(lambda a:255 if a>=128 else 0))
  # Atlas identities share cell coordinates; per-source silhouette bounds normalize their original height.
  bbox=im.getbbox();normalized=Image.new('RGBA',(418,418));cropped=im.crop(bbox);target=(round(cropped.width*358/cropped.height),358);cropped=cropped.resize(target,Image.Resampling.NEAREST);normalized.alpha_composite(cropped,(round(224-target[0]/2),60));im=normalized
  torso,tc=maskcrop(im,[(175,153),(238,153),(261,174),(265,276),(194,277),(194,215),(166,207),(172,175)])
  head,hc=maskcrop(im,[(120,48),(290,48),(290,145),(254,170),(188,164),(120,148)])
  parts=[]
  for side in range(2):
   hip=(208,279) if side==0 else (247,279);kne=(197,346) if side==0 else (247,346);ank=(185,395) if side==0 else (254,395)
   arm=((183,211),(179,254),(178,285)) if side==0 else ((265,208),(277,248),(284,279))
   upper=bone(im,hip,kne,44,True);lower=bone(im,kne,ank,33,True)
   box=(163,388,215,418) if side==0 else (232,387,304,418);foot=im.crop(box).resize((round((box[2]-box[0])*S),round((box[3]-box[1])*S)),Image.Resampling.NEAREST)
   ua=bone(im,arm[0],arm[1],27);la=bone(im,arm[1],arm[2],25)
   parts.append((hip,upper,lower,foot,arm,ua,la))
  for frame in range(8):
   canvas=Image.new('RGBA',(100,100));p=frame/8;bob=1.3*math.sin(p*4*math.pi);shift=-2+bob
   feet=[]
   for side in [1,0]:
    hip,upper,lower,foot,arm,ua,la=parts[side];phase=(p+side*.5)%1
    fx=STRIDE*.25-phase*STRIDE if phase<.5 else -STRIDE*.25+(phase-.5)*STRIDE
    lift=0 if phase<.5 else math.sin((phase-.5)*2*math.pi)*7
    h=(hip[0]*S,hip[1]*S+shift);ank=(hip[0]*S+fx,98-foot.height-lift);kn=knee(h,ank,upper.height,lower.height)
    drawbone(canvas,upper,h,kn);drawbone(canvas,lower,kn,ank);place(canvas,foot,(ank[0]+1,ank[1]+foot.height/2));feet.append({'side':side,'x':ank[0],'sole':98-lift,'support':phase<.5})
   place(canvas,torso,(tc[0],tc[1]+shift));place(canvas,head,(hc[0],hc[1]+shift))
   for side in [1,0]:
    hip,upper,lower,foot,arm,ua,la=parts[side];phase=p+side*.5;sh=(arm[0][0]*S,arm[0][1]*S+shift);hand=(sh[0]-math.cos(phase*2*math.pi)*7,sh[1]+ua.height+la.height-2);el=knee(sh,hand,ua.height,la.height)
    drawbone(canvas,ua,sh,el);drawbone(canvas,la,el,hand)
    handbox=(165,278,197,307) if side==0 else (273,270,301,299)
    palm=im.crop(handbox).resize((max(3,round((handbox[2]-handbox[0])*S)),7),Image.Resampling.NEAREST)
    place(canvas,palm,(hand[0],hand[1]+1))
   atlas.alpha_composite(canvas,(frame*100,row*100));metadata['clips'].append({'outfit':row,'frame':frame,'feet':feet,'bodyDown':bob})
 OUT.mkdir(parents=True,exist_ok=True);atlas.save(OUT/(identity+'.png'));(OUT/(identity+'.json')).write_text(json.dumps(metadata,indent=2)+'\n')
if __name__=='__main__':
 for identity in ['male-default','male-nusantara','female-default','female-nusantara']:generate(identity)
