import type { LandPoint } from "./land.js";

export type GatewayRoute = {
  segment: readonly [LandPoint, LandPoint];
  fraction: number;
};

export type GatewaySpec = {
  id: string;
  label: string;
  elevation: number;
  route: GatewayRoute;
  roadSurfaceId: string;
  roadPolygon: readonly LandPoint[];
  colliderIds: readonly [string, string];
  baseSize?: readonly [number, number];
  edgeClearance?: number;
  halfSpan?: number;
};

/** Right/forward and dimensions use the physical Z-up ground plane, not map pixels. */
export type LandGateway = {
  id: string;
  label: string;
  elevation: number;
  route: GatewayRoute;
  roadSurfaceId: string;
  center: LandPoint;
  right: LandPoint;
  forward: LandPoint;
  roadSection: readonly [number, number];
  halfSpan: number;
  baseSize: readonly [number, number];
  edgeClearance: number;
  postCenters: readonly [LandPoint, LandPoint];
  postFootprints: readonly [LandPoint[], LandPoint[]];
  colliderIds: readonly [string, string];
  crossing: readonly [LandPoint, LandPoint];
};

const COS_TILT = Math.cos((55 * Math.PI) / 180);
const EPSILON = 1e-7;
const embed = ([x, y]: LandPoint): LandPoint => [x, -y / COS_TILT];
const unembed = ([x, y]: LandPoint): LandPoint => [x, -y * COS_TILT];
const cross = (a: LandPoint, b: LandPoint) => a[0] * b[1] - a[1] * b[0];
const subtract = (a: LandPoint, b: LandPoint): LandPoint => [a[0] - b[0], a[1] - b[1]];
const offset = (p: LandPoint, axis: LandPoint, distance: number): LandPoint => [
  p[0] + axis[0] * distance,
  p[1] + axis[1] * distance,
];

function finitePoint(point: LandPoint) {
  return point.length === 2 && point.every(Number.isFinite);
}

function roadSection(center: LandPoint, right: LandPoint, polygon: readonly LandPoint[]): [number, number] {
  const intersections: number[] = [];
  for (let index = 0; index < polygon.length; index++) {
    const start = embed(polygon[index]);
    const edge = subtract(embed(polygon[(index + 1) % polygon.length]), start);
    const denominator = cross(right, edge);
    if (Math.abs(denominator) < EPSILON) continue;
    const fromCenter = subtract(start, center);
    const fraction = cross(fromCenter, right) / denominator;
    if (fraction < -EPSILON || fraction > 1 + EPSILON) continue;
    const at = cross(fromCenter, edge) / denominator;
    if (!intersections.some((value) => Math.abs(value - at) < EPSILON)) intersections.push(at);
  }
  intersections.sort((a, b) => a - b);
  // Select the filled interval containing the route; concave polygons may cross more than twice.
  for (let index = 0; index + 1 < intersections.length; index += 2)
    if (intersections[index] < -EPSILON && intersections[index + 1] > EPSILON)
      return [intersections[index], intersections[index + 1]];
  throw new Error("Gateway route center must be inside its actual road polygon");
}

export function createLandGateway(spec: GatewaySpec): LandGateway {
  const { segment, fraction } = spec.route;
  const baseSize = spec.baseSize ?? [18, 18];
  const edgeClearance = spec.edgeClearance ?? 4;
  if (!spec.id || !spec.label || !spec.roadSurfaceId || !Number.isFinite(spec.elevation) ||
      !segment.every(finitePoint) || !Number.isFinite(fraction) || fraction < 0 || fraction > 1 ||
      spec.roadPolygon.length < 3 || !spec.roadPolygon.every(finitePoint) ||
      !baseSize.every((value) => Number.isFinite(value) && value > 0) ||
      !Number.isFinite(edgeClearance) || edgeClearance < 0 ||
      spec.colliderIds.some((id) => !id) || spec.colliderIds[0] === spec.colliderIds[1])
    throw new Error("Invalid gateway specification");
  const start = embed(segment[0]);
  const delta = subtract(embed(segment[1]), start);
  const length = Math.hypot(...delta);
  if (length < EPSILON) throw new Error("Gateway route segment has no length");
  const forward: LandPoint = [delta[0] / length, delta[1] / length];
  const right: LandPoint = [forward[1], -forward[0]];
  const origin = offset(start, forward, fraction * length);
  const section = roadSection(origin, right, spec.roadPolygon);
  const minimumHalfSpan = Math.max(-section[0], section[1]) + baseSize[0] / 2 + edgeClearance;
  const halfSpan = spec.halfSpan ?? minimumHalfSpan;
  if (!Number.isFinite(halfSpan) || halfSpan + EPSILON < minimumHalfSpan)
    throw new Error(`Gateway posts intrude into the road: halfSpan ${halfSpan} < ${minimumHalfSpan}`);
  const physicalPosts = [-halfSpan, halfSpan].map((distance) => offset(origin, right, distance));
  const footprints = physicalPosts.map((post) =>
    ([[-1, -1], [1, -1], [1, 1], [-1, 1]] as const).map(([x, y]) =>
      unembed(offset(offset(post, right, x * baseSize[0] / 2), forward, y * baseSize[1] / 2))),
  );
  return {
    id: spec.id,
    label: spec.label,
    elevation: spec.elevation,
    route: { segment: [segment[0], segment[1]], fraction },
    roadSurfaceId: spec.roadSurfaceId,
    center: unembed(origin), right, forward, roadSection: section,
    halfSpan, baseSize: [baseSize[0], baseSize[1]], edgeClearance,
    postCenters: [unembed(physicalPosts[0]), unembed(physicalPosts[1])],
    postFootprints: [footprints[0], footprints[1]],
    colliderIds: [spec.colliderIds[0], spec.colliderIds[1]],
    crossing: [unembed(offset(origin, forward, -36)), unembed(offset(origin, forward, 36))],
  };
}
