import { fetchWorld, hubRoute } from "./game-navigation.mjs";
import { chromium } from "@playwright/test";
import assert from "node:assert/strict";
import { readFileSync, mkdirSync, writeFileSync, rmSync } from "node:fs";
const fixture = JSON.parse(
  readFileSync(
    process.env.BROWSER_FIXTURE ?? ".runtime/touch-browser.json",
    "utf8",
  ),
);
const user = fixture.accounts.find((x) => x.role === "player");
const origin = process.env.APP_TEST_ORIGIN ?? "http://localhost:3100";
const browser = await chromium.launch({
  args: [
    "--enable-webgl",
    "--use-gl=angle",
    "--use-angle=swiftshader",
    "--enable-unsafe-swiftshader",
  ],
});
const context = await browser.newContext({
  viewport: { width: 844, height: 390 },
  hasTouch: true,
  isMobile: true,
  deviceScaleFactor: 1,
});
const page = await context.newPage(),
  errors = [];
page.on("pageerror", (e) => errors.push(e.message));
page.on("console", (m) => {
  if (m.type() === "error") errors.push(m.text());
});
page.setDefaultTimeout(60000);
mkdirSync("artifacts/godot", { recursive: true });
try {
  await page.addInitScript(() => {
    window.jalasmaraDiagnostics = true;
  });
  await page.goto(origin);
  await page.getByLabel("Email", { exact: true }).fill(user.email);
  await page.getByLabel("Password", { exact: true }).fill(fixture.password);
  await page.getByRole("button", { name: "Masuk ke Jalasmara" }).click();
  await page.waitForURL("**/play");
  const frame = await (
    await page.locator("iframe").elementHandle()
  ).contentFrame();
  await frame.waitForFunction(() => window.jalasmaraReady === true, null, {
    timeout: origin.startsWith("https:") ? 240000 : 90000,
    polling: 200,
  });
  await frame.waitForFunction(
    () => window.jalasmaraSnapshot?.x !== undefined,
    null,
    { timeout: 60000 },
  );
  assert(
    await frame.evaluate(() => matchMedia("(pointer:coarse)").matches),
    "Expected coarse pointer",
  );
  const client = await context.newCDPSession(page);
  const snapshot = () => frame.evaluate(() => window.jalasmaraSnapshot);
  async function touch(x, y, ms = 100) {
    const box = await frame.locator("canvas").boundingBox();
    const logical = (await snapshot()).hud.logicalSize;
    const point = {
      x: box.x + (x * box.width) / logical[0],
      y: box.y + (y * box.height) / logical[1],
      id: 1,
      radiusX: 4,
      radiusY: 4,
      force: 1,
    };
    await client.send("Input.dispatchTouchEvent", {
      type: "touchStart",
      touchPoints: [point],
    });
    await page.waitForTimeout(ms);
    await client.send("Input.dispatchTouchEvent", {
      type: "touchEnd",
      touchPoints: [],
    });
    await page.waitForTimeout(650);
  }
  const before = await snapshot();
  async function touchControl(name, duration = 100) {
    const center = (await snapshot()).hud?.[name];
    assert(
      Array.isArray(center) && center.length === 2,
      `HUD control ${name} is missing`,
    );
    assert(
      center[0] >= 0 &&
        center[0] <= (await snapshot()).hud.logicalSize[0] &&
        center[1] >= 0 &&
        center[1] <= (await snapshot()).hud.logicalSize[1],
    );
    await touch(center[0], center[1], duration);
  }
  assert.equal(
    before.modal,
    false,
    "Touch fixture requires appearance and tutorial already selected",
  );
  async function joystick(dx, dy, duration = 200, magnitude = 1) {
    const state = await snapshot(),
      stick = state.hud.joystick,
      logical = state.hud.logicalSize;
    assert(stick?.radius > 0, "Round joystick metadata required");
    const canvas = await frame.locator("canvas").boundingBox();
    const point = (x, y) => ({
      x: canvas.x + (x * canvas.width) / logical[0],
      y: canvas.y + (y * canvas.height) / logical[1],
      id: 1,
      radiusX: 4,
      radiusY: 4,
      force: 1,
    });
    const length = Math.hypot(dx, dy) || 1;
    await client.send("Input.dispatchTouchEvent", {
      type: "touchStart",
      touchPoints: [point(...stick.center)],
    });
    await client.send("Input.dispatchTouchEvent", {
      type: "touchMove",
      touchPoints: [
        point(
          stick.center[0] + (dx / length) * stick.radius * magnitude,
          stick.center[1] + (dy / length) * stick.radius * magnitude,
        ),
      ],
    });
    await page.waitForTimeout(duration);
    await client.send("Input.dispatchTouchEvent", {
      type: "touchEnd",
      touchPoints: [],
    });
    await page.waitForTimeout(450);
    const released = (await snapshot()).hud.joystick.direction;
    assert(
      Math.hypot(...released) < 0.001,
      "Joystick release must clear analog input",
    );
  }
  const deadStart = await snapshot();
  await joystick(1, 0, 250, 0.1);
  const deadEnd = await snapshot();
  assert(
    Math.hypot(deadEnd.x - deadStart.x, deadEnd.y - deadStart.y) < 2,
    "Dead-zone touch must not move Nala",
  );
  async function moveTo(x, y, targetRadius = 30) {
    for (let i = 0; i < 100; i++) {
      const at = await snapshot(),
        dx = x - at.x,
        dy = y - at.y;
      if (Math.hypot(dx, dy) < targetRadius) return;
      await joystick(
        dx,
        dy,
        Math.min(300, Math.max(100, Math.hypot(dx, dy) * 4)),
      );
      await frame
        .waitForFunction(
          (old) => {
            const state = window.jalasmaraSnapshot;
            return state && Math.hypot(state.x - old.x, state.y - old.y) > 0.5;
          },
          at,
          { timeout: 3500 },
        )
        .catch(() => {});
    }
    throw Error(
      `Touch movement could not reach (${x}, ${y}): ${JSON.stringify(await snapshot())}`,
    );
  }
  const world = await fetchWorld(context.request, origin);
  for (const [x, y] of hubRoute(world, before, world.hub.divePoint))
    await moveTo(x, y);
  const moved = await snapshot();
  assert(
    Math.hypot(
      moved.x - world.hub.divePoint.x,
      moved.y - world.hub.divePoint.y,
    ) < 30,
    "Touch navigation must reach the actual dive point",
  );
  for (const [axis, label] of [
    ["x", "horizontal"],
    ["y", "vertical"],
  ]) {
    const expected = world.hub.divePoint[axis] - before[axis];
    const progress = (moved[axis] - before[axis]) * Math.sign(expected);
    assert(
      progress >= Math.max(20, Math.abs(expected) - 30),
      `Analog joystick ${label} movement failed: ${JSON.stringify({ before, moved, destination: world.hub.divePoint })}`,
    );
  }
  await touchControl("action");
  await frame.waitForFunction(() => window.jalasmaraSnapshot?.diving === true);
  await moveTo(1250, 530, 40);
  const captured = page.waitForResponse((r) =>
    r.url().endsWith("/api/dive/collect"),
  );
  await touchControl("net", 850);
  const result = await (await captured).json();
  assert(result.dive?.loot.length > 0, "Touch net did not capture");
  assert.equal(
    result.dive.challenge,
    undefined,
    "Ordinary capture should not open quiz",
  );
  await page.screenshot({ path: "artifacts/godot/touch.png", fullPage: true });
  await page.setViewportSize({width:390,height:844});
  await frame.waitForFunction(()=>window.jalasmaraSnapshot?.hud?.logicalSize?.[1]>1000,null,{polling:200});
  await page.waitForTimeout(3000);
  assert.equal((await snapshot()).diving,true,"Rotation must preserve the active dive");
  await page.screenshot({path:"artifacts/godot/touch-dive-portrait.png",fullPage:true});
  await page.setViewportSize({width:844,height:390});
  await frame.waitForFunction(()=>window.jalasmaraSnapshot?.hud?.logicalSize?.[1]===540,null,{polling:200});
  await page.waitForTimeout(1200);
  assert.deepEqual(errors, []);
  rmSync("artifacts/godot/touch-errors.json", { force: true });
  rmSync("artifacts/godot/touch-failure.png", { force: true });
  writeFileSync(
    "artifacts/godot/touch-results.json",
    JSON.stringify(
      {
        emulation: true,
        engine: "chromium",
        pointer: "coarse",
        origin,
        viewport: { width: 844, height: 390 },
        checks: [
          "round-joystick-horizontal",
          "round-joystick-vertical",
          "round-joystick-dead-zone-and-release",
          "touch-start-dive",
          "touch-swim",
          "touch-net-without-quiz",
          "portrait-rotation-preserves-dive",
        ],
        snapshot: await snapshot(),
        errors,
      },
      null,
      2,
    ),
  );
  console.log(
    "Chromium landscape touch emulation: round analog joystick, dead zone/release, dive, swim, capture passed.",
  );
} catch (e) {
  await page.screenshot({
    path: "artifacts/godot/touch-failure.png",
    fullPage: true,
  });
  writeFileSync(
    "artifacts/godot/touch-errors.json",
    JSON.stringify(
      {
        error: e.message,
        errors,
        snapshot: await page
          .locator("iframe")
          .evaluate((el) => el.contentWindow.jalasmaraSnapshot)
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
