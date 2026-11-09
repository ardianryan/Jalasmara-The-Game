import { test } from "node:test";
import assert from "node:assert/strict";
import { WORLD } from "../packages/shared/src/world.ts";
import { deriveSarasFixture } from "./saras-alpha-fixture.mjs";

test("current Saras fixture uses real night rest and daytime work with separated legal viewpoints", () => {
  const before = JSON.stringify(WORLD);
  const night = deriveSarasFixture(WORLD);
  assert.equal(night.phase, "rest");
  assert.deepEqual(night.station, { x: 1020, y: 310 });
  assert.deepEqual(night.viewpoints, [{ x: 1070, y: 345 }, { x: 1050, y: 370 }]);
  const day = deriveSarasFixture(WORLD, 600);
  assert.equal(day.phase, "work");
  assert.deepEqual(day.station, { x: 1480, y: 680 });
  assert.equal(day.imageReviewRequired, true);
  assert.equal(day.historicalCauseEstablished, false);
  assert.equal(JSON.stringify(WORLD), before);
});
test("Saras fixture rejects arbitrary clock settings and substituted portrait provenance", () => {
  assert.throws(() => deriveSarasFixture(WORLD, 1110), /separate actual/);
  const world = structuredClone(WORLD);
  world.surface_hub.residents.find((entry) => entry.id === "npc_saras").appearance = 6;
  assert.throws(() => deriveSarasFixture(world), /existing Saras portrait/);
});
test("Saras fixture rejects obstructed viewpoints and proximity-stalled commute setup", () => {
  const obstructed = structuredClone(WORLD);
  obstructed.landMaps.hub.obstacles.push({ id: "fixture-only-block", x: 1060, y: 335, width: 20, height: 20, footprint: [[1060,335],[1080,335],[1080,355],[1060,355]], collision: true });
  assert.throws(() => deriveSarasFixture(obstructed), /body clearance/);
  const stalled = structuredClone(WORLD);
  stalled.surface_hub.residents.find((entry) => entry.id === "npc_saras").activity.commute.push([800, 1000]);
  assert.throws(() => deriveSarasFixture(stalled), /stall Saras/);
});
