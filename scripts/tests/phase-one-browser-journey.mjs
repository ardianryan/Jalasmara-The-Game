// Local browser replay of disposable Phase 1 story checkpoints. Run after a source-matched export/build.
import assert from "node:assert/strict";
import { spawn, execFileSync } from "node:child_process";
import { createHash, randomBytes, randomUUID } from "node:crypto";
import {
  createReadStream,
  closeSync,
  mkdirSync,
  openSync,
  readFileSync,
  statSync,
  writeFileSync,
} from "node:fs";
import { createServer } from "node:net";
import { resolve } from "node:path";
import { once } from "node:events";
import argon2 from "argon2";
import { chromium } from "@playwright/test";
import Redis from "ioredis";
import { MongoClient } from "mongodb";
import { seedCatalog } from "../../apps/api/src/content.ts";
import {
  freshAbilities,
  freshCalendar,
  freshHomestead,
  freshProgress,
} from "../../packages/shared/src/index.ts";
import { WORLD } from "../../packages/shared/src/world.ts";

const mongoText = process.env.PHASE1_BROWSER_MONGO_URL;
const redisText = process.env.PHASE1_BROWSER_REDIS_URL;
const expectedSource = process.env.PHASE1_EXPECT_SOURCE_SHA;
const expectedPck = process.env.PHASE1_EXPECT_PCK;
const expectedPckBytes = Number(process.env.PHASE1_EXPECT_PCK_BYTES);
assert(
  mongoText && redisText,
  "Set disposable PHASE1_BROWSER_MONGO_URL and PHASE1_BROWSER_REDIS_URL.",
);
assert(
  /^[a-f0-9]{40}$/.test(expectedSource ?? ""),
  "Pin PHASE1_EXPECT_SOURCE_SHA to HEAD.",
);
assert(
  /^[a-f0-9]{64}$/.test(expectedPck ?? ""),
  "Pin PHASE1_EXPECT_PCK to the candidate export.",
);
assert(
  Number.isSafeInteger(expectedPckBytes) && expectedPckBytes > 0,
  "Pin PHASE1_EXPECT_PCK_BYTES.",
);
const mongoUrl = new URL(mongoText);
const redisUrl = new URL(redisText);
assert.equal(mongoUrl.protocol, "mongodb:");
assert(
  ["127.0.0.1", "localhost"].includes(mongoUrl.hostname) &&
    Number(mongoUrl.port) >= 27020,
);
assert(
  /^\/jalasmara_phase1_browser_journey_[a-f0-9]{16,}$/.test(mongoUrl.pathname),
  "Use a unique Phase 1 browser database.",
);
assert.equal(redisUrl.protocol, "redis:");
assert(
  ["127.0.0.1", "localhost"].includes(redisUrl.hostname) &&
    Number(redisUrl.port) >= 6381,
);
assert.equal(redisUrl.pathname, "/15", "Use fixture Redis DB 15.");

const caseIds = [
  "prologue",
  "first_dive",
  "first_kedai",
  "first_service",
  "garden_crisis",
  "saras_visit",
  "cave_warning",
  "earthquake",
  "boss_intro",
  "boss_phase_two",
  "victory",
  "epilogue",
];
const titles = {
  prologue: "Kabut di Atas Bandar Hujung",
  first_dive: "Tetes Pertama di Segaran",
  first_kedai: "Malam Pertama di Kedai Waras",
  first_service: "Ingatan yang Menyala",
  garden_crisis: "Krisis Kebun Apung",
  saras_visit: "Tamu Rahasia di Kedai Waras",
  cave_warning: "Gema dari Jalatunda",
  earthquake: "Lagu Sandi Sang Penjaga",
  boss_intro: "Gajah Mina Penjaga yang Tercemar",
  boss_phase_two: "Inti Smara Terbuka",
  victory: "Hujan Cahaya Ingatan",
  epilogue: "Fajar Baru di Bandar Hujung",
};
const imagemagickVersion = execFileSync("magick", ["-version"], {
  encoding: "utf8",
}).split("\n")[0];
const tesseractVersion = execFileSync("tesseract", ["--version"], {
  encoding: "utf8",
}).split("\n")[0];
const selected = new Set(
  (process.env.PHASE1_BROWSER_CASES || caseIds.join(","))
    .split(",")
    .map((part) => part.trim()),
);
assert(
  [...selected].every((id) => caseIds.includes(id)),
  "Unknown PHASE1_BROWSER_CASES entry.",
);
assert(selected.size > 0);
assert(
  !selected.has("epilogue") || selected.has("victory"),
  "Epilogue follows victory in the same browser session.",
);
assert(
  !selected.has("boss_phase_two") || selected.has("boss_intro"),
  "Phase two follows boss intro in the same browser session.",
);

const runId = randomUUID();
const artifactDir = resolve(`artifacts/browser/phase-one-journey-${runId}`);
mkdirSync(artifactDir, { recursive: true });
const sourceSha = execFileSync("git", ["rev-parse", "HEAD"], {
  encoding: "utf8",
}).trim();
assert.equal(sourceSha, expectedSource, "Source changed after export pinning.");
execFileSync("git", [
  "diff",
  "--quiet",
  "--",
  "client-godot",
  "apps/web",
  "apps/api",
  "packages/shared",
]);
const sourceTime =
  Number(
    execFileSync("git", ["show", "-s", "--format=%ct", "HEAD"], {
      encoding: "utf8",
    }).trim(),
  ) * 1000;
const publicPck = resolve("apps/web/public/game/index.pck");
const distPck = resolve("apps/web/dist/game/index.pck");
const publicManifest = resolve("apps/web/public/game/pck-manifest.json");
const distManifest = resolve("apps/web/dist/game/pck-manifest.json");
const webHtml = resolve("apps/web/dist/index.html");
const apiEntry = resolve("apps/api/dist/apps/api/src/index.js");
for (const path of [
  publicPck,
  publicManifest,
  distPck,
  distManifest,
  webHtml,
  apiEntry,
]) {
  assert(
    statSync(path).mtimeMs >= sourceTime,
    `${path} predates source HEAD; rebuild this SHA.`,
  );
}
assert.equal(statSync(publicPck).size, expectedPckBytes);
assert.equal(statSync(distPck).size, expectedPckBytes);
const manifest = JSON.parse(readFileSync(publicManifest, "utf8"));
assert.deepEqual(JSON.parse(readFileSync(distManifest, "utf8")), manifest);
assert.equal(manifest.sha256, expectedPck);
assert.equal(manifest.bytes, expectedPckBytes);
for (const path of [publicPck, distPck]) {
  const hash = createHash("sha256");
  for await (const chunk of createReadStream(path)) hash.update(chunk);
  assert.equal(
    hash.digest("hex"),
    expectedPck,
    `${path} differs from pinned PCK.`,
  );
}

const checks = [];
const screenshots = [];
const errors = [];
const observed = [];
const mongo = new MongoClient(mongoText);
const redis = new Redis(redisText);
const accounts = new Map();
const authCookies = [];
let browser;
let server;
let logFd;
let origin;
let contentId = "";
let cleaned = false;
let completed = false;
let failure = "";
let mongoConnected = false;

async function freePort() {
  const listener = createServer();
  listener.listen(0, "127.0.0.1");
  await once(listener, "listening");
  const port = listener.address().port;
  listener.close();
  await once(listener, "close");
  return port >= 3100 ? port : freePort();
}

async function waitForServer() {
  for (let attempt = 0; attempt < 100; attempt++) {
    if (server.exitCode !== null)
      throw new Error(`Fixture API exited: ${server.exitCode}`);
    try {
      const response = await fetch(new URL("/api/health", origin), {
        signal: AbortSignal.timeout(1000),
      });
      if (response.ok && (await response.json()).status === "ok") return;
    } catch {
      /* The private listener may still be starting. */
    }
    await new Promise((done) => setTimeout(done, 150));
  }
  throw new Error("Fixture API did not become healthy.");
}

function playerSeed(label, day, stage, extra = {}) {
  const id = randomUUID();
  const password = randomBytes(24).toString("base64url");
  const progress = {
    ...freshProgress(),
    day,
    stage,
    tutorial: label !== "opening",
    ...extra.progress,
  };
  const now = new Date().toISOString();
  return {
    id,
    password,
    document: {
      id,
      email: `phase-one-browser-${id}@test.invalid`,
      name: `Phase 1 ${label}`,
      role: "player",
      status: "active",
      appearance: "female_nusantara",
      coins: 0,
      inventory: [],
      abilities: { ...freshAbilities(), ...extra.abilities },
      progress,
      adventure: extra.adventure ?? {
        discoveries: [],
        puzzles: [],
        keyItems: [],
      },
      calendar: freshCalendar(),
      homestead: freshHomestead(),
      version: 0,
      authVersion: 0,
      createdAt: now,
      updatedAt: now,
    },
  };
}

async function createPlayer(label, day, stage, extra) {
  const seed = playerSeed(label, day, stage, extra);
  seed.document.passwordHash = await argon2.hash(seed.password, {
    type: argon2.argon2id,
  });
  await mongo.db().collection("players").insertOne(seed.document);
  accounts.set(label, seed);
  return seed;
}

async function login(context, account) {
  const session = await context.request.get(
    new URL("/api/auth/session", origin).href,
  );
  assert(session.ok(), "Fixture auth session failed.");
  let csrf = (await session.json()).csrf;
  const response = await context.request.post(
    new URL("/api/auth/login", origin).href,
    {
      headers: { origin: origin.origin, "x-csrf-token": csrf },
      data: { email: account.document.email, password: account.password },
    },
  );
  assert(response.ok(), `Fixture login failed: ${response.status()}`);
  const body = await response.json();
  assert.equal(body.user.id, account.id);
  csrf = body.csrf;
  return async (path, data) => {
    const result = await context.request.post(
      new URL(`/api${path}`, origin).href,
      {
        headers: {
          origin: origin.origin,
          "x-csrf-token": csrf,
          "idempotency-key": randomUUID(),
        },
        data,
      },
    );
    const json = await result.json();
    assert(result.ok(), `${path}: ${result.status()} ${JSON.stringify(json)}`);
    return json;
  };
}

async function openGame(context, previousPage) {
  const page = previousPage ?? (await context.newPage());
  if (!previousPage) {
    page.on("pageerror", (error) => errors.push(error.message));
    page.on("console", (message) => {
      if (message.type() === "error") errors.push(message.text());
    });
    await page.addInitScript(() => {
      window.jalasmaraDiagnostics = true;
    });
  }
  if (previousPage) await page.reload({ waitUntil: "domcontentloaded" });
  else
    await page.goto(new URL("/play", origin).href, {
      waitUntil: "domcontentloaded",
    });
  const element = await page
    .locator("iframe")
    .elementHandle({ timeout: 30000 });
  assert(element, "Godot iframe missing.");
  const frame = await element.contentFrame();
  assert(frame);
  await frame.waitForFunction(
    () => window.jalasmaraReady === true && !!window.jalasmaraSnapshot,
    null,
    {
      timeout: 240000,
      polling: 150,
    },
  );
  await frame.locator("canvas").focus();
  await page.keyboard.press("Shift");
  await frame.waitForFunction(
    () => window.jalasmaraSnapshot?.audio?.unlocked === true,
    null,
    { timeout: 10000, polling: 100 },
  );
  return { page, frame };
}

async function waitForSpeaker(frame, speaker) {
  await frame.waitForFunction(
    (expected) => {
      const state = window.jalasmaraSnapshot;
      return state?.modal === true && state.dialogue?.speaker === expected;
    },
    speaker,
    { timeout: 30000, polling: 100 },
  );
  return frame.evaluate(() => window.jalasmaraSnapshot);
}

async function picture(playback, name, width, height, expectPortrait = true) {
  const { page, frame } = playback;
  await page.setViewportSize({ width, height });
  await frame.waitForFunction(
    ([w, h]) => {
      const size = window.jalasmaraSnapshot?.hud?.logicalSize;
      return size && Math.abs(size[0] / size[1] - w / h) < 0.02;
    },
    [width, height],
    { timeout: 12000, polling: 100 },
  );
  await page.waitForTimeout(450);
  const state = await frame.evaluate(() => window.jalasmaraSnapshot);
  assert.equal(
    state?.dialogue?.portrait,
    expectPortrait,
    `${name}: speaker portrait mismatch.`,
  );
  const logical = state.hud.logicalSize;
  const dialog = state.dialogue;
  assert(
    dialog.position[0] >= 0 && dialog.position[1] >= 0,
    `${name}: dialog starts outside view.`,
  );
  assert(
    dialog.position[0] + dialog.size[0] <= logical[0] + 2,
    `${name}: dialog clips right edge.`,
  );
  assert(
    dialog.position[1] + dialog.size[1] <= logical[1] + 2,
    `${name}: dialog clips bottom edge.`,
  );
  const path = resolve(artifactDir, `${name}-${width}x${height}.png`);
  const image = await page.screenshot({ path });
  assert.equal(image.readUInt32BE(16), width);
  assert.equal(image.readUInt32BE(20), height);
  let ocrTitle = "";
  if (width === 667) {
    const id = name.split("-")[0];
    const cropped = execFileSync("magick", [
      path,
      "-crop",
      "520x52+0+0",
      "-resize",
      "300%",
      "png:-",
    ]);
    ocrTitle = execFileSync("tesseract", ["stdin", "stdout", "--psm", "7"], {
      input: cropped,
      stdio: ["pipe", "pipe", "ignore"],
      encoding: "utf8",
    }).trim();
    const normalize = (value) =>
      value
        .toLowerCase()
        .normalize("NFKD")
        .replace(/[^a-z0-9]+/g, " ")
        .trim();
    assert(
      normalize(ocrTitle).includes(normalize(titles[id])),
      `${name}: expected cutscene title ${titles[id]}, OCR saw ${ocrTitle}.`,
    );
  }
  screenshots.push({
    name,
    path,
    width,
    height,
    sha256: createHash("sha256").update(image).digest("hex"),
    ocrTitle,
  });
}

async function checkpoint(playback, id, speaker, track, stage) {
  const state = await waitForSpeaker(playback.frame, speaker);
  assert.equal(state.stage, stage, `${id}: unexpected server-owned stage.`);
  try {
    await playback.frame.waitForFunction(
      (expected) => window.jalasmaraSnapshot?.audio?.track === expected,
      track,
      { timeout: 18000, polling: 100 },
    );
  } catch (error) {
    const actual = await playback.frame.evaluate(
      () => window.jalasmaraSnapshot,
    );
    throw new Error(
      `${id}: expected BGM ${track}, observed ${JSON.stringify(actual?.audio)}; ${error}`,
    );
  }
  await picture(playback, id, 844, 390);
  await picture(playback, id, 667, 375);
  const final = await playback.frame.evaluate(() => window.jalasmaraSnapshot);
  observed.push({
    id,
    stage,
    speaker: final.dialogue.speaker,
    audioTrack: final.audio.track,
    audioPlayingReported: final.audio.playing,
    portrait: final.dialogue.portrait,
    title: screenshots.findLast(
      (shot) => shot.name === id && shot.width === 667,
    )?.ocrTitle,
  });
  checks.push(`${id}-presented-at-844x390-and-667x375`);
}

async function skip(playback, nextSpeaker = "") {
  await playback.frame.locator("canvas").focus();
  await playback.page.keyboard.press("Escape");
  await playback.frame.waitForFunction(
    (expected) => {
      const state = window.jalasmaraSnapshot;
      return expected
        ? state?.dialogue?.speaker === expected
        : state && !state.dialogue?.speaker;
    },
    nextSpeaker,
    { timeout: 18000, polling: 100 },
  );
}

async function advanceTo(playback, speaker) {
  await playback.frame.locator("canvas").focus();
  for (let press = 0; press < 14; press++) {
    await playback.page.keyboard.press("Space");
    await playback.page.waitForTimeout(130);
    const current = await playback.frame.evaluate(
      () => window.jalasmaraSnapshot?.dialogue?.speaker,
    );
    if (current === speaker) return;
  }
  throw new Error(
    `The expected ${speaker} beat did not appear after 14 advances.`,
  );
}

async function setProgress(account, patch) {
  const result = await mongo
    .db()
    .collection("players")
    .updateOne(
      { id: account.id, email: account.document.email },
      {
        $set: Object.fromEntries(
          Object.entries(patch).map(([key, value]) => [
            `progress.${key}`,
            value,
          ]),
        ),
        $inc: { version: 1 },
      },
    );
  assert.equal(result.matchedCount, 1);
}

async function setupScene(label) {
  const account = accounts.get(label);
  const context = await browser.newContext({
    viewport: { width: 844, height: 390 },
    deviceScaleFactor: 1,
  });
  const post = await login(context, account);
  return { account, context, post, playback: null };
}

async function closeScene(scene) {
  authCookies.push(
    ...(await scene.context.cookies()).filter((cookie) =>
      ["jalasmara", "__Host-jalasmara"].includes(cookie.name),
    ),
  );
  await scene.context.close();
}

try {
  await mongo.connect();
  mongoConnected = true;
  const db = mongo.db();
  for (const name of ["players", "shifts", "receipts", "contents"]) {
    assert.equal(
      await db.collection(name).countDocuments(),
      0,
      `Fixture ${name} collection must be empty.`,
    );
  }
  contentId = randomUUID();
  const now = new Date().toISOString();
  await db.collection("contents").insertOne({
    id: contentId,
    label: "Phase 1 browser journey fixture",
    state: "published",
    catalog: seedCatalog(),
    createdAt: now,
    publishedAt: now,
  });
  await createPlayer("opening", 1, "dive");
  await createPlayer("garden", 2, "dive", {
    adventure: {
      discoveries: ["nitrogen", "photosynthesis", "osmosis"],
      puzzles: [],
      keyItems: [],
    },
  });
  await createPlayer("deep", 3, "dive", {
    abilities: {
      oxygen: WORLD.boss.requiredUpgrades.oxygen,
      net: WORLD.boss.requiredUpgrades.net,
    },
  });
  await createPlayer("ending", 3, "done", {
    progress: {
      bossDefeated: true,
      missions: ["gajah_mina"],
    },
    adventure: { discoveries: [], puzzles: [], keyItems: [WORLD.boss.keyItem] },
  });

  const port = await freePort();
  origin = new URL(`http://127.0.0.1:${port}`);
  logFd = openSync(resolve(artifactDir, "fixture-api.log"), "wx");
  server = spawn(process.execPath, [apiEntry], {
    cwd: resolve("."),
    env: {
      ...process.env,
      NODE_ENV: "test",
      HOST: "127.0.0.1",
      PORT: String(port),
      APP_ORIGIN: origin.origin,
      MONGO_URL: mongoText,
      REDIS_URL: redisText,
      WEB_DIST: resolve("apps/web/dist"),
    },
    stdio: ["ignore", logFd, logFd],
  });
  await waitForServer();
  const servedHtml = await fetch(new URL("/play", origin), {
    signal: AbortSignal.timeout(10000),
  });
  assert(servedHtml.ok);
  assert.equal(
    await servedHtml.text(),
    readFileSync(webHtml, "utf8"),
    "Host HTML differs from local build.",
  );
  const servedManifest = await fetch(
    new URL("/game/pck-manifest.json", origin),
    { signal: AbortSignal.timeout(10000) },
  );
  assert(servedManifest.ok);
  assert.deepEqual(
    await servedManifest.json(),
    manifest,
    "Host PCK manifest differs from local build.",
  );
  checks.push("source-api-web-and-pck-bound-to-local-candidate");

  browser = await chromium.launch({
    args: [
      "--enable-webgl",
      "--use-gl=angle",
      "--use-angle=swiftshader",
      "--enable-unsafe-swiftshader",
    ],
  });
  if (
    ["prologue", "first_dive", "first_kedai", "first_service"].some((id) =>
      selected.has(id),
    )
  ) {
    const scene = await setupScene("opening");
    try {
      scene.playback = await openGame(scene.context);
      if (selected.has("prologue"))
        await checkpoint(
          scene.playback,
          "prologue",
          "Mbah Wira",
          "title_theme",
          "dive",
        );
      await skip(scene.playback);
      for (let attempt = 0; attempt < 50; attempt++) {
        const response = await scene.context.request.get(
          new URL("/api/game/state", origin).href,
        );
        if ((await response.json()).player.progress.tutorial) break;
        await scene.playback.page.waitForTimeout(200);
      }
      const acknowledged = await (
        await scene.context.request.get(new URL("/api/game/state", origin).href)
      ).json();
      assert.equal(
        acknowledged.player.progress.tutorial,
        true,
        "Prologue skip must acknowledge the tutorial.",
      );
      checks.push("prologue-skip-acknowledges-tutorial-on-server");
      if (selected.has("first_dive")) {
        await scene.post("/dive/start", { mode: "dive" });
        scene.playback = await openGame(scene.context, scene.playback.page);
        await checkpoint(
          scene.playback,
          "first_dive",
          "Nala",
          "underwater_segaran",
          "dive",
        );
        await skip(scene.playback);
      }
      if (selected.has("first_kedai") || selected.has("first_service")) {
        await redis.del(`dive:${scene.account.id}`);
        await setProgress(scene.account, { stage: "night" });
        const shift = (await scene.post("/kedai/start", {})).shift;
        assert(
          shift.customers.some((customer) => customer.id === "daun_kuning"),
        );
        scene.playback = await openGame(scene.context, scene.playback.page);
        if (selected.has("first_kedai"))
          await checkpoint(
            scene.playback,
            "first_kedai",
            "Pak Ranto",
            "kedai_waras_night",
            "night",
          );
        await skip(scene.playback);
        if (selected.has("first_service")) {
          const update = await db
            .collection("shifts")
            .updateOne(
              { id: shift.id, userId: scene.account.id },
              { $set: { served: ["daun_kuning"] } },
            );
          assert.equal(update.matchedCount, 1);
          scene.playback = await openGame(scene.context, scene.playback.page);
          await checkpoint(
            scene.playback,
            "first_service",
            "Pak Ranto",
            "kedai_waras_night",
            "night",
          );
          await advanceTo(scene.playback, "Inspektur Raka");
          await picture(scene.playback, "first_service-raka", 667, 375);
          await skip(scene.playback);
        }
      }
    } finally {
      await closeScene(scene);
    }
  }

  if (["garden_crisis", "saras_visit"].some((id) => selected.has(id))) {
    const scene = await setupScene("garden");
    try {
      scene.playback = await openGame(scene.context);
      if (selected.has("garden_crisis"))
        await checkpoint(
          scene.playback,
          "garden_crisis",
          "Bu Darmi",
          "coastal_day",
          "dive",
        );
      await skip(scene.playback);
      if (selected.has("saras_visit")) {
        await setProgress(scene.account, { stage: "night" });
        const shift = (await scene.post("/kedai/start", {})).shift;
        const update = await db
          .collection("shifts")
          .updateOne(
            { id: shift.id, userId: scene.account.id },
            { $set: { served: ["akar"] } },
          );
        assert.equal(update.matchedCount, 1);
        scene.playback = await openGame(scene.context, scene.playback.page);
        await checkpoint(
          scene.playback,
          "saras_visit",
          "Bu Darmi",
          "village_hall",
          "night",
        );
        await advanceTo(scene.playback, "Saras");
        await picture(scene.playback, "saras_visit-saras", 667, 375);
        await skip(scene.playback);
      }
    } finally {
      await closeScene(scene);
    }
  }

  if (
    ["cave_warning", "earthquake", "boss_intro", "boss_phase_two"].some((id) =>
      selected.has(id),
    )
  ) {
    const scene = await setupScene("deep");
    try {
      if (selected.has("cave_warning")) {
        await scene.post("/dive/start", { mode: "dive" });
        const key = `dive:${scene.account.id}`;
        const dive = JSON.parse(await redis.get(key));
        dive.position = { x: 4200, y: 2200 };
        dive.updatedAt = Date.now();
        await redis.set(key, JSON.stringify(dive), "KEEPTTL");
        scene.playback = await openGame(scene.context);
        await checkpoint(
          scene.playback,
          "cave_warning",
          "Saras",
          "underwater_cave_deep",
          "dive",
        );
        await skip(scene.playback);
      }
      if (selected.has("earthquake") || selected.has("boss_intro")) {
        await redis.del(`dive:${scene.account.id}`);
        await setProgress(scene.account, { stage: "boss" });
        scene.playback = await openGame(scene.context, scene.playback?.page);
        if (selected.has("earthquake"))
          await checkpoint(
            scene.playback,
            "earthquake",
            "Ki Lurah Wirabhumi",
            "village_hall",
            "boss",
          );
        await skip(scene.playback);
      }
      if (selected.has("boss_intro")) {
        const started = await scene.post("/dive/start", { mode: "boss" });
        assert.equal(started.dive.requiredHits, 6);
        scene.playback = await openGame(scene.context, scene.playback.page);
        await checkpoint(
          scene.playback,
          "boss_intro",
          "Saras",
          "boss_gajah_mina",
          "boss",
        );
        await skip(scene.playback);
        await scene.playback.page.waitForTimeout(3000);
      }
      if (selected.has("boss_phase_two")) {
        const key = `dive:${scene.account.id}`;
        const dive = JSON.parse(await redis.get(key));
        dive.hits = 3;
        dive.targets.slice(0, 3).forEach((target) => {
          target.caught = true;
        });
        dive.oxygen = dive.maxOxygen;
        dive.updatedAt = Date.now();
        await redis.set(key, JSON.stringify(dive), "KEEPTTL");
        scene.playback = await openGame(scene.context, scene.playback.page);
        await checkpoint(
          scene.playback,
          "boss_phase_two",
          "Saras",
          "boss_gajah_mina",
          "boss",
        );
      }
    } finally {
      await closeScene(scene);
    }
  }

  if (selected.has("victory")) {
    const scene = await setupScene("ending");
    try {
      scene.playback = await openGame(scene.context);
      await checkpoint(
        scene.playback,
        "victory",
        "Nala",
        "coastal_dusk",
        "done",
      );
      await skip(scene.playback, "Inspektur Raka");
      if (selected.has("epilogue")) {
        await checkpoint(
          scene.playback,
          "epilogue",
          "Inspektur Raka",
          "village_hall",
          "done",
        );
        for (const speaker of [
          "Ki Lurah Wirabhumi",
          "Gito",
          "Saras",
          "Ki Lurah Wirabhumi",
          "Beno",
          "Mbah Wira",
          "Jala Smara",
        ]) {
          await advanceTo(scene.playback, speaker);
          if (speaker === "Saras") {
            await scene.playback.frame.waitForFunction(
              () => window.jalasmaraSnapshot?.audio?.track === "coastal_dusk",
              null,
              { timeout: 12000 },
            );
            await picture(scene.playback, "epilogue-map-room", 667, 375);
          }
        }
        await picture(scene.playback, "epilogue-ending-card", 844, 390, false);
        await picture(scene.playback, "epilogue-ending-card", 667, 375, false);
        checks.push("epilogue-reaches-ending-card-and-map-room-music-change");
        await skip(scene.playback);
      }
    } finally {
      await closeScene(scene);
    }
  }
  assert.deepEqual(errors, [], "Browser console/page errors occurred.");
  completed = true;
} catch (error) {
  failure =
    error instanceof Error ? (error.stack ?? error.message) : String(error);
  throw error;
} finally {
  await browser?.close();
  if (server && server.exitCode === null) {
    server.kill("SIGTERM");
    await Promise.race([
      once(server, "close"),
      new Promise((done) => setTimeout(done, 5000)),
    ]);
  }
  if (logFd !== undefined) closeSync(logFd);
  try {
    if (mongoConnected) {
      const db = mongo.db();
      const ids = [...accounts.values()].map((account) => account.id);
      const keys = ids.flatMap((id) => [
        `surface:${id}`,
        `home:${id}`,
        `dive:${id}`,
        `calendar:writer:${id}`,
      ]);
      for (const cookie of authCookies) {
        const key = `auth:${createHash("sha256").update(cookie.value).digest("hex")}`;
        const raw = await redis.get(key);
        if (raw && ids.includes(JSON.parse(raw).userId)) keys.push(key);
      }
      if (keys.length) await redis.del(...keys);
      await db
        .collection("receipts")
        .deleteMany({ _id: { $in: ids.map((id) => new RegExp(`^${id}:`)) } });
      await db.collection("shifts").deleteMany({ userId: { $in: ids } });
      await db.collection("players").deleteMany({ id: { $in: ids } });
      if (contentId)
        await db.collection("contents").deleteOne({ id: contentId });
      for (const name of ["players", "shifts", "receipts", "contents"])
        assert.equal(await db.collection(name).countDocuments(), 0);
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
          fixtureDb: mongoUrl.pathname.slice(1),
          fixtureRedisDb: 15,
          origin: origin?.href ?? "",
          runId,
          selectedCases: [...selected],
          observed,
          outcome: completed && cleaned ? "passed" : "failed",
          completed,
          cleaned,
          failure,
          checks,
          screenshots,
          errors,
          tools: { imagemagickVersion, tesseractVersion },
          caveat:
            "Seeded local Chromium/SwiftShader visual replay only. Progression is covered separately by the API journey test. Audio track selection is observable; sound quality and physical Windows/Android performance are not measured.",
        },
        null,
        2,
      ),
    );
  }
}
