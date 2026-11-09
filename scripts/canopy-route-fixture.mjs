import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import { createHash } from "node:crypto";
import { readFileSync } from "node:fs";
import { physicalRoute } from "./plan06-physical-route.mjs";
import { isLandWalkable } from "../packages/shared/src/land.ts";

const dot = (a, b) => a.reduce((sum, value, axis) => sum + value * b[axis], 0);
const add = (...vectors) =>
  vectors[0].map((_, axis) => vectors.reduce((sum, v) => sum + v[axis], 0));
const scale = (v, factor) => v.map((value) => value * factor);
const radians = (degrees) => (degrees * Math.PI) / 180;
const cosineTilt = Math.cos(radians(55));

export function canopyBasis(view) {
  assert.equal(
    view?.azimuth,
    -45,
    "Current left-view canopy fixture requires actual azimuth−45",
  );
  assert.equal(
    view?.elevation,
    35,
    "Current canopy fixture requires actual elevation35",
  );
  const a = radians(view.azimuth),
    e = radians(view.elevation);
  return {
    forward: [
      -Math.sin(a) * Math.cos(e),
      Math.cos(a) * Math.cos(e),
      -Math.sin(e),
    ],
    right: [Math.cos(a), Math.sin(a), 0],
    up: [-Math.sin(a) * Math.sin(e), Math.cos(a) * Math.sin(e), Math.cos(e)],
  };
}

// Godot caches a nearest 64² mask from each 512² atlas cell. Accept a mask
// sample only when its entire source block is opaque, avoiding resize ambiguity.
export function readCanopyAlpha(
  atlasPath = new URL(
    "../client-godot/resources/art/land-foliage-v1.png",
    import.meta.url,
  ),
) {
  const filename = atlasPath instanceof URL ? atlasPath.pathname : atlasPath;
  const output = execFileSync(
    "python3",
    [
      "-c",
      String.raw`
import json,sys
from PIL import Image
im=Image.open(sys.argv[1]).convert("RGBA")
assert im.size==(1536,1024)
frames=[]
for frame in range(2):
    alpha=im.crop((frame*512,0,(frame+1)*512,512)).getchannel("A")
    frames.append([min(alpha.crop((x*8,y*8,x*8+8,y*8+8)).getdata())>90 for y in range(64) for x in range(64)])
print(json.dumps(frames))
`,
      filename,
    ],
    { maxBuffer: 100000 },
  );
  const renderer = readFileSync(
    new URL("../client-godot/scripts/land/LandWorld3D.gd", import.meta.url),
    "utf8",
  );
  const forest = renderer.slice(renderer.indexOf('elif area=="forest":'));
  const borders = forest.match(
    /for border_pt in \[([^\]]+)\]:\s+_tree\(\{"height3d":(\d+),"variant":"([^"]+)"\},Rect2\(border_pt-Vector2\((\d+),(\d+)\),Vector2\((\d+),(\d+)\)\),map_point\(border_pt,0\.0\)\)/,
  );
  assert(
    borders,
    "Renderer-only border crowns need an explicit supported source shape",
  );
  const landmarkTrees = [
    ...borders[1].matchAll(/Vector2\((-?\d+),(-?\d+)\)/g),
  ].map((match, index) => ({
    id: `renderer_forest_border_${index}`,
    x: Number(match[1]) - Number(borders[4]),
    y: Number(match[2]) - Number(borders[5]),
    width: Number(borders[6]),
    height: Number(borders[7]),
    height3d: Number(borders[2]),
    variant: borders[3],
  }));
  assert.equal(landmarkTrees.length, 4);
  return {
    landmarkTrees,
    rendererSha256: createHash("sha256").update(renderer).digest("hex"),
    sha256: createHash("sha256").update(readFileSync(filename)).digest("hex"),
    frames: JSON.parse(output),
  };
}

function crowns(map, basis, alpha) {
  assert.equal(map.id, "forest");
  assert.equal(map.stairs.length, 0);
  assert(
    map.surfaces.every((surface) => surface.elevation === 0),
    "Fixture must account for new terrain height before use",
  );
  return [
    ...map.obstacles.filter((entry) => entry.kind === "tree"),
    ...alpha.landmarkTrees,
  ].map((tree, index) => {
    const palm = tree.variant === "palm",
      width = palm ? tree.height3d * 1.35 : 210 + tree.height3d * 0.25;
    const foot = [
      tree.x + tree.width / 2,
      -(tree.y + tree.height / 2) / cosineTilt,
      (tree.elevation ?? 0) * 48,
    ];
    return {
      id: tree.id,
      index,
      width,
      frame: palm ? 1 : 0,
      center: add(
        foot,
        [Math.sin(1.2) * 14, 5, tree.height3d],
        scale(basis.up, width * 0.08),
      ),
    };
  });
}

export function predictedCanopy(map, position, view, alpha, sway = 0) {
  const basis = canopyBasis(view),
    feet = [position.x, -position.y / cosineTilt, 0];
  const body = add(feet, scale(basis.up, 48), scale(basis.forward, -8));
  return crowns(map, basis, alpha).flatMap((crown) => {
    const relative = add(body, scale(add(crown.center, [sway, 0, 0]), -1));
    const local = [dot(relative, basis.right), -dot(relative, basis.up)],
      depth = dot(relative, basis.forward);
    if (
      depth <= 12 ||
      Math.abs(local[0]) >= crown.width / 2 + 28 ||
      Math.abs(local[1]) >= crown.width / 2 + 48
    )
      return [];
    const opaque = [
      [0, -28],
      [-15, 0],
      [15, 0],
      [0, 27],
    ].some((offset) => {
      const uv = local.map(
        (value, axis) => (value + offset[axis]) / crown.width + 0.5,
      );
      return (
        uv.every((value) => value >= 0 && value < 1) &&
        alpha.frames[crown.frame][
          Math.floor(uv[1] * 64) * 64 + Math.floor(uv[0] * 64)
        ]
      );
    });
    return opaque ? [{ id: crown.id, index: crown.index, local, depth }] : [];
  });
}

export function deriveCanopyTarget(world, from, view, alpha) {
  const map = world.landMaps.forest,
    basis = canopyBasis(view),
    candidates = [];
  for (const crown of crowns(map, basis, alpha)) {
    for (const screenX of [-30, 0, 30])
      for (const screenY of [-25, 0, 25]) {
        const body = add(
          crown.center,
          scale(basis.right, screenX),
          scale(basis.up, -screenY),
        );
        const distance = (48 * basis.up[2] - body[2]) / basis.forward[2];
        const feet = add(
          body,
          scale(basis.up, -48),
          scale(basis.forward, distance),
        );
        const target = {
          x: Math.round(feet[0]),
          y: Math.round(-feet[1] * cosineTilt),
        };
        if (!isLandWalkable(map, target, 12)) continue;
        const samples = [];
        for (const dx of [-5, 0, 5])
          for (const dy of [-5, 0, 5])
            for (const sway of [-3, 0, 3]) {
              samples.push(
                predictedCanopy(
                  map,
                  { x: target.x + dx, y: target.y + dy },
                  view,
                  alpha,
                  sway,
                ),
              );
            }
        if (
          !samples.every(
            (active) =>
              active.some((entry) => entry.id === crown.id) &&
              active.length < crowns(map, basis, alpha).length / 4,
          )
        )
          continue;
        let route;
        try {
          route = physicalRoute(world, from, target, "forest");
        } catch {
          continue;
        }
        const length = [from, ...route.map(([x, y]) => ({ x, y }))]
          .slice(1)
          .reduce((sum, value, index) => {
            const previous =
              index === 0
                ? from
                : { x: route[index - 1][0], y: route[index - 1][1] };
            return sum + Math.hypot(value.x - previous.x, value.y - previous.y);
          }, 0);
        candidates.push({
          target,
          route,
          length,
          treeId: crown.id,
          crownIndex: crown.index,
          alphaSha256: alpha.sha256,
          rendererSha256: alpha.rendererSha256,
          crowns: crowns(map, basis, alpha).length,
          centerPrediction: predictedCanopy(map, target, view, alpha),
          maxPredictedReveals: Math.max(
            ...samples.map((active) => active.length),
          ),
          samples: samples.length,
        });
      }
  }
  assert(
    candidates.length,
    "No alpha-backed physically reachable canopy occlusion target fits this world/view",
  );
  return candidates.sort((a, b) => a.length - b.length)[0];
}
