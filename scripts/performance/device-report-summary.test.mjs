import test from "node:test";
import assert from "node:assert/strict";
import { readFileSync, writeFileSync, mkdtempSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { createHash } from "node:crypto";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";
import {
  MAX_REPORT_BYTES,
  readDeviceReport,
  summarizeDeviceReport,
  compareDeviceReports,
  runDeviceReportCli,
} from "./device-report-summary.mjs";
const actualFile = fileURLToPath(
  new URL("./fixtures/device-auto30-swiftshader-b34d.json", import.meta.url),
);
const actual = () => JSON.parse(readFileSync(actualFile, "utf8"));

// Explicit synthetic protocol/compatibility fixtures, never physical captures.
function synthetic(requested = "auto", effective = "low") {
  const report = actual();
  report.device = {
    userAgent: "Synthetic Test Browser",
    platform: "Synthetic",
    hardwareConcurrency: 4,
    deviceMemoryGiB: 4,
    viewport: { width: 844, height: 390, devicePixelRatio: 1 },
    gpu: { vendor: "Synthetic Test", renderer: "Synthetic Fixture GPU" },
  };
  report.session = {
    startedAt: "2000-01-01T00:00:00.000Z",
    durationMs: 30000,
    elapsedMs: 30000,
    reason: "duration-completed",
    quality: requested,
  };
  report.samples = Array.from({ length: 29 }, (_, i) => ({
    elapsedMs: (i + 1) * 1000,
    paused: i === 3 || i === 4,
    values: {
      fps: 40,
      processMs: 10,
      drawCalls: 200,
      quality: { requested, effective },
    },
    jsHeapUsedBytes: null,
  }));
  report.frameScheduling = {
    intervalsMs: { count: 100, p50: 16, p95: 20, max: 40 },
    hitches: { over50Ms: 0, over100Ms: 0, over250Ms: 0, over1000Ms: 0 },
    eligibleCallbacks: 103,
    pausedCallbacks: 2,
    droppedIntervals: 0,
  };
  return report;
}
const summarize = (report) => summarizeDeviceReport(report);

test("exact previous AUTO30 SwiftShader report remains byte-identical and is summarized without a physical claim", () => {
  const before = readFileSync(actualFile);
  assert.equal(before.length, 14494);
  assert.equal(
    createHash("sha256").update(before).digest("hex"),
    "d26f6036f2f5c4d6f40fd9cdd9ce3a4948138bfac7b7735fd3f8794b4ac38595",
  );
  const report = readDeviceReport(actualFile),
    summary = summarize(report);
  assert.equal(summary.hardware.softwareRenderer, "reported-software");
  assert.equal(summary.session.elapsedMs, 30104.5);
  assert.equal(summary.quality.configuredRequested, "auto");
  assert.equal(summary.quality.stableEffective, "low");
  assert.deepEqual(summary.coverage, {
    samples: 28,
    activeSamples: 25,
    pausedSamples: 3,
    expectedOneSecondSamples: 30,
    recordedFraction: 28 / 30,
    activeFractionOfExpected: 25 / 30,
  });
  assert.equal(summary.engine.fps.count, 25);
  assert.equal(summary.engine.fps.p50, report.engine.fps.p50);
  assert.equal(summary.provenance.status, "known-loader-pin");
  assert.equal(
    summary.provenance.identity.pckSha256,
    "b34d95211a61354eebf9cd218455d1c2f4e4b99723b57e4cfbe2b0a113f0ba26",
  );
  assert.deepEqual(readFileSync(actualFile), before);
});

test("synthetic Auto effective-low and manual Low are the same effective profile, without profile deltas", () => {
  const auto = synthetic(),
    low = synthetic("low", "low"),
    before = structuredClone(auto);
  const comparison = compareDeviceReports(summarize(auto), summarize(low));
  assert.equal(comparison.compatible, true);
  assert.equal(comparison.distinctEffectiveProfiles, false);
  assert.equal(comparison.descriptiveDifferences, null);
  assert.match(comparison.interpretation, /Not distinct effective profiles/);
  assert.deepEqual(auto, before);
});

test("synthetic distinct stable profiles produce only descriptive observations with explicit missing workload control", () => {
  const a = synthetic(),
    b = synthetic("balanced", "balanced");
  for (const s of b.samples) s.values.fps = 44;
  const result = compareDeviceReports(summarize(a), summarize(b));
  assert.equal(result.compatible, true);
  assert.equal(result.distinctEffectiveProfiles, true);
  assert.equal(result.descriptiveDifferences.engineFpsP50, 4);
  assert.match(result.interpretation, /not a causal FPS win or target pass/);
  assert(
    result.limitations.some((s) => s.includes("Scene, movement, thermal")),
  );
});

test("synthetic device, viewport, method, duration, reason or PCK changes withhold comparisons", () => {
  for (const mutate of [
    (r) => (r.device.hardwareConcurrency = 8),
    (r) => (r.device.viewport.width = 932),
    (r) => (r.device.viewport.devicePixelRatio = 2),
    (r) => (r.definitions.engine = "unknown-cadence"),
    (r) => (r.session.durationMs = 300000),
    (r) => (r.session.reason = "user-stopped"),
    (r) => {
      r.assetProvenance.start.pckSha256 = "f".repeat(64);
      r.assetProvenance.end.pckSha256 = "f".repeat(64);
    },
  ]) {
    const changed = synthetic("balanced", "balanced");
    mutate(changed);
    const c = compareDeviceReports(summarize(synthetic()), summarize(changed));
    assert.equal(c.compatible, false);
    assert.equal(c.descriptiveDifferences, null);
  }
});

test("older missing provenance stays unavailable; changed/incomplete/malformed provenance is never assigned the current pin", () => {
  for (const [mutate, status] of [
    [(r) => delete r.assetProvenance, "unavailable"],
    [(r) => (r.assetProvenance.end.pckSha256 = "f".repeat(64)), "changed"],
    [(r) => (r.assetProvenance.document = "changed"), "changed"],
    [(r) => (r.assetProvenance.end = null), "incomplete"],
    [
      (r) => (r.assetProvenance.start.verification = "whole-file-computed"),
      "incomplete",
    ],
  ]) {
    const report = synthetic();
    mutate(report);
    const s = summarize(report);
    assert.equal(s.provenance.status, status);
    assert.equal(s.provenance.identity, null);
    assert.equal(
      compareDeviceReports(s, summarize(synthetic())).compatible,
      false,
    );
  }
});

test("synthetic mixed/missing sampled quality and pause/coverage differences withhold a causal-looking comparison", () => {
  for (const mutate of [
    (r) => (r.samples[0].values.quality.effective = "balanced"),
    (r) => delete r.samples[0].values.quality,
    (r) => {
      for (let i = 0; i < 14; i++) r.samples[i].paused = true;
    },
    (r) => (r.samples = r.samples.slice(0, 5)),
    (r) => (r.frameScheduling.droppedIntervals = 2),
  ]) {
    const r = synthetic();
    mutate(r);
    const c = compareDeviceReports(summarize(synthetic()), summarize(r));
    assert.equal(c.compatible, false);
    assert.equal(c.descriptiveDifferences, null);
  }
});

test("summary allowlist excludes account/URL/coordinates and missing metrics remain null instead of zero", () => {
  const report = synthetic();
  report.account = "PRIVATE-ACCOUNT";
  report.device.email = "PRIVATE-EMAIL";
  report.samples[0].values.coordinates = [10, 20];
  report.samples[0].token = "PRIVATE-TOKEN";
  report.pageUrl = "https://private.invalid/secret";
  for (const s of report.samples) delete s.values.fps;
  const summary = summarize(report),
    serialized = JSON.stringify(summary);
  assert(!serialized.includes("PRIVATE-"));
  assert(!serialized.includes("private.invalid"));
  assert(!serialized.includes('"coordinates"'));
  assert.deepEqual(summary.engine.fps, {
    count: 0,
    p50: null,
    p95: null,
    max: null,
  });
  assert.equal(
    compareDeviceReports(summary, summarize(synthetic())).compatible,
    false,
  );
  report.device.gpu = null;
  assert.equal(summarize(report).hardware.softwareRenderer, "unknown");
});

test("malformed schema, nonfinite values, unordered samples and oversize sample arrays are rejected", () => {
  for (const mutate of [
    (r) => (r.kind = "other"),
    (r) => (r.schemaVersion = 2),
    (r) => (r.session.elapsedMs = Infinity),
    (r) => (r.device.viewport.width = -1),
    (r) => (r.samples[1].elapsedMs = r.samples[0].elapsedMs),
    (r) => (r.samples = Array(2001).fill(r.samples[0])),
  ]) {
    const r = synthetic();
    mutate(r);
    assert.throws(() => summarize(r));
  }
});

test("CLI is read-only and never echoes parser snippets, paths or malformed private values", () => {
  const directory = mkdtempSync(join(tmpdir(), "jalasmara-device-summary-"));
  try {
    const invalid = join(directory, "PRIVATE-FILENAME.json");
    writeFileSync(invalid, '{"kind": "PRIVATE-PARSER-SECRET", broken}');
    const huge = join(directory, "huge.json");
    writeFileSync(huge, Buffer.alloc(MAX_REPORT_BYTES + 1, 32));
    for (const file of [
      invalid,
      huge,
      join(directory, "absent.json"),
      "https://private.invalid/report.json",
      directory,
    ]) {
      let stdout = "",
        stderr = "";
      const code = runDeviceReportCli(
        [file],
        { write: (s) => (stdout += s) },
        { write: (s) => (stderr += s) },
      );
      assert.equal(code, 1);
      assert.equal(stdout, "");
      assert(!stderr.includes("PRIVATE-"));
      assert(!stderr.includes(directory));
      assert(!stderr.includes("private.invalid"));
      assert.match(stderr, /Unable to summarize/);
    }
    let stdout = "",
      stderr = "";
    assert.equal(
      runDeviceReportCli(
        [actualFile],
        { write: (s) => (stdout += s) },
        { write: (s) => (stderr += s) },
      ),
      0,
    );
    assert.equal(stderr, "");
    assert.equal(
      JSON.parse(stdout).reports[0].hardware.softwareRenderer,
      "reported-software",
    );
    assert.equal(
      createHash("sha256").update(readFileSync(actualFile)).digest("hex"),
      "d26f6036f2f5c4d6f40fd9cdd9ce3a4948138bfac7b7735fd3f8794b4ac38595",
    );
  } finally {
    rmSync(directory, { recursive: true, force: true });
  }
});

test(
  "a local FIFO is rejected without waiting for a writer",
  { skip: process.platform === "win32" },
  () => {
    const directory = mkdtempSync(join(tmpdir(), "jalasmara-device-pipe-"));
    try {
      const fifo = join(directory, "report-pipe");
      assert.equal(spawnSync("mkfifo", [fifo]).status, 0);
      const child = spawnSync(
        process.execPath,
        [
          fileURLToPath(
            new URL("./device-report-summary.mjs", import.meta.url),
          ),
          fifo,
        ],
        { timeout: 1000, encoding: "utf8" },
      );
      assert.equal(child.error, undefined);
      assert.equal(child.status, 1);
      assert.equal(JSON.parse(child.stderr).code, "LOCAL_FILE_REQUIRED");
      assert.equal(child.stdout, "");
      assert(!child.stderr.includes(fifo));
    } finally {
      rmSync(directory, { recursive: true, force: true });
    }
  },
);
