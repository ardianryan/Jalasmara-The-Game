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
const artifacts = "artifacts/godot/forest";
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
  const email = `forest-${Date.now()}-${randomBytes(3).toString("hex")}@example.test`;
  const password = `Forest-${randomBytes(20).toString("base64url")}!`;
  const invitation = await post(
    admin,
    "/admin/invitations",
    { email, reason: "Isolated local forest browser acceptance test" },
    login.csrf,
  );
  const token = new URL(invitation.url).hash.slice(1);
  const activationSession = await (
    await context.request.get(`${origin}/api/auth/session`)
  ).json();
  const activated = await post(
    context.request,
    "/auth/activate",
    { token, password, name: "Penjelajah Hutan Uji" },
    activationSession.csrf,
  );
  csrf = activated.csrf;
  player = activated.user;
  writeFileSync(
    ".runtime/forest-browser.json",
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
  for (const [x, y] of hubRoute(world, await snapshot(), world.forest.gate))
    await walkTo(x, y);
  const travel = page.waitForResponse((response) =>
    response.url().endsWith("/api/adventure/travel"),
  );
  await page.keyboard.press("e");
  assert.equal((await (await travel).json()).surface.area, "forest");
  await frame.waitForFunction(
    () => window.jalasmaraSnapshot?.area === "forest",
    null,
    { timeout: 30000 },
  );
  assert.equal((await snapshot()).diving, false);
  checks.push("physical-hub-gate-travel");
  await page.screenshot({ path: `${artifacts}/02-entry.png`, fullPage: true });
  const entry = await snapshot();
  for (const [x, y] of [
    [350, 1250],
    [480, 1210],
    [650, 1050],
  ])
    await walkTo(x, y);
  const canopy = await snapshot();
  assert(
    Math.abs(canopy.x - entry.x) > 300 && Math.abs(canopy.y - entry.y) > 150,
    "Forest must allow movement on both axes.",
  );
  assert.equal(canopy.nearby, "forest_canopy");
  checks.push("free-two-axis-keyboard-exploration");
  await page.screenshot({ path: `${artifacts}/03-canopy.png`, fullPage: true });
  const discovery = page.waitForResponse((response) =>
    response.url().endsWith("/api/adventure/surface-interact"),
  );
  await page.keyboard.press("e");
  const learned = await (await discovery).json();
  assert(learned.adventure.discoveries.includes("forest_canopy"));
  assert(learned.knowledge.text.length > 30);
  assert.equal(learned.reward, 80);
  await frame.waitForFunction(() => window.jalasmaraSnapshot?.modal === true);
  checks.push("server-validated-learning-and-reward");
  await page.screenshot({
    path: `${artifacts}/04-discovery.png`,
    fullPage: true,
  });
  await page.keyboard.press("Escape");
  await frame.waitForFunction(() => window.jalasmaraSnapshot?.modal === false);
  await page.keyboard.press("j");
  await frame.waitForFunction(() => window.jalasmaraSnapshot?.modal === true);
  await page.screenshot({
    path: `${artifacts}/05-journal.png`,
    fullPage: true,
  });
  checks.push("discovery-journal");
  await page.keyboard.press("Escape");
  await frame.waitForFunction(() => window.jalasmaraSnapshot?.modal === false);
  await page.keyboard.press("c");
  await frame.waitForFunction(() => window.jalasmaraSnapshot?.modal === true);
  await page.keyboard.press("Tab");
  const changedAppearance = page.waitForResponse((response) =>
    response.url().endsWith("/api/game/appearance"),
  );
  await page.keyboard.press("Enter");
  const changed = await (await changedAppearance).json();
  assert.equal(changed.player.appearance, "male_nusantara");
  await frame.waitForFunction(
    () =>
      window.jalasmaraSnapshot?.modal === false &&
      window.jalasmaraSnapshot?.appearance === "male_nusantara",
  );
  await page.screenshot({
    path: `${artifacts}/06-nusantara-character.png`,
    fullPage: true,
  });
  checks.push("forest-character-change-preserves-location");
  await page.keyboard.press("m");
  await frame.waitForFunction(() => window.jalasmaraSnapshot?.modal === true);
  await page.screenshot({
    path: `${artifacts}/07-world-atlas.png`,
    fullPage: true,
  });
  await page.keyboard.press("Escape");
  await frame.waitForFunction(() => window.jalasmaraSnapshot?.modal === false);
  checks.push("world-atlas-with-locked-regions");
  await page.waitForTimeout(2500);
  await page.reload();
  await attachFrame();
  await frame.waitForFunction(
    () => window.jalasmaraSnapshot?.area === "forest",
  );
  assert(
    Math.hypot(
      (await snapshot()).x - canopy.x,
      (await snapshot()).y - canopy.y,
    ) < 35,
  );
  await page.screenshot({
    path: `${artifacts}/08-refresh-resume.png`,
    fullPage: true,
  });
  checks.push("direct-forest-refresh-ready-and-position-resume");
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
  console.log(`Forest browser PASS: ${checks.join(", ")}`);
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
