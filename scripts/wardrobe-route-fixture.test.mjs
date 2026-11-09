import test from "node:test";
import assert from "node:assert/strict";
import { WORLD } from "../packages/shared/src/world.ts";
import { deriveWardrobeFixture } from "./wardrobe-route-fixture.mjs";

test("current dock booth provides two clear sides and a reachable actual dive ladder", () => {
  const before = JSON.stringify(WORLD);
  const fixture = deriveWardrobeFixture(WORLD);
  assert.deepEqual(fixture.daily, { x: 1360, y: 1290 });
  assert.deepEqual(fixture.curtain, { x: 1430, y: 1290 });
  assert.deepEqual(fixture.diving, { x: 1490, y: 1290 });
  assert.deepEqual(fixture.diveRoute.at(-1), [1485, 1330]);
  assert.equal(JSON.stringify(WORLD), before);
});

test("fixture rejects a missing booth and a newly obstructed crossing", () => {
  const absent = structuredClone(WORLD);
  absent.landMaps.hub.obstacles = absent.landMaps.hub.obstacles.filter(
    (entry) => entry.id !== "changing_post_north",
  );
  assert.throws(() => deriveWardrobeFixture(absent), /both authored supports/);
  const blocked = structuredClone(WORLD);
  blocked.landMaps.hub.obstacles.push({
    id: "fixture-crossing-blocker",
    kind: "crate",
    footprint: [
      [1410, 1260],
      [1450, 1260],
      [1450, 1320],
      [1410, 1320],
    ],
  });
  assert.throws(
    () => deriveWardrobeFixture(blocked),
    /clear dock floor|real booth opening/,
  );
});
