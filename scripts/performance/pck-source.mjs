import assert from 'node:assert/strict';
import {existsSync,readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {createHash} from 'node:crypto';
export function pckSource({overridePath,servedPath,expectedHash}) {
 const mode=overridePath?'intercepted-local-pck':'served';
 const selected=overridePath??servedPath;
 if(!selected)return {mode,path:null,sha256:null,bytes:null};
 assert(existsSync(selected),'Selected PCK file must exist');
 const data=readFileSync(selected),sha256=createHash('sha256').update(data).digest('hex');
 if(expectedHash)assert.equal(sha256,expectedHash,'PCK checksum mismatch');
 return {mode,path:resolve(selected),sha256,bytes:data.length};
}
export function isPckRequest(rawUrl,method,origin) {
 const url=new URL(rawUrl);
 return method==='GET'&&url.origin===origin&&url.pathname==='/game/index.pck';
}

export async function verifyPckOverrideTransport({overridePath,origin,fetcher=fetch}) {
 if(!overridePath)return;
 assert(['localhost','127.0.0.1'].includes(new URL(origin).hostname),'PCK profiling overrides are local only');
 const response=await fetcher(new URL('/game/pck-manifest.json',origin).href,{cache:'no-store',signal:AbortSignal.timeout(10000)});
 assert.equal(response.status,404,response.ok
  ?'PROFILE_OVERRIDE_PCK does not support segmented PCK delivery. Use the served candidate with PROFILE_PCK_FILE; no override was installed.'
  :`Cannot establish legacy direct-PCK delivery: manifest returned HTTP${response.status}. No override was installed.`);
}
