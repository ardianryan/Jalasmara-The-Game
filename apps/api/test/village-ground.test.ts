import test from "node:test";
import assert from "node:assert/strict";
import {
  LAND_MAPS,
  isLandWalkable,
  isLandSegmentWalkable,
  landDistanceToSegment,
  landPointInPolygon,
  mapFootMaterial,
  type LandMap,
  type LandPoint,
} from "../../../packages/shared/src/land.ts";
import { decorateVillageGround } from "../../../packages/shared/src/village-ground.ts";
const prefix = "village_dirt_";
const original = structuredClone(LAND_MAPS.hub);
original.surfaces = original.surfaces.filter(
  (surface) => !surface.id.startsWith(prefix),
);
for (const surface of original.surfaces)
  if (["lower_court", "upper_court"].includes(surface.id))
    surface.material = "dirt";
const painted = decorateVillageGround(original);
const additions = painted.surfaces.filter((surface) =>
  surface.id.startsWith(prefix),
);
const point = ([x, y]: LandPoint) => ({ x, y });
const area = (polygon: readonly LandPoint[]) =>
  Math.abs(
    polygon.reduce((sum, a, i) => {
      const b = polygon[(i + 1) % polygon.length];
      return sum + a[0] * b[1] - b[0] * a[1];
    }, 0) / 2,
  );
function insideOrBoundary(at: { x: number; y: number }, polygon: LandPoint[]) {
  return (
    landPointInPolygon(at, polygon) ||
    polygon.some(
      (a, i) =>
        landDistanceToSegment(at, a, polygon[(i + 1) % polygon.length]) < 1e-6,
    )
  );
}
function fixture(): LandMap {
  return {
    id: "hub",
    layoutVersion: 10,
    width: 100,
    height: 100,
    spawn: { x: 10, y: 50 },
    surfaces: [
      {
        id: "upper_court",
        polygon: [
          [0, 0],
          [100, 0],
          [100, 100],
          [0, 100],
        ],
        material: "dirt",
        elevation: 2,
      },
    ],
    obstacles: [],
    stairs: [],
    terraces: [],
    routes: [
      [
        [-100, 50],
        [200, 50],
      ],
    ],
  };
}

test("village courts become grass without mutation or changes to floor geometry, elevation or connectors", () => {
  const before = JSON.stringify(original),
    result = decorateVillageGround(original);
  assert.notEqual(result, original);
  assert.equal(JSON.stringify(original), before);
  assert.deepEqual({ ...result, surfaces: original.surfaces }, { ...original });
  for (const surface of original.surfaces) {
    const after = result.surfaces.find((entry) => entry.id === surface.id)!;
    assert.deepEqual(
      after,
      ["lower_court", "upper_court"].includes(surface.id)
        ? { ...surface, material: "grass" }
        : surface,
    );
  }
  assert.deepEqual(result.stairs, original.stairs);
  assert.deepEqual(result.routes, original.routes);
  assert.deepEqual(result.obstacles, original.obstacles);
  assert.deepEqual(result.gateways, original.gateways);
  assert.deepEqual(
    decorateVillageGround(result),
    result,
    "Repeated decoration must not accumulate surfaces",
  );
});

test("every dirt vertex and edge sample stays inside its original owning court including clipped boundaries", () => {
  assert(additions.length > 0 && additions.length < 64);
  for (const surface of additions) {
    const owner = original.surfaces.find(
      (candidate) =>
        ["lower_court", "upper_court"].includes(candidate.id) &&
        surface.id.startsWith(`${prefix}${candidate.id}_`),
    )!;
    assert(owner, surface.id);
    assert.equal(surface.material, "dirt");
    assert.equal(surface.elevation, owner.elevation);
    assert.equal(surface.priority, 4);
    assert.equal(surface.walkable, false);
    assert(!surface.connectorId && !surface.bridgeId);
    assert(area(surface.polygon) > 1);
    for (let i = 0; i < surface.polygon.length; i++) {
      const a = surface.polygon[i],
        b = surface.polygon[(i + 1) % surface.polygon.length];
      for (const t of [0, 0.25, 0.5, 0.75, 1])
        assert(
          insideOrBoundary(
            { x: a[0] + (b[0] - a[0]) * t, y: a[1] + (b[1] - a[1]) * t },
            owner.polygon,
          ),
          surface.id,
        );
    }
  }
});

test("clipping a route across a court preserves exact boundary and72-unit trail width", () => {
  const map = fixture(),
    result = decorateVillageGround(map),
    paths = result.surfaces.filter((surface) => surface.id.startsWith(prefix));
  assert.equal(paths.length, 1);
  assert.equal(area(paths[0].polygon), 7200);
  assert.equal(Math.min(...paths[0].polygon.map((p) => p[0])), 0);
  assert.equal(Math.max(...paths[0].polygon.map((p) => p[0])), 100);
  assert.equal(Math.min(...paths[0].polygon.map((p) => p[1])), 14);
  assert.equal(Math.max(...paths[0].polygon.map((p) => p[1])), 86);
  map.surfaces[0].polygon.reverse();
  assert.equal(
    area(
      decorateVillageGround(map).surfaces.find((surface) =>
        surface.id.startsWith(prefix),
      )!.polygon,
    ),
    7200,
    "Clockwise court winding must clip identically",
  );
});

test("original stone, wood, stair connector and garden paint is subtracted rather than duplicated", () => {
  for (const protectedKind of ["stone", "wood", "connector", "garden"]) {
    const map = fixture(),
      polygon: LandPoint[] = [
        [45, 0],
        [55, 0],
        [55, 100],
        [45, 100],
      ];
    if (protectedKind === "garden")
      map.obstacles.push({
        id: "garden",
        kind: "garden",
        x: 45,
        y: 0,
        width: 10,
        height: 100,
        height3d: 20,
        footprint: polygon,
      });
    else
      map.surfaces.push({
        id: "existing",
        polygon,
        material: protectedKind === "wood" ? "wood" : "stone",
        elevation: 2,
        priority: 8,
        walkable: false,
        ...(protectedKind === "connector" ? { connectorId: "stairs" } : {}),
      });
    const result = decorateVillageGround(map),
      paths = result.surfaces.filter((surface) =>
        surface.id.startsWith(prefix),
      );
    assert.equal(paths.length, 2, protectedKind);
    assert.equal(
      paths.reduce((sum, p) => sum + area(p.polygon), 0),
      6480,
      protectedKind,
    );
    for (const surface of paths)
      for (const [x] of surface.polygon)
        assert(x <= 45 + 1e-6 || x >= 55 - 1e-6, protectedKind);
    assert.deepEqual(
      result.surfaces.filter(
        (surface) =>
          !surface.id.startsWith(prefix) && surface.id !== "upper_court",
      ),
      map.surfaces.filter((surface) => surface.id !== "upper_court"),
    );
  }
});

test("actual village walkability, authored route clearance and old stone service paths remain unchanged", () => {
  let samples = 0;
  for (let y = 100; y <= 1400; y += 35)
    for (let x = 40; x <= 2380; x += 35) {
      assert.equal(
        isLandWalkable(painted, { x, y }, 13),
        isLandWalkable(original, { x, y }, 13),
      );
      samples++;
    }
  assert(samples > 2000);
  for (const route of original.routes)
    for (let index = 1; index < route.length; index++)
      assert.equal(
        isLandSegmentWalkable(
          painted,
          point(route[index - 1]),
          point(route[index]),
          13,
        ),
        isLandSegmentWalkable(
          original,
          point(route[index - 1]),
          point(route[index]),
          13,
        ),
      );
  for (const at of [
    { x: 900, y: 650 },
    { x: 1150, y: 360 },
    { x: 1005, y: 975 },
  ])
    assert.equal(mapFootMaterial(painted, at), mapFootMaterial(original, at));
  for (const courtId of ["lower_court", "upper_court"]) {
    const court = original.surfaces.find((surface) => surface.id === courtId)!;
    let green = 0,
      total = 0;
    for (let y = 100; y <= 1400; y += 20)
      for (let x = 40; x <= 2380; x += 20) {
        if (
          !landPointInPolygon({ x, y }, court.polygon) ||
          !isLandWalkable(original, { x, y }, 13)
        )
          continue;
        total++;
        if (mapFootMaterial(painted, { x, y }) === "grass") green++;
      }
    assert(
      green / total > 0.6,
      `${courtId}: cheerful grass must cover most reachable court ground, actual ${green}/${total}`,
    );
  }
});

test("forest and noncourt floors are untouched and invalid concave court authoring is rejected", () => {
  assert.deepEqual(decorateVillageGround(LAND_MAPS.forest), LAND_MAPS.forest);
  const invalid = fixture();
  invalid.surfaces[0].polygon = [
    [0, 0],
    [100, 0],
    [50, 50],
    [100, 100],
    [0, 100],
  ];
  assert.throws(() => decorateVillageGround(invalid), /convex floor/);
});
