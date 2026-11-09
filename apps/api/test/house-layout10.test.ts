import assert from "node:assert/strict";
import test from "node:test";
import { readFileSync } from "node:fs";
import {
  LAND_MAPS,
  isLandWalkable,
  isLandSegmentWalkable,
  nearestSafeLandPoint,
  landPointInPolygon,
  type LandMap,
  type LandPosition,
} from "../../../packages/shared/src/land.ts";
import { WORLD } from "../../../packages/shared/src/world.ts";

const map = LAND_MAPS.hub;
const oldMap: LandMap = JSON.parse(
  readFileSync(new URL("./fixtures/hub-layout9.json", import.meta.url), "utf8"),
);
const houses = map.obstacles.filter(
  (entry) => entry.kind === "house" && entry.id !== "griya_sasmita",
);
const point = (p: readonly number[]): LandPosition => ({ x: p[0], y: p[1] });
const changedCorners: Record<string, number> = {
  kedai_waras: 78,
  galangan_beno: 105,
  pos_cakrawala: 54,
  balai_lurah: 70,
  rumah_ratih: 41,
  rumah_sari: 41,
  rumah_tedi: 27,
};
function groundElevation(layout: LandMap, at: LandPosition) {
  const surfaces = layout.surfaces.filter((s) =>
    landPointInPolygon(at, s.polygon),
  );
  return surfaces.reduce((best, next) =>
    (next.priority ?? 0) >= (best.priority ?? 0) ? next : best,
  ).elevation;
}

test("layout10 removes house shear while retaining centres, real floors and existing identities", () => {
  assert.equal(oldMap.layoutVersion, 9);
  assert.equal(map.layoutVersion, 10);
  assert.deepEqual(
    map.surfaces.filter((s) => s.walkable !== false),
    oldMap.surfaces
      .filter((s) => s.walkable !== false)
      .map((surface) =>
        ["lower_court", "upper_court"].includes(surface.id)
          ? { ...surface, material: "grass" }
          : surface,
      ),
  );
  assert.deepEqual(
    map.obstacles.map((o) => [o.id, o.kind, o.variant]),
    oldMap.obstacles.map((o) => [o.id, o.kind, o.variant]),
  );
  assert.deepEqual(
    map.obstacles.find((o) => o.id === "griya_sasmita"),
    oldMap.obstacles.find((o) => o.id === "griya_sasmita"),
  );
  for (const house of houses) {
    const old = oldMap.obstacles.find((o) => o.id === house.id)!;
    assert.deepEqual(
      [
        house.x + house.width / 2,
        house.y + house.height / 2,
        house.height3d,
        house.elevation,
      ],
      [
        old.x + old.width / 2,
        old.y + old.height / 2,
        old.height3d,
        old.elevation,
      ],
    );
    const [a, b, c, d] = house.footprint;
    const along = [
      b[0] - a[0],
      -(b[1] - a[1]) / Math.cos((55 * Math.PI) / 180),
    ];
    const back = [a[0] - d[0], -(a[1] - d[1]) / Math.cos((55 * Math.PI) / 180)];
    const [oa, ob, , od] = old.footprint;
    const oldAlong = [
      ob[0] - oa[0],
      (ob[1] - oa[1]) / Math.cos((55 * Math.PI) / 180),
    ];
    const oldOut = [
      od[0] - oa[0],
      (od[1] - oa[1]) / Math.cos((55 * Math.PI) / 180),
    ];
    const oldArea = Math.abs(oldAlong[0] * oldOut[1] - oldAlong[1] * oldOut[0]);
    assert.ok(
      Math.abs(
        (house.width * house.height) / Math.cos((55 * Math.PI) / 180) - oldArea,
      ) < 1e-7,
      `${house.id} must not grow while removing shear`,
    );
    assert.ok(
      Math.abs(
        house.width / (house.height / Math.cos((55 * Math.PI) / 180)) -
          Math.hypot(...oldAlong) / Math.hypot(...oldOut),
      ) < 1e-10,
      `${house.id} preserves the old physical axis aspect`,
    );
    assert.equal(along[0] * back[0] + along[1] * back[1], 0, house.id);
    assert.deepEqual(
      [(a[0] + c[0]) / 2, (a[1] + c[1]) / 2],
      [house.x + house.width / 2, house.y + house.height / 2],
    );
  }
});

test("layout10 supports and all authored routes retain client-sized clearance", () => {
  const profiles = [
    ...WORLD.surface_hub.residents,
    { name: "Bu Darmi", ...WORLD.surface_hub.districtActivities["Bu Darmi"] },
  ];
  for (const shelter of map.shelters!.filter((s) => !s.existing)) {
    const house = map.obstacles.find((o) => o.id === shelter.buildingId)!;
    assert.equal(shelter.roof[0][1], shelter.roof[1][1], shelter.id);
    assert.equal(shelter.roof[0][1], house.y + house.height - 8, shelter.id);
    for (const [index, at] of shelter.posts.entries()) {
      const post = map.obstacles.find(
        (o) => o.id === `${shelter.id}_post_${index}`,
      )!;
      assert.deepEqual([post.x + post.width / 2, post.y + post.height / 2], at);
      assert.equal(post.elevation, house.elevation);
    }
  }
  for (const profile of profiles)
    for (const key of ["work", "rest", "shelter"] as const)
      assert.ok(
        isLandWalkable(map, point(profile.activity[key]), 13),
        `${profile.name}/${key}`,
      );
  for (const route of [
    ...map.routes,
    ...profiles.map((p) => p.activity.commute),
  ])
    for (let i = 1; i < route.length; i++)
      assert.ok(
        isLandSegmentWalkable(map, point(route[i - 1]), point(route[i]), 13),
        JSON.stringify([route[i - 1], route[i]]),
      );
  assert.ok(
    map.routes.some((route) => route.some((p) => p[0] === 760 && p[1] === 325)),
  );
  assert.ok(
    !profiles[1].activity.commute.some((p) => p[0] === 760 && p[1] === 350),
  );
});

function localConnectivity(house: (typeof houses)[number]) {
  const step = 16,
    lowX = house.x - 128,
    lowY = house.y - 128;
  const columns = Math.ceil((house.width + 256) / step) + 1;
  const rows = Math.ceil((house.height + 288) / step) + 1;
  const points = new Map<number, LandPosition>();
  for (let y = 0; y < rows; y++)
    for (let x = 0; x < columns; x++) {
      const p = { x: lowX + x * step, y: lowY + y * step };
      if (isLandWalkable(map, p, 13)) points.set(y * columns + x, p);
    }
  const front = {
    x: house.x + house.width / 2,
    y: house.y + house.height + 64,
  };
  const anchors = map.routes
    .flatMap((route) => route.map(point))
    .filter((p) => isLandWalkable(map, p, 13));
  anchors.sort(
    (a, b) =>
      Math.hypot(a.x - front.x, a.y - front.y) -
      Math.hypot(b.x - front.x, b.y - front.y),
  );
  const anchor = anchors[0];
  const reached = new Set<number>(),
    queue: number[] = [];
  for (const [id, p] of points)
    if (
      Math.hypot(p.x - anchor.x, p.y - anchor.y) <= 32 &&
      isLandSegmentWalkable(map, p, anchor, 13)
    ) {
      reached.add(id);
      queue.push(id);
    }
  assert.ok(
    queue.length,
    `${house.id} must attach to its authored front route`,
  );
  for (let index = 0; index < queue.length; index++) {
    const id = queue[index],
      x = id % columns,
      y = Math.floor(id / columns),
      from = points.get(id)!;
    for (let dy = -1; dy <= 1; dy++)
      for (let dx = -1; dx <= 1; dx++) {
        if (
          (!dx && !dy) ||
          x + dx < 0 ||
          x + dx >= columns ||
          y + dy < 0 ||
          y + dy >= rows
        )
          continue;
        const next = (y + dy) * columns + x + dx,
          to = points.get(next);
        if (
          to &&
          !reached.has(next) &&
          isLandSegmentWalkable(map, from, to, 13)
        ) {
          reached.add(next);
          queue.push(next);
        }
      }
  }
  return (safe: LandPosition) => {
    const x = Math.round((safe.x - lowX) / step),
      y = Math.round((safe.y - lowY) / step);
    for (let dy = -1; dy <= 1; dy++)
      for (let dx = -1; dx <= 1; dx++) {
        const id = (y + dy) * columns + x + dx,
          at = points.get(id);
        if (at && reached.has(id) && isLandSegmentWalkable(map, safe, at, 13))
          return true;
      }
    return false;
  };
}

test(
  "old layout9 corner saves recover onto connected floor with the client's 13px clearance",
  { timeout: 120000 },
  (t) => {
    let samples = 0,
      maximumShift = 0;
    for (const house of houses) {
      const old = oldMap.obstacles.find((entry) => entry.id === house.id)!;
      const reachesFront = localConnectivity(house);
      let localSamples = 0;
      for (let y = old.y - 24; y <= old.y + old.height + 24; y += 8)
        for (let x = old.x - 24; x <= old.x + old.width + 24; x += 8) {
          const previous = { x, y };
          if (
            !isLandWalkable(oldMap, previous, 13) ||
            isLandWalkable(map, previous, 13)
          )
            continue;
          const safe = nearestSafeLandPoint(map, previous);
          assert.ok(
            isLandWalkable(map, safe, 13),
            `${house.id}: API-valid but client-stuck recovery ${JSON.stringify({ previous, safe })}`,
          );
          assert.equal(
            groundElevation(map, safe),
            groundElevation(oldMap, previous),
            `${house.id}: corner recovery must stay on the original real floor`,
          );
          assert.ok(
            reachesFront(safe),
            `${house.id}: recovery cannot reach its real front route ${JSON.stringify({ previous, safe })}`,
          );
          const distance = Math.hypot(safe.x - x, safe.y - y);
          assert.ok(
            distance <= 32.001,
            `${house.id}: nearby correction must not reset to the world spawn`,
          );
          maximumShift = Math.max(maximumShift, distance);
          localSamples++;
          samples++;
        }
      assert.equal(
        localSamples,
        changedCorners[house.id],
        `${house.id} must exercise previously legal corners, not fabricated old blocked positions`,
      );
    }
    t.diagnostic(
      `${samples} frozen-layout9 positions recovered with a connected 13px perimeter path; max correction ${maximumShift.toFixed(2)}`,
    );
  },
);
