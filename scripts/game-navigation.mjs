import assert from "node:assert/strict";

export async function fetchWorld(api, origin) {
  const response = await api.get(`${origin}/api/adventure/state`);
  assert(response.ok(), `World state unavailable: ${response.status()}`);
  const state = await response.json();
  assert(state.world?.hub?.paths?.length, "Village path metadata is required");
  return state.world;
}

export function hubRoute(world, from, destination) {
  const nodes = new Map();
  const edges = new Map();
  const key = (point) => `${point[0]},${point[1]}`;
  for (const path of world.hub.paths) {
    for (const point of path) {
      nodes.set(key(point), point);
      if (!edges.has(key(point))) edges.set(key(point), new Set());
    }
    for (let i = 1; i < path.length; i++) {
      edges.get(key(path[i - 1])).add(key(path[i]));
      edges.get(key(path[i])).add(key(path[i - 1]));
    }
  }
  const nearest = (point) =>
    [...nodes.keys()].sort((a, b) => {
      const distance = (id) =>
        Math.hypot(nodes.get(id)[0] - point.x, nodes.get(id)[1] - point.y);
      return distance(a) - distance(b);
    })[0];
  const start = nearest(from),
    finish = nearest(destination),
    costs = new Map([[start, 0]]),
    parents = new Map(),
    pending = new Set(nodes.keys());
  while (pending.size) {
    const current = [...pending].sort(
      (a, b) => (costs.get(a) ?? Infinity) - (costs.get(b) ?? Infinity),
    )[0];
    if (!Number.isFinite(costs.get(current))) break;
    pending.delete(current);
    if (current === finish) break;
    for (const next of edges.get(current)) {
      const a = nodes.get(current),
        b = nodes.get(next),
        cost = costs.get(current) + Math.hypot(a[0] - b[0], a[1] - b[1]);
      if (cost < (costs.get(next) ?? Infinity)) {
        costs.set(next, cost);
        parents.set(next, current);
      }
    }
  }
  assert(
    Number.isFinite(costs.get(finish)),
    "Destination is disconnected from village paths",
  );
  const route = [];
  for (let node = finish; node !== undefined; node = parents.get(node))
    route.unshift(nodes.get(node));
  if (
    Math.hypot(
      route.at(-1)[0] - destination.x,
      route.at(-1)[1] - destination.y,
    ) > 1
  )
    route.push([destination.x, destination.y]);
  return route;
}
