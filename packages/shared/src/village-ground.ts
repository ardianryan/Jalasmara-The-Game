import type { LandMap, LandPoint, LandSurface } from "./land.js";

const EPSILON = 1e-7;
const PREFIX = "village_dirt_";
const WIDTH = 72;
const COURTS = new Set(["lower_court", "upper_court"]);
const area = (polygon: readonly LandPoint[]) =>
  polygon.reduce((sum, a, index) => {
    const b = polygon[(index + 1) % polygon.length];
    return sum + a[0] * b[1] - b[0] * a[1];
  }, 0) / 2;
const cross = (a: LandPoint, b: LandPoint, p: LandPoint) =>
  (b[0] - a[0]) * (p[1] - a[1]) - (b[1] - a[1]) * (p[0] - a[0]);

function convex(polygon: readonly LandPoint[]) {
  if (
    polygon.length < 3 ||
    polygon.some((point) => point.length !== 2 || !point.every(Number.isFinite))
  )
    throw new Error("Village ground requires finite convex floor polygons");
  const orientation = Math.sign(area(polygon));
  if (
    !orientation ||
    polygon.some(
      (a, index) =>
        cross(
          a,
          polygon[(index + 1) % polygon.length],
          polygon[(index + 2) % polygon.length],
        ) *
          orientation <
        -EPSILON,
    )
  )
    throw new Error(
      "Village ground requires non-degenerate convex floor polygons",
    );
  return orientation;
}

function halfPlane(
  subject: readonly LandPoint[],
  a: LandPoint,
  b: LandPoint,
  orientation: number,
  inside: boolean,
): LandPoint[] {
  const result: LandPoint[] = [];
  if (!subject.length) return result;
  const distance = (p: LandPoint) =>
    cross(a, b, p) * orientation * (inside ? 1 : -1);
  for (let index = 0; index < subject.length; index++) {
    const start = subject[index],
      end = subject[(index + 1) % subject.length];
    const d0 = distance(start),
      d1 = distance(end),
      keep0 = d0 >= -EPSILON,
      keep1 = d1 >= -EPSILON;
    if (keep0) result.push([start[0], start[1]]);
    if (keep0 !== keep1) {
      const t = d0 / (d0 - d1);
      result.push([
        start[0] + (end[0] - start[0]) * t,
        start[1] + (end[1] - start[1]) * t,
      ]);
    }
  }
  return result.filter((point, index) => {
    const previous = result[(index + result.length - 1) % result.length];
    return Math.hypot(point[0] - previous[0], point[1] - previous[1]) > EPSILON;
  });
}

function clip(
  subject: readonly LandPoint[],
  boundary: readonly LandPoint[],
): LandPoint[] {
  const orientation = convex(boundary);
  let result = [...subject];
  for (let index = 0; index < boundary.length && result.length; index++)
    result = halfPlane(
      result,
      boundary[index],
      boundary[(index + 1) % boundary.length],
      orientation,
      true,
    );
  return result;
}

function subtract(
  subject: LandPoint[],
  boundary: readonly LandPoint[],
): LandPoint[][] {
  const orientation = convex(boundary),
    outside: LandPoint[][] = [];
  const overlap = clip(subject, boundary);
  if (overlap.length < 3 || Math.abs(area(overlap)) <= EPSILON)
    return [subject];
  let remainder = subject;
  for (let index = 0; index < boundary.length && remainder.length; index++) {
    const a = boundary[index],
      b = boundary[(index + 1) % boundary.length];
    const piece = halfPlane(remainder, a, b, orientation, false);
    if (piece.length >= 3 && Math.abs(area(piece)) > 1) outside.push(piece);
    remainder = halfPlane(remainder, a, b, orientation, true);
  }
  return outside;
}

function routePaint(map: LandMap): { id: string; polygon: LandPoint[] }[] {
  const paint: { id: string; polygon: LandPoint[] }[] = [];
  const segments = new Set<string>(),
    joins = new Set<string>();
  for (const route of map.routes) {
    for (let index = 1; index < route.length; index++) {
      const a = route[index - 1],
        b = route[index],
        length = Math.hypot(b[0] - a[0], b[1] - a[1]);
      if (length < EPSILON) continue;
      const key = [a.join(","), b.join(",")].sort().join(";");
      if (segments.has(key)) continue;
      segments.add(key);
      const nx = ((-(b[1] - a[1]) / length) * WIDTH) / 2,
        ny = (((b[0] - a[0]) / length) * WIDTH) / 2;
      paint.push({
        id: `segment_${segments.size - 1}`,
        polygon: [
          [a[0] + nx, a[1] + ny],
          [a[0] - nx, a[1] - ny],
          [b[0] - nx, b[1] - ny],
          [b[0] + nx, b[1] + ny],
        ],
      });
      for (const point of [a, b]) {
        if (joins.has(point.join(","))) continue;
        joins.add(point.join(","));
        paint.push({
          id: `join_${joins.size - 1}`,
          polygon: Array.from({ length: 8 }, (_, corner): LandPoint => [
            point[0] + (Math.cos((corner * Math.PI) / 4) * WIDTH) / 2,
            point[1] + (Math.sin((corner * Math.PI) / 4) * WIDTH) / 2,
          ]),
        });
      }
    }
  }
  return paint;
}

/** Paint changes material only; every added surface is excluded from authoritative floor union. */
export function decorateVillageGround(map: LandMap): LandMap {
  const result = structuredClone(map);
  if (map.id !== "hub") return result;
  result.surfaces = result.surfaces.filter(
    (surface) => !surface.id.startsWith(PREFIX),
  );
  const courts = result.surfaces.filter((surface) => COURTS.has(surface.id));
  const protectedSurfaces = result.surfaces.filter(
    (surface) =>
      !COURTS.has(surface.id) &&
      (Boolean(surface.connectorId) ||
        ["stone", "wood", "dock", "bridge"].includes(surface.material)),
  );
  const gardenFootprints = result.obstacles
    .filter((obstacle) => obstacle.kind === "garden")
    .map((obstacle) => obstacle.footprint);
  const paths = routePaint(result),
    additions: LandSurface[] = [];
  for (const court of courts) {
    convex(court.polygon);
    court.material = "grass";
    for (const path of paths) {
      const clipped = clip(path.polygon, court.polygon);
      if (clipped.length < 3 || Math.abs(area(clipped)) <= 1) continue;
      let pieces = [clipped];
      for (const boundary of [
        ...protectedSurfaces.map((surface) => surface.polygon),
        ...gardenFootprints,
      ]) {
        pieces = pieces.flatMap((piece) => subtract(piece, boundary));
        if (!pieces.length) break;
        if (pieces.length > 256)
          throw new Error(
            "Village ground paint exceeded its bounded clipping budget",
          );
      }
      for (const [index, polygon] of pieces.entries())
        additions.push({
          id: `${PREFIX}${court.id}_${path.id}_${index}`,
          polygon,
          material: "dirt",
          elevation: court.elevation,
          priority: 4,
          walkable: false,
        });
    }
  }
  if (additions.length > 512)
    throw new Error("Village ground paint exceeded its bounded surface budget");
  result.surfaces.push(...additions);
  return result;
}
