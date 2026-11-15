import assert from 'node:assert/strict';
import {
  LAND_MAPS,
  isLandSegmentWalkable,
  isLandWalkable,
  landDistanceToSegment,
} from '../../packages/shared/src/land.ts';
import { WORLD } from '../../packages/shared/src/world.ts';

// Proposed world-unit footprints. Source sprite dimensions are not collider sizes.
const reservations = {
  saras_tent: [1530, 610, 90, 45],
  raka_quarters: [2145, 165, 75, 60],
  director_generator: [1690, 280, 30, 22],
};
const hub = LAND_MAPS.hub;
const rectangle = ([x, y, width, height]) => [
  [x, y], [x + width, y], [x + width, y + height], [x, y + height],
];

function samples([x, y, width, height], spacing) {
  const cols = Math.ceil(width / spacing);
  const rows = Math.ceil(height / spacing);
  return Array.from({ length: (cols + 1) * (rows + 1) }, (_, index) => ({
    x: x + (index % (cols + 1)) * width / cols,
    y: y + Math.floor(index / (cols + 1)) * height / rows,
  }));
}

for (const [name, box] of Object.entries(reservations)) {
  for (const point of samples(box, 4))
    assert.ok(isLandWalkable(hub, point, 9), `${name} has no clear authored floor at ${JSON.stringify(point)}`);
}

const proposed = {
  ...hub,
  obstacles: [
    ...hub.obstacles,
    ...Object.entries(reservations).map(([id, box]) => ({
      id,
      kind: 'house',
      x: box[0], y: box[1], width: box[2], height: box[3],
      height3d: 100,
      footprint: rectangle(box),
    })),
  ],
};

let existingSegments = 0;
for (const route of hub.routes) {
  for (let index = 1; index < route.length; index++) {
    const from = { x: route[index - 1][0], y: route[index - 1][1] };
    const to = { x: route[index][0], y: route[index][1] };
    assert.ok(isLandSegmentWalkable(hub, from, to, 13), 'existing route is already blocked');
    assert.ok(isLandSegmentWalkable(proposed, from, to, 13), 'reservation blocks an existing route');
    existingSegments++;
  }
}

const access = {
  saras_work_to_tent: [[1480, 680], [1490, 590], [1575, 585]],
  saras_existing_commute: [[1480, 680], [1350, 635], [900, 650], [900, 350], [940, 310], [1020, 310]],
  raka_office_to_quarters: [[1950, 300], [2180, 300], [2182.5, 250]],
  director_door_to_office: [[1770, 240], [1770, 310], [1830, 310]],
};
for (const [name, path] of Object.entries(access)) {
  for (let index = 1; index < path.length; index++) {
    const from = { x: path[index - 1][0], y: path[index - 1][1] };
    const to = { x: path[index][0], y: path[index][1] };
    assert.ok(isLandSegmentWalkable(proposed, from, to, 13), `${name} is disconnected`);
  }
}

for (const [name, box] of Object.entries(reservations)) {
  const clearance = Math.min(...samples(box, 8).flatMap((point) =>
    hub.routes.flatMap((route) => route.slice(1).map((end, index) =>
      landDistanceToSegment(point, route[index], end)))));
  assert.ok(clearance >= 24, `${name} intrudes on an authored route`);
}

for (const [x, y] of [[1480, 680], [1950, 300], [1770, 240], [2295, 125], [1775, 515], [1775, 635]])
  assert.ok(isLandWalkable(proposed, { x, y }, 13), `protected service at ${x},${y} is blocked`);

assert.equal(WORLD.atlas.regions.find((region) => region.id === 'forest_hulu')?.status, 'coming_soon');
console.log(JSON.stringify({ reservations, existingSegments, accessPaths: Object.keys(access).length, forestHulu: 'coming_soon' }));
