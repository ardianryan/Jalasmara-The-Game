import test from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { WORLD } from "../../../packages/shared/src/world.ts";
import {
  isLandWalkable,
  isLandSegmentWalkable,
  landPointInPolygon,
  nearestSafeLandPoint,
  type LandMap,
} from "../../../packages/shared/src/land.ts";

const map = WORLD.landMaps.hub;
const old: LandMap = JSON.parse(
  readFileSync(
    new URL("./fixtures/hub-layout10.json", import.meta.url),
    "utf8",
  ),
);
const point = (p: readonly number[]) => ({ x: p[0], y: p[1] });

test("separate private homes and all six new identities preserve existing homes and public services", () => {
  assert.equal(map.layoutVersion, 11);
  for (const house of old.obstacles.filter((o) => o.kind === "house"))
    assert.deepEqual(
      map.obstacles.find((o) => o.id === house.id),
      house,
    );
  assert.deepEqual(WORLD.homestead.permitBoard, { x: 940, y: 310 });
  const homes = WORLD.homestead.privateHomes;
  assert.equal(homes.length, 2);
  for (const home of homes) {
    const building = map.obstacles.find((o) => o.id === home.id)!;
    assert.ok(building && building.kind === "house");
    assert.ok(isLandWalkable(map, home.door, 13));
    assert.equal(landPointInPolygon(home.door, building.footprint), false);
    assert.ok(
      map.shelters!.some(
        (roof) =>
          roof.buildingId === building.id &&
          landPointInPolygon(home.door, roof.roof),
      ),
    );
    const resident = WORLD.surface_hub.residents.find(
      (r) => r.id === home.residentId,
    )!;
    assert.deepEqual(point(resident.activity.rest), home.door);
  }
  assert.notEqual(homes[0].id, "balai_lurah");
  assert.equal(
    map.obstacles.find((o) => o.id === "rumah_direktur")!.variant,
    "director_rv",
  );
  assert.equal(
    WORLD.surface_hub.districts.find((d) => d.id === "dist_pos_korporat")!.npc,
    "Inspektur Raka",
  );
  assert.equal(
    WORLD.surface_hub.residents.filter((r) => r.id === "npc_direktur_cakrawala")
      .length,
    1,
  );
  const children = WORLD.surface_hub.residents.filter(
    (r) => "category" in r && r.category === "village_kid",
  );
  assert.deepEqual(children.map((c) => c.name).sort(), [
    "Bagas",
    "Cempaka",
    "Danu",
    "Gito",
    "Kinasih",
  ]);
  for (const child of children) {
    assert.ok("age" in child && child.age >= 9 && child.age <= 12);
    assert.ok("bodyScale" in child && child.bodyScale < 0.75);
    assert.ok(
      "visual" in child && child.visual.kind === "child" && child.visual.prop,
    );
    assert.ok(child.line.length > 40 && child.evening.length > 30);
  }
});

test("all original and added routes remain body-clear, including the unchanged forest gateway approach", () => {
  const routes = [
    ...map.routes,
    ...WORLD.surface_hub.residents.flatMap((r) => [
      r.route,
      r.activity.commute,
    ]),
  ];
  for (const route of routes)
    for (let i = 1; i < route.length; i++)
      assert.ok(
        isLandSegmentWalkable(map, point(route[i - 1]), point(route[i]), 13),
        JSON.stringify([route[i - 1], route[i]]),
      );
  for (const resident of WORLD.surface_hub.residents)
    for (const key of ["work", "rest", "shelter"] as const)
      assert.ok(
        isLandWalkable(map, point(resident.activity[key]), 13),
        resident.id + "/" + key,
      );
  for (const route of old.routes)
    for (let i = 1; i < route.length; i++)
      assert.ok(
        isLandSegmentWalkable(map, point(route[i - 1]), point(route[i]), 13),
        "Existing route must not be silently rerouted around a new building",
      );
  assert.equal(JSON.stringify(map.gateways), JSON.stringify(old.gateways));
});

test(
  "layout10 saves blocked by the private home, porch and moved tree recover into the connected hub",
  { timeout: 60000 },
  (t) => {
    const step = 24,
      queue = [{ ...map.spawn }],
      reached = new Map([[`${map.spawn.x},${map.spawn.y}`, map.spawn]]),
      checked = new Set<string>();
    for (let i = 0; i < queue.length; i++) {
      const at = queue[i];
      for (let dx = -1; dx <= 1; dx++)
        for (let dy = -1; dy <= 1; dy++) {
          if (!dx && !dy) continue;
          const next = { x: at.x + dx * step, y: at.y + dy * step },
            key = `${next.x},${next.y}`;
          if (
            reached.has(key) ||
            next.x < 40 ||
            next.x > 2360 ||
            next.y < 12 ||
            next.y > 1520
          )
            continue;
          if (!checked.has(key)) {
            checked.add(key);
            if (!isLandWalkable(map, next, 13)) continue;
          } else if (!isLandWalkable(map, next, 13)) continue;
          if (!isLandSegmentWalkable(map, at, next, 13)) continue;
          reached.set(key, next);
          queue.push(next);
        }
    }
    assert.ok(reached.size > 1000);
    const connects = (at: { x: number; y: number }) =>
      queue.some(
        (node) =>
          Math.hypot(node.x - at.x, node.y - at.y) < 40 &&
          isLandSegmentWalkable(map, at, node, 13),
      );
    let samples = 0;
    const changed = map.obstacles.filter(
      (o) =>
        JSON.stringify(old.obstacles.find((p) => p.id === o.id)?.footprint) !==
        JSON.stringify(o.footprint),
    );
    for (const obstacle of changed) {
      const positions = [
        {
          x: obstacle.x + obstacle.width / 2,
          y: obstacle.y + obstacle.height / 2,
        },
      ];
      for (
        let y = obstacle.y - 16;
        y <= obstacle.y + obstacle.height + 16;
        y += 16
      )
        for (
          let x = obstacle.x - 16;
          x <= obstacle.x + obstacle.width + 16;
          x += 16
        )
          positions.push({ x, y });
      for (const previous of positions) {
        if (
          !isLandWalkable(old, previous, 13) ||
          isLandWalkable(map, previous, 13)
        )
          continue;
        const safe = nearestSafeLandPoint(map, previous);
        assert.ok(isLandWalkable(map, safe, 13));
        assert.ok(
          connects(safe),
          obstacle.id +
            " recovery must have a real path to the dock, not merely a walkable point " +
            JSON.stringify(safe),
        );
        assert.ok(Math.hypot(safe.x - previous.x, safe.y - previous.y) <= 128);
        samples++;
      }
    }
    for (const home of WORLD.homestead.privateHomes)
      assert.ok(
        connects(home.door),
        home.id + " door must connect to the same hub floor component",
      );
    assert.ok(samples >= 40);
    t.diagnostic(
      `${samples} real old saves and ${reached.size} collision/segment checked hub nodes`,
    );
  },
);
