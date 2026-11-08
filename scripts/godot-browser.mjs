import { fetchWorld, hubRoute } from "./game-navigation.mjs";
import { chromium, firefox, webkit } from "@playwright/test";
import assert from "node:assert/strict";
import { readFileSync, mkdirSync, writeFileSync, rmSync } from "node:fs";
const fixture = JSON.parse(
  readFileSync(process.env.BROWSER_FIXTURE ?? ".runtime/browser.json", "utf8"),
);
const user = fixture.accounts.find((x) => x.role === "player");
const origin = process.env.APP_TEST_ORIGIN ?? "http://localhost:5173";
mkdirSync("artifacts/godot", { recursive: true });
const engine = process.env.BROWSER_ENGINE ?? "chromium";
const browser = await { chromium, firefox, webkit }[engine].launch({
  args:
    engine === "chromium"
      ? [
          "--enable-webgl",
          "--use-gl=angle",
          "--use-angle=swiftshader",
          "--enable-unsafe-swiftshader",
        ]
      : [],
});
const context = await browser.newContext({
  viewport: { width: 1440, height: 900 },
});
const page = await context.newPage(),
  errors = [],
  diagnostics = [];
page.setDefaultTimeout(15000);
page.on("pageerror", (e) => errors.push(e.message));
page.on("console", (m) => {
  diagnostics.push({ type: m.type(), text: m.text() });
  writeFileSync(
    ".runtime/godot-browser-diagnostics.json",
    JSON.stringify(diagnostics.slice(-200)),
  );
  if (m.type() === "error") errors.push(m.text());
});
const snapshot = (frame) => frame.evaluate(() => window.jalasmaraSnapshot);
const stairEvidence = [];
function recordStairs(state) {
  const stair = state.traversal;
  if (
    process.env.VERIFY_LAND === "1" &&
    !state.diving &&
    stair?.onStairs &&
    stair.paceScale < 1
  )
    stairEvidence.push({ position: [state.x, state.y], ...stair });
}
async function walkTo(frame, x, y, tolerance = 22, accept = null) {
  let previous = null,
    stalled = 0;
  for (let i = 0; i < 150; i++) {
    const at = await snapshot(frame),
      dx = x - at.x,
      dy = y - at.y;
    recordStairs(at);
    const arrivalTolerance = !at.diving && tolerance === 22 ? 30 : tolerance;
    if (accept && (await accept(at))) return;
    writeFileSync(
      ".runtime/godot-browser-progress.json",
      JSON.stringify({
        target: [x, y],
        tolerance,
        iteration: i,
        position: [at.x, at.y],
        traversal: at.traversal,
      }),
    );
    if (Math.hypot(dx, dy) < arrivalTolerance) return;
    stalled =
      previous && Math.hypot(at.x - previous.x, at.y - previous.y) < 0.4
        ? stalled + 1
        : 0;
    previous = at;
    if (stalled >= 12)
      throw Error(
        "Keyboard route blocked: " +
          JSON.stringify({
            target: [x, y],
            position: [at.x, at.y],
            traversal: at.traversal,
          }),
      );
    const keys = [];
    const threshold = tolerance < 22 ? tolerance / 2 : 14;
    if (Math.abs(dx) > threshold) keys.push(dx > 0 ? "d" : "a");
    if (Math.abs(dy) > threshold) keys.push(dy > 0 ? "s" : "w");
    for (const key of keys) await page.keyboard.down(key);
    const surfaceCheck = process.env.VERIFY_LAND === "1" && !at.diving;
    await page.waitForTimeout(
      surfaceCheck && Math.hypot(dx, dy) < 80
        ? 110
        : tolerance < 22
          ? Math.max(110, Math.min(160, Math.hypot(dx, dy) * 3))
          : 160,
    );
    // Release first: a slow renderer must not extend the hold while we inspect it.
    for (const key of keys) await page.keyboard.up(key);
    if (surfaceCheck) recordStairs(await snapshot(frame));
    await page.waitForTimeout(surfaceCheck || tolerance < 22 ? 220 : 70);
    if (accept && (await accept(await snapshot(frame)))) return;
  }
  const at = await snapshot(frame);
  throw Error(
    "Keyboard route did not converge: " +
      JSON.stringify({
        target: [x, y],
        position: [at.x, at.y],
        tolerance,
        traversal: at.traversal,
      }),
  );
}
try {
  await page.goto(origin);
  await page.getByLabel("Email", { exact: true }).fill(user.email);
  await page.getByLabel("Password", { exact: true }).fill(fixture.password);
  await page.getByRole("button", { name: "Masuk ke Jalasmara" }).click();
  await page.waitForURL("**/play");
  const frame = await (
    await page.locator("iframe").elementHandle()
  ).contentFrame();
  await frame.waitForFunction(() => window.jalasmaraReady === true, null, {
    polling: 200,
    timeout: origin.startsWith("https:") ? 240000 : 90000,
  });
  await frame.waitForFunction(() => window.jalasmaraSnapshot != null, null, {
    polling: 200,
  });
  if (origin.startsWith("https:")) {
    const session = (await context.cookies()).find(
      (c) => c.name === "__Host-jalasmara",
    );
    assert(session?.secure && session.httpOnly && session.sameSite === "Lax");
  }
  assert.equal(
    (await snapshot(frame)).modal,
    false,
    "Fixture harus sudah menyelesaikan tutorial",
  );
  await page.screenshot({
    path: "artifacts/godot/bandar-hujung.png",
    fullPage: true,
  });
  await frame.locator("canvas").click();
  if (!(await snapshot(frame)).diving) {
    const world = await fetchWorld(context.request, origin);
    if (process.env.VERIFY_LAND === "1") {
      const output = "artifacts/godot/land";
      mkdirSync(output, { recursive: true });
      const trunk = world.hub.treeTrunks?.[0];
      assert(trunk, "Surface test requires authored trunk collision metadata");
      const frontPoint = { x: trunk.x + 35, y: trunk.y + 60 };
      const behindPoint = { x: 780, y: 637 };
      const physicalTrunk = world.hub.treeTrunks[1];
      const treeAt = (state) =>
        state.occlusion?.trees?.find(
          (tree) =>
            Math.hypot(tree.base[0] - trunk.x, tree.base[1] - trunk.y) < 1,
        );
      for (const [x, y] of hubRoute(world, await snapshot(frame), frontPoint))
        await walkTo(frame, x, y);
      await page.waitForTimeout(350);
      const front = await snapshot(frame),
        frontTree = treeAt(front);
      assert(
        front.occlusion?.sortByFeet,
        "Tree sorting must use the feet plane",
      );
      assert(
        front.occlusion.landRock?.ready &&
          front.occlusion.landRock.meshCount === 1 &&
          front.occlusion.landRock.contained,
        "Actual 3D land rock must be ready and contained in the solid footprint",
      );
      assert(frontTree?.leafMasked && frontTree.woodLayer);
      assert.equal(frontTree.behind, false);
      assert.equal(frontTree.fadeActive, false);
      assert(
        front.occlusion.water?.active &&
          front.occlusion.water.regionCells > 1000,
      );
      assert.equal(front.occlusion.water.geometryChanged, false);
      await page.screenshot({ path: `${output}/01-front.png`, fullPage: true });
      for (const [x, y] of hubRoute(world, front, {
        x: physicalTrunk.x - 85,
        y: physicalTrunk.y,
      }))
        await walkTo(frame, x, y);
      await walkTo(frame, physicalTrunk.x - 85, physicalTrunk.y, 12);
      await page.waitForTimeout(300);
      const approach = await snapshot(frame);
      assert(
        Math.abs(approach.y - physicalTrunk.y) < 12,
        "Physical trunk test must approach its center line: " +
          JSON.stringify({
            position: [approach.x, approach.y],
            trunk: physicalTrunk,
          }),
      );
      await page.keyboard.down("d");
      await page.waitForTimeout(650);
      await page.keyboard.up("d");
      await page.waitForTimeout(200);
      const blocked = await snapshot(frame);
      assert(
        Math.hypot(blocked.x - physicalTrunk.x, blocked.y - physicalTrunk.y) >=
          physicalTrunk.radius + 8,
        "Nala must collide with the physical trunk",
      );
      assert(
        blocked.x > physicalTrunk.x - 75 && blocked.x < physicalTrunk.x,
        "Trunk test must walk toward the trunk from its west side",
      );
      for (const [x, y] of hubRoute(world, blocked, behindPoint))
        await walkTo(frame, x, y);
      const raster = await page.evaluateHandle(
        async (png) => {
          const image = new Image();
          image.src = png;
          await image.decode();
          const canvas = document.createElement("canvas");
          canvas.width = image.width;
          canvas.height = image.height;
          canvas.getContext("2d").drawImage(image, 0, 0);
          return canvas;
        },
        "data:image/png;base64," +
          readFileSync(
            "client-godot/resources/art/coastal-village-map.png",
          ).toString("base64"),
      );
      const footColor = async (state) =>
        raster.evaluate(
          (canvas, { point, extent }) =>
            Array.from(
              canvas
                .getContext("2d")
                .getImageData(
                  Math.floor((point[0] / extent[0]) * canvas.width),
                  Math.floor((point[1] / extent[1]) * canvas.height),
                  1,
                  1,
                ).data,
            ).slice(0, 3),
          {
            point: [state.x, state.y],
            extent: [world.hub.width, world.hub.height],
          },
        );
      const onBrownSoil = (rgb) =>
        rgb[0] > rgb[1] * 1.1 && rgb[0] > rgb[2] * 1.4;
      const strictBrownSoil = process.env.VERIFY_BROWN_SOIL === "1";
      const outsideSolids = (state) => {
        if (
          world.hub.obstacles.some(
            ([x, y, width, height]) =>
              state.x >= x - 12 &&
              state.x <= x + width + 12 &&
              state.y >= y - 12 &&
              state.y <= y + height + 12,
          )
        )
          return false;
        return !world.hub.treeTrunks.some(
          (root) =>
            Math.hypot(state.x - root.x, state.y - root.y) < root.radius + 12,
        );
      };
      const validBehind = async (state) => {
        const tree = treeAt(state);
        return (
          tree?.behind &&
          tree.headCovered &&
          tree.fadeActive &&
          outsideSolids(state) &&
          (!strictBrownSoil || onBrownSoil(await footColor(state)))
        );
      };
      let behind, behindTree, behindFootRGB;
      for (const [x, y] of [
        [780, 637],
        [758, 666],
        [780, 637],
        [766, 659],
        [748, 659],
        [780, 659],
      ]) {
        await walkTo(frame, x, y, 18, validBehind);
        await page.waitForTimeout(250);
        behind = await snapshot(frame);
        behindTree = treeAt(behind);
        behindFootRGB = await footColor(behind);
        if (await validBehind(behind)) break;
      }
      assert(
        behindTree?.behind && behindTree.headCovered && behindTree.fadeActive,
        "Passing behind the actual crown must reveal Nala's head",
      );
      assert(
        outsideSolids(behind),
        "Actual feet must remain outside all authoritative solid rectangles and trunk circles",
      );
      if (strictBrownSoil)
        assert(
          onBrownSoil(behindFootRGB),
          "Strict raster brown-soil diagnostic failed: " +
            JSON.stringify({
              position: [behind.x, behind.y],
              rgb: behindFootRGB,
            }),
        );
      let serverSurface;
      for (let attempt = 0; attempt < 10; attempt++) {
        const response = await context.request.get(
          origin + "/api/adventure/state",
        );
        assert(
          response.ok(),
          "Authenticated server surface state must remain available",
        );
        serverSurface = (await response.json()).surface;
        if (
          serverSurface?.area === "hub" &&
          Math.hypot(serverSurface.x - behind.x, serverSurface.y - behind.y) <=
            2
        )
          break;
        await page.waitForTimeout(600);
      }
      assert(
        serverSurface?.area === "hub" &&
          Math.hypot(serverSurface.x - behind.x, serverSurface.y - behind.y) <=
            2,
        "Visible occlusion position must also be accepted by the server: " +
          JSON.stringify({
            client: [behind.x, behind.y],
            server: serverSurface,
          }),
      );
      await raster.dispose();
      assert(behind.y < behindTree.footY - 100);
      assert(
        behind.occlusion.water.phase > front.occlusion.water.phase + 1,
        "Surface ripple phase must advance during actual exploration",
      );
      await page.screenshot({
        path: `${output}/02-behind.png`,
        fullPage: true,
      });
      const climbed = stairEvidence.filter((step) => step.direction === "up");
      assert(
        climbed.some(
          (step) =>
            step.footstepMaterial === "stone" &&
            step.elevation > 1 &&
            step.steps >= 3,
        ),
        "Real keyboard navigation must climb authored stone stairs with reduced pace",
      );
      writeFileSync(
        `${output}/results.json`,
        JSON.stringify(
          {
            origin,
            engine,
            checks: [
              "feet-sorted-front-crown",
              "leaf-mask-and-solid-wood",
              "physical-trunk-blocks-player",
              "head-reveal-behind-crown",
              "surface-water-animation-advances",
              "actual-3d-land-rock",
              "keyboard-stair-climb",
              "feet-outside-authoritative-solids",
              "server-surface-position-synced",
              ...(strictBrownSoil ? ["strict-raster-brown-soil"] : []),
            ],
            stairs: climbed,
            front: {
              position: [front.x, front.y],
              tree: frontTree,
              water: front.occlusion.water,
            },
            blocked: {
              approach: [approach.x, approach.y],
              position: [blocked.x, blocked.y],
              trunk: physicalTrunk,
            },
            behind: {
              position: [behind.x, behind.y],
              tree: behindTree,
              footRGB: behindFootRGB,
              footRGBDiagnosticOnly: !strictBrownSoil,
              serverPosition: [serverSurface.x, serverSurface.y],
              water: behind.occlusion.water,
            },
          },
          null,
          2,
        ),
      );
    }
    for (const [x, y] of hubRoute(
      world,
      await snapshot(frame),
      world.hub.divePoint,
    ))
      await walkTo(frame, x, y);
    if (process.env.VERIFY_LIVING === "1") {
      const walking = await snapshot(frame);
      assert(
        walking.foley?.steps > 0,
        "Walking must dispatch distance-based foley",
      );
      assert(walking.audio?.sfxPlayed > 0);
    }
    await page.keyboard.press("e");
    await frame.waitForFunction(
      () => window.jalasmaraSnapshot?.diving === true,
      null,
      { polling: 200, timeout: 30000 },
    );
  }
  await page.screenshot({
    path: "artifacts/godot/segaran.png",
    fullPage: true,
  });
  await walkTo(frame, 1250, 530);
  const collect = page.waitForResponse((r) =>
    r.url().endsWith("/api/dive/collect"),
  );
  await page.keyboard.down("Space");
  await page.waitForTimeout(850);
  await page.keyboard.up("Space");
  const captured = await (await collect).json();
  assert(captured.dive?.loot.length > 0, JSON.stringify(captured));
  assert.equal(
    captured.dive.challenge,
    undefined,
    "Biota biasa tidak membuka kuis",
  );
  await walkTo(frame, 1550, 620);
  const discovery = page.waitForResponse((r) =>
    r.url().endsWith("/api/adventure/interact"),
  );
  await page.keyboard.press("e");
  assert.equal(
    (await (await discovery).json()).player.adventure.discoveries.includes(
      "cell",
    ),
    true,
  );
  await frame.waitForFunction(
    () => window.jalasmaraSnapshot?.modal === true,
    null,
    { polling: 200 },
  );
  await page.screenshot({
    path: "artifacts/godot/discovery.png",
    fullPage: true,
  });
  await page.keyboard.press("Escape");
  await page.waitForTimeout(650);
  await page.screenshot({
    path: "artifacts/godot/swimming.png",
    fullPage: true,
  });
  if (process.env.VERIFY_LIVING === "1") {
    const output = "artifacts/godot/living";
    mkdirSync(output, { recursive: true });
    const before = await snapshot(frame);
    assert.equal(before.life?.generated, true);
    assert(before.life.creatures >= 29 && before.life.schools >= 4);
    assert.equal(before.hybrid.water?.active, true);
    assert.equal(before.hybrid.water.threeDParticles, 0);
    assert(before.hybrid.water.contourClips > 0);
    assert(before.hybrid.water.motes > 0 && before.hybrid.water.motes <= 48);
    await page.screenshot({ path: `${output}/01-alive.png`, fullPage: true });
    await page.waitForTimeout(2400);
    const after = await snapshot(frame);
    const moving = after.life.positions.filter(
      (p, i) =>
        Math.hypot(
          p[0] - before.life.positions[i][0],
          p[1] - before.life.positions[i][1],
        ) > 2,
    ).length;
    assert(
      moving >= 12,
      `Expected visible world simulation, only ${moving} creatures moved`,
    );
    assert.notEqual(
      after.weather.current_x,
      before.weather.current_x,
      "Current must evolve with weather/time",
    );
    assert(after.foley.underwater && after.audio.underwater);
    await page.screenshot({ path: `${output}/02-alive.png`, fullPage: true });
    writeFileSync(
      `${output}/results.json`,
      JSON.stringify(
        {
          origin,
          moving,
          life: after.life,
          water: after.hybrid.water,
          foley: after.foley,
          checks: [
            "generated-creature-runtime",
            "schooling-simulation-advances",
            "world-space-water",
            "contour-occluded-light",
            "dynamic-current",
            "motion-foley",
          ],
        },
        null,
        2,
      ),
    );
  }
  if (process.env.VERIFY_HYBRID === "1") {
    const output = "artifacts/godot/hybrid";
    mkdirSync(output, { recursive: true });
    const rendered = (await snapshot(frame)).hybrid;
    assert.equal(rendered.active, true);
    assert.equal(rendered.renderer, "SubViewport3D");
    assert.equal(rendered.orthographic, true);
    assert(rendered.mesh_count >= 15 && rendered.sprite_count > 1);
    await page.screenshot({ path: `${output}/01-reef-3d.png`, fullPage: true });
    await page.keyboard.press("F6");
    await frame.waitForFunction(
      () => window.jalasmaraSnapshot?.hybrid?.active === false,
      null,
      { polling: 100 },
    );
    await page.screenshot({
      path: `${output}/02-reef-2d-comparison.png`,
      fullPage: true,
    });
    await page.keyboard.press("F6");
    await frame.waitForFunction(
      () => window.jalasmaraSnapshot?.hybrid?.active === true,
      null,
      { polling: 100 },
    );
    for (const [key, facing] of [
      ["d", 1],
      ["a", -1],
    ]) {
      await page.keyboard.down(key);
      await page.waitForTimeout(220);
      await page.keyboard.up(key);
      await page.waitForTimeout(350);
      const state = await snapshot(frame),
        lamp = state.hybrid.flashlight;
      assert.equal(lamp.facing, facing);
      assert(
        (lamp.mount[0] - state.x) * facing > 20,
        "3D flashlight must mount in front of Nala",
      );
      assert(
        (lamp.aim[0] - lamp.mount[0]) * facing > 400,
        "3D beam must point forward",
      );
      await page.keyboard.press("F6");
      await frame.waitForFunction(
        () => window.jalasmaraSnapshot?.flashlight2d?.active === true,
        null,
        { polling: 100 },
      );
      const fallback = await snapshot(frame),
        lamp2d = fallback.flashlight2d;
      assert(
        (lamp2d.mount[0] - fallback.x) * facing > 20,
        "2D flashlight must mount in front of Nala",
      );
      assert(
        (lamp2d.aim[0] - lamp2d.mount[0]) * facing > 400,
        "2D beam must point forward",
      );
      await page.screenshot({
        path: `${output}/flashlight-2d-${facing}.png`,
        fullPage: true,
      });
      await page.keyboard.press("F6");
      await frame.waitForFunction(
        () => window.jalasmaraSnapshot?.hybrid?.active === true,
        null,
        { polling: 100 },
      );
    }
    await page.keyboard.press("i");
    await frame.waitForFunction(
      () => window.jalasmaraSnapshot?.modal === true,
      null,
      { polling: 100 },
    );
    await page.screenshot({ path: `${output}/inventory.png`, fullPage: true });
    await page.keyboard.press("Escape");
    await page.waitForTimeout(250);
    for (const [x, y] of [
      [1000, 580],
      [1000, 900],
      [750, 900],
    ])
      await walkTo(frame, x, y);
    const cave = await snapshot(frame);
    assert(cave.hybrid.active && cave.hybrid.spot_shadow);
    assert(cave.hud?.oxygen?.visible && cave.hud.oxygen.value > 0);
    assert(Math.hypot(cave.x - 750, cave.y - 900) < 25);
    await page.screenshot({
      path: `${output}/03-cave-passage.png`,
      fullPage: true,
    });
    writeFileSync(
      `${output}/results.json`,
      JSON.stringify(
        {
          origin,
          checks: [
            "real-3d-meshes",
            "billboard-actors",
            "orthographic-pixel-viewport",
            "F6-comparison-toggle",
            "swim-through-authoritative-cave-gap",
            "shadowed-headlamp",
            "forward-flashlight-both-facings-both-renderers",
            "inventory-modal",
          ],
          reef: rendered,
          cave: cave.hybrid,
        },
        null,
        2,
      ),
    );
  }
  if (process.env.VERIFY_BACKDROP === "1") {
    const output = "artifacts/godot/backdrop";
    mkdirSync(output, { recursive: true });
    // Both the ordinary route and the hybrid cave route reach this same clear-water start.
    for (const [x, y] of [
      [1000, 900],
      [1000, 580],
      [1550, 620],
    ])
      await walkTo(frame, x, y);
    await page.waitForTimeout(450);
    const shallow = await snapshot(frame);
    const before = shallow.hybrid?.backdrop;
    assert.equal(shallow.hybrid?.active, true);
    assert.equal(before?.active, true);
    assert.equal(
      before.atlasAvailable,
      true,
      "Generated atmosphere atlas must actually load",
    );
    assert(
      before.layers.length >= 3,
      "Need distinct far, middle, and near scenery",
    );
    for (const layer of before.layers) {
      assert(
        layer.cards > 0,
        `Backdrop layer ${layer.id} has no rendered cards`,
      );
      assert(layer.parallax.every((factor) => factor > 0 && factor < 1));
      assert(layer.tint.length === 4 && layer.tint.every(Number.isFinite));
    }
    await page.screenshot({ path: `${output}/01-shallow.png`, fullPage: true });
    for (const [x, y] of [
      [1000, 580],
      [1000, 900],
      [750, 900],
    ])
      await walkTo(frame, x, y);
    await page.waitForTimeout(450);
    const deeper = await snapshot(frame),
      after = deeper.hybrid?.backdrop;
    assert.equal(after?.active, true);
    assert(after.depth > before.depth, "Depth tint must follow actual descent");
    const cameraDelta = deeper.hybrid.camera_center.map(
      (value, axis) => value - shallow.hybrid.camera_center[axis],
    );
    assert(
      Math.abs(cameraDelta[0]) > 300 && cameraDelta[1] > 80,
      "Backdrop proof requires real horizontal and vertical camera movement",
    );
    let changedTints = 0;
    const offsets = [];
    for (const previous of before.layers) {
      const current = after.layers.find((layer) => layer.id === previous.id);
      assert(
        current,
        `Lost backdrop layer ${previous.id} during camera movement`,
      );
      const cameraBefore = shallow.hybrid.camera_center;
      const cameraAfter = deeper.hybrid.camera_center;
      const expected = [0, 1].map((axis) => {
        const origin = axis === 0 ? 1550 : 620;
        const project = (value) => {
          const offset = (value - origin) * (1 - previous.parallax[axis]);
          return axis === 1 ? Math.max(-220, Math.min(220, offset)) : offset;
        };
        return project(cameraAfter[axis]) - project(cameraBefore[axis]);
      });
      const actual = current.offset.map(
        (value, axis) => value - previous.offset[axis],
      );
      for (const axis of [0, 1])
        assert(
          Math.abs(actual[axis] - expected[axis]) < 2,
          `${previous.id} axis ${axis}: parallax ${actual[axis]} should be ${expected[axis]}`,
        );
      if (
        current.tint.some(
          (value, channel) => Math.abs(value - previous.tint[channel]) > 0.0001,
        )
      )
        changedTints++;
      offsets.push({
        id: previous.id,
        factors: previous.parallax,
        actual,
        expected,
      });
    }
    const ordered = [...after.layers].sort(
      (a, b) => a.parallax[0] - b.parallax[0],
    );
    assert(ordered[0].parallax[0] < ordered.at(-1).parallax[0]);
    assert(ordered[0].parallax[1] < ordered.at(-1).parallax[1]);
    assert(
      ordered[0].contrast < ordered.at(-1).contrast,
      "Distant scenery must have lower contrast than nearby scenery",
    );
    assert(
      changedTints > 0,
      "Descent must change atmospheric tint, not only position",
    );
    await page.screenshot({ path: `${output}/02-deeper.png`, fullPage: true });
    writeFileSync(
      `${output}/results.json`,
      JSON.stringify(
        {
          origin,
          engine,
          checks: [
            "generated-atlas-loaded",
            "three-rendered-depth-layers",
            "real-camera-travel",
            "per-layer-parallax-x-y",
            "distant-contrast-falloff",
            "depth-tint-progression",
          ],
          cameraDelta,
          changedTints,
          offsets,
          shallow: {
            position: [shallow.x, shallow.y],
            camera: shallow.hybrid.camera_center,
            backdrop: before,
          },
          deeper: {
            position: [deeper.x, deeper.y],
            camera: deeper.hybrid.camera_center,
            backdrop: after,
          },
        },
        null,
        2,
      ),
    );
  }
  await page.keyboard.press("m");
  await frame.waitForFunction(
    () => window.jalasmaraSnapshot?.modal === true,
    null,
    { polling: 200 },
  );
  assert.equal((await snapshot(frame)).modal, true);
  await page.screenshot({ path: "artifacts/godot/map.png", fullPage: true });
  assert.deepEqual(errors, []);
  rmSync("artifacts/godot/errors.json", { force: true });
  rmSync("artifacts/godot/failure.png", { force: true });
  writeFileSync(
    "artifacts/godot/results.json",
    JSON.stringify(
      {
        origin,
        errors,
        checks: [
          "walk",
          "dive",
          "swim",
          "net-without-quiz",
          "discovery",
          "map",
        ],
        snapshot: await snapshot(frame),
      },
      null,
      2,
    ),
  );
  console.log(
    "Godot browser: walk, dive, swim, capture, discovery, map passed; no browser errors.",
  );
} catch (e) {
  await page
    .screenshot({
      path: "artifacts/godot/failure.png",
      timeout: 5000,
      fullPage: true,
    })
    .catch(() => {});
  writeFileSync(
    "artifacts/godot/errors.json",
    JSON.stringify(
      {
        error: e.message,
        errors,
        diagnostics,
        url: page.url(),
        ready: await page
          .locator("iframe")
          .evaluate((el) => el.contentWindow.jalasmaraReady, null, {
            timeout: 1000,
          })
          .catch(() => null),
        snapshot: await page
          .locator("iframe")
          .evaluate((el) => el.contentWindow.jalasmaraSnapshot, null, {
            timeout: 1000,
          })
          .catch(() => null),
      },
      null,
      2,
    ),
  );
  console.error(e.stack);
  process.exitCode = 1;
} finally {
  await browser.close();
}
