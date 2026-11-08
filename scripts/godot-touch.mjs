import { chromium } from "@playwright/test";
import assert from "node:assert/strict";
import { readFileSync, mkdirSync, writeFileSync } from "node:fs";
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
page.setDefaultTimeout(15000);
mkdirSync("artifacts/godot", { recursive: true });
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
    timeout: 60000,
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
    const scale = Math.min(box.width / 960, box.height / 540);
    const point = {
      x: box.x + (box.width - 960 * scale) / 2 + x * scale,
      y: box.y + (box.height - 540 * scale) / 2 + y * scale,
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
  assert.equal(
    before.modal,
    false,
    "Touch fixture requires appearance and tutorial already selected",
  );
  async function moveTo(x, y, targetRadius = 30) {
    for (let i = 0; i < 80; i++) {
      const at = await snapshot();
      const dx = x - at.x,
        dy = y - at.y;
      if (Math.hypot(dx, dy) < targetRadius) return;
      if (Math.abs(dy) > 22)
        await touch(132, dy > 0 ? 480 : 404, Math.min(420, Math.abs(dy) * 4));
      else if (Math.abs(dx) > 18)
        await touch(dx > 0 ? 208 : 56, 480, Math.min(420, Math.abs(dx) * 4));
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
  await moveTo(1280, 520);
  const moved = await snapshot();
  assert(moved.x > before.x + 80, "D-pad horizontal movement failed");
  assert(moved.y > before.y + 80, "D-pad vertical movement failed");
  await touch(904, 484);
  await frame.waitForFunction(() => window.jalasmaraSnapshot?.diving === true);
  await moveTo(1250, 530, 40);
  const captured = page.waitForResponse((r) =>
    r.url().endsWith("/api/dive/collect"),
  );
  await touch(816, 484, 850);
  const result = await (await captured).json();
  assert(result.dive?.loot.length > 0, "Touch net did not capture");
  assert.equal(
    result.dive.challenge,
    undefined,
    "Ordinary capture should not open quiz",
  );
  await page.screenshot({ path: "artifacts/godot/touch.png", fullPage: true });
  assert.deepEqual(errors, []);
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
          "touch-dpad-horizontal",
          "touch-dpad-vertical",
          "touch-start-dive",
          "touch-swim",
          "touch-net-without-quiz",
        ],
        snapshot: await snapshot(),
        errors,
      },
      null,
      2,
    ),
  );
  console.log(
    "Chromium landscape touch emulation: D-pad, dive, swim, capture passed.",
  );
} catch (e) {
  await page.screenshot({
    path: "artifacts/godot/touch-failure.png",
    fullPage: true,
  });
  writeFileSync(
    "artifacts/godot/touch-errors.json",
    JSON.stringify({ error: e.message, errors }, null, 2),
  );
  console.error(e.stack);
  process.exitCode = 1;
} finally {
  await browser.close();
}
