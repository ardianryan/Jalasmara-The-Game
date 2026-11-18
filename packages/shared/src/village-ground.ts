import type { LandMap, LandPoint, LandSurface } from "./land.js";

const EPSILON = 1e-7;
const PREFIX = "village_dirt_";
const TREAD_PREFIX = "village_stone_tread_";
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

const samePoint = (a: LandPoint, b: LandPoint) =>
  Math.hypot(a[0] - b[0], a[1] - b[1]) < EPSILON;
const LOWER_SPINE: LandPoint[] = [[600, 950], [1120, 1000], [1370, 950], [1600, 950]];
const isLowerSpine = (route: readonly LandPoint[]) =>
  route.length === LOWER_SPINE.length &&
  LOWER_SPINE.every((point, index) => samePoint(route[index], point));
const isCentralStairApproach = (a: LandPoint, b: LandPoint) =>
  (samePoint(a, [1370, 950]) && samePoint(b, [1370, 815])) ||
  (samePoint(b, [1370, 950]) && samePoint(a, [1370, 815]));

function joinedSpine(route: readonly LandPoint[]): LandPoint[] {
  const centerline: LandPoint[] = [route[0]];
  for (let index = 1; index < route.length - 1; index++) {
    const a = route[index - 1],
      corner = route[index],
      b = route[index + 1];
    const beforeLength = Math.hypot(corner[0] - a[0], corner[1] - a[1]);
    const afterLength = Math.hypot(b[0] - corner[0], b[1] - corner[1]);
    const radius = Math.min(24, beforeLength / 4, afterLength / 4);
    const before: LandPoint = [
      corner[0] - ((corner[0] - a[0]) / beforeLength) * radius,
      corner[1] - ((corner[1] - a[1]) / beforeLength) * radius,
    ];
    const after: LandPoint = [
      corner[0] + ((b[0] - corner[0]) / afterLength) * radius,
      corner[1] + ((b[1] - corner[1]) / afterLength) * radius,
    ];
    centerline.push(before);
    for (const t of [0.25, 0.5, 0.75, 1])
      centerline.push([
        (1 - t) ** 2 * before[0] + 2 * (1 - t) * t * corner[0] + t ** 2 * after[0],
        (1 - t) ** 2 * before[1] + 2 * (1 - t) * t * corner[1] + t ** 2 * after[1],
      ]);
  }
  centerline.push(route[route.length - 1]);
  const side = (sign: number): LandPoint[] =>
    centerline.map((point, index) => {
      const a = centerline[Math.max(0, index - 1)];
      const b = centerline[Math.min(centerline.length - 1, index + 1)];
      const length = Math.hypot(b[0] - a[0], b[1] - a[1]);
      return [
        point[0] - ((b[1] - a[1]) / length) * (WIDTH / 2) * sign,
        point[1] + ((b[0] - a[0]) / length) * (WIDTH / 2) * sign,
      ];
    });
  return [...side(1), ...side(-1).reverse()];
}

function centralStairTreads(): LandSurface[] {
  return [838, 862, 886, 908].map((y, index) => ({
    id: `${TREAD_PREFIX}${index}`,
    polygon: [
      [1340 + (index % 2) * 3, y - 8],
      [1399 - (index % 2) * 2, y - 9],
      [1405 - (index % 2) * 2, y - 3],
      [1401, y + 8],
      [1340, y + 9],
      [1335 + (index % 2) * 2, y + 2],
    ],
    material: "stone",
    elevation: 1,
    priority: 4,
    walkable: false,
  }));
}

function routePaint(map: LandMap): { id: string; polygon: LandPoint[] }[] {
  const paint: { id: string; polygon: LandPoint[] }[] = [];
  const segments = new Set<string>(),
    joins = new Set<string>();
  for (const route of map.routes) {
    if (isLowerSpine(route)) {
      paint.push({ id: "joined_lower_spine", polygon: joinedSpine(route) });
      continue;
    }
    for (let index = 1; index < route.length; index++) {
      const a = route[index - 1],
        b = route[index],
        length = Math.hypot(b[0] - a[0], b[1] - a[1]);
      if (isCentralStairApproach(a, b)) continue;
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
        if (
          samePoint(point, [1370, 950]) ||
          samePoint(point, [1370, 815]) ||
          samePoint(point, [1370, 735])
        ) continue;
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
    (surface) => !surface.id.startsWith(PREFIX) && !surface.id.startsWith(TREAD_PREFIX),
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
      for (const [index, polygon] of pieces.entries()) {
        if (path.id === "joined_lower_spine" && Math.abs(area(polygon)) < 500)
          continue;
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
  }
  if (additions.length > 512)
    throw new Error("Village ground paint exceeded its bounded surface budget");
  result.surfaces.push(...additions);
  if (
    result.routes.some(isLowerSpine) &&
    result.stairs.some((stair) => stair.id === "central_stone_steps") &&
    courts.some((court) => court.id === "lower_court")
  )
    result.surfaces.push(...centralStairTreads());
  return result;
}
