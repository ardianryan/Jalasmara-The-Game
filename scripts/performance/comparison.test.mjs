import {test} from 'node:test';
import assert from 'node:assert/strict';
import {compareCaptures} from './comparison.mjs';
const batch=(hash,p95)=>({method:{device:'software',diagnostics:true,sampleMs:15000,warmupMs:8000,motion:'stationary',profileOrder:'alternating',viewport:[844,390]},cleanup:true,errors:[],pckSHA256:hash,results:[{scenario:'forest-day',profile:'low',summary:{rafIntervalsMs:{p50:16,p95},hitches:{over50Ms:0},sampledGodot:{processMs:{p50:8,p95:10},drawCalls:{p50:200}}}}]});
test('comparison separates RAF delta from CPU and identifies only a rerun candidate',()=>{
 const [row]=compareCaptures(batch('old',30),batch('new',60));
 assert.equal(row.rafP95DeltaMs,30);assert.equal(row.rafP95Ratio,2);assert.equal(row.rerunRecommended,true);assert.equal(row.after.godotProcessMs.p95,10);
});
test('different viewports, failed cleanup and same PCK cannot be presented as before/after',()=>{
 const original=batch('old',30),latest=batch('new',35);latest.method.viewport=[390,844];assert.throws(()=>compareCaptures(original,latest),/Viewport/);
 latest.method.viewport=[844,390];latest.cleanup=false;assert.throws(()=>compareCaptures(original,latest),/cleanup/);
 latest.cleanup=true;latest.pckSHA256='old';assert.throws(()=>compareCaptures(original,latest),/Distinct verified PCKs/);
});
test('missing or duplicate combinations are rejected instead of silently compared',()=>{
 const original=batch('old',30),latest=batch('new',35);latest.results.push(latest.results[0]);assert.throws(()=>compareCaptures(original,latest),/Duplicate/);
 latest.results=[];assert.throws(()=>compareCaptures(original,latest),/sets differ/);
});

test('missing RAF counters remain unknown and cannot become zero-millisecond deltas',()=>{
 const original=batch('old',30),latest=batch('new',null);assert.throws(()=>compareCaptures(original,latest),/Missing RAF/);
});

test('served network batches cannot be silently mixed with intercepted PCK controls',()=>{
 const original=batch('old',30),latest=batch('new',35);latest.method.assetDelivery='intercepted-local-pck';assert.throws(()=>compareCaptures(original,latest),/delivery modes differ/);
});
