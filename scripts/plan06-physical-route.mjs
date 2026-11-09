import assert from "node:assert/strict";
import {
  isLandWalkable,
  isLandSegmentWalkable,
} from "../packages/shared/src/land.ts";
import { hubRoute } from "./game-navigation.mjs";

const caches = new WeakMap();
const point = (value) => ({ x: value[0], y: value[1] });

// Prefer the established stair/bridge route. Only use a checked detour when new
// supports interrupt an old segment or a station needs a different approach.
export function physicalRoute(world, from, destination, area = "hub") {
  const map = area === "home" ? world.homestead.interior : world.landMaps[area];
  assert(map, `Missing ${area} manifest`);
  assert(
    isLandWalkable(map, from),
    `Current ${area} position is not on authoritative floor`,
  );
  assert(
    isLandWalkable(map, destination),
    `Target ${area} position is not on authoritative floor`,
  );
  let authored;
  try {
    authored = hubRoute({ hub: { paths: map.routes } }, from, destination).map(
      point,
    );
  } catch (error) {
    if (
      !(error instanceof assert.AssertionError) ||
      !error.message.includes("disconnected")
    )
      throw error;
  }
  if (
    authored?.length &&
    [from, ...authored].every(
      (value, index, values) =>
        index === 0 || isLandSegmentWalkable(map, values[index - 1], value),
    )
  )
    return authored.map((value) => [value.x, value.y]);
  let graph = caches.get(map);
  if (!graph) {
    const candidates = map.routes.flat().map(point);
    if (area === "hub") {
      for (const profile of [
        ...world.surface_hub.residents,
        ...Object.values(world.surface_hub.districtActivities),
      ])
        candidates.push(...profile.activity.commute.map(point));
      for (const obstacle of map.obstacles.filter(
        (value) => value.variant === "shelter_post",
      )) {
        for (const dx of [-32, 32])
          for (const dy of [-32, 32])
            candidates.push({
              x: obstacle.x + obstacle.width / 2 + dx,
              y: obstacle.y + obstacle.height / 2 + dy,
            });
      }
    }
    const unique = new Map(
      candidates
        .filter((value) => isLandWalkable(map, value))
        .map((value) => [`${value.x},${value.y}`, value]),
    );
    const points = [...unique.values()],
      edges = points.map(() => []);
    for (let a = 0; a < points.length; a++)
      for (let b = a + 1; b < points.length; b++) {
        if (!isLandSegmentWalkable(map, points[a], points[b])) continue;
        const cost = Math.hypot(
          points[a].x - points[b].x,
          points[a].y - points[b].y,
        );
        edges[a].push([b, cost]);
        edges[b].push([a, cost]);
      }
    graph = { points, edges };
    caches.set(map, graph);
  }
  const points = [...graph.points, { x: from.x, y: from.y }, destination];
  const edges = graph.edges.map((value) => [...value]);
  const start = points.length - 2,
    finish = points.length - 1;
  edges.push([], []);
  for (const index of [start, finish])
    for (let other = 0; other < index; other++) {
      if (!isLandSegmentWalkable(map, points[index], points[other])) continue;
      const cost = Math.hypot(
        points[index].x - points[other].x,
        points[index].y - points[other].y,
      );
      edges[index].push([other, cost]);
      edges[other].push([index, cost]);
    }
  const costs = new Map([[start, 0]]),
    parents = new Map(),
    pending = new Set(points.map((_, index) => index));
  while (pending.size) {
    const current = [...pending].sort(
      (a, b) => (costs.get(a) ?? Infinity) - (costs.get(b) ?? Infinity),
    )[0];
    if (!Number.isFinite(costs.get(current)) || current === finish) break;
    pending.delete(current);
    for (const [next, cost] of edges[current])
      if ((costs.get(next) ?? Infinity) > costs.get(current) + cost) {
        costs.set(next, costs.get(current) + cost);
        parents.set(next, current);
      }
  }
  assert(
    Number.isFinite(costs.get(finish)),
    `No physical ${area} detour connects the destination`,
  );
  const route = [];
  for (let current = finish; current !== start; current = parents.get(current))
    route.unshift(points[current]);
  return route.map((value) => [value.x, value.y]);
}
