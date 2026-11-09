// Local real-loader body failure/retry acceptance; one own UUID per explicit asset mode.
import assert from "node:assert/strict";
import { randomUUID, randomBytes, createHash } from "node:crypto";
import { mkdirSync, writeFileSync } from "node:fs";
import { chromium } from "@playwright/test";
import { MongoClient } from "mongodb";
import Redis from "ioredis";
import argon2 from "argon2";
import {
  freshAbilities,
  freshProgress,
  freshCalendar,
  freshHomestead,
} from "../packages/shared/src/index.ts";
import { startLoaderBodyFault } from "./loader-body-fault.mjs";
import { withTrackedStreamErrors } from "./godot-preloader-stream.mjs";
import { withWasmInitErrors } from "./godot-wasm-init-errors.mjs";

const origin = process.env.APP_TEST_ORIGIN ?? "http://localhost:3101";
const mongoUrl =
  process.env.MONGO_URL ?? "mongodb://127.0.0.1:27018/jalasmara?replicaSet=rs0";
const redisUrl = process.env.REDIS_URL ?? "redis://127.0.0.1:6380";
const mode = process.env.PLAN06_LOADER_FAULT;
assert(
  ["pck", "wasm"].includes(mode),
  "Explicit PLAN06_LOADER_FAULT=pck|wasm required",
);
assert(["localhost", "127.0.0.1"].includes(new URL(origin).hostname));
assert(/^mongodb:\/\/(127\.0\.0\.1|localhost)(:|\/)/.test(mongoUrl));
assert(["localhost", "127.0.0.1"].includes(new URL(redisUrl).hostname));
assert(!process.env.BROWSER_FIXTURE);
const expectedPck = process.env.PLAN06_EXPECT_PCK,
  expectedPckBytes = Number(process.env.PLAN06_EXPECT_PCK_BYTES);
assert(
  /^[a-f0-9]{64}$/.test(expectedPck ?? "") &&
    Number.isSafeInteger(expectedPckBytes) &&
    expectedPckBytes > 0,
);
const id = randomUUID(),
  email = `loader-fault-${id}@test.invalid`,
  password = randomBytes(24).toString("base64url");
const directory = `artifacts/browser/loader-body-${mode}-${id}`;
mkdirSync(directory, { recursive: true });
const mongo = new MongoClient(mongoUrl),
  checks = [],
  consoleErrors = [],
  pageErrors = [],
  apiFailures = [],
  assetRequests = [],
  assetFailures = [],
  transfers = [],
  observations = [];
let browser,
  context,
  page,
  frame,
  fault,
  fixtureAttempted = false,
  cleaned = false,
  completed = false,
  phase = "preflight",
  failureSummary = null,
  manifest;
const path = `/game/index.${mode}`;
async function asset(extension, size) {
  const response = await fetch(`${origin}/game/index.${extension}`, {
    signal: AbortSignal.timeout(120000),
  });
  assert(response.ok);
  const hash = createHash("sha256"),
    parts = [];
  let bytes = 0,
    prefixBytes = 0;
  for await (const chunk of response.body) {
    hash.update(chunk);
    bytes += chunk.length;
    assert(bytes <= size);
    if (prefixBytes < 262144) {
      const part = chunk.subarray(0, 262144 - prefixBytes);
      parts.push(part);
      prefixBytes += part.length;
    }
  }
  assert.equal(bytes, size);
  return {
    decodedBytes: bytes,
    sha256: hash.digest("hex"),
    prefix: Buffer.concat(parts),
  };
}
async function shot(name) {
  await page.screenshot({ path: `${directory}/${name}.png` });
}
async function capture(name) {
  observations.push({
    name,
    at: Date.now(),
    phase,
    host: await page.evaluate(() => window.loaderFaultObservations),
    faultRequests: fault.requests.map((value) => ({ ...value })),
  });
}
try {
  const loaderResponse = await fetch(`${origin}/game/index.js`);
  assert(loaderResponse.ok);
  const loader = await loaderResponse.text();
  assert.equal(
    withWasmInitErrors(withTrackedStreamErrors(loader)),
    loader,
    "Actual served export must already include both reviewed rejection patches",
  );
  const bootstrapResponse = await fetch(`${origin}/game/bootstrap-1.js`);
  assert(bootstrapResponse.ok);
  const bootstrap = await bootstrapResponse.text(),
    match = bootstrap.match(/const GODOT_CONFIG = ([^\n]+);/);
  assert(match);
  const config = JSON.parse(match[1]);
  assert.equal(config.fileSizes["index.pck"], expectedPckBytes);
  const wasmBytes = config.fileSizes["index.wasm"];
  assert(Number.isSafeInteger(wasmBytes) && wasmBytes > 262144);
  const pck = await asset("pck", expectedPckBytes);
  assert.equal(pck.sha256, expectedPck);
  const wasm = await asset("wasm", wasmBytes);
  manifest = {
    pck: { sha256: expectedPck, decodedBytes: expectedPckBytes },
    wasm: { sha256: wasm.sha256, decodedBytes: wasmBytes },
    loaderSha256: createHash("sha256").update(loader).digest("hex"),
  };
  checks.push(
    "local-served-package-and-patched-loader-verified-before-fixture",
  );
  fault = await startLoaderBodyFault({
    path,
    origin,
    totalBytes: mode === "pck" ? expectedPckBytes : wasmBytes,
    prefix: mode === "pck" ? pck.prefix : wasm.prefix,
  });
  await mongo.connect();
  assert(
    await mongo.db().collection("contents").findOne({ state: "published" }),
  );
  const now = new Date().toISOString();
  fixtureAttempted = true;
  await mongo
    .db()
    .collection("players")
    .insertOne({
      id,
      email,
      name: "Nala Uji Loader Body",
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
    viewport: { width: 844, height: 390 },
    hasTouch: true,
    isMobile: true,
    serviceWorkers: "block",
  });
  page = await context.newPage();
  page.setDefaultTimeout(30000);
  const cdp = await context.newCDPSession(page);
  await cdp.send("Network.enable");
  await cdp.send("Network.setCacheDisabled", { cacheDisabled: true });
  const network = new Map();
  cdp.on("Network.requestWillBeSent", (event) => {
    const pathname = new URL(event.request.url).pathname;
    if (!/\/game\/index\.(wasm|pck)$/.test(pathname)) return;
    const record = { path: pathname, phase, at: Date.now(), dataBytes: 0 };
    network.set(event.requestId, record);
    transfers.push(record);
  });
  cdp.on("Network.responseReceived", (event) => {
    const record = network.get(event.requestId);
    if (record)
      Object.assign(record, {
        status: event.response.status,
        protocol: event.response.protocol,
      });
  });
  cdp.on("Network.dataReceived", (event) => {
    const record = network.get(event.requestId);
    if (record) record.dataBytes += event.dataLength;
  });
  cdp.on("Network.loadingFailed", (event) => {
    const record = network.get(event.requestId);
    if (record)
      Object.assign(record, {
        failedAt: Date.now(),
        error: event.errorText,
        cancelled: event.canceled,
      });
  });
  cdp.on("Network.loadingFinished", (event) => {
    const record = network.get(event.requestId);
    if (record) record.finishedAt = Date.now();
  });
  await page.addInitScript(() => {
    window.jalasmaraDiagnostics = true;
    if (window !== window.top) return;
    window.loaderFaultObservations = { events: [], dom: [] };
    addEventListener("message", (event) => {
      if (
        event.origin !== location.origin ||
        event.source !== document.querySelector("iframe")?.contentWindow ||
        !["jalasmara:loading", "jalasmara:ready"].includes(event.data?.type)
      )
        return;
      window.loaderFaultObservations.events.push({
        at: performance.now(),
        type: event.data.type,
        version: event.data.version,
        phase: event.data.phase,
        downloadedBytes: event.data.downloadedBytes,
        totalBytes: event.data.totalBytes,
      });
    });
    new MutationObserver(() => {
      const panel = document.querySelector(".game-loading"),
        progress = panel?.querySelector("progress");
      const value = {
        visible: Boolean(panel),
        percent:
          panel?.querySelector(".harbor-loading-percent")?.textContent ?? null,
        value: progress?.getAttribute("value") ?? null,
        stage: panel?.querySelector('[role="status"] p')?.textContent ?? null,
        detail:
          panel?.querySelector(".harbor-loading-detail")?.textContent ?? null,
      };
      const previous = window.loaderFaultObservations.dom.at(-1);
      if (!previous || JSON.stringify(previous) !== JSON.stringify(value))
        window.loaderFaultObservations.dom.push(value);
    }).observe(document, {
      subtree: true,
      childList: true,
      attributes: true,
      characterData: true,
    });
  });
  page.on("pageerror", (error) =>
    pageErrors.push({ phase, name: error.name, message: error.message }),
  );
  page.on("console", (message) => {
    if (message.type() === "error")
      consoleErrors.push({ phase, message: message.text() });
  });
  page.on("request", (request) => {
    const pathname = new URL(request.url()).pathname;
    if (/\/game\/index\.(wasm|pck)$/.test(pathname))
      assetRequests.push({ phase, path: pathname, at: Date.now() });
  });
  page.on("requestfailed", (request) => {
    const pathname = new URL(request.url()).pathname;
    if (/\/game\/index\.(wasm|pck)$/.test(pathname))
      assetFailures.push({
        phase,
        path: pathname,
        error: request.failure()?.errorText,
      });
  });
  page.on("response", (response) => {
    const pathname = new URL(response.url()).pathname;
    if (pathname.startsWith("/api/") && response.status() >= 400)
      apiFailures.push({ phase, path: pathname, status: response.status() });
  });
  let injected = true;
  await page.route(`${origin}${path}`, (route) =>
    injected ? route.continue({ url: fault.url }) : route.continue(),
  );
  phase = "injected-body-failure";
  await page.goto(`${origin}/login`);
  await page.getByLabel("Email", { exact: true }).fill(email);
  await page.getByLabel("Password", { exact: true }).fill(password);
  await page.getByRole("button", { name: "Masuk ke Jalasmara" }).click();
  await page.waitForURL("**/play");
  await page.waitForFunction(
    () =>
      window.loaderFaultObservations?.events.some(
        (event) => event.phase === "downloading" && event.downloadedBytes > 0,
      ),
    null,
    { timeout: 30000 },
  );
  await shot("01-real-partial-byte-progress");
  await page
    .getByRole("heading", { name: "Perjalanan belum dapat dimulai" })
    .waitFor({ timeout: 30000 });
  await page.waitForTimeout(400);
  await capture("injected-error-ui");
  await shot("02-real-body-error-and-retry");
  const failed = await page.evaluate(() => window.loaderFaultObservations),
    expectedAttempts = mode === "pck" ? 4 : 1;
  assert.equal(
    fault.requests.length,
    expectedAttempts,
    "Only the upstream four-attempt PCK budget or one raw-WASM consumer attempt is expected",
  );
  assert(
    fault.requests.every(
      (record) =>
        record.status === 200 &&
        record.writtenBytes === 262144 &&
        record.destroyedAt,
    ),
  );
  assert(
    transfers.some(
      (record) =>
        record.path === path && record.status === 200 && record.dataBytes > 0,
    ),
  );
  assert(assetFailures.some((record) => record.path === path));
  assert(failed.events.some((event) => event.phase === "error"));
  assert.equal(await page.getByRole("progressbar").count(), 0);
  assert.equal(
    await page
      .getByRole("button", { name: "Muat ulang permainan", exact: true })
      .count(),
    1,
  );
  assert.deepEqual(
    pageErrors,
    [],
    "Body failure must be handled, with no unhandled page rejection",
  );
  assert.deepEqual(apiFailures, []);
  const downloads = failed.events.filter(
    (event) => event.phase === "downloading" && event.downloadedBytes > 0,
  );
  assert(
    downloads.length > 0 &&
      downloads.every(
        (event) =>
          event.version === 1 &&
          Number.isSafeInteger(event.downloadedBytes) &&
          event.downloadedBytes <= event.totalBytes,
      ),
  );
  assert(
    downloads.some(
      (event) => event.totalBytes === expectedPckBytes + wasmBytes,
    ),
  );
  const percentages = new Set(
    downloads
      .filter((event) => event.totalBytes > 0)
      .map((event) =>
        String(Math.floor((100 * event.downloadedBytes) / event.totalBytes)),
      ),
  );
  assert(
    failed.dom.some(
      (value) =>
        /^\d+%$/.test(value.percent ?? "") &&
        percentages.has(value.percent.slice(0, -1)) &&
        value.value === value.percent.slice(0, -1),
    ),
  );
  checks.push(
    `${mode}-real-http200-partial-body-failure-reaches-visible-error-with-actual-progress-and-existing-attempt-budget`,
  );
  injected = false;
  phase = "successful-ui-retry";
  const retryStart = Date.now();
  const failedFrameElement = await page.locator("iframe").elementHandle();
  await page
    .getByRole("button", { name: "Muat ulang permainan", exact: true })
    .click();
  await page.waitForFunction(
    (element) => !element.isConnected,
    failedFrameElement,
  );
  await page.locator("iframe").waitFor();
  frame = await (await page.locator("iframe").elementHandle()).contentFrame();
  await frame.waitForFunction(
    () => window.jalasmaraReady && window.jalasmaraSnapshot?.hud,
    null,
    { polling: 200, timeout: 120000 },
  );
  await page.locator(".game-loading").waitFor({ state: "detached" });
  await page.waitForTimeout(500);
  await capture("successful-ui-retry");
  await shot("03-real-ready-after-retry");
  assert.equal(
    fault.requests.length,
    expectedAttempts,
    "Retry must use the healthy original origin, with no further injected sockets",
  );
  assert.equal(await page.locator("iframe").count(), 1);
  assert.deepEqual(pageErrors, []);
  assert.deepEqual(apiFailures, []);
  assert.deepEqual(
    consoleErrors.filter((error) => error.phase === "successful-ui-retry"),
    [],
  );
  const stateResponse = await context.request.get(
    `${origin}/api/adventure/state`,
  );
  assert(stateResponse.ok());
  const state = await stateResponse.json();
  assert.equal(state.player.coins, 200);
  assert.equal(state.player.progress.day, 1);
  assert.equal(state.player.progress.stage, "dive");
  assert.deepEqual(state.player.inventory, []);
  assert.equal(state.calendar.dayLengthMs, 36 * 60 * 1000);
  const actorCount = await frame.evaluate(
    () => window.jalasmaraSnapshot.land.actors.player,
  );
  assert.equal(actorCount, 1);
  observations.push({
    name: "successful-retry-metadata",
    retryMs: Date.now() - retryStart,
    actorCount,
  });
  checks.push(
    `${mode}-actual-ui-retry-replaces-frame-and-starts-real-game-without-economic-or-story-change`,
  );
  completed = true;
} catch (error) {
  failureSummary = {
    phase,
    name:
      error.name === "AssertionError"
        ? "AssertionError"
        : error.name === "TimeoutError"
          ? "TimeoutError"
          : "Error",
  };
  if (page) {
    await shot("failure").catch(() => {});
    if (fault) await capture("failure").catch(() => {});
  }
  throw error;
} finally {
  const cookies = context ? await context.cookies().catch(() => []) : [];
  const shutdownErrors = [];
  for (const operation of [() => browser?.close(), () => fault?.close()]) {
    try {
      await operation();
    } catch {
      shutdownErrors.push("owned-resource-close-failed");
    }
  }
  const cache = fixtureAttempted ? new Redis(redisUrl) : null;
  try {
    if (fixtureAttempted) {
      await mongo
        .db()
        .collection("players")
        .deleteOne({ id, email, role: "player", name: "Nala Uji Loader Body" });
      await mongo
        .db()
        .collection("receipts")
        .deleteMany({ _id: { $regex: `^${id}:` } });
      await mongo.db().collection("shifts").deleteMany({ userId: id });
      const keys = ["surface:", "home:", "calendar:writer:", "dive:"].map(
        (prefix) => prefix + id,
      );
      for (const cookie of cookies.filter((value) =>
        ["jalasmara", "__Host-jalasmara"].includes(value.name),
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
        await mongo.db().collection("players").countDocuments({ id }),
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
      assert((await cache.mget(...keys)).every((value) => value === null));
      cleaned = true;
    }
    assert.deepEqual(shutdownErrors, []);
  } finally {
    await mongo.close();
    await cache?.quit();
    const result = {
      origin,
      mode,
      manifest,
      checks,
      outcome: completed && cleaned ? "completed" : "failed",
      completed: completed && cleaned,
      failureSummary,
      expectedInjectedAssetFailures: assetFailures.filter(
        (record) => record.phase === "injected-body-failure",
      ),
      unexpectedRetryAssetFailures: assetFailures.filter(
        (record) => record.phase === "successful-ui-retry",
      ),
      expectedInjectedConsoleErrors: consoleErrors.filter(
        (record) => record.phase === "injected-body-failure",
      ),
      unexpectedRetryConsoleErrors: consoleErrors.filter(
        (record) => record.phase === "successful-ui-retry",
      ),
      pageErrors,
      apiFailures,
      assetRequests,
      transfers,
      observations,
      faultRequests: fault?.requests,
      ownTemporaryPlayerRemoved: cleaned,
      fixtureAttempted,
      shutdownErrors,
    };
    writeFileSync(`${directory}/results.json`, JSON.stringify(result, null, 2));
    console.log(
      JSON.stringify(
        {
          directory,
          checks,
          outcome: result.outcome,
          failureSummary,
          ownTemporaryPlayerRemoved: cleaned,
        },
        null,
        2,
      ),
    );
  }
}
