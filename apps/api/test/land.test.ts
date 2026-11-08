import { test } from "node:test";
import assert from "node:assert/strict";
import {
  LAND_MAPS,
  isLandWalkable,
  isLandSegmentWalkable,
  mapFootMaterial,
  nearestSafeLandPoint,
  landDistanceToSegment,
  landPointInPolygon,
} from "../../../packages/shared/src/land.js";

test("modular land rejects roofs, gardens, rocks, trunks and shoreline with the same 12px body clearance", () => {
  let samples = 0;
  for (const map of Object.values(LAND_MAPS))
    for (const obstacle of map.obstacles) {
      assert.equal(
        isLandWalkable(map, {
          x: obstacle.x + obstacle.width / 2,
          y: obstacle.y + obstacle.height / 2,
        }),
        false,
        obstacle.id,
      );
      for (let i = 0; i <= 20; i++) {
        const t = i / 20;
        for (let edge = 0; edge < obstacle.footprint.length; edge++) {
          const a = obstacle.footprint[edge],
            b = obstacle.footprint[(edge + 1) % obstacle.footprint.length];
          const dx = b[0] - a[0],
            dy = b[1] - a[1],
            length = Math.hypot(dx, dy);
          const point = {
            x: a[0] + dx * t + (dy / length) * 6,
            y: a[1] + dy * t - (dx / length) * 6,
          };
          assert.equal(
            isLandWalkable(map, point),
            false,
            `${map.id}/${obstacle.id}/${JSON.stringify(point)}`,
          );
          samples++;
        }
      }
    }
  assert.ok(samples > 2000);
  assert.ok(
    isLandWalkable(LAND_MAPS.hub, { x: 370, y: 430 }),
    "A freed oblique-house corner must not retain an invisible rectangular wall",
  );
  for (const point of [
    { x: 840, y: 1300 },
    { x: 1560, y: 1330 },
    { x: 1485, y: 1410 },
    { x: 50, y: 1490 },
  ])
    assert.equal(isLandWalkable(LAND_MAPS.hub, point), false);
});

test("all authored routes, NPCs, landmarks, spawn, dive point and portal remain connected on explicit floor geometry", () => {
  let samples = 0;
  for (const map of Object.values(LAND_MAPS)) {
    assert.ok(isLandWalkable(map, map.spawn));
    for (const route of map.routes)
      for (let i = 1; i < route.length; i++) {
        assert.ok(
          isLandSegmentWalkable(
            map,
            { x: route[i - 1][0], y: route[i - 1][1] },
            { x: route[i][0], y: route[i][1] },
          ),
          `${map.id}/${JSON.stringify(route[i])}`,
        );
        samples += Math.ceil(
          Math.hypot(
            route[i][0] - route[i - 1][0],
            route[i][1] - route[i - 1][1],
          ) / 6,
        );
      }
  }
  for (const [x, y] of [
    [595, 650],
    [1350, 635],
    [1720, 520],
    [1950, 300],
    [1485, 1330],
    [2295, 125],
  ])
    assert.ok(isLandWalkable(LAND_MAPS.hub, { x, y }), `hub POI${x}/${y}`);
  for (const [x, y] of [
    [650, 1050],
    [1200, 730],
    [1830, 470],
    [2130, 1050],
  ])
    assert.ok(isLandWalkable(LAND_MAPS.forest, { x, y }));
  assert.ok(samples > 1000);
});

test("terrace edges cannot be climbed outside authored stairs and a river cannot be filled by a decorative dirt overlay", () => {
  const hub = LAND_MAPS.hub,
    forest = LAND_MAPS.forest;
  assert.ok(isLandWalkable(hub, { x: 1370, y: 775 }));
  assert.ok(isLandWalkable(hub, { x: 600, y: 775 }));
  assert.equal(isLandWalkable(hub, { x: 900, y: 775 }), false);
  assert.equal(
    isLandSegmentWalkable(hub, { x: 900, y: 700 }, { x: 900, y: 850 }),
    false,
  );
  assert.ok(
    isLandSegmentWalkable(hub, { x: 1370, y: 700 }, { x: 1370, y: 850 }),
  );
  assert.equal(mapFootMaterial(hub, { x: 1370, y: 775 }), "stone");
  assert.equal(mapFootMaterial(hub, hub.spawn), "dock");
  assert.equal(isLandWalkable(forest, { x: 1450, y: 450 }), false);
  assert.ok(
    isLandSegmentWalkable(forest, { x: 1280, y: 710 }, { x: 1620, y: 620 }),
  );
  const fake = {
    ...forest,
    surfaces: [
      ...forest.surfaces,
      {
        id: "decorative_false_bridge",
        polygon: [
          [1400, 200],
          [1500, 200],
          [1500, 500],
          [1400, 500],
        ] as const,
        material: "dirt" as const,
        elevation: 0,
        walkable: false,
      },
    ],
  };
  assert.equal(
    isLandWalkable(fake as typeof forest, { x: 1450, y: 400 }),
    false,
  );
});

test("free exploration reaches broad forest ground away from routes and migrations preserve safe coordinates", () => {
  const point = { x: 300, y: 700 };
  assert.ok(isLandWalkable(LAND_MAPS.forest, point));
  const routeDistance = Math.min(
    ...LAND_MAPS.forest.routes.flatMap((route) =>
      route
        .slice(1)
        .map((end, i) => landDistanceToSegment(point, route[i], end)),
    ),
  );
  assert.ok(routeDistance > 250);
  for (const map of Object.values(LAND_MAPS)) {
    assert.deepEqual(nearestSafeLandPoint(map, map.spawn), map.spawn);
    const before = JSON.stringify(map),
      safe = nearestSafeLandPoint(map, { x: 1450, y: 450 });
    assert.ok(isLandWalkable(map, safe));
    assert.equal(JSON.stringify(map), before);
  }
});

test("coastal backing remains visual-only and twenty-five canopy trees preserve route and bridge clearance", () => {
  const hub = LAND_MAPS.hub,
    forest = LAND_MAPS.forest;
  assert.ok(hub.landmass && hub.landmass.length > 12);
  assert.ok(landPointInPolygon({ x: 900, y: 775 }, hub.landmass));
  assert.equal(
    isLandWalkable(hub, { x: 900, y: 775 }),
    false,
    "Earth behind a terrace wall must not become a climbable floor",
  );
  const additions = forest.obstacles.filter((o) =>
    o.id.startsWith("forest_canopy_tree_"),
  );
  assert.equal(additions.length, 25);
  for (const tree of additions) {
    const point = { x: tree.x + tree.width / 2, y: tree.y + tree.height / 2 };
    assert.equal(
      isLandWalkable(forest, point),
      false,
      "Visible canopy trees need physical trunk footprints",
    );
    assert.ok(
      Math.min(
        ...forest.routes.flatMap((route) =>
          route
            .slice(1)
            .map((end, i) => landDistanceToSegment(point, route[i], end)),
        ),
      ) >= 175,
    );
  }
});
