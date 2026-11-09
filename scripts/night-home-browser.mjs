// Local integration: node --import tsx scripts/night-home-browser.mjs
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
import { isLandWalkable } from "../packages/shared/src/land.ts";
import { physicalRoute } from "./plan06-physical-route.mjs";
import { gameplayFailureDetails } from "./gameplay-api-failure.mjs";
import { keyboardPulse, corridorTargets } from "./land-view-navigation.mjs";

const homeOnly = process.env.NIGHT_HOME_ONLY === "1";
const serviceOnly = process.env.NIGHT_SERVICE_ONLY === "1";
assert(!process.env.NIGHT_SERVICE_ONLY || serviceOnly);
assert(
  !(homeOnly && serviceOnly),
  "Home and service use separate initial fixtures.",
);
const compactRequested =
  serviceOnly || process.env.VERIFY_COMPACT_NIGHT === "1";
assert(
  !process.env.NIGHT_HOME_ONLY || homeOnly,
  "NIGHT_HOME_ONLY accepts only 1 when set.",
);
const origin = process.env.APP_TEST_ORIGIN ?? "http://localhost:3101";
const mongoUrl =
  process.env.MONGO_URL ?? "mongodb://127.0.0.1:27018/jalasmara?replicaSet=rs0";
const redisUrl = process.env.REDIS_URL ?? "redis://127.0.0.1:6380";
assert(
  !process.env.BROWSER_FIXTURE,
  "This test creates its own local player; existing fixtures are not accepted.",
);
assert(["localhost", "127.0.0.1"].includes(new URL(origin).hostname));
assert(/^mongodb:\/\/(127\.0\.0\.1|localhost)(:|\/)/.test(mongoUrl));
assert(["localhost", "127.0.0.1"].includes(new URL(redisUrl).hostname));
const id = randomUUID(),
  email = `night-home-${id}@test.invalid`,
  password = randomBytes(24).toString("base64url");
const expectedPck = process.env.PLAN06_EXPECT_PCK;
const expectedPckBytes = Number(process.env.PLAN06_EXPECT_PCK_BYTES);
assert(
  /^[a-f0-9]{64}$/.test(expectedPck ?? ""),
  "PLAN06_EXPECT_PCK must pin the candidate SHA-256.",
);
assert(
  Number.isSafeInteger(expectedPckBytes) && expectedPckBytes > 0,
  "PLAN06_EXPECT_PCK_BYTES must pin its exact size.",
);
const artifacts = `artifacts/browser/night-home-${id}`;
mkdirSync(artifacts, { recursive: true });
const mongo = new MongoClient(mongoUrl);
const checks = [],
  operations = [],
  errors = [],
  failures = [],
  observations = [],
  trace = [];
const requestTrace = new WeakMap();
const tracePaths = new Set([
  "/api/adventure/surface-position",
  "/api/adventure/state",
  "/api/game/state",
  "/api/homestead/state",
  "/api/homestead/action",
  "/api/homestead/position",
  "/api/kedai/start",
  "/api/kedai/serve",
  "/api/kedai/close-shift",
  "/api/calendar/heartbeat",
]);
let currentPhase = "setup";
let completed = false,
  failureStage = null;
let browser,
  context,
  page,
  frame,
  world,
  recipes,
  multiplier,
  candidatePck,
  routeStarted,
  fixtureAttempted = false,
  cleaned = false;
const navigation = { matrixPulses: 0, legacyPulses: 0 };
function budget() {
  assert(
    !routeStarted || Date.now() - routeStarted < 8 * 60 * 1000,
    "Night route exceeded its bounded eight-minute budget.",
  );
}
const snapshot = () => frame.evaluate(() => window.jalasmaraSnapshot);
async function waitState(predicate, timeout = 25000) {
  const start = Date.now();
  while (Date.now() - start < timeout) {
    budget();
    const state = await snapshot();
    if (predicate(state)) return state;
    await page.waitForTimeout(220);
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
  console.log(
    JSON.stringify({
      phase: "attached",
      area: (await snapshot()).area ?? (await snapshot()).land?.area,
    }),
  );
}
async function state() {
  const response = await context.request.get(`${origin}/api/homestead/state`);
  assert(response.ok(), `Read state: ${response.status()}`);
  return response.json();
}
async function walkTo(x, y) {
  const from = await snapshot();
  const onLand = !from.diving && from.area !== "home" && from.land?.active;
  const targets = onLand ? corridorTargets([from.x, from.y], [x, y]) : [[x, y]];
  for (const [targetX, targetY] of targets) await walkDirect(targetX, targetY);
}
async function walkDirect(x, y) {
  await frame.locator("canvas").focus();
  let previous,
    stuck = 0;
  for (let i = 0; i < 450; i++) {
    budget();
    const s = await snapshot(),
      dx = x - s.x,
      dy = y - s.y,
      distance = Math.hypot(dx, dy);
    assert(!s.modal && !s.homePanel, "Close panels before walking.");
    const arrival = s.land?.active && s.area !== "home" && !s.diving ? 5 : 15;
    if (distance < arrival) return;
    stuck =
      previous && Math.hypot(s.x - previous.x, s.y - previous.y) < 0.5
        ? stuck + 1
        : 0;
    previous = s;
    assert(stuck < 20, `Blocked route to ${x},${y} from ${s.x},${s.y}`);
    let keys, holdMs, releaseMs;
    if (s.land?.active && s.area !== "home" && !s.diving) {
      assert(
        s.land.view?.motion,
        "Night land navigation requires the actual renderer motion contract.",
      );
      ({ keys, holdMs, releaseMs } = keyboardPulse(
        [dx, dy],
        s.land.view.motion,
        { speed: 100 * (s.traversal?.paceScale ?? 1), acceleration: 850 },
      ));
      navigation.matrixPulses++;
    } else {
      keys = [];
      const threshold = stuck >= 2 ? 3 : 8;
      if (Math.abs(dx) > threshold) keys.push(dx > 0 ? "d" : "a");
      if (Math.abs(dy) > threshold) keys.push(dy > 0 ? "s" : "w");
      holdMs = distance < 90 ? 110 : 160;
      releaseMs = 230;
      navigation.legacyPulses++;
    }
    for (const key of keys) await page.keyboard.down(key);
    try {
      await page.waitForTimeout(holdMs);
    } finally {
      for (const key of keys) await page.keyboard.up(key);
    }
    await page.waitForTimeout(releaseMs);
  }
  throw Error(`Route exceeded bounded attempts: ${x},${y}`);
}
async function routeTo(point, inside = false) {
  for (const [x, y] of physicalRoute(
    world,
    await snapshot(),
    point,
    inside ? "home" : "hub",
  ))
    await walkTo(x, y);
  await page.waitForTimeout(450);
}
async function requestViaKeys(path, predicate, keys) {
  const response = page.waitForResponse(
    (r) =>
      r.url().endsWith(`/api/${path}`) &&
      r.request().method() === "POST" &&
      predicate(r.request().postDataJSON()),
    { timeout: 15000 },
  );
  for (const key of keys) {
    await page.keyboard.press(key);
    await page.waitForTimeout(260);
  }
  const result = await response,
    data = await result.json();
  assert(result.ok(), `${path}: ${result.status()} ${JSON.stringify(data)}`);
  operations.push({
    path,
    action: result.request().postDataJSON().action ?? path,
    earned: data.earned,
    gardenBonus: data.gardenBonus,
  });
  await page.waitForTimeout(600);
  return data;
}
async function firstButton() {
  await page.keyboard.press("Enter");
  await page.waitForTimeout(500);
}
async function shot(name) {
  currentPhase = name;
  await page.screenshot({ path: `${artifacts}/${name}.png` });
  const value = await snapshot();
  observations.push({
    name,
    x: value.x,
    y: value.y,
    area: value.area ?? value.land?.area,
    land: value.land,
    renderer: value.renderer,
    weather: value.weather,
    hud: value.hud,
    dialogue: value.dialogue,
  });
  console.log(JSON.stringify({ phase: name }));
}

async function compactNight(label, expectedModal) {
  if (!compactRequested) return;
  const cdp = await context.newCDPSession(page);
  for (const [width, height] of [
    [667, 375],
    [390, 844],
  ]) {
    await page.setViewportSize({ width, height });
    await page.evaluate(() => {
      const probe = document.querySelector(".play-safe-area");
      if (!probe) throw Error("Missing real host safe-area probe");
      Object.assign(probe.style, {
        paddingLeft: "24px",
        paddingRight: "16px",
        paddingTop: "12px",
        paddingBottom: "18px",
      });
      window.dispatchEvent(new Event("resize"));
    });
    await page.waitForTimeout(1400);
    let current = await snapshot();
    assert.equal(current.modal, expectedModal);
    assert.equal(current.homePanel, false);
    assert.equal(
      current.weather.night,
      true,
      "Compact capture must show actual night gameplay",
    );
    assert.equal(current.hud.touch, true);
    const logical = current.hud.logicalSize;
    assert(Math.abs(logical[0] / logical[1] - width / height) < 0.015);
    if (!expectedModal) {
      for (const control of ["bag", "journal", "map", "character", "sound"]) {
        const center = current.hud[control];
        const physical = [
          (center[0] * width) / logical[0],
          (center[1] * height) / logical[1],
        ];
        assert(
          physical[0] >= 24 && physical[0] <= width - 16,
          `${control} must respect emulated horizontal safe insets`,
        );
        assert(
          physical[1] >= 12 && physical[1] <= height - 18,
          `${control} must stay within the visible safe viewport`,
        );
      }
    }
    await shot(`${label}-${width}x${height}`);
    if (!expectedModal) {
      const canvas = await frame.locator("canvas").boundingBox();
      const center = current.hud.bag;
      const point = {
        id: 1,
        x: canvas.x + (center[0] * canvas.width) / logical[0],
        y: canvas.y + (center[1] * canvas.height) / logical[1],
        radiusX: 4,
        radiusY: 4,
        force: 1,
      };
      await cdp.send("Input.dispatchTouchEvent", {
        type: "touchStart",
        touchPoints: [point],
      });
      await page.waitForTimeout(120);
      await cdp.send("Input.dispatchTouchEvent", {
        type: "touchEnd",
        touchPoints: [],
      });
      await waitState((value) => value.modal && value.weather.clockPaused);
      await shot(`bag-night-${width}x${height}`);
      current = await snapshot();
      assert.equal(
        current.hud.oxygen.visible,
        false,
        "Non-diving bag must not show the O2 instrument",
      );
      assert(
        Math.hypot(...current.hud.joystick.direction) < 0.001,
        "Opening a real bag must release movement input",
      );
      await page.keyboard.press("Escape");
      await waitState((value) => !value.modal && !value.homePanel);
    }
    checks.push(
      `actual-night-${label}-${width}x${height}-safe-insets-and-${expectedModal ? "dialogue" : "bag-pause-release"}`,
    );
  }
  await page.evaluate(() => {
    document.querySelector(".play-safe-area").removeAttribute("style");
    window.dispatchEvent(new Event("resize"));
  });
  await page.setViewportSize({ width: 1440, height: 900 });
  await page.waitForTimeout(1200);
  await frame.locator("canvas").focus();
  await cdp.detach();
}

try {
  const release = await fetch(`${origin}/game/index.pck`, {
    redirect: "error",
    signal: AbortSignal.timeout(180000),
  });
  assert(
    release.ok,
    "Pinned game package must be served before creating a fixture.",
  );
  const digest = createHash("sha256");
  let downloaded = 0;
  for await (const chunk of release.body) {
    digest.update(chunk);
    downloaded += chunk.length;
    assert(downloaded <= expectedPckBytes, "PCK exceeds pinned size.");
  }
  assert.equal(downloaded, expectedPckBytes);
  assert.equal(digest.digest("hex"), expectedPck);
  candidatePck = { sha256: expectedPck, decodedBytes: expectedPckBytes };
  await mongo.connect();
  const content = await mongo
    .db()
    .collection("contents")
    .findOne({ state: "published" });
  assert(content?.catalog, "Published local content required.");
  recipes = content.catalog.recipes.filter((r) => r.day === 1);
  assert(recipes.length > 0);
  // Consumed rows disappear, so the first remaining inventory button matches the next customer.
  assert.equal(
    new Set(recipes.map((r) => r.fragmentId)).size,
    recipes.length,
    "Fixture requires distinct day-one fragments to keep keyboard selection unambiguous.",
  );
  multiplier = content.catalog.balance.starMultipliers[2];
  const now = new Date().toISOString(),
    home = freshHomestead();
  home.pantry.kangkung = homeOnly ? 0 : 1;
  if (homeOnly) {
    home.pendingStoryAdvance = { storyDay: 1, shiftId: randomUUID() };
    home.revision++;
  }
  fixtureAttempted = true;
  await mongo
    .db()
    .collection("players")
    .insertOne({
      id,
      email,
      name: "Nala Uji Malam",
      role: "player",
      status: "active",
      appearance: "male_default",
      coins: homeOnly
        ? 105 +
          recipes.reduce((sum, r) => sum + Math.round(r.reward * multiplier), 0)
        : 100,
      inventory: homeOnly
        ? []
        : recipes.map((r) => ({
            fragmentId: r.fragmentId,
            stars: 3,
            quantity: 1,
          })),
      abilities: freshAbilities(),
      progress: {
        ...freshProgress(),
        day: 1,
        stage: "night",
        tutorial: true,
        missions: homeOnly
          ? recipes.map((recipe) => recipe.id)
          : freshProgress().missions,
      },
      adventure: { discoveries: [], puzzles: [], keyItems: [] },
      calendar: { ...freshCalendar(), minuteOfDay: 1140 },
      homestead: home,
      version: homeOnly ? 4 : 0,
      authVersion: 0,
      passwordHash: await argon2.hash(password, { type: argon2.argon2id }),
      createdAt: now,
      updatedAt: now,
    });
  if (homeOnly || serviceOnly) {
    const initialPoint = serviceOnly
      ? WORLD.surface_hub.districts.find((entry) => entry.npc === "Mbah Wira")
      : WORLD.homestead.door;
    assert(initialPoint && isLandWalkable(WORLD.landMaps.hub, initialPoint));
    const cache = new Redis(redisUrl);
    try {
      await cache.set(
        `surface:${id}`,
        JSON.stringify({
          area: "hub",
          x: initialPoint.x,
          y: initialPoint.y,
          layoutVersion: WORLD.hub.layoutVersion,
          playerVersion: homeOnly ? 4 : 0,
          positionAt: Date.now(),
        }),
        "EX",
        1800,
      );
    } finally {
      await cache.quit();
    }
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
    viewport: serviceOnly
      ? { width: 667, height: 375 }
      : { width: 1440, height: 900 },
    hasTouch: compactRequested,
    isMobile: compactRequested,
    deviceScaleFactor: 1,
  });
  page = await context.newPage();
  page.setDefaultTimeout(60000);
  page.on("pageerror", (error) => errors.push(error.message));
  page.on("console", (message) => {
    if (message.type() === "error") errors.push(message.text());
  });
  page.on("request", (request) => {
    const url = new URL(request.url());
    if (url.origin !== origin || !tracePaths.has(url.pathname)) return;
    const body =
      request.method() === "POST" ? (request.postDataJSON() ?? {}) : {};
    const entry = {
      sequence: trace.length + 1,
      at: Date.now(),
      phase: currentPhase,
      path: url.pathname,
      method: request.method(),
      sent: {
        action: body.action,
        version: body.version,
        fromPositionAt: body.fromPositionAt,
        expectedRevision: body.expectedRevision,
        x: body.x,
        y: body.y,
        pathPoints: body.path?.length,
        positionPath: gameplayFailureDetails(url.pathname, body).positionPath,
        paused: body.paused,
      },
    };
    trace.push(entry);
    requestTrace.set(request, entry);
  });
  page.on("response", async (response) => {
    const entry = requestTrace.get(response.request());
    const path = new URL(response.url()).pathname;
    if (!entry) return;
    const body = await response.json().catch(() => ({}));
    Object.assign(entry, {
      respondedAt: Date.now(),
      status: response.status(),
      code: body.code,
      error: typeof body.error === "string" ? body.error : undefined,
      playerVersion: body.player?.version,
      surface: body.surface,
      home: body.homestead
        ? {
            inside: body.homestead.inside,
            revision: body.homestead.revision,
            pendingStoryDay: body.homestead.pendingStoryAdvance?.storyDay,
          }
        : undefined,
    });
    if (response.status() >= 400) {
      const failure = {
        sequence: entry.sequence,
        path,
        status: response.status(),
        code: body.code,
        error: entry.error,
        sent: entry.sent,
        at: entry.at,
        respondedAt: entry.respondedAt,
        phase: entry.phase,
      };
      failures.push(failure);
      console.log(JSON.stringify({ phase: "api-failure", ...failure }));
    }
  });
  page.on("requestfailed", (request) => {
    const entry = requestTrace.get(request);
    if (entry)
      Object.assign(entry, {
        failedAt: Date.now(),
        failure: request.failure()?.errorText,
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
  await waitState((s) => s.stage === "night" && !s.modal && !s.homePanel);
  if (!homeOnly) {
    const wira = world.surface_hub.districts.find((d) => d.npc === "Mbah Wira");
    assert(wira);
    await routeTo(wira);
    const shift = await requestViaKeys("kedai/start", () => true, ["e"]);
    assert.deepEqual(
      shift.shift.customers.map((r) => r.id),
      recipes.map((r) => r.id),
    );
    await waitState((s) => s.modal);
    if (serviceOnly) {
      await page.waitForTimeout(1200);
      await shot("00-service-667-pinned-context-before-touch-scroll");
      const clip = { x: 280, y: 245, width: 300, height: 75 };
      const before = createHash("sha256")
        .update(await page.screenshot({ clip }))
        .digest("hex");
      const cdp = await context.newCDPSession(page);
      await cdp.send("Input.dispatchTouchEvent", {
        type: "touchStart",
        touchPoints: [{ x: 500, y: 330 }],
      });
      for (let step = 1; step <= 8; step++) {
        await cdp.send("Input.dispatchTouchEvent", {
          type: "touchMove",
          touchPoints: [{ x: 500, y: 330 - step * 12 }],
        });
        await page.waitForTimeout(50);
      }
      await cdp.send("Input.dispatchTouchEvent", {
        type: "touchEnd",
        touchPoints: [],
      });
      await page.waitForTimeout(350);
      const after = createHash("sha256")
        .update(await page.screenshot({ clip }))
        .digest("hex");
      assert.notEqual(
        after,
        before,
        "Actual touch drag must change the opaque options region, not just water behind the modal.",
      );
      assert(
        (await snapshot()).modal && (await snapshot()).weather.clockPaused,
      );
      await shot("00-service-667-options-after-real-touch-scroll");
      checks.push(
        "667-service-options-region-changes-after-real-touch-drag-with-world-paused",
      );
    }
    for (let i = 0; i < recipes.length; i++) {
      const keys = i === 0 ? ["Space", "Tab", "Enter"] : ["Enter"];
      const result = await requestViaKeys(
        "kedai/serve",
        (body) => body.recipeId === recipes[i].id,
        keys,
      );
      assert.equal(result.gardenBonus, i === 0 ? 5 : 0);
      assert.equal(
        result.earned,
        Math.round(recipes[i].reward * multiplier) + (i === 0 ? 5 : 0),
      );
      assert.equal(result.homestead.pantry.kangkung, 0);
      assert(
        !result.player.inventory.some(
          (item) => item.fragmentId === recipes[i].fragmentId,
        ),
      );
      if (i === 0) await shot("01-garden-ingredient-served");
      await firstButton();
    }
    checks.push(
      "garden-checkbutton-consumes-one-kangkung-and-real-fragment-for-five-bonus",
    );
    const closed = await requestViaKeys(
      "kedai/close-shift",
      (body) => body.abandon === false,
      ["Enter"],
    );
    assert.equal(closed.player.progress.day, 1);
    assert.equal(closed.homestead.pendingStoryAdvance.storyDay, 1);
    assert.equal(
      closed.player.coins,
      105 +
        recipes.reduce((sum, r) => sum + Math.round(r.reward * multiplier), 0),
    );
    await shot("02-shift-closed-pending-sleep");
    await compactNight("02-night-result-dialogue", true);
    const conversation = (await snapshot()).dialogue;
    assert(
      conversation,
      "Shift completion must use the shared dialogue presenter",
    );
    await page.keyboard.press("Enter");
    if (conversation.visibleCharacters >= 0) {
      await waitState((s) => s.modal && s.dialogue?.visibleCharacters === -1);
      await page.keyboard.press("Enter");
      checks.push("dialogue-first-enter-reveals-second-enter-continues");
    }
    await waitState((s) => !s.modal && !s.homePanel);
    checks.push(
      "all-day-one-customers-served-close-keeps-story-day-until-sleep",
    );
    await compactNight("02-night-clear-gameplay", false);
  } else {
    assert.deepEqual(world.homestead.door, WORLD.homestead.door);
    checks.push("focused-home-fixture-starts-after-closed-shift-at-real-door");
  }
  if (!serviceOnly) {
    await routeTo(world.homestead.door);
    await waitState((s) => s.nearby === "home_enter");
    await page.keyboard.press("e");
    await waitState((s) => s.homePanel);
    await requestViaKeys("homestead/action", (b) => b.action === "enter", [
      "Enter",
    ]);
    await waitState(
      (s) => s.area === "home" && s.homestead?.inside && s.renderer?.active,
    );
    await frame.locator("canvas").focus();
    await routeTo({ x: 270, y: 330 }, true);
    await waitState((s) => s.nearby === "bed");
    await page.keyboard.press("e");
    await waitState((s) => s.homePanel);
    const slept = await requestViaKeys(
      "homestead/action",
      (b) => b.action === "sleep",
      ["Enter"],
    );
    assert.equal(slept.player.progress.day, 2);
    assert.equal(slept.player.progress.stage, "dive");
    assert.equal(slept.calendar.calendarDay, 2);
    assert.equal(slept.calendar.minuteOfDay, 360);
    assert(!slept.homestead.pendingStoryAdvance);
    await shot("03-sleep-advances-morning");
    await page.keyboard.press("Enter");
    await waitState((s) => !s.modal && !s.homePanel);
    await routeTo(world.homestead.interior.entry, true);
    await waitState((s) => s.nearby === "exit");
    const exited = await requestViaKeys(
      "homestead/action",
      (b) => b.action === "exit",
      ["e"],
    );
    await waitState((s) => s.area !== "home" && !s.homestead?.inside);
    await waitState((s) => s.land?.active && s.land.view?.motion);
    await page.waitForTimeout(3500);
    let postExitPosition;
    if (homeOnly) {
      const from = await snapshot(),
        afterSequence = trace.length;
      await routeTo({
        x: world.homestead.door.x + 45,
        y: world.homestead.door.y,
      });
      postExitPosition = await snapshot();
      assert(
        Math.hypot(postExitPosition.x - from.x, postExitPosition.y - from.y) >
          20,
      );
      const deadline = Date.now() + 15000;
      let acknowledgement;
      while (!acknowledgement && Date.now() < deadline) {
        acknowledgement = trace
          .slice(afterSequence)
          .find(
            (entry) =>
              entry.path === "/api/adventure/surface-position" &&
              entry.status === 200 &&
              entry.sent.version === exited.player.version &&
              entry.surface?.playerVersion === exited.player.version &&
              Math.hypot(
                entry.surface.x - postExitPosition.x,
                entry.surface.y - postExitPosition.y,
              ) < 15,
          );
        if (!acknowledgement) await page.waitForTimeout(150);
      }
      assert(
        acknowledgement,
        "A real move after home exit must ACK the returned player version.",
      );
      checks.push("post-home-exit-walk-acknowledges-exit-player-version");
      await shot("03-post-exit-walk-acknowledged");
    }
    await page.reload();
    await attach();
    await waitState((s) => s.stage === "dive" && !s.homestead?.inside);
    if (postExitPosition) {
      const reloaded = await snapshot();
      assert(
        Math.hypot(
          reloaded.x - postExitPosition.x,
          reloaded.y - postExitPosition.y,
        ) < 15,
      );
      checks.push("post-home-exit-walk-persists-after-reload");
    }
    const persisted = await state();
    assert.equal(persisted.player.progress.day, 2);
    assert.equal(persisted.calendar.calendarDay, 2);
    assert(
      persisted.calendar.minuteOfDay >= 360 &&
        persisted.calendar.minuteOfDay < 390,
    );
    assert.equal(persisted.homestead.pantry.kangkung, 0);
    assert(!persisted.homestead.pendingStoryAdvance);
    assert.equal(persisted.homestead.inside, false);
    assert(
      recipes.every((r) => persisted.player.progress.missions.includes(r.id)),
    );
    checks.push(
      "home-bed-sleep-advances-story-and-calendar-once-exit-reload-persists",
    );
    await shot("04-reloaded-morning");
  } else {
    const persisted = await state();
    assert.equal(persisted.player.progress.day, 1);
    assert.equal(persisted.homestead.pendingStoryAdvance.storyDay, 1);
    assert.equal(persisted.homestead.pantry.kangkung, 0);
    assert(
      recipes.every((recipe) =>
        persisted.player.progress.missions.includes(recipe.id),
      ),
    );
    checks.push(
      "focused-service-receipts-persist-with-story-advance-still-pending-sleep",
    );
  }
  assert.deepEqual(failures, []);
  assert.deepEqual(errors, []);
  completed = true;
  console.log(
    JSON.stringify(
      { checks, operations: operations.length, browserErrors: errors.length },
      null,
      2,
    ),
  );
} catch (error) {
  failureStage = currentPhase;
  if (page) await shot("failure").catch(() => {});
  throw error;
} finally {
  const cookies = context ? await context.cookies().catch(() => []) : [];
  if (browser) await browser.close();
  const cache = fixtureAttempted ? new Redis(redisUrl) : null;
  try {
    if (fixtureAttempted) {
      const players = mongo.db().collection("players");
      await players.deleteOne({
        id,
        email,
        role: "player",
        name: "Nala Uji Malam",
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
      for (const cookie of cookies.filter((value) =>
        ["jalasmara", "__Host-jalasmara"].includes(value.name),
      )) {
        const key = `auth:${createHash("sha256").update(cookie.value).digest("hex")}`;
        const raw = await cache.get(key);
        if (raw) {
          assert.equal(JSON.parse(raw).userId, id);
          keys.push(key);
        }
      }
      await cache.del(...keys);
      assert.equal(
        await players.countDocuments({ id, email, role: "player" }),
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
      `${artifacts}/results.json`,
      JSON.stringify(
        {
          origin,
          id,
          outcome: completed && cleaned ? "passed" : "failed",
          completed,
          failureStage,
          candidatePck,
          checks,
          operations,
          errors,
          failures,
          navigation,
          observations,
          trace,
          homeOnly,
          serviceOnly,
          ownTemporaryPlayerRemoved: cleaned,
          routeElapsedMs: routeStarted ? Date.now() - routeStarted : null,
        },
        null,
        2,
      ),
    );
    console.log(
      JSON.stringify({
        artifacts,
        checks,
        errors,
        failures,
        ownTemporaryPlayerRemoved: cleaned,
      }),
    );
  }
}
