// APP_TEST_ORIGIN=http://localhost:3111 PLAN06_EXPECT_PCK=<sha256> PLAN06_EXPECT_PCK_BYTES=<bytes> node --import tsx scripts/live-parent-cycle-browser.mjs
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
import { oceanRoute } from "./live-parent-navigation.mjs";
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
while (calendarRain(id, 2)) id = randomUUID();
const email = `live-parent-${id}@test.invalid`,
  password = randomBytes(24).toString("base64url");
const artifacts = `artifacts/browser/live-parent-${id}`;
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
    !routeStarted || Date.now() - routeStarted < 18 * 60 * 1000,
    "Bounded eighteen-minute route exceeded",
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
async function closeDialogue() {
  for (let attempt = 0; attempt < 3 && (await snapshot()).modal; attempt++) {
    await page.keyboard.press(attempt === 0 ? "Escape" : "Enter");
    await page.waitForTimeout(350);
  }
  await waitState((s) => !s.modal);
}
async function swimTo(destination) {
  await frame.locator("canvas").focus();
  const start = await snapshot();
  const route = oceanRoute(world, start, destination);
  for (const [x, y] of route) {
    let previous,
      stuck = 0,
      arrived = false;
    for (let attempt = 0; attempt < 450; attempt++) {
      budget();
      const s = await snapshot();
      assert(
        s.diving && !s.modal && !s.homePanel,
        "Actual unpaused dive required for swimming",
      );
      const dx = x - s.x,
        dy = y - s.y,
        distance = Math.hypot(dx, dy);
      if (distance < 18) {
        arrived = true;
        break;
      }
      stuck =
        previous && Math.hypot(s.x - previous.x, s.y - previous.y) < 0.5
          ? stuck + 1
          : 0;
      assert(
        stuck < 20,
        `Blocked actual ocean route at ${s.x},${s.y} toward ${x},${y}`,
      );
      previous = s;
      const keys = [];
      if (Math.abs(dx) > 5) keys.push(dx > 0 ? "d" : "a");
      if (Math.abs(dy) > 5) keys.push(dy > 0 ? "s" : "w");
      for (const key of keys) await page.keyboard.down(key);
      try {
        await page.waitForTimeout(distance < 90 ? 110 : 160);
      } finally {
        for (const key of keys) await page.keyboard.up(key);
      }
      await page.waitForTimeout(230);
    }
    assert(arrived, "Ocean movement exceeded bounded input attempts");
    console.log(JSON.stringify({ phase, oceanWaypoint: [x, y] }));
  }
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
      name: "Nala Uji Indukan Hidup",
      role: "player",
      status: "active",
      appearance: "male_nusantara",
      coins: 250,
      inventory: [],
      abilities: Object.fromEntries(
        Object.keys(freshAbilities()).map((key) => [key, 3]),
      ),
      progress: {
        ...freshProgress(),
        day: 2,
        stage: "dive",
        tutorial: true,
        missions: ["malam_1", "akar"],
      },
      adventure: { discoveries: [], puzzles: [], keyItems: [] },
      calendar: { ...freshCalendar(), calendarDay: 2, minuteOfDay: 480 },
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
        ...WORLD.hub.divePoint,
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
      targetId: sent.targetId,
      stars: body.stars,
      oxygen: body.dive?.oxygen,
      liveCatch: body.dive?.liveCatch,
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
  assert.equal(initial.player.inventory.length, 0);
  assert.equal(initial.homesteadDefinitions.fishPen.parentCount, 2);
  assert.equal(initial.homesteadDefinitions.fishPen.growthDays, 2);
  assert.equal(initial.homestead.liveCatch.reef_seruni, 0);
  assert.equal(initial.homestead.fishPen.breeders, 0);
  assert.equal(initial.homestead.fishPen.offspring, 0);
  assert(
    Object.values(initial.homestead.produce).every((value) => value === 0),
  );
  phase = "real-dive-start";
  await waitState((s) => s.nearby === "ladder");
  const started = await pressResponse("/api/dive/start", () => true, "e");
  assert.equal(started.dive.mode, "dive");
  assert.equal(started.dive.liveCatch?.reef_seruni ?? 0, 0);
  await waitState((s) => s.diving && !s.modal);
  const candidates = started.dive.targets
    .filter(
      (target) =>
        !target.caught &&
        ["ekosistem", "netralisasi"].includes(target.fragmentId),
    )
    .sort(
      (a, b) =>
        Math.hypot(a.x - world.spawn.x, a.y - world.spawn.y) -
        Math.hypot(b.x - world.spawn.x, b.y - world.spawn.y),
    );
  assert(candidates.length >= 2);
  for (let index = 0; index < 2; index++) {
    const target = candidates[index];
    phase = `actual-three-star-parent-${index + 1}`;
    await swimTo(target);
    await waitState((s) => s.diving && s.nearby === target.id && !s.modal);
    const netStart = page.waitForResponse((r) =>
      r.url().endsWith("/api/dive/net/start"),
    );
    const collect = page.waitForResponse(
      (r) =>
        r.url().endsWith("/api/dive/collect") &&
        r.request().postDataJSON()?.targetId === target.id,
    );
    void collect.catch(() => {});
    await page.keyboard.down("Space");
    let netAckMonotonicMs;
    try {
      const ack = await netStart;
      assert(ack.ok());
      netAckMonotonicMs = performance.now();
      operations.push({
        action: "net_start_ack",
        targetId: target.id,
        netAckMonotonicMs,
        requestMonotonicMs: requestTimes.get(ack.request()),
      });
      await page.waitForTimeout(800);
    } finally {
      await page.keyboard.up("Space");
    }
    const captureResponse = await collect;
    const captured = await captureResponse.json();
    const collectRequestMonotonicMs = requestTimes.get(
      captureResponse.request(),
    );
    operations.push({
      action: "actual_collect",
      targetId: target.id,
      fragmentId: target.fragmentId,
      status: captureResponse.status(),
      stars: captured.stars,
      oxygen: captured.dive?.oxygen,
      liveCatch: captured.dive?.liveCatch?.reef_seruni,
      netAckMonotonicMs,
      collectRequestMonotonicMs,
      ackToCollectRequestMs: collectRequestMonotonicMs - netAckMonotonicMs,
    });
    assert(
      Number.isFinite(collectRequestMonotonicMs),
      "Capture request must retain its actual monotonic timestamp",
    );
    assert(captureResponse.ok(), JSON.stringify(captured));
    assert.equal(
      captured.stars,
      3,
      "Only an actual server three-star capture qualifies; no fixture replacement",
    );
    assert.equal(captured.dive.liveCatch.reef_seruni, index + 1);
    assert(captured.dive.oxygen > 0);
    assert(
      !captured.dive.challenge,
      "Ordinary biota capture must not require a quiz",
    );
    const beforeExtract = await apiState();
    assert.equal(
      beforeExtract.homestead.liveCatch.reef_seruni,
      0,
      "Live session catch cannot become homestead parents before extraction",
    );
    checks.push(
      `actual-ui-three-star-${target.fragmentId}-${index + 1}-awaits-extract`,
    );
    await shot(`0${index + 1}-actual-live-parent`);
  }
  phase = "successful-live-extraction";
  await swimTo(world.spawn);
  await waitState((s) => s.nearby === "boat");
  const extracted = await pressResponse("/api/dive/extract", () => true, "e");
  assert(!extracted.fainted);
  assert.equal(extracted.surface.area, "hub");
  assert.equal(extracted.surface.playerVersion, extracted.player.version);
  await waitState((s) => !s.diving && s.modal);
  await closeDialogue();
  await waitState((s) => !s.diving && !s.modal && s.land?.active);
  const landed = await apiState();
  assert.equal(landed.homestead.liveCatch.reef_seruni, 2);
  assert.equal(landed.homestead.fishPen.breeders, 0);
  const knowledge = landed.player.inventory;
  assert.equal(
    knowledge
      .filter(
        (entry) =>
          ["ekosistem", "netralisasi"].includes(entry.fragmentId) &&
          entry.stars === 3,
      )
      .reduce((sum, entry) => sum + entry.quantity, 0),
    2,
  );
  checks.push(
    "successful-actual-extract-transfers-two-live-parents-and-separate-knowledge-loot",
  );
  await shot("03-extracted-live-parents");
  phase = "stock-actual-live-parents";
  await openAt(world.homestead.fishPen.interaction, "fish_pen");
  const stocked = await action("stock_pen", { itemId: "reef_seruni", qty: 2 });
  assert.equal(stocked.homestead.liveCatch.reef_seruni, 0);
  assert.equal(stocked.homestead.fishPen.breeders, 2);
  assert.equal(stocked.homestead.fishPen.progressDays, 0);
  assert.equal(stocked.homestead.fishPen.offspring, 0);
  checks.push(
    "actual-live-catch-consumed-once-as-two-independently-stored-parents",
  );
  for (let cycle = 1; cycle <= 2; cycle++) {
    phase = `feed-and-real-sleep-${cycle}`;
    const beforeFeed = await apiState();
    const fed = await action("feed_pen");
    assert.equal(
      fed.player.coins,
      beforeFeed.player.coins - initial.homesteadDefinitions.fishPen.feedCost,
    );
    assert.equal(fed.homestead.fishPen.fed, true);
    assert.equal(fed.homestead.fishPen.offspring, 0);
    const oldDay = fed.calendar.calendarDay;
    await closePanel();
    await openAt(world.homestead.door, "home_enter");
    await action("enter");
    await waitState(
      (s) => s.area === "home" && s.homestead?.inside && s.renderer?.active,
    );
    await routeTo({ x: 270, y: 330 }, true);
    await waitState((s) => s.nearby === "bed");
    await page.keyboard.press("e");
    await waitState((s) => s.homePanel);
    const slept = await action("sleep");
    assert.equal(slept.calendar.calendarDay, oldDay + 1);
    assert.equal(slept.calendar.minuteOfDay, 360);
    assert.equal(slept.player.progress.day, 2);
    assert.equal(slept.player.progress.stage, stocked.player.progress.stage);
    assert.equal(slept.homestead.fishPen.breeders, 2);
    assert.equal(slept.homestead.fishPen.progressDays, cycle === 1 ? 1 : 0);
    assert.equal(slept.homestead.fishPen.offspring, cycle === 1 ? 0 : 1);
    checks.push(`actual-fed-settlement-${cycle}-one-calendar-advance`);
    await shot(`0${cycle + 3}-actual-fed-settlement`);
    await page.keyboard.press("Enter");
    await waitState((s) => !s.modal && !s.homePanel);
    const settled = await apiState();
    assert.equal(settled.calendar.calendarDay, slept.calendar.calendarDay);
    assert.equal(
      settled.homestead.fishPen.offspring,
      slept.homestead.fishPen.offspring,
    );
    await routeTo(world.homestead.interior.entry, true);
    await waitState((s) => s.nearby === "exit");
    const exited = await pressResponse(
      "/api/homestead/action",
      (body) => body.action === "exit",
      "e",
    );
    assert.equal(exited.homestead.inside, false);
    assert.equal(exited.surface.playerVersion, exited.player.version);
    await waitState(
      (s) => s.area !== "home" && !s.homestead?.inside && s.land?.active,
    );
    await openAt(world.homestead.fishPen.interaction, "fish_pen");
  }
  phase = "harvest-genuine-bred-offspring";
  const harvested = await action("harvest_pen", { qty: 1 }, 1);
  assert.equal(harvested.homestead.fishPen.offspring, 0);
  assert.equal(harvested.homestead.produce.ikan_seruni, 1);
  assert.equal(harvested.homestead.fishPen.breeders, 2);
  assert.equal(harvested.homestead.liveCatch.reef_seruni, 0);
  assert.deepEqual(
    harvested.player.inventory,
    knowledge,
    "Knowledge loot cannot be consumed as parent fish",
  );
  assert.equal(
    harvested.player.coins,
    stocked.player.coins - 2 * initial.homesteadDefinitions.fishPen.feedCost,
  );
  checks.push(
    "genuine-two-fed-settlements-yield-exactly-one-harvest-with-two-parents-retained",
  );
  await closePanel();
  const canonical = await apiState();
  const pinned = {
    revision: canonical.homestead.revision,
    version: canonical.player.version,
    coins: canonical.player.coins,
    homestead: canonical.homestead,
    inventory: canonical.player.inventory,
    day: canonical.calendar.calendarDay,
  };
  await page.reload();
  await attach();
  await waitState(
    (s) =>
      !s.modal && !s.homePanel && s.homestead?.revision === pinned.revision,
  );
  const persisted = await apiState();
  assert.equal(persisted.player.version, pinned.version);
  assert.equal(persisted.player.coins, pinned.coins);
  assert.deepEqual(persisted.player.inventory, pinned.inventory);
  assert.deepEqual(persisted.homestead, pinned.homestead);
  assert.equal(persisted.calendar.calendarDay, pinned.day);
  checks.push(
    "reload-persists-genuine-live-parent-breeding-coin-and-knowledge-ledger",
  );
  await shot("06-genuine-offspring-persisted");
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
        name: "Nala Uji Indukan Hidup",
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
            raining: calendarRain(id, 2),
            permit: true,
            gearLevels: { oxygen: 3, speed: 3, bag: 3, net: 3 },
            initialSurface: WORLD.hub.divePoint,
            liveCatch: 0,
            parents: 0,
            offspring: 0,
            produce: 0,
            viewport: { width: 844, height: 390 },
            activeRouteBudgetMinutes: 18,
            limits:
              "Declared story/permit/gear/location only; no injected parents, live catch, offspring or rewards. Functional software-renderer proof only; no device FPS claim",
          },
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
