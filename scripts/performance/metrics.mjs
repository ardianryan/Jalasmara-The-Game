export function distribution(values) {
  const samples = values.filter(Number.isFinite).filter(value => value >= 0).sort((a,b)=>a-b);
  if (!samples.length) return {count:0,p50:null,p95:null,max:null};
  const percentile = p => samples[Math.max(0,Math.ceil(p*samples.length)-1)];
  return {count:samples.length,p50:percentile(.5),p95:percentile(.95),max:samples.at(-1)};
}

export function summarizeCapture(capture) {
  const intervals = capture.frameIntervals;
  const metrics = ['fps','processMs','physicsMs','drawCalls','renderObjects','renderPrimitives','pathQueue'];
  const sampledGodot = Object.fromEntries(metrics.map(key=>[key,distribution(capture.engineSamples.map(value=>value[key]))]));
  return {
    intervalDefinition:'Visible iframe requestAnimationFrame callback intervals; scheduling proxy, not GPU frame duration',
    durationMs:capture.durationMs,
    rafIntervalsMs:distribution(intervals),
    hitches:Object.fromEntries([50,100,250,1000].map(limit=>[`over${limit}Ms`,intervals.filter(value=>value>limit).length])),
    hiddenSamples:capture.hiddenSamples,
    sampledGodot,
    unknown:{godotNodes:'Not exposed by the served baseline diagnostic bridge',wasmLinearMemory:'Not exposed by public engine bridge',gpuTime:'No GPU timer-query instrumentation',gpuMemory:'Not exposed by the served baseline',physicalWindowsS23:'No physical device measured'},
  };
}

export function scalarMetrics(metrics) {
  const values = Object.fromEntries(metrics.metrics.map(value=>[value.name,value.value]));
  return Object.fromEntries(['JSHeapUsedSize','JSHeapTotalSize','Nodes','Documents','LayoutCount','TaskDuration','ScriptDuration'].map(key=>[key,values[key]??null]));
}
