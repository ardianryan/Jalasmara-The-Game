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
      const maps = world.landMaps;
      assert(
        maps?.hub?.surfaces?.length && maps?.forest?.surfaces?.length,
        "Both modular land manifests are required",
      );
      const distanceToSegment = (p, a, b) => {
        const dx = b[0] - a[0],
          dy = b[1] - a[1],
          denominator = dx * dx + dy * dy;
        const t = denominator
          ? Math.max(
              0,
              Math.min(
                1,
                ((p[0] - a[0]) * dx + (p[1] - a[1]) * dy) / denominator,
              ),
            )
          : 0;
        return Math.hypot(p[0] - a[0] - t * dx, p[1] - a[1] - t * dy);
      };
      const inside = (point, polygon) => {
        let result = false;
        for (let i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
          const a = polygon[j],
            b = polygon[i];
          if (distanceToSegment(point, a, b) < 0.02) return true;
          if (
            a[1] > point[1] !== b[1] > point[1] &&
            point[0] <
              ((b[0] - a[0]) * (point[1] - a[1])) / (b[1] - a[1]) + a[0]
          )
            result = !result;
        }
        return result;
      };
      const validFeet = (map, state) => {
        const point = [state.x, state.y];
        if (
          map.obstacles.some(
            (item) =>
              inside(point, item.footprint) ||
              item.footprint.some(
                (a, i) =>
                  distanceToSegment(
                    point,
                    a,
                    item.footprint[(i + 1) % item.footprint.length],
                  ) < 11.5,
              ),
          )
        )
          return false;
        const floors = map.surfaces.filter((item) => item.walkable !== false);
        return [
          point,
          ...Array.from({ length: 8 }, (_, i) => [
            point[0] + Math.cos((i * Math.PI) / 4) * 11.5,
            point[1] + Math.sin((i * Math.PI) / 4) * 11.5,
          ]),
        ].every((p) => floors.some((item) => inside(p, item.polygon)));
      };
      const rendered = (state, area) => {
        const land = state.land,
          map = maps[area];
        assert(
          land?.active &&
            land.area === area &&
            land.renderer === "LandSubViewport3D",
        );
        assert.equal(
          land.bitmapGround,
          false,
          "The modular world must not use a painted ground map",
        );
        assert.deepEqual(land.viewport, [480, 270]);
        assert.equal(land.elevationDegrees, 35);
        assert(land.meshes > 0 && land.trees > 0 && land.glbModels > 0);
        assert.equal(land.surfaces, map.surfaces.length);
        assert.equal(land.obstacles, map.obstacles.length);
        assert.equal(land.actors.player, 1);
        assert(
          land.maxFootError < 1,
          "3D actor feet must match logical ground coordinates",
        );
        assert(
          land.water?.mesh &&
            land.water.vertexWaves &&
            land.water.shoreFoam &&
            !land.water.walkable,
        );
        assert(
          validFeet(map, state),
          "Rendered player feet entered a solid or left the floor union",
        );
        if (area === "forest") {
          assert.equal(map.bridges.length, 2);
          for (const bridge of map.bridges) {
            const emitted = land.bridges?.[bridge.id];
            assert(emitted?.oriented && emitted.thickness >= 12);
            assert(emitted.planks >= 8 && emitted.sideBeams === 2);
            assert(emitted.railPosts >= 8 && emitted.railBeams >= 4);
            assert.deepEqual(emitted.endpoints, bridge.path);
          }
        }
        return land;
      };
      const go = async (map, destination) => {
        for (const [x, y] of hubRoute(
          { hub: { paths: map.routes } },
          await snapshot(frame),
          destination,
        ))
          await walkTo(frame, x, y);
      };
      const serverPosition = async (area, state) => {
        let surface;
        for (let attempt = 0; attempt < 10; attempt++) {
          const response = await context.request.get(
            origin + "/api/adventure/state",
          );
          assert(response.ok());
          surface = (await response.json()).surface;
          if (
            surface?.area === area &&
            Math.hypot(surface.x - state.x, surface.y - state.y) < 2
          )
            return surface;
          await page.waitForTimeout(600);
        }
        assert.fail(
          "Logical and server land coordinates disagree: " +
            JSON.stringify({ area, client: [state.x, state.y], surface }),
        );
      };
      const views = [];
      const capture = async (label, area) => {
        await page.waitForTimeout(350);
        const state = await snapshot(frame),
          land = rendered(state, area);
        const server = await serverPosition(area, state);
        const screenshot = await page.screenshot({
          path: `${output}/${label}.png`,
          fullPage: true,
        });
        const raster = await page.evaluate(async (encoded) => {
          const image = new Image();
          image.src = "data:image/png;base64," + encoded;
          await image.decode();
          const canvas = document.createElement("canvas");
          canvas.width = Math.floor(image.width * 0.7);
          canvas.height = Math.floor(image.height * 0.44);
          const context = canvas.getContext("2d");
          context.drawImage(image, -image.width * 0.15, -image.height * 0.28);
          const pixels = context.getImageData(
            0,
            0,
            canvas.width,
            canvas.height,
          ).data;
          const colors = new Map();
          for (let i = 0; i < pixels.length; i += 4) {
            const key =
              ((pixels[i] >> 4) << 8) |
              ((pixels[i + 1] >> 4) << 4) |
              (pixels[i + 2] >> 4);
            colors.set(key, (colors.get(key) ?? 0) + 1);
          }
          return {
            colors: colors.size,
            dominantFraction:
              Math.max(...colors.values()) / (pixels.length / 4),
          };
        }, screenshot.toString("base64"));
        assert(
          raster.colors > 60 && raster.dominantFraction < 0.8,
          "Actual world screenshot is covered by a flat fallback despite renderer metadata: " +
            JSON.stringify({ label, raster }),
        );
        views.push({
          label,
          area,
          position: [state.x, state.y],
          server: [server.x, server.y],
          land,
          foley: state.foley,
          raster,
        });
        return state;
      };
      const dock = maps.hub.surfaces.find((item) => item.id === "dock_main");
      assert(dock, "An authored dock floor is required for the shoreline test");
      const shoreX = Math.max(...dock.polygon.map((p) => p[0]));
      const shoreY =
        dock.polygon.reduce((sum, p) => sum + p[1], 0) / dock.polygon.length;
      await go(maps.hub, { x: shoreX - 60, y: shoreY });
      await page.keyboard.down("d");
      await page.waitForTimeout(900);
      await page.keyboard.up("d");
      await page.waitForTimeout(350);
      const shore = await capture("01-dock-shore", "hub");
      assert.equal(shore.outfit, "diving", "Crossing the changing booth must equip dive clothing before entry");
      assert.equal(shore.equipment?.tank, true);
      assert.equal(shore.equipment?.net, true);
      assert(
        shore.x <= shoreX - 11.5 && shore.x > shoreX - 55,
        "Actual keyboard input must reach and stop at the dock/water boundary",
      );
      const house = maps.hub.obstacles.find(
        (item) => item.id === "kedai_waras",
      );
      assert(house?.kind === "house");
      const houseBottom = Math.max(...house.footprint.map((p) => p[1]));
      const houseFront = { x: house.x + house.width / 2, y: houseBottom + 60 };
      await go(maps.hub, houseFront);
      const beforeHouse = await snapshot(frame);
      await page.keyboard.down("w");
      await page.waitForTimeout(850);
      await page.keyboard.up("w");
      await page.waitForTimeout(350);
      const architecture = await capture("02-kedai-roof-boundary", "hub");
      assert.equal(architecture.outfit, "daily", "Returning to the village removes dive equipment");
      assert.equal(architecture.equipment?.tank, false);
      assert(
        architecture.y < beforeHouse.y - 25,
        "Building collision test must really approach the wall",
      );
      assert(!inside([architecture.x, architecture.y], house.footprint));
      assert(
        architecture.land.houses >= 3 &&
          architecture.land.components?.LimasRoof === 2 &&
          architecture.land.components?.ContainerFlatRoof === 1 &&
          architecture.land.components?.ContainerOfficeBody === 1 &&
          architecture.land.components?.CorporateServiceWindow === 1,
        "Kedai/Beno roofs and the distinct corporate container must actually be emitted",
      );
      const garden = maps.hub.obstacles.find((item) => item.kind === "garden");
      assert(garden);
      await go(maps.hub, { x: garden.x - 70, y: garden.y + garden.height / 2 });
      const beforeGarden = await snapshot(frame);
      await page.keyboard.down("d");
      await page.waitForTimeout(800);
      await page.keyboard.up("d");
      await page.waitForTimeout(350);
      const gardenView = await capture("03-garden-components", "hub");
      assert(
        gardenView.x > beforeGarden.x + 20 && gardenView.x < garden.x,
        "Raised garden beds must block actual movement at their component footprint",
      );
      assert(
        gardenView.land.components?.RaisedBed >= 1 &&
          gardenView.land.components?.CropLeaves >= 3,
      );
      assert(
        gardenView.land.water.elapsed > shore.land.water.elapsed + 1,
        "Actual 3D shore-water time must advance during exploration",
      );
      const climbed = stairEvidence.filter((item) => item.direction === "up");
      assert(
        climbed.some(
          (item) =>
            item.footstepMaterial === "stone" &&
            item.elevation > 1 &&
            item.steps >= 3,
        ),
        "Actual keyboard navigation must traverse the authored stone stairs",
      );
      assert(
        gardenView.land.stairTreads >=
          maps.hub.stairs
            .filter((item) => item.type === "stairs")
            .reduce((sum, item) => sum + item.steps, 0),
      );
      await go(maps.hub, world.forest.gate);
      await page.keyboard.press("e");
      await frame.waitForFunction(
        () =>
          window.jalasmaraSnapshot?.land?.area === "forest" &&
          window.jalasmaraSnapshot.land.active,
        null,
        { polling: 200, timeout: 90000 },
      );
      const bridge = maps.forest.surfaces.find(
        (item) => item.id === "bridge_upper",
      );
      assert(bridge?.material === "bridge");
      const bridgeCenter = {
        x:
          bridge.polygon.reduce((sum, p) => sum + p[0], 0) /
          bridge.polygon.length,
        y:
          bridge.polygon.reduce((sum, p) => sum + p[1], 0) /
          bridge.polygon.length,
      };
      await go(maps.forest, bridgeCenter);
      const forest = await capture("04-forest-bridge", "forest");
      assert.equal(forest.outfit, "explorer");
      assert.equal(forest.equipment?.tank, false);
      assert.equal(forest.equipment?.satchel, true);
      assert(
        inside([forest.x, forest.y], bridge.polygon),
        "Forest exploration must really cross onto the bridge component",
      );
      assert.equal(forest.foley.material, "bridge");
      const crossing = maps.forest.bridges.find(
        (item) => item.id === bridge.bridgeId,
      );
      assert(crossing);
      const [start, end] = crossing.path;
      const length = Math.hypot(end[0] - start[0], end[1] - start[1]);
      const normal = [
        -(end[1] - start[1]) / length,
        (end[0] - start[0]) / length,
      ];
      const railKey =
        Math.abs(normal[0]) > Math.abs(normal[1])
          ? normal[0] > 0
            ? "d"
            : "a"
          : normal[1] > 0
            ? "s"
            : "w";
      await page.keyboard.down(railKey);
      await page.waitForTimeout(850);
      await page.keyboard.up(railKey);
      await page.waitForTimeout(350);
      const stopped = await snapshot(frame);
      const lateral =
        (stopped.x - bridgeCenter.x) * normal[0] +
        (stopped.y - bridgeCenter.y) * normal[1];
      assert(
        lateral > crossing.width / 2 - 35 && lateral < crossing.width / 2 - 18,
        "Actual movement must stop at the rail before reaching the deck/water edge",
      );
      rendered(stopped, "forest");
      const downstream = maps.forest.surfaces.find(
        (item) => item.id === "bridge_lower",
      );
      assert(downstream?.bridgeId && downstream.material === "bridge");
      const downstreamCenter = {
        x:
          downstream.polygon.reduce((sum, p) => sum + p[0], 0) /
          downstream.polygon.length,
        y:
          downstream.polygon.reduce((sum, p) => sum + p[1], 0) /
          downstream.polygon.length,
      };
      assert(
        Math.hypot(
          downstreamCenter.x - bridgeCenter.x,
          downstreamCenter.y - bridgeCenter.y,
        ) > 250,
      );
      await go(maps.forest, downstreamCenter);
      const secondCrossing = await capture(
        "05-forest-downstream-bridge",
        "forest",
      );
      assert(inside([secondCrossing.x, secondCrossing.y], downstream.polygon));
      assert.equal(secondCrossing.foley.material, "bridge");
      assert(
        Math.hypot(
          views[0].land.camera[0] - views[2].land.camera[0],
          views[0].land.camera[1] - views[2].land.camera[1],
        ) > 500,
        "Component proof must include actual camera travel, not four unchanged screenshots",
      );
      await go(maps.forest, world.forest.entry);
      await page.keyboard.press("e");
      await frame.waitForFunction(
        () =>
          window.jalasmaraSnapshot?.land?.area === "hub" &&
          window.jalasmaraSnapshot.land.active,
        null,
        { polling: 200, timeout: 90000 },
      );
      rendered(await snapshot(frame), "hub");
      writeFileSync(
        `${output}/results.json`,
        JSON.stringify(
          {
            origin,
            engine,
            scope:
              "Modular 3D geometry and authoritative footprint checks; no bitmap/RGB-ground inference.",
            checks: [
              "real-modular-land-renderer",
              "shared-footprint-and-floor-union",
              "dock-shore-blocks-walking-into-water",
              "house-wall-and-three-dimensional-roofs",
              "raised-garden-component-boundary",
              "actual-stair-climb-and-treads",
              "animated-3d-shore-water",
              "hub-forest-roundtrip",
              "forest-bridge-material-and-movement",
              "five-camera-server-synced-captures",
              "two-oriented-bridges-and-physical-rails",
              "actor-feet-projection",
            ],
            stairs: climbed,
            views,
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
    await page.waitForTimeout(500);
    const afterToggle = (await snapshot(frame)).hybrid;
    assert(
      afterToggle.active && afterToggle.renderer === "SubViewport3D",
      "Release builds must keep the production renderer when F6 is pressed",
    );
    await page.screenshot({
      path: `${output}/02-release-renderer.png`,
      fullPage: true,
    });
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
      await page.screenshot({
        path: `${output}/flashlight-3d-${facing}.png`,
        fullPage: true,
      });
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
            "release-no-legacy-renderer-toggle",
            "swim-through-authoritative-cave-gap",
            "shadowed-headlamp",
            "3D-forward-flashlight-both-facings",
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
  assert.deepEqual(
    diagnostics.filter((entry) => /WebGL: INVALID_OPERATION/.test(entry.text)),
    [],
    "The production renderer must not emit invalid WebGL operations",
  );
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
