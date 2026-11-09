import test from "node:test";
import assert from "node:assert/strict";
import { WORLD } from "../packages/shared/src/world.ts";
import { blockedByContours } from "../apps/api/src/geometry.ts";
import { oceanRoute } from "./live-parent-navigation.mjs";

test("live-parent route goes around real reef contours and hazards without exceeding storyday2 depth", () => {
  let from = WORLD.spawn;
  let samples = 0;
  for (const to of [{ x: 2720, y: 1200 }, { x: 2720, y: 1325 }, WORLD.spawn]) {
    const route = oceanRoute(WORLD, from, to);
    assert.deepEqual(route.at(-1), [to.x, to.y]);
    for (const [x, y] of route) {
      const steps = Math.ceil(Math.hypot(x - from.x, y - from.y) / 2);
      for (let i = 0; i <= steps; i++) {
        const point = {
          x: from.x + ((x - from.x) * i) / steps,
          y: from.y + ((y - from.y) * i) / steps,
        };
        assert(
          !blockedByContours(point, WORLD.terrainContours, 12),
          "Independent dense samples must satisfy the actual server contour margin",
        );
        assert(point.y >= WORLD.surface && point.y <= 2080);
        for (const hazard of WORLD.hazards)
          assert(
            Math.hypot(point.x - hazard.x, point.y - hazard.y) >
              hazard.radius + 20,
          );
        samples++;
      }
      from = { x, y };
    }
  }
  assert(samples > 1800);
});
test("live-parent route rejects targets inside an actual reef rather than teleporting across it", () => {
  assert.throws(
    () => oceanRoute(WORLD, WORLD.spawn, { x: 1900, y: 860 }),
    /target must be clear/,
  );
});
