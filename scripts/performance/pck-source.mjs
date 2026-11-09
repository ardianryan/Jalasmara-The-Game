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
