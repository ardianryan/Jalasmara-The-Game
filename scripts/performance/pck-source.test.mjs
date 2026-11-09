import {test} from 'node:test';
import assert from 'node:assert/strict';
import {mkdtempSync,writeFileSync,rmSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {join} from 'node:path';
import {pckSource,isPckRequest} from './pck-source.mjs';
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
