import test from "node:test";
import assert from "node:assert/strict";
import {
  keyboardForLogicalDelta,
  keyboardPulse,
  corridorTargets,
  logicalMotionFromKeys,
  projectLogicalDelta,
} from "./land-view-navigation.mjs";

const legacy = {
  schemaVersion: 1,
  columns: [
    [1, 0],
    [0, 1],
  ],
};
// A renderer contract is the source of truth; this consumer never reconstructs camera angles.
const quarter = {
  schemaVersion: 1,
  columns: [
    [0.7071067811865476, -0.3535533905932737],
    [1.232803051821635, 0.6164015259108174],
  ],
};
const directions = [
  [1, 0],
  [1, 1],
  [0, 1],
  [-1, 1],
  [-1, 0],
  [-1, -1],
  [0, -1],
  [1, -1],
];

test("legacy matrix preserves eight physical keyboard directions", () => {
  const expected = [
    ["d"],
    ["d", "s"],
    ["s"],
    ["a", "s"],
    ["a"],
    ["a", "w"],
    ["w"],
    ["d", "w"],
  ];
  directions.forEach((delta, index) =>
    assert.deepEqual(
      keyboardForLogicalDelta(delta, legacy).keys,
      expected[index],
    ),
  );
});
test("left-view routes select screen keys through the actual matrix", () => {
  assert.deepEqual(keyboardForLogicalDelta([1, 0], quarter).keys, ["d", "w"]);
  assert.deepEqual(keyboardForLogicalDelta([0, 1], quarter).keys, ["d", "s"]);
  assert.deepEqual(keyboardForLogicalDelta([0, -1], quarter).keys, ["a", "w"]);
  for (const strength of [0.25, 1, 2]) {
    const logical = logicalMotionFromKeys([strength, 0], quarter);
    assert(Math.abs(Math.hypot(...logical) - Math.min(strength, 1)) < 1e-12);
    const screen = projectLogicalDelta(logical, quarter);
    assert(screen[0] > 0 && Math.abs(screen[1]) < 1e-12);
  }
});
test("bounded pulses limit predicted lateral drift and release the player", () => {
  for (const contract of [legacy, quarter])
    for (const delta of directions) {
      const pulse = keyboardPulse(
        delta.map((value) => value * 120),
        contract,
      );
      assert(pulse.holdMs > 0 && pulse.holdMs <= 330);
      assert(pulse.releaseMs >= 143);
      assert(pulse.nominalDistance * Math.abs(pulse.crossTrack) <= 2.1 + 1e-9);
      assert(pulse.alignment > 0);
    }
  assert.equal(keyboardPulse([0, 0], quarter).holdMs, 0);
});
test("navigation refuses missing, stale or singular view contracts", () => {
  for (const contract of [
    undefined,
    { schemaVersion: 0, columns: legacy.columns },
    {
      schemaVersion: 1,
      columns: [
        [1, 0],
        [2, 0],
      ],
    },
  ])
    assert.throws(() => keyboardForLogicalDelta([1, 0], contract));
});

test("Tedi's 520-unit approach stays in its authored corridor with eight-key input", () => {
  const actual = {
    schemaVersion: 1,
    columns: [
      [0.707106828689575, -0.405579805374146],
      [1.23280310630798, 0.707106828689575],
    ],
  };
  const from = [1120, 1000],
    to = [600, 950];
  const distance = Math.hypot(to[0] - from[0], to[1] - from[1]);
  function simulate(targets) {
    let position = [...from],
      maxCrossTrack = 0,
      pulses = 0;
    const visited = [];
    for (const target of targets)
      while (
        Math.hypot(target[0] - position[0], target[1] - position[1]) >= 5
      ) {
        assert(
          ++pulses <= 1000,
          "Controller must make bounded forward progress",
        );
        const pulse = keyboardPulse(
          [target[0] - position[0], target[1] - position[1]],
          actual,
        );
        position = position.map(
          (value, axis) =>
            value + pulse.logicalInput[axis] * pulse.nominalDistance,
        );
        visited.push([...position]);
        const deviation =
          Math.abs(
            (to[0] - from[0]) * (position[1] - from[1]) -
              (to[1] - from[1]) * (position[0] - from[0]),
          ) / distance;
        maxCrossTrack = Math.max(maxCrossTrack, deviation);
      }
    return { position, maxCrossTrack, visited };
  }
  // The layout-9 porch post that the original real-browser route hit, with body clearance.
  const post = [
    1016.251840848291, 1014.9653970290715, 1026.251840848291,
    1024.9653970290715,
  ];
  const hitsPost = ([x, y]) =>
    Math.hypot(
      Math.max(post[0] - x, 0, x - post[2]),
      Math.max(post[1] - y, 0, y - post[3]),
    ) < 12;
  const old = simulate([to]);
  assert(
    old.maxCrossTrack > 30 && old.visited.some(hitsPost),
    "The regression must reproduce the failed greedy route",
  );
  const targets = corridorTargets(from, to);
  const fixed = simulate(targets);
  assert(
    fixed.maxCrossTrack < 4,
    "Cumulative lateral drift must stay inside the support clearance budget",
  );
  assert(!fixed.visited.some(hitsPost));
  assert(Math.hypot(fixed.position[0] - to[0], fixed.position[1] - to[1]) < 5);
  for (let index = 0; index < targets.length; index++) {
    const previous = index ? targets[index - 1] : from;
    assert(
      Math.hypot(
        targets[index][0] - previous[0],
        targets[index][1] - previous[1],
      ) <=
        24 + 1e-9,
    );
  }
  assert.deepEqual(targets.at(-1), to);
  for (const spacing of [0, -1, Infinity])
    assert.throws(() => corridorTargets(from, to, spacing));
});
