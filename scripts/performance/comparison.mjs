import assert from 'node:assert/strict';
const key=row=>`${row.scenario}/${row.profile}`;
export function compareCaptures(before,after) {
  assert.equal(after.method.assetDelivery??'served',before.method.assetDelivery??'served','PCK delivery modes differ');
  for(const field of ['device','diagnostics','sampleMs','warmupMs','motion','profileOrder'])assert.deepEqual(after.method[field],before.method[field],`Method mismatch: ${field}`);
  assert.deepEqual(after.method.viewport,before.method.viewport,'Viewport mismatch');
  assert(before.cleanup&&after.cleanup,'Both batches must finish isolated cleanup');
  assert.equal(before.errors.length+after.errors.length,0,'Browser errors invalidate clean comparison');
  assert(before.pckSHA256&&after.pckSHA256&&before.pckSHA256!==after.pckSHA256,'Distinct verified PCKs required for before/after');
  const original=new Map(before.results.map(row=>[key(row),row]));
  const latest=new Map(after.results.map(row=>[key(row),row]));
  assert.equal(original.size,before.results.length,'Duplicate before rows');
  assert.equal(latest.size,after.results.length,'Duplicate after rows');
  assert.deepEqual([...latest.keys()].sort(),[...original.keys()].sort(),'Scene/profile sets differ');
  return after.results.map(row=>{
    const previous=original.get(key(row));
    const first=previous.summary.rafIntervalsMs,next=row.summary.rafIntervalsMs;
    assert(Number.isFinite(first.p95)&&Number.isFinite(next.p95),'Missing RAF p95 counter');
    const delta=next.p95-first.p95,ratio=first.p95>0?next.p95/first.p95:null;
    return {scenario:row.scenario,profile:row.profile,before:{raf:first,hitches:previous.summary.hitches,godotProcessMs:previous.summary.sampledGodot.processMs,drawCalls:previous.summary.sampledGodot.drawCalls},after:{raf:next,hitches:row.summary.hitches,godotProcessMs:row.summary.sampledGodot.processMs,drawCalls:row.summary.sampledGodot.drawCalls},rafP95DeltaMs:delta,rafP95Ratio:ratio,rerunRecommended:ratio>1.5&&delta>10,interpretation:'Single batches; callback spacing is not GPU frame duration. Rerun flags are investigation prompts, not confirmed regressions.'};
  });
}
