export const CAPTURE_DURATIONS = [30_000, 300_000] as const;
const MAX_INTERVALS = 60_000;
const METRICS = [
  "fps",
  "processMs",
  "physicsMs",
  "drawCalls",
  "renderObjects",
  "renderPrimitives",
  "pathQueue",
] as const;

function numeric(value: unknown): value is number {
  return typeof value === "number" && Number.isFinite(value) && value >= 0;
}

export function distribution(values: number[]) {
  const sorted = values.filter(numeric).sort((a, b) => a - b);
  const at = (fraction: number) =>
    sorted[Math.max(0, Math.ceil(sorted.length * fraction) - 1)] ?? null;
  return {
    count: sorted.length,
    p50: at(0.5),
    p95: at(0.95),
    max: sorted.at(-1) ?? null,
  };
}

export function assetIdentity(value: unknown) {
  if (!value || typeof value !== "object") return null;
  try {
    const source = value as Record<string, unknown>;
    const schemaVersion = source.schemaVersion;
    const verification = source.verification;
    const sha = source.pckSha256;
    const bytes = source.pckBytes;
    const parts = source.partCount;
    if (
      schemaVersion !== 1 ||
      verification !== "all-parts-verified-manifest" ||
      typeof sha !== "string" ||
      !/^[a-f0-9]{64}$/.test(sha) ||
      typeof bytes !== "number" ||
      !Number.isSafeInteger(bytes) ||
      bytes < 1 ||
      bytes > 512 * 1024 * 1024 ||
      parts !== Math.ceil(bytes / (1024 * 1024))
    )
      return null;
    return {
      schemaVersion: 1,
      pckSha256: sha,
      pckBytes: bytes,
      partCount: parts as number,
      verification: "all-parts-verified-manifest",
    };
  } catch {
    return null;
  }
}

export function assetProvenance(
  start: unknown,
  end: unknown,
  sameDocument?: boolean,
) {
  const first = assetIdentity(start);
  const last = assetIdentity(end);
  const status =
    sameDocument === false
      ? "changed-document"
      : !first && !last
        ? "unavailable"
        : !first || !last
          ? "incomplete"
          : first.pckSha256 !== last.pckSha256 ||
              first.pckBytes !== last.pckBytes
            ? "changed"
            : "unchanged-loader-pin";
  return {
    status,
    document:
      sameDocument === undefined
        ? "unobserved"
        : sameDocument
          ? "same"
          : "changed",
    start: first,
    end: last,
  };
}

export function engineSample(value: unknown) {
  if (!value || typeof value !== "object") return {};
  const source = value as Record<string, unknown>;
  const result: Record<string, number | Record<string, string>> = {};
  for (const key of METRICS)
    if (numeric(source[key])) result[key] = source[key];
  if (source.quality && typeof source.quality === "object") {
    const quality = source.quality as Record<string, unknown>;
    result.quality = Object.fromEntries(
      ["requested", "effective"]
        .filter((key) =>
          ["auto", "low", "balanced", "sharp"].includes(String(quality[key])),
        )
        .map((key) => [key, String(quality[key])]),
    );
  }
  return result;
}

export class FrameCapture {
  private previous: number | null = null;
  private intervals: number[] = [];
  private active = false;
  eligibleCallbacks = 0;
  pausedCallbacks = 0;
  droppedIntervals = 0;

  frame(timestamp: number, playing: boolean) {
    if (!numeric(timestamp)) return;
    if (playing) this.eligibleCallbacks++;
    else this.pausedCallbacks++;
    if (
      playing &&
      this.active &&
      this.previous !== null &&
      timestamp >= this.previous
    ) {
      if (this.intervals.length < MAX_INTERVALS)
        this.intervals.push(timestamp - this.previous);
      else this.droppedIntervals++;
    }
    this.previous = timestamp;
    this.active = playing;
  }

  summary() {
    return {
      intervalsMs: distribution(this.intervals),
      hitches: Object.fromEntries(
        [50, 100, 250, 1000].map((limit) => [
          `over${limit}Ms`,
          this.intervals.filter((value) => value > limit).length,
        ]),
      ),
      eligibleCallbacks: this.eligibleCallbacks,
      pausedCallbacks: this.pausedCallbacks,
      droppedIntervals: this.droppedIntervals,
    };
  }
}

function deviceMetadata(target: Window) {
  const navigator = target.navigator;
  const memory = target.performance as Performance & {
    memory?: {
      usedJSHeapSize: number;
      totalJSHeapSize: number;
      jsHeapSizeLimit: number;
    };
  };
  const hardware = navigator as Navigator & { deviceMemory?: number };
  const canvas = target.document.querySelector("canvas");
  let gpu: { vendor: string; renderer: string } | null = null;
  try {
    const context = canvas?.getContext("webgl2") ?? canvas?.getContext("webgl");
    const extension = context?.getExtension("WEBGL_debug_renderer_info");
    if (context && extension)
      gpu = {
        vendor: String(context.getParameter(extension.UNMASKED_VENDOR_WEBGL)),
        renderer: String(
          context.getParameter(extension.UNMASKED_RENDERER_WEBGL),
        ),
      };
  } catch {
    /* Browsers may restrict renderer identification. */
  }
  return {
    userAgent: navigator.userAgent,
    platform: navigator.platform,
    hardwareConcurrency: navigator.hardwareConcurrency,
    deviceMemoryGiB: hardware.deviceMemory ?? null,
    viewport: {
      width: target.innerWidth,
      height: target.innerHeight,
      devicePixelRatio: target.devicePixelRatio,
    },
    gpu,
    jsHeap: memory.memory
      ? {
          usedBytes: memory.memory.usedJSHeapSize,
          totalBytes: memory.memory.totalJSHeapSize,
          limitBytes: memory.memory.jsHeapSizeLimit,
        }
      : null,
  };
}

export type PerformanceReport = ReturnType<typeof buildReport>;

export function buildReport(
  frames: FrameCapture,
  samples: {
    elapsedMs: number;
    paused: boolean;
    values: ReturnType<typeof engineSample>;
    jsHeapUsedBytes: number | null;
  }[],
  session: {
    startedAt: string;
    durationMs: number;
    elapsedMs: number;
    reason: string;
    quality: string;
  },
  device: ReturnType<typeof deviceMetadata>,
  assets: { start: unknown; end: unknown; sameDocument?: boolean } = {
    start: null,
    end: null,
  },
) {
  return {
    schemaVersion: 1,
    kind: "jalasmara-device-performance",
    session,
    device,
    assetProvenance: assetProvenance(
      assets.start,
      assets.end,
      assets.sameDocument,
    ),
    frameScheduling: frames.summary(),
    engine: Object.fromEntries(
      METRICS.map((key) => [
        key,
        distribution(
          samples
            .filter((sample) => !sample.paused)
            .map((sample) => sample.values[key])
            .filter((value): value is number => typeof value === "number"),
        ),
      ]),
    ),
    samples,
    definitions: {
      frameScheduling:
        "Visible, unpaused iframe requestAnimationFrame intervals; a browser scheduling measure, not GPU frame duration.",
      engine:
        "Godot diagnostic monitor samples taken once per second. Menu/hidden samples are excluded from distributions.",
      jsHeap:
        "Optional browser JavaScript heap counters; not total process memory, WASM linear memory or GPU memory.",
      privacy:
        "No account, email, cookie, token, game inventory, world coordinates, API data or page URL is included. This file is generated locally and is not uploaded.",
      limitations:
        "GPU time, VRAM and WASM memory are not measured. Hardware strings are reported by this browser and may identify a software renderer or be unavailable.",
      assetProvenance:
        "Allowlisted identity from this iframe loader after each PCK part passed SHA-256 and reached its consumer. The whole-file hash is the manifest declaration, not a new whole-file digest, proof of Godot READY or a runtime attestation. Older loaders report unavailable. No manifest or API request is made by this recorder.",
    },
  };
}

export function recordPerformance(
  frame: HTMLIFrameElement,
  options: {
    durationMs: (typeof CAPTURE_DURATIONS)[number];
    quality: string;
    paused: () => boolean;
    complete: (report: PerformanceReport) => void;
  },
) {
  const target = frame.contentWindow;
  if (!target) throw new Error("Game frame is not ready");
  if (!CAPTURE_DURATIONS.includes(options.durationMs))
    throw new Error("Unsupported capture duration");
  const start = performance.now();
  const startedAt = new Date().toISOString();
  const device = deviceMetadata(target);
  const originalDocument = target.document;
  const readIdentity = () => {
    try {
      return assetIdentity(
        (target as Window & { jalasmaraPckIdentity?: unknown })
          .jalasmaraPckIdentity,
      );
    } catch {
      return null;
    }
  };
  const sameDocument = () => {
    try {
      return target.document === originalDocument;
    } catch {
      return false;
    }
  };
  const startIdentity = readIdentity();
  const frames = new FrameCapture();
  const samples: Parameters<typeof buildReport>[1] = [];
  const cancelFrame = target.cancelAnimationFrame.bind(target);
  let request = 0,
    stopped = false;
  const paused = () =>
    !sameDocument() ||
    document.hidden ||
    originalDocument.hidden ||
    options.paused();
  const tick = (timestamp: number) => {
    if (stopped) return;
    if (!frame.isConnected || !sameDocument()) {
      stop("game-frame-replaced");
      return;
    }
    frames.frame(timestamp, !paused());
    request = target.requestAnimationFrame(tick);
  };
  request = target.requestAnimationFrame(tick);
  const sample = window.setInterval(() => {
    if (!frame.isConnected || !sameDocument()) {
      stop("game-frame-replaced");
      return;
    }
    const source = target as Window & {
      jalasmaraPerformance?: unknown;
      jalasmaraSnapshot?: { performance?: unknown };
    };
    const memory = target.performance as Performance & {
      memory?: { usedJSHeapSize: number };
    };
    samples.push({
      elapsedMs: performance.now() - start,
      paused: paused(),
      values: engineSample(
        source.jalasmaraPerformance ?? source.jalasmaraSnapshot?.performance,
      ),
      jsHeapUsedBytes: memory.memory?.usedJSHeapSize ?? null,
    });
  }, 1000);
  const deadline = window.setTimeout(
    () => stop("duration-completed"),
    options.durationMs,
  );
  function cancel() {
    stopped = true;
    clearInterval(sample);
    clearTimeout(deadline);
    try {
      cancelFrame(request);
    } catch {
      // A replaced document may revoke access to its original animation handle.
    }
  }
  function stop(reason = "user-stopped") {
    if (stopped) return;
    cancel();
    options.complete(
      buildReport(
        frames,
        samples,
        {
          startedAt,
          durationMs: options.durationMs,
          elapsedMs: performance.now() - start,
          reason,
          quality: options.quality,
        },
        device,
        {
          start: startIdentity,
          end: readIdentity(),
          sameDocument: sameDocument(),
        },
      ),
    );
  }
  return { stop, cancel };
}

export function downloadPerformance(report: PerformanceReport) {
  const url = URL.createObjectURL(
    new Blob([JSON.stringify(report, null, 2)], { type: "application/json" }),
  );
  const link = document.createElement("a");
  link.href = url;
  link.download = `jalasmara-performa-${report.session.startedAt.replace(/[:.]/g, "-")}.json`;
  document.body.append(link);
  link.click();
  link.remove();
  setTimeout(() => URL.revokeObjectURL(url), 1000);
}
