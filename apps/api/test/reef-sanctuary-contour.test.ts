import assert from "node:assert/strict";
import test from "node:test";
import { WORLD } from "../../../packages/shared/src/world.js";
import { blockedByContours } from "../src/geometry.js";

test("sanctuary reef keeps the boss arena reachable", () => {
  const contour = WORLD.terrainContours[12];
  const cross = (a: readonly number[], b: readonly number[], c: readonly number[]) =>
    (b[0] - a[0]) * (c[1] - a[1]) -
    (b[1] - a[1]) * (c[0] - a[0]);
  for (let i = 0; i < contour.length; i++) {
    for (let j = i + 2; j < contour.length; j++) {
      if (i === 0 && j === contour.length - 1) continue;
      const a = contour[i], b = contour[(i + 1) % contour.length];
      const c = contour[j], d = contour[(j + 1) % contour.length];
      assert.ok(
        !(cross(a, b, c) * cross(a, b, d) < 0 &&
          cross(c, d, a) * cross(c, d, b) < 0),
        `reef edges ${i} and ${j} cross`,
      );
    }
  }

  const step = 40, left = 3000, top = 2520, right = 4320, bottom = 3400;
  const key = (x: number, y: number) => `${x},${y}`;
  const queue: [number, number][] = [[4140, 2700]];
  const seen = new Set([key(...queue[0])]);
  for (let index = 0; index < queue.length; index++) {
    const [x, y] = queue[index];
    for (const [dx, dy] of [[step, 0], [-step, 0], [0, step], [0, -step]]) {
      const nx = x + dx, ny = y + dy, id = key(nx, ny);
      if (nx < left || nx > right || ny < top || ny > bottom || seen.has(id)) continue;
      if (blockedByContours({ x: nx, y: ny }, WORLD.terrainContours, 12)) continue;
      seen.add(id);
      queue.push([nx, ny]);
    }
  }
  for (const y of [3060, 3260]) {
    for (const x of [3380, 3620, 3860]) {
      assert.ok(seen.has(key(x, y)), `resonance target ${x},${y} is cut off`);
    }
  }
  assert.equal(blockedByContours({ x: 4660, y: 2630 }, WORLD.terrainContours, 12), false);
});
