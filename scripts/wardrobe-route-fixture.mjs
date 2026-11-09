import assert from "node:assert/strict";
import {
  isLandWalkable,
  isLandSegmentWalkable,
} from "../packages/shared/src/land.ts";
import { physicalRoute } from "./plan06-physical-route.mjs";

export function deriveWardrobeFixture(world) {
  const map = world.landMaps.hub;
  const posts = map.obstacles.filter(
    (entry) => entry.variant === "changing_booth",
  );
  assert.equal(
    posts.length,
    2,
    "Changing booth requires both authored supports",
  );
  const centers = posts
    .map((entry) => ({
      x:
        entry.footprint.reduce((sum, point) => sum + point[0], 0) /
        entry.footprint.length,
      y:
        entry.footprint.reduce((sum, point) => sum + point[1], 0) /
        entry.footprint.length,
    }))
    .sort((a, b) => a.y - b.y);
  assert(Math.abs(centers[0].x - centers[1].x) < 1);
  const curtain = { x: centers[0].x, y: (centers[0].y + centers[1].y) / 2 };
  const daily = { x: curtain.x - 70, y: curtain.y };
  const diving = { x: curtain.x + 60, y: curtain.y };
  // Fail if the authored booth moves beyond the current production hysteresis.
  assert(
    daily.x < 1390 &&
      diving.x > 1450 &&
      curtain.x > 1390 &&
      curtain.x < 1450 &&
      curtain.y > 1230,
  );
  for (const point of [daily, curtain, diving, world.hub.divePoint])
    assert(
      isLandWalkable(map, point, 12),
      "Wardrobe sample requires an actual clear dock floor",
    );
  assert(
    isLandSegmentWalkable(map, daily, diving),
    "Changing route must pass through the real booth opening",
  );
  return {
    area: "hub",
    layoutVersion: map.layoutVersion,
    postIds: posts.map((entry) => entry.id),
    daily,
    curtain,
    diving,
    divePoint: world.hub.divePoint,
    diveRoute: physicalRoute(world, diving, world.hub.divePoint, "hub"),
    initialStory: { day: 2, stage: "dive", coins: 200, inventory: [] },
  };
}
