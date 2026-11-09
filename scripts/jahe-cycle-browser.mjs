// APP_TEST_ORIGIN=http://localhost:3111 PLAN06_EXPECT_PCK=<sha256> PLAN06_EXPECT_PCK_BYTES=<bytes> node --import tsx scripts/jahe-cycle-browser.mjs
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
  calendarRain,
} from "../packages/shared/src/index.ts";
import { WORLD } from "../packages/shared/src/world.ts";
import { fetchWorld } from "./game-navigation.mjs";
import { physicalRoute } from "./plan06-physical-route.mjs";
import { corridorTargets, keyboardPulse } from "./land-view-navigation.mjs";
import { deriveJaheCycleFixture } from "./jahe-cycle-fixture.mjs";
import { findFixtureAuthKeys } from "./own-fixture-auth.mjs";

const origin = process.env.APP_TEST_ORIGIN ?? "http://localhost:3111";
assert(
  ["localhost", "127.0.0.1"].includes(new URL(origin).hostname) &&
    new URL(origin).port === "3111",
  "Only dedicated local3111 is allowed",
);
assert(
  !process.env.BROWSER_FIXTURE,
  "Existing accounts/fixtures are not accepted",
);
const mongoUrl =
  process.env.MONGO_URL ?? "mongodb://127.0.0.1:27018/jalasmara?replicaSet=rs0";
const redisUrl = process.env.REDIS_URL ?? "redis://127.0.0.1:6380";
assert(/^mongodb:\/\/(127\.0\.0\.1|localhost)(:|\/)/.test(mongoUrl));
assert(["localhost", "127.0.0.1"].includes(new URL(redisUrl).hostname));
const expectedPck = process.env.PLAN06_EXPECT_PCK,
  expectedBytes = Number(process.env.PLAN06_EXPECT_PCK_BYTES);
assert(
  /^[a-f0-9]{64}$/.test(expectedPck ?? ""),
  "New candidate PCK SHA256 is mandatory",
);
assert(
  Number.isSafeInteger(expectedBytes) && expectedBytes > 0,
  "Exact candidate PCK bytes are mandatory",
);
let id = randomUUID();
const careDays = [2, 3, 4, 5];
while (careDays.some((day) => calendarRain(id, day))) id = randomUUID();
const setup = deriveJaheCycleFixture(WORLD);
const email = `jahe-cycle-${id}@test.invalid`,
  password = randomBytes(24).toString("base64url");
const artifacts = `artifacts/browser/jahe-cycle-${id}`;
mkdirSync(artifacts, { recursive: true });
const mongo = new MongoClient(mongoUrl),
  checks = [],
  operations = [],
  errors = [],
  failures = [],
  trace = [],
  ledger = [];
const requestTimes = new WeakMap();
let browser,
  context,
  page,
  frame,
  world,
  created = false,
  fixtureAttempted = false,
  cleaned = false,
  completed = false,
  phase = "setup",
  routeStarted,
  heartbeat,
  failureSnapshot = null,
  failureScreenshot = false,
  browserClosed = false,
  ownAuthKeysRemaining = null;
const snapshot = () => frame.evaluate(() => window.jalasmaraSnapshot);
function budget() {
  assert(
    !routeStarted || Date.now() - routeStarted < 15 * 60 * 1000,
    "Bounded fifteen-minute jahe route exceeded",
  );
}
async function waitState(predicate, timeout = 25000) {
  const start = Date.now();
  while (Date.now() - start < timeout) {
    budget();
    const s = await snapshot();
    if (predicate(s)) return s;
    await page.waitForTimeout(200);
  }
  throw Error("State timeout: " + JSON.stringify(await snapshot()));
}
async function attach() {
  await page.locator("iframe").waitFor();
  frame = await (await page.locator("iframe").elementHandle()).contentFrame();
  await frame.waitForFunction(
    () => window.jalasmaraReady && window.jalasmaraSnapshot,
    null,
    { timeout: 240000, polling: 200 },
  );
  await page.locator(".game-loading").waitFor({ state: "detached" });
  await frame.locator("canvas").focus();
  routeStarted ??= Date.now();
}
async function apiState() {
  const r = await context.request.get(`${origin}/api/homestead/state`);
  assert(r.ok());
  const state = await r.json();
  ledger.push({
    phase,
    version: state.player.version,
    coins: state.player.coins,
    calendarDay: state.calendar.calendarDay,
    revision: state.homestead.revision,
    storyDay: state.player.progress.day,
    seeds: state.homestead.seeds,
    plots: state.homestead.plots,
    pantry: state.homestead.pantry,
    liveCatch: state.homestead.liveCatch,
    pen: state.homestead.fishPen,
    produce: state.homestead.produce,
    inventory: state.player.inventory,
  });
  return state;
}
async function walkDirect(x, y, inside = false) {
  let previous,
    stuck = 0;
  for (let i = 0; i < 450; i++) {
    budget();
    const s = await snapshot(),
      dx = x - s.x,
      dy = y - s.y;
    const distance = Math.hypot(dx, dy);
    if (distance < (inside ? 12 : 5)) return;
    assert(!s.modal && !s.homePanel && !s.diving);
    stuck =
      previous && Math.hypot(s.x - previous.x, s.y - previous.y) < 0.5
        ? stuck + 1
        : 0;
    assert(stuck < 20, `Blocked ${phase} route ${x},${y} at ${s.x},${s.y}`);
    previous = s;
    let control;
    if (inside) {
      const keys = [];
      if (Math.abs(dx) > 4) keys.push(dx > 0 ? "d" : "a");
      if (Math.abs(dy) > 4) keys.push(dy > 0 ? "s" : "w");
      control = { keys, holdMs: distance < 90 ? 110 : 160, releaseMs: 230 };
    } else {
      assert(s.land?.view?.motion);
      control = keyboardPulse([dx, dy], s.land.view.motion, {
        speed: 100 * (s.traversal?.paceScale ?? 1),
        acceleration: 850,
      });
    }
    for (const key of control.keys) await page.keyboard.down(key);
    try {
      await page.waitForTimeout(control.holdMs);
    } finally {
      for (const key of control.keys) await page.keyboard.up(key);
    }
    await page.waitForTimeout(control.releaseMs);
  }
  throw Error("Route limit");
}
async function routeTo(point, inside = false) {
  await frame.locator("canvas").focus();
  for (const [x, y] of physicalRoute(
    world,
    await snapshot(),
    point,
    inside ? "home" : "hub",
  )) {
    const from = await snapshot();
    for (const [tx, ty] of inside
      ? [[x, y]]
      : corridorTargets([from.x, from.y], [x, y]))
      await walkDirect(tx, ty, inside);
  }
  await page.waitForTimeout(450);
}
async function openAt(point, nearby) {
  await routeTo(point);
  await waitState((s) => s.nearby === nearby);
  await page.keyboard.press("e");
  await waitState((s) => s.homePanel && s.modal);
  await page.waitForTimeout(350);
}
async function closePanel() {
  await page.keyboard.press("Escape");
  await waitState((s) => !s.modal && !s.homePanel);
  await page.waitForTimeout(250);
}
async function pressResponse(path, predicate, key) {
  const pending = page.waitForResponse(
    (r) =>
      r.url().endsWith(path) &&
      r.request().method() === "POST" &&
      predicate(r.request().postDataJSON()),
  );
  await page.keyboard.press(key);
  const response = await pending;
  const data = await response.json();
  assert(response.ok(), `${path} ${response.status()} ${JSON.stringify(data)}`);
  return data;
}
async function action(name, extra = {}, tabs = 0) {
  for (let i = 0; i < tabs; i++) await page.keyboard.press("Tab");
  const pending = page.waitForResponse(
    (r) =>
      r.url().endsWith("/api/homestead/action") &&
      r.request().postDataJSON()?.action === name,
  );
  await page.keyboard.press("Enter");
  const r = await pending,
    data = await r.json();
  assert(r.ok(), `${name} ${r.status()} ${JSON.stringify(data)}`);
  for (const [key, value] of Object.entries(extra))
    assert.equal(r.request().postDataJSON()[key], value);
  operations.push({
    action: name,
    itemId: extra.itemId,
    revision: data.homestead.revision,
    version: data.player.version,
    coins: data.player.coins,
    calendarDay: data.calendar?.calendarDay,
    plot: data.homestead.plots.find((plot) => plot.id === setup.plot.id),
    seeds: data.homestead.seeds,
    produce: data.homestead.produce,
    pantry: data.homestead.pantry,
    pen: data.homestead.fishPen,
  });
  await waitState((s) => s.homestead?.revision === data.homestead.revision);
  await page.waitForTimeout(400);
  return data;
}
async function shot(name) {
  phase = name;
  await page.screenshot({ path: `${artifacts}/${name}.png` });
  console.log(JSON.stringify({ phase: name }));
}
async function captureFailure() {
  if (frame && !frame.isDetached()) {
    let timer;
    try {
      failureSnapshot = await Promise.race([
        frame
          .evaluate(() => {
            const s = window.jalasmaraSnapshot;
            if (!s) return { unavailable: "snapshot missing" };
            return {
              x: s.x,
              y: s.y,
              area: s.area,
              stage: s.stage,
              diving: s.diving,
              modal: s.modal,
              homePanel: s.homePanel,
              nearby: s.nearby,
              outfit: s.outfit,
              clock: s.weather?.clock,
              land: {
                active: s.land?.active,
                area: s.land?.area,
                azimuth: s.land?.view?.azimuth,
              },
              homestead: s.homestead
                ? {
                    inside: s.homestead.inside,
                    revision: s.homestead.revision,
                    liveCatch: s.homestead.liveCatch,
                    fishPen: s.homestead.fishPen,
                    produce: s.homestead.produce,
                    seeds: s.homestead.seeds,
                    pantry: s.homestead.pantry,
                    plots: s.homestead.plots,
                  }
                : null,
            };
          })
          .catch(() => ({ unavailable: "frame evaluation failed" })),
        new Promise((resolve) => {
          timer = setTimeout(
            () => resolve({ unavailable: "snapshot timeout3seconds" }),
            3000,
          );
        }),
      ]);
    } finally {
      clearTimeout(timer);
    }
    writeFileSync(
      `${artifacts}/failure-snapshot.json`,
      JSON.stringify({ phase, state: failureSnapshot }, null, 2),
    );
  }
  if (page && !page.isClosed()) {
    failureScreenshot = await page
      .screenshot({ path: `${artifacts}/failure.png`, timeout: 5000 })
      .then(() => true)
      .catch(() => false);
  }
}

function plotOf(state) {
  const plot = state.homestead.plots.find((item) => item.id === setup.plot.id);
  assert(plot, "The actual selected plot must exist");
  return plot;
}
function assertCommon(state, { seeds = 0, produce = 0, pantry = 0 } = {}) {
  const home = state.homestead;
  assert.equal(state.player.coins, 250);
  assert.equal(state.player.progress.day, 2);
  assert.equal(state.player.progress.stage, "dive");
  assert.deepEqual(state.player.progress.missions, ["akar"]);
  assert.deepEqual(state.player.inventory, []);
  assert.equal(home.permit, true);
  assert.deepEqual(home.seeds, { benih_kangkung: 0, benih_jahe: seeds });
  assert.deepEqual(home.produce, {
    kangkung: 0,
    jahe: produce,
    ikan_seruni: 0,
  });
  assert.deepEqual(home.pantry, { kangkung: 0, jahe: pantry, ikan_seruni: 0 });
  assert.equal(home.liveCatch.reef_seruni, 0);
  assert.equal(home.fishPen.breeders, 0);
  assert.equal(home.fishPen.offspring, 0);
  assert.equal(home.fishPen.progressDays, 0);
  assert.deepEqual(home.storageLoot, []);
  for (const plot of home.plots.filter((item) => item.id !== setup.plot.id)) {
    assert.equal(plot.cropId, null);
    assert.equal(plot.growthDays, 0);
  }
}
async function verifyReload(name, produce, pantry) {
  phase = name;
  const before = await apiState(),
    position = await snapshot();
  assertCommon(before, { produce, pantry });
  const fields = (state) => ({
    version: state.player.version,
    coins: state.player.coins,
    seeds: state.homestead.seeds,
    plots: state.homestead.plots,
    produce: state.homestead.produce,
    pantry: state.homestead.pantry,
    pen: state.homestead.fishPen,
    liveCatch: state.homestead.liveCatch,
    story: state.player.progress,
    inventory: state.player.inventory,
    calendarDay: state.calendar.calendarDay,
  });
  const pinned = fields(before);
  await page.reload();
  await attach();
  const resumed = await waitState(
    (s) =>
      !s.modal &&
      !s.homePanel &&
      s.land?.active &&
      s.homestead?.revision === before.homestead.revision,
  );
  assert(Math.hypot(resumed.x - position.x, resumed.y - position.y) < 30);
  const persisted = await apiState();
  assertCommon(persisted, { produce, pantry });
  assert.deepEqual(fields(persisted), pinned);
  assert.equal(persisted.calendar.calendarDay, 6);
  await shot(name);
}

try {
  const release = await fetch(`${origin}/game/index.pck`, {
    redirect: "error",
    signal: AbortSignal.timeout(180000),
  });
  assert(release.ok);
  const digest = createHash("sha256");
  let bytes = 0;
  for await (const chunk of release.body) {
    bytes += chunk.length;
    assert(bytes <= expectedBytes);
    digest.update(chunk);
  }
  assert.equal(bytes, expectedBytes);
  assert.equal(digest.digest("hex"), expectedPck);
  await mongo.connect();
  const home = freshHomestead(2, true);
  home.seeds = { benih_kangkung: 0, benih_jahe: 1 };
  assert.equal(home.liveCatch.reef_seruni, 0);
  assert.equal(home.fishPen.breeders, 0);
  assert.equal(home.fishPen.offspring, 0);
  const now = new Date().toISOString();
  fixtureAttempted = true;
  await mongo
    .db()
    .collection("players")
    .insertOne({
      id,
      email,
      name: "Nala Uji Jahe Empat Hari",
      role: "player",
      status: "active",
      appearance: "male_nusantara",
      coins: 250,
      inventory: [],
      abilities: freshAbilities(),
      progress: {
        ...freshProgress(),
        day: 2,
        stage: "dive",
        tutorial: true,
        missions: ["akar"],
      },
      adventure: { discoveries: [], puzzles: [], keyItems: [] },
      calendar: {
        ...freshCalendar(),
        calendarDay: 2,
        lastSettledDay: 2,
        minuteOfDay: 480,
      },
      homestead: home,
      version: 0,
      authVersion: 0,
      passwordHash: await argon2.hash(password, { type: argon2.argon2id }),
      createdAt: now,
      updatedAt: now,
    });
  created = true;
  const cache = new Redis(redisUrl);
  try {
    await cache.set(
      `surface:${id}`,
      JSON.stringify({
        area: "hub",
        ...setup.plot.interaction,
        layoutVersion: WORLD.hub.layoutVersion,
        playerVersion: 0,
        positionAt: Date.now(),
      }),
      "EX",
      1800,
    );
  } finally {
    await cache.quit();
  }
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
  page.on("request", (request) => requestTimes.set(request, performance.now()));
  page.on("pageerror", (e) => errors.push(e.message));
  page.on("console", (m) => {
    if (m.type() === "error") errors.push(m.text());
  });
  page.on("response", async (r) => {
    if (!r.url().includes("/api/")) return;
    const responseMonotonicMs = performance.now();
    const path = new URL(r.url()).pathname,
      body = await r.json().catch(() => ({}));
    let sent = {};
    try {
      sent = r.request().postDataJSON() ?? {};
    } catch {}
    const expected = false;
    trace.push({
      phase,
      requestMonotonicMs: requestTimes.get(r.request()),
      responseMonotonicMs,
      path,
      status: r.status(),
      action: sent.action,
      itemId: sent.itemId,
      expectedRevision: sent.expectedRevision,
      receipt: r.request().headers()["idempotency-key"],
      version: body.player?.version,
      revision: body.homestead?.revision,
      plotId: sent.plotId,
      confirmEarly: sent.confirmEarly,
      seeds: body.homestead?.seeds,
      plot: body.homestead?.plots?.find((plot) => plot.id === setup.plot.id),
      produce: body.homestead?.produce,
      pantry: body.homestead?.pantry,
      calendarDay: body.calendar?.calendarDay,
      pen: body.homestead?.fishPen,
      expected,
    });
    if (r.status() >= 400 && !expected)
      failures.push({
        path,
        status: r.status(),
        code: body.code,
        action: sent.action,
      });
  });
  await page.addInitScript(() => {
    window.jalasmaraDiagnostics = true;
  });
  await page.goto(`${origin}/login`);
  await page.getByLabel("Email", { exact: true }).fill(email);
  await page.getByLabel("Password", { exact: true }).fill(password);
  await page.getByRole("button", { name: "Masuk ke Jalasmara" }).click();
  await page.waitForURL("**/play");
  await attach();
  world = await fetchWorld(context.request, origin);
  await waitState((s) => !s.modal && !s.homePanel && s.land?.active);
  assert.equal((await snapshot()).land.view.azimuth, -45);
  heartbeat = setInterval(
    () =>
      console.log(
        JSON.stringify({
          phase,
          elapsedMs: Date.now() - routeStarted,
          checks: checks.length,
        }),
      ),
    30000,
  );

  const initial = await apiState();
  assert.deepEqual(
    deriveJaheCycleFixture(world, initial.homesteadDefinitions),
    setup,
  );
  assert.equal(initial.homestead.seeds.benih_jahe, 1);
  assert.equal(
    initial.homestead.plots.find((plot) => plot.id === setup.plot.id).cropId,
    null,
  );
  assertCommon(initial, { seeds: 1 });
  checks.push(
    "declared-one-seed-permit-fixture-starts-with-zero-produce-pantry-and-parents",
  );
  await openAt(setup.plot.interaction, setup.plot.id);
  phase = "actual-jahe-plant";
  const planted = await action("plant", {
    plotId: setup.plot.id,
    itemId: setup.crop.seedId,
  });
  assertCommon(planted);
  assert.equal(plotOf(planted).cropId, "jahe");
  assert.equal(plotOf(planted).growthDays, 0);
  assert.equal(plotOf(planted).watered, false);
  checks.push(
    "actual-jahe-plant-consumes-one-declared-seed-with-no-growth-or-produce",
  );
  await shot("01-jahe-planted-from-one-seed");

  for (let cycle = 1; cycle <= setup.crop.growthDays; cycle++) {
    phase = `actual-jahe-care-and-sleep-${cycle}`;
    const beforeCare = await apiState();
    assertCommon(beforeCare);
    assert.equal(beforeCare.calendar.calendarDay, 1 + cycle);
    assert.equal(calendarRain(id, beforeCare.calendar.calendarDay), false);
    assert.equal(plotOf(beforeCare).cropId, "jahe");
    assert.equal(plotOf(beforeCare).growthDays, cycle - 1);
    assert.equal(plotOf(beforeCare).ready, false);
    assert.equal(plotOf(beforeCare).watered, false);
    const watered = await action("water", { plotId: setup.plot.id });
    assertCommon(watered);
    assert.equal(plotOf(watered).watered, true);
    assert.equal(plotOf(watered).wateredDay, beforeCare.calendar.calendarDay);
    assert.equal(plotOf(watered).growthDays, cycle - 1);
    await closePanel();
    await openAt(world.homestead.door, "home_enter");
    const entered = await action("enter");
    assertCommon(entered);
    await waitState(
      (s) => s.area === "home" && s.homestead?.inside && s.renderer?.active,
    );
    await routeTo(setup.bedApproach, true);
    await waitState((s) => s.nearby === "bed");
    await page.keyboard.press("e");
    await waitState((s) => s.homePanel && s.modal);
    const slept = await action("sleep", { confirmEarly: true });
    assertCommon(slept);
    assert.equal(
      slept.calendar.calendarDay,
      beforeCare.calendar.calendarDay + 1,
    );
    assert.equal(slept.calendar.minuteOfDay, 360);
    assert.equal(plotOf(slept).growthDays, cycle);
    assert.equal(plotOf(slept).ready, cycle === setup.crop.growthDays);
    checks.push(
      `actual-water-and-real-bed-sleep-${cycle}-settles-exactly-one-jahe-growth-day`,
    );
    await shot(`0${cycle + 1}-jahe-real-growth-day-${cycle}`);
    await page.keyboard.press("Enter");
    await waitState((s) => !s.modal && !s.homePanel);
    await routeTo(world.homestead.interior.entry, true);
    await waitState((s) => s.nearby === "exit");
    const exited = await pressResponse(
      "/api/homestead/action",
      (body) => body.action === "exit",
      "e",
    );
    assertCommon(exited);
    assert.equal(exited.homestead.inside, false);
    assert.equal(exited.surface.playerVersion, exited.player.version);
    operations.push({
      action: "exit",
      version: exited.player.version,
      revision: exited.homestead.revision,
      calendarDay: exited.calendar.calendarDay,
    });
    await waitState(
      (s) =>
        s.area !== "home" &&
        !s.homestead?.inside &&
        s.land?.active &&
        s.land?.view?.motion,
    );
    await openAt(setup.plot.interaction, setup.plot.id);
  }

  phase = "actual-jahe-harvest-after-four-sleeps";
  const ripe = await apiState();
  assertCommon(ripe);
  assert.equal(ripe.calendar.calendarDay, 6);
  assert.equal(plotOf(ripe).growthDays, 4);
  assert.equal(plotOf(ripe).ready, true);
  const harvested = await action("harvest", { plotId: setup.plot.id });
  assertCommon(harvested, { produce: setup.crop.yield });
  assert.equal(plotOf(harvested).cropId, null);
  assert.equal(plotOf(harvested).growthDays, 0);
  checks.push(
    "actual-four-day-jahe-harvest-yields-exactly-three-and-clears-only-its-plot",
  );
  await shot("06-jahe-actual-harvest-three");
  await closePanel();
  await verifyReload("07-jahe-harvest-persists-after-real-reload", 3, 0);
  checks.push(
    "actual-harvest-reload-retains-three-jahe-seed-coin-story-and-empty-parent-ledger",
  );

  phase = "physical-wira-pantry-stock-not-sale";
  await routeTo(setup.wira);
  await waitState((s) =>
    [setup.wira.id, "wira", "Mbah Wira"].includes(s.nearby),
  );
  await page.keyboard.press("e");
  await waitState((s) => s.homePanel && s.modal);
  await page.waitForTimeout(350);
  await page.keyboard.press("Enter");
  await page.waitForTimeout(400);
  await shot("08-wira-actual-harvested-jahe-stock-option");
  const stocked = await action("stock_kedai", { itemId: "jahe", qty: 1 });
  assertCommon(stocked, { produce: 2, pantry: 1 });
  checks.push(
    "ordinary-wira-pantry-stock-moves-one-actual-jahe-leaving-two-without-coin-sale",
  );
  await closePanel();
  await verifyReload("09-jahe-pantry-two-produce-persists", 2, 1);
  checks.push(
    "real-reload-persists-one-jahe-in-pantry-two-carried-and-no-invented-revenue",
  );
  for (const [name, count] of Object.entries({
    plant: 1,
    water: 4,
    sleep: 4,
    enter: 4,
    exit: 4,
    harvest: 1,
    stock_kedai: 1,
  }))
    assert.equal(
      operations.filter((operation) => operation.action === name).length,
      count,
    );
  assert.equal(errors.length, 0, JSON.stringify(errors));
  assert.equal(failures.length, 0, JSON.stringify(failures));
  completed = true;
} catch (error) {
  console.error(error);
  errors.push(String(error));
  process.exitCode = 1;
  await captureFailure();
} finally {
  clearInterval(heartbeat);
  const cookies = context ? await context.cookies().catch(() => []) : [];
  try {
    await browser?.close();
    browserClosed = true;
  } catch (error) {
    completed = false;
    process.exitCode = 1;
    errors.push("Browser shutdown failed: " + String(error));
  }
  const cache = fixtureAttempted ? new Redis(redisUrl) : null;
  try {
    if (fixtureAttempted) {
      await mongo.db().collection("players").deleteOne({
        id,
        email,
        role: "player",
        name: "Nala Uji Jahe Empat Hari",
      });
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
      for (const cookie of cookies.filter((c) =>
        ["jalasmara", "__Host-jalasmara"].includes(c.name),
      )) {
        const key = `auth:${createHash("sha256").update(cookie.value).digest("hex")}`,
          raw = await cache.get(key);
        if (raw) {
          assert.equal(JSON.parse(raw).userId, id);
          keys.push(key);
        }
      }
      keys.push(...(await findFixtureAuthKeys(cache, id)));
      await cache.del(...new Set(keys));
      assert.equal(
        await mongo.db().collection("players").countDocuments({ id, email }),
        0,
      );
      assert.equal(
        await mongo
          .db()
          .collection("receipts")
          .countDocuments({ _id: { $regex: `^${id}:` } }),
        0,
      );
      assert.equal(
        await mongo.db().collection("shifts").countDocuments({ userId: id }),
        0,
      );
      assert((await cache.mget(...keys)).every((v) => v === null));
      ownAuthKeysRemaining = (await findFixtureAuthKeys(cache, id)).length;
      assert.equal(ownAuthKeysRemaining, 0);
      cleaned = true;
    }
  } finally {
    await mongo.close();
    await cache?.quit();
    writeFileSync(
      `${artifacts}/results.json`,
      JSON.stringify(
        {
          id,
          origin,
          phase,
          outcome: completed && cleaned ? "passed" : "failed",
          completed,
          fixtureAttempted,
          fixtureInsertAcknowledged: created,
          browserClosed,
          ownAuthKeysRemaining,
          failureScreenshot,
          failureSnapshot,
          ownTemporaryPlayerRemoved: cleaned,
          candidatePck: { sha256: expectedPck, bytes: expectedBytes },
          fixture: {
            storyDay: 2,
            calendarDay: 2,
            minuteOfDay: 480,
            permit: true,
            coins: 250,
            seeds: { benih_kangkung: 0, benih_jahe: 1 },
            dryCareDays: careDays.map((day) => ({
              day,
              raining: calendarRain(id, day),
            })),
            initialSurface: setup.plot.interaction,
            initialProduce: 0,
            initialPantry: 0,
            initialLiveCatch: 0,
            initialParents: 0,
            initialOffspring: 0,
            viewport: { width: 844, height: 390 },
            activeRouteBudgetMinutes: 15,
            startupTimeoutMsPerAttach: 240000,
            limits:
              "Declared seed/permit/story/coins/location; no acquisition claim, calendar writes, growth/harvest injection, sale/revenue or serving-bonus claim",
          },
          setup,
          routeElapsedMs: routeStarted ? Date.now() - routeStarted : null,
          checks,
          operations,
          errors,
          failures,
          trace,
          ledger,
        },
        null,
        2,
      ),
    );
    console.log(
      JSON.stringify({ completed, cleaned, checks: checks.length, artifacts }),
    );
  }
}
