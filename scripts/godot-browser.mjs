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
async function walkTo(frame, x, y) {
  for (let i = 0; i < 150; i++) {
    const at = await snapshot(frame),
      dx = x - at.x,
      dy = y - at.y;
    if (Math.hypot(dx, dy) < 22) return;
    const keys = [];
    if (Math.abs(dx) > 14) keys.push(dx > 0 ? "d" : "a");
    if (Math.abs(dy) > 14) keys.push(dy > 0 ? "s" : "w");
    for (const key of keys) await page.keyboard.down(key);
    await page.waitForTimeout(160);
    for (const key of keys) await page.keyboard.up(key);
    await page.waitForTimeout(70);
  }
  throw Error("Nala belum mencapai objek melalui gerakan keyboard.");
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
