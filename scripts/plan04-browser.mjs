import { chromium } from '@playwright/test';
import assert from 'node:assert/strict';
import {readFileSync,mkdirSync,writeFileSync} from 'node:fs';
const fixture=JSON.parse(readFileSync(process.env.BROWSER_FIXTURE??'.runtime/browser.json','utf8'));
const user=fixture.accounts.find(x=>x.role==='player');
const origin=process.env.APP_TEST_ORIGIN??'http://localhost:3100';
const dir='artifacts/godot/plan04'; mkdirSync(dir,{recursive:true});
const browser=await chromium.launch({args:['--enable-webgl','--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader']});
const context=await browser.newContext({viewport:{width:844,height:390},hasTouch:true,isMobile:true,deviceScaleFactor:1});
const page=await context.newPage();page.setDefaultTimeout(60000);
const errors=[],checks=[],heartbeats=[];
page.on('response',async response=>{
 if(!response.url().endsWith('/api/calendar/heartbeat'))return;
 try{const request=response.request().postDataJSON(),body=await response.json();heartbeats.push({paused:request.paused,focused:request.focused,status:response.status(),minute:body.calendar?.minuteOfDay});}catch{}
});
page.on('pageerror',e=>errors.push(e.message));
page.on('console',m=>{if(m.type()==='error')errors.push(m.text());});
let frame;
try{
 await page.addInitScript(()=>{window.jalasmaraDiagnostics=true;});
 await page.goto(origin);await page.getByLabel('Email',{exact:true}).fill(user.email);await page.getByLabel('Password',{exact:true}).fill(fixture.password);
 await page.getByRole('button',{name:'Masuk ke Jalasmara'}).click();await page.waitForURL('**/play');
 frame=await(await page.locator('iframe').elementHandle()).contentFrame();
 await frame.waitForFunction(()=>window.jalasmaraReady&&window.jalasmaraSnapshot?.hud,null,{polling:200,timeout:120000});
 const snapshot=()=>frame.evaluate(()=>window.jalasmaraSnapshot);
 const cdp=await context.newCDPSession(page);
 async function point(center,id=1){const box=await frame.locator('canvas').boundingBox(),logical=(await snapshot()).hud.logicalSize;return{x:box.x+center[0]*box.width/logical[0],y:box.y+center[1]*box.height/logical[1],id,radiusX:4,radiusY:4,force:1};}
 async function tap(name){const s=await snapshot(),p=await point(s.hud[name]);await cdp.send('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[p]});await page.waitForTimeout(120);await cdp.send('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[]});await page.waitForTimeout(700);}
 async function responsive(width,height){await page.setViewportSize({width,height});await page.waitForTimeout(1800);const s=await snapshot(),box=await page.locator('iframe').boundingBox();assert(Math.abs(box.width-width)<2&&Math.abs(box.height-height)<2,'Host must fill viewport');assert(Math.abs(s.hud.logicalSize[0]/s.hud.logicalSize[1]-width/height)<.015,'Godot logical aspect must follow viewport');for(const name of ['bag','journal','map','action','net']){const p=s.hud[name];assert(p[0]>=0&&p[1]>=0&&p[0]<=s.hud.logicalSize[0]&&p[1]<=s.hud.logicalSize[1],`${name} outside viewport`);}checks.push({name:`responsive-${width}x${height}`,logical:s.hud.logicalSize,landViewport:s.land?.viewport});await page.screenshot({path:`${dir}/${width}x${height}.png`});}
 await responsive(844,390);
 for(const control of ['bag','journal','map','objective']){await tap(control);await frame.waitForFunction(()=>window.jalasmaraSnapshot.modal===true,null,{polling:200});await page.screenshot({path:`${dir}/${control}-landscape.png`});await page.keyboard.press('Escape');await frame.waitForFunction(()=>!window.jalasmaraSnapshot.modal,null,{polling:200});checks.push({name:`${control}-opens-closes`});}
 await tap('map');await frame.waitForFunction(()=>window.jalasmaraSnapshot.modal,null,{polling:200});
 await page.setViewportSize({width:390,height:844});await page.waitForTimeout(1800);
 assert.equal((await snapshot()).modal,true,'Rotating with atlas open must retain its modal state');
 await page.screenshot({path:`${dir}/map-portrait.png`});
 await page.keyboard.press('m');await frame.waitForFunction(()=>!window.jalasmaraSnapshot.modal,null,{polling:200});
 checks.push({name:'atlas-open-resize-and-keyboard-toggle'});
 await responsive(390,844);
 await tap('bag');await frame.waitForFunction(()=>window.jalasmaraSnapshot.modal,null,{polling:200});await page.screenshot({path:`${dir}/bag-portrait.png`});await page.keyboard.press('Escape');await frame.waitForFunction(()=>!window.jalasmaraSnapshot.modal,null,{polling:200});
 await responsive(844,390);
 const s=await snapshot(),j=s.hud.joystick,c=await point(j.center),end=await point([j.center[0]+j.radius*.6,j.center[1]-j.radius*.6]);
 await cdp.send('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[c]});await cdp.send('Input.dispatchTouchEvent',{type:'touchMove',touchPoints:[end]});await page.waitForTimeout(200);
 const firstHeld=await snapshot(); const sound=await point(s.hud.sound,2);await cdp.send('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[end,sound]});await page.waitForTimeout(350);await cdp.send('Input.dispatchTouchEvent',{type:'touchMove',touchPoints:[end]});await page.waitForTimeout(150);
 const held=await snapshot();assert(Math.hypot(...firstHeld.hud.joystick.direction)>.1,'First pointer must move joystick'); assert(Math.hypot(...held.hud.joystick.direction)>.1,'Second pointer release must preserve first joystick pointer');await cdp.send('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[]});await page.waitForTimeout(650);assert(Math.hypot(...(await snapshot()).hud.joystick.direction)<.01);checks.push({name:'joystick-multitouch-independent-release'});
 assert(!(await snapshot()).diving,'Plan04 calendar pause test requires a land fixture');
 const pausedHeartbeat=page.waitForResponse(response=>response.url().endsWith('/api/calendar/heartbeat')&&response.request().postDataJSON()?.paused===true);
 await page.getByRole('button',{name:'Menu',exact:true}).click();
 await frame.waitForFunction(()=>window.jalasmaraSnapshot?.weather?.clockPaused===true,null,{polling:200});
 assert.equal((await pausedHeartbeat).status(),200,'Server must acknowledge host-menu calendar pause');
 await page.waitForTimeout(700);
 const paused=await snapshot();
 assert(Number.isFinite(paused.calendar?.minuteOfDay),'Authoritative calendar snapshot missing');
 await page.waitForTimeout(6200);
 const still=await snapshot();
 assert.equal(still.weather.clockPaused,true);
 assert.equal(still.calendar.minuteOfDay,paused.calendar.minuteOfDay,'Server calendar must remain stable through the next paused heartbeat');
 assert.equal(still.weather.clock,paused.weather.clock,'Visual clock must remain paused');
 assert(Math.hypot(still.x-paused.x,still.y-paused.y)<2,'Menu must pause player');
 await page.screenshot({path:`${dir}/menu.png`});
 checks.push({name:'host-menu-pauses-server-and-visual-clock',minute:still.calendar.minuteOfDay});
 const requested=still.performance?.quality?.requested;
 assert(requested,'Actual engine quality profile is required for trusted host-message test');
 const maliciousQuality=requested==='low'?'balanced':'low';
 await frame.evaluate(quality=>{
  const data={type:'jalasmara:viewport',version:1,hostMenuOpen:false,focused:true,graphicsQuality:quality};
  window.postMessage(data,location.origin);
  window.dispatchEvent(new MessageEvent('message',{data,origin:'https://untrusted.invalid',source:window.parent}));
 },maliciousQuality);
 await page.evaluate(quality=>document.querySelector('iframe').contentWindow.postMessage({type:'jalasmara:viewport',version:999,hostMenuOpen:false,focused:true,graphicsQuality:quality},location.origin),maliciousQuality);
 await page.waitForTimeout(900);
 const defended=await snapshot();
 assert.equal(defended.weather.clockPaused,true,'Spoofed sender/origin/version must not resume the game');
 assert.equal(defended.performance.quality.requested,requested,'Spoofed sender/origin/version must not change actual graphics');
 checks.push({name:'host-message-source-origin-version-rejected'});
 if(process.env.VERIFY_QUALITY==='1'){
  for(const value of ['low','balanced','auto']){
   await page.getByLabel('Kualitas dunia',{exact:true}).selectOption(value);
   await frame.waitForFunction((requested)=>window.jalasmaraSnapshot?.performance?.quality?.requested===requested,value,{polling:200});
   const current=await snapshot(),quality=current.performance.quality;
   assert.equal(quality.effective,value==='auto'?'low':value);
   assert.equal(quality.sunShadows,quality.effective==='balanced');
   assert.equal(quality.spotShadowAtlasSize,512);
   for(const metric of ['fps','processMs','physicsMs','drawCalls'])assert(Number.isFinite(current.performance[metric]),`Missing actual monitor ${metric}`);
   checks.push({name:`actual-render-quality-${value}`,profile:quality,performance:current.performance});
  }
 }
 await page.getByRole('button',{name:'Layar penuh',exact:true}).click();await page.waitForTimeout(1200);assert(await page.evaluate(()=>!!document.fullscreenElement),'Real fullscreen must enter');checks.push({name:'real-browser-fullscreen'});await page.getByRole('button',{name:'Keluar layar penuh',exact:true}).click();await page.getByRole('button',{name:'Lanjut bermain',exact:true}).click();await frame.waitForFunction(()=>window.jalasmaraSnapshot?.weather?.clockPaused===false,null,{polling:200});
 assert.deepEqual(errors,[]);writeFileSync(`${dir}/results.json`,JSON.stringify({checks,heartbeats,errors},null,2));console.log(JSON.stringify({passed:checks.length,checks,errors}));
}catch(error){await page.screenshot({path:`${dir}/failure.png`}).catch(()=>{});writeFileSync(`${dir}/errors.json`,JSON.stringify({message:error.message,errors,heartbeats,snapshot:frame?await frame.evaluate(()=>window.jalasmaraSnapshot).catch(()=>null):null,checks},null,2));console.error(error);process.exitCode=1;}finally{await browser.close();}
