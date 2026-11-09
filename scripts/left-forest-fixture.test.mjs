import assert from "node:assert/strict";
import test from "node:test";
import { WORLD } from "../packages/shared/src/world.ts";
import {
  isLandWalkable,
  isLandSegmentWalkable,
} from "../packages/shared/src/land.ts";
import { deriveLeftForestFixture } from "./left-forest-fixture.mjs";

test("current shared route derives a legal clear approach and complete upper-bridge crossing", () => {
  const before = JSON.stringify(WORLD);
  const fixture = deriveLeftForestFixture(WORLD);
  assert.deepEqual(fixture.point, { x: 1200, y: 730 });
  assert.equal(fixture.layoutVersion, WORLD.landMaps.forest.layoutVersion);
  assert.equal(fixture.joystickClearance, 55);
  let current = fixture.point;
  for (const [x, y] of [...fixture.route, fixture.bridgePath[1]]) {
    assert(isLandWalkable(WORLD.landMaps.forest, { x, y }, 12));
    assert(isLandSegmentWalkable(WORLD.landMaps.forest, current, { x, y }));
    current = { x, y };
  }
  assert.deepEqual(current, { x: 1600, y: 640 });
  assert.equal(JSON.stringify(WORLD), before);
});

test("setup rejects a blocked actual bridge instead of loosening crossing or teleporting", () => {
  const world = structuredClone(WORLD);
  world.landMaps.forest.obstacles.push({
    id: "fixture_blocked_bridge",
    kind: "rock",
    x: 1435,
    y: 585,
    width: 30,
    height: 140,
    footprint: [
      [1435, 585],
      [1465, 585],
      [1465, 725],
      [1435, 725],
    ],
  });
  assert.throws(
    () => deriveLeftForestFixture(world),
    /crossing must remain physically walkable/,
  );
});

test("setup rejects missing authored approach clearance and malformed bridge metadata", () => {
  const blocked = structuredClone(WORLD);
  blocked.landMaps.forest.obstacles.push({
    id: "fixture_blocked_approach",
    kind: "rock",
    x: 1100,
    y: 680,
    width: 140,
    height: 120,
    footprint: [
      [1100, 680],
      [1240, 680],
      [1240, 800],
      [1100, 800],
    ],
  });
  assert.throws(
    () => deriveLeftForestFixture(blocked),
    /approach has joystick clearance/,
  );
  const malformed = structuredClone(WORLD);
  malformed.landMaps.forest.bridges
    .find((entry) => entry.id === "bridge_upper")
    .path.pop();
  assert.throws(
    () => deriveLeftForestFixture(malformed),
    /two authored endpoints/,
  );
});
