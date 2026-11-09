// Explicit post-release smoke; temporary player lifecycle runs inside the staging app.
// RUN_STAGING_SMOKE=plan06-public PLAN06_EXPECT_PCK=... PLAN06_EXPECT_PCK_BYTES=... node --import tsx scripts/staging-plan06-smoke.mjs
import assert from "node:assert/strict";
import { randomUUID, randomBytes, createHash } from "node:crypto";
import { mkdirSync, writeFileSync } from "node:fs";
import { spawn } from "node:child_process";
import { chromium } from "@playwright/test";
import { fetchWorld } from "./game-navigation.mjs";
import { physicalRoute } from "./plan06-physical-route.mjs";
import { keyboardPulse, corridorTargets } from "./land-view-navigation.mjs";

assert.equal(
  process.env.RUN_STAGING_SMOKE,
  "plan06-public",
  "Explicit post-release staging run required",
);
assert(
  !process.env.BROWSER_FIXTURE,
  "Existing account fixtures are never accepted",
);
const origin = "https://staging-jalasmara.ardianryan.com";
const expectedPck = process.env.PLAN06_EXPECT_PCK;
const expectedPckBytes = Number(process.env.PLAN06_EXPECT_PCK_BYTES);
assert(
  /^[a-f0-9]{64}$/.test(expectedPck ?? ""),
  "PLAN06_EXPECT_PCK must pin the candidate SHA-256.",
);
assert(
  Number.isSafeInteger(expectedPckBytes) && expectedPckBytes > 0,
  "PLAN06_EXPECT_PCK_BYTES must pin its exact size.",
);
const id = randomUUID(),
  email = `plan06-public-${id}@test.invalid`;
const password = randomBytes(24).toString("base64url");
const directory = `artifacts/browser/staging-plan06-${id}`;
mkdirSync(directory, { recursive: true });
const checks = [],
  errors = [],
  failures = [],
  observations = [];
let browser,
  context,
  page,
  frame,
  fixtureAttempted = false,
  cleanup,
  publicPck,
  routeStarted;
const navigation = { matrixPulses: 0 };
function budget() {
  assert(
    !routeStarted || Date.now() - routeStarted < 8 * 60 * 1000,
    "Public physical route exceeded eight minutes.",
  );
}

// No credential is interpolated into this code or the SSH command line.
const remoteCode = String.raw`
import assert from "node:assert/strict";
import { MongoClient } from "mongodb";
import Redis from "ioredis";
import argon2 from "argon2";
let input = "";
for await (const part of process.stdin) input += part;
const p = JSON.parse(input);
assert.equal(process.env.NODE_ENV, "production");
assert.equal(process.env.APP_ORIGIN, "https://staging-jalasmara.ardianryan.com");
assert(/^[a-f0-9]{8}-[a-f0-9]{4}-4[a-f0-9]{3}-[89ab][a-f0-9]{3}-[a-f0-9]{12}$/.test(p.id));
assert.equal(p.email, "plan06-public-" + p.id + "@test.invalid");
assert(["create", "cleanup"].includes(p.action));
const mongo = new MongoClient(process.env.MONGO_URL, { serverSelectionTimeoutMS: 15000 });
const redis = new Redis(process.env.REDIS_URL, { connectTimeout: 10000, maxRetriesPerRequest: 1 });
try {
  await mongo.connect();
  const db = mongo.db(), users = db.collection("players");
  if (p.action === "create") {
    assert.equal(typeof p.password, "string");
    assert(p.password.length >= 24);
    assert.equal(await users.countDocuments({ $or: [{ id: p.id }, { email: p.email }] }), 0);
    assert(await db.collection("contents").findOne({ state: "published" }));
    const { freshAbilities, freshProgress, freshCalendar, freshHomestead } =
      await import("./apps/api/dist/packages/shared/src/index.js");
    const now = new Date().toISOString();
    await users.insertOne({
      id: p.id, email: p.email, name: "Nala Uji Publik 06", role: "player", status: "active",
      appearance: "male_nusantara", coins: 200, inventory: [], abilities: freshAbilities(),
      progress: { ...freshProgress(), day: 1, stage: "dive", tutorial: true },
      adventure: { discoveries: [], puzzles: [], keyItems: [] },
      calendar: { ...freshCalendar(), minuteOfDay: 600 }, homestead: freshHomestead(),
      version: 0, authVersion: 0,
      passwordHash: await argon2.hash(p.password, { type: argon2.argon2id }),
      createdAt: now, updatedAt: now
    });
    console.log(JSON.stringify({ ok: true, created: true }));
  } else {
    const existing = await users.findOne({ id: p.id });
    if (existing) {
      assert.equal(existing.email, p.email);
      assert.equal(existing.role, "player");
      assert.equal(existing.name, "Nala Uji Publik 06");
    }
    await users.deleteOne({ id: p.id, email: p.email, role: "player", name: "Nala Uji Publik 06" });
    await db.collection("receipts").deleteMany({ _id: { $regex: "^" + p.id + ":" } });
    await db.collection("shifts").deleteMany({ userId: p.id });
    const keys = ["surface:", "home:", "calendar:writer:", "dive:"].map(prefix => prefix + p.id);
    for (const digest of p.sessionDigests ?? []) {
      assert(/^[a-f0-9]{64}$/.test(digest));
      const key = "auth:" + digest, raw = await redis.get(key);
      if (raw) { assert.equal(JSON.parse(raw).userId, p.id); keys.push(key); }
    }
    let cursor = "0";
    do {
      const next = await redis.scan(cursor, "MATCH", "auth:*", "COUNT", 100);
      cursor = next[0];
      for (const key of next[1]) {
        const raw = await redis.get(key);
        if (raw && JSON.parse(raw).userId === p.id) keys.push(key);
      }
    } while (cursor !== "0");
    await redis.del(...new Set(keys));
    const remaining = {
      players: await users.countDocuments({ id: p.id }),
      receipts: await db.collection("receipts").countDocuments({ _id: { $regex: "^" + p.id + ":" } }),
      shifts: await db.collection("shifts").countDocuments({ userId: p.id }),
      keys: (await redis.mget(...keys)).filter(value => value !== null).length
    };
    assert(Object.values(remaining).every(value => value === 0));
    console.log(JSON.stringify({ ok: true, remaining }));
  }
} finally { await mongo.close(); await redis.quit(); }
`;
const quoteShell = (value) => "'" + value.replaceAll("'", "'\\''") + "'";
async function remote(action, sessionDigests = []) {
  const command =
    "cd /opt/jalasmara && docker compose exec -T app node --input-type=module -e " +
    quoteShell(remoteCode);
  const child = spawn(
    "ssh",
    [
      "-T",
      "-o",
      "BatchMode=yes",
      "-o",
      "ConnectTimeout=15",
      "-o",
      "ServerAliveInterval=15",
      "-o",
      "ServerAliveCountMax=2",
      "dev-jalasmara",
      command,
    ],
    {
      stdio: ["pipe", "pipe", "pipe"],
    },
  );
  let stdout = "";
  child.stdout.on("data", (chunk) => (stdout += chunk));
  child.stderr.resume();
  child.stdin.on("error", () => {});
  const done = new Promise((resolve, reject) => {
    child.once("error", () =>
      reject(Error(`SSH staging fixture ${action} could not start`)),
    );
    child.once("close", (code) =>
      code === 0
        ? resolve()
        : reject(
            Error(
              `SSH staging fixture ${action} failed (exit ${code}); no credentials logged`,
            ),
          ),
    );
  });
  child.stdin.end(
    JSON.stringify({
      action,
      id,
      email,
      ...(action === "create" ? { password } : { sessionDigests }),
    }),
  );
  await done;
  const result = JSON.parse(stdout.trim());
  assert.equal(result.ok, true);
  return result;
}
const snapshot = () => frame.evaluate(() => window.jalasmaraSnapshot);
async function waitState(predicate, timeout = 30000) {
  const deadline = Date.now() + timeout;
  while (Date.now() < deadline) {
    budget();
    const value = await snapshot();
    if (value && predicate(value)) return value;
    await page.waitForTimeout(180);
  }
  throw Error(
    `Public game state wait expired: ${JSON.stringify(await snapshot())}`,
  );
}
async function attach() {
  await page.locator("iframe").waitFor();
  frame = await (await page.locator("iframe").elementHandle()).contentFrame();
  await frame.waitForFunction(
    () => window.jalasmaraReady && window.jalasmaraSnapshot?.hud,
    null,
    { polling: 200, timeout: 240000 },
  );
  await page.locator(".game-loading").waitFor({ state: "detached" });
  await frame.locator("canvas").focus();
  routeStarted ??= Date.now();
}
async function shot(name) {
  await page.screenshot({ path: `${directory}/${name}.png` });
  const value = await snapshot();
  observations.push({
    name,
    x: value.x,
    y: value.y,
    land: value.land,
    weather: value.weather,
    hud: value.hud,
  });
}
async function walkTo(x, y) {
  const from = await snapshot();
  const onLand = !from.diving && from.area !== "home" && from.land?.active;
  const targets = onLand ? corridorTargets([from.x, from.y], [x, y]) : [[x, y]];
  for (const [targetX, targetY] of targets) await walkDirect(targetX, targetY);
}
async function walkDirect(x, y) {
  await frame.locator("canvas").focus();
  let previous,
    stuck = 0;
  for (let tick = 0; tick < 450; tick++) {
    const value = await snapshot(),
      dx = x - value.x,
      dy = y - value.y,
      distance = Math.hypot(dx, dy);
    assert(!value.modal && !value.homePanel);
    if (distance < 5) return value;
    stuck =
      previous && Math.hypot(value.x - previous.x, value.y - previous.y) < 0.5
        ? stuck + 1
        : 0;
    assert(
      stuck < 20,
      `Public physical route blocked to ${x},${y} at ${value.x},${value.y}`,
    );
    previous = value;
    budget();
    assert(
      value.land?.view?.motion,
      "Public land navigation requires the actual renderer motion contract.",
    );
    const { keys, holdMs, releaseMs } = keyboardPulse(
      [dx, dy],
      value.land.view.motion,
      {
        speed: 100 * (value.traversal?.paceScale ?? 1),
        acceleration: value.area === "forest" ? 1250 : 850,
      },
    );
    navigation.matrixPulses++;
    for (const key of keys) await page.keyboard.down(key);
    try {
      await page.waitForTimeout(holdMs);
    } finally {
      for (const key of keys) await page.keyboard.up(key);
    }
    await page.waitForTimeout(releaseMs);
  }
  throw Error("Public physical navigation exceeded bounded attempts");
}
async function apiState() {
  const response = await context.request.get(`${origin}/api/adventure/state`);
  assert(response.ok());
  return response.json();
}

try {
  const health = await fetch(`${origin}/api/health`, {
    signal: AbortSignal.timeout(15000),
  });
  assert(health.ok, `Public health ${health.status}`);
  assert.equal((await health.json()).status, "ok");
  const response = await fetch(`${origin}/game/index.pck`, {
    signal: AbortSignal.timeout(180000),
  });
  assert(response.ok);
  const hash = createHash("sha256");
  let decodedBytes = 0;
  for await (const bytes of response.body) {
    hash.update(bytes);
    decodedBytes += bytes.length;
    assert(
      decodedBytes <= expectedPckBytes,
      "Public PCK exceeds pinned release size",
    );
  }
  assert.equal(
    hash.digest("hex"),
    expectedPck,
    "Public release PCK must match before creating an account",
  );
  assert.equal(
    decodedBytes,
    expectedPckBytes,
    "Public PCK size must match release",
  );
  // Only validated release metadata reaches the report, never downloaded content.
  publicPck = { sha256: expectedPck, decodedBytes: expectedPckBytes };
  checks.push("public-health-and-downloaded-pck-match-release");
  fixtureAttempted = true;
  await remote("create");
  browser = await chromium.launch({
    args: [
      "--enable-webgl",
      "--use-gl=angle",
      "--use-angle=swiftshader",
      "--enable-unsafe-swiftshader",
    ],
  });
  context = await browser.newContext({
    viewport: { width: 844, height: 390 },
    hasTouch: true,
    isMobile: true,
    deviceScaleFactor: 1,
  });
  page = await context.newPage();
  page.setDefaultTimeout(60000);
  await page.addInitScript(() => {
    window.jalasmaraDiagnostics = true;
  });
  page.on("pageerror", (error) => errors.push(error.message));
  page.on("console", (message) => {
    if (message.type() === "error") errors.push(message.text());
  });
  page.on("response", (response) => {
    if (
      new URL(response.url()).pathname.startsWith("/api/") &&
      response.status() >= 400
    )
      failures.push({
        path: new URL(response.url()).pathname,
        status: response.status(),
      });
  });
  await page.goto(`${origin}/login`);
  await page.getByLabel("Email", { exact: true }).fill(email);
  await page.getByLabel("Password", { exact: true }).fill(password);
  await page.getByRole("button", { name: "Masuk ke Jalasmara" }).click();
  await page.waitForURL("**/play");
  await attach();
  const auth = (await context.cookies()).find(
    (cookie) => cookie.name === "__Host-jalasmara",
  );
  assert(auth?.secure && auth.httpOnly && auth.sameSite === "Lax");
  assert.equal((await snapshot()).land.actors.player, 1);
  await shot("01-public-ready-hub");
  checks.push("public-form-login-secure-cookie-and-real-game-ready");
  const world = await fetchWorld(context.request, origin);
  for (const [x, y] of physicalRoute(
    world,
    await snapshot(),
    world.forest.gate,
    "hub",
  ))
    await walkTo(x, y);
  const travel = page.waitForResponse(
    (response) =>
      response.url().endsWith("/api/adventure/travel") &&
      response.request().method() === "POST",
  );
  await page.keyboard.press("e");
  assert.equal((await (await travel).json()).surface.area, "forest");
  await waitState(
    (value) => value.area === "forest" && value.land?.actors?.player === 1,
  );
  for (const [x, y] of physicalRoute(
    world,
    await snapshot(),
    { x: 350, y: 1250 },
    "forest",
  ))
    await walkTo(x, y);
  await page.waitForTimeout(800);
  const canopy = await snapshot();
  assert.equal(canopy.land.elevationDegrees, 35);
  assert(
    canopy.land.readability.revealed > 0 &&
      canopy.land.readability.revealed < canopy.land.readability.crowns / 4,
  );
  assert(canopy.land.readability.active.every((entry) => entry.amount > 0.99));
  assert(canopy.land.readability.trunksUntouched);
  await page.setViewportSize({ width: 667, height: 375 });
  await page.waitForTimeout(1300);
  await shot("02-public-physical-canopy-667x375");
  checks.push("public-physical-gate-and-settled-local-canopy-reveal");
  const hud = (await snapshot()).hud,
    box = await frame.locator("canvas").boundingBox(),
    cdp = await context.newCDPSession(page);
  const touch = {
    id: 1,
    x: box.x + (hud.journal[0] * box.width) / hud.logicalSize[0],
    y: box.y + (hud.journal[1] * box.height) / hud.logicalSize[1],
    radiusX: 4,
    radiusY: 4,
    force: 1,
  };
  await cdp.send("Input.dispatchTouchEvent", {
    type: "touchStart",
    touchPoints: [touch],
  });
  await page.waitForTimeout(90);
  await cdp.send("Input.dispatchTouchEvent", {
    type: "touchEnd",
    touchPoints: [],
  });
  await waitState((value) => value.modal && value.weather.clockPaused);
  const before = await snapshot();
  await page.keyboard.down("d");
  await page.waitForTimeout(350);
  await page.keyboard.up("d");
  const during = await snapshot();
  assert(Math.hypot(before.x - during.x, before.y - during.y) < 1);
  await shot("03-public-journal-pauses-movement");
  await page.keyboard.press("Escape");
  await waitState((value) => !value.modal && !value.weather.clockPaused);
  await cdp.detach();
  checks.push("public-touch-journal-opens-pauses-and-closes");
  const savedDeadline = Date.now() + 15000;
  let saved;
  while (Date.now() < savedDeadline) {
    saved = await apiState();
    if (
      saved.surface.area === "forest" &&
      Math.hypot(saved.surface.x - before.x, saved.surface.y - before.y) < 25
    )
      break;
    await page.waitForTimeout(400);
  }
  assert.equal(saved.surface.area, "forest");
  assert(
    Math.hypot(saved.surface.x - before.x, saved.surface.y - before.y) < 25,
  );
  await page.reload();
  await attach();
  const resumed = await waitState(
    (value) => value.area === "forest" && value.land?.actors?.player === 1,
  );
  assert(Math.hypot(resumed.x - before.x, resumed.y - before.y) < 30);
  await page.waitForTimeout(800);
  await shot("04-public-forest-resumes-after-reload");
  const finalState = await apiState();
  assert.equal(finalState.player.coins, 200);
  assert.equal(finalState.player.progress.day, 1);
  assert.equal(finalState.calendar.dayLengthMs, 36 * 60 * 1000);
  assert.deepEqual(errors, []);
  assert.deepEqual(failures, []);
  checks.push("public-server-position-reloads-without-story-or-reward-change");
} catch (error) {
  if (frame) await shot("failure").catch(() => {});
  throw error;
} finally {
  const cookies = context ? await context.cookies().catch(() => []) : [];
  if (browser) await browser.close();
  try {
    if (fixtureAttempted)
      cleanup = await remote(
        "cleanup",
        cookies
          .filter((cookie) =>
            ["__Host-jalasmara", "jalasmara"].includes(cookie.name),
          )
          .map((cookie) =>
            createHash("sha256").update(cookie.value).digest("hex"),
          ),
      );
  } finally {
    writeFileSync(
      `${directory}/results.json`,
      JSON.stringify(
        {
          origin,
          expectedPck,
          publicPck,
          navigation,
          routeElapsedMs: routeStarted ? Date.now() - routeStarted : null,
          checks,
          errors,
          failures,
          observations,
          cleanup,
        },
        null,
        2,
      ),
    );
    console.log(
      JSON.stringify({ directory, checks, errors, failures, cleanup }, null, 2),
    );
  }
}
