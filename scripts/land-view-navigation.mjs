import assert from "node:assert/strict";

const controls = [
  { keys: ["d"], input: [1, 0] },
  { keys: ["d", "s"], input: [Math.SQRT1_2, Math.SQRT1_2] },
  { keys: ["s"], input: [0, 1] },
  { keys: ["a", "s"], input: [-Math.SQRT1_2, Math.SQRT1_2] },
  { keys: ["a"], input: [-1, 0] },
  { keys: ["a", "w"], input: [-Math.SQRT1_2, -Math.SQRT1_2] },
  { keys: ["w"], input: [0, -1] },
  { keys: ["d", "w"], input: [Math.SQRT1_2, -Math.SQRT1_2] },
];
const length = (v) => Math.hypot(...v);
const dot = (a, b) => a[0] * b[0] + a[1] * b[1];
const cross = (a, b) => a[0] * b[1] - a[1] * b[0];
const unit = (v) => (length(v) ? v.map((value) => value / length(v)) : [0, 0]);

function matrix(contract) {
  assert.equal(
    contract?.schemaVersion,
    1,
    "The actual renderer motion contract is required; camera mode must not be guessed from the route",
  );
  const columns = contract.columns;
  assert(
    columns?.length === 2 &&
      columns.every((v) => v.length === 2 && v.every(Number.isFinite)),
  );
  const determinant = cross(columns[0], columns[1]);
  assert(
    Math.abs(determinant) > 1e-6,
    "Projected ground plane must have an invertible motion contract",
  );
  return { columns, determinant };
}
export function logicalMotionFromKeys(screenInput, contract) {
  const { columns, determinant } = matrix(contract);
  assert(screenInput.length === 2 && screenInput.every(Number.isFinite));
  const raw = [
    cross(screenInput, columns[1]) / determinant,
    cross(columns[0], screenInput) / determinant,
  ];
  return unit(raw).map((value) => value * Math.min(1, length(screenInput)));
}
export function projectLogicalDelta(logicalDelta, contract) {
  const { columns } = matrix(contract);
  assert(logicalDelta.length === 2 && logicalDelta.every(Number.isFinite));
  return [
    columns[0][0] * logicalDelta[0] + columns[1][0] * logicalDelta[1],
    columns[0][1] * logicalDelta[0] + columns[1][1] * logicalDelta[1],
  ];
}
export function keyboardForLogicalDelta(logicalDelta, contract) {
  matrix(contract);
  const direction = unit(logicalDelta);
  if (length(logicalDelta) < 1e-6)
    return {
      keys: [],
      input: [0, 0],
      logicalInput: [0, 0],
      alignment: 1,
      crossTrack: 0,
    };
  const candidates = controls.map((control) => {
    const logicalInput = logicalMotionFromKeys(control.input, contract);
    return {
      ...control,
      logicalInput,
      alignment: dot(logicalInput, direction),
      crossTrack: cross(direction, logicalInput),
    };
  });
  return candidates.sort((a, b) => b.alignment - a.alignment)[0];
}
export function keyboardPulse(
  logicalDelta,
  contract,
  { speed = 100, acceleration = 850, maxCrossTrack = 3, maxHoldMs = 330 } = {},
) {
  assert(
    [speed, acceleration, maxCrossTrack, maxHoldMs].every(
      (value) => Number.isFinite(value) && value > 0,
    ),
  );
  const control = keyboardForLogicalDelta(logicalDelta, contract);
  if (!control.keys.length)
    return { ...control, holdMs: 0, releaseMs: 0, nominalDistance: 0 };
  const allowedDistance = Math.min(
    length(logicalDelta) * 0.7,
    (maxCrossTrack * 0.7) / Math.max(1e-9, Math.abs(control.crossTrack)),
    (speed * maxHoldMs) / 1000,
  );
  const holdSeconds =
    allowedDistance <= (speed * speed) / acceleration
      ? Math.sqrt(allowedDistance / acceleration)
      : allowedDistance / speed;
  const holdMs = Math.min(maxHoldMs, holdSeconds * 1000);
  const nominalDistance = Math.min(
    acceleration * (holdMs / 1000) ** 2,
    (speed * holdMs) / 1000,
  );
  // Release until the existing minimum deceleration can stop a full-speed player.
  return {
    ...control,
    holdMs,
    releaseMs: Math.ceil((speed / acceleration) * 1000) + 25,
    nominalDistance,
  };
}

export function corridorTargets(from, to, maxSpacing = 24) {
  assert(
    [from, to].every(
      (point) =>
        Array.isArray(point) &&
        point.length === 2 &&
        point.every(Number.isFinite),
    ),
  );
  assert(Number.isFinite(maxSpacing) && maxSpacing > 0);
  const delta = [to[0] - from[0], to[1] - from[1]];
  const steps = Math.max(1, Math.ceil(length(delta) / maxSpacing));
  assert(
    Number.isSafeInteger(steps) && steps <= 10000,
    "Bounded corridor subdivision required",
  );
  return Array.from({ length: steps }, (_, index) =>
    from.map((value, axis) => value + (delta[axis] * (index + 1)) / steps),
  );
}
