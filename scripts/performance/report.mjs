import {readFileSync,writeFileSync} from 'node:fs';
const path=process.argv[2]??'artifacts/performance/06p-baseline/results.json';
const report=JSON.parse(readFileSync(path,'utf8'));
const value=n=>Number.isFinite(n)?n.toFixed(2):'unknown';
const lines=[`# Local browser baseline`, '', `Runtime: \`${report.runtimeBaseline}\`; PCK: \`${report.pckSHA256??'unverified'}\`.`, `Captured ${report.createdAt}. ${report.method.device}.`, '', '| Scene | Profile | RAF p50/p95 ms | >50ms | Godot CPU p50/p95 ms | Draw calls p50 | JS heap after MiB |', '|---|---|---|---:|---|---:|---:|'];
for(const row of report.results){const s=row.summary;lines.push(`| ${row.scenario} | ${row.profile} | ${value(s.rafIntervalsMs.p50)} / ${value(s.rafIntervalsMs.p95)} | ${s.hitches.over50Ms} | ${value(s.sampledGodot.processMs.p50)} / ${value(s.sampledGodot.processMs.p95)} | ${value(s.sampledGodot.drawCalls.p50)} | ${value(row.browserMemory.after.JSHeapUsedSize/1048576)} |`);}
lines.push('', 'RAF is browser callback spacing, not a GPU timer. Godot CPU counters are sampled snapshots, not per-frame traces. JS heap excludes WASM, GPU memory, and total process RSS. Godot node count is unavailable in this baseline. These are stationary scene samples with active world simulation, not walking-route or physical Windows/S23 measurements.', '', `Cleanup: ${report.cleanup}; browser errors: ${report.errors.length}.`);
writeFileSync(path.replace(/\.json$/,'.md'),lines.join('\n')+'\n');
