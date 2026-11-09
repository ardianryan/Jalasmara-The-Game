import { fetchWorld, hubRoute } from "./game-navigation.mjs";
import { chromium, request } from "@playwright/test";
import assert from "node:assert/strict";
import { readFileSync, mkdirSync, writeFileSync } from "node:fs";
import { randomBytes, randomUUID } from "node:crypto";

const origin = process.env.APP_TEST_ORIGIN ?? "http://localhost:3100";
assert(
  ["localhost", "127.0.0.1"].includes(new URL(origin).hostname),
  "Fixture creation is restricted to a local test server.",
);
const source = JSON.parse(
  readFileSync(process.env.BROWSER_FIXTURE ?? ".runtime/browser.json", "utf8"),
);
const owner = source.accounts.find((account) => account.role === "owner");
assert(owner, "Local owner fixture is required to invite an isolated player.");
const artifacts = "artifacts/godot/geographic-map";
mkdirSync(artifacts, { recursive: true });
const errors = [];
const failures = [];
const checks = [];
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
const page = await context.newPage();
page.setDefaultTimeout(20000);
page.on("pageerror", (error) => errors.push(error.message));
page.on("console", (message) => {
  if (message.type() === "error") errors.push(message.text());
});
page.on("response", async (response) => {
  if (response.url().includes("/api/") && response.status() >= 400)
    failures.push({
      url: new URL(response.url()).pathname,
      status: response.status(),
      body: await response.json().catch(() => null),
    });
});
let player;
let frame;
let csrf;
const snapshot = () => frame.evaluate(() => window.jalasmaraSnapshot);
async function post(api, path, data, token) {
  const response = await api.post(`${origin}/api${path}`, {
    data,
    headers: {
      Origin: origin,
      "X-CSRF-Token": token ?? "",
      "Idempotency-Key": randomUUID(),
    },
  });
  const body = await response.json();
  assert(
    response.ok(),
    `${path}: ${response.status()} ${JSON.stringify(body)}`,
  );
  return body;
}
async function attachFrame() {
  await page.locator("iframe").waitFor();
  frame = await (await page.locator("iframe").elementHandle()).contentFrame();
  await frame.waitForFunction(
    () => window.jalasmaraReady === true && window.jalasmaraSnapshot != null,
    null,
    { timeout: 90000 },
  );
}
async function walkTo(x, y, maxSteps = 240) {
  let stuck = 0;
  let previous;
  for (let step = 0; step < maxSteps; step++) {
    const at = await snapshot();
    assert(!at.modal, `Unexpected modal while walking: ${JSON.stringify(at)}`);
    const dx = x - at.x;
    const dy = y - at.y;
    if (Math.hypot(dx, dy) < 23) return at;
    const keys = [];
    if (Math.abs(dx) > 12) keys.push(dx > 0 ? "d" : "a");
    if (Math.abs(dy) > 12) keys.push(dy > 0 ? "s" : "w");
    for (const key of keys) await page.keyboard.down(key);
    await page.waitForTimeout(145);
    for (const key of keys) await page.keyboard.up(key);
    await page.waitForTimeout(100);
    if (previous && Math.hypot(at.x - previous.x, at.y - previous.y) < 2)
      stuck++;
    else stuck = 0;
    assert(
      stuck < 14,
      `Collision prevents path to ${x},${y}; ${JSON.stringify(at)}`,
    );
    previous = at;
  }
  throw Error(
    `Walking timed out toward ${x},${y}: ${JSON.stringify(await snapshot())}`,
  );
}
try {
  const admin = await request.newContext();
  const guest = await admin.get(`${origin}/api/auth/session`);
  const guestSession = await guest.json();
  const login = await post(
    admin,
    "/auth/login",
    { email: owner.email, password: source.password },
    guestSession.csrf,
  );
  const email = `map-${Date.now()}-${randomBytes(3).toString("hex")}@example.test`;
  const password = `Forest-${randomBytes(20).toString("base64url")}!`;
  const invitation = await post(
    admin,
    "/admin/invitations",
    { email, reason: "Isolated local geographic-map browser acceptance test" },
    login.csrf,
  );
  const token = new URL(invitation.url).hash.slice(1);
  const activationSession = await (
    await context.request.get(`${origin}/api/auth/session`)
  ).json();
  const activated = await post(
    context.request,
    "/auth/activate",
    { token, password, name: "Penjelajah Peta Uji" },
    activationSession.csrf,
  );
  csrf = activated.csrf;
  player = activated.user;
  writeFileSync(
    ".runtime/geographic-map-browser.json",
    JSON.stringify(
      {
        accounts: [{ id: player.id, email, role: "player" }],
        password,
        createdAt: new Date().toISOString(),
      },
      null,
      2,
    ),
    { mode: 0o600 },
  );
  await post(context.request, "/game/tutorial", {}, csrf);
  await admin.dispose();
  await page.addInitScript(() => {
    window.jalasmaraDiagnostics = true;
  });
  await page.goto(`${origin}/play`);
  await attachFrame();
  await frame.waitForFunction(() => window.jalasmaraSnapshot?.modal === true);
  await page.screenshot({
    path: `${artifacts}/01-character.png`,
    fullPage: true,
  });
  await frame.locator("canvas").focus();
  const appearanceSaved = page.waitForResponse((response) =>
    response.url().endsWith("/api/game/appearance"),
  );
  await page.keyboard.press("Enter");
  const appearanceResult = await (await appearanceSaved).json();
  assert.equal(appearanceResult.player.appearance, "male_default");
  await frame.waitForFunction(() => window.jalasmaraSnapshot?.modal === false);
  checks.push("new-player-first-appearance-keyboard");
  await frame.locator("canvas").click({ position: { x: 450, y: 350 } });
  const world = await fetchWorld(context.request, origin);
  const at = await snapshot();
  await page.keyboard.press("m");
  await frame.waitForFunction(() => window.jalasmaraSnapshot?.modal === true);
  checks.push("M-opens-geographic-map");
  const canvas = frame.locator("canvas");
  const bounds = await canvas.boundingBox();
  const native = (x, y) => ({
    x: bounds.x + (x / 960) * bounds.width,
    y: bounds.y + (y / 540) * bounds.height,
  });
  const mapCenter = native(455, 255);
  const mapClip = {
    ...native(150, 175),
    width: (600 / 960) * bounds.width,
    height: (200 / 540) * bounds.height,
  };
  await page.waitForTimeout(500);
  const fullMap = await page.screenshot({
    path: `${artifacts}/01-geographic-map.png`,
    clip: mapClip,
  });
  await page.mouse.move(mapCenter.x, mapCenter.y);
  await page.mouse.wheel(0, -600);
  await page.waitForTimeout(500);
  const zoomed = await page.screenshot({
    path: `${artifacts}/02-zoomed-map.png`,
    clip: mapClip,
  });
  assert(
    !fullMap.equals(zoomed),
    "Mouse wheel must change geographic map view",
  );
  checks.push("wheel-zoom-changes-geography");
  await page.mouse.down();
  await page.mouse.move(mapCenter.x + 100, mapCenter.y + 60, { steps: 12 });
  await page.mouse.up();
  await page.waitForTimeout(400);
  const panned = await page.screenshot({
    path: `${artifacts}/03-panned-map.png`,
    clip: mapClip,
  });
  assert(!zoomed.equals(panned), "Dragging must move geographic map view");
  checks.push("drag-pans-geographic-map");
  // Plus/minus are native Godot buttons; preserve their position in the map header.
  const plus = native(762, 122);
  await page.mouse.click(plus.x, plus.y);
  await page.waitForTimeout(350);
  await page.screenshot({
    path: `${artifacts}/04-map-controls.png`,
    fullPage: true,
  });
  checks.push("map-header-controls-clickable");
  await page.keyboard.press("m");
  await frame.waitForFunction(() => window.jalasmaraSnapshot?.modal === false);
  checks.push("M-closes-map");
  const route = hubRoute(world, at, world.hub.divePoint);
  const point = route[Math.min(1, route.length - 1)];
  await walkTo(point[0], point[1]);
  const moved = await snapshot();
  assert(
    Math.hypot(moved.x - at.x, moved.y - at.y) > 40,
    "Player must move after map closes",
  );
  await page.screenshot({
    path: `${artifacts}/05-minimap-after-movement.png`,
    fullPage: true,
  });
  checks.push("movement-after-map-and-minimap-screenshot");
  assert.deepEqual(failures, []);
  assert.deepEqual(errors, []);
  writeFileSync(
    `${artifacts}/results.json`,
    JSON.stringify(
      {
        origin,
        playerId: player.id,
        checks,
        errors,
        failures,
        snapshot: await snapshot(),
      },
      null,
      2,
    ),
  );
  console.log(`Geographic map browser PASS: ${checks.join(", ")}`);
} catch (error) {
  await page
    .screenshot({ path: `${artifacts}/failure.png`, fullPage: true })
    .catch(() => {});
  writeFileSync(
    `${artifacts}/failure.json`,
    JSON.stringify(
      {
        error: error.message,
        checks,
        errors,
        failures,
        snapshot: frame ? await snapshot().catch(() => null) : null,
      },
      null,
      2,
    ),
  );
  console.error(error.stack);
  process.exitCode = 1;
} finally {
  await browser.close();
}
