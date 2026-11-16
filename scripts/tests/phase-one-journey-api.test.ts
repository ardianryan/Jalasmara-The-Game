import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import { createHash, randomUUID } from "node:crypto";
import { mkdirSync, writeFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { test } from "node:test";
import argon2 from "argon2";
import { buildApp } from "../../apps/api/src/app.js";
import { seedCatalog } from "../../apps/api/src/content.js";
import {
  close,
  connect,
  type Store,
  type User,
} from "../../apps/api/src/db.js";
import {
  freshAbilities,
  freshProgress,
} from "../../packages/shared/src/index.js";
import { WORLD } from "../../packages/shared/src/world.js";

// Run against an explicitly supplied local replica set and Redis fixture, never the app's defaults.
const mongoBase = process.env.PHASE1_TEST_MONGO_URL;
const redisUrl = process.env.PHASE1_TEST_REDIS_URL;
assert(
  mongoBase && redisUrl,
  "Set PHASE1_TEST_MONGO_URL and PHASE1_TEST_REDIS_URL to isolated local services.",
);
const mongo = new URL(mongoBase);
const redis = new URL(redisUrl);
assert.equal(mongo.protocol, "mongodb:");
assert(["127.0.0.1", "localhost"].includes(mongo.hostname));
assert(
  Number(mongo.port) >= 27020,
  "Use a fixture MongoDB port, not the owner/default database.",
);
assert.equal(mongo.pathname, "/jalasmara_phase1_journey_base");
assert.equal(redis.protocol, "redis:");
assert(["127.0.0.1", "localhost"].includes(redis.hostname));
assert(
  Number(redis.port) >= 6381,
  "Use a fixture Redis port, not the owner/default service.",
);
assert.equal(
  redis.pathname,
  "/15",
  "Reserve Redis logical DB 15 for this fixture.",
);
const runId = randomUUID();
const sourceSha = execFileSync("git", ["rev-parse", "HEAD"], {
  encoding: "utf8",
}).trim();
mongo.pathname = `/jalasmara_phase1_journey_${runId.replaceAll("-", "")}`;
process.env.NODE_ENV = "test";
process.env.APP_ORIGIN = "http://localhost:5173";
process.env.MONGO_URL = mongo.toString();
process.env.REDIS_URL = redis.toString();

const tracePath = resolve(
  process.env.PHASE1_JOURNEY_TRACE ??
    `artifacts/phase-one-journey/${runId}.json`,
);
const trace: Array<Record<string, unknown>> = [];
let store: Store;
let app: Awaited<ReturnType<typeof buildApp>>;
let player: User;
let publishedId = "";
const cookies = new Map<string, string>();
let csrf = "";
let passed = false;
let cleanup: Record<string, number> = {};

async function request(
  path: string,
  body?: unknown,
  key: string = randomUUID(),
) {
  const response = await app.inject({
    method: body === undefined ? "GET" : "POST",
    url: `/api${path}`,
    remoteAddress: "fd00:face:1234::15",
    headers: {
      cookie: [...cookies]
        .map(([name, value]) => `${name}=${value}`)
        .join("; "),
      origin: "http://localhost:5173",
      "x-csrf-token": csrf,
      "idempotency-key": key,
    },
    payload: body as Record<string, unknown> | undefined,
  });
  for (const cookie of response.cookies) {
    if (["jalasmara", "jalasmara_csrf"].includes(cookie.name))
      cookies.set(cookie.name, cookie.value);
  }
  const data = response.json() as any;
  if (data.csrf) csrf = data.csrf;
  return { status: response.statusCode, data };
}

async function ok(path: string, body?: unknown, key?: string) {
  const result = await request(path, body, key);
  assert.equal(result.status, 200, `${path}: ${JSON.stringify(result.data)}`);
  return result.data;
}

async function state() {
  return ok("/game/state");
}

function record(
  id: string,
  trigger: string,
  stateValue: any,
  expectedEligible = "",
) {
  const p = stateValue.player;
  assert(p?.id === player.id, `${id}: state belongs to the disposable player`);
  const d = stateValue.dive ?? {};
  const shift = stateValue.shift ?? {};
  trace.push({
    id,
    trigger,
    expectedEligible,
    player: { id: p.id, progress: p.progress },
    dive: Object.keys(d).length
      ? {
          id: d.id,
          mode: d.mode,
          hits: d.hits,
          requiredHits: d.requiredHits,
          oxygen: d.oxygen,
          position: d.position,
          challenge: d.challenge ? { id: d.challenge.id } : {},
        }
      : {},
    shift: Object.keys(shift).length ? { id: shift.id } : {},
    coins: p.coins,
    missions: p.progress.missions,
  });
}

async function positionDive(point: { x: number; y: number }) {
  const key = `dive:${player.id}`;
  const raw = await store.redis.get(key);
  assert(raw, "Dive fixture exists");
  const dive = JSON.parse(raw);
  dive.position = { x: point.x, y: point.y };
  await store.redis.set(key, JSON.stringify(dive), "KEEPTTL");
}

async function positionSurface(
  point: { x: number; y: number },
  area: "hub" | "forest" = "hub",
) {
  const current = await store.users.findOne({ id: player.id });
  assert(current);
  await store.redis.set(
    `surface:${player.id}`,
    JSON.stringify({
      area,
      x: point.x,
      y: point.y,
      positionAt: Date.now() - 2000,
      playerVersion: current.version,
      layoutVersion: WORLD.landMaps[area].layoutVersion,
    }),
    "EX",
    1800,
  );
}

async function observeDive(diveId: string, id: string, settings?: number[]) {
  const point = [...WORLD.landmarks, ...WORLD.puzzles, ...WORLD.caches].find(
    (item) => item.id === id,
  );
  assert(point, `Known dive landmark ${id}`);
  await positionDive(point);
  const result = await ok("/adventure/interact", {
    diveId,
    id,
    ...(settings ? { settings } : {}),
  });
  assert.equal(result.alreadyFound, false, `First discovery ${id}`);
  assert(result.reward > 0, `${id} awards server-owned coins`);
}

async function observeSurface(id: string) {
  const hub = WORLD.surface_hub.landmarks.find((item) => item.id === id);
  const forest = [...WORLD.forest.landmarks, ...WORLD.forest.caches].find(
    (item) => item.id === id,
  );
  const point = hub ?? forest;
  assert(point, `Known surface landmark ${id}`);
  await positionSurface(point, hub ? "hub" : "forest");
  const result = await ok("/adventure/surface-interact", { id });
  assert.equal(result.alreadyFound, false, `First surface discovery ${id}`);
  assert(result.reward > 0);
}

async function capture(dive: any, target: any) {
  await positionDive(target);
  if (dive.mode === "boss") {
    if (dive.hits > 0) await new Promise((done) => setTimeout(done, 1110));
    dive = (
      await ok("/dive/neutralize", { diveId: dive.id, targetId: target.id })
    ).dive;
  }
  const started = await ok("/dive/challenge", {
    diveId: dive.id,
    targetId: target.id,
  });
  const challenge = started.dive.challenge;
  assert(
    challenge?.id && !("correctIndex" in challenge.question),
    "Answer is hidden from the client",
  );
  const authored = seedCatalog().questions.find(
    (question) => question.id === challenge.question.id,
  );
  assert(
    authored,
    `Question ${challenge.question.id} is in published fixture content`,
  );
  const answered = await ok("/dive/catch", {
    diveId: dive.id,
    challengeId: challenge.id,
    selectedOption: authored.correctIndex,
  });
  assert.equal(answered.dive.challenge.result.correct, true);
  const continued = await ok("/dive/continue", {
    diveId: dive.id,
    challengeId: challenge.id,
  });
  return continued.dive;
}

async function homeAction(action: string) {
  const home = await ok("/homestead/state");
  return ok("/homestead/action", {
    action,
    expectedRevision: home.homestead.revision,
  });
}

test(
  "isolated fresh Phase 1 account reaches server-owned finale and emits cutscene gate trace",
  { timeout: 180000 },
  async () => {
    try {
      store = await connect();
      assert.equal(
        await store.users.countDocuments(),
        0,
        "Fixture database was not empty",
      );
      assert.equal(
        await store.contents.countDocuments(),
        0,
        "Fixture database was not empty",
      );
      const catalog = seedCatalog();
      publishedId = randomUUID();
      await store.contents.insertOne({
        id: publishedId,
        label: "Phase 1 journey fixture",
        state: "published",
        catalog,
        createdAt: new Date().toISOString(),
        publishedAt: new Date().toISOString(),
      });
      app = await buildApp(store, false);
      await app.ready();
      const now = new Date().toISOString();
      const password = randomUUID() + "-local-fixture";
      player = {
        id: runId,
        email: `phase-one-${runId}@test.invalid`,
        name: "Nala Phase 1 Fixture",
        role: "player",
        status: "active",
        appearance: "female_nusantara",
        coins: 0,
        inventory: [],
        abilities: freshAbilities(),
        progress: freshProgress(),
        version: 0,
        authVersion: 0,
        passwordHash: await argon2.hash(password, { type: argon2.argon2id }),
        createdAt: now,
        updatedAt: now,
      };
      await store.users.insertOne(player);
      await ok("/auth/session");
      await ok("/auth/login", { email: player.email, password });
      let current = await state();
      assert.equal(current.player.progress.tutorial, false);
      record("prologue", "new_selected_character", current, "prologue");
      current = await ok("/game/tutorial", {});
      assert.equal(current.player.progress.tutorial, true);
      record("tutorial_acknowledged", "game/tutorial", await state());

      for (let day = 1; day <= 3; day++) {
        current = await state();
        assert.equal(current.player.progress.day, day);
        assert.equal(current.player.progress.stage, "dive");
        if (day === 2) {
          record("garden_crisis", "sleep_day_1", current, "garden_crisis");
          for (const id of [
            "garden_leaf",
            "garden_root",
            "garden_channel",
            "forest_canopy",
            "forest_roots",
            "forest_stream",
          ])
            await observeSurface(id);
          await positionSurface(WORLD.hub.divePoint);
          await positionSurface(WORLD.homestead.permitBoard);
          const prematurePermit = await request("/homestead/action", {
            action: "permit",
            expectedRevision: (await ok("/homestead/state")).homestead.revision,
          });
          assert.equal(prematurePermit.data.code, "PERMIT_REQUIREMENT");
        }
        let dive = (await ok("/dive/start", { mode: "dive" })).dive;
        if (day === 1) record("first_dive", "dive/start", await state());
        const needed = catalog.recipes.filter((recipe) => recipe.day === day);
        for (const recipe of needed) {
          const target = dive.targets.find(
            (candidate: any) =>
              candidate.fragmentId === recipe.fragmentId && !candidate.caught,
          );
          assert(target, `Target for ${recipe.id}`);
          dive = await capture(dive, target);
        }
        if (day === 2)
          for (const id of ["nitrogen", "photosynthesis", "osmosis"])
            await observeDive(dive.id, id);
        if (day === 3) {
          await positionDive({ x: 4200, y: 2200 });
          record("cave_warning", "dive_depth_60m", await state());
          for (const id of ["corporate_pipe", "inscription"])
            await observeDive(dive.id, id);
          await observeDive(dive.id, "filter", [0, 1, 2]);
        }
        await positionDive(WORLD.spawn);
        const extracted = await ok("/dive/extract", { diveId: dive.id });
        assert.equal(extracted.player.progress.stage, "night");
        assert.equal(extracted.loot.length, 3);
        const firstNight = (await ok("/kedai/start", {})).shift;
        if (day === 1) record("first_kedai", "kedai/start", await state());
        assert.equal(firstNight.customers.length, 3);
        let shift = firstNight;
        for (const recipe of needed) {
          const before = await state();
          const item = before.player.inventory.find(
            (entry: any) =>
              entry.fragmentId === recipe.fragmentId && entry.quantity > 0,
          );
          assert(item, `Earned ${recipe.fragmentId} for ${recipe.id}`);
          const served = await ok("/kedai/serve", {
            shiftId: shift.id,
            recipeId: recipe.id,
            fragmentId: item.fragmentId,
            stars: item.stars,
          });
          shift = served.shift;
          assert(served.player.progress.missions.includes(recipe.id));
          if (recipe.id === "daun_kuning")
            record("first_service", "kedai/serve", await state());
          if (recipe.id === "akar") {
            record("saras_visit", "kedai/serve", await state());
          }
        }
        const closed = await ok("/kedai/close-shift", { shiftId: shift.id });
        assert.equal(closed.homestead.pendingStoryAdvance.storyDay, day);
        assert.equal(
          closed.player.progress.day,
          day,
          "Story day advances only on sleep",
        );
        if (day === 2) {
          await positionSurface(WORLD.homestead.permitBoard);
          const permit = await homeAction("permit");
          assert.equal(permit.homestead.permit, true);
        }
        await positionSurface(WORLD.homestead.door);
        await homeAction("enter");
        const live = (await store.users.findOne({ id: player.id }))!;
        await store.redis.set(
          `home:${player.id}`,
          JSON.stringify({
            x: 270,
            y: 330,
            positionAt: Date.now() - 2000,
            playerVersion: live.version,
          }),
          "EX",
          1800,
        );
        const slept = await homeAction("sleep");
        assert.equal(slept.player.progress.day, Math.min(3, day + 1));
        assert.equal(slept.player.progress.stage, day === 3 ? "boss" : "dive");
        assert.equal(slept.homestead.pendingStoryAdvance, undefined);
        await store.redis.set(
          `home:${player.id}`,
          JSON.stringify({
            x: WORLD.homestead.interior.exit.x,
            y: WORLD.homestead.interior.exit.y,
            positionAt: Date.now() - 2000,
            playerVersion: slept.player.version,
          }),
          "EX",
          1800,
        );
        await homeAction("exit");
        if (day === 3)
          record("earthquake", "sleep_day_3", await state(), "earthquake");
      }

      let ready = await state();
      for (const ability of ["oxygen", "net"] as const)
        while (
          ready.player.abilities[ability] < WORLD.boss.requiredUpgrades[ability]
        ) {
          ready = await ok("/game/upgrade", { ability });
        }
      assert.equal(ready.player.progress.stage, "boss");
      assert(ready.player.coins >= 0);
      let boss = (await ok("/dive/start", { mode: "boss" })).dive;
      record("boss_intro", "dive/start_boss", await state(), "boss_intro");
      assert.equal(boss.requiredHits, 6);
      for (let index = 0; index < boss.targets.length; index++) {
        boss = await capture(boss, boss.targets[index]);
        assert.equal(boss.hits, index + 1);
        if (boss.hits === 3)
          record(
            "boss_phase_two",
            "three_of_six_resonances",
            await state(),
            "boss_phase_two",
          );
      }
      const victory = await ok("/dive/extract", { diveId: boss.id });
      assert.equal(victory.victory, true);
      assert.equal(victory.player.progress.stage, "done");
      assert.equal(victory.player.progress.bossDefeated, true);
      assert(victory.player.progress.missions.includes("gajah_mina"));
      assert(victory.player.adventure.keyItems.includes(WORLD.boss.keyItem));
      record("victory", "dive/extract_boss", await state(), "victory");
      record("epilogue", "victory_followup", await state(), "victory");
      assert.equal(
        (await request("/dive/start", { mode: "boss" })).status,
        409,
      );
      passed = true;
    } finally {
      if (app) await app.close();
      if (store) {
        if (player) {
          const deletedUsers = (
            await store.users.deleteOne({ id: player.id, email: player.email })
          ).deletedCount;
          const deletedShifts = (
            await store.db
              .collection("shifts")
              .deleteMany({ userId: player.id })
          ).deletedCount;
          const deletedReceipts = (
            await store.receipts.deleteMany({
              _id: { $regex: `^${player.id}:` },
            })
          ).deletedCount;
          const keys = [
            `surface:${player.id}`,
            `home:${player.id}`,
            `dive:${player.id}`,
            `calendar:writer:${player.id}`,
          ];
          const token = cookies.get("jalasmara");
          if (token) {
            const authKey = `auth:${createHash("sha256").update(token).digest("hex")}`;
            const raw = await store.redis.get(authKey);
            if (raw) {
              assert.equal(JSON.parse(raw).userId, player.id);
              keys.push(authKey);
            }
          }
          const deletedRedisKeys = await store.redis.del(...keys);
          cleanup = {
            deletedUsers,
            deletedShifts,
            deletedReceipts,
            deletedRedisKeys,
          };
        }
        if (publishedId)
          cleanup.deletedContent = (
            await store.contents.deleteOne({ id: publishedId })
          ).deletedCount;
        cleanup.remainingUsers = await store.users.countDocuments();
        cleanup.remainingContent = await store.contents.countDocuments();
        cleanup.remainingShifts = await store.db
          .collection("shifts")
          .countDocuments();
        cleanup.remainingReceipts = await store.receipts.countDocuments();
        assert.equal(cleanup.remainingUsers, 0);
        assert.equal(cleanup.remainingContent, 0);
        assert.equal(cleanup.remainingShifts, 0);
        assert.equal(cleanup.remainingReceipts, 0);
        await close(store);
      }
      mkdirSync(dirname(tracePath), { recursive: true });
      writeFileSync(
        tracePath,
        JSON.stringify(
          {
            runId,
            sourceSha,
            source: "local_api_inject",
            status: passed ? "passed" : "failed",
            fixture: {
              mongoHost: mongo.hostname,
              mongoPort: Number(mongo.port),
              mongoDb: mongo.pathname.slice(1),
              redisHost: redis.hostname,
              redisPort: Number(redis.port),
              redisDb: Number(redis.pathname.slice(1)),
            },
            cleanup,
            caveat:
              "Server API milestones use fixture positions. This does not prove physical movement, Godot playback, timing, or visual quality.",
            events: trace,
          },
          null,
          2,
        ),
      );
      console.log(`PHASE_ONE_JOURNEY_TRACE=${tracePath}`);
    }
  },
);
