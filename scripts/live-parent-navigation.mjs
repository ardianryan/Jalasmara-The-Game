import assert from "node:assert/strict";
import { blockedByContours } from "../apps/api/src/geometry.ts";

const distance = (a, b) => Math.hypot(a.x - b.x, a.y - b.y);
export function safeOceanPoint(world, point, maxY = 2080, clearance = 24) {
  return (
    point.x >= clearance &&
    point.x <= world.width - clearance &&
    point.y >= world.surface + clearance &&
    point.y <= maxY - clearance &&
    !blockedByContours(point, world.terrainContours, clearance) &&
    world.hazards.every(
      (hazard) => distance(point, hazard) > hazard.radius + 36,
    )
  );
}
export function safeOceanSegment(world, from, to, maxY = 2080, spacing = 12) {
  const steps = Math.max(1, Math.ceil(distance(from, to) / spacing));
  for (let i = 0; i <= steps; i++) {
    const t = i / steps;
    if (
      !safeOceanPoint(
        world,
        {
          x: from.x + (to.x - from.x) * t,
          y: from.y + (to.y - from.y) * t,
        },
        maxY,
      )
    )
      return false;
  }
  return true;
}
export function oceanRoute(world, from, to, maxY = 2080) {
  assert(
    safeOceanPoint(world, from, maxY),
    "Ocean start must be clear of actual contours/hazards",
  );
  assert(
    safeOceanPoint(world, to, maxY),
    "Ocean target must be clear of actual contours/hazards",
  );
  if (safeOceanSegment(world, from, to, maxY)) return [[to.x, to.y]];
  const points = [
    { x: from.x, y: from.y },
    { x: to.x, y: to.y },
  ];
  for (const polygon of world.terrainContours) {
    const xs = polygon.map((p) => p[0]),
      ys = polygon.map((p) => p[1]);
    for (const x of [Math.min(...xs) - 48, Math.max(...xs) + 48])
      for (const y of [Math.min(...ys) - 48, Math.max(...ys) + 48])
        if (safeOceanPoint(world, { x, y }, maxY)) points.push({ x, y });
  }
  for (const hazard of world.hazards) {
    for (let index = 0; index < 12; index++) {
      const angle = (index * Math.PI) / 6,
        radius = hazard.radius + 80;
      const point = {
        x: hazard.x + Math.cos(angle) * radius,
        y: hazard.y + Math.sin(angle) * radius,
      };
      if (safeOceanPoint(world, point, maxY)) points.push(point);
    }
  }
  const costs = points.map(() => Infinity),
    parents = [],
    visited = new Set();
  costs[0] = 0;
  for (let count = 0; count < points.length; count++) {
    let current = -1;
    for (let index = 0; index < points.length; index++)
      if (!visited.has(index) && (current < 0 || costs[index] < costs[current]))
        current = index;
    if (current < 0 || !Number.isFinite(costs[current])) break;
    if (current === 1) break;
    visited.add(current);
    for (let next = 1; next < points.length; next++) {
      if (visited.has(next)) continue;
      const cost = costs[current] + distance(points[current], points[next]);
      if (
        cost >= costs[next] ||
        !safeOceanSegment(world, points[current], points[next], maxY)
      )
        continue;
      costs[next] = cost;
      parents[next] = current;
    }
  }
  assert(Number.isFinite(costs[1]), "No actual clear ocean route to target");
  const path = [];
  for (let index = 1; index !== 0; index = parents[index]) {
    assert(Number.isInteger(index), "Ocean route graph must remain connected");
    path.unshift([points[index].x, points[index].y]);
  }
  return path;
}
