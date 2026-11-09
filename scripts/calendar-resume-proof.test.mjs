import assert from "node:assert/strict";
import test from "node:test";
import { calendarResumeProof } from "./calendar-resume-proof.mjs";

const first = {
  status: 200,
  focused: true,
  paused: false,
  writer: true,
  at: 20000,
  serverNow: 20000,
  calendarDay: 1,
  minuteOfDay: 600,
  calendarRevision: 4,
  dayLengthMs: 2160000,
};
const later = {
  ...first,
  at: 25000,
  serverNow: 25000,
  minuteOfDay: 603.3333333333334,
  calendarRevision: 5,
};

test("actual heartbeat protocol proves lease recovery only after active authoritative time advances", () => {
  assert.equal(calendarResumeProof([{ ...first, writer: false }, first]), null);
  assert.equal(
    calendarResumeProof([first, { ...later, minuteOfDay: first.minuteOfDay }]),
    null,
  );
  const proof = calendarResumeProof([
    { ...first, writer: false },
    first,
    later,
  ]);
  assert.equal(proof.writerObservedAt, 20000);
  assert.equal(proof.advancingObservedAt, 25000);
  assert(Math.abs(proof.activeElapsedMs - 5000) < 1e-6);
});

test("paused/unfocused/non-writer or unchanged revisions cannot substitute for active time", () => {
  for (const changed of [
    { paused: true },
    { focused: false },
    { writer: false },
    { status: 409 },
    { calendarRevision: 4 },
    { dayLengthMs: 3600000 },
  ])
    assert.equal(calendarResumeProof([first, { ...later, ...changed }]), null);
});

test("proof handles real calendar-day rollover and rejects invalid response geometry", () => {
  const proof = calendarResumeProof([
    { ...first, minuteOfDay: 1439 },
    { ...later, calendarDay: 2, minuteOfDay: 2.3333333333333335 },
  ]);
  assert(Math.abs(proof.activeElapsedMs - 5000) < 1e-6);
  for (const changed of [
    { calendarDay: 0 },
    { minuteOfDay: 1440 },
    { dayLengthMs: 0 },
    { serverNow: undefined },
  ])
    assert.equal(calendarResumeProof([first, { ...later, ...changed }]), null);
});
