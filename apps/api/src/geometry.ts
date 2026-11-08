export type Point = { x: number; y: number };
export type Contour = readonly (readonly [number, number])[];

export function distanceToEdge(
  point: Point,
  start: readonly [number, number],
  end: readonly [number, number],
) {
  const dx = end[0] - start[0];
  const dy = end[1] - start[1];
  const lengthSquared = dx * dx + dy * dy;
  const t =
    lengthSquared === 0
      ? 0
      : Math.max(
          0,
          Math.min(
            1,
            ((point.x - start[0]) * dx + (point.y - start[1]) * dy) /
              lengthSquared,
          ),
        );
  return Math.hypot(point.x - start[0] - t * dx, point.y - start[1] - t * dy);
}

export function blockedByContours(
  point: Point,
  contours: readonly Contour[],
  clearance = 12,
) {
  for (const polygon of contours) {
    if (polygon.length < 3) continue;
    let inside = false;
    for (let i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      const a = polygon[j],
        b = polygon[i];
      if (distanceToEdge(point, a, b) <= clearance) return true;
      if (
        a[1] > point.y !== b[1] > point.y &&
        point.x < ((b[0] - a[0]) * (point.y - a[1])) / (b[1] - a[1]) + a[0]
      )
        inside = !inside;
    }
    if (inside) return true;
  }
  return false;
}
