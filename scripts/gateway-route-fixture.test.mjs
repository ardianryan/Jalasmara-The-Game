import assert from "node:assert/strict";
import test from "node:test";
import { WORLD } from "../packages/shared/src/world.ts";
import {
  isLandSegmentWalkable,
  isLandWalkable,
} from "../packages/shared/src/land.ts";
import {
  validateGatewayRoute,
  deriveGatewayPostProbe,
  gatewayCoordinates,
  gatewayPostClearance,
  validateGatewayMeshes,
} from "./gateway-route-fixture.mjs";
const world = WORLD;
for (const area of ["hub", "forest"]) {
  const from =
    area === "hub" ? { x: 2295, y: 210 } : world.landMaps.forest.spawn;
  test(`${area} gate route crosses the actual plane both ways with body clearance`, () => {
    const result = validateGatewayRoute(world, area, from);
    let previous = from;
    for (const [x, y] of result.approach) {
      assert(isLandSegmentWalkable(world.landMaps[area], previous, { x, y }));
      previous = { x, y };
    }
    assert(gatewayCoordinates(result.gate, result.before).along < -35.9);
    assert(gatewayCoordinates(result.gate, result.after).along > 35.9);
    assert(
      isLandSegmentWalkable(
        world.landMaps[area],
        result.before,
        result.after,
        13,
      ),
    );
    assert(
      isLandSegmentWalkable(
        world.landMaps[area],
        result.after,
        result.before,
        13,
      ),
    );
  });
  test(`${area} post probe starts on reachable clear floor and aims inside the authoritative collider`, () => {
    const { gate, after } = validateGatewayRoute(world, area, from);
    for (const index of [0, 1]) {
      const probe = deriveGatewayPostProbe(world, area, gate, after, index);
      assert(isLandWalkable(world.landMaps[area], probe.approach, 13));
      assert(!isLandWalkable(world.landMaps[area], probe.target, 0));
      assert(gatewayPostClearance(gate, index, probe.approach) >= 13);
      let previous = after;
      for (const [x, y] of probe.route) {
        assert(isLandSegmentWalkable(world.landMaps[area], previous, { x, y }));
        previous = { x, y };
      }
      assert.throws(
        () => gatewayPostClearance(gate, index, probe.target),
        /entered the real/,
      );
    }
  });
}
test("gateway fixtures reject missing metadata and swapped crossing sides", () => {
  const missing = structuredClone(world);
  delete missing.landMaps.hub.gateways;
  assert.throws(
    () => validateGatewayRoute(missing, "hub", { x: 2295, y: 210 }),
    /Actual gateway/,
  );
  const swapped = structuredClone(world);
  swapped.landMaps.hub.gateways[0].crossing.reverse();
  assert.throws(() =>
    validateGatewayRoute(swapped, "hub", { x: 2295, y: 210 }),
  );
});

test("metadata alone is not accepted as evidence of emitted gate geometry", () => {
  const gate = world.landMaps.hub.gateways[0];
  assert.throws(
    () => validateGatewayMeshes(gate, { ...gate, meshes: [] }),
    /Actual emitted/,
  );
});
