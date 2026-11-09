import test from "node:test";
import assert from "node:assert/strict";
import {
  FrameCapture,
  distribution,
  engineSample,
  buildReport,
} from "../../apps/web/src/performance-capture.ts";

test("frame capture excludes pauses and the first frame after resume, retaining visible hitches", () => {
  const frames = new FrameCapture();
  for (const [at, playing] of [
    [0, true],
    [16, true],
    [32, true],
    [1000, false],
    [2000, true],
    [2018, true],
    [2268, true],
  ])
    frames.frame(at, playing);
  assert.deepEqual(frames.summary().intervalsMs, {
    count: 4,
    p50: 16,
    p95: 250,
    max: 250,
  });
  assert.equal(frames.summary().hitches.over100Ms, 1);
  assert.equal(frames.summary().pausedCallbacks, 1);
  assert.equal(frames.summary().eligibleCallbacks, 6);
});
test("long capture retains a bounded interval window and explicitly counts discarded samples", () => {
  const frames = new FrameCapture();
  for (let i = 0; i <= 60002; i++) frames.frame(i * 8, true);
  const r = frames.summary();
  assert.equal(r.intervalsMs.count, 60000);
  assert.equal(r.droppedIntervals, 2);
  assert.equal(r.intervalsMs.p95, 8);
});
test("engine sample copies measured numeric fields and declared profiles, never game or account state", () => {
  const r = engineSample({
    fps: 60,
    processMs: 4.5,
    physicsMs: NaN,
    drawCalls: -1,
    renderObjects: 250,
    email: "private-player@test.invalid",
    token: "secret-test-token",
    inventory: [{ id: "private-item" }],
    coordinates: [12, 34],
    quality: {
      requested: "auto",
      effective: "low",
      email: "private-player@test.invalid",
    },
  });
  assert.deepEqual(r, {
    fps: 60,
    processMs: 4.5,
    renderObjects: 250,
    quality: { requested: "auto", effective: "low" },
  });
  assert.deepEqual(engineSample(null), {});
});
test("download report distinguishes scheduling and heap, excludes paused engine measurements and makes missing metrics explicit", () => {
  const f = new FrameCapture();
  f.frame(0, true);
  f.frame(20, true);
  const samples = [
    {
      elapsedMs: 1000,
      paused: false,
      values: engineSample({ fps: 50, processMs: 5 }),
      jsHeapUsedBytes: 1000,
    },
    {
      elapsedMs: 2000,
      paused: true,
      values: engineSample({ fps: 1, processMs: 900 }),
      jsHeapUsedBytes: 1200,
    },
  ];
  const report = buildReport(
    f,
    samples,
    {
      startedAt: "2026-11-09T00:00:00.000Z",
      durationMs: 30000,
      elapsedMs: 2000,
      reason: "user-stopped",
      quality: "auto",
    },
    {
      userAgent: "actual-browser",
      platform: "actual-platform",
      hardwareConcurrency: 4,
      deviceMemoryGiB: null,
      viewport: { width: 667, height: 375, devicePixelRatio: 2 },
      gpu: null,
      jsHeap: null,
    },
  );
  assert.equal(report.engine.fps.p50, 50);
  assert.equal(report.engine.processMs.max, 5);
  assert.equal(report.engine.drawCalls.p95, null);
  assert.equal(report.device.gpu, null);
  assert(report.definitions.frameScheduling.includes("not GPU"));
  assert(report.definitions.jsHeap.includes("not total process"));
  assert.equal(report.samples.length, 2);
  assert.equal(report.session.reason, "user-stopped");
});
test("distribution handles empty, invalid and finite percentile samples without manufacturing zero measurements", () => {
  assert.deepEqual(distribution([NaN, -1, Infinity]), {
    count: 0,
    p50: null,
    p95: null,
    max: null,
  });
  assert.deepEqual(distribution([100, 1, 2, 3, 4]), {
    count: 5,
    p50: 3,
    p95: 100,
    max: 100,
  });
});
