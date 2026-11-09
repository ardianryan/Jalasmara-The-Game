import assert from "node:assert/strict";
import test from "node:test";
import { randomUUID } from "node:crypto";
import { readFileSync } from "node:fs";
import argon2 from "argon2";
import { connect, close, seed, digest, type Store, type User } from "../src/db.js";
import { buildApp } from "../src/app.js";
import { freshAbilities, freshProgress } from "../../../packages/shared/src/index.js";
import {
  LAND_MAPS, isLandWalkable, isLandSegmentWalkable, landPointInPolygon,
  nearestSafeLandPoint, type LandMap, type LandPosition,
} from "../../../packages/shared/src/land.ts";

const old: LandMap = JSON.parse(readFileSync(new URL("./fixtures/forest-layout5.json", import.meta.url), "utf8"));
const forest = LAND_MAPS.forest;
const point = ([x, y]: readonly number[]): LandPosition => ({ x, y });
const oldSaves = forest.gateways![0].postCenters.flatMap(([x, y]) =>
  [[0, 0], [-4, 0], [4, 0], [0, -4], [0, 4]].map(([dx, dy]) => ({ x: x + dx, y: y + dy })),
);
function reachesSpawn(start: LandPosition) {
  const nodes = [start, forest.spawn, ...forest.routes.flat().map(point)];
  for (const [x, y] of forest.gateways![0].postCenters)
    for (let direction = 0; direction < 16; direction++) {
      const angle = direction * Math.PI / 8;
      const p = { x: x + 40 * Math.cos(angle), y: y + 40 * Math.sin(angle) };
      if (isLandWalkable(forest, p, 13)) nodes.push(p);
    }
  const seen = new Set([0]), queue = [0];
  while (queue.length) {
    const index = queue.shift()!;
    if (index === 1) return true;
    for (let next = 1; next < nodes.length; next++)
      if (!seen.has(next) && isLandSegmentWalkable(forest, nodes[index], nodes[next], 13)) {
        seen.add(next); queue.push(next);
      }
  }
  return false;
}

test("both gateways share real road orientation and authoritative collision openings", () => {
  assert.equal(LAND_MAPS.hub.layoutVersion, 10);
  assert.equal(forest.layoutVersion, 6);
  for (const map of Object.values(LAND_MAPS)) {
    assert.equal(map.gateways!.length, 1);
    const gate = map.gateways![0];
    const a = point(gate.crossing[0]), b = point(gate.crossing[1]);
    assert.ok(isLandSegmentWalkable(map, a, b, 13), `${gate.id} forward`);
    assert.ok(isLandSegmentWalkable(map, b, a, 13), `${gate.id} reverse`);
    const posts = gate.colliderIds.map((id) => map.obstacles.find((o) => o.id === id)!);
    for (const [index, post] of posts.entries()) {
      assert.ok(post, gate.colliderIds[index]);
      assert.equal(isLandWalkable(map, point(gate.postCenters[index]), 13), false);
      for (const corner of gate.postFootprints[index]) {
        assert.ok(landPointInPolygon(point(corner), post.footprint), `${gate.id} visual base stays inside its collider`);
        assert.ok(map.surfaces.some((s) => s.walkable !== false && landPointInPolygon(point(corner), s.polygon)), `${gate.id} base has real floor`);
      }
    }
    const [p, q] = gate.postCenters;
    const span = [q[0] - p[0], -(q[1] - p[1]) / Math.cos(55 * Math.PI / 180)];
    const [r, s] = gate.route.segment;
    const along = [s[0] - r[0], -(s[1] - r[1]) / Math.cos(55 * Math.PI / 180)];
    assert.ok(Math.abs((span[0] * along[0] + span[1] * along[1]) / Math.hypot(...span) / Math.hypot(...along)) < 1e-10);
  }
});

test("hub gateway paint follows the actual route and narrows inside unchanged fence clearance", () => {
  const map = LAND_MAPS.hub, gate = map.gateways![0];
  assert.deepEqual(gate.center, [2295, 135]);
  const road = map.surfaces.find((s) => s.id === gate.roadSurfaceId)!;
  assert.ok(Math.abs(gate.roadSection[0] + 26) < 1e-8);
  assert.ok(Math.abs(gate.roadSection[1] - 26) < 1e-8);
  for (let y = 125; y <= 230; y += 5) {
    assert.ok(landPointInPolygon({ x: 2295, y }, road.polygon));
    assert.ok(isLandWalkable(map, { x: 2295, y }, 13));
  }
  const pieces = map.surfaces.filter((s) => s.id.startsWith("hub_ridge_trail_"));
  for (let i = 1; i < pieces.length; i++) {
    assert.deepEqual(pieces[i - 1].polygon[2], pieces[i].polygon[1]);
    assert.deepEqual(pieces[i - 1].polygon[3], pieces[i].polygon[0]);
  }
});

test("new forest posts recover frozen layout5 saves onto connected client-clear floor", () => {
  assert.equal(old.layoutVersion, 5);
  assert.deepEqual(forest.surfaces, old.surfaces);
  assert.deepEqual(forest.spawn, old.spawn);
  assert.deepEqual(forest.routes, old.routes);
  assert.deepEqual(forest.obstacles.filter((o) => o.variant !== "gateway_post"), old.obstacles);
  assert.equal(oldSaves.length, 10);
  for (const previous of oldSaves) {
    assert.ok(isLandWalkable(old, previous, 13));
    assert.equal(isLandWalkable(forest, previous, 13), false);
    const safe = nearestSafeLandPoint(forest, previous);
    assert.ok(isLandWalkable(forest, safe, 13));
    assert.ok(Math.hypot(safe.x - previous.x, safe.y - previous.y) <= 32.001);
    assert.ok(reachesSpawn(safe), "Recovery must connect to the real forest spawn");
  }
});

test("forest layout5 gate saves migrate through real API and persist legal movement without reward changes", { timeout: 30000 }, async (t) => {
  const run = randomUUID().replaceAll("-", ""), database = `jalasmara_gateway_${run}`;
  const previousEnv = Object.fromEntries(["NODE_ENV", "APP_ORIGIN", "MONGO_URL", "REDIS_URL"].map((key) => [key, process.env[key]]));
  const mongo = new URL(process.env.TEST_MONGO_URL ?? "mongodb://127.0.0.1:27018/unused?replicaSet=rs0");
  mongo.pathname = `/${database}`;
  process.env.NODE_ENV = "test"; process.env.APP_ORIGIN = "http://localhost:5173";
  process.env.MONGO_URL = mongo.toString();
  process.env.REDIS_URL = process.env.TEST_REDIS_URL ?? "redis://127.0.0.1:6380/14";
  const id = randomUUID(), remoteAddress = `fd00:${run.match(/.{4}/g)!.slice(0, 5).join(":")}::1`;
  const keys = new Set([`surface:${id}`, `calendar:writer:${id}`]);
  let store: Store | undefined, app: Awaited<ReturnType<typeof buildApp>> | undefined;
  try {
    store = await connect(); assert.equal(store.db.databaseName, database); await seed(store);
    app = await buildApp(store, false); await app.ready();
    const cookies: Record<string, string> = {}; let csrf = "";
    async function request(path: string, payload?: Record<string, unknown>) {
      const response = await app!.inject({ method: payload ? "POST" : "GET", url: `/api${path}`, remoteAddress,
        headers: { cookie: Object.entries(cookies).map(([k, v]) => `${k}=${v}`).join("; "), origin: store!.cfg.origin, "x-csrf-token": csrf }, payload });
      for (const cookie of response.cookies) { cookies[cookie.name] = cookie.value; if (cookie.name === "jalasmara") keys.add(`auth:${digest(cookie.value)}`); }
      const data = response.json(); if (data.csrf) csrf = data.csrf;
      return { status: response.statusCode, data };
    }
    const now = new Date().toISOString(), password = randomUUID();
    const user: User = { id, email: `${id}@gateway.test.invalid`, name: "Penguji Gapura", role: "player", status: "active", coins: 423,
      inventory: [{ fragmentId: "klorofil", stars: 3, quantity: 2 }], abilities: freshAbilities(),
      progress: { ...freshProgress(), tutorial: true, day: 2, missions: ["malam_1"] }, version: 7, authVersion: 0,
      passwordHash: await argon2.hash(password, { type: argon2.argon2id }), createdAt: now, updatedAt: now };
    await store.users.insertOne(user);
    assert.equal((await request("/auth/session")).status, 200);
    assert.equal((await request("/auth/login", { email: user.email, password })).status, 200);
    assert.equal((await request("/adventure/state")).status, 200);
    const before = await store.users.findOne({ id });
    for (const previous of oldSaves) {
      const at = Date.now() - 5000;
      await store.redis.set(`surface:${id}`, JSON.stringify({ area: "forest", ...previous, layoutVersion: 5, playerVersion: 7, positionAt: at }), "EX", 1800);
      const resumed = await request("/adventure/state"); assert.equal(resumed.status, 200);
      const saved = resumed.data.surface;
      assert.equal(saved.layoutVersion, 6); assert.equal(saved.area, "forest"); assert.ok(saved.positionAt > at);
      assert.ok(isLandWalkable(forest, saved, 13)); assert.ok(reachesSpawn(saved));
      assert.deepEqual({ x: saved.x, y: saved.y }, nearestSafeLandPoint(forest, previous));
      assert.deepEqual((await request("/adventure/state")).data.surface, saved);
      const stale = await request("/adventure/surface-position", { area: "forest", x: saved.x, y: saved.y, version: 7, fromPositionAt: at });
      assert.equal(stale.status, 409); assert.equal(stale.data.code, "POSITION_CHANGED");
      const blocked = await request("/adventure/surface-position", { area: "forest", ...previous, version: 7, fromPositionAt: saved.positionAt });
      assert.equal(blocked.status, 409); assert.equal(blocked.data.code, "PATH_BLOCKED");
      let destination: LandPosition | undefined;
      for (let direction = 0; direction < 16; direction++) {
        const angle = direction * Math.PI / 8, candidate = { x: saved.x + Math.cos(angle) * 8, y: saved.y + Math.sin(angle) * 8 };
        if (isLandSegmentWalkable(forest, saved, candidate, 13)) { destination = candidate; break; }
      }
      assert.ok(destination);
      const moved = await request("/adventure/surface-position", { area: "forest", ...destination, version: 7, fromPositionAt: saved.positionAt });
      assert.equal(moved.status, 200, JSON.stringify(moved.data));
      assert.deepEqual({ x: moved.data.surface.x, y: moved.data.surface.y }, destination);
      assert.deepEqual((await request("/adventure/state")).data.surface, moved.data.surface);
      assert.deepEqual(await store.users.findOne({ id }), before);
    }
    t.diagnostic("Ten frozen layout5 gate saves migrated, rejected stale/blocked paths, moved and reloaded unchanged player state");
  } finally {
    if (app) await app.close();
    if (store) {
      let cursor = "0";
      do { const result = await store.redis.scan(cursor, "MATCH", `*${remoteAddress}*`, "COUNT", 100); cursor = result[0]; result[1].forEach((key) => keys.add(key)); } while (cursor !== "0");
      await store.redis.del(...keys); assert.equal(store.db.databaseName, database); await store.db.dropDatabase(); await close(store);
    }
    for (const [key, value] of Object.entries(previousEnv)) { if (value === undefined) delete process.env[key]; else process.env[key] = value; }
  }
});
