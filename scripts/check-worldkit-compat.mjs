import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { importOpenWorld } from '../tools/worldkit/adapter.mjs';
import { isLandWalkable as draftWalkable, isLandSegmentWalkable as draftSegment } from '../tools/worldkit/geometry.mjs';
import { isLandWalkable, isLandSegmentWalkable, LAND_MAPS } from '../packages/shared/src/land.ts';

const read = name => JSON.parse(readFileSync(new URL(`../tools/worldkit/fixtures/${name}`, import.meta.url)));
const liveBefore = JSON.stringify(LAND_MAPS);
const draft = importOpenWorld(read('connected.json'), read('mapping.json'));
assert(draft.valid && !draft.publishable);
let probes = 0;
for (const map of Object.values(draft.landMaps)) {
  assert(isLandWalkable(map, map.spawn), `${map.id}: server must accept imported spawn`);
  for (let y = 0; y <= map.height; y += 6) for (let x = 0; x <= map.width; x += 6) {
    const point = { x, y };
    assert.equal(draftWalkable(map, point), isLandWalkable(map, point), `${map.id}: body clearance at ${x},${y}`);
    probes++;
  }
  for (const route of map.routes) for (let i = 1; i < route.length; i++) {
    const from = { x: route[i - 1][0], y: route[i - 1][1] };
    const to = { x: route[i][0], y: route[i][1] };
    assert.equal(draftSegment(map, from, to), isLandSegmentWalkable(map, from, to));
  }
}
assert.equal(JSON.stringify(LAND_MAPS), liveBefore, 'Import must not modify published maps');
console.log(`WorldKit compatibility PASS: ${probes} imported-floor/obstacle probes agree with the live server geometry contract; published maps unchanged.`);
