// Local acceptance with the actual exported game, API and physically traversed paths.
// Run: node --import tsx scripts/plan06-forest-browser.mjs
import { chromium } from "@playwright/test";
import { MongoClient } from "mongodb";
import Redis from "ioredis";
import argon2 from "argon2";
import { randomUUID, randomBytes, createHash } from "node:crypto";
import { mkdirSync, writeFileSync } from "node:fs";
import assert from "node:assert/strict";
import {
  freshAbilities,
  freshProgress,
  freshCalendar,
  freshHomestead,
} from "../packages/shared/src/index.ts";
import { fetchWorld, hubRoute } from "./game-navigation.mjs";

const origin = process.env.APP_TEST_ORIGIN ?? "http://localhost:3100";
const mongoUrl =
  process.env.MONGO_URL ?? "mongodb://127.0.0.1:27018/jalasmara?replicaSet=rs0";
const redisUrl = process.env.REDIS_URL ?? "redis://127.0.0.1:6380";
assert(
  !process.env.BROWSER_FIXTURE,
  "Existing players and owner fixtures are not accepted.",
);
assert(["localhost", "127.0.0.1"].includes(new URL(origin).hostname));
assert(/^mongodb:\/\/(127\.0\.0\.1|localhost)(:|\/)/.test(mongoUrl));
assert(["localhost", "127.0.0.1"].includes(new URL(redisUrl).hostname));
const directory = "artifacts/browser/plan06-forest";
mkdirSync(directory, { recursive: true });
const id = randomUUID(),
  email = `plan06-forest-${id}@test.invalid`,
  password = randomBytes(24).toString("base64url");
const mongo = new MongoClient(mongoUrl);
const checks = [],
  observations = [],
  operations = [],
  errors = [],
  failures = [];
let browser,
  context,
  page,
  frame,
  world,
  cdp,
  cleaned = false,
  lastSnapshot;
const snapshot = () => frame.evaluate(() => window.jalasmaraSnapshot);
async function waitState(predicate, timeout = 30000) {
  const start = Date.now();
  while (Date.now() - start < timeout) {
    const value = await snapshot();
    if (value && predicate(value)) return value;
    await page.waitForTimeout(180);
  }
  throw Error(`State wait expired: ${JSON.stringify(await snapshot())}`);
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
}
async function shot(name) {
  await page.screenshot({ path: `${directory}/${name}.png` });
  const value = await snapshot();
  observations.push({
    name,
    at: new Date().toISOString(),
    x: value.x,
    y: value.y,
    area: value.area ?? value.land?.area,
    land: value.land,
    weather: value.weather,
    hud: value.hud,
  });
}
async function walkTo(x, y) {
  await frame.locator("canvas").focus();
  let previous,
    stuck = 0;
  for (let tick = 0; tick < 450; tick++) {
    const value = await snapshot(),
      dx = x - value.x,
      dy = y - value.y,
      distance = Math.hypot(dx, dy);
    assert(
      !value.modal && !value.homePanel,
      "A modal cannot be bypassed while navigating.",
    );
    if (distance < 15) return value;
    stuck =
      previous && Math.hypot(value.x - previous.x, value.y - previous.y) < 0.5
        ? stuck + 1
        : 0;
    assert(
      stuck < 20,
      `Physical collision blocks ${x},${y}; actual ${value.x},${value.y}`,
    );
    previous = value;
    const threshold = stuck > 2 ? 3 : 8;
    const keys = [];
    if (Math.abs(dx) > threshold) keys.push(dx > 0 ? "d" : "a");
    if (Math.abs(dy) > threshold) keys.push(dy > 0 ? "s" : "w");
    for (const key of keys) await page.keyboard.down(key);
    await page.waitForTimeout(distance > 150 ? 330 : distance > 50 ? 200 : 90);
    for (const key of keys) await page.keyboard.up(key);
    await page.waitForTimeout(90);
  }
  throw Error(
    `Bounded navigation timed out at ${JSON.stringify(await snapshot())}`,
  );
}
async function routeTo(point, area) {
  const graph =
    area === "forest"
      ? { hub: { paths: world.landMaps.forest.routes } }
      : world;
  for (const [x, y] of hubRoute(graph, await snapshot(), point))
    await walkTo(x, y);
}
async function apiState() {
  const response = await context.request.get(`${origin}/api/adventure/state`);
  assert(response.ok());
  return response.json();
}
async function waitSaved(at) {
  const deadline = Date.now() + 15000;
  while (Date.now() < deadline) {
    const state = await apiState();
    if (
      state.surface?.area === "forest" &&
      Math.hypot(state.surface.x - at.x, state.surface.y - at.y) < 25
    )
      return state;
    await page.waitForTimeout(400);
  }
  throw Error(
    "The physically reached forest position was not saved by the game.",
  );
}
async function touchPoint(center, pointer = 1) {
  const value = await snapshot(),
    box = await frame.locator("canvas").boundingBox();
  return {
    x: box.x + (center[0] * box.width) / value.hud.logicalSize[0],
    y: box.y + (center[1] * box.height) / value.hud.logicalSize[1],
    id: pointer,
    radiusX: 4,
    radiusY: 4,
    force: 1,
  };
}
async function tap(name) {
  const point = await touchPoint((await snapshot()).hud[name]);
  await cdp.send("Input.dispatchTouchEvent", {
    type: "touchStart",
    touchPoints: [point],
  });
  await page.waitForTimeout(90);
  await cdp.send("Input.dispatchTouchEvent", {
    type: "touchEnd",
    touchPoints: [],
  });
}
async function responsive(width, height, label) {
  await page.setViewportSize({ width, height });
  await page.waitForTimeout(1300);
  const value = await snapshot(),
    box = await page.locator("iframe").boundingBox(),
    logical = value.hud.logicalSize;
  assert.equal(value.hud.touch, true);
  assert(Math.abs(box.width - width) < 2 && Math.abs(box.height - height) < 2);
  assert(Math.abs(logical[0] / logical[1] - width / height) < 0.015);
  assert.equal(
    await page.evaluate(
      () => document.documentElement.scrollWidth > innerWidth,
    ),
    false,
  );
  for (const name of ["bag", "journal", "map", "action"]) {
    const point = value.hud[name];
    assert(
      point[0] >= 0 &&
        point[1] >= 0 &&
        point[0] <= logical[0] &&
        point[1] <= logical[1],
    );
  }
  assert.equal(value.land.actors.player, 1);
  assert.equal(value.land.elevationDegrees, 35);
  assert(value.land.maxFootError < 0.1);
  await shot(label);
}

try {
  await mongo.connect();
  assert(
    await mongo.db().collection("contents").findOne({ state: "published" }),
    "Published local content required.",
  );
  const now = new Date().toISOString();
  await mongo
    .db()
    .collection("players")
    .insertOne({
      id,
      email,
      name: "Nala Uji Rute 06",
      role: "player",
      status: "active",
      appearance: "male_nusantara",
      coins: 200,
      inventory: [],
      abilities: freshAbilities(),
      progress: { ...freshProgress(), day: 1, stage: "dive", tutorial: true },
      adventure: { discoveries: [], puzzles: [], keyItems: [] },
      calendar: { ...freshCalendar(), minuteOfDay: 600 },
      homestead: freshHomestead(),
      version: 0,
      authVersion: 0,
      passwordHash: await argon2.hash(password, { type: argon2.argon2id }),
      createdAt: now,
      updatedAt: now,
    });
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
  cdp = await context.newCDPSession(page);
  await page.addInitScript(() => {
    window.jalasmaraDiagnostics = true;
  });
  page.on("pageerror", (error) => errors.push(error.message));
  page.on("console", (message) => {
    if (message.type() === "error") errors.push(message.text());
  });
  page.on("response", async (response) => {
    const path = new URL(response.url()).pathname;
    if (!path.startsWith("/api/")) return;
    if (response.status() >= 400)
      failures.push({ path, status: response.status() });
    if (
      response.request().method() !== "POST" ||
      !["/api/adventure/travel", "/api/adventure/surface-position"].includes(
        path,
      )
    )
      return;
    const body = await response.json().catch(() => ({}));
    operations.push({ path, status: response.status(), surface: body.surface });
  });
  await page.goto(`${origin}/login`);
  await page.getByLabel("Email", { exact: true }).fill(email);
  await page.getByLabel("Password", { exact: true }).fill(password);
  await page.getByRole("button", { name: "Masuk ke Jalasmara" }).click();
  await page.waitForURL("**/play");
  await attach();
  world = await fetchWorld(context.request, origin);
  await routeTo(world.forest.gate, "hub");
  const travel = page.waitForResponse(
    (response) =>
      response.url().endsWith("/api/adventure/travel") &&
      response.request().method() === "POST",
  );
  await page.keyboard.press("e");
  assert.equal((await (await travel).json()).surface.area, "forest");
  await waitState(
    (value) =>
      value.area === "forest" &&
      value.land?.readability &&
      value.land?.actors?.player === 1,
  );
  await page.waitForTimeout(700);
  await shot("01-physical-forest-entry");
  checks.push("physical-hub-gate-to-forest-entry-with-real-3d-player");

  await walkTo(350, 1250);
  await page.waitForTimeout(700);
  const gateway = await snapshot(),
    originalCrowns = gateway.land.readability.active.map(
      (entry) => entry.index,
    );
  assert(
    originalCrowns.length > 0 &&
      originalCrowns.length < gateway.land.readability.crowns / 4,
  );
  assert(gateway.land.readability.active.every((entry) => entry.amount > 0.99));
  await responsive(667, 375, "02-gateway-667x375");
  const beforeModal = await snapshot();
  const pausedHeartbeat = page.waitForResponse(
    (response) =>
      response.url().endsWith("/api/calendar/heartbeat") &&
      response.request().postDataJSON()?.paused === true,
  );
  await tap("journal");
  await waitState((value) => value.modal && value.weather.clockPaused);
  const pausedCalendarResponse = await pausedHeartbeat;
  assert(pausedCalendarResponse.ok());
  const pausedCalendar = (await pausedCalendarResponse.json()).calendar;
  await page.keyboard.down("d");
  await page.waitForTimeout(350);
  await page.keyboard.up("d");
  const paused = await snapshot();
  assert(Math.hypot(paused.x - beforeModal.x, paused.y - beforeModal.y) < 1);
  await page.waitForTimeout(6200);
  assert.equal(
    (await apiState()).calendar.minuteOfDay,
    pausedCalendar.minuteOfDay,
    "The actual server calendar must stay paused through the next heartbeat while reading",
  );
  await shot("03-journal-pauses-under-canopy");
  await page.keyboard.press("Escape");
  await waitState((value) => !value.modal && !value.weather.clockPaused);
  checks.push("localized-settled-canopy-and-touch-journal-pause-at-667x375");

  await responsive(844, 390, "04-gateway-844x390");
  const joystick = (await snapshot()).hud.joystick,
    start = await touchPoint(joystick.center),
    moved = await touchPoint([
      joystick.center[0] + joystick.radius * 0.65,
      joystick.center[1] - joystick.radius * 0.25,
    ]);
  const prior = await snapshot();
  await cdp.send("Input.dispatchTouchEvent", {
    type: "touchStart",
    touchPoints: [start],
  });
  await cdp.send("Input.dispatchTouchEvent", {
    type: "touchMove",
    touchPoints: [moved],
  });
  await page.waitForTimeout(350);
  assert(Math.hypot(...(await snapshot()).hud.joystick.direction) > 0.1);
  await cdp.send("Input.dispatchTouchEvent", {
    type: "touchEnd",
    touchPoints: [],
  });
  await page.waitForTimeout(350);
  const released = await snapshot();
  assert(Math.hypot(...released.hud.joystick.direction) < 0.01);
  assert(Math.hypot(released.x - prior.x, released.y - prior.y) > 2);
  checks.push(
    "round-joystick-physically-moves-and-releases-in-forest-at-844x390",
  );
  await responsive(1440, 900, "05-gateway-desktop-width-touch-context");
  checks.push("desktop-width-preserves-3d-projection-and-hud-context");

  await walkTo(480, 1210);
  await walkTo(650, 1050);
  await page.waitForTimeout(1000);
  const canopy = await snapshot();
  assert.equal(canopy.nearby, "forest_canopy");
  assert(
    originalCrowns.every(
      (index) =>
        !canopy.land.readability.active.some((entry) => entry.index === index),
    ),
    "Entrance crowns must recover after leaving them",
  );
  await shot("06-canopy-clearing-restored-entrance-crowns");
  await waitSaved(canopy);
  await page.reload();
  await attach();
  const resumed = await waitState(
    (value) => value.area === "forest" && value.land?.actors?.player === 1,
  );
  assert(Math.hypot(resumed.x - canopy.x, resumed.y - canopy.y) < 30);
  await shot("07-forest-save-reload");
  checks.push(
    "entrance-crowns-restore-and-physical-forest-position-survives-reload",
  );

  for (const bridge of world.landMaps.forest.bridges) {
    const [a, b] = bridge.path;
    await routeTo({ x: a[0], y: a[1] }, "forest");
    const before = await snapshot();
    await walkTo(b[0], b[1]);
    const after = await snapshot(),
      emitted = after.land.bridges[bridge.id];
    assert(Math.hypot(after.x - before.x, after.y - before.y) > 250);
    assert(
      emitted &&
        emitted.oriented &&
        emitted.railPosts >= 8 &&
        emitted.thickness >= 12,
    );
    assert.equal(after.diving, false);
    await shot(`08-${bridge.id}-crossed`);
    checks.push(
      `${bridge.id}-crossed-physically-with-deck-rails-and-ground-foot-pivot`,
    );
  }
  await routeTo({ x: 200, y: 1320 }, "forest");
  await waitState((value) => value.nearby === "return");
  const returning = page.waitForResponse(
    (response) =>
      response.url().endsWith("/api/adventure/travel") &&
      response.request().method() === "POST",
  );
  await page.keyboard.press("e");
  assert.equal((await (await returning).json()).surface.area, "hub");
  await waitState(
    (value) =>
      value.area !== "forest" &&
      value.land?.area === "hub" &&
      value.land?.actors?.player === 1,
  );
  await shot("09-return-through-real-portal");
  const finalState = await apiState();
  assert.equal(finalState.surface.area, "hub");
  assert.equal(
    finalState.player.coins,
    200,
    "World readability and physical navigation must not invent rewards",
  );
  assert.equal(finalState.player.progress.day, 1);
  assert.equal(finalState.calendar.dayLengthMs, 36 * 60 * 1000);
  assert.equal((await snapshot()).weather.dayLengthMinutes, 36);
  checks.push(
    "physical-return-portal-keeps-story-coins-and-authoritative-surface",
  );
  assert.deepEqual(errors, []);
  assert.deepEqual(failures, []);
  lastSnapshot = await snapshot();
  console.log(
    JSON.stringify(
      {
        checks,
        errors,
        failures,
        positionSyncs: operations.filter((operation) =>
          operation.path.endsWith("surface-position"),
        ).length,
      },
      null,
      2,
    ),
  );
} catch (error) {
  if (page) await shot("failure").catch(() => {});
  lastSnapshot = frame ? await snapshot().catch(() => null) : null;
  throw error;
} finally {
  const cookies = context ? await context.cookies().catch(() => []) : [];
  if (browser) await browser.close();
  const cache = new Redis(redisUrl);
  try {
    await mongo
      .db()
      .collection("players")
      .deleteOne({ id, email, role: "player" });
    await mongo
      .db()
      .collection("receipts")
      .deleteMany({ _id: { $regex: `^${id}:` } });
    await mongo.db().collection("shifts").deleteMany({ userId: id });
    const keys = [
      `surface:${id}`,
      `home:${id}`,
      `calendar:writer:${id}`,
      `dive:${id}`,
    ];
    for (const cookie of cookies.filter((value) => value.name === "jalasmara"))
      keys.push(
        `auth:${createHash("sha256").update(cookie.value).digest("hex")}`,
      );
    await cache.del(...keys);
    assert.equal(
      await mongo
        .db()
        .collection("players")
        .countDocuments({ id, email, role: "player" }),
      0,
    );
    cleaned = true;
  } finally {
    await mongo.close();
    await cache.quit();
    writeFileSync(
      `${directory}/results.json`,
      JSON.stringify(
        {
          checks,
          errors,
          failures,
          operations,
          observations,
          lastSnapshot,
          ownTemporaryPlayerRemoved: cleaned,
        },
        null,
        2,
      ),
    );
  }
}
