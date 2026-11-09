// APP_TEST_ORIGIN=http://localhost:3111 PLAN06_EXPECT_PCK=<sha256> PLAN06_EXPECT_PCK_BYTES=<bytes> node --import tsx scripts/garden-pen-browser.mjs
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
import { WORLD } from "../packages/shared/src/world.ts";
import { fetchWorld } from "./game-navigation.mjs";
import { physicalRoute } from "./plan06-physical-route.mjs";
import { corridorTargets, keyboardPulse } from "./land-view-navigation.mjs";

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
const id = randomUUID(),
  email = `garden-pen-${id}@test.invalid`,
  password = randomBytes(24).toString("base64url");
const artifacts = `artifacts/browser/garden-pen-${id}`;
mkdirSync(artifacts, { recursive: true });
const mongo = new MongoClient(mongoUrl),
  checks = [],
  operations = [],
  errors = [],
  failures = [],
  trace = [];
let browser,
  context,
  page,
  frame,
  world,
  created = false,
  cleaned = false,
  completed = false,
  phase = "setup",
  routeStarted,
  committedFeed,
  feedKey,
  injected = false,
  expectedLost = false;
const snapshot = () => frame.evaluate(() => window.jalasmaraSnapshot);
function budget() {
  assert(
    !routeStarted || Date.now() - routeStarted < 8 * 60 * 1000,
    "Bounded eight-minute route exceeded",
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
  return r.json();
}
async function walkDirect(x, y) {
  let previous,
    stuck = 0;
  for (let i = 0; i < 450; i++) {
    budget();
    const s = await snapshot(),
      dx = x - s.x,
      dy = y - s.y;
    if (Math.hypot(dx, dy) < 5) return;
    assert(!s.modal && !s.homePanel && !s.diving && s.land?.view?.motion);
    stuck =
      previous && Math.hypot(s.x - previous.x, s.y - previous.y) < 0.5
        ? stuck + 1
        : 0;
    assert(stuck < 20, `Blocked ${phase} route ${x},${y} at ${s.x},${s.y}`);
    previous = s;
    const control = keyboardPulse([dx, dy], s.land.view.motion, {
      speed: 100 * (s.traversal?.paceScale ?? 1),
      acceleration: 850,
    });
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
async function routeTo(point) {
  await frame.locator("canvas").focus();
  for (const [x, y] of physicalRoute(world, await snapshot(), point, "hub")) {
    const from = await snapshot();
    for (const [tx, ty] of corridorTargets([from.x, from.y], [x, y]))
      await walkDirect(tx, ty);
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

try {
  const release = await fetch(`${origin}/game/index.pck`, {
    redirect: "error",
    signal: AbortSignal.timeout(180000),
  });
  assert(release.ok());
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
  home.produce.jahe = 1;
  home.fishPen = {
    breeders: 2,
    progressDays: 0,
    fedDay: 0,
    lastSettledDay: 2,
    offspring: 1,
  };
  const now = new Date().toISOString();
  await mongo
    .db()
    .collection("players")
    .insertOne({
      id,
      email,
      name: "Nala Uji Kebun Keramba",
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
        ...WORLD.homestead.fishPen.interaction,
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
    viewport: { width: 1440, height: 900 },
  });
  page = await context.newPage();
  page.setDefaultTimeout(60000);
  page.on("pageerror", (e) => errors.push(e.message));
  page.on("console", (m) => {
    if (m.type() === "error" && !(expectedLost && m.text().includes("503")))
      errors.push(m.text());
  });
  page.on("response", async (r) => {
    if (!r.url().includes("/api/")) return;
    const path = new URL(r.url()).pathname,
      body = await r.json().catch(() => ({}));
    let sent = {};
    try {
      sent = r.request().postDataJSON() ?? {};
    } catch {}
    const expected =
      r.status() === 503 &&
      path === "/api/homestead/action" &&
      sent.action === "feed_pen" &&
      body.code === "TEST_RESPONSE_LOST";
    trace.push({
      phase,
      path,
      status: r.status(),
      action: sent.action,
      itemId: sent.itemId,
      expectedRevision: sent.expectedRevision,
      receipt: r.request().headers()["idempotency-key"],
      version: body.player?.version,
      revision: body.homestead?.revision,
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
  phase = "pen-feed-retry";
  await openAt(world.homestead.fishPen.interaction, "fish_pen");
  await shot("01-pen-ready-own-fixture");
  const before = await apiState();
  assert.equal(before.homestead.fishPen.breeders, 2);
  assert.equal(before.homestead.fishPen.offspring, 1);
  const pattern = "**/api/homestead/action";
  expectedLost = true;
  const handler = async (route) => {
    if (route.request().postDataJSON()?.action === "feed_pen" && !injected) {
      const actual = await route.fetch();
      assert(actual.ok());
      committedFeed = await actual.json();
      feedKey = route.request().headers()["idempotency-key"];
      injected = true;
      await route.fulfill({
        status: 503,
        contentType: "application/json",
        body: JSON.stringify({
          error: "Simulated lost response after committed feed",
          code: "TEST_RESPONSE_LOST",
        }),
      });
    } else await route.continue();
  };
  await page.route(pattern, handler);
  const lost = page.waitForResponse(
    (r) =>
      r.url().endsWith("/api/homestead/action") &&
      r.request().postDataJSON()?.action === "feed_pen",
  );
  await page.keyboard.press("Enter");
  assert.equal((await lost).status(), 503);
  await page.waitForTimeout(1200);
  const pendingRetry = page.waitForResponse(
    (r) =>
      r.url().endsWith("/api/homestead/action") &&
      r.request().postDataJSON()?.action === "feed_pen",
  );
  await page.keyboard.press("Enter");
  const retry = await pendingRetry;
  assert(retry.ok());
  assert.equal(retry.request().headers()["idempotency-key"], feedKey);
  const fed = await retry.json();
  assert.deepEqual(fed, committedFeed);
  assert.equal(fed.player.coins, before.player.coins - 2);
  assert.equal(fed.homestead.fishPen.offspring, 1);
  await waitState((s) => s.homestead?.revision === fed.homestead.revision);
  await page.unroute(pattern, handler);
  expectedLost = false;
  checks.push("real-feed-ui-retry-same-receipt-no-double-charge-or-offspring");
  await shot("02-feed-confirmed-after-retry");
  // Tab selects the next enabled action when the fed button is disabled.
  const harvested = await action("harvest_pen", { qty: 1 }, 1);
  assert.equal(harvested.homestead.fishPen.offspring, 0);
  assert.equal(harvested.homestead.produce.ikan_seruni, 1);
  assert.equal(harvested.homestead.fishPen.breeders, 2);
  checks.push("actual-nearest-pen-harvest-retains-two-parents");
  await closePanel();
  phase = "jahe-plot-option";
  await openAt(world.homestead.gardenPlots[0].interaction, "plot_1");
  await shot("03-jahe-seed-option");
  const planted = await action("plant", {
    plotId: "plot_1",
    itemId: "benih_jahe",
  });
  assert.equal(planted.homestead.plots[0].cropId, "jahe");
  assert.equal(planted.homestead.seeds.benih_jahe, 0);
  const watered = await action("water", { plotId: "plot_1" });
  assert.equal(watered.homestead.plots[0].watered, true);
  checks.push("jahe-choice-uses-authoritative-seed-and-actual-water-action");
  await closePanel();
  phase = "pantry-stock";
  const wira = world.surface_hub.districts.find((d) => d.npc === "Mbah Wira");
  assert(wira);
  await routeTo(wira);
  await waitState(
    (s) =>
      s.nearby === wira.id || s.nearby === "wira" || s.nearby === "Mbah Wira",
  );
  await page.keyboard.press("e");
  await waitState((s) => s.homePanel);
  await page.waitForTimeout(350);
  await page.keyboard.press("Enter");
  await page.waitForTimeout(350);
  await shot("04-pantry-selected-produce");
  const stockedJahe = await action("stock_kedai", { itemId: "jahe", qty: 1 });
  assert.equal(stockedJahe.homestead.pantry.jahe, 1);
  assert.equal(stockedJahe.homestead.produce.jahe, 0);
  const stockedFish = await action("stock_kedai", {
    itemId: "ikan_seruni",
    qty: 1,
  });
  assert.equal(stockedFish.homestead.pantry.ikan_seruni, 1);
  assert.equal(stockedFish.homestead.produce.ikan_seruni, 0);
  checks.push("actual-ui-stocks-two-canonical-pantry-ingredients");
  await closePanel();
  const canonical = await apiState();
  assert(canonical.player.version > before.player.version);
  const pinned = {
    revision: canonical.homestead.revision,
    version: canonical.player.version,
    coins: canonical.player.coins,
    pantry: canonical.homestead.pantry,
    pen: canonical.homestead.fishPen,
    plots: canonical.homestead.plots,
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
  assert.deepEqual(persisted.homestead.pantry, pinned.pantry);
  assert.deepEqual(persisted.homestead.fishPen, pinned.pen);
  assert.deepEqual(persisted.homestead.plots, pinned.plots);
  checks.push("reload-retains-canonical-pantry-plot-pen-version-and-coins");
  await shot("05-persisted-reload");
  assert.equal(errors.length, 0, JSON.stringify(errors));
  assert.equal(failures.length, 0, JSON.stringify(failures));
  completed = true;
} catch (error) {
  console.error(error);
  errors.push(String(error));
  process.exitCode = 1;
} finally {
  const cookies = context ? await context.cookies().catch(() => []) : [];
  await browser?.close();
  const cache = created ? new Redis(redisUrl) : null;
  try {
    if (created) {
      await mongo
        .db()
        .collection("players")
        .deleteOne({
          id,
          email,
          role: "player",
          name: "Nala Uji Kebun Keramba",
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
      await cache.del(...keys);
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
      assert((await cache.mget(...keys)).every((v) => v === null));
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
          ownTemporaryPlayerRemoved: cleaned,
          candidatePck: { sha256: expectedPck, bytes: expectedBytes },
          fixture: {
            storyDay: 2,
            calendarDay: 2,
            permit: true,
            seeds: { benih_jahe: 1 },
            produce: { jahe: 1 },
            pen: { breeders: 2, offspring: 1 },
            limits:
              "Explicit fixture stock/day; no browser acquisition, full breeding/growth, or serving bonus claim",
          },
          checks,
          operations,
          errors,
          failures,
          trace,
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
