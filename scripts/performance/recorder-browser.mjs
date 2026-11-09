// Local, actual-game recorder acceptance. Never targets an existing account.
import { chromium } from "@playwright/test";
import { MongoClient } from "mongodb";
import Redis from "ioredis";
import argon2 from "argon2";
import { randomUUID, randomBytes, createHash } from "node:crypto";
import { mkdirSync, writeFileSync, readFileSync } from "node:fs";
import assert from "node:assert/strict";
import {
  freshAbilities,
  freshProgress,
  freshCalendar,
  freshHomestead,
} from "../../packages/shared/src/index.ts";
import { WORLD } from "../../packages/shared/src/world.ts";

const origin = process.env.APP_TEST_ORIGIN ?? "http://localhost:3111";
const mongoUrl =
  process.env.MONGO_URL ?? "mongodb://127.0.0.1:27018/jalasmara?replicaSet=rs0";
const redisUrl = process.env.REDIS_URL ?? "redis://127.0.0.1:6380";
assert(["localhost", "127.0.0.1"].includes(new URL(origin).hostname));
assert(/^mongodb:\/\/(127\.0\.0\.1|localhost)(:|\/)/.test(mongoUrl));
assert(["localhost", "127.0.0.1"].includes(new URL(redisUrl).hostname));
assert(!process.env.BROWSER_FIXTURE);
const expected = process.env.PLAN06_EXPECT_PCK;
const expectedBytes = Number(process.env.PLAN06_EXPECT_PCK_BYTES);
assert(/^[a-f0-9]{64}$/.test(expected ?? ""));
assert(Number.isSafeInteger(expectedBytes) && expectedBytes > 0);
const recorderMode = process.env.PERFORMANCE_RECORDER_MODE ?? "manual";
assert(["manual", "auto30"].includes(recorderMode), "PERFORMANCE_RECORDER_MODE must be manual or auto30");
const id = randomUUID();
const email = `recorder-${id}@test.invalid`;
const password = randomBytes(24).toString("base64url");
const name = "Nala Uji Rekaman";
const directory = `artifacts/browser/performance-recorder-${id}`;
mkdirSync(directory, { recursive: true });
const mongo = new MongoClient(mongoUrl);
const checks = [],
  errors = [],
  apiFailures = [],
  shutdownErrors = [];
let browser,
  context,
  page,
  fixtureAttempted = false,
  cleaned = false,
  completed = false,
  phase = "pin",
  failureStage = null;
let reportSummary;
const safe = (value) =>
  String(value)
    .replaceAll(email, "[fixture-email]")
    .replaceAll(password, "[fixture-password]")
    .replaceAll(id, "[fixture-id]");
async function shot(label) {
  await page.screenshot({ path: `${directory}/${label}.png` });
}
try {
  const response = await fetch(`${origin}/game/index.pck`, {
    signal: AbortSignal.timeout(30000),
  });
  assert.equal(response.status, 200);
  const hash = createHash("sha256");
  let downloaded = 0;
  for await (const chunk of response.body) {
    downloaded += chunk.length;
    assert(downloaded <= expectedBytes);
    hash.update(chunk);
  }
  assert.equal(downloaded, expectedBytes);
  assert.equal(hash.digest("hex"), expected);
  checks.push("live-local-PCK-byte-count-and-SHA-match-before-fixture");
  phase = "fixture";
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
      name,
      role: "player",
      status: "active",
      appearance: "male_nusantara",
      coins: 200,
      inventory: [],
      abilities: freshAbilities(),
      progress: { ...freshProgress(), day: 2, stage: "dive", tutorial: true },
      adventure: { discoveries: [], puzzles: [], keyItems: [] },
      calendar: {
        ...freshCalendar(),
        calendarDay: 2,
        lastSettledDay: 2,
        minuteOfDay: 600,
      },
      homestead: freshHomestead(2),
      version: 0,
      authVersion: 0,
      passwordHash: await argon2.hash(password, { type: argon2.argon2id }),
      createdAt: now,
      updatedAt: now,
    });
  const cache = new Redis(redisUrl);
  try {
    await cache.set(
      `surface:${id}`,
      JSON.stringify({
        area: "hub",
        ...WORLD.surfaceSpawn,
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
    acceptDownloads: true,
  });
  page = await context.newPage();
  page.setDefaultTimeout(15000);
  page.on("pageerror", (error) => errors.push(safe(error.message)));
  page.on("console", (message) => {
    if (message.type() === "error") errors.push(safe(message.text()));
  });
  page.on("response", async (response) => {
    const path = new URL(response.url()).pathname;
    if (path.startsWith("/api/") && response.status() >= 400) {
      const body = await response.json().catch(() => ({}));
      apiFailures.push({
        path,
        status: response.status(),
        code: String(body.code ?? body.error ?? "").slice(0, 100),
      });
    }
  });
  phase = "login";
  await page.goto(`${origin}/login`);
  await page.getByLabel("Email", { exact: true }).fill(email);
  await page.getByLabel("Password", { exact: true }).fill(password);
  await page.getByRole("button", { name: "Masuk ke Jalasmara" }).click();
  await page.waitForURL("**/play");
  phase = "actual-game-start";
  await page.locator("iframe").waitFor();
  const frame = await (
    await page.locator("iframe").elementHandle()
  ).contentFrame();
  await frame.waitForFunction(() => window.jalasmaraReady, null, {
    timeout: 90000,
    polling: 200,
  });
  await page
    .locator(".game-loading")
    .waitFor({ state: "detached", timeout: 90000 });
  assert.equal(
    await frame.evaluate(() => window.jalasmaraSnapshot == null),
    true,
    "Recorder must work without full QA/account snapshots",
  );
  checks.push("actual-game-ready-without-full-diagnostics-snapshot");
  phase = "start-recorder";
  await page.getByRole("button", { name: "Menu", exact: true }).click();
  await page.getByLabel("Durasi rekaman").selectOption("30000");
  await page.getByRole("button", { name: "Mulai rekam performa" }).click();
  await page.locator('.play-menu-toggle[data-capture="active"]').waitFor();
  await page.getByRole("dialog").waitFor({ state: "detached" });
  await frame.locator("canvas").focus();
  await page.keyboard.down("d");
  await page.waitForTimeout(180);
  await page.keyboard.up("d");
  await page.waitForTimeout(2400);
  await frame.waitForFunction(
    () => Number.isFinite(window.jalasmaraPerformance?.fps),
    null,
    { timeout: 10000 },
  );
  await shot("recording-actual-game");
  phase = "pause-resume";
  await page.getByRole("button", { name: "Menu", exact: true }).click();
  await page.getByRole("dialog").waitFor();
  await page.waitForTimeout(2200);
  await shot("menu-pauses-recording");
  await page.keyboard.press("Escape");
  await page.getByRole("dialog").waitFor({ state: "detached" });
  await frame.locator("canvas").focus();
  await page.waitForTimeout(2200);
  if (recorderMode === "auto30") {
    phase = "automatic-duration-expiry";
    await page.locator('.play-menu-toggle[data-capture="ready"]').waitFor({ timeout: 40000 });
    assert.equal(await page.getByRole("dialog").count(), 0,
      "Automatic completion must leave actual gameplay visible without opening the host menu");
    assert.equal(await frame.evaluate(() => window.jalasmaraSnapshot == null), true,
      "Automatic expiry cannot enable the full diagnostics/account snapshot");
    await shot("auto30-ready-during-actual-gameplay");
    await page.getByRole("button", { name: "Menu", exact: true }).click();
    assert.equal(await page.getByRole("button", { name: "Hentikan rekaman" }).count(), 0,
      "The completed capture cannot still expose an active Stop action");
  } else {
    await page.getByRole("button", { name: "Menu", exact: true }).click();
    await page.getByRole("button", { name: "Hentikan rekaman" }).click();
    await page.locator('.play-menu-toggle[data-capture="ready"]').waitFor();
  }
  phase = "download";
  const [download] = await Promise.all([
    page.waitForEvent("download"),
    page.getByRole("button", { name: "Unduh laporan JSON" }).click(),
  ]);
  assert.match(download.suggestedFilename(), /^jalasmara-performa-.*\.json$/);
  const file = `${directory}/downloaded-performance.json`;
  await download.saveAs(file);
  const raw = readFileSync(file, "utf8"),
    report = JSON.parse(raw);
  assert.equal(report.kind, "jalasmara-device-performance");
  assert.equal(report.schemaVersion, 1);
  assert.equal(report.session.durationMs, 30000);
  assert.equal(report.session.reason, recorderMode === "auto30" ? "duration-completed" : "user-stopped");
  if (recorderMode === "auto30") {
    assert(report.session.elapsedMs >= 30000 && report.session.elapsedMs < 45000,
      "Automatic completion must reach the actual30s host deadline under the bounded foreground acceptance window");
  } else assert(report.session.elapsedMs >= 6500 && report.session.elapsedMs < 30000);
  assert(
    report.frameScheduling.intervalsMs.count > 0 &&
      report.frameScheduling.pausedCallbacks > 0,
  );
  assert(report.samples.some((sample) => sample.paused));
  assert(
    report.samples.some(
      (sample) => !sample.paused && Number.isFinite(sample.values.fps),
    ),
  );
  assert(report.engine.fps.count > 0 && report.engine.processMs.count > 0);
  assert.equal(
    report.device.userAgent,
    await frame.evaluate(() => navigator.userAgent),
  );
  assert.equal(
    report.device.platform,
    await frame.evaluate(() => navigator.platform),
  );
  for (const secret of [id, email, password, origin])
    assert(
      !raw.includes(secret),
      "Local report must omit identity, credentials and page URL",
    );
  assert(
    !/"(token|cookie|inventory|coordinates|email|player|account)"\s*:/.test(
      raw,
    ),
  );
  assert(report.definitions.frameScheduling.includes("not GPU"));
  checks.push(
    recorderMode === "auto30"
      ? "actual30s-option-user-start-menu-pause-resume-automatic-expiry-and-local-JSON-download"
      : "actual30s-option-user-start-menu-pause-resume-stop-and-local-JSON-download",
  );
  checks.push(
    "real-engine-samples-and-browser-metadata-without-fixture-identity-or-account-state",
  );
  reportSummary = {
    kind: report.kind,
    durationMs: report.session.durationMs,
    elapsedMs: report.session.elapsedMs,
    reason: report.session.reason,
    frameCallbacks: report.frameScheduling.eligibleCallbacks,
    pausedCallbacks: report.frameScheduling.pausedCallbacks,
    sampleCount: report.samples.length,
    engineSampleCount: report.engine.fps.count,
    gpu: report.device.gpu,
    physicalDevice: false,
  };
  await shot("download-ready");
  assert.deepEqual(errors, []);
  assert.deepEqual(apiFailures, []);
  completed = true;
} catch (error) {
  failureStage = phase;
  if (page) await shot("failure").catch(() => {});
  console.error(safe(error.message));
  process.exitCode = 1;
} finally {
  const cookies = context ? await context.cookies().catch(() => []) : [];
  try {
    await browser?.close();
  } catch {
    shutdownErrors.push("owned-browser-close-failed");
    process.exitCode = 1;
  }
  const cache = fixtureAttempted ? new Redis(redisUrl) : null;
  try {
    if (fixtureAttempted) {
      await mongo
        .db()
        .collection("players")
        .deleteOne({ id, email, role: "player", name });
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
        await mongo
          .db()
          .collection("players")
          .countDocuments({ id, email, role: "player" }),
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
  } finally {
    await mongo.close();
    await cache?.quit();
    writeFileSync(
      `${directory}/results.json`,
      JSON.stringify(
        {
          origin,
          recorderMode,
          candidatePck: { sha256: expected, decodedBytes: expectedBytes },
          outcome: completed && cleaned && shutdownErrors.length === 0 ? "passed" : "failed",
          completed,
          failureStage,
          checks,
          errors,
          apiFailures,
          shutdownErrors,
          reportSummary,
          ownTemporaryPlayerRemoved: cleaned,
          limits: [
            "Local Chromium software-renderer acceptance, not physical Samsung S23 or Windows performance.",
            recorderMode === "auto30"
              ? "Auto30 requires actual duration-completed at the host wall-clock deadline; menu pauses exclude measurements, not elapsed time. Five-minute completion is not covered."
              : "Configured30s capture was manually stopped after pause/resume; automatic expiry and5min completion are not claimed.",
          ],
        },
        null,
        2,
      ),
    );
  }
}
console.log(
  JSON.stringify({ directory, completed, cleaned, checks: checks.length }),
);
