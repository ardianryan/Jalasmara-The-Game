// Run: APP_TEST_ORIGIN=http://localhost:3100 node --import tsx scripts/homestead-browser.mjs
import { chromium } from "@playwright/test";
import { MongoClient } from "mongodb";
import argon2 from "argon2";
import Redis from "ioredis";
import { randomUUID, randomBytes, createHash } from "node:crypto";
import { mkdirSync, writeFileSync, readFileSync } from "node:fs";
import assert from "node:assert/strict";
import {
  freshAbilities,
  freshProgress,
  freshCalendar,
  freshHomestead,
} from "../packages/shared/src/index.ts";
import { fetchWorld, hubRoute } from "./game-navigation.mjs";

const origin = process.env.APP_TEST_ORIGIN ?? "http://localhost:3100";
const createdLocally = !process.env.BROWSER_FIXTURE;
const mongoUrl =
  process.env.MONGO_URL ?? "mongodb://127.0.0.1:27018/jalasmara?replicaSet=rs0";
const redisUrl = process.env.REDIS_URL ?? "redis://127.0.0.1:6380";
if (createdLocally) {
  assert(
    ["localhost", "127.0.0.1"].includes(new URL(origin).hostname),
    "Remote tests require an explicit dedicated BROWSER_FIXTURE.",
  );
  assert(
    /^mongodb:\/\/(127\.0\.0\.1|localhost)(:|\/)/.test(mongoUrl),
    "Local MongoDB required.",
  );
  assert(
    ["localhost", "127.0.0.1"].includes(new URL(redisUrl).hostname),
    "Local Redis required.",
  );
}
const artifacts = "artifacts/godot/homestead";
mkdirSync(artifacts, { recursive: true });
const checks = [],
  errors = [],
  failures = [],
  operations = [];
let expectingLostResponse = false;
let id, password, email;
if (process.env.BROWSER_FIXTURE) {
  const fixture = JSON.parse(readFileSync(process.env.BROWSER_FIXTURE, "utf8"));
  const account = fixture.accounts.find((account) => account.role === "player");
  assert(
    account && fixture.password,
    "Dedicated player fixture required; an owner account is never used.",
  );
  ({ id, email } = account);
  password = fixture.password;
} else {
  const mongo = new MongoClient(mongoUrl);
  await mongo.connect();
  id = randomUUID();
  password = randomBytes(24).toString("base64url");
  email = `homestead-${id}@test.invalid`;
  const now = new Date().toISOString();
  const player = {
    id,
    email,
    name: "Nala Uji Rumah",
    role: "player",
    status: "active",
    appearance: "male_default",
    coins: 100,
    inventory: [{ fragmentId: "klorofil", stars: 3, quantity: 2 }],
    abilities: freshAbilities(),
    progress: {
      ...freshProgress(),
      day: 2,
      tutorial: true,
      missions: ["malam_1", "akar"],
    },
    adventure: { discoveries: [], puzzles: [], keyItems: [] },
    calendar: freshCalendar(),
    homestead: freshHomestead(),
    version: 0,
    authVersion: 0,
    passwordHash: await argon2.hash(password, { type: argon2.argon2id }),
    createdAt: now,
    updatedAt: now,
  };
  await mongo.db().collection("players").insertOne(player);
  writeFileSync(
    ".runtime/homestead-browser.json",
    JSON.stringify({ password, accounts: [{ id, email, role: "player" }] }),
    { mode: 0o600 },
  );
  await mongo.close();
}
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
  }),
  page = await context.newPage();
page.setDefaultTimeout(60000);
page.on("pageerror", (e) => errors.push(e.message));
page.on("console", (m) => {
  if (
    m.type() === "error" &&
    !(expectingLostResponse && m.text().includes("503"))
  )
    errors.push(m.text());
});
page.on("response", async (r) => {
  if (r.url().includes("/api/") && r.status() >= 400)
    failures.push({ path: new URL(r.url()).pathname, status: r.status() });
});
let frame, world;
const snapshot = () => frame.evaluate(() => window.jalasmaraSnapshot);
const apiState = async () => {
  const r = await context.request.get(`${origin}/api/homestead/state`);
  assert(r.ok());
  return r.json();
};
async function attach() {
  await page.locator("iframe").waitFor();
  frame = await (await page.locator("iframe").elementHandle()).contentFrame();
  await frame.waitForFunction(
    () => window.jalasmaraReady && window.jalasmaraSnapshot,
    null,
    { polling: 200, timeout: origin.startsWith("https:") ? 240000 : 180000 },
  );
  await frame.locator("canvas").focus();
}
async function waitState(predicate, timeout = 20000) {
  const start = Date.now();
  while (Date.now() - start < timeout) {
    const s = await snapshot();
    if (predicate(s)) return s;
    await page.waitForTimeout(220);
  }
  throw Error("State timeout: " + JSON.stringify(await snapshot()));
}
async function walkTo(x, y, tolerance = 28) {
  let last,
    stuck = 0;
  for (let i = 0; i < 180; i++) {
    const s = await snapshot(),
      dx = x - s.x,
      dy = y - s.y,
      distance = Math.hypot(dx, dy);
    assert(!s.homePanel && !s.modal, "Close modal before walking.");
    writeFileSync(
      ".runtime/homestead-browser-progress.json",
      JSON.stringify({
        target: [x, y],
        position: [s.x, s.y],
        iteration: i,
        nearby: s.nearby,
        area: s.area,
        checks,
      }),
    );
    if (distance < tolerance) return s;
    stuck =
      last && Math.hypot(s.x - last.x, s.y - last.y) < 0.5 ? stuck + 1 : 0;
    last = s;
    assert(
      stuck < 15,
      "Blocked keyboard route: " + JSON.stringify({ x, y, at: [s.x, s.y] }),
    );
    const keys = [];
    if (stuck >= 2 && Math.abs(dx) > 3 && Math.abs(dy) > 3) {
      // Align the narrow corridor before advancing; diagonal input can reject both axes.
      keys.push(
        Math.abs(dx) < Math.abs(dy) ? (dx > 0 ? "d" : "a") : dy > 0 ? "s" : "w",
      );
    } else {
      if (Math.abs(dx) > 13) keys.push(dx > 0 ? "d" : "a");
      if (Math.abs(dy) > 13) keys.push(dy > 0 ? "s" : "w");
    }
    for (const key of keys) await page.keyboard.down(key);
    await page.waitForTimeout(distance < 90 ? 110 : 160);
    for (const key of keys) await page.keyboard.up(key);
    await page.waitForTimeout(230);
  }
  throw Error(
    "Keyboard route failed: " +
      JSON.stringify({ target: [x, y], state: await snapshot() }),
  );
}
async function routeTo(point, inside = false) {
  const map = inside
    ? { hub: { paths: world.homestead.interior.routes } }
    : world;
  for (const [x, y] of hubRoute(map, await snapshot(), point))
    await walkTo(x, y);
  await page.waitForTimeout(400);
}
async function openAt(point, nearby, inside = false) {
  await routeTo(point, inside);
  await waitState((s) => s.nearby === nearby);
  await page.keyboard.press("e");
  await waitState((s) => s.homePanel === true);
  await page.waitForTimeout(350);
}
async function closePanel() {
  await page.keyboard.press("Escape");
  await waitState((s) => !s.homePanel && !s.modal);
  await page.waitForTimeout(200);
}
async function action(action, tabs = 0) {
  for (let i = 0; i < tabs; i++) await page.keyboard.press("Tab");
  const response = page.waitForResponse(
    (r) =>
      r.url().endsWith("/api/homestead/action") &&
      r.request().postDataJSON()?.action === action,
  );
  await page.keyboard.press("Enter");
  const r = await response,
    data = await r.json();
  assert(r.ok(), `${action}: ${r.status()} ${JSON.stringify(data)}`);
  operations.push({
    action,
    revision: data.homestead.revision,
    calendarDay: data.calendar.calendarDay,
    inside: data.homestead.inside,
  });
  await waitState((s) => s.homestead?.revision === data.homestead.revision);
  await page.waitForTimeout(500);
  return data;
}
async function enter() {
  await openAt(world.homestead.door, "home_enter");
  await action("enter");
  const inside = await waitState(
    (s) => s.area === "home" && s.homestead?.inside && s.renderer?.active,
  );
  assert.equal(inside.renderer.renderer, "LandSubViewport3D");
  assert.equal(inside.renderer.elevationDegrees, 35);
  assert(inside.renderer.meshes > 10);
  await frame.locator("canvas").focus();
}
async function exit() {
  await routeTo(world.homestead.interior.entry, true);
  await waitState((s) => s.nearby === "exit");
  const response = page.waitForResponse(
    (r) =>
      r.url().endsWith("/api/homestead/action") &&
      r.request().postDataJSON()?.action === "exit",
  );
  await page.keyboard.press("e");
  assert((await response).ok());
  await waitState(
    (s) => s.area !== "home" && !s.homestead?.inside && s.land?.active,
  );
  await page.waitForTimeout(900);
  await frame.locator("canvas").focus();
}
async function sleep(simulateLostResponse = false) {
  await openAt({ x: 270, y: 330 }, "bed", true);
  let result;
  if (simulateLostResponse) {
    let committed, firstKey;
    expectingLostResponse = true;
    const pattern = "**/api/homestead/action";
    const handler = async (route) => {
      if (route.request().postDataJSON()?.action === "sleep" && !committed) {
        const actual = await route.fetch();
        assert(actual.ok());
        committed = await actual.json();
        firstKey = route.request().headers()["idempotency-key"];
        await route.fulfill({
          status: 503,
          contentType: "application/json",
          body: JSON.stringify({
            error: "Simulated lost response after server commit",
            code: "TEST_RESPONSE_LOST",
          }),
        });
      } else await route.continue();
    };
    await page.route(pattern, handler);
    const failed = page.waitForResponse(
      (r) =>
        r.url().endsWith("/api/homestead/action") &&
        r.request().postDataJSON()?.action === "sleep",
    );
    await page.keyboard.press("Enter");
    assert.equal((await failed).status(), 503);
    await page.waitForTimeout(1500);
    const retried = page.waitForResponse(
      (r) =>
        r.url().endsWith("/api/homestead/action") &&
        r.request().postDataJSON()?.action === "sleep",
    );
    await page.keyboard.press("Enter");
    const response = await retried;
    assert(response.ok());
    assert.equal(response.request().headers()["idempotency-key"], firstKey);
    result = await response.json();
    assert.deepEqual(result, committed);
    await waitState((s) => s.homestead?.revision === result.homestead.revision);
    await page.unroute(pattern, handler);
    expectingLostResponse = false;
    checks.push("lost-sleep-response-retries-same-key-without-extra-day");
  } else result = await action("sleep");
  await page.waitForTimeout(500);
  await page.keyboard.press("Enter");
  await waitState((s) => !s.homePanel);
  return result;
}
async function shot(name) {
  if (name.startsWith("05-growth")) {
    await waitState((state) => state.land?.active && state.land.meshes > 0);
    await page.waitForTimeout(1200);
  }
  const png = await page.screenshot({
    path: `${artifacts}/${name}.png`,
    fullPage: true,
  });
  if (name.startsWith("05-growth")) {
    const colors = await page.evaluate(async (encoded) => {
      const bytes = Uint8Array.from(atob(encoded), (c) => c.charCodeAt(0));
      const bitmap = await createImageBitmap(
        new Blob([bytes], { type: "image/png" }),
      );
      const canvas = new OffscreenCanvas(bitmap.width, bitmap.height),
        ctx = canvas.getContext("2d");
      ctx.drawImage(bitmap, 0, 0);
      const x = Math.floor(bitmap.width * 0.15),
        y = Math.floor(bitmap.height * 0.28),
        w = Math.floor(bitmap.width * 0.7),
        h = Math.floor(bitmap.height * 0.44);
      const data = ctx.getImageData(x, y, w, h).data,
        palette = new Set();
      for (let index = 0; index < data.length; index += 16)
        palette.add(
          `${data[index] >> 4},${data[index + 1] >> 4},${data[index + 2] >> 4}`,
        );
      return palette.size;
    }, png.toString("base64"));
    assert(
      colors > 60,
      `${name} captured an incomplete land frame (${colors} colors)`,
    );
    writeFileSync(
      `${artifacts}/${name}.json`,
      JSON.stringify({ colors, land: (await snapshot()).land }),
    );
  }
}
try {
  await page.goto(origin);
  await page.getByLabel("Email", { exact: true }).fill(email);
  await page.getByLabel("Password", { exact: true }).fill(password);
  await page.getByRole("button", { name: "Masuk ke Jalasmara" }).click();
  await page.waitForURL("**/play", { timeout: 60000 });
  await attach();
  if (origin.startsWith("https:")) {
    const auth = (await context.cookies()).find(
      (cookie) => cookie.name === "__Host-jalasmara",
    );
    assert(auth?.secure && auth.httpOnly && auth.sameSite === "Lax");
    checks.push("https-secure-httponly-lax-cookie");
  }
  await waitState((s) => !s.modal);
  world = await fetchWorld(context.request, origin);
  await openAt(world.homestead.permitBoard, "balai");
  let result = await action("permit");
  assert(result.homestead.permit);
  assert.equal(result.homestead.seeds.benih_kangkung, 2);
  await closePanel();
  checks.push("permit-earned-at-balai");
  await openAt(world.homestead.market, "market");
  result = await action("buy_seed");
  assert.equal(result.player.coins, 80);
  assert.equal(result.homestead.seeds.benih_kangkung, 3);
  await shot("01-market");
  await closePanel();
  checks.push("ratih-seed-price-and-stock");
  await enter();
  await openAt({ x: 700, y: 425 }, "chest", true);
  result = await action("deposit");
  assert.equal(result.homestead.storageLoot[0].quantity, 1);
  await shot("02-chest");
  result = await action("withdraw", 1);
  assert.equal(result.homestead.storageLoot.length, 0);
  assert.equal(result.player.inventory[0].quantity, 2);
  await closePanel();
  checks.push("chest-deposit-withdraw-quality");
  await openAt({ x: 650, y: 280 }, "archive", true);
  await shot("03-archive");
  await closePanel();
  checks.push("archive-real-interior-interaction");
  await page.reload();
  await attach();
  await waitState((s) => s.area === "home" && s.homestead?.inside);
  assert.equal((await apiState()).homestead.inside, true);
  checks.push("refresh-resumes-inside-home");
  await exit();
  for (const plot of world.homestead.gardenPlots) {
    await openAt(plot.interaction, plot.id);
    result = await action("plant");
    assert.equal(
      result.homestead.plots.find((p) => p.id === plot.id).stage,
      "seed",
    );
    await closePanel();
  }
  checks.push("two-plots-consume-two-physical-seeds");
  await shot("04-seeded");
  for (let careDay = 0; careDay < 3; careDay++) {
    for (const plot of world.homestead.gardenPlots) {
      await openAt(plot.interaction, plot.id);
      const before = await apiState();
      if (!before.homestead.plots.find((p) => p.id === plot.id).watered)
        await action("water");
      await closePanel();
    }
    await enter();
    const before = await apiState();
    result = await sleep(careDay === 0);
    assert.equal(result.calendar.calendarDay, before.calendar.calendarDay + 1);
    assert.equal(result.player.progress.day, 2);
    for (const plot of result.homestead.plots)
      assert.equal(plot.growthDays, careDay + 1);
    await exit();
    await routeTo(world.homestead.gardenPlots[1].interaction);
    await shot(`05-growth-day-${careDay + 1}`);
  }
  checks.push("three-care-sleep-days-grow-once-without-story-skip");
  for (const plot of world.homestead.gardenPlots) {
    await openAt(plot.interaction, plot.id);
    result = await action("harvest");
    await closePanel();
  }
  assert.equal(result.homestead.produce.kangkung, 6);
  assert(result.homestead.plots.every((p) => p.stage === "empty"));
  checks.push("two-harvests-yield-six-and-clear-plots");
  const wira = world.surface_hub.districts.find((p) => p.npc === "Mbah Wira");
  await routeTo(wira);
  await page.keyboard.press("e");
  await waitState((s) => s.homePanel);
  await page.keyboard.press("Enter");
  await page.waitForTimeout(350);
  result = await action("stock_kedai");
  assert.equal(result.homestead.pantry.kangkung, 1);
  assert.equal(result.homestead.produce.kangkung, 5);
  await shot("06-kedai-stock");
  await closePanel();
  checks.push("harvest-becomes-real-kedai-pantry");
  assert.deepEqual(errors, []);
  assert.deepEqual(
    failures.filter(
      (failure) =>
        !(failure.path === "/api/homestead/action" && failure.status === 503),
    ),
    [],
    "Unexpected API failures",
  );
  console.log(
    JSON.stringify(
      {
        origin,
        checks,
        operations: operations.length,
        browserErrors: errors.length,
      },
      null,
      2,
    ),
  );
} catch (error) {
  await shot("failure").catch(() => {});
  throw error;
} finally {
  writeFileSync(
    `${artifacts}/results.json`,
    JSON.stringify({ origin, checks, operations, errors, failures }, null, 2),
  );
  const cookies = await context.cookies().catch(() => []);
  await browser.close();
  if (createdLocally) {
    const cleanup = new MongoClient(mongoUrl),
      cache = new Redis(redisUrl);
    try {
      await cleanup.connect();
      await cleanup
        .db()
        .collection("players")
        .deleteOne({ id, email, role: "player" });
      await cleanup
        .db()
        .collection("receipts")
        .deleteMany({ _id: { $regex: `^${id}:` } });
      const auth = cookies.find((cookie) => cookie.name === "jalasmara");
      const keys = [
        `surface:${id}`,
        `home:${id}`,
        `calendar:writer:${id}`,
        `dive:${id}`,
      ];
      if (auth)
        keys.push(
          `auth:${createHash("sha256").update(auth.value).digest("hex")}`,
        );
      await cache.del(...keys);
    } finally {
      await cleanup.close();
      await cache.quit();
    }
  }
}
