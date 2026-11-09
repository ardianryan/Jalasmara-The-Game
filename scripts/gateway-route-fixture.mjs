import assert from "node:assert/strict";
import {
  isLandWalkable,
  isLandSegmentWalkable,
  landDistanceToSegment,
  landPointInPolygon,
} from "../packages/shared/src/land.ts";
import { physicalRoute } from "./plan06-physical-route.mjs";
const cosine = Math.cos((55 * Math.PI) / 180);
const physical = (point) => [point.x, -point.y / cosine];
const logical = ([x, y]) => ({ x, y: -y * cosine });
const point = ([x, y]) => ({ x, y });
const dot = (a, b) => a[0] * b[0] + a[1] * b[1];

export function gatewayCoordinates(gate, at) {
  const center = physical(point(gate.center)),
    position = physical(at),
    delta = position.map((value, index) => value - center[index]);
  return { lateral: dot(delta, gate.right), along: dot(delta, gate.forward) };
}

export function validateGatewayRoute(world, area, from) {
  const map = world.landMaps[area],
    gate = map?.gateways?.[0];
  assert(
    gate?.crossing?.length === 2 &&
      gate.postCenters?.length === 2 &&
      gate.postFootprints?.length === 2,
    "Actual gateway frame and posts are required",
  );
  assert(
    gate.right.length === 2 &&
      gate.forward.length === 2 &&
      [...gate.right, ...gate.forward].every(Number.isFinite),
  );
  assert(Math.abs(dot(gate.right, gate.forward)) < 1e-6);
  assert(
    Math.abs(Math.hypot(...gate.right) - 1) < 1e-6 &&
      Math.abs(Math.hypot(...gate.forward) - 1) < 1e-6,
  );
  const [before, after] = gate.crossing.map(point);
  const a = gatewayCoordinates(gate, before),
    b = gatewayCoordinates(gate, after);
  assert(
    a.along < -35.9 &&
      b.along > 35.9 &&
      Math.abs(a.lateral) < 1e-6 &&
      Math.abs(b.lateral) < 1e-6,
  );
  assert(
    isLandSegmentWalkable(map, before, after, 13) &&
      isLandSegmentWalkable(map, after, before, 13),
  );
  assert(isLandWalkable(map, point(gate.center), 13));
  for (const [index, center] of gate.postCenters.entries()) {
    assert(!isLandWalkable(map, point(center), 0));
    const obstacle = map.obstacles.find(
      (entry) => entry.id === gate.colliderIds[index],
    );
    assert(
      obstacle &&
        gate.postFootprints[index].every((corner) =>
          landPointInPolygon(point(corner), obstacle.footprint),
        ),
    );
  }
  return {
    gate,
    approach: physicalRoute(world, from, before, area),
    before,
    after,
  };
}

export function deriveGatewayPostProbe(world, area, gate, from, index = 0) {
  assert([0, 1].includes(index));
  const map = world.landMaps[area],
    center = physical(point(gate.postCenters[index])),
    sign = index === 0 ? 1 : -1;
  for (let offset = 1; offset < gate.halfSpan - 8; offset++) {
    const nearest = logical(
      center.map((value, axis) => value + gate.right[axis] * sign * offset),
    );
    const approach = logical(
      center.map(
        (value, axis) => value + gate.right[axis] * sign * (offset + 8),
      ),
    );
    if (!isLandWalkable(map, nearest, 13) || !isLandWalkable(map, approach, 13))
      continue;
    const route = physicalRoute(world, from, approach, area);
    return {
      index,
      target: point(gate.postCenters[index]),
      approach,
      route,
      physicalOffset: offset + 8,
    };
  }
  assert.fail(
    "No body-clear inner gateway post approach fits the real collider gap",
  );
}

export function gatewayPostClearance(gate, index, at) {
  const footprint = gate.postFootprints[index];
  assert(
    !landPointInPolygon(at, footprint),
    "Player center entered the real gateway post",
  );
  return Math.min(
    ...footprint.map((start, i) =>
      landDistanceToSegment(at, start, footprint[(i + 1) % footprint.length]),
    ),
  );
}

export function validateGatewayMeshes(gate, record) {
  assert(
    record?.meshes?.length >= 7,
    "Actual emitted gate meshes are required",
  );
  for (const field of [
    "center",
    "postCenters",
    "postFootprints",
    "crossing",
    "colliderIds",
  ])
    assert.deepEqual(record[field], gate[field]);
  const elevation = gate.elevation * 48,
    tangent = Math.tan((55 * Math.PI) / 180),
    center = physical(point(gate.center));
  const origin = [center[0], center[1] - elevation * tangent, elevation];
  for (const mesh of record.meshes) {
    assert(
      mesh.vertices?.length === 8 &&
        mesh.vertices.flat().every(Number.isFinite),
    );
    assert(
      Math.abs(Math.hypot(...mesh.right) - 1) < 1e-5 &&
        Math.abs(Math.hypot(...mesh.forward) - 1) < 1e-5,
    );
    assert(Math.abs(mesh.right[2]) < 1e-5 && Math.abs(mesh.forward[2]) < 1e-5);
    assert(
      dot(mesh.right, gate.right) > 0.99999 &&
        dot(mesh.forward, gate.forward) > 0.99999,
      "Actual box axes must follow the road frame",
    );
  }
  const bases = record.meshes.filter(
    (mesh) => mesh.label === `${gate.label}_Base`,
  );
  assert.equal(bases.length, 2);
  for (const [index, mesh] of bases.entries()) {
    const p = physical(point(gate.postCenters[index]));
    assert(
      Math.hypot(
        mesh.center[0] - p[0],
        mesh.center[1] - (p[1] - elevation * tangent),
        mesh.center[2] - (elevation + 10),
      ) < 0.003,
    );
    const bottom = mesh.vertices.filter(
      (vertex) => Math.abs(vertex[2] - elevation) < 0.01,
    );
    assert.equal(bottom.length, 4);
    for (const vertex of bottom) {
      const at = {
          x: vertex[0],
          y: -(vertex[1] + elevation * tangent) * cosine,
        },
        footprint = gate.postFootprints[index];
      assert(
        landPointInPolygon(at, footprint) ||
          Math.min(
            ...footprint.map((a, i) =>
              landDistanceToSegment(
                at,
                a,
                footprint[(i + 1) % footprint.length],
              ),
            ),
          ) < 0.01,
        "Actual base corner must remain inside its post collider",
      );
    }
  }
  const roof = record.meshes.find(
    (mesh) => mesh.label === `${gate.label}_LintelRoof`,
  );
  assert(
    roof &&
      Math.hypot(
        ...roof.center.map(
          (value, index) => value - origin[index] - (index === 2 ? 122 : 0),
        ),
      ) < 0.003,
    "Actual roof must be centered above this road frame",
  );
  return {
    gateId: gate.id,
    baseCount: bases.length,
    emittedBoxCount: record.meshes.length,
    roofVertices: roof.vertices,
  };
}
