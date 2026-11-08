import { chromium } from "@playwright/test";
import assert from "node:assert/strict";
import { readFileSync, mkdirSync, writeFileSync } from "node:fs";
const fixture = JSON.parse(
  readFileSync(process.env.BROWSER_FIXTURE ?? ".runtime/browser.json", "utf8"),
);
const user = fixture.accounts.find((x) => x.role === "player");
const origin = process.env.APP_TEST_ORIGIN ?? "http://localhost:5173";
mkdirSync("artifacts/godot", { recursive: true });
const browser = await chromium.launch({
  args: [
    "--enable-webgl",
    "--use-gl=angle",
    "--use-angle=swiftshader",
    "--enable-unsafe-swiftshader",
  ],
});
const context = await browser.newContext({
  viewport: { width: 1440, height: 900 },
});
const page = await context.newPage(),
  errors = [];
page.setDefaultTimeout(15000);
page.on("pageerror", (e) => errors.push(e.message));
page.on("console", (m) => {
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
    timeout: 60000,
  });
  await page.waitForTimeout(800);
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
    await page.keyboard.down("d");
    await page.waitForTimeout(1400);
    await page.keyboard.up("d");
    await page.keyboard.press("e");
    await frame.waitForFunction(
      () => window.jalasmaraSnapshot?.diving === true,
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
  await frame.waitForFunction(() => window.jalasmaraSnapshot?.modal === true);
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
  await page.keyboard.press("m");
  await frame.waitForFunction(() => window.jalasmaraSnapshot?.modal === true);
  assert.equal((await snapshot(frame)).modal, true);
  await page.screenshot({ path: "artifacts/godot/map.png", fullPage: true });
  assert.deepEqual(errors, []);
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
  await page.screenshot({
    path: "artifacts/godot/failure.png",
    fullPage: true,
  });
  writeFileSync(
    "artifacts/godot/errors.json",
    JSON.stringify({ error: e.message, errors }, null, 2),
  );
  console.error(e.stack);
  process.exitCode = 1;
} finally {
  await browser.close();
}
