import test from "node:test";
import assert from "node:assert/strict";
import {
  assetIdentity,
  recordPerformance,
} from "../../apps/web/src/performance-capture.ts";

const pin = () => ({
  schemaVersion: 1,
  pckSha256: "a".repeat(64),
  pckBytes: 1048593,
  partCount: 2,
  verification: "all-parts-verified-manifest",
});

function fixture() {
  const names = ["window", "document", "clearInterval", "clearTimeout"];
  const previous = Object.fromEntries(
    names.map((name) => [
      name,
      Object.getOwnPropertyDescriptor(globalThis, name),
    ]),
  );
  const initialDocument = { hidden: false, querySelector: () => null };
  let document = initialDocument,
    crossOrigin = false,
    nextFrame = 0,
    foreignMetricReads = 0;
  const rafs = new Map(),
    intervals = new Map(),
    deadlines = new Map(),
    cleared = [];
  const reports = [];
  const target = {
    navigator: {
      userAgent: "CPU-recorder-fixture",
      platform: "CPU-fixture",
      hardwareConcurrency: 1,
    },
    innerWidth: 844,
    innerHeight: 390,
    devicePixelRatio: 1,
    get document() {
      if (crossOrigin)
        throw new DOMException(
          "fixture document inaccessible",
          "SecurityError",
        );
      return document;
    },
    get performance() {
      if (crossOrigin)
        throw new DOMException(
          "fixture performance inaccessible",
          "SecurityError",
        );
      return {};
    },
    get jalasmaraPckIdentity() {
      if (crossOrigin)
        throw new DOMException(
          "fixture identity inaccessible",
          "SecurityError",
        );
      return pin();
    },
    get jalasmaraPerformance() {
      if (document !== initialDocument) foreignMetricReads++;
      return { fps: 123 };
    },
    requestAnimationFrame(callback) {
      rafs.set(++nextFrame, callback);
      return nextFrame;
    },
    get cancelAnimationFrame() {
      if (crossOrigin)
        throw new DOMException("fixture cancel inaccessible", "SecurityError");
      return (request) => rafs.delete(request);
    },
  };
  const define = (name, value) =>
    Object.defineProperty(globalThis, name, {
      value,
      writable: true,
      configurable: true,
    });
  define("document", { hidden: false });
  define("window", {
    setInterval(callback) {
      intervals.set(101, callback);
      return 101;
    },
    setTimeout(callback) {
      deadlines.set(202, callback);
      return 202;
    },
  });
  define("clearInterval", (id) => {
    cleared.push(["interval", id]);
    intervals.delete(id);
  });
  define("clearTimeout", (id) => {
    cleared.push(["timeout", id]);
    deadlines.delete(id);
  });
  const capture = recordPerformance(
    { contentWindow: target, isConnected: true },
    {
      durationMs: 30000,
      quality: "low",
      paused: () => false,
      complete: (report) => reports.push(report),
    },
  );
  return {
    capture,
    reports,
    rafs,
    intervals,
    deadlines,
    cleared,
    replaceDocument(cross = false) {
      document = { hidden: false, querySelector: () => null };
      crossOrigin = cross;
    },
    foreignMetricReads: () => foreignMetricReads,
    restore() {
      try {
        capture.cancel();
      } catch {
        /* A failing implementation must not leak the test globals. */
      }
      for (const name of names) {
        if (previous[name])
          Object.defineProperty(globalThis, name, previous[name]);
        else delete globalThis[name];
      }
    },
  };
}

test("identity snapshots an unstable getter exactly once before validation and copying", () => {
  let reads = 0;
  const source = {
    ...pin(),
    get pckSha256() {
      return ++reads < 3 ? "a".repeat(64) : "UNVALIDATED-THIRD-READ";
    },
    url: "fixture-extra-not-allowed",
  };
  const identity = assetIdentity(source);
  assert.equal(reads, 1);
  assert.deepEqual(identity, pin());
  source.pckBytes = 1;
  assert.equal(identity.pckBytes, 1048593);
  assert(!JSON.stringify(identity).includes("fixture-extra"));
});

test("identity treats throwing access and malformed primitive metadata as unavailable", () => {
  assert.equal(
    assetIdentity(
      new Proxy(
        {},
        {
          get() {
            throw new Error("fixture getter rejected");
          },
        },
      ),
    ),
    null,
  );
  for (const changes of [
    { pckSha256: "not-a-hash" },
    { pckBytes: NaN },
    { partCount: 1 },
    { verification: "whole-file-computed" },
  ])
    assert.equal(assetIdentity({ ...pin(), ...changes }), null);
});

test("cross-origin document replacement cannot prevent report completion or timer cleanup", () => {
  const f = fixture();
  try {
    f.replaceDocument(true);
    assert.doesNotThrow(() => f.capture.stop());
    assert.equal(f.reports.length, 1);
    assert.equal(f.reports[0].assetProvenance.status, "changed-document");
    assert.equal(f.reports[0].assetProvenance.end, null);
    assert.equal(f.intervals.size, 0);
    assert.equal(f.deadlines.size, 0);
    assert.deepEqual(f.cleared, [
      ["interval", 101],
      ["timeout", 202],
    ]);
    f.capture.stop();
    assert.equal(f.reports.length, 1);
  } finally {
    f.restore();
  }
});

for (const callback of ["sample", "raf"])
  test(`same-origin new document stops ${callback} before mixing metrics or frames`, () => {
    const f = fixture();
    try {
      const invoke =
        callback === "sample" ? f.intervals.get(101) : f.rafs.get(1);
      f.replaceDocument();
      invoke(100);
      assert.equal(f.reports.length, 1);
      assert.equal(f.reports[0].session.reason, "game-frame-replaced");
      assert.equal(f.reports[0].assetProvenance.status, "changed-document");
      assert.equal(f.reports[0].samples.length, 0);
      assert.equal(f.reports[0].frameScheduling.eligibleCallbacks, 0);
      assert.equal(f.foreignMetricReads(), 0);
      assert.equal(f.intervals.size, 0);
      assert.equal(f.deadlines.size, 0);
      invoke(200);
      assert.equal(f.reports.length, 1);
    } finally {
      f.restore();
    }
  });
