import assert from "node:assert/strict";
import {
  isLandWalkable,
  isLandSegmentWalkable,
} from "../packages/shared/src/land.ts";
import { physicalRoute } from "./plan06-physical-route.mjs";

export function deriveLeftForestFixture(world) {
  const map = world.landMaps.forest;
  assert(Number.isSafeInteger(map.layoutVersion));
  const bridge = map.bridges.find((entry) => entry.id === "bridge_upper");
  assert(
    bridge?.path.length === 2,
    "Upper bridge must have two authored endpoints",
  );
  const [before, after] = bridge.path;
  assert(Math.hypot(after[0] - before[0], after[1] - before[1]) > 250);
  assert(
    isLandSegmentWalkable(
      map,
      { x: before[0], y: before[1] },
      { x: after[0], y: after[1] },
    ),
    "Upper bridge crossing must remain physically walkable",
  );
  const route = map.routes.find((points) =>
    points.some(
      (point, index) =>
        point[0] === before[0] &&
        point[1] === before[1] &&
        points[index + 1]?.[0] === after[0] &&
        points[index + 1]?.[1] === after[1],
    ),
  );
  assert(route, "Upper bridge must belong to the authored forest route");
  const index = route.findIndex(
    (point) => point[0] === before[0] && point[1] === before[1],
  );
  const joystickClearance = 55;
  const approach = route
    .slice(0, index)
    .reverse()
    .find(([x, y]) => {
      if (
        Math.hypot(x - before[0], y - before[1]) > 180 ||
        !isLandWalkable(map, { x, y }, 12)
      )
        return false;
      return Array.from({ length: 16 }, (_, step) => ({
        x: x + Math.cos((step * Math.PI) / 8) * joystickClearance,
        y: y + Math.sin((step * Math.PI) / 8) * joystickClearance,
      })).every(
        (point) =>
          isLandWalkable(map, point, 12) &&
          isLandSegmentWalkable(map, { x, y }, point),
      );
    });
  assert(
    approach,
    "No nearby authored upper-bridge approach has joystick clearance",
  );
  const point = { x: approach[0], y: approach[1] };
  const path = physicalRoute(
    world,
    point,
    { x: before[0], y: before[1] },
    "forest",
  );
  return {
    area: "forest",
    layoutVersion: map.layoutVersion,
    bridgeId: bridge.id,
    point,
    bridgePath: bridge.path,
    route: path,
    joystickClearance,
  };
}
