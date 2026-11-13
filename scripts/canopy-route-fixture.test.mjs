import assert from "node:assert/strict";
import test from "node:test";
import { readFileSync } from "node:fs";
import { WORLD } from "../packages/shared/src/world.ts";
import {
  isLandWalkable,
  isLandSegmentWalkable,
} from "../packages/shared/src/land.ts";
import {
  canopyBasis,
  readCanopyAlpha,
  predictedCanopy,
  deriveCanopyTarget,
} from "./canopy-route-fixture.mjs";
const view = { azimuth: -45, elevation: 35 };
const map = WORLD.landMaps.forest;
const alpha = readCanopyAlpha();
const fixture = deriveCanopyTarget(WORLD, map.spawn, view, alpha);

test("current left camera and original foliage alpha explain the old unobstructed target", () => {
  assert.deepEqual(predictedCanopy(map, { x: 350, y: 1250 }, view, alpha), []);
  const { forward, right, up } = canopyBasis(view);
  const dot = (a, b) =>
    a.reduce((sum, value, index) => sum + value * b[index], 0);
  for (const vector of [forward, right, up])
    assert(Math.abs(Math.hypot(...vector) - 1) < 1e-12);
  assert(
    Math.abs(dot(forward, right)) < 1e-12 &&
      Math.abs(dot(forward, up)) < 1e-12 &&
      Math.abs(dot(up, right)) < 1e-12,
  );
});

test("derived crown really covers an opaque source block behind its billboard and has a legal input route", () => {
  assert.equal(fixture.samples, 27);
  assert.equal(alpha.landmarkTrees.length, 4);
  assert.equal(
    fixture.crowns,
    map.obstacles.filter((entry) => entry.kind === "tree").length + 4,
  );
  assert(
    fixture.centerPrediction.some(
      (entry) => entry.id === fixture.treeId && entry.depth > 12,
    ),
  );
  assert(
    fixture.maxPredictedReveals > 0 &&
      fixture.maxPredictedReveals <
        map.obstacles.filter((entry) => entry.kind === "tree").length / 4,
  );
  assert(isLandWalkable(map, fixture.target, 12));
  let previous = map.spawn;
  for (const [x, y] of fixture.route) {
    assert(isLandSegmentWalkable(map, previous, { x, y }));
    previous = { x, y };
  }
  assert.deepEqual(previous, fixture.target);
  for (const dx of [-5, 0, 5])
    for (const dy of [-5, 0, 5])
      for (const sway of [-3, 0, 3]) {
        assert(
          predictedCanopy(
            map,
            { x: fixture.target.x + dx, y: fixture.target.y + dy },
            view,
            alpha,
            sway,
          ).some((entry) => entry.id === fixture.treeId),
        );
      }
});

test("fixture rejects unsupported camera, terrain and transparent crowns instead of relaxing reveal", () => {
  assert.throws(
    () => canopyBasis({ azimuth: 45, elevation: 35 }),
    /actual azimuth/,
  );
  assert.throws(
    () => canopyBasis({ azimuth: -45, elevation: 45 }),
    /actual elevation/,
  );
  const altered = structuredClone(WORLD);
  altered.landMaps.forest.surfaces[0].elevation = 1;
  assert.throws(
    () => deriveCanopyTarget(altered, map.spawn, view, alpha),
    /terrain height/,
  );
  const transparent = {
    ...alpha,
    frames: alpha.frames.map((frame) => frame.map(() => false)),
  };
  assert.throws(
    () => deriveCanopyTarget(WORLD, map.spawn, view, transparent),
    /No alpha-backed/,
  );
});

test("CPU projection assumptions stay tied to current renderer equations and sway limits", () => {
  const renderer = readFileSync(
    new URL("../client-godot/scripts/land/LandWorld3D.gd", import.meta.url),
    "utf8",
  );
  for (const expression of [
    "const TILT := deg_to_rad(55.0)",
    "return Vector3(point.x,-point.y/cos(TILT)-height*tan(TILT),height)",
    "sin(progress*1.2)*14,progress*5,height*progress",
    "210+height*.25",
    "height*1.35",
    "camera_up()*width*.08",
    'preload("res://scripts/FoliageMotion.gd").land_offset(now,Vector2(home.x,home.y),wind,float(leaf.pixel),float(leaf.size))',
  ])
    assert(renderer.includes(expression), expression);
  const foliage = readFileSync(
    new URL("../client-godot/scripts/FoliageMotion.gd", import.meta.url),
    "utf8",
  );
  for (const expression of [
    "floorf(seconds*10.0)/10.0",
    "roundf(distance/maxf(.2,pixel_step))*pixel_step",
    "clampf(wind/22.0,.35,1.4)",
  ])
    assert(foliage.includes(expression), expression);
  const readability = readFileSync(
    new URL(
      "../client-godot/scripts/land/CanopyReadability3D.gd",
      import.meta.url,
    ),
    "utf8",
  );
  for (const expression of [
    "feet+up*48.0-forward*8.0",
    "relative.dot(forward)>12.0",
    "Vector2(0,-28),Vector2(-15,0),Vector2(15,0),Vector2(0,27)",
    "image.resize(64,64,Image.INTERPOLATE_NEAREST)",
  ])
    assert(readability.includes(expression), expression);
  const environment = readFileSync(
    new URL("../client-godot/autoloads/EnvironmentState.gd", import.meta.url),
    "utf8",
  );
  assert(
    environment.includes(
      "9.0+coverage*22.0+sin(elapsed_seconds*0.21+story_day)*4.0",
    ),
  );
  assert(1.2 + 35 * 0.035 < 3);
});
