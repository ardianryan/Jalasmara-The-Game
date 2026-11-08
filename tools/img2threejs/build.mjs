import {spawnSync} from 'node:child_process';
import {mkdirSync,readFileSync,writeFileSync,copyFileSync,readdirSync,existsSync} from 'node:fs';
import {createServer} from 'node:http';
import {resolve,join,extname} from 'node:path';
import {createHash} from 'node:crypto';
import {build} from 'esbuild';
import {chromium} from '@playwright/test';
const base=resolve(import.meta.dirname,'../..');process.chdir(base);
const pin='0c0c49bc168e648dbaf9c8c080474de0b3a941b6',upstream='.runtime/img2threejs-upstream';
function run(cmd,args){const r=spawnSync(cmd,args,{stdio:'inherit'});if(r.status!==0)throw Error(cmd+' failed');}
if(!existsSync(upstream)){run('git',['clone','https://github.com/img2threejs/img2threejs.git',upstream]);run('git',['-C',upstream,'checkout',pin]);}
const actual=spawnSync('git',['-C',upstream,'rev-parse','HEAD'],{encoding:'utf8'}).stdout.trim();if(actual!==pin)throw Error('Upstream revision mismatch');
const python=process.env.IMG2_PYTHON??(existsSync('.runtime/python312/bin/python3')?'.runtime/python312/bin/python3':'python3');
const folder='assets/source-3d/img2threejs',spec=folder+'/memory-slab.spec.json';
run(python,[upstream+'/forge/stage2_spec/validate_sculpt_spec.py',spec,'--strict-quality']);
run(python,[upstream+'/forge/stage3_build/generate_threejs_factory.py',spec,'--out',folder+'/memory-slab.factory.ts','--pass-id','blockout','--force']);
const web='.runtime/img2threejs-web';mkdirSync(web,{recursive:true});
await build({entryPoints:['tools/img2threejs/browser-entry.ts'],outfile:web+'/app.js',bundle:true,format:'esm',platform:'browser',nodePaths:[resolve('tools/img2threejs/node_modules')]});
for(const file of readdirSync(folder+'/material-evidence'))if(file.endsWith('.png'))copyFileSync(folder+'/material-evidence/'+file,web+'/'+file);
writeFileSync(web+'/index.html','<!doctype html><html><body style="margin:0;background:#203b3f"><script type="module" src="app.js"></script></body></html>');
const server=createServer((req,res)=>{const path=resolve(web,'.'+new URL(req.url,'http://localhost').pathname);if(!path.startsWith(resolve(web)+'/')){res.writeHead(404).end();return;}try{res.setHeader('Content-Type',extname(path)==='.js'?'text/javascript':extname(path)==='.png'?'image/png':'text/html');res.end(readFileSync(path));}catch{res.writeHead(404).end();}});await new Promise(r=>server.listen(0,'127.0.0.1',r));
const browser=await chromium.launch({args:['--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader']});const page=await browser.newPage({viewport:{width:512,height:512}});const errors=[];page.on('pageerror',e=>errors.push(e.message));
try{await page.goto(`http://127.0.0.1:${server.address().port}/index.html`);await page.waitForFunction(()=>window.modelReady===true);const metrics=await page.evaluate(()=>window.assetMetrics);if(metrics.triangles<10||metrics.bounds.some(n=>n<=0))throw Error('Degenerate model');
for(const [name,yaw]of [['front',0],['side',1.15],['rear',Math.PI]]){await page.evaluate(yaw=>window.renderModel(yaw),yaw);await page.screenshot({path:folder+'/render-'+name+'.png'});}
const glb=Buffer.from(await page.evaluate(()=>window.exportModel()),'base64');writeFileSync(folder+'/memory-slab.glb',glb);mkdirSync('client-godot/resources/models',{recursive:true});copyFileSync(folder+'/memory-slab.glb','client-godot/resources/models/memory-slab.glb');
writeFileSync(folder+'/manifest.json',JSON.stringify({source:'https://github.com/img2threejs/img2threejs',revision:pin,upstreamLicense:'Apache-2.0',mode:'official strict-validated blockout factory → browser GLTFExporter → static GLB',metrics,sha256:createHash('sha256').update(glb).digest('hex'),browserErrors:errors,limitations:['Approximate low-poly slab; hidden back and thickness inferred.','Only blockout pass rendered; complete eight-pass upstream fidelity approval is not claimed.','No Three.js code runs in the Godot web game.']},null,2)+'\n');if(errors.length)throw Error(errors.join('\n'));console.log('img2threejs GLB + three camera renders PASS',metrics);
}finally{await browser.close();await new Promise(r=>server.close(r));}
