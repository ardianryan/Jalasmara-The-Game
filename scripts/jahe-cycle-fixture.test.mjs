import assert from "node:assert/strict";
import test from "node:test";
import { WORLD } from "../packages/shared/src/world.ts";
import { HOMESTEAD_DEFINITIONS } from "../packages/shared/src/index.ts";
import { isLandSegmentWalkable } from "../packages/shared/src/land.ts";
import { deriveJaheCycleFixture } from "./jahe-cycle-fixture.mjs";

test("actual jahe setup derives clear garden/bed/Wira routes without changing the world", () => {
  const original = JSON.stringify(WORLD);
  const setup = deriveJaheCycleFixture(WORLD);
  assert.deepEqual(setup.bedApproach, { x: 270, y: 330 });
  assert.equal(setup.crop.growthDays, 4);
  assert.equal(setup.crop.yield, 3);
  for (const [name, from, map] of [
    ["plotToDoor", setup.plot.interaction, WORLD.landMaps.hub],
    ["entryToBed", WORLD.homestead.interior.entry, WORLD.homestead.interior],
    ["doorToWira", WORLD.homestead.door, WORLD.landMaps.hub],
  ]) {
    let previous = from;
    for (const [x, y] of setup.routes[name]) {
      assert(isLandSegmentWalkable(map, previous, { x, y }));
      previous = { x, y };
    }
  }
  assert.equal(JSON.stringify(WORLD), original);
});

test("setup refuses changed crop requirements and an unreachable authored bed", () => {
  const definitions = structuredClone(HOMESTEAD_DEFINITIONS);
  definitions.crops.find((crop) => crop.id === "jahe").growthDays = 3;
  assert.throws(() => deriveJaheCycleFixture(WORLD, definitions), /four-day/);
  const world = structuredClone(WORLD);
  world.homestead.interior.routes = [
    [
      [480, 580],
      [480, 420],
    ],
  ];
  assert.throws(() => deriveJaheCycleFixture(world), /legal authored approach/);
});
