import assert from "node:assert/strict";
import { isLandWalkable } from "../packages/shared/src/land.ts";
import { physicalRoute } from "./plan06-physical-route.mjs";
import { canopyBasis } from "./canopy-route-fixture.mjs";
import { deriveWardrobeFixture } from "./wardrobe-route-fixture.mjs";

const dot = (a, b) => a.reduce((sum, value, i) => sum + value * b[i], 0);
const cosTilt = Math.cos((55 * Math.PI) / 180);
function hull(points) {
  const sorted = [...points].sort((a, b) => a[0] - b[0] || a[1] - b[1]);
  const cross = (a, b, c) =>
    (b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0]);
  const half = (values) => {
    const result = [];
    for (const point of values) {
      while (
        result.length >= 2 &&
        cross(result.at(-2), result.at(-1), point) <= 0
      )
        result.pop();
      result.push(point);
    }
    return result;
  };
  return [...half(sorted).slice(0, -1), ...half(sorted.reverse()).slice(0, -1)];
}
function separated(a, b) {
  return [a, b].some((polygon) =>
    polygon.some((p, i) => {
      const next = polygon[(i + 1) % polygon.length],
        axis = [p[1] - next[1], next[0] - p[0]];
      const first = a.map((point) => dot(point, axis)),
        second = b.map((point) => dot(point, axis));
      return (
        Math.max(...first) < Math.min(...second) ||
        Math.max(...second) < Math.min(...first)
      );
    }),
  );
}

export function wardrobeBoothProjection(world, view, source) {
  // Stop if the production geometry changes; this is a bounded model of its
  // emitted shade, folded curtains and posts, not a universal occlusion engine.
  for (const text of [
    "camera_azimuth := -45.0",
    "camera_elevation := 35.0",
    "Vector2(1430,1200)",
    "Vector2(1430,1380)",
    "Vector3(-38,-canopy_half,2)",
    "Vector3(0,0,118)",
    "76,45",
    "sin(strip*PI*.75)*2.2",
  ])
    assert(
      source.includes(text),
      "Changing-booth projection source drift: " + text,
    );
  const basis = canopyBasis(view);
  const project = (point) => [dot(point, basis.right), -dot(point, basis.up)];
  const fixture = deriveWardrobeFixture(world);
  const x = fixture.curtain.x,
    north = fixture.curtain.y - 90,
    south = fixture.curtain.y + 90;
  const box = (xs, ys, zs) =>
    hull(
      xs.flatMap((x) => ys.flatMap((y) => zs.map((z) => project([x, y, z])))),
    );
  const shapes = [
    box([x - 38, x + 38], [-north / cosTilt, -south / cosTilt], [120]),
  ];
  for (const [logicalY, sign] of [
    [north, 1],
    [south, -1],
  ]) {
    const centerY = -logicalY / cosTilt + sign * 4;
    shapes.push(
      box([x - 38, x + 38], [centerY - 2.2, centerY + 2.2], [73, 118]),
    );
    shapes.push(
      box(
        [x - 6.5, x + 6.5],
        [
          -logicalY / cosTilt - 6.5 / cosTilt,
          -logicalY / cosTilt + 6.5 / cosTilt,
        ],
        [0, 126],
      ),
    );
  }
  return { project, shapes };
}

export function projectedWardrobeClear(world, point, view, source) {
  const { project, shapes } = wardrobeBoothProjection(world, view, source);
  const foot = project([point.x, -point.y / cosTilt, 0]);
  // Conservative idle body+gear envelope including a navigation margin. Native
  // or browser pixels must still confirm actual pose and other occluders.
  const rectangle = [
    [-48, -96],
    [48, -96],
    [48, 12],
    [-48, 12],
  ].map(([x, y]) => [x + foot[0], y + foot[1]]);
  return shapes.every((shape) => separated(shape, rectangle));
}

export function deriveWardrobeVisibilityFixture(world, view, source) {
  const booth = deriveWardrobeFixture(world);
  const dock = world.landMaps.hub.surfaces.find(
    (entry) => entry.id === "dock_main",
  );
  assert(dock);
  const point = {
    x: Math.max(...dock.polygon.map(([x]) => x)) - 14,
    y: Math.max(...dock.polygon.map(([, y]) => y)) - 14,
  };
  assert(isLandWalkable(world.landMaps.hub, point, 12));
  assert(
    projectedWardrobeClear(world, point, view, source),
    "No conservative unobscured sample at the legal dock corner",
  );
  return {
    point,
    route: physicalRoute(world, booth.diving, point, "hub"),
    view,
    modelScope: "projected-booth-geometry-only-needs-actual-image-review",
    envelope: [-48, -96, 48, 12],
  };
}
