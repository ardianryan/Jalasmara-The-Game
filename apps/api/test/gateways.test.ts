import { test } from "node:test";
import assert from "node:assert/strict";
import { createLandGateway, type GatewaySpec } from "../../../packages/shared/src/gateways.js";
import { LAND_MAPS, isLandWalkable, isLandSegmentWalkable, type LandObstacle } from "../../../packages/shared/src/land.js";

const physical = ([x, y]: readonly number[]) => [x, -y / Math.cos(55 * Math.PI / 180)];
const close = (a: number, b: number, epsilon = 1e-7) => assert.ok(Math.abs(a - b) < epsilon, `${a} != ${b}`);
const forestRoad = LAND_MAPS.forest.surfaces.find((surface) => surface.id === "forest_trail_0_1")!;
const forestSpec: GatewaySpec = {
  id: "forest_entry_gate", label: "ForestEntryGate", elevation: 0,
  route: { segment: [[85, 1378], [200, 1320]], fraction: .65 },
  roadSurfaceId: forestRoad.id, roadPolygon: forestRoad.polygon,
  colliderIds: ["forest_entry_gate_post_0", "forest_entry_gate_post_1"],
};
const hubSpec: GatewaySpec = {
  id: "hub_forest_gate", label: "HubForestGate", elevation: 3,
  route: { segment: [[2295, 230], [2295, 125]], fraction: 95 / 105 },
  roadSurfaceId: "hub_ridge_trail_3",
  roadPolygon: [[2269, 230], [2321, 230], [2321, 125], [2269, 125]],
  colliderIds: ["forest_gate_west", "forest_gate_east"], halfSpan: 42.5,
};

test("forest gateway derives physical perpendicular and post footprints from the actual painted trail", () => {
  const gate = createLandGateway(forestSpec);
  close(gate.center[0], 159.75);
  close(gate.center[1], 1340.3);
  close(gate.halfSpan, 89.99161004207626);
  close(gate.right[0] * gate.forward[0] + gate.right[1] * gate.forward[1], 0);
  close(gate.right[0] * gate.forward[1] - gate.right[1] * gate.forward[0], 1);
  const [a, b] = gate.postCenters.map(physical);
  close(Math.hypot(a[0] - b[0], a[1] - b[1]), 2 * gate.halfSpan);
  const [start, end] = forestSpec.route.segment.map(physical);
  close((b[0] - a[0]) * (end[0] - start[0]) + (b[1] - a[1]) * (end[1] - start[1]), 0);
  for (const footprint of gate.postFootprints) {
    const points = footprint.map(physical);
    for (let index = 0; index < 4; index++) {
      const next = points[(index + 1) % 4];
      close(Math.hypot(next[0] - points[index][0], next[1] - points[index][1]), 18);
      assert.ok(isLandWalkable(LAND_MAPS.forest, { x: footprint[index][0], y: footprint[index][1] }, 0), "each base corner stays on actual forest floor");
    }
  }
  close(-gate.halfSpan + gate.baseSize[0] / 2 + gate.edgeClearance, gate.roadSection[0], .002);
  close(gate.halfSpan - gate.baseSize[0] / 2 - gate.edgeClearance, gate.roadSection[1]);
  // A normal in map pixels is visibly different after the y/cos55 embedding.
  const logicalNormal = physical([58, 115]);
  assert.ok(Math.abs(logicalNormal[0] * gate.forward[0] + logicalNormal[1] * gate.forward[1]) > 80);
});

test("forest physical bases block their footprints while the real radius13 gate crossing stays legal", () => {
  const gate = createLandGateway(forestSpec);
  const posts: LandObstacle[] = gate.postFootprints.map((footprint, index) => {
    const xs = footprint.map((point) => point[0]), ys = footprint.map((point) => point[1]);
    return { id: gate.colliderIds[index], kind: "fence", variant: "gateway_post", x: Math.min(...xs), y: Math.min(...ys), width: Math.max(...xs) - Math.min(...xs), height: Math.max(...ys) - Math.min(...ys), height3d: 118, elevation: 0, footprint };
  });
  const originalObstacles = JSON.stringify(LAND_MAPS.forest.obstacles);
  const map = { ...LAND_MAPS.forest, obstacles: [...LAND_MAPS.forest.obstacles.filter((obstacle) => !gate.colliderIds.includes(obstacle.id)), ...posts] };
  for (const [x, y] of gate.postCenters) assert.equal(isLandWalkable(map, { x, y }, 0), false);
  const [before, after] = gate.crossing.map(([x, y]) => ({ x, y }));
  assert.ok(isLandSegmentWalkable(map, before, after, 13));
  assert.ok(isLandSegmentWalkable(map, after, LAND_MAPS.forest.spawn, 13));
  assert.equal(JSON.stringify(LAND_MAPS.forest.obstacles), originalObstacles, "fixture never mutates source map");
});

test("hub fixed posts retain side fence centers and require the recentered52px terminal paint", () => {
  const gate = createLandGateway(hubSpec);
  assert.deepEqual(gate.center, [2295, 135]);
  assert.deepEqual(gate.postCenters, [[2252.5, 135], [2337.5, 135]]);
  for (let index = 0; index < 2; index++) {
    const collider = LAND_MAPS.hub.obstacles.find((obstacle) => obstacle.id === gate.colliderIds[index])!;
    close(gate.postCenters[index][0], collider.x + collider.width / 2);
    close(gate.postCenters[index][1], collider.y + collider.height / 2);
  }
  assert.deepEqual(gate.roadSection, [-26, 26]);
  assert.ok(isLandSegmentWalkable(LAND_MAPS.hub, ...gate.crossing.map(([x, y]) => ({ x, y })) as [{ x: number; y: number }, { x: number; y: number }], 13));
  // f7a3b96 hub_ridge_trail_4: legacy92px paint centered at2282.
  const oldTerminal = [[2328, 249.22], [2236, 200.78], [2236, 82], [2328, 82]] as const;
  assert.throws(() => createLandGateway({ ...hubSpec, roadPolygon: oldTerminal }), /intrude into the road/);
});

test("gate factory rejects degenerate routes, off-road origins and insufficient base clearance", () => {
  assert.throws(() => createLandGateway({ ...forestSpec, route: { segment: [[1, 1], [1, 1]], fraction: .5 } }), /no length/);
  assert.throws(() => createLandGateway({ ...forestSpec, route: { ...forestSpec.route, fraction: NaN } }), /Invalid/);
  assert.throws(() => createLandGateway({ ...forestSpec, route: { segment: [[85, 1700], [200, 1700]], fraction: .65 } }), /inside/);
  assert.throws(() => createLandGateway({ ...forestSpec, halfSpan: 80 }), /intrude/);
  assert.throws(() => createLandGateway({ ...forestSpec, baseSize: [-1, 18] }), /Invalid/);
});
