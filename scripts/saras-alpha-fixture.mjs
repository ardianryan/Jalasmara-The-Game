import assert from "node:assert/strict";
import { isLandWalkable, isLandSegmentWalkable } from "../packages/shared/src/land.ts";

export function deriveSarasFixture(world, minute = 1200, attentionAtWork = false) {
  assert(typeof attentionAtWork === "boolean" && (!attentionAtWork || minute === 1200), "Work attention variant retains the actual20:00 night calendar");
  assert([600, 1200].includes(minute), "Saras probes use separate actual morning/night calendar fixtures");
  const resident = world.surface_hub.residents.find((entry) => entry.id === "npc_saras");
  assert(resident?.name === "Saras" && resident.appearance === 5 && resident.cycle === 2,
    "The audit targets the existing Saras portrait path, not a substituted character");
  const phase = minute >= resident.activity.startMinute && minute < resident.activity.endMinute ? "work" : "rest";
  const [x, y] = resident.activity[attentionAtWork ? "work" : phase];
  const viewpoints = [{ x: x + 50, y: y + 35 }, attentionAtWork ? { x: x + 60, y: y + 10 } : phase === "rest" ? { x: x + 30, y: y + 60 } : { x: x - 50, y: y - 35 }];
  const quiet = attentionAtWork ? { ...viewpoints[0] } : { x: 800, y: 1000 };
  for (const point of [quiet, ...viewpoints])
    assert(isLandWalkable(world.landMaps.hub, point, 14), "Every alpha-audit fixture point must fit the actual authored body clearance");
  if (attentionAtWork) {
    assert(Math.hypot(quiet.x - resident.route[0][0], quiet.y - resident.route[0][1]) < 80,
      "The ordinary player-attention radius must already contain the real authored initial spawn");
    let previous = quiet, distance = 0;
    for (const point of viewpoints) {
      assert(isLandSegmentWalkable(world.landMaps.hub, previous, point, 14), "Short work-site viewpoints require a physically clear direct corridor");
      distance += Math.hypot(point.x - previous.x, point.y - previous.y);
      previous = point;
    }
    assert(distance <= 100, "Attention probe cannot repeat the long rest-site route");
  } else {
    for (const [routeX, routeY] of [...resident.route, ...resident.activity.commute, resident.activity.work, resident.activity.rest])
      assert(Math.hypot(quiet.x - routeX, quiet.y - routeY) > 175,
        "Quiet fixture cannot stall Saras's real commute through player attention");
  }
  for (const point of viewpoints) {
    const distance = Math.hypot(point.x - x, point.y - y);
    assert(distance > 55 && distance < 75,
      "Actual interaction must remain separated from the source portrait and inside its80unit radius");
    const board = world.homestead.permitBoard;
    assert(distance < Math.hypot(point.x - board.x, point.y - board.y),
      "The nearer Balai board cannot replace the intended actual Saras interaction");
  }
  return { name: resident.name, minute, phase, attentionAtWork, scheduledStation: resident.activity[phase], station: { x, y }, quiet, viewpoints,
    imageReviewRequired: true, historicalCauseEstablished: false };
}
