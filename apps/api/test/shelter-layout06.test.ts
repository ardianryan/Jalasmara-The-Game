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
const oldMapV8 = {
  ...map,
  layoutVersion: 8,
  obstacles: map.obstacles
    .filter((entry) => entry.variant !== "shelter_post")
    .map((entry) =>
      entry.id === "griya_sasmita"
        ? {
            ...entry,
            x: 60,
            width: 200,
            footprint: [
              [92, 420],
              [260, 459.15],
              [228, 565],
              [60, 525.85],
            ] as typeof entry.footprint,
          }
        : entry,
    ),
};
const griyaOldCorners = [
  [72, 432],
  [248, 434],
  [248, 550],
  [75, 550],
] as const;
const deckAisles = [
  [59, 400],
  [261, 400],
  [59, 600],
  [261, 600],
] as const;

test("seven rain stations have body clearance under physical roofs in legacy and left views", () => {
  for (const profile of profiles) {
    const station = point(profile.activity.shelter);
    assert.ok(isLandWalkable(map, station), profile.name);
    const roof = map.shelters!.find((shelter) => {
      for (const azimuth of [0, -Math.PI / 4]) {
        const upX = -Math.sin(azimuth) * Math.sin((35 * Math.PI) / 180);
        const upY = Math.cos(azimuth) * Math.sin((35 * Math.PI) / 180);
        for (const height of [0, 35, 70]) {
          for (let index = 0; index < 16; index++) {
            const angle = (index * Math.PI) / 8;
            if (!landPointInPolygon({
              x: station.x + Math.cos(angle) * 13 + upX * height,
              y: station.y + Math.sin(angle) * 13 - upY * height * Math.cos((55 * Math.PI) / 180),
            }, shelter.roof)) return false;
          }
        }
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
nodes.push(...deckAisles.map(point));
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
      if (!isLandWalkable(oldMapV8, previous)) continue;
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
  assert.equal(
    migrated,
    49,
    "Forty-nine old support/clearance samples were valid; the southern Ratih sample was already outside floor clearance",
  );
});

test("Griya follows both deck axes and keeps body-sized access around its changed footprint", () => {
  const house = map.obstacles.find((entry) => entry.id === "griya_sasmita")!;
  const deck = map.surfaces.find((entry) => entry.id === "sasmita_deck")!;
  assert.deepEqual(
    [house.x + house.width / 2, house.y + house.height / 2],
    [160, 492.5],
  );
  const [a, b, , d] = house.footprint;
  assert.equal(a[1], b[1]);
  assert.equal(a[0], d[0]);
  assert.equal(house.x - deck.polygon[0][0], 38);
  assert.equal(deck.polygon[1][0] - house.x - house.width, 38);
  const loop = [
    [160, 615],
    deckAisles[2],
    deckAisles[0],
    deckAisles[1],
    deckAisles[3],
    [160, 615],
  ];
  for (let index = 1; index < loop.length; index++)
    assert.ok(
      isLandSegmentWalkable(map, point(loop[index - 1]), point(loop[index])),
      "The strip behind Griya must not become an isolated floor island",
    );
  for (const value of griyaOldCorners) {
    const previous = point(value);
    assert.ok(isLandWalkable(oldMapV8, previous));
    assert.equal(isLandWalkable(map, previous), false);
    const migrated = nearestSafeLandPoint(map, previous);
    assert.ok(reachesHub(migrated));
    assert.ok(
      Math.hypot(migrated.x - previous.x, migrated.y - previous.y) <= 32,
    );
  }
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
      let migrated = 0;
      const samples = [
        ...map.obstacles.filter((entry) => entry.variant === "shelter_post"),
        ...griyaOldCorners.map((value, index) => ({
          id: `griya_old_corner_${index}`,
          x: value[0],
          y: value[1],
          width: 0,
          height: 0,
        })),
      ];
      for (const post of samples) {
        const previous = {
          x: post.x + post.width / 2,
          y: post.y + post.height / 2,
        };
        if (!isLandWalkable(oldMapV8, previous)) continue;
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
        14,
        "Exercise ten support centres and four formerly free corners of Griya",
      );
      for (const value of [[160, 400], ...deckAisles]) {
        const previous = point(value);
        assert.ok(isLandWalkable(oldMapV8, previous));
        assert.ok(isLandWalkable(map, previous));
        await store.redis.set(
          `surface:${id}`,
          JSON.stringify({
            area: "hub",
            ...previous,
            layoutVersion: 8,
            playerVersion: 7,
            positionAt: Date.now() - 5000,
          }),
          "EX",
          1800,
        );
        const resumed = await request("/adventure/state");
        assert.equal(resumed.status, 200);
        assert.deepEqual(
          { x: resumed.data.surface.x, y: resumed.data.surface.y },
          previous,
          "A valid old saved point must be preserved, including the strip behind Griya",
        );
        assert.ok(reachesHub(resumed.data.surface));
        assert.deepEqual(
          (await request("/adventure/state")).data.surface,
          resumed.data.surface,
        );
      }
      t.diagnostic(
        `${migrated} old support/corner saves migrated and completed legal API round-trips; five valid old deck points stayed unchanged`,
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
