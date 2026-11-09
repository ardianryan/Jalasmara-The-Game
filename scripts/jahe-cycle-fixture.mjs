import assert from "node:assert/strict";
import { isLandWalkable } from "../packages/shared/src/land.ts";
import { HOMESTEAD_DEFINITIONS } from "../packages/shared/src/index.ts";
import { physicalRoute } from "./plan06-physical-route.mjs";

export function deriveJaheCycleFixture(
  world,
  definitions = HOMESTEAD_DEFINITIONS,
) {
  const crop = definitions.crops.find((item) => item.id === "jahe");
  assert(
    crop &&
      crop.seedId === "benih_jahe" &&
      crop.growthDays === 4 &&
      crop.yield === 3,
    "This component acceptance requires the real four-day, three-yield jahe definition",
  );
  const plot = world.homestead.gardenPlots.find((item) => item.id === "plot_1");
  assert(plot && isLandWalkable(world.landMaps.hub, plot.interaction, 12));
  const interior = world.homestead.interior;
  const bedApproach = interior.routes
    .flat()
    .map(([x, y]) => ({ x, y }))
    .filter((point) => isLandWalkable(interior, point, 12))
    .sort(
      (a, b) =>
        Math.hypot(a.x - interior.bed.x, a.y - interior.bed.y) -
        Math.hypot(b.x - interior.bed.x, b.y - interior.bed.y),
    )[0];
  assert(
    bedApproach &&
      Math.hypot(
        bedApproach.x - interior.bed.x,
        bedApproach.y - interior.bed.y,
      ) < 110,
    "A legal authored approach must reach the actual bed interaction radius",
  );
  const wira = world.surface_hub.districts.find(
    (item) => item.npc === "Mbah Wira",
  );
  assert(wira, "Actual Wira district is required for ordinary pantry stock");
  return {
    crop,
    plot,
    bedApproach,
    wira,
    routes: {
      plotToDoor: physicalRoute(world, plot.interaction, world.homestead.door),
      entryToBed: physicalRoute(world, interior.entry, bedApproach, "home"),
      doorToWira: physicalRoute(world, world.homestead.door, wira),
    },
  };
}
