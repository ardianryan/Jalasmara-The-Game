// Local layout-9 acceptance with the actual game and physically traversed paths.
// PCK SHA/byte pins are required before the temporary player is created.
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
import { isLandWalkable } from "../packages/shared/src/land.ts";
import { fetchWorld } from "./game-navigation.mjs";
import { physicalRoute } from "./plan06-physical-route.mjs";
import {
  keyboardPulse,
  corridorTargets,
  projectLogicalDelta,
} from "./land-view-navigation.mjs";

const origin = process.env.APP_TEST_ORIGIN ?? "http://localhost:3101";
const mongoUrl =
  process.env.MONGO_URL ?? "mongodb://127.0.0.1:27018/jalasmara?replicaSet=rs0";
const redisUrl = process.env.REDIS_URL ?? "redis://127.0.0.1:6380";
assert(
  !process.env.BROWSER_FIXTURE,
  "Existing players and owner fixtures are not accepted.",
);
assert(["localhost", "127.0.0.1"].includes(new URL(origin).hostname));
assert(/^mongodb:\/\/(127\.0\.0\.1|localhost)(:|\/)/.test(mongoUrl));
assert(["localhost", "127.0.0.1"].includes(new URL(redisUrl).hostname));
const routeMode = process.env.PLAN06_ROUTE_MODE ?? "full";
assert(
  [
    "full",
    "continuation",
    "ocean",
    "dialogue",
    "left",
    "shelters",
    "lower",
  ].includes(routeMode),
);
const routeLimitMs =
  (["left", "lower"].includes(routeMode) ? 5 : 10) * 60 * 1000;
const navigation = { matrixPulses: 0, legacyPulses: 0 };
const inputProofs = [];
const fixtureStoryDay = routeMode === "dialogue" ? 1 : 2;
const expectedPck = process.env.PLAN06_EXPECT_PCK;
const expectedPckBytes = Number(process.env.PLAN06_EXPECT_PCK_BYTES);
assert(
  /^[a-f0-9]{64}$/.test(expectedPck ?? ""),
  "Set PLAN06_EXPECT_PCK to the exported candidate SHA-256.",
);
assert(
  Number.isSafeInteger(expectedPckBytes) && expectedPckBytes > 0,
  "Set PLAN06_EXPECT_PCK_BYTES to the exact exported PCK size.",
);
assert.equal(WORLD.hub.layoutVersion, 9, "Harness source targets layout 9.");
let id;
do {
  id = randomUUID();
} while (!calendarRain(id, 2));
const directory = `artifacts/browser/plan06-layout-${id}`;
mkdirSync(directory, { recursive: true });
const email = `plan06-layout-${id}@test.invalid`,
  password = randomBytes(24).toString("base64url");
const mongo = new MongoClient(mongoUrl);
const checks = [],
  observations = [],
  operations = [],
  errors = [],
  failures = [];
let browser,
  context,
  page,
  frame,
  world,
  cdp,
  cleaned = false,
  lastSnapshot;
let candidatePck,
  initialLegacy,
  initialContinuation,
  initialHub,
  initialLower,
  routeStarted,
  fixtureAttempted = false;
function budget() {
  assert(
    !routeStarted || Date.now() - routeStarted < routeLimitMs,
    `Bounded ${routeMode} route exceeded ${routeLimitMs / 60000} minutes; preserve partial evidence and clean the fixture.`,
  );
}
const snapshot = () => frame.evaluate(() => window.jalasmaraSnapshot);
async function waitState(predicate, timeout = 30000) {
  const start = Date.now();
  while (Date.now() - start < timeout) {
    budget();
    const value = await snapshot();
    if (value && predicate(value)) return value;
    await page.waitForTimeout(180);
  }
  throw Error(`State wait expired: ${JSON.stringify(await snapshot())}`);
}
async function attach() {
  await page.locator("iframe").waitFor();
  frame = await (await page.locator("iframe").elementHandle()).contentFrame();
  await frame.waitForFunction(
    () =>
      window.jalasmaraReady &&
      (window.jalasmaraSnapshot?.hud ||
        (window.jalasmaraSnapshot?.area === "home" &&
          window.jalasmaraSnapshot?.renderer?.active)),
    null,
    { polling: 200, timeout: 240000 },
  );
  await page.locator(".game-loading").waitFor({ state: "detached" });
  await frame.locator("canvas").focus();
  const value = await snapshot();
  console.log(
    JSON.stringify({
      phase: "game-attached",
      area: value.area ?? value.land?.area,
      inside: value.homestead?.inside ?? false,
    }),
  );
}
async function shot(name) {
  await page.screenshot({ path: `${directory}/${name}.png` });
  const value = await snapshot();
  observations.push({
    name,
    at: new Date().toISOString(),
    x: value.x,
    y: value.y,
    area: value.area ?? value.land?.area,
    land: value.land,
    renderer: value.renderer,
    dialogue: value.dialogue,
    weather: value.weather,
    hud: value.hud,
  });
  console.log(
    JSON.stringify({
      phase: name,
      area: value.area ?? value.land?.area,
      x: value.x,
      y: value.y,
    }),
  );
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
  for (let tick = 0; tick < 450; tick++) {
    budget();
    const value = await snapshot(),
      dx = x - value.x,
      dy = y - value.y,
      distance = Math.hypot(dx, dy);
    assert(
      !value.modal && !value.homePanel,
      "A modal cannot be bypassed while navigating.",
    );
    const arrival =
      !value.diving && value.area !== "home" && value.land?.active ? 5 : 15;
    if (distance < arrival) return value;
    stuck =
      previous && Math.hypot(value.x - previous.x, value.y - previous.y) < 0.5
        ? stuck + 1
        : 0;
    assert(
      stuck < 20,
      `Physical collision blocks ${x},${y}; actual ${value.x},${value.y}`,
    );
    previous = value;
    const contract =
      !value.diving && value.area !== "home" && value.land?.active
        ? value.land.view?.motion
        : null;
    if (routeMode === "left")
      assert(
        contract,
        "Left-view navigation requires the actual renderer motion contract.",
      );
    let keys, holdMs, releaseMs;
    if (contract) {
      const pulse = keyboardPulse([dx, dy], contract, {
        speed: 100 * (value.traversal?.paceScale ?? 1),
        acceleration: value.area === "forest" ? 1250 : 850,
      });
      ({ keys, holdMs, releaseMs } = pulse);
      navigation.matrixPulses++;
    } else {
      const threshold = stuck > 2 ? 3 : 8;
      keys = [];
      if (Math.abs(dx) > threshold) keys.push(dx > 0 ? "d" : "a");
      if (Math.abs(dy) > threshold) keys.push(dy > 0 ? "s" : "w");
      holdMs = distance > 150 ? 330 : distance > 50 ? 200 : 90;
      releaseMs = 90;
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
  throw Error(
    `Bounded navigation timed out at ${JSON.stringify(await snapshot())}`,
  );
}
async function routeTo(point, area) {
  for (const [x, y] of physicalRoute(world, await snapshot(), point, area))
    await walkTo(x, y);
}
async function apiState() {
  const response = await context.request.get(`${origin}/api/adventure/state`);
  assert(response.ok());
  return response.json();
}
async function waitSaved(at) {
  const deadline = Date.now() + 15000;
  while (Date.now() < deadline) {
    const state = await apiState();
    if (
      state.surface?.area === (at.area ?? at.land?.area ?? "hub") &&
      Math.hypot(state.surface.x - at.x, state.surface.y - at.y) < 25
    )
      return state;
    await page.waitForTimeout(400);
  }
  throw Error("The physically reached position was not saved by the game.");
}
async function touchPoint(center, pointer = 1) {
  const value = await snapshot(),
    box = await frame.locator("canvas").boundingBox();
  return {
    x: box.x + (center[0] * box.width) / value.hud.logicalSize[0],
    y: box.y + (center[1] * box.height) / value.hud.logicalSize[1],
    id: pointer,
    radiusX: 4,
    radiusY: 4,
    force: 1,
  };
}
async function tap(name) {
  const point = await touchPoint((await snapshot()).hud[name]);
  await cdp.send("Input.dispatchTouchEvent", {
    type: "touchStart",
    touchPoints: [point],
  });
  await page.waitForTimeout(90);
  await cdp.send("Input.dispatchTouchEvent", {
    type: "touchEnd",
    touchPoints: [],
  });
}
async function responsive(width, height, label) {
  await page.setViewportSize({ width, height });
  await page.evaluate(() => {
    const probe = document.querySelector(".play-safe-area");
    if (!probe) throw Error("The real host safe-area probe is required.");
    Object.assign(probe.style, {
      paddingLeft: "24px",
      paddingRight: "16px",
      paddingTop: "12px",
      paddingBottom: "18px",
    });
    dispatchEvent(new Event("resize"));
  });
  await page.waitForTimeout(1300);
  const value = await snapshot(),
    box = await page.locator("iframe").boundingBox(),
    logical = value.hud.logicalSize;
  assert.equal(value.hud.touch, true);
  assert.equal(
    value.weather.night,
    true,
    "The HUD fixture must still be actual calendar night.",
  );
  assert(Math.abs(box.width - width) < 2 && Math.abs(box.height - height) < 2);
  assert(Math.abs(logical[0] / logical[1] - width / height) < 0.015);
  assert.equal(
    await page.evaluate(
      () => document.documentElement.scrollWidth > innerWidth,
    ),
    false,
  );
  for (const name of ["bag", "journal", "map", "action"]) {
    const point = value.hud[name];
    assert(
      point[0] >= 0 &&
        point[1] >= 0 &&
        point[0] <= logical[0] &&
        point[1] <= logical[1],
    );
    const physical = [
      (point[0] * width) / logical[0],
      (point[1] * height) / logical[1],
    ];
    assert(
      physical[0] >= 24 &&
        physical[0] <= width - 16 &&
        physical[1] >= 12 &&
        physical[1] <= height - 18,
      `${name} respects the emulated safe insets`,
    );
  }
  assert.equal(value.land.actors.player, 1);
  assert.equal(value.land.elevationDegrees, 35);
  assert(value.land.maxFootError < 0.1);
  await shot(label);
}

async function pressAndPost(path, action, key = "Enter") {
  const response = page.waitForResponse(
    (value) =>
      new URL(value.url()).pathname === `/api/${path}` &&
      value.request().method() === "POST" &&
      (!action || value.request().postDataJSON()?.action === action),
    { timeout: 15000 },
  );
  await page.keyboard.press(key);
  const result = await response;
  assert(result.ok(), `${path}: HTTP ${result.status()}`);
  const data = await result.json();
  operations.push({ path: `/api/${path}`, action, status: result.status() });
  return data;
}

async function closeDialogue() {
  for (let index = 0; index < 12; index++) {
    const value = await snapshot();
    if (!value.modal && !value.homePanel) return;
    await page.keyboard.press("Enter");
    await page.waitForTimeout(250);
  }
  assert.fail(
    "Conversation did not close after bounded reveal/continue actions.",
  );
}

async function verifyHome() {
  await routeTo(world.homestead.door, "hub");
  await waitState((value) => value.nearby === "home_enter");
  await responsive(667, 375, "home-porch-night-667x375");
  await page.keyboard.press("e");
  await waitState((value) => value.homePanel);
  await pressAndPost("homestead/action", "enter");
  await waitState(
    (value) =>
      value.area === "home" &&
      value.homestead?.inside &&
      value.renderer?.active,
  );
  await frame.locator("canvas").focus();
  await routeTo({ x: 270, y: 330 }, "home");
  const interior = await snapshot();
  await waitState((asyncValue) => asyncValue.area === "home");
  const deadline = Date.now() + 15000;
  let saved;
  while (Date.now() < deadline) {
    const response = await context.request.get(`${origin}/api/homestead/state`);
    assert(response.ok());
    saved = await response.json();
    if (
      saved.homestead.inside &&
      Math.hypot(
        saved.homestead.position.x - interior.x,
        saved.homestead.position.y - interior.y,
      ) < 25
    )
      break;
    await page.waitForTimeout(350);
  }
  assert(
    saved.homestead.inside &&
      Math.hypot(
        saved.homestead.position.x - interior.x,
        saved.homestead.position.y - interior.y,
      ) < 25,
  );
  await page.reload();
  await attach();
  const resumed = await waitState(
    (value) => value.area === "home" && value.homestead?.inside,
  );
  assert(Math.hypot(resumed.x - interior.x, resumed.y - interior.y) < 30);
  await shot("home-interior-resumes-after-reload");
  await routeTo(world.homestead.interior.entry, "home");
  await waitState((value) => value.nearby === "exit");
  await pressAndPost("homestead/action", "exit", "e");
  await waitState(
    (value) =>
      value.land?.area === "hub" &&
      !value.homestead?.inside &&
      value.land?.actors?.player === 1,
  );
  checks.push(
    "new-griya-porch-remains-accessible-interior-position-saves-reloads-and-exits",
  );
}

async function verifyShelters() {
  const residents = world.surface_hub.residents.map((value) => ({
    ...value,
    nearby: value.name,
  }));
  const darmi = world.surface_hub.districtActivities["Bu Darmi"];
  residents.push({
    ...darmi,
    name: "Bu Darmi",
    nearby: world.surface_hub.districts.find(
      (value) => value.npc === "Bu Darmi",
    ).id,
  });
  assert.equal(residents.length, 7);
  console.log(
    JSON.stringify({
      phase: "waiting-seven-shelters",
      residentStates: (await snapshot()).land?.actors?.residentStates,
    }),
  );
  await waitState(
    (value) =>
      value.weather.rain > 0.42 &&
      value.weather.night &&
      residents.every((resident) => {
        const state = value.land?.actors?.residentStates?.[resident.name];
        return state?.phase === "shelter" && state.atStation && !state.moving;
      }),
    160000,
  );
  checks.push(
    "seven-residents-reach-rain-shelter-stations-on-the-real-night-calendar",
  );
  for (const resident of residents.sort(
    (a, b) =>
      a.activity.shelter[1] - b.activity.shelter[1] ||
      a.activity.shelter[0] - b.activity.shelter[0],
  )) {
    const [x, y] = resident.activity.shelter;
    await routeTo({ x, y }, "hub");
    await waitState((value) => value.nearby === resident.nearby);
    const before = await snapshot();
    assert.equal(
      before.land.actors.residentStates[resident.name].phase,
      "shelter",
    );
    await shot(
      `shelter-${resident.name.replaceAll(" ", "-")}-before-conversation`,
    );
    await page.keyboard.press("e");
    await waitState((value) => value.modal && value.weather.clockPaused);
    await shot(`shelter-${resident.name.replaceAll(" ", "-")}-conversation`);
    await closeDialogue();
    await waitState((value) => !value.modal && !value.weather.clockPaused);
    checks.push(
      `${resident.name}: physical-shelter-access-dialogue-and-resume`,
    );
  }
}

async function verifyRemainingShelters() {
  assertLeftView(await snapshot(), "hub");
  await responsive(667, 375, "left-seven-shelters-start-667x375");
  await verifyShelters();
  const state = await apiState();
  assert.equal(state.player.progress.day, 2);
  assert.equal(state.player.progress.stage, "dive");
  assert.equal(state.player.coins, 200);
  assert.equal(state.player.inventory.length, 0);
  assert.equal(state.calendar.dayLengthMs, 36 * 60 * 1000);
  checks.push(
    "seven-left-view-shelter-conversations-preserve-server-progress-and-rewards",
  );
}
async function verifyLowerBridge() {
  let value = await snapshot();
  assertLeftView(value, "forest");
  const bridge = world.landMaps.forest.bridges.find(
    (entry) => entry.id === "bridge_lower",
  );
  assert.deepEqual(bridge.path[0], [initialLower.x, initialLower.y]);
  await responsive(844, 390, "left-lower-bridge-start-844x390");
  const [x, y] = bridge.path.at(-1);
  await walkTo(x, y);
  value = await snapshot();
  assert(Math.hypot(value.x - initialLower.x, value.y - initialLower.y) > 250);
  const rendered = value.land.bridges[bridge.id];
  assert(
    rendered?.oriented && rendered.railPosts >= 8 && rendered.thickness >= 12,
  );
  await shot("left-lower-bridge-crossed");
  await waitSaved(value);
  await page.reload();
  await attach();
  const resumed = await waitState(
    (state) => state.area === "forest" && state.land?.actors?.player === 1,
  );
  assertLeftView(resumed, "forest");
  assert(Math.hypot(resumed.x - value.x, resumed.y - value.y) < 30);
  const state = await apiState();
  assert.equal(state.player.progress.day, 2);
  assert.equal(state.player.coins, 200);
  assert.equal(state.player.inventory.length, 0);
  assert.equal(state.calendar.dayLengthMs, 36 * 60 * 1000);
  await shot("left-lower-bridge-position-resumes-after-reload");
  checks.push(
    "left-lower-bridge-physical-crossing-and-reload-preserve-server-state",
  );
}

function assertLeftView(value, area) {
  assert.equal(value.land?.area, area);
  assert.equal(value.land.bitmapGround, false);
  assert.equal(value.land.view?.azimuth, -45);
  assert.equal(value.land.view?.elevation, 35);
  assert.equal(value.land.view?.input, "screen-relative");
  assert.equal(value.land.view?.motion?.schemaVersion, 1);
  assert.equal(value.land.actors.player, 1);
  assert(value.land.maxFootError < 0.1);
}
function recordScreenRight(before, after, kind) {
  const logical = [after.x - before.x, after.y - before.y];
  const projected = projectLogicalDelta(logical, before.land.view.motion);
  inputProofs.push({
    kind,
    logical,
    projected,
    area: before.land.area,
    azimuth: before.land.view.azimuth,
  });
  assert(
    projected[0] > 4,
    `${kind} must physically move the player toward screen-right.`,
  );
  assert(
    Math.abs(projected[1]) < Math.max(3, projected[0] * 0.35),
    `${kind} must preserve the intended screen direction.`,
  );
}
async function verifyLeftView() {
  let value = await snapshot();
  assertLeftView(value, "hub");
  await responsive(667, 375, "left-hub-667x375");
  const keyboardBefore = await snapshot();
  await page.keyboard.down("d");
  await page.waitForTimeout(350);
  await page.keyboard.up("d");
  await page.waitForTimeout(250);
  recordScreenRight(keyboardBefore, await snapshot(), "hub-keyboard-right");
  checks.push("left-hub-keyboard-follows-actual-projected-screen-direction");
  await routeTo(world.forest.gate, "hub");
  await waitState((state) => state.nearby === "forest_gate");
  const travel = await pressAndPost("adventure/travel", null, "e");
  assert.equal(travel.surface.area, "forest");
  value = await waitState(
    (state) => state.area === "forest" && state.land?.actors?.player === 1,
  );
  assertLeftView(value, "forest");
  await shot("left-real-forest-entry");
  await routeTo({ x: 650, y: 1050 }, "forest");
  await responsive(844, 390, "left-forest-touch-844x390");
  const prior = await snapshot();
  const stick = prior.hud.joystick;
  const start = await touchPoint(stick.center);
  const moved = await touchPoint([
    stick.center[0] + stick.radius * 0.65,
    stick.center[1],
  ]);
  await cdp.send("Input.dispatchTouchEvent", {
    type: "touchStart",
    touchPoints: [start],
  });
  await cdp.send("Input.dispatchTouchEvent", {
    type: "touchMove",
    touchPoints: [moved],
  });
  await page.waitForTimeout(350);
  assert(Math.hypot(...(await snapshot()).hud.joystick.direction) > 0.1);
  await cdp.send("Input.dispatchTouchEvent", {
    type: "touchEnd",
    touchPoints: [],
  });
  await page.waitForTimeout(300);
  const released = await snapshot();
  assert(Math.hypot(...released.hud.joystick.direction) < 0.01);
  recordScreenRight(prior, released, "forest-joystick-right");
  await shot("left-forest-touch-released");
  checks.push("left-forest-joystick-follows-screen-direction-and-releases");
  const bridge = world.landMaps.forest.bridges.find(
    (entry) => entry.id === "bridge_upper",
  );
  assert(bridge);
  const [a, b] = bridge.path;
  await routeTo({ x: a[0], y: a[1] }, "forest");
  const before = await snapshot();
  await walkTo(b[0], b[1]);
  const after = await snapshot();
  assert(Math.hypot(after.x - before.x, after.y - before.y) > 250);
  assert(
    after.land.bridges[bridge.id]?.oriented &&
      after.land.bridges[bridge.id].railPosts >= 8,
  );
  assertLeftView(after, "forest");
  await shot("left-bridge-upper-crossed");
  await waitSaved(after);
  await page.reload();
  await attach();
  const resumed = await waitState(
    (state) => state.area === "forest" && state.land?.actors?.player === 1,
  );
  assertLeftView(resumed, "forest");
  assert(Math.hypot(resumed.x - after.x, resumed.y - after.y) < 30);
  const state = await apiState();
  assert.equal(state.surface.area, "forest");
  assert.equal(state.player.progress.day, 2);
  assert.equal(state.player.coins, 200);
  assert.equal(state.player.inventory.length, 0);
  assert.equal(state.calendar.dayLengthMs, 36 * 60 * 1000);
  assert(navigation.matrixPulses > 0);
  assert.equal(navigation.legacyPulses, 0);
  await shot("left-forest-position-resumes-after-reload");
  checks.push(
    "left-real-gate-bridge-and-position-reload-preserve-server-state",
  );
}

async function verifyCompactDialogue() {
  const wira = world.surface_hub.districts.find(
    (entry) => entry.npc === "Mbah Wira",
  );
  assert(wira);
  await routeTo(wira, "hub");
  await waitState((value) => value.nearby === wira.id);
  await responsive(667, 375, "compact-dialogue-before-conversation-667x375");
  await page.keyboard.press("e");
  await waitState(
    (value) => value.modal && value.dialogue?.speaker === "Mbah Wira",
  );
  for (const [speaker, tag, cap, minimum, maximum] of [
    ["Mbah Wira", "paragraph", 0.42, 100, 190],
    ["Nala", "short", 0.34, 20, 80],
  ]) {
    let current = await waitState(
      (value) => value.dialogue?.speaker === speaker,
    );
    const before = current.dialogue;
    assert(before.total >= minimum && before.total <= maximum);
    assert(before.compact && before.portrait);
    assert(current.weather.clockPaused);
    const logical = current.hud.logicalSize;
    assert(before.size[1] / logical[1] <= cap + 0.003);
    assert(before.position[0] >= 0 && before.position[1] >= 0);
    assert(before.position[0] + before.size[0] <= logical[0] + 1);
    assert(before.position[1] + before.size[1] <= logical[1] + 1);
    if (before.visibleCharacters >= 0) {
      await page.keyboard.press("Enter");
      current = await waitState(
        (value) =>
          value.dialogue?.speaker === speaker &&
          value.dialogue.visibleCharacters === -1,
      );
      assert.deepEqual(current.dialogue.size, before.size);
    }
    await shot(`actual-dialogue-${tag}-667x375`);
    checks.push(
      `actual-${tag}-dialogue-667x375-leaves-world-visible-and-reveals-without-resize`,
    );
    await page.keyboard.press("Enter");
  }
  await waitState((value) => !value.modal && !value.weather.clockPaused);
  const state = await apiState();
  assert.equal(state.player.progress.day, 1);
  assert.equal(state.player.coins, 200);
  assert.equal(state.player.inventory.length, 0);
  checks.push(
    "actual-dialogue-resumes-world-without-advancing-story-or-rewards",
  );
}

async function verifyOcean() {
  await routeTo(world.hub.divePoint, "hub");
  await waitState((value) => value.nearby === "ladder");
  await pressAndPost("dive/start", null, "e");
  await waitState(
    (value) =>
      value.diving && value.hud?.oxygen?.visible && value.hybrid?.active,
  );
  await page.setViewportSize({ width: 390, height: 844 });
  await page.waitForTimeout(1400);
  let value = await snapshot();
  assert(value.weather.night && value.hud.touch && value.hud.oxygen.value > 0);
  const stick = value.hud.joystick;
  const start = await touchPoint(stick.center);
  const moved = await touchPoint([
    stick.center[0] + stick.radius * 0.65,
    stick.center[1] + stick.radius * 0.3,
  ]);
  await cdp.send("Input.dispatchTouchEvent", {
    type: "touchStart",
    touchPoints: [start],
  });
  await cdp.send("Input.dispatchTouchEvent", {
    type: "touchMove",
    touchPoints: [moved],
  });
  await page.waitForTimeout(350);
  assert(Math.hypot(...(await snapshot()).hud.joystick.direction) > 0.1);
  await cdp.send("Input.dispatchTouchEvent", {
    type: "touchCancel",
    touchPoints: [],
  });
  await page.waitForTimeout(500);
  const stopped = await snapshot();
  assert(Math.hypot(...stopped.hud.joystick.direction) < 0.01);
  assert(Math.hypot(stopped.x - value.x, stopped.y - value.y) > 2);
  await shot("ocean-night-portrait-joystick-cancelled");
  await tap("bag");
  await waitState((state) => state.modal && state.weather.clockPaused);
  await shot("ocean-night-portrait-bag-pauses-and-cancels-input");
  await page.keyboard.press("Escape");
  await waitState((state) => !state.modal && !state.weather.clockPaused);
  await walkTo(world.spawn.x, world.spawn.y);
  await waitState((state) => state.nearby === "boat");
  const extracted = await pressAndPost("dive/extract", null, "e");
  assert.equal(extracted.player.coins, 200);
  assert.equal(extracted.player.progress.day, 2);
  assert.equal(
    extracted.player.progress.stage,
    "night",
    "An empty normal extraction still advances the existing shift stage.",
  );
  await waitState((state) => !state.diving && state.modal);
  await closeDialogue();
  await waitState((state) => !state.diving && state.land?.actors?.player === 1);
  await responsive(667, 375, "returned-hub-night-667x375");
  const beforeMove = operations.length;
  await routeTo(
    { x: world.hub.divePoint.x - 60, y: world.hub.divePoint.y - 40 },
    "hub",
  );
  const at = await snapshot();
  const saved = await waitSaved(at);
  assert.equal(saved.player.version, extracted.player.version);
  assert.equal(saved.surface.playerVersion, extracted.player.version);
  const acknowledgementDeadline = Date.now() + 10000;
  let acknowledged;
  while (!acknowledged && Date.now() < acknowledgementDeadline) {
    acknowledged = operations
      .slice(beforeMove)
      .find(
        (operation) =>
          operation.path === "/api/adventure/surface-position" &&
          operation.status === 200 &&
          operation.requestVersion === extracted.player.version &&
          operation.surface?.playerVersion === extracted.player.version &&
          Math.hypot(operation.surface.x - at.x, operation.surface.y - at.y) <
            25,
      );
    if (!acknowledged) await page.waitForTimeout(150);
  }
  assert(
    acknowledged,
    "A real dock move must be acknowledged using the version returned by extraction.",
  );
  checks.push("post-extraction-dock-move-acknowledges-returned-player-version");
  await shot("post-extraction-dock-move-saved-with-new-version");
  await page.waitForTimeout(2500);
  await page.reload();
  await attach();
  value = await waitState(
    (state) => !state.diving && state.land?.area === "hub",
  );
  assert(Math.hypot(value.x - at.x, value.y - at.y) < 30);
  const state = await apiState();
  assert.equal(state.surface.layoutVersion, 9);
  assert.equal(state.player.coins, 200);
  assert.equal(state.player.inventory.length, 0);
  assert.equal(state.player.progress.day, 2);
  assert.equal(state.player.progress.stage, "night");
  await shot("final-hub-save-reload-after-empty-dive");
  checks.push(
    "real-ocean-entry-portrait-joystick-cancel-bag-pause-extract-and-hub-reload",
  );
}

try {
  const health = await fetch(`${origin}/api/health`, {
    redirect: "error",
    signal: AbortSignal.timeout(15000),
  });
  assert(
    health.ok && (await health.json()).status === "ok",
    "Local candidate health is required.",
  );
  const pck = await fetch(`${origin}/game/index.pck`, {
    redirect: "error",
    signal: AbortSignal.timeout(180000),
  });
  assert(pck.ok, "Export the candidate before starting browser acceptance.");
  const digest = createHash("sha256");
  let downloaded = 0;
  for await (const chunk of pck.body) {
    digest.update(chunk);
    downloaded += chunk.length;
    assert(
      downloaded <= expectedPckBytes,
      "Served PCK exceeds the pinned candidate.",
    );
  }
  assert.equal(downloaded, expectedPckBytes);
  assert.equal(digest.digest("hex"), expectedPck);
  candidatePck = { sha256: expectedPck, decodedBytes: expectedPckBytes };
  await mongo.connect();
  assert(
    await mongo.db().collection("contents").findOne({ state: "published" }),
    "Published local content required.",
  );
  const now = new Date().toISOString();
  fixtureAttempted = true;
  await mongo
    .db()
    .collection("players")
    .insertOne({
      id,
      email,
      name: "Nala Uji Layout 06",
      role: "player",
      status: "active",
      appearance: "male_nusantara",
      coins: 200,
      inventory: [],
      abilities: freshAbilities(),
      progress: {
        ...freshProgress(),
        day: fixtureStoryDay,
        stage: "dive",
        tutorial: true,
      },
      adventure: { discoveries: [], puzzles: [], keyItems: [] },
      calendar: {
        ...freshCalendar(),
        calendarDay: 2,
        lastSettledDay: 2,
        minuteOfDay: 1110,
      },
      homestead: freshHomestead(fixtureStoryDay),
      version: 0,
      authVersion: 0,
      passwordHash: await argon2.hash(password, { type: argon2.argon2id }),
      createdAt: now,
      updatedAt: now,
    });
  const fixtureCache = new Redis(redisUrl);
  try {
    let initialSurface;
    if (["ocean", "dialogue", "left", "shelters"].includes(routeMode)) {
      initialHub = {
        area: "hub",
        ...WORLD.surfaceSpawn,
        layoutVersion: WORLD.hub.layoutVersion,
        playerVersion: 0,
        positionAt: Date.now(),
      };
      assert(isLandWalkable(WORLD.landMaps.hub, initialHub));
      initialSurface = initialHub;
    } else if (routeMode === "lower") {
      const bridge = WORLD.landMaps.forest.bridges.find(
        (entry) => entry.id === "bridge_lower",
      );
      const [x, y] = bridge.path[0];
      initialLower = {
        area: "forest",
        x,
        y,
        layoutVersion: WORLD.landMaps.forest.layoutVersion,
        playerVersion: 0,
        positionAt: Date.now(),
      };
      assert(isLandWalkable(WORLD.landMaps.forest, initialLower));
      initialSurface = initialLower;
    } else if (routeMode === "continuation") {
      const bridge = WORLD.landMaps.forest.bridges.find(
        (entry) => entry.id === "bridge_lower",
      );
      const [x, y] = bridge.path.at(-1);
      initialContinuation = {
        area: "forest",
        x,
        y,
        layoutVersion: WORLD.hub.layoutVersion,
        playerVersion: 0,
        positionAt: Date.now(),
      };
      assert(isLandWalkable(WORLD.landMaps.forest, initialContinuation));
      initialSurface = initialContinuation;
    } else {
      const [x, y] = WORLD.landMaps.hub.shelters.find(
        (shelter) => !shelter.existing,
      ).posts[0];
      assert(!isLandWalkable(WORLD.landMaps.hub, { x, y }));
      initialLegacy = {
        area: "hub",
        x,
        y,
        layoutVersion: 8,
        playerVersion: 0,
        positionAt: Date.now(),
      };
      initialSurface = initialLegacy;
    }
    await fixtureCache.set(
      `surface:${id}`,
      JSON.stringify(initialSurface),
      "EX",
      1800,
    );
  } finally {
    await fixtureCache.quit();
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
  cdp = await context.newCDPSession(page);
  await page.addInitScript(() => {
    window.jalasmaraDiagnostics = true;
  });
  page.on("pageerror", (error) => errors.push(error.message));
  page.on("console", (message) => {
    if (message.type() === "error") errors.push(message.text());
  });
  page.on("response", async (response) => {
    const path = new URL(response.url()).pathname;
    if (!path.startsWith("/api/")) return;
    if (response.status() >= 400) {
      const body = await response.json().catch(() => ({}));
      const sent = response.request().postDataJSON() ?? {};
      failures.push({
        path,
        status: response.status(),
        code: body.code,
        error: body.error,
        requestVersion: sent.version,
        fromPositionAt: sent.fromPositionAt,
      });
    }
    if (
      response.request().method() !== "POST" ||
      !["/api/adventure/travel", "/api/adventure/surface-position"].includes(
        path,
      )
    )
      return;
    const body = await response.json().catch(() => ({}));
    const sent = response.request().postDataJSON() ?? {};
    operations.push({
      path,
      status: response.status(),
      surface: body.surface,
      requestVersion: sent.version,
      fromPositionAt: sent.fromPositionAt,
    });
  });
  await page.goto(`${origin}/login`);
  await page.getByLabel("Email", { exact: true }).fill(email);
  await page.getByLabel("Password", { exact: true }).fill(password);
  await page.getByRole("button", { name: "Masuk ke Jalasmara" }).click();
  await page.waitForURL("**/play");
  await attach();
  routeStarted = Date.now();
  world = await fetchWorld(context.request, origin);
  assert.equal(
    world.hub.layoutVersion,
    9,
    "Running API must include the exported shelter layout.",
  );
  if (routeMode === "full") {
    const migrated = await apiState();
    assert.equal(migrated.surface.layoutVersion, 9);
    assert(isLandWalkable(world.landMaps.hub, migrated.surface));
    assert(
      Math.hypot(
        migrated.surface.x - initialLegacy.x,
        migrated.surface.y - initialLegacy.y,
      ) >= 12,
    );
    assert.equal((await snapshot()).land.components.AttachedShelterRoofs, 5);
    assert.equal((await snapshot()).land.components.ShelterCollisionPosts, 10);
    assert.equal((await snapshot()).land.components.SasmitaPileFooting, 4);
    checks.push("legacy-layout8-post-position-migrates-to-real-layout9-floor");
    await verifyHome();
    await verifyShelters();
    await routeTo(world.forest.gate, "hub");
    const travel = page.waitForResponse(
      (response) =>
        response.url().endsWith("/api/adventure/travel") &&
        response.request().method() === "POST",
    );
    await page.keyboard.press("e");
    assert.equal((await (await travel).json()).surface.area, "forest");
    await waitState(
      (value) =>
        value.area === "forest" &&
        value.land?.readability &&
        value.land?.actors?.player === 1,
    );
    await page.waitForTimeout(700);
    await shot("01-physical-forest-entry");
    checks.push("physical-hub-gate-to-forest-entry-with-real-3d-player");

    await walkTo(350, 1250);
    await page.waitForTimeout(700);
    const gateway = await snapshot(),
      originalCrowns = gateway.land.readability.active.map(
        (entry) => entry.index,
      );
    assert(
      originalCrowns.length > 0 &&
        originalCrowns.length < gateway.land.readability.crowns / 4,
    );
    assert(
      gateway.land.readability.active.every((entry) => entry.amount > 0.99),
    );
    await responsive(667, 375, "02-gateway-667x375");
    const beforeModal = await snapshot();
    const pausedHeartbeat = page.waitForResponse(
      (response) =>
        response.url().endsWith("/api/calendar/heartbeat") &&
        response.request().postDataJSON()?.paused === true,
    );
    await tap("journal");
    await waitState((value) => value.modal && value.weather.clockPaused);
    const pausedCalendarResponse = await pausedHeartbeat;
    assert(pausedCalendarResponse.ok());
    const pausedCalendar = (await pausedCalendarResponse.json()).calendar;
    await page.keyboard.down("d");
    await page.waitForTimeout(350);
    await page.keyboard.up("d");
    const paused = await snapshot();
    assert(Math.hypot(paused.x - beforeModal.x, paused.y - beforeModal.y) < 1);
    await page.waitForTimeout(6200);
    assert.equal(
      (await apiState()).calendar.minuteOfDay,
      pausedCalendar.minuteOfDay,
      "The actual server calendar must stay paused through the next heartbeat while reading",
    );
    await shot("03-journal-pauses-under-canopy");
    await page.keyboard.press("Escape");
    await waitState((value) => !value.modal && !value.weather.clockPaused);
    checks.push("localized-settled-canopy-and-touch-journal-pause-at-667x375");

    await responsive(844, 390, "04-gateway-844x390");
    const joystick = (await snapshot()).hud.joystick,
      start = await touchPoint(joystick.center),
      moved = await touchPoint([
        joystick.center[0] + joystick.radius * 0.65,
        joystick.center[1] - joystick.radius * 0.25,
      ]);
    const prior = await snapshot();
    await cdp.send("Input.dispatchTouchEvent", {
      type: "touchStart",
      touchPoints: [start],
    });
    await cdp.send("Input.dispatchTouchEvent", {
      type: "touchMove",
      touchPoints: [moved],
    });
    await page.waitForTimeout(350);
    assert(Math.hypot(...(await snapshot()).hud.joystick.direction) > 0.1);
    await cdp.send("Input.dispatchTouchEvent", {
      type: "touchEnd",
      touchPoints: [],
    });
    await page.waitForTimeout(350);
    const released = await snapshot();
    assert(Math.hypot(...released.hud.joystick.direction) < 0.01);
    assert(Math.hypot(released.x - prior.x, released.y - prior.y) > 2);
    checks.push(
      "round-joystick-physically-moves-and-releases-in-forest-at-844x390",
    );
    await responsive(1440, 900, "05-gateway-desktop-width-touch-context");
    checks.push("desktop-width-preserves-3d-projection-and-hud-context");

    await walkTo(480, 1210);
    await walkTo(650, 1050);
    await page.waitForTimeout(1000);
    const canopy = await snapshot();
    assert.equal(canopy.nearby, "forest_canopy");
    assert(
      originalCrowns.every(
        (index) =>
          !canopy.land.readability.active.some(
            (entry) => entry.index === index,
          ),
      ),
      "Entrance crowns must recover after leaving them",
    );
    await shot("06-canopy-clearing-restored-entrance-crowns");
    await waitSaved(canopy);
    await page.reload();
    await attach();
    const resumed = await waitState(
      (value) => value.area === "forest" && value.land?.actors?.player === 1,
    );
    assert(Math.hypot(resumed.x - canopy.x, resumed.y - canopy.y) < 30);
    await shot("07-forest-save-reload");
    checks.push(
      "entrance-crowns-restore-and-physical-forest-position-survives-reload",
    );

    for (const bridge of world.landMaps.forest.bridges) {
      const [a, b] = bridge.path;
      await routeTo({ x: a[0], y: a[1] }, "forest");
      const before = await snapshot();
      await walkTo(b[0], b[1]);
      const after = await snapshot(),
        emitted = after.land.bridges[bridge.id];
      assert(Math.hypot(after.x - before.x, after.y - before.y) > 250);
      assert(
        emitted &&
          emitted.oriented &&
          emitted.railPosts >= 8 &&
          emitted.thickness >= 12,
      );
      assert.equal(after.diving, false);
      await shot(`08-${bridge.id}-crossed`);
      checks.push(
        `${bridge.id}-crossed-physically-with-deck-rails-and-ground-foot-pivot`,
      );
    }
  } else if (routeMode === "continuation") {
    const initial = await waitState(
      (value) => value.area === "forest" && value.land?.actors?.player === 1,
    );
    assert(
      Math.hypot(
        initial.x - initialContinuation.x,
        initial.y - initialContinuation.y,
      ) < 30,
    );
    const actualBridge = world.landMaps.forest.bridges.find(
      (entry) => entry.id === "bridge_lower",
    );
    assert.deepEqual(actualBridge.path.at(-1), [
      initialContinuation.x,
      initialContinuation.y,
    ]);
    await shot("continuation-start-at-lower-bridge-endpoint");
    checks.push(
      "separate-fixture-starts-at-previously-crossed-real-forest-bridge",
    );
  }
  if (!["ocean", "dialogue", "left", "shelters", "lower"].includes(routeMode)) {
    await routeTo({ x: 200, y: 1320 }, "forest");
    await waitState((value) => value.nearby === "return");
    const returning = page.waitForResponse(
      (response) =>
        response.url().endsWith("/api/adventure/travel") &&
        response.request().method() === "POST",
    );
    await page.keyboard.press("e");
    assert.equal((await (await returning).json()).surface.area, "hub");
    await waitState(
      (value) =>
        value.area !== "forest" &&
        value.land?.area === "hub" &&
        value.land?.actors?.player === 1,
    );
    await shot("09-return-through-real-portal");
    const finalState = await apiState();
    assert.equal(finalState.surface.area, "hub");
    assert.equal(
      finalState.player.coins,
      200,
      "World readability and physical navigation must not invent rewards",
    );
    assert.equal(finalState.player.progress.day, 2);
    assert.equal(finalState.calendar.dayLengthMs, 36 * 60 * 1000);
    assert.equal((await snapshot()).weather.dayLengthMinutes, 36);
    checks.push(
      "physical-return-portal-keeps-story-coins-and-authoritative-surface",
    );
  } else if (routeMode === "lower") {
    const initial = await waitState(
      (value) => value.area === "forest" && value.land?.actors?.player === 1,
    );
    assert(
      Math.hypot(initial.x - initialLower.x, initial.y - initialLower.y) < 30,
    );
    await shot("lower-fixture-start-at-real-bridge-approach");
    checks.push("separate-lower-fixture-starts-on-real-forest-floor");
  } else {
    const initial = await waitState(
      (value) => value.land?.area === "hub" && value.land?.actors?.player === 1,
    );
    assert(Math.hypot(initial.x - initialHub.x, initial.y - initialHub.y) < 30);
    assert.deepEqual(world.surfaceSpawn, WORLD.surfaceSpawn);
    await shot(`${routeMode}-fixture-start-at-actual-hub-spawn`);
    checks.push(`separate-${routeMode}-fixture-starts-on-real-hub-floor`);
  }
  if (routeMode === "shelters") await verifyRemainingShelters();
  else if (routeMode === "lower") await verifyLowerBridge();
  else if (routeMode === "left") await verifyLeftView();
  else if (routeMode === "dialogue") await verifyCompactDialogue();
  else await verifyOcean();
  assert.deepEqual(errors, []);
  assert.deepEqual(failures, []);
  lastSnapshot = await snapshot();
  console.log(
    JSON.stringify(
      {
        checks,
        errors,
        failures,
        positionSyncs: operations.filter((operation) =>
          operation.path.endsWith("surface-position"),
        ).length,
      },
      null,
      2,
    ),
  );
} catch (error) {
  if (page) await shot("failure").catch(() => {});
  lastSnapshot = frame ? await snapshot().catch(() => null) : null;
  throw error;
} finally {
  const cookies = context ? await context.cookies().catch(() => []) : [];
  if (browser) await browser.close();
  const cache = fixtureAttempted ? new Redis(redisUrl) : null;
  try {
    if (fixtureAttempted) {
      await mongo
        .db()
        .collection("players")
        .deleteOne({ id, email, role: "player", name: "Nala Uji Layout 06" });
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
          checks,
          origin,
          candidatePck,
          routeMode,
          navigation,
          inputProofs,
          initialLegacy,
          initialContinuation,
          initialHub,
          initialLower,
          errors,
          failures,
          operations,
          observations,
          lastSnapshot,
          ownTemporaryPlayerRemoved: cleaned,
          fixtureAttempted,
          routeElapsedMs: routeStarted ? Date.now() - routeStarted : null,
        },
        null,
        2,
      ),
    );
  }
}
