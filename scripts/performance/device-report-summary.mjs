#!/usr/bin/env node
import { openSync, fstatSync, readSync, closeSync, constants } from "node:fs";
import { pathToFileURL } from "node:url";
import { resolve } from "node:path";

export const MAX_REPORT_BYTES = 4 * 1024 * 1024;
const MAX_SAMPLES = 2000;
const metrics = [
  "fps",
  "processMs",
  "physicsMs",
  "drawCalls",
  "renderObjects",
  "renderPrimitives",
  "pathQueue",
];
const profiles = ["auto", "low", "balanced"];
const methods = {
  frameScheduling:
    "Visible, unpaused iframe requestAnimationFrame intervals; a browser scheduling measure, not GPU frame duration.",
  engine:
    "Godot diagnostic monitor samples taken once per second. Menu/hidden samples are excluded from distributions.",
};
const limitations = [
  "Browser-reported metadata is not a physical-device identity or runtime attestation.",
  "RAF intervals measure browser scheduling, not GPU frame duration. No performance target is graded.",
  "Scene, movement, thermal state and other applications are not recorded; comparisons are descriptive, not causal improvements.",
];
class ReportError extends Error {
  constructor(code = "INVALID_REPORT") {
    super("Unsupported or invalid local performance report.");
    this.code = code;
  }
}
const object = (value) =>
  value !== null && typeof value === "object" && !Array.isArray(value);
const number = (value) =>
  typeof value === "number" && Number.isFinite(value) && value >= 0;
const count = (value) => Number.isSafeInteger(value) && value >= 0;
function requireValue(condition) {
  if (!condition) throw new ReportError();
}
const text = (value, max) =>
  typeof value === "string" && value.length > 0 && value.length <= max
    ? value
    : null;
const profile = (value) => (profiles.includes(value) ? value : null);
const same = (a, b) => JSON.stringify(a) === JSON.stringify(b);

export function readDeviceReport(filename) {
  if (typeof filename !== "string" || /^[a-z]+:\/\//i.test(filename))
    throw new ReportError("LOCAL_FILE_REQUIRED");
  let fd;
  try {
    fd = openSync(filename, constants.O_RDONLY | (constants.O_NONBLOCK ?? 0));
    const stat = fstatSync(fd);
    if (!stat.isFile()) throw new ReportError("LOCAL_FILE_REQUIRED");
    if (stat.size > MAX_REPORT_BYTES) throw new ReportError("REPORT_TOO_LARGE");
    const buffer = Buffer.alloc(MAX_REPORT_BYTES + 1);
    let size = 0,
      loaded;
    do {
      loaded = readSync(fd, buffer, size, buffer.length - size, null);
      size += loaded;
      if (size > MAX_REPORT_BYTES) throw new ReportError("REPORT_TOO_LARGE");
    } while (loaded > 0);
    try {
      return JSON.parse(buffer.subarray(0, size).toString("utf8"));
    } catch {
      throw new ReportError("INVALID_JSON");
    }
  } catch (error) {
    if (error instanceof ReportError) throw error;
    throw new ReportError("FILE_READ_FAILED");
  } finally {
    if (fd !== undefined) closeSync(fd);
  }
}

function distribution(values) {
  const sorted = values.filter(number).sort((a, b) => a - b);
  const at = (fraction) =>
    sorted[Math.max(0, Math.ceil(sorted.length * fraction) - 1)] ?? null;
  return {
    count: sorted.length,
    p50: at(0.5),
    p95: at(0.95),
    max: sorted.at(-1) ?? null,
  };
}
function reportedDistribution(value) {
  if (!object(value) || !count(value.count) || value.count > 60000) return null;
  if (value.count === 0)
    return [value.p50, value.p95, value.max].every((x) => x === null)
      ? { count: 0, p50: null, p95: null, max: null }
      : null;
  if (
    ![value.p50, value.p95, value.max].every(number) ||
    value.p50 > value.p95 ||
    value.p95 > value.max
  )
    return null;
  return { count: value.count, p50: value.p50, p95: value.p95, max: value.max };
}
function identity(value) {
  if (
    !object(value) ||
    value.schemaVersion !== 1 ||
    value.verification !== "all-parts-verified-manifest" ||
    !/^[a-f0-9]{64}$/.test(value.pckSha256 ?? "") ||
    !Number.isSafeInteger(value.pckBytes) ||
    value.pckBytes < 1 ||
    value.pckBytes > 512 * 1048576 ||
    value.partCount !== Math.ceil(value.pckBytes / 1048576)
  )
    return null;
  return {
    pckSha256: value.pckSha256,
    pckBytes: value.pckBytes,
    partCount: value.partCount,
    verification: "all-parts-verified-manifest",
  };
}
export function summarizeProvenance(value) {
  if (value === undefined) return { status: "unavailable", identity: null };
  if (!object(value)) return { status: "invalid", identity: null };
  const start = identity(value.start),
    end = identity(value.end);
  if (
    value.status === "changed-document" ||
    value.document === "changed" ||
    value.status === "changed" ||
    (start && end && !same(start, end))
  )
    return { status: "changed", identity: null };
  if (!start && !end)
    return {
      status:
        value.start == null && value.end == null ? "unavailable" : "invalid",
      identity: null,
    };
  if (
    !start ||
    !end ||
    value.document !== "same" ||
    value.status !== "unchanged-loader-pin"
  )
    return { status: "incomplete", identity: null };
  return { status: "known-loader-pin", identity: start };
}
function hardware(value) {
  const gpu = object(value.gpu)
    ? {
        vendor: text(value.gpu.vendor, 256),
        renderer: text(value.gpu.renderer, 512),
      }
    : null;
  const renderer = gpu?.renderer;
  return {
    userAgent: text(value.userAgent, 1024),
    platform: text(value.platform, 128),
    hardwareConcurrency:
      Number.isSafeInteger(value.hardwareConcurrency) &&
      value.hardwareConcurrency > 0 &&
      value.hardwareConcurrency <= 4096
        ? value.hardwareConcurrency
        : null,
    deviceMemoryGiB:
      number(value.deviceMemoryGiB) &&
      value.deviceMemoryGiB > 0 &&
      value.deviceMemoryGiB <= 65536
        ? value.deviceMemoryGiB
        : null,
    gpu,
    softwareRenderer:
      renderer === null || renderer === undefined
        ? "unknown"
        : /swiftshader|llvmpipe|softpipe|software rasterizer|microsoft basic render|warp\b/i.test(
              renderer,
            )
          ? "reported-software"
          : "not-detected-not-physical-proof",
  };
}
export function summarizeDeviceReport(report) {
  requireValue(
    object(report) &&
      report.kind === "jalasmara-device-performance" &&
      report.schemaVersion === 1,
  );
  const session = report.session,
    device = report.device,
    frames = report.frameScheduling;
  requireValue(object(session) && object(device) && object(frames));
  requireValue(
    [30000, 300000].includes(session.durationMs) &&
      number(session.elapsedMs) &&
      session.elapsedMs > 0 &&
      session.elapsedMs <= 86400000,
  );
  requireValue(
    ["duration-completed", "user-stopped", "game-frame-replaced"].includes(
      session.reason,
    ),
  );
  requireValue(
    Array.isArray(report.samples) && report.samples.length <= MAX_SAMPLES,
  );
  const viewport = device.viewport;
  requireValue(
    object(viewport) &&
      [viewport.width, viewport.height].every(
        (v) => Number.isSafeInteger(v) && v > 0 && v <= 32768,
      ) &&
      number(viewport.devicePixelRatio) &&
      viewport.devicePixelRatio > 0 &&
      viewport.devicePixelRatio <= 16,
  );
  let previous = -1;
  for (const sample of report.samples) {
    requireValue(
      object(sample) &&
        typeof sample.paused === "boolean" &&
        number(sample.elapsedMs) &&
        sample.elapsedMs > previous &&
        sample.elapsedMs <= session.elapsedMs + 1000 &&
        object(sample.values),
    );
    previous = sample.elapsedMs;
  }
  const active = report.samples.filter((s) => !s.paused),
    quality = new Map();
  let missingQuality = 0;
  for (const sample of active) {
    const requested = profile(sample.values.quality?.requested),
      effective = profile(sample.values.quality?.effective);
    if (!requested || !["low", "balanced"].includes(effective)) {
      missingQuality++;
      continue;
    }
    const key = requested + "/" + effective;
    const row = quality.get(key) ?? { requested, effective, samples: 0 };
    row.samples++;
    quality.set(key, row);
  }
  const rows = [...quality.values()].sort((a, b) =>
    (a.requested + a.effective).localeCompare(b.requested + b.effective),
  );
  const requested = [...new Set(rows.map((r) => r.requested))],
    effective = [...new Set(rows.map((r) => r.effective))];
  const expectedSamples = Math.floor(session.elapsedMs / 1000);
  const knownMethod =
    object(report.definitions) &&
    Object.entries(methods).every(
      ([key, value]) => report.definitions[key] === value,
    );
  const hitches = Object.fromEntries(
    ["over50Ms", "over100Ms", "over250Ms", "over1000Ms"].map((key) => [
      key,
      count(frames.hitches?.[key]) ? frames.hitches[key] : null,
    ]),
  );
  return {
    schemaVersion: 1,
    kind: "jalasmara-device-report-summary",
    method: knownMethod ? "schema1-iframe-raf-and-active-godot-1s" : "unknown",
    hardware: hardware(device),
    viewport: {
      width: viewport.width,
      height: viewport.height,
      devicePixelRatio: viewport.devicePixelRatio,
    },
    session: {
      configuredDurationMs: session.durationMs,
      elapsedMs: session.elapsedMs,
      reason: session.reason,
    },
    quality: {
      configuredRequested: profile(session.quality),
      activeSampled: rows,
      missingActiveSamples: missingQuality,
      stableEffective:
        missingQuality === 0 && effective.length === 1 ? effective[0] : null,
      stableRequested:
        missingQuality === 0 && requested.length === 1 ? requested[0] : null,
    },
    coverage: {
      samples: report.samples.length,
      activeSamples: active.length,
      pausedSamples: report.samples.length - active.length,
      expectedOneSecondSamples: expectedSamples,
      recordedFraction:
        expectedSamples > 0 ? report.samples.length / expectedSamples : null,
      activeFractionOfExpected:
        expectedSamples > 0 ? active.length / expectedSamples : null,
    },
    raf: {
      intervalsMs: reportedDistribution(frames.intervalsMs),
      hitches,
      eligibleCallbacks: count(frames.eligibleCallbacks)
        ? frames.eligibleCallbacks
        : null,
      pausedCallbacks: count(frames.pausedCallbacks)
        ? frames.pausedCallbacks
        : null,
      droppedIntervals: count(frames.droppedIntervals)
        ? frames.droppedIntervals
        : null,
    },
    engine: Object.fromEntries(
      metrics.map((key) => [
        key,
        distribution(active.map((s) => s.values[key])),
      ]),
    ),
    provenance: summarizeProvenance(report.assetProvenance),
    limitations: [...limitations],
  };
}

export function compareDeviceReports(first, second) {
  const reasons = [];
  if (first.method === "unknown" || first.method !== second.method)
    reasons.push("unknown-or-different-measurement-method");
  const completeHardware = (s) =>
    s.hardware.userAgent &&
    s.hardware.platform &&
    s.hardware.hardwareConcurrency &&
    s.hardware.gpu?.vendor &&
    s.hardware.gpu?.renderer;
  if (!completeHardware(first) || !completeHardware(second))
    reasons.push("incomplete-browser-reported-device-metadata");
  else if (!same(first.hardware, second.hardware))
    reasons.push("different-browser-reported-device-metadata");
  if (!same(first.viewport, second.viewport))
    reasons.push("different-viewport-or-device-pixel-ratio");
  if (
    first.session.configuredDurationMs !==
      second.session.configuredDurationMs ||
    first.session.reason !== second.session.reason ||
    first.session.reason === "game-frame-replaced"
  )
    reasons.push("different-or-interrupted-capture-duration-method");
  const tolerance = Math.max(
    500,
    Math.min(first.session.elapsedMs, second.session.elapsedMs) * 0.05,
  );
  if (Math.abs(first.session.elapsedMs - second.session.elapsedMs) > tolerance)
    reasons.push("different-actual-capture-window");
  for (const s of [first, second]) {
    if ((s.raf.droppedIntervals ?? 0) > 0)
      reasons.push("truncated-raf-interval-window");
    if ((s.coverage.recordedFraction ?? 0) > 1.1)
      reasons.push("sample-cadence-inconsistent-with-recorded-method");
    if (
      s.session.reason === "duration-completed" &&
      (s.session.elapsedMs < s.session.configuredDurationMs ||
        s.session.elapsedMs > s.session.configuredDurationMs * 1.05)
    )
      reasons.push("automatic-deadline-drift");
    if (
      (s.coverage.recordedFraction ?? 0) < 0.8 ||
      (s.coverage.activeFractionOfExpected ?? 0) < 0.7 ||
      !s.engine.fps.count ||
      !s.raf.intervalsMs?.count
    )
      reasons.push("insufficient-active-or-recorded-sample-coverage");
    if (
      !s.quality.stableEffective ||
      !s.quality.stableRequested ||
      s.quality.stableRequested !== s.quality.configuredRequested
    )
      reasons.push("mixed-missing-or-changed-quality-profile");
  }
  if (
    Math.abs(
      (first.coverage.activeFractionOfExpected ?? 0) -
        (second.coverage.activeFractionOfExpected ?? 0),
    ) > 0.1
  )
    reasons.push("different-active-sample-coverage");
  if (
    first.provenance.status !== "known-loader-pin" ||
    second.provenance.status !== "known-loader-pin"
  )
    reasons.push("unknown-incomplete-or-changed-pck-provenance");
  else if (!same(first.provenance.identity, second.provenance.identity))
    reasons.push("different-pck-loader-pins");
  const compatible = reasons.length === 0;
  const distinct =
    compatible &&
    first.quality.stableEffective !== second.quality.stableEffective;
  const delta = (a, b) => (number(a) && number(b) ? b - a : null);
  return {
    compatible,
    reasons: [...new Set(reasons)],
    distinctEffectiveProfiles: compatible ? distinct : null,
    interpretation: !compatible
      ? "Comparison withheld: recording metadata or active coverage is incompatible."
      : !distinct
        ? "Not distinct effective profiles: different setting names selected the same effective renderer profile. No profile delta is calculated."
        : "Compatible metadata only. Differences below are descriptive observations, not a causal FPS win or target pass.",
    descriptiveDifferences: distinct
      ? {
          rafP95IntervalMs: delta(
            first.raf.intervalsMs?.p95,
            second.raf.intervalsMs?.p95,
          ),
          engineFpsP50: delta(first.engine.fps.p50, second.engine.fps.p50),
          godotProcessP95Ms: delta(
            first.engine.processMs.p95,
            second.engine.processMs.p95,
          ),
        }
      : null,
    limitations: [
      ...limitations,
      "Coverage checks use once-per-second sample counts, not exact paused wall time: recorded>=80%, active>=70%, active-coverage difference<=10 percentage points; actual durations must agree within5% or500ms.",
    ],
  };
}

export function runDeviceReportCli(
  args,
  output = process.stdout,
  error = process.stderr,
) {
  if (args.length === 1 && args[0] === "--help") {
    output.write(
      "Usage: node scripts/performance/device-report-summary.mjs report.json [second-report.json]\n",
    );
    return 0;
  }
  if (args.length < 1 || args.length > 2) {
    error.write("Expected one or two local report JSON files. Use --help.\n");
    return 1;
  }
  try {
    const reports = args.map((file) =>
      summarizeDeviceReport(readDeviceReport(file)),
    );
    output.write(
      JSON.stringify(
        {
          reports,
          ...(reports.length === 2
            ? { comparison: compareDeviceReports(...reports) }
            : {}),
        },
        null,
        2,
      ) + "\n",
    );
    return 0;
  } catch (failure) {
    // Never print native JSON.parse/FS errors: they can include input contents or paths.
    error.write(
      JSON.stringify({
        error: "Unable to summarize a supported local performance report.",
        code: failure instanceof ReportError ? failure.code : "INVALID_REPORT",
      }) + "\n",
    );
    return 1;
  }
}
if (
  process.argv[1] &&
  pathToFileURL(resolve(process.argv[1])).href === import.meta.url
)
  process.exitCode = runDeviceReportCli(process.argv.slice(2));
