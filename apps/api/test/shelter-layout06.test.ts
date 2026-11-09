import assert from "node:assert/strict";
import test from "node:test";
import { randomUUID } from "node:crypto";
import argon2 from "argon2";
import {
  connect,
  close,
  seed,
  opaque,
  digest,
  type Store,
  type User,
} from "../src/db.js";
import { buildApp } from "../src/app.js";
import {
  freshAbilities,
  freshProgress,
} from "../../../packages/shared/src/index.js";
import { WORLD } from "../../../packages/shared/src/world.ts";
import {
  isLandWalkable,
  isLandSegmentWalkable,
  landPointInPolygon,
  nearestSafeLandPoint,
} from "../../../packages/shared/src/land.ts";

const map = WORLD.landMaps.hub;
const profiles = [
  ...WORLD.surface_hub.residents,
  { name: "Bu Darmi", ...WORLD.surface_hub.districtActivities["Bu Darmi"] },
];
const point = (value: readonly number[]) => ({ x: value[0], y: value[1] });

test("seven rain stations have body clearance under physical roof plans", () => {
  for (const profile of profiles) {
    const station = point(profile.activity.shelter);
    assert.ok(isLandWalkable(map, station), profile.name);
    const roof = map.shelters!.find((shelter) => {
      for (let index = 0; index < 16; index++) {
        const angle = (index * Math.PI) / 8;
        if (
          !landPointInPolygon(
            {
              x: station.x + Math.cos(angle) * 13,
              y: station.y + Math.sin(angle) * 13,
            },
            shelter.roof,
          )
        )
          return false;
      }
      return true;
    });
    assert.ok(
      roof,
      `${profile.name} must fit beneath one actual roof, not merely a house bbox`,
    );
  }
});

// Clear segments through authored stations and support corners prove physical floor connectivity.
// Runtime NPC graph traversal is checked separately by village-routine06.gd.
const routes = [
  ...map.routes,
  ...profiles.map((profile) => profile.activity.commute),
];
const nodes = routes.flatMap((route) => route.map(point));
for (const post of map.obstacles.filter(
  (entry) => entry.variant === "shelter_post",
)) {
  for (const [dx, dy] of [
    [-32, -32],
    [-32, 32],
    [32, -32],
    [32, 32],
  ]) {
    const candidate = { x: post.x + 5 + dx, y: post.y + 5 + dy };
    if (isLandWalkable(map, candidate)) nodes.push(candidate);
  }
}
const graph = nodes.map(() => [] as number[]);
for (let i = 0; i < nodes.length; i++)
  for (let j = i + 1; j < nodes.length; j++) {
    if (!isLandSegmentWalkable(map, nodes[i], nodes[j])) continue;
    graph[i].push(j);
    graph[j].push(i);
  }
function reachesHub(start: { x: number; y: number }) {
  const queue = nodes.flatMap((node, index) =>
    isLandSegmentWalkable(map, start, node) ? [index] : [],
  );
  const seen = new Set(queue);
  while (queue.length) {
    const index = queue.shift()!;
    if (nodes[index].x === map.spawn.x && nodes[index].y === map.spawn.y)
      return true;
    for (const next of graph[index])
      if (!seen.has(next)) {
        seen.add(next);
        queue.push(next);
      }
  }
  return false;
}
test("stations, bridge, changing booth and forest portal stay connected", () => {
  for (const profile of profiles)
    for (const station of ["work", "rest", "shelter"] as const) {
      assert.ok(
        reachesHub(point(profile.activity[station])),
        `${profile.name}/${station}`,
      );
    }
  for (const target of [
    [160, 615],
    [265, 720],
    [400, 720],
    [1485, 1330],
    [2295, 125],
  ]) {
    assert.ok(reachesHub(point(target)), String(target));
  }
});

test("layout migration from each newly blocked support retains connected land", () => {
  const old = {
    ...map,
    layoutVersion: 8,
    obstacles: map.obstacles.filter(
      (entry) => entry.variant !== "shelter_post",
    ),
  };
  assert.equal(map.layoutVersion, 9);
  let migrated = 0;
  for (const post of map.obstacles.filter(
    (entry) => entry.variant === "shelter_post",
  )) {
    for (const [dx, dy] of [
      [0, 0],
      [-8, 0],
      [8, 0],
      [0, -8],
      [0, 8],
    ]) {
      const previous = {
        x: post.x + post.width / 2 + dx,
        y: post.y + post.height / 2 + dy,
      };
      if (!isLandWalkable(old, previous)) continue;
      assert.equal(isLandWalkable(map, previous), false, post.id);
      const safe = nearestSafeLandPoint(map, previous);
      assert.ok(isLandWalkable(map, safe), post.id);
      assert.ok(
        reachesHub(safe),
        `${post.id} migration must not end on an isolated island of floor`,
      );
      migrated++;
    }
  }
  assert.ok(
    migrated >= 30,
    `Insufficient previously valid support samples: ${migrated}`,
  );
});

test(
  "layout 9 API migrates old support saves and persists legal movement without touching player state",
  { timeout: 30000 },
  async (t) => {
    const runId = randomUUID().replaceAll("-", "");
    const database = `jalasmara_shelter_${runId}`;
    const mongoUrl = new URL(
      process.env.TEST_MONGO_URL ??
        "mongodb://127.0.0.1:27018/unused?replicaSet=rs0",
    );
    mongoUrl.pathname = `/${database}`;
    const previousEnv = Object.fromEntries(
      ["NODE_ENV", "APP_ORIGIN", "MONGO_URL", "REDIS_URL"].map((key) => [
        key,
        process.env[key],
      ]),
    );
    process.env.NODE_ENV = "test";
    process.env.APP_ORIGIN = "http://localhost:5173";
    process.env.MONGO_URL = mongoUrl.toString();
    process.env.REDIS_URL =
      process.env.TEST_REDIS_URL ?? "redis://127.0.0.1:6380/14";
    const id = randomUUID();
    const remoteAddress = `fd00:${runId.match(/.{4}/g)!.slice(0, 5).join(":")}::1`;
    const cookies: Record<string, string> = {};
    const authKeys = new Set<string>();
    let csrf = "",
      store: Store | undefined,
      app: Awaited<ReturnType<typeof buildApp>> | undefined;
    try {
      store = await connect();
      assert.equal(store.db.databaseName, database);
      await seed(store);
      app = await buildApp(store, false);
      await app.ready();
      const request = async (
        path: string,
        payload?: Record<string, unknown>,
      ) => {
        const response = await app!.inject({
          method: payload === undefined ? "GET" : "POST",
          url: `/api${path}`,
          remoteAddress,
          headers: {
            cookie: Object.entries(cookies)
              .map(([key, value]) => `${key}=${value}`)
              .join("; "),
            origin: store!.cfg.origin,
            "x-csrf-token": csrf,
          },
          payload,
        });
        for (const cookie of response.cookies) {
          cookies[cookie.name] = cookie.value;
          if (cookie.name === "jalasmara")
            authKeys.add(`auth:${digest(cookie.value)}`);
        }
        const data = response.json();
        if (data.csrf) csrf = data.csrf;
        return { status: response.statusCode, data };
      };
      const now = new Date().toISOString(),
        password = opaque();
      const user: User = {
        id,
        email: `${id}@shelter.test.invalid`,
        name: "Penguji Serambi",
        role: "player",
        status: "active",
        coins: 1234,
        inventory: [{ fragmentId: "klorofil", stars: 3, quantity: 2 }],
        abilities: freshAbilities(),
        progress: {
          ...freshProgress(),
          tutorial: true,
          day: 2,
          missions: ["malam_1"],
        },
        version: 7,
        authVersion: 0,
        passwordHash: await argon2.hash(password, { type: argon2.argon2id }),
        createdAt: now,
        updatedAt: now,
      };
      await store.users.insertOne(user);
      assert.equal((await request("/auth/session")).status, 200);
      assert.equal(
        (await request("/auth/login", { email: user.email, password })).status,
        200,
      );
      assert.equal((await request("/adventure/state")).status, 200);
      const before = await store.users.findOne({ id });
      const oldMap = {
        ...map,
        layoutVersion: 8,
        obstacles: map.obstacles.filter(
          (entry) => entry.variant !== "shelter_post",
        ),
      };
      let migrated = 0;
      for (const post of map.obstacles.filter(
        (entry) => entry.variant === "shelter_post",
      )) {
        const previous = {
          x: post.x + post.width / 2,
          y: post.y + post.height / 2,
        };
        if (!isLandWalkable(oldMap, previous)) continue;
        const oldPositionAt = Date.now() - 5000;
        await store.redis.set(
          `surface:${id}`,
          JSON.stringify({
            area: "hub",
            ...previous,
            layoutVersion: 8,
            playerVersion: 7,
            positionAt: oldPositionAt,
          }),
          "EX",
          1800,
        );
        const resumed = await request("/adventure/state");
        assert.equal(resumed.status, 200, post.id);
        const saved = resumed.data.surface;
        assert.equal(saved.layoutVersion, 9);
        assert.equal(saved.area, "hub");
        assert.deepEqual(
          { x: saved.x, y: saved.y },
          nearestSafeLandPoint(map, previous),
        );
        assert.ok(
          reachesHub(saved),
          `${post.id} must remain connected to the real hub network`,
        );
        assert.ok(saved.positionAt > oldPositionAt);
        assert.deepEqual(
          JSON.parse((await store.redis.get(`surface:${id}`))!),
          saved,
        );
        assert.deepEqual(
          (await request("/adventure/state")).data.surface,
          saved,
          "Reload must preserve the migrated position and timestamp",
        );
        const stale = await request("/adventure/surface-position", {
          area: "hub",
          x: saved.x,
          y: saved.y,
          version: 7,
          fromPositionAt: oldPositionAt,
        });
        assert.equal(stale.status, 409);
        assert.equal(stale.data.code, "POSITION_CHANGED");
        const blocked = await request("/adventure/surface-position", {
          area: "hub",
          ...previous,
          version: 7,
          fromPositionAt: saved.positionAt,
        });
        assert.equal(blocked.status, 409);
        assert.equal(blocked.data.code, "PATH_BLOCKED");
        let destination: { x: number; y: number } | undefined;
        for (let direction = 0; direction < 16; direction++) {
          const angle = (direction * Math.PI) / 8;
          const candidate = {
            x: saved.x + Math.cos(angle) * 8,
            y: saved.y + Math.sin(angle) * 8,
          };
          if (isLandSegmentWalkable(map, saved, candidate)) {
            destination = candidate;
            break;
          }
        }
        assert.ok(
          destination,
          `${post.id} must permit legal movement after migration`,
        );
        const moved = await request("/adventure/surface-position", {
          area: "hub",
          ...destination,
          version: 7,
          fromPositionAt: saved.positionAt,
        });
        assert.equal(moved.status, 200, JSON.stringify(moved.data));
        assert.deepEqual(
          { x: moved.data.surface.x, y: moved.data.surface.y },
          destination,
        );
        assert.equal(moved.data.surface.layoutVersion, 9);
        assert.deepEqual(
          (await request("/adventure/state")).data.surface,
          moved.data.surface,
        );
        assert.deepEqual(
          await store.users.findOne({ id }),
          before,
          "Migration and movement must preserve coins, inventory, calendar, homestead and story",
        );
        migrated++;
      }
      assert.equal(
        migrated,
        9,
        "Exercise every support whose centre was previously a valid saved position",
      );
      t.diagnostic(
        `${migrated} old support saves migrated, rejected stale/blocked moves, and completed legal API save/reload round-trips`,
      );
    } finally {
      if (app) await app.close();
      if (store) {
        const keys = [`surface:${id}`, `calendar:writer:${id}`, ...authKeys];
        let cursor = "0";
        do {
          const result = await store.redis.scan(
            cursor,
            "MATCH",
            `*${remoteAddress}*`,
            "COUNT",
            100,
          );
          cursor = result[0];
          keys.push(...result[1]);
        } while (cursor !== "0");
        await store.redis.del(...keys);
        assert.equal(store.db.databaseName, database);
        await store.db.dropDatabase();
        await close(store);
      }
      for (const [key, value] of Object.entries(previousEnv)) {
        if (value === undefined) delete process.env[key];
        else process.env[key] = value;
      }
    }
  },
);
