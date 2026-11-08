import {mkdirSync,writeFileSync,readFileSync,copyFileSync} from 'node:fs';
import {fileURLToPath} from 'node:url';
import {dirname,resolve} from 'node:path';
import {execFileSync} from 'node:child_process';
import {createHash} from 'node:crypto';
const here=dirname(fileURLToPath(import.meta.url)), root=resolve(here,'../..');
const cli=resolve(here,'node_modules/pixelbolt/bin/pixelbolt.js');
const palette={c:'#AF8759',w:'#F1E1BC',t:'#6FABA2',a:'#A2D8CA',d:'#496C68',f:'#D59A53',h:'#FFF0C5',s:'#B8C9BE88',m:'#74D4CD'};
const specs=[['lantern-flame',4,130],['bubble-splash',8,90],['pot-steam',6,160],['memory-spark',6,110]];
const hashes={};
for(const [name,count,duration] of specs){
 const frames=[];
 for(let frame=0;frame<count;frame++){
  const grid=Array.from({length:32},()=>Array(32).fill('.'));
  const put=(x,y,c)=>{x=Math.round(x);y=Math.round(y);if(x>=0&&x<32&&y>=0&&y<32)grid[y][x]=c;};
  const ellipse=(cx,cy,rx,ry,c,ring=false)=>{for(let y=Math.floor(cy-ry);y<=cy+ry;y++)for(let x=Math.floor(cx-rx);x<=cx+rx;x++){const d=((x-cx)/rx)**2+((y-cy)/ry)**2;if(d<=1&&(!ring||d>.43))put(x,y,c);}};
  if(name==='lantern-flame'){
   const sway=[0,1,0,-1][frame];
   ellipse(16,24,6,3,'c');ellipse(16,20,5,7,'f');ellipse(16+sway,14,3,7-frame%2,'f');
   ellipse(16,21,3,5,'w');ellipse(16+sway,18,2,4,'h');put(17+sway,7-frame%2,'f');
   for(let x=11;x<=21;x++)put(x,26,'c');
  }else if(name==='bubble-splash'){
   const t=frame/7;
   for(let i=0;i<5;i++){const angle=-Math.PI+(i/4)*Math.PI;const distance=3+t*12;const x=16+Math.cos(angle)*distance,y=25+Math.sin(angle)*distance-t*5;ellipse(x,y,Math.max(1,3-frame*.25),Math.max(1,3-frame*.25),'t',true);put(x-1,y-1,'a');}
   if(frame<4)for(let x=7-frame;x<25+frame;x++)if((x+frame)%3!==0)put(x,27-frame%2,'a');
  }else if(name==='pot-steam'){
   for(let i=0;i<3;i++){const step=(frame+i*2)%6;const y=27-step*4;const x=12+i*4+Math.round(Math.sin(step*1.3+i)*2);ellipse(x,y,2+Math.floor(step/3),2,'s');put(x-1,y-1,'w');}
  }else{
   const size=[1,3,5,4,2,1][frame];
   for(let i=-size;i<=size;i++){put(16+i,16,'m');put(16,16+i,'m');}
   put(16,16,'h');put(15,16,'w');put(16,15,'w');
   for(let i=0;i<4;i++){const angle=i*Math.PI/2+frame*.18;const r=6+frame;put(16+Math.cos(angle)*r,16+Math.sin(angle)*r,'t');}
  }
  frames.push({name:`${name}-${frame}`,duration,ops:[{op:'grid',x:0,y:0,rows:grid.map(row=>row.join(''))}]});
 }
 const recipe={version:1,name,width:32,height:32,palette,frames,animations:{idle:{frames:frames.map(f=>f.name),loop:name!=='bubble-splash'}}};
 const path=resolve(here,'recipes',`${name}.json`);writeFileSync(path,JSON.stringify(recipe,null,2)+'\n');
 const out=resolve(root,'.runtime/pixelbolt',name);mkdirSync(out,{recursive:true});
 execFileSync(process.execPath,[cli,'validate',path],{stdio:'pipe'});
 const args=['render',path,'--out',out,'--force','--expect',JSON.stringify({width:32,height:32,frames:count})];
 execFileSync(process.execPath,[cli,...args],{stdio:'pipe'});
 const hash=()=>createHash('sha256').update(readFileSync(resolve(out,`${name}.png`))).digest('hex');
 const before=hash();execFileSync(process.execPath,[cli,...args],{stdio:'pipe'});
 if(before!==hash())throw new Error(`Non-deterministic ${name}`);
 for(const suffix of ['png','tres','atlas.json'])copyFileSync(resolve(out,`${name}.${suffix}`),resolve(root,'client-godot/resources/art/pixelbolt',`${name}.${suffix}`));
 hashes[name]={frames:count,width:32,height:32,sha256:before};
}
writeFileSync(resolve(here,'manifest.json'),JSON.stringify({generator:'pixelbolt@0.13.0',authorship:'Original Jalasmara recipes; no third-party artwork',assets:hashes},null,2)+'\n');
console.log('Pixelbolt: four recipes validated, rendered twice byte-identically, PNG/SpriteFrames/atlas exported.');
