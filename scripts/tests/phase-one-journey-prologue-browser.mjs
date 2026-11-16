// Run only against a source-matched local export, API, MongoDB, and Redis fixture.
import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import { createHash, randomBytes, randomUUID } from "node:crypto";
import {
  createReadStream,
  mkdirSync,
  readFileSync,
  statSync,
  writeFileSync,
} from "node:fs";
import { resolve } from "node:path";
import argon2 from "argon2";
import { chromium } from "@playwright/test";
import Redis from "ioredis";
import { MongoClient } from "mongodb";
import {
  freshAbilities,
  freshCalendar,
  freshHomestead,
  freshProgress,
} from "../../packages/shared/src/index.ts";

const originText = process.env.PHASE1_BROWSER_ORIGIN;
const mongoText = process.env.PHASE1_BROWSER_MONGO_URL;
const redisText = process.env.PHASE1_BROWSER_REDIS_URL;
const expectedSource = process.env.PHASE1_EXPECT_SOURCE_SHA;
const expectedPck = process.env.PHASE1_EXPECT_PCK;
const expectedPckBytes = Number(process.env.PHASE1_EXPECT_PCK_BYTES);
assert(
  originText && mongoText && redisText,
  "Set explicit PHASE1_BROWSER_ORIGIN, PHASE1_BROWSER_MONGO_URL, and PHASE1_BROWSER_REDIS_URL.",
);
assert(
  /^[a-f0-9]{40}$/.test(expectedSource ?? ""),
  "Pin PHASE1_EXPECT_SOURCE_SHA to the local Git commit.",
);
assert(
  /^[a-f0-9]{64}$/.test(expectedPck ?? ""),
  "Pin PHASE1_EXPECT_PCK to the candidate export.",
);
assert(
  Number.isSafeInteger(expectedPckBytes) && expectedPckBytes > 0,
  "Pin PHASE1_EXPECT_PCK_BYTES.",
);
assert(
  !process.env.BROWSER_FIXTURE,
  "Existing fixture accounts are not accepted.",
);
const origin = new URL(originText);
const mongoUrl = new URL(mongoText);
const redisUrl = new URL(redisText);
assert.equal(origin.protocol, "http:", "This fixture is local HTTP only.");
assert(
  ["127.0.0.1", "localhost"].includes(origin.hostname) &&
    Number(origin.port) >= 3100,
);
assert.equal(mongoUrl.protocol, "mongodb:");
assert(
  ["127.0.0.1", "localhost"].includes(mongoUrl.hostname) &&
    Number(mongoUrl.port) >= 27020,
);
assert(
  /^\/jalasmara_phase1_browser_[a-f0-9]{16,}$/.test(mongoUrl.pathname),
  "Use an explicit disposable Phase 1 browser database.",
);
assert.equal(redisUrl.protocol, "redis:");
assert(
  ["127.0.0.1", "localhost"].includes(redisUrl.hostname) &&
    Number(redisUrl.port) >= 6381,
);
assert.equal(
  redisUrl.pathname,
  "/15",
  "Use fixture Redis DB 15, not the owner/default service.",
);
const sourceSha = execFileSync("git", ["rev-parse", "HEAD"], {
  encoding: "utf8",
}).trim();
assert.equal(
  sourceSha,
  expectedSource,
  "Source changed after candidate export pinning.",
);
execFileSync("git", [
  "diff",
  "--quiet",
  "--",
  "client-godot",
  "apps/web",
  "apps/api",
  "packages/shared",
]);

const pckPath = resolve("apps/web/public/game/index.pck");
const manifestPath = resolve("apps/web/public/game/pck-manifest.json");
const sourceCommittedAt =
  Number(
    execFileSync("git", ["show", "-s", "--format=%ct", "HEAD"], {
      encoding: "utf8",
    }).trim(),
  ) * 1000;
assert(
  statSync(pckPath).mtimeMs >= sourceCommittedAt &&
    statSync(manifestPath).mtimeMs >= sourceCommittedAt,
  "Candidate PCK/manifest predates this source commit; export this SHA first.",
);
assert.equal(
  statSync(pckPath).size,
  expectedPckBytes,
  "Local candidate PCK byte count differs.",
);
const localHash = createHash("sha256");
for await (const chunk of createReadStream(pckPath)) localHash.update(chunk);
assert.equal(
  localHash.digest("hex"),
  expectedPck,
  "Local candidate PCK hash differs.",
);
const localManifest = JSON.parse(readFileSync(manifestPath, "utf8"));
assert.equal(localManifest.sha256, expectedPck);
assert.equal(localManifest.bytes, expectedPckBytes);
const remoteManifestResponse = await fetch(
  new URL("/game/pck-manifest.json", origin),
  {
    cache: "no-store",
    signal: AbortSignal.timeout(15000),
  },
);
assert(
  remoteManifestResponse.ok,
  `Local host did not serve the PCK manifest: ${remoteManifestResponse.status}`,
);
const remoteManifest = await remoteManifestResponse.json();
assert.equal(
  remoteManifest.sha256,
  expectedPck,
  "Host serves a different PCK.",
);
assert.equal(remoteManifest.bytes, expectedPckBytes);
assert.deepEqual(remoteManifest.hashes, localManifest.hashes);

const runId = randomUUID();
const email = `phase-one-browser-${runId}@test.invalid`;
const password = randomBytes(24).toString("base64url");
const artifactDir = resolve(`artifacts/browser/phase-one-prologue-${runId}`);
mkdirSync(artifactDir, { recursive: true });
const mongo = new MongoClient(mongoText);
const redis = new Redis(redisText);
let browser;
let context;
let page;
let frame;
let inserted = false;
let completed = false;
let cleaned = false;
let failure = "";
const errors = [];
const screenshots = [];
const checks = [];

async function screenshot(name, width, height) {
  await page.setViewportSize({ width, height });
  await frame.waitForFunction(
    ([w, h]) => {
      const size = window.jalasmaraSnapshot?.hud?.logicalSize;
      return size && Math.abs(size[0] / size[1] - w / h) < 0.02;
    },
    [width, height],
    { timeout: 10000, polling: 100 },
  );
  await page.waitForTimeout(350);
  const path = resolve(artifactDir, `${name}-${width}x${height}.png`);
  const png = await page.screenshot({ path });
  assert.equal(png.readUInt32BE(16), width);
  assert.equal(png.readUInt32BE(20), height);
  screenshots.push({
    path,
    width,
    height,
    sha256: createHash("sha256").update(png).digest("hex"),
  });
}

try {
  await mongo.connect();
  const db = mongo.db();
  assert.equal(
    await db.collection("players").countDocuments(),
    0,
    "The fixture DB must have no players before this run.",
  );
  assert.equal(await db.collection("shifts").countDocuments(), 0);
  assert.equal(await db.collection("receipts").countDocuments(), 0);
  assert.equal(
    await db.collection("contents").countDocuments({ state: "published" }),
    1,
    "Prepare exactly one published local catalog before starting the API.",
  );
  const now = new Date().toISOString();
  await db.collection("players").insertOne({
    id: runId,
    email,
    name: "Nala Prologue Fixture",
    role: "player",
    status: "active",
    appearance: "female_nusantara",
    coins: 0,
    inventory: [],
    abilities: freshAbilities(),
    progress: freshProgress(),
    adventure: { discoveries: [], puzzles: [], keyItems: [] },
    calendar: freshCalendar(),
    homestead: freshHomestead(),
    version: 0,
    authVersion: 0,
    passwordHash: await argon2.hash(password, { type: argon2.argon2id }),
    createdAt: now,
    updatedAt: now,
  });
  inserted = true;
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
    deviceScaleFactor: 1,
  });
  page = await context.newPage();
  page.on("pageerror", (error) => errors.push(error.message));
  page.on("console", (message) => {
    if (message.type() === "error") errors.push(message.text());
  });
  await page.addInitScript(() => {
    window.jalasmaraDiagnostics = true;
  });
  await page.goto(new URL("/login", origin).href);
  await page.getByLabel("Email", { exact: true }).fill(email);
  await page.getByLabel("Password", { exact: true }).fill(password);
  await page.getByRole("button", { name: "Masuk ke Jalasmara" }).click();
  await page.waitForURL("**/play");
  frame = await (await page.locator("iframe").elementHandle()).contentFrame();
  assert(frame);
  await frame.waitForFunction(
    () =>
      window.jalasmaraReady === true &&
      window.jalasmaraSnapshot?.modal === true,
    null,
    { timeout: 240000, polling: 200 },
  );
  const opening = await frame.evaluate(() => window.jalasmaraSnapshot);
  assert.equal(opening.stage, "dive");
  assert.equal(opening.diving, false);
  assert.equal(opening.dialogue?.speaker, "Mbah Wira");
  assert.equal(opening.dialogue?.portrait, true);
  checks.push("new-player-prologue-visible-with-portrait-and-world-paused");
  await screenshot("prologue", 844, 390);
  await screenshot("prologue", 667, 375);
  await frame.locator("canvas").focus();
  await page.keyboard.press("Escape");
  await frame.waitForFunction(
    () => window.jalasmaraSnapshot?.modal === false,
    null,
    { timeout: 10000, polling: 100 },
  );
  let gameState;
  for (let attempt = 0; attempt < 50; attempt++) {
    const response = await context.request.get(
      new URL("/api/game/state", origin).href,
    );
    assert(response.ok());
    gameState = await response.json();
    if (gameState.player.progress.tutorial) break;
    await page.waitForTimeout(200);
  }
  assert.equal(gameState.player.id, runId);
  assert.equal(
    gameState.player.progress.tutorial,
    true,
    "Skipping the prologue must acknowledge the tutorial once.",
  );
  checks.push("escape-skips-prologue-and-server-acknowledges-tutorial");
  await screenshot("after-skip", 667, 375);
  assert.deepEqual(
    errors,
    [],
    "No page/console errors during prologue playback.",
  );
  completed = true;
} catch (error) {
  failure =
    error instanceof Error ? (error.stack ?? error.message) : String(error);
  throw error;
} finally {
  const authCookies = context ? await context.cookies().catch(() => []) : [];
  await browser?.close();
  try {
    if (inserted) {
      const db = mongo.db();
      const removed = await db
        .collection("players")
        .deleteOne({ id: runId, email, name: "Nala Prologue Fixture" });
      assert.equal(removed.deletedCount, 1);
      const keys = [
        `surface:${runId}`,
        `home:${runId}`,
        `dive:${runId}`,
        `calendar:writer:${runId}`,
      ];
      for (const cookie of authCookies.filter((item) =>
        ["jalasmara", "__Host-jalasmara"].includes(item.name),
      )) {
        const key = `auth:${createHash("sha256").update(cookie.value).digest("hex")}`;
        const raw = await redis.get(key);
        if (raw) {
          assert.equal(JSON.parse(raw).userId, runId);
          keys.push(key);
        }
      }
      await redis.del(...keys);
      assert.equal(await db.collection("players").countDocuments(), 0);
      assert.equal(await db.collection("shifts").countDocuments(), 0);
      assert.equal(await db.collection("receipts").countDocuments(), 0);
      assert((await redis.mget(...keys)).every((value) => value === null));
      cleaned = true;
    }
  } finally {
    await mongo.close();
    await redis.quit();
    writeFileSync(
      resolve(artifactDir, "results.json"),
      JSON.stringify(
        {
          sourceSha,
          pckSha256: expectedPck,
          pckBytes: expectedPckBytes,
          origin: origin.href,
          fixtureDb: mongoUrl.pathname.slice(1),
          fixtureRedisDb: 15,
          runId,
          outcome: completed && cleaned ? "passed" : "failed",
          completed,
          cleaned,
          failure,
          checks,
          screenshots,
          errors,
          caveat:
            "This covers prologue presentation and skip in local Chromium/SwiftShader only; it does not prove the remaining Phase 1 scenes, physical journey, audio, or device performance.",
        },
        null,
        2,
      ),
    );
  }
}
