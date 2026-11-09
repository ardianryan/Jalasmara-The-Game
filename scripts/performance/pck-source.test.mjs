import {test} from 'node:test';
import assert from 'node:assert/strict';
import {mkdtempSync,writeFileSync,rmSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {join} from 'node:path';
import {pckSource,isPckRequest,verifyPckOverrideTransport} from './pck-source.mjs';
test('override provenance hashes the delivered file rather than the served candidate',()=>{
 const folder=mkdtempSync(join(tmpdir(),'jalasmara-pck-source-'));
 try{
  const served=join(folder,'new.pck'),old=join(folder,'old.pck');writeFileSync(served,'candidate');writeFileSync(old,'baseline');
  const original=pckSource({servedPath:served}),override=pckSource({servedPath:served,overridePath:old});
  assert.equal(original.mode,'served');assert.equal(override.mode,'intercepted-local-pck');assert.equal(override.bytes,8);assert.notEqual(original.sha256,override.sha256);
  assert.throws(()=>pckSource({overridePath:old,expectedHash:original.sha256}),/checksum mismatch/);
 }finally{rmSync(folder,{recursive:true,force:true});}
});
test('only the exact same-origin GET PCK is intercepted, with cache-query support',()=>{
 const origin='http://localhost:3100';
 assert(isPckRequest(`${origin}/game/index.pck?v=abc`,'GET',origin));
 for(const [url,method] of [[`${origin}/game/index.wasm`,'GET'],[`${origin}/api/adventure/state`,'GET'],[`${origin}/game/index.pckx`,'GET'],['https://example.com/game/index.pck','GET'],[`${origin}/game/index.pck`,'POST']])assert.equal(isPckRequest(url,method,origin),false);
});

test('served profiling performs no override transport probe',async()=>{
 await verifyPckOverrideTransport({origin:'http://localhost:3111',fetcher:()=>assert.fail('Served mode must not issue an override probe')});
});
test('legacy override requires an actual same-origin404 before delivery',async()=>{
 let calls=0;
 await verifyPckOverrideTransport({overridePath:'/local/baseline.pck',origin:'http://localhost:3111',fetcher:async(url,options)=>{
  calls++;assert.equal(url,'http://localhost:3111/game/pck-manifest.json');assert.equal(options.cache,'no-store');assert(options.signal instanceof AbortSignal);assert(!options.signal.aborted);return new Response(null,{status:404});
 }});
 assert.equal(calls,1);
});
test('a present segmented manifest rejects direct-only override even when its hash might match',async()=>{
 await assert.rejects(verifyPckOverrideTransport({overridePath:'/local/baseline.pck',origin:'http://localhost:3111',fetcher:async()=>new Response(JSON.stringify({version:1,sha256:'f'.repeat(64),bytes:64488008,partSize:1048576}),{status:200})}),/PROFILE_OVERRIDE_PCK does not support segmented PCK/);
});
test('manifest errors and network failures cannot masquerade as legacy404',async()=>{
 for(const status of [204,301,401,403,500,503])await assert.rejects(verifyPckOverrideTransport({overridePath:'/local/baseline.pck',origin:'http://localhost:3111',fetcher:async()=>new Response(null,{status})}),/No override was installed|no override was installed/);
 await assert.rejects(verifyPckOverrideTransport({overridePath:'/local/baseline.pck',origin:'http://localhost:3111',fetcher:async()=>{throw new Error('body/connection failed');}}),/body\/connection failed/);
});
test('override guard never requests a non-local server',async()=>{
 await assert.rejects(verifyPckOverrideTransport({overridePath:'/local/baseline.pck',origin:'https://example.com',fetcher:()=>assert.fail('Must reject before fetch')}),/local only/);
});
