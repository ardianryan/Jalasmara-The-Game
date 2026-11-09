// Isolated LOCAL scene fixtures; this measures rendering, not a gameplay acceptance route.
import {chromium} from '@playwright/test';
import {MongoClient} from 'mongodb';
import Redis from 'ioredis';
import argon2 from 'argon2';
import {randomUUID,randomBytes,createHash} from 'node:crypto';
import {mkdirSync,writeFileSync,existsSync} from 'node:fs';
import {execFileSync} from 'node:child_process';
import assert from 'node:assert/strict';
import {platform,arch,release,cpus,totalmem} from 'node:os';
import {freshProgress,freshAbilities,freshCalendar,freshHomestead,calendarRain} from '../../packages/shared/src/index.ts';
import {WORLD} from '../../packages/shared/src/world.ts';
import {isLandWalkable} from '../../packages/shared/src/land.ts';
import {parseForestPoint} from './forest-point.mjs';
import {summarizeCapture,scalarMetrics} from './metrics.mjs';
import {pckSource,isPckRequest} from './pck-source.mjs';

const origin=process.env.APP_TEST_ORIGIN??'http://localhost:3100';
const mongoUrl=process.env.MONGO_URL??'mongodb://127.0.0.1:27018/jalasmara?replicaSet=rs0';
const redisUrl=process.env.REDIS_URL??'redis://127.0.0.1:6380';
assert(['localhost','127.0.0.1'].includes(new URL(origin).hostname));
assert(/^mongodb:\/\/(127\.0\.0\.1|localhost)(:|\/)/.test(mongoUrl));
assert(['localhost','127.0.0.1'].includes(new URL(redisUrl).hostname));
const duration=Number(process.env.PROFILE_SAMPLE_MS??15000),warmup=Number(process.env.PROFILE_WARMUP_MS??8000);
assert(duration>=1000&&duration<=120000&&warmup>=7000&&warmup<=60000);
const pck={...pckSource({overridePath:process.env.PROFILE_OVERRIDE_PCK,servedPath:process.env.PROFILE_PCK_FILE,expectedHash:process.env.PROFILE_EXPECTED_PCK_SHA}),interceptedRequests:0};
const directory=process.env.PROFILE_OUTPUT??'artifacts/performance/06p-baseline';mkdirSync(directory,{recursive:true});
assert(!existsSync(`${directory}/results.json`),'Choose a new PROFILE_OUTPUT; existing captures are immutable');
const forestPoint=parseForestPoint(process.env.PROFILE_FOREST_POINT,(point,margin)=>isLandWalkable(WORLD.landMaps.forest,point,margin));
const expectActiveCanopy=process.env.PROFILE_EXPECT_ACTIVE_CANOPY==='1';
const cases=[
 {id:'village-day',area:'hub',point:WORLD.surfaceSpawn,minute:600,rain:false},
 {id:'forest-day',area:'forest',point:forestPoint,minute:600,rain:false},
 {id:'ocean-reef',area:'ocean',point:WORLD.hub.divePoint,minute:600,rain:false},
 {id:'village-night',area:'hub',point:{x:595,y:650},minute:1200,rain:false},
 {id:'forest-rain',area:'forest',point:{x:1300,y:660},minute:600,rain:true},
].map((value,order)=>({...value,order})).filter(value=>!process.env.PROFILE_SCENARIOS||process.env.PROFILE_SCENARIOS.split(',').includes(value.id));
assert(cases.length>0);
if(expectActiveCanopy)assert(cases.some(value=>value.id==='forest-day'),'Active canopy validation requires forest-day');
const report={source:execFileSync('git',['rev-parse','HEAD'],{encoding:'utf8'}).trim(),runtimeBaseline:process.env.PROFILE_RUNTIME_SHA??'UNVERIFIED',pckSHA256:pck.sha256,pckDelivery:pck,origin,createdAt:new Date().toISOString(),environment:{platform:platform(),arch:arch(),osRelease:release(),cpuModel:cpus()[0]?.model,cpuCount:cpus().length,totalMemoryBytes:totalmem(),browser:null},validation:{requiresActiveCanopy:expectActiveCanopy},method:{forestDayPoint:[forestPoint.x,forestPoint.y],assetDelivery:pck.mode,device:'Chromium SwiftShader software GPU; not Windows/S23 hardware',viewport:[844,390],diagnostics:true,motion:'Stationary player; actual NPC/fauna/water/weather remain active',sampleMs:duration,warmupMs:warmup,profileOrder:'Alternating low/balanced order per scene; warmup outside measurement',startup:pck.mode==='served'?'First scene cold context + same-context warm reload; others fresh contexts':'Excluded: local PCK intercept is not network/startup measurement',godotSampling:'Latest actual Godot counters sampled at most every100ms; separate from iframe RAF intervals'},results:[],startup:[],errors:[],cleanup:false};
let browser,context,page,frame;const fixtures=[];const mongo=new MongoClient(mongoUrl),redis=new Redis(redisUrl);
const save=()=>writeFileSync(`${directory}/results.json`,JSON.stringify(report,null,2));
const snapshot=()=>frame.evaluate(()=>window.jalasmaraSnapshot);
async function until(predicate,timeout=45000){const started=Date.now();while(Date.now()-started<timeout){const value=await snapshot();if(predicate(value))return value;await page.waitForTimeout(250);}throw Error('Expected scene condition not reached');}
async function attach(){frame=await(await page.locator('iframe').elementHandle()).contentFrame();await frame.waitForFunction(()=>window.jalasmaraReady&&window.jalasmaraSnapshot?.performance,null,{polling:200,timeout:180000});await frame.locator('canvas').focus();}
async function startup(kind){
 if(pck.mode==='intercepted-local-pck'){report.startup.push({kind,excluded:true,reason:'Local PCK intercepted: not a network/startup benchmark',pckSHA256:pck.sha256});save();return;}
 const observed=await page.evaluate(()=>window.profileLoading);
 const timing=await frame.evaluate(()=>performance.getEntriesByType('resource').filter(value=>/\/game\/index\.(wasm|pck)$/.test(new URL(value.name).pathname)).map(value=>({path:new URL(value.name).pathname,durationMs:value.duration,transferSize:value.transferSize,encodedBodySize:value.encodedBodySize,decodedBodySize:value.decodedBodySize})));
 report.startup.push({kind,hostReadyMs:observed.readyMs,decodedProgressBytes:Math.max(0,...observed.events.map(value=>value.downloadedBytes??0)),resources:timing,notes:'ResourceTiming transferSize includes protocol/cache effects; decoded progress is not network transfer'});save();
}
async function capture(){return frame.evaluate(ms=>new Promise(resolve=>{
 const intervals=[],samples=[];let previous=null,lastSample=-Infinity,hidden=0;const start=performance.now();
 const tick=now=>{if(previous!==null)intervals.push(now-previous);previous=now;if(document.hidden)hidden++;if(now-lastSample>=100){lastSample=now;const p=window.jalasmaraSnapshot?.performance??{};samples.push(Object.fromEntries(['fps','processMs','physicsMs','drawCalls','renderObjects','renderPrimitives','pathQueue'].map(key=>[key,p[key]??null])));}if(now-start<ms)requestAnimationFrame(tick);else resolve({durationMs:now-start,frameIntervals:intervals,engineSamples:samples,hiddenSamples:hidden});};requestAnimationFrame(tick);
}),duration);}
try{
 await mongo.connect();assert(await mongo.db().collection('contents').findOne({state:'published'}),'Local published content required');
 browser=await chromium.launch({args:['--enable-webgl','--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader']});
 report.environment.browser=browser.version();
 for(const [index,scenario] of cases.entries()){
  let id;do{id=randomUUID();}while(calendarRain(id,1)!==scenario.rain);
  const password=randomBytes(24).toString('base64url'),email=`profile06-${id}@test.invalid`,now=new Date().toISOString();fixtures.push({id,email,auth:[]});
  await mongo.db().collection('players').insertOne({id,email,name:'Nala Uji Profil06',role:'player',status:'active',appearance:'male_default',coins:0,inventory:[],abilities:freshAbilities(),progress:{...freshProgress(),tutorial:true},adventure:{discoveries:[],puzzles:[],keyItems:[]},calendar:{...freshCalendar(),minuteOfDay:scenario.minute},homestead:freshHomestead(),version:0,authVersion:0,passwordHash:await argon2.hash(password,{type:argon2.argon2id}),createdAt:now,updatedAt:now});
  const area=scenario.area==='forest'?'forest':'hub';await redis.set(`surface:${id}`,JSON.stringify({area,...scenario.point,layoutVersion:WORLD.landMaps[area].layoutVersion,playerVersion:0,positionAt:Date.now()}),'EX',1800);
  context=await browser.newContext({viewport:{width:844,height:390},hasTouch:true,isMobile:true,deviceScaleFactor:1,serviceWorkers:'block'});page=await context.newPage();page.setDefaultTimeout(60000);
  if(pck.mode==='intercepted-local-pck')await context.route('**/game/index.pck*',async route=>{const request=route.request();if(!isPckRequest(request.url(),request.method(),origin))return route.continue();pck.interceptedRequests++;await route.fulfill({path:pck.path,contentType:'application/octet-stream',headers:{'Cache-Control':'no-store','Content-Length':String(pck.bytes)}});});
  page.on('pageerror',error=>report.errors.push({scene:scenario.id,type:'pageerror',message:error.message}));page.on('console',message=>{if(message.type()==='error')report.errors.push({scene:scenario.id,type:'console',message:message.text()});});
  const profiles=scenario.order%2?['balanced','low']:['low','balanced'];
  await page.addInitScript(initial=>{window.jalasmaraDiagnostics=true;localStorage.setItem('jalasmara.graphicsQuality',initial);if(window!==window.top)return;window.profileLoading={events:[],readyMs:null};addEventListener('message',event=>{if(event.origin!==location.origin||event.source!==document.querySelector('iframe')?.contentWindow)return;if(event.data?.type==='jalasmara:loading')window.profileLoading.events.push({at:performance.now(),phase:event.data.phase,downloadedBytes:event.data.downloadedBytes,totalBytes:event.data.totalBytes});if(event.data?.type==='jalasmara:ready')window.profileLoading.readyMs=performance.now();});},profiles[0]);
  const guest=await(await context.request.get(`${origin}/api/auth/session`)).json();const login=await context.request.post(`${origin}/api/auth/login`,{data:{email,password},headers:{Origin:origin,'X-CSRF-Token':guest.csrf}});assert(login.ok(),`Local fixture login status${login.status()}`);const auth=await login.json();
  if(scenario.area==='ocean'){const dive=await context.request.post(`${origin}/api/dive/start`,{data:{mode:'dive'},headers:{Origin:origin,'X-CSRF-Token':auth.csrf,'Idempotency-Key':randomUUID()}});assert(dive.ok(),`Start ordinary dive status${dive.status()}`);}
  const deliveredBefore=pck.interceptedRequests;await page.goto(`${origin}/play`);await attach();
  if(pck.mode==='intercepted-local-pck')assert(pck.interceptedRequests>deliveredBefore,'Expected real PCK override request was not delivered');
  if(index===0)await startup('cold-context');
  await until(value=>scenario.area==='ocean'?value.diving:value.land?.active&&value.land.area===area);
  if(scenario.area==='ocean'){
   await page.keyboard.down('a');await page.waitForTimeout(1800);await page.keyboard.up('a');await page.keyboard.down('s');await page.waitForTimeout(600);await page.keyboard.up('s');await page.waitForTimeout(400);
  }
  for(const profile of profiles){
   await page.getByRole('button',{name:'Menu',exact:true}).click();await page.getByLabel('Kualitas dunia',{exact:true}).selectOption(profile);await page.getByRole('button',{name:'Lanjut bermain',exact:true}).click();await frame.locator('canvas').focus();
   await until(value=>value.performance?.quality?.effective===profile&&!value.weather.clockPaused&&value.weather.clockWriter);
   await page.waitForTimeout(warmup);const before=await snapshot();assert.equal(before.weather.night,scenario.minute>=1110);assert(scenario.rain?before.weather.rain>.5:before.weather.rain<.05);
   if(scenario.id==='forest-day'){assert(before.land.actors.player>=1,'Actual Nala Sprite3D must be active');assert(Math.hypot(before.x-forestPoint.x,before.y-forestPoint.y)<3,'Forest fixture position changed');if(expectActiveCanopy)assert(before.land.readability?.revealed>0,'Expected active canopy reveal before sample');}
   const cdp=await context.newCDPSession(page);await cdp.send('Performance.enable');const memoryBefore=scalarMetrics(await cdp.send('Performance.getMetrics'));const heapBefore=await cdp.send('Runtime.getHeapUsage');
   const captured=await capture();const memoryAfter=scalarMetrics(await cdp.send('Performance.getMetrics'));const heapAfter=await cdp.send('Runtime.getHeapUsage');const after=await snapshot();assert.equal(captured.hiddenSamples,0,'Hidden-tab RAF cannot be a foreground benchmark');
   if(scenario.id==='forest-day'){assert(after.land.actors.player>=1,'Actual Nala must remain active');if(expectActiveCanopy)assert(after.land.readability?.revealed>0,'Expected active canopy reveal after sample');}
   const result={scenario:scenario.id,profile,conditions:{before:{position:[before.x,before.y],weather:before.weather,camera:(before.land?.active?before.land:before.hybrid)?.camera??before.hybrid?.camera_center},after:{position:[after.x,after.y],weather:after.weather}},renderer:before.land?.active?before.land:before.hybrid,avatar:{appearance:before.appearance,renderedPlayers:before.land?.actors?.player??null},summary:summarizeCapture(captured),browserMemory:{before:memoryBefore,after:memoryAfter,heapBefore,heapAfter,definition:'CDP DOM/JS heap counters; not Godot nodes, total process RSS, GPU VRAM, or total WASM memory'},raw:captured};report.results.push(result);save();await page.screenshot({path:`${directory}/${scenario.id}-${profile}.png`});
   if(process.env.PROFILE_CPU==='1'&&scenario.id==='village-day'&&profile==='balanced'){
    await cdp.send('Profiler.enable');await cdp.send('Profiler.start');await page.waitForTimeout(5000);const trace=await cdp.send('Profiler.stop');writeFileSync(`${directory}/village-balanced.cpuprofile`,JSON.stringify(trace.profile));await cdp.send('Profiler.disable');
   }
   await cdp.detach();console.log(JSON.stringify({scenario:scenario.id,profile,rafMs:result.summary.rafIntervalsMs,godotProcessMs:result.summary.sampledGodot.processMs,drawCalls:result.summary.sampledGodot.drawCalls}));
  }
  if(index===0){await page.reload();await attach();await startup('warm-reload-same-context');}
  for(const cookie of await context.cookies())if(cookie.name==='jalasmara')fixtures.at(-1).auth.push(`auth:${createHash('sha256').update(cookie.value).digest('hex')}`);
  await context.close();context=null;save();
 }
 assert.deepEqual(report.errors,[]);
}catch(error){
 report.failure={name:error.name,message:error.message};
 if(page&&!page.isClosed())await page.screenshot({path:`${directory}/failure.png`}).catch(()=>{});
 save();throw error;
}finally{
 if(context){for(const cookie of await context.cookies().catch(()=>[]))if(cookie.name==='jalasmara')fixtures.at(-1)?.auth.push(`auth:${createHash('sha256').update(cookie.value).digest('hex')}`);await context.close();}
 if(browser)await browser.close();
 for(const fixture of fixtures){await mongo.db().collection('players').deleteOne({id:fixture.id,email:fixture.email,role:'player'});await mongo.db().collection('receipts').deleteMany({_id:{$regex:`^${fixture.id}:`}});await mongo.db().collection('shifts').deleteMany({userId:fixture.id});await redis.del(`surface:${fixture.id}`,`home:${fixture.id}`,`dive:${fixture.id}`,`calendar:writer:${fixture.id}`,...fixture.auth);}
 report.cleanup=true;save();await mongo.close();await redis.quit();
}
