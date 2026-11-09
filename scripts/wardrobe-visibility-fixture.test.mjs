import test from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { WORLD } from "../packages/shared/src/world.ts";
import {
  deriveWardrobeVisibilityFixture,
  projectedWardrobeClear,
} from "./wardrobe-visibility-fixture.mjs";
const source = readFileSync(
  new URL("../client-godot/scripts/land/LandWorld3D.gd", import.meta.url),
  "utf8",
);
const view = { azimuth: -45, elevation: 35 };
test("actual booth geometry rejects occluded old sample and derives reachable clear candidate", () => {
  assert.equal(
    projectedWardrobeClear(WORLD, { x: 1490, y: 1290 }, view, source),
    false,
  );
  const fixture = deriveWardrobeVisibilityFixture(WORLD, view, source);
  assert.deepEqual(fixture.point, { x: 1536, y: 1386 });
  assert.deepEqual(fixture.route.at(-1), [1536, 1386]);
  assert.equal(
    projectedWardrobeClear(WORLD, { x: 1532, y: 1382 }, view, source),
    false,
  );
});
test("camera or geometry drift cannot silently reuse the frame", () => {
  assert.throws(() =>
    deriveWardrobeVisibilityFixture(WORLD, { ...view, azimuth: 45 }, source),
  );
  assert.throws(
    () =>
      deriveWardrobeVisibilityFixture(
        WORLD,
        view,
        source.replace("76,45", "96,45"),
      ),
    /source drift/,
  );
});
