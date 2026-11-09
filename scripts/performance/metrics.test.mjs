import {test} from 'node:test';
import assert from 'node:assert/strict';
import {distribution,summarizeCapture,scalarMetrics} from './metrics.mjs';
test('nearest-rank percentiles retain real hitches, exclude invalid/missing counters',()=>{
 assert.deepEqual(distribution([16,17,18,19,250,NaN,-2,undefined]),{count:5,p50:18,p95:250,max:250});
 assert.deepEqual(distribution([]),{count:0,p50:null,p95:null,max:null});
});
test('scheduler intervals, sampled engine CPU, and unsupported metrics remain distinct',()=>{
 const result=summarizeCapture({durationMs:2000,frameIntervals:[16,17,51,101,251,1001],hiddenSamples:0,engineSamples:[{fps:30,processMs:8,drawCalls:100},{fps:29,processMs:9,drawCalls:101}]});
 assert.deepEqual(result.hitches,{over50Ms:4,over100Ms:3,over250Ms:2,over1000Ms:1});
 assert.equal(result.sampledGodot.processMs.p95,9);
 assert.equal(result.sampledGodot.physicsMs.p50,null);
 assert(result.unknown.godotNodes && result.unknown.gpuTime);
});
test('CDP DOM node count is separate browser memory metadata, absent values stay unknown',()=>{
 const result=scalarMetrics({metrics:[{name:'Nodes',value:20},{name:'JSHeapUsedSize',value:512}]});
 assert.equal(result.Nodes,20);assert.equal(result.JSHeapUsedSize,512);assert.equal(result.ScriptDuration,null);
});
