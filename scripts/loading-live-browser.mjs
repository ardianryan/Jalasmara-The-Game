// Actual local game startup, with its own disposable player and a fresh browser cache.
// Run only after building/exporting the game and restarting the local API/static host.
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

const origin = process.env.APP_TEST_ORIGIN ?? "http://localhost:3100";
const mongoUrl =
  process.env.MONGO_URL ?? "mongodb://127.0.0.1:27018/jalasmara?replicaSet=rs0";
const redisUrl = process.env.REDIS_URL ?? "redis://127.0.0.1:6380";
assert(
  !process.env.BROWSER_FIXTURE,
  "This test never uses an existing player.",
);
assert(["localhost", "127.0.0.1"].includes(new URL(origin).hostname));
assert(/^mongodb:\/\/(127\.0\.0\.1|localhost)(:|\/)/.test(mongoUrl));
assert(["localhost", "127.0.0.1"].includes(new URL(redisUrl).hostname));
const directory = "artifacts/browser/website-loading-live";
mkdirSync(directory, { recursive: true });
const id = randomUUID(),
  email = `loading-live-${id}@test.invalid`,
  password = randomBytes(24).toString("base64url");
const mongo = new MongoClient(mongoUrl);
const checks = [],
  errors = [],
  requests = [],
  responses = [],
  failures = [],
  expectedStartupErrors = [],
  expectedStartupFailures = [];
let browser,
  context,
  page,
  frame,
  observations,
  startupFailure,
  startupFailureDelayMs,
  testingAuthFailure = false,
  cleanup = false;
try {
  await mongo.connect();
  assert(
    await mongo.db().collection("contents").findOne({ state: "published" }),
    "Published local content is required.",
  );
  const now = new Date().toISOString();
  await mongo
    .db()
    .collection("players")
    .insertOne({
      id,
      email,
      name: "Nala Uji Pemuatan",
      role: "player",
      status: "active",
      appearance: "male_nusantara",
      coins: 200,
      inventory: [],
      abilities: freshAbilities(),
      progress: { ...freshProgress(), day: 1, stage: "dive", tutorial: true },
      adventure: { discoveries: [], puzzles: [], keyItems: [] },
      calendar: freshCalendar(),
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
    viewport: { width: 1440, height: 900 },
    serviceWorkers: "block",
  });
  page = await context.newPage();
  page.setDefaultTimeout(60000);
  const cdp = await context.newCDPSession(page);
  await cdp.send("Network.enable");
  await cdp.send("Network.setCacheDisabled", { cacheDisabled: true });
  await page.addInitScript(() => {
    window.jalasmaraDiagnostics = true;
    if (window !== window.top) return;
    window.loadingObservations = { events: [], dom: [] };
    addEventListener("message", (event) => {
      if (
        event.origin !== location.origin ||
        event.source !== document.querySelector("iframe")?.contentWindow
      )
        return;
      if (!["jalasmara:loading", "jalasmara:ready"].includes(event.data?.type))
        return;
      window.loadingObservations.events.push({
        at: performance.now(),
        ...event.data,
      });
    });
    const capture = () => {
      const panel = document.querySelector(".harbor-loading");
      const progress = panel?.querySelector("progress");
      const value = {
        at: performance.now(),
        visible: Boolean(panel),
        percent:
          panel?.querySelector(".harbor-loading-percent")?.textContent ?? null,
        stage:
          panel?.querySelector(".harbor-loading-stage p")?.textContent ?? null,
        detail:
          panel?.querySelector(".harbor-loading-detail")?.textContent ?? null,
        value: progress?.getAttribute("value") ?? null,
      };
      const previous = window.loadingObservations.dom.at(-1);
      if (
        !previous ||
        ["visible", "percent", "stage", "detail", "value"].some(
          (key) => value[key] !== previous[key],
        )
      )
        window.loadingObservations.dom.push(value);
    };
    new MutationObserver(capture).observe(document, {
      childList: true,
      subtree: true,
      attributes: true,
      characterData: true,
    });
  });
  page.on("pageerror", (error) => errors.push(error.message));
  page.on("console", (message) => {
    if (message.type() === "error") {
      (testingAuthFailure ? expectedStartupErrors : errors).push(
        message.text(),
      );
    }
  });
  page.on("request", (request) => {
    const path = new URL(request.url()).pathname;
    if (/\/game\/index\.(wasm|pck)$/.test(path))
      requests.push({ path, method: request.method() });
  });
  page.on("response", (response) => {
    const path = new URL(response.url()).pathname;
    if (/\/game\/index\.(wasm|pck)$/.test(path))
      responses.push({ path, status: response.status() });
    if (path.startsWith("/api/") && response.status() >= 400)
      (testingAuthFailure ? expectedStartupFailures : failures).push({
        path,
        status: response.status(),
      });
  });
  await page.goto(`${origin}/login`);
  await page.getByLabel("Email", { exact: true }).fill(email);
  await page.getByLabel("Password", { exact: true }).fill(password);
  await page.getByRole("button", { name: "Masuk ke Jalasmara" }).click();
  await page.waitForURL("**/play");
  await page.locator("iframe").waitFor();
  frame = await (await page.locator("iframe").elementHandle()).contentFrame();
  await page.waitForFunction(
    () =>
      window.loadingObservations.events.some(
        (event) =>
          event.type === "jalasmara:loading" &&
          event.phase === "downloading" &&
          event.downloadedBytes > 0,
      ),
    null,
    { timeout: 120000 },
  );
  await page.screenshot({ path: `${directory}/01-real-download.png` });
  await page.waitForFunction(
    () =>
      window.loadingObservations.events.some(
        (event) => event.phase === "preparing",
      ),
    null,
    { timeout: 240000 },
  );
  await page.screenshot({ path: `${directory}/02-preparing.png` });
  await frame.waitForFunction(
    () => window.jalasmaraReady && window.jalasmaraSnapshot?.hud,
    null,
    { polling: 200, timeout: 240000 },
  );
  await page.locator(".game-loading").waitFor({ state: "detached" });
  await page.screenshot({ path: `${directory}/03-ready.png` });
  observations = await page.evaluate(() => window.loadingObservations);
  const downloads = observations.events.filter(
    (event) =>
      event.type === "jalasmara:loading" &&
      event.phase === "downloading" &&
      event.downloadedBytes > 0,
  );
  assert(
    downloads.length > 0,
    "Actual exported progress must report nonzero downloaded bytes.",
  );
  assert(
    downloads.every(
      (event) =>
        event.version === 1 &&
        Number.isSafeInteger(event.downloadedBytes) &&
        event.downloadedBytes >= 0,
    ),
  );
  const known = downloads.filter((event) => event.totalBytes > 0);
  assert(
    known.length > 0,
    "This unmodified local export must provide a real valid total.",
  );
  assert(known.every((event) => event.downloadedBytes <= event.totalBytes));
  checks.push(
    "actual-export-reports-valid-versioned-download-byte-observations",
  );
  const observedPercentages = new Set(
    observations.events
      .filter((event) => event.phase === "downloading" && event.totalBytes > 0)
      .map((event) =>
        String(Math.floor((event.downloadedBytes / event.totalBytes) * 100)),
      ),
  );
  const domProgress = observations.dom.filter((value) =>
    /^\d+%$/.test(value.percent ?? ""),
  );
  assert(
    domProgress.length > 0,
    "The host must display real download progress, not just receive it.",
  );
  assert(
    domProgress.every(
      (value) =>
        observedPercentages.has(value.percent.slice(0, -1)) &&
        value.value === value.percent.slice(0, -1),
    ),
  );
  checks.push(
    "real-percentage-native-progress-and-megabyte-text-reach-the-visible-host",
  );
  const preparation = observations.events.find(
    (event) => event.phase === "preparing",
  );
  const ready = observations.events.find(
    (event) => event.type === "jalasmara:ready",
  );
  assert(preparation && ready);
  assert(
    preparation.at <= ready.at,
    "Preparation and real ready events must remain distinct and ordered.",
  );
  assert(
    observations.dom.some(
      (value) =>
        value.stage === "Menyiapkan dunia petualangan" && value.visible,
    ),
  );
  assert(
    observations.dom.some((value) => !value.visible && value.at >= ready.at),
  );
  assert.equal(await page.locator("iframe").count(), 1);
  assert.equal(await page.locator(".landscape-hint").count(), 0);
  checks.push(
    "actual-engine-ready-dismisses-preparation-overlay-and-keeps-single-frame",
  );
  for (const extension of ["wasm", "pck"]) {
    const path = `/game/index.${extension}`;
    assert.equal(
      requests.filter((request) => request.path === path).length,
      1,
      `${path} must be requested once, without progress-prefetch duplication`,
    );
    assert.equal(
      responses.filter(
        (response) => response.path === path && response.status === 200,
      ).length,
      1,
    );
  }
  checks.push(
    "fresh-cache-engine-and-game-bundle-each-download-once-successfully",
  );
  assert.deepEqual(errors, []);
  assert.deepEqual(failures, []);
  const successfulRequests = requests.slice();
  let deniedAt = 0;
  testingAuthFailure = true;
  await page.route("**/api/auth/session", (route) => {
    if (route.request().frame().parentFrame()) {
      deniedAt = Date.now();
      return route.fulfill({ status: 401, json: { user: null } });
    }
    return route.continue();
  });
  await page.reload();
  await page
    .getByRole("heading", { name: "Perjalanan belum dapat dimulai" })
    .waitFor({ timeout: 240000 });
  startupFailureDelayMs = Date.now() - deniedAt;
  assert(
    deniedAt > 0 && startupFailureDelayMs < 5000,
    "Actual startup auth failure must reach the host promptly, without the 30-second stall fallback.",
  );
  assert.equal(await page.getByRole("progressbar").count(), 0);
  assert.equal(
    await page
      .getByRole("link", { name: "Halaman utama", exact: true })
      .getAttribute("href"),
    "/",
  );
  startupFailure = await page.evaluate(() => window.loadingObservations);
  assert(
    startupFailure.events.some(
      (event) =>
        event.type === "jalasmara:loading" &&
        event.version === 1 &&
        event.phase === "error",
    ),
  );
  await page.screenshot({ path: `${directory}/04-startup-auth-failure.png` });
  checks.push(
    "actual-engine-startup-auth-failure-reaches-host-error-before-stall-timeout",
  );
  console.log(
    JSON.stringify(
      {
        checks,
        errors,
        failures,
        successfulRequests,
        downloadObservations: downloads.length,
        totalBytes: known.at(-1).totalBytes,
        downloadedBytes: known.at(-1).downloadedBytes,
        preparationMs: preparation.at,
        readyMs: ready.at,
        startupFailureDelayMs,
      },
      null,
      2,
    ),
  );
} catch (error) {
  if (page) {
    await page.screenshot({ path: `${directory}/failure.png` }).catch(() => {});
    observations = await page
      .evaluate(() => window.loadingObservations)
      .catch(() => undefined);
  }
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
    cleanup = true;
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
          requests,
          responses,
          observations,
          startupFailure,
          startupFailureDelayMs,
          expectedStartupErrors,
          expectedStartupFailures,
          ownTemporaryPlayerRemoved: cleanup,
        },
        null,
        2,
      ),
    );
  }
}
