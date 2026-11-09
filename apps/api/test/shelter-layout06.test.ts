import assert from "node:assert/strict";
import test from "node:test";
import { WORLD } from "../../../packages/shared/src/world.ts";
import {
  isLandWalkable,
  isLandSegmentWalkable,
  landPointInPolygon,
  nearestSafeLandPoint,
} from "../../../packages/shared/src/land.ts";

const map = WORLD.landMaps.hub;
const profiles = [
  ...WORLD.surface_hub.residents,
  { name: "Bu Darmi", ...WORLD.surface_hub.districtActivities["Bu Darmi"] },
];
const point = (value: readonly number[]) => ({ x: value[0], y: value[1] });

test("seven rain stations have body clearance under physical roof plans", () => {
  for (const profile of profiles) {
    const station = point(profile.activity.shelter);
    assert.ok(isLandWalkable(map, station), profile.name);
    const roof = map.shelters!.find((shelter) => {
      for (let index = 0; index < 16; index++) {
        const angle = (index * Math.PI) / 8;
        if (
          !landPointInPolygon(
            {
              x: station.x + Math.cos(angle) * 13,
              y: station.y + Math.sin(angle) * 13,
            },
            shelter.roof,
          )
        )
          return false;
      }
      return true;
    });
    assert.ok(
      roof,
      `${profile.name} must fit beneath one actual roof, not merely a house bbox`,
    );
  }
});

// Clear segments through authored stations and support corners prove physical floor connectivity.
// Runtime NPC graph traversal is checked separately by village-routine06.gd.
const routes = [
  ...map.routes,
  ...profiles.map((profile) => profile.activity.commute),
];
const nodes = routes.flatMap((route) => route.map(point));
for (const post of map.obstacles.filter(
  (entry) => entry.variant === "shelter_post",
)) {
  for (const [dx, dy] of [
    [-32, -32],
    [-32, 32],
    [32, -32],
    [32, 32],
  ]) {
    const candidate = { x: post.x + 5 + dx, y: post.y + 5 + dy };
    if (isLandWalkable(map, candidate)) nodes.push(candidate);
  }
}
const graph = nodes.map(() => [] as number[]);
for (let i = 0; i < nodes.length; i++)
  for (let j = i + 1; j < nodes.length; j++) {
    if (!isLandSegmentWalkable(map, nodes[i], nodes[j])) continue;
    graph[i].push(j);
    graph[j].push(i);
  }
function reachesHub(start: { x: number; y: number }) {
  const queue = nodes.flatMap((node, index) =>
    isLandSegmentWalkable(map, start, node) ? [index] : [],
  );
  const seen = new Set(queue);
  while (queue.length) {
    const index = queue.shift()!;
    if (nodes[index].x === map.spawn.x && nodes[index].y === map.spawn.y)
      return true;
    for (const next of graph[index])
      if (!seen.has(next)) {
        seen.add(next);
        queue.push(next);
      }
  }
  return false;
}
test("stations, bridge, changing booth and forest portal stay connected", () => {
  for (const profile of profiles)
    for (const station of ["work", "rest", "shelter"] as const) {
      assert.ok(
        reachesHub(point(profile.activity[station])),
        `${profile.name}/${station}`,
      );
    }
  for (const target of [
    [160, 615],
    [265, 720],
    [400, 720],
    [1485, 1330],
    [2295, 125],
  ]) {
    assert.ok(reachesHub(point(target)), String(target));
  }
});

test("layout migration from each newly blocked support retains connected land", () => {
  const old = {
    ...map,
    layoutVersion: 8,
    obstacles: map.obstacles.filter(
      (entry) => entry.variant !== "shelter_post",
    ),
  };
  assert.equal(map.layoutVersion, 9);
  let migrated = 0;
  for (const post of map.obstacles.filter(
    (entry) => entry.variant === "shelter_post",
  )) {
    for (const [dx, dy] of [
      [0, 0],
      [-8, 0],
      [8, 0],
      [0, -8],
      [0, 8],
    ]) {
      const previous = {
        x: post.x + post.width / 2 + dx,
        y: post.y + post.height / 2 + dy,
      };
      if (!isLandWalkable(old, previous)) continue;
      assert.equal(isLandWalkable(map, previous), false, post.id);
      const safe = nearestSafeLandPoint(map, previous);
      assert.ok(isLandWalkable(map, safe), post.id);
      assert.ok(
        reachesHub(safe),
        `${post.id} migration must not end on an isolated island of floor`,
      );
      migrated++;
    }
  }
  assert.ok(
    migrated >= 30,
    `Insufficient previously valid support samples: ${migrated}`,
  );
});
