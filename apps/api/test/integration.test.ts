import { test, before, after } from "node:test";
import assert from "node:assert/strict";
import { randomUUID } from "node:crypto";
import { mkdtempSync, mkdirSync, writeFileSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { get } from "node:http";
import { gzipSync, gunzipSync } from "node:zlib";
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
import { seedCatalog, catalogSchema } from "../src/content.js";
import {
  freshAbilities,
  freshProgress,
} from "../../../packages/shared/src/index.js";
import type { FastifyInstance } from "fastify";
import { WORLD } from "../../../packages/shared/src/world.js";
import {
  isLandWalkable,
  isLandSegmentWalkable,
  landPointInPolygon,
  landDistanceToSegment,
  nearestSafeLandPoint,
} from "../../../packages/shared/src/land.js";
import { hubRoute } from "../../../scripts/game-navigation.mjs";
import { distanceToEdge } from "../src/geometry.js";
process.env.NODE_ENV = "test";
process.env.APP_ORIGIN = "http://localhost:5173";
process.env.MONGO_URL =
  process.env.TEST_MONGO_URL ??
  `mongodb://127.0.0.1:27018/jalasmara_test_${randomUUID().replaceAll("-", "")}?replicaSet=rs0`;
process.env.REDIS_URL =
  process.env.TEST_REDIS_URL ?? "redis://127.0.0.1:6380/14";
let s: Store,
  app: FastifyInstance,
  owner: User,
  admin: User,
  pass = opaque();
const runAddress = `fd00:${randomUUID().replaceAll("-", "").match(/.{4}/g)!.slice(0, 5).join(":")}`;
let ip = 0;
class Browser {
  cookies: Record<string, string> = {};
  csrf = "";
  remoteAddress = `${runAddress}::${(++ip).toString(16)}`;
  async request(
    path: string,
    body?: unknown,
    method = body === undefined ? "GET" : "POST",
    key = randomUUID(),
  ) {
    const r = await app.inject({
      method: method as any,
      url: `/api${path}`,
      remoteAddress: this.remoteAddress,
      headers: {
        cookie: Object.entries(this.cookies)
          .map(([k, v]) => `${k}=${v}`)
          .join("; "),
        origin: s.cfg.origin,
        "x-csrf-token": this.csrf,
        "idempotency-key": key,
      },
      payload: body as any,
    });
    for (const c of r.cookies) this.cookies[c.name] = c.value;
    let data: any;
    try {
      data = r.json();
    } catch {
      data = r.body;
    }
    if (data.csrf) this.csrf = data.csrf;
    return { status: r.statusCode, data, r };
  }
  async login(u: User) {
    await this.request("/auth/session");
    const r = await this.request("/auth/login", {
      email: u.email,
      password: pass,
    });
    assert.equal(r.status, 200, JSON.stringify(r.data));
    return this;
  }
}
async function account(role: User["role"] = "player") {
  const now = new Date().toISOString(),
    id = randomUUID();
  const u: User = {
    id,
    email: `${id}@test.invalid`,
    name: `Pemain ${id.slice(0, 5)}`,
    role,
    status: "active",
    coins: 0,
    inventory: [],
    abilities: freshAbilities(),
    progress: { ...freshProgress(), tutorial: true },
    version: 0,
    authVersion: 0,
    passwordHash: await argon2.hash(pass, { type: argon2.argon2id }),
    createdAt: now,
    updatedAt: now,
  };
  await s.users.insertOne(u);
  return u;
}
async function manager() {
  return new Browser().login(owner);
}
async function start(b: Browser, mode = "dive") {
  const r = await b.request("/dive/start", { mode });
  assert.equal(r.status, 200, JSON.stringify(r.data));
  return r.data.dive;
}
async function fixturePosition(b: Browser, point: { x: number; y: number }) {
  const id = (await b.request("/auth/session")).data.user.id;
  const d = JSON.parse((await s.redis.get(`dive:${id}`))!);
  d.position = { x: point.x, y: point.y };
  await s.redis.set(`dive:${id}`, JSON.stringify(d), "KEEPTTL");
}
async function observe(b: Browser, d: any, id: string, settings?: number[]) {
  const point = [...WORLD.landmarks, ...WORLD.puzzles, ...WORLD.caches].find(
    (x) => x.id === id,
  )!;
  await fixturePosition(b, point);
  return b.request("/adventure/interact", {
    diveId: d.id,
    id,
    ...(settings ? { settings } : {}),
  });
}
async function answer(b: Browser, d: any, target: any, correct = true) {
  await fixturePosition(b, target);
  const r = await b.request("/dive/challenge", {
    diveId: d.id,
    targetId: target.id,
  });
  assert.equal(r.status, 200, JSON.stringify(r.data));
  const challenge = r.data.dive.challenge;
  const q = (await s.contents.findOne({
    id: d.contentId,
  }))!.catalog.questions.find((q) => q.id === challenge.question.id)!;
  const result = await b.request("/dive/catch", {
    diveId: d.id,
    challengeId: challenge.id,
    selectedOption: correct ? q.correctIndex : (q.correctIndex + 1) % 4,
  });
  assert.equal(result.status, 200, JSON.stringify(result.data));
  return result.data.dive;
}
async function continueDive(b: Browser, d: any) {
  const r = await b.request("/dive/continue", {
    diveId: d.id,
    challengeId: d.challenge.id,
  });
  assert.equal(r.status, 200);
  return r.data.dive;
}
async function change(b: Browser, u: User, body: any, key?: string) {
  const p = await s.users.findOne({ id: u.id });
  return b.request(
    `/admin/players/${u.id}/change`,
    { version: p!.version, reason: "Pengujian pemulihan pemain", ...body },
    "POST",
    key,
  );
}
before(async () => {
  s = await connect();
  await seed(s);
  app = await buildApp(s, false);
  await app.ready();
  owner = await account("owner");
  admin = await account("admin");
});
after(async () => {
  await app.close();
  await s.db.dropDatabase();
  await close(s);
});
test("60 soal valid dan setiap kunci jawaban tetap cocok setelah rotasi opsi", () => {
  const c = seedCatalog();
  assert.equal(c.questions.length, 60);
  assert.equal(catalogSchema.safeParse(c).success, true);
  assert.equal(new Set(c.questions.map((q) => q.id)).size, 60);
  assert(
    c.questions.every(
      (q) => q.options[q.correctIndex] && q.source.startsWith("https://"),
    ),
  );
});
test("CSRF menolak origin dan token yang salah; cookie tidak dapat diakses JavaScript", async () => {
  const b = await manager();
  const r = await app.inject({
    method: "POST",
    url: "/api/auth/logout",
    headers: {
      origin: "https://evil.invalid",
      cookie: `jalasmara=${b.cookies.jalasmara}`,
      "x-csrf-token": b.csrf,
    },
    payload: {},
  });
  assert.equal(r.statusCode, 403);
  const session = await b.request("/auth/session");
  assert.equal(session.status, 200);
  const login = await b.request("/auth/login", {
    email: owner.email,
    password: pass,
  });
  assert(login.r.cookies.some((c) => c.name === "jalasmara" && c.httpOnly));
  assert.equal(
    (
      await app.inject({
        method: "POST",
        url: "/api/auth/logout",
        headers: { origin: s.cfg.origin },
        payload: {},
      })
    ).statusCode,
    403,
  );
});
test("pemain ditolak admin; admin ditolak undangan, reset, peran, dan perubahan owner", async () => {
  const p = await account(),
    pb = await new Browser().login(p),
    ab = await new Browser().login(admin);
  assert.equal((await pb.request("/admin/players")).status, 403);
  assert.equal(
    (
      await ab.request("/admin/invitations", {
        email: "other@test.invalid",
        reason: "Uji hak akses",
      })
    ).status,
    403,
  );
  assert.equal(
    (
      await ab.request(`/admin/players/${p.id}/reset-password`, {
        reason: "Uji hak akses",
      })
    ).status,
    403,
  );
  assert.equal(
    (await change(ab, p, { action: "role", role: "admin" })).status,
    403,
  );
  assert.equal(
    (await change(ab, owner, { action: "coins", mode: "add", amount: 100 }))
      .status,
    403,
  );
});
test("undangan dirotasi, sekali pakai, tanpa pendaftaran publik", async () => {
  const b = await manager(),
    email = `${randomUUID()}@test.invalid`;
  const first = await b.request("/admin/invitations", {
    email,
    reason: "Undangan untuk pengujian",
  });
  const second = await b.request("/admin/invitations", {
    email,
    reason: "Kirim ulang undangan",
  });
  const guest = new Browser();
  await guest.request("/auth/session");
  const activation = { name: "Nala Uji", password: pass };
  assert.equal(
    (
      await guest.request("/auth/activate", {
        ...activation,
        token: first.data.url.split("#")[1],
      })
    ).status,
    400,
  );
  const token = second.data.url.split("#")[1];
  const r = await guest.request("/auth/activate", { ...activation, token });
  assert.equal(r.status, 200);
  assert.equal(r.data.user.role, "player");
  assert.equal(
    (await guest.request("/auth/activate", { ...activation, token })).status,
    400,
  );
  assert.equal(
    (await guest.request("/auth/register", { email, password: pass })).status,
    404,
  );
});
test("token kedaluwarsa ditolak dan reset mencabut seluruh sesi", async () => {
  const b = await manager(),
    p = await account(),
    player = await new Browser().login(p),
    other = await new Browser().login(p);
  const link = await b.request(`/admin/players/${p.id}/reset-password`, {
    reason: "Pemulihan untuk pengujian",
  });
  const token = link.data.url.split("#")[1];
  await s.tokens.updateOne(
    { _id: digest(token) },
    { $set: { expiresAt: new Date(Date.now() - 1000) } },
  );
  const guest = new Browser();
  await guest.request("/auth/session");
  assert.equal(
    (await guest.request("/auth/reset", { token, password: pass })).status,
    400,
  );
  const next = await b.request(`/admin/players/${p.id}/reset-password`, {
    reason: "Terbitkan kembali reset",
  });
  const r = await guest.request("/auth/reset", {
    token: next.data.url.split("#")[1],
    password: pass,
  });
  assert.equal(r.status, 200);
  assert.equal((await player.request("/game/state")).status, 401);
  assert.equal((await other.request("/game/state")).status, 401);
  assert.equal(
    (
      await guest.request("/auth/reset", {
        token: next.data.url.split("#")[1],
        password: pass,
      })
    ).status,
    400,
  );
  assert.equal(
    (
      await b.request(`/admin/players/${owner.id}/reset-password`, {
        reason: "Percobaan reset owner",
      })
    ).status,
    403,
  );
});
test("login lokal tetap berfungsi tanpa ZITADEL; penautan memerlukan sesi", async () => {
  const b = await new Browser().login(await account());
  assert.equal((await b.request("/auth/session")).data.oidcEnabled, false);
  assert.equal(
    (await new Browser().request("/auth/oidc/start?mode=link")).status,
    401,
  );
  assert.equal((await b.request("/auth/oidc/start")).status, 404);
  assert.equal(
    (await b.request("/auth/reauth", { password: "password yang salah" }))
      .status,
    401,
  );
});
test("soal tidak membocorkan kunci; bintang, penalti, replay, dan kepemilikan divalidasi", async () => {
  const u = await account(),
    b = await new Browser().login(u),
    other = await new Browser().login(await account());
  let d = await start(b);
  assert(!JSON.stringify(d).includes("correctIndex"));
  assert.equal(
    (
      await other.request("/dive/challenge", {
        diveId: d.id,
        targetId: d.targets[0].id,
      })
    ).status,
    410,
  );
  const initial = d.oxygen;
  d = await answer(b, d, d.targets[0], false);
  assert.equal(d.challenge.result.stars, 1);
  assert(d.oxygen < initial - 7);
  assert.equal(d.loot[0].quantity, 1);
  const duplicate = await b.request("/dive/catch", {
    diveId: d.id,
    challengeId: d.challenge.id,
    selectedOption: 0,
  });
  assert.equal(duplicate.data.dive.loot[0].quantity, 1);
  d = await continueDive(b, d);
  const moved = JSON.parse((await s.redis.get(`dive:${u.id}`))!);
  moved.position = { x: d.targets[1].x, y: d.targets[1].y };
  await s.redis.set(`dive:${u.id}`, JSON.stringify(moved), "KEEPTTL");
  const prompt = await b.request("/dive/challenge", {
    diveId: d.id,
    targetId: d.targets[1].id,
  });
  assert(!("correctIndex" in prompt.data.dive.challenge.question));
  const raw = JSON.parse((await s.redis.get(`dive:${u.id}`))!);
  raw.challenge.startedAt -= raw.challenge.question.timeLimitMs + 1000;
  await s.redis.set(`dive:${u.id}`, JSON.stringify(raw), "EX", 1800);
  const slow = await b.request("/dive/catch", {
    diveId: d.id,
    challengeId: raw.challenge.id,
    selectedOption: raw.challenge.question.correctIndex,
  });
  assert.equal(slow.data.dive.challenge.result.stars, 2);
});
test("server menolak klaim waktu, koin, atau status ekstraksi dari klien", async () => {
  const b = await new Browser().login(await account()),
    d = await start(b);
  assert.equal(
    (
      await b.request("/dive/catch", {
        diveId: d.id,
        challengeId: randomUUID(),
        selectedOption: 0,
        timeTakenMs: 0,
      })
    ).status,
    400,
  );
  assert.equal(
    (await b.request("/dive/extract", { diveId: d.id, status: "success" }))
      .status,
    400,
  );
  assert.equal(
    (
      await b.request("/kedai/close-shift", {
        shiftId: randomUUID(),
        coins_earned: 999999,
      })
    ).status,
    400,
  );
});
test("ekstraksi idempoten dan mempertahankan hanya satu item ketika oksigen habis", async () => {
  const u = await account(),
    b = await new Browser().login(u);
  let d = await start(b);
  for (const target of d.targets.slice(0, 3)) {
    d = await answer(b, d, target);
    d = await continueDive(b, d);
  }
  const raw = JSON.parse((await s.redis.get(`dive:${u.id}`))!);
  raw.oxygen = 0;
  await s.redis.set(`dive:${u.id}`, JSON.stringify(raw), "EX", 1800);
  const key = randomUUID(),
    r = await b.request("/dive/extract", { diveId: d.id }, "POST", key);
  assert.equal(r.status, 200);
  assert.equal(r.data.fainted, true);
  assert.equal(
    r.data.player.inventory.reduce((n: number, x: any) => n + x.quantity, 0),
    1,
  );
  const replay = await b.request(
    "/dive/extract",
    { diveId: d.id },
    "POST",
    key,
  );
  assert.deepEqual(replay.data, r.data);
  assert.equal(
    (await b.request("/dive/extract", { diveId: d.id })).status,
    410,
  );
});
test("admin mengubah koin secara idempoten, memvalidasi versi, dan menulis audit atomik", async () => {
  const u = await account(),
    b = await manager(),
    key = randomUUID(),
    body = {
      version: 0,
      reason: "Kompensasi laporan pemain",
      action: "coins",
      mode: "add",
      amount: 350,
    };
  const first = await b.request(
    `/admin/players/${u.id}/change`,
    body,
    "POST",
    key,
  );
  assert.equal(first.status, 200);
  assert.equal(first.data.player.coins, 350);
  assert.deepEqual(
    (await b.request(`/admin/players/${u.id}/change`, body, "POST", key)).data,
    first.data,
  );
  assert.equal(
    (
      await b.request(
        `/admin/players/${u.id}/change`,
        { ...body, amount: 500 },
        "POST",
        key,
      )
    ).status,
    409,
  );
  assert.equal(
    (await b.request(`/admin/players/${u.id}/change`, body)).status,
    409,
  );
  const count = await s.audits.countDocuments({ target: u.id });
  assert.equal(count, 1);
  assert.equal(
    (await change(b, u, { action: "coins", mode: "subtract", amount: 999 }))
      .status,
    400,
  );
  assert.equal(await s.audits.countDocuments({ target: u.id }), count);
  assert.equal((await s.users.findOne({ id: u.id }))!.coins, 350);
});
test("perubahan admin membatalkan sesi lama dan ekstraksi terlambat", async () => {
  const u = await account(),
    b = await new Browser().login(u),
    m = await manager();
  const d = await start(b);
  assert.equal(
    (
      await change(m, u, {
        action: "inventory",
        fragmentId: "klorofil",
        stars: 3,
        mode: "add",
        amount: 5,
      })
    ).status,
    200,
  );
  assert.equal(
    (
      await b.request("/dive/challenge", {
        diveId: d.id,
        targetId: d.targets[0].id,
      })
    ).data.code,
    "SESSION_CHANGED",
  );
  assert.equal(
    (await b.request("/dive/extract", { diveId: d.id })).status,
    410,
  );
  assert.equal(
    (await b.request("/game/state")).data.player.inventory[0].quantity,
    5,
  );
});
test("semua kontrol admin mematuhi batas dan owner mengendalikan peran", async () => {
  const u = await account(),
    b = await manager(),
    p = await new Browser().login(u);
  assert.equal(
    (await change(b, u, { action: "ability", ability: "oxygen", level: 3 }))
      .status,
    200,
  );
  assert.equal(
    (await change(b, u, { action: "ability", ability: "oxygen", level: 4 }))
      .status,
    400,
  );
  assert.equal(
    (
      await change(b, u, {
        action: "inventory",
        fragmentId: "tidak_ada",
        stars: 3,
        mode: "add",
        amount: 1,
      })
    ).status,
    400,
  );
  assert.equal(
    (
      await change(b, u, {
        action: "progress",
        progress: { ...freshProgress(), day: 3, stage: "boss", tutorial: true },
      })
    ).status,
    200,
  );
  assert.equal((await change(b, u, { action: "block" })).status, 200);
  assert.equal((await p.request("/game/state")).status, 401);
  assert.equal((await change(b, u, { action: "unblock" })).status, 200);
  await p.login(u);
  assert.equal((await change(b, u, { action: "revoke" })).status, 200);
  assert.equal((await p.request("/game/state")).status, 401);
  assert.equal(
    (await change(b, u, { action: "role", role: "admin" })).status,
    200,
  );
  assert.equal((await change(b, u, { action: "reset" })).data.player.coins, 0);
});
test("transaksi dan audit dibatalkan bersama ketika penyimpanan audit gagal", async () => {
  const u = await account(),
    b = await manager();
  await s.db.command({
    collMod: "audits",
    validator: { action: { $eq: "never_allowed" } },
    validationLevel: "strict",
  });
  try {
    const r = await change(b, u, { action: "coins", mode: "add", amount: 123 });
    assert.equal(r.status, 500);
    assert.equal((await s.users.findOne({ id: u.id }))!.coins, 0);
  } finally {
    await s.db.command({
      collMod: "audits",
      validator: {},
      validationLevel: "strict",
    });
  }
});
test("draft, konflik editor, validasi referensi, publikasi, dan snapshot sesi", async () => {
  const m = await manager(),
    b = await new Browser().login(await account()),
    d = await start(b),
    old = await s.contents.findOne({ state: "published" });
  const draft = await m.request("/admin/content/draft", {
    sourceId: old!.id,
    label: "Versi uji",
    reason: "Peninjauan konten baru",
  });
  assert.equal(draft.status, 200);
  const c = structuredClone(draft.data.content.catalog);
  c.balance.wrongPenalty = 11;
  let save = await m.request(
    `/admin/content/${draft.data.content.id}`,
    { catalog: c, hash: draft.data.hash, reason: "Ubah penalti kuis" },
    "PUT",
  );
  assert.equal(save.status, 200);
  assert.equal(
    (
      await m.request(
        `/admin/content/${draft.data.content.id}`,
        { catalog: c, hash: draft.data.hash, reason: "Simpan versi lama" },
        "PUT",
      )
    ).status,
    409,
  );
  assert.equal(
    (
      await m.request(`/admin/content/${draft.data.content.id}/publish`, {
        hash: save.data.hash,
        reason: "Publikasi setelah tinjauan",
      })
    ).status,
    200,
  );
  assert.equal(
    (await b.request("/game/state")).data.dive.contentId,
    d.contentId,
  );
  const malformed = structuredClone(c);
  malformed.questions[0].fragmentId = "tidak_ada";
  assert.equal(
    (
      await m.request("/admin/questions/validate", [
        { ...c.questions[0], correctIndex: 9 },
      ])
    ).status,
    400,
  );
  assert.equal(catalogSchema.safeParse(malformed).success, false);
  assert.equal(
    (
      await m.request(`/admin/content/${draft.data.content.id}/archive`, {
        reason: "Tidak boleh arsip aktif",
      })
    ).status,
    409,
  );
});
test("tiga siklus siang-malam, anti-farming pelanggan, upgrade, dan boss sampai tamat", async () => {
  const u = await account(),
    b = await new Browser().login(u);
  for (let day = 1; day <= 3; day++) {
    let d = await start(b);
    for (const target of d.targets.slice(0, 3)) {
      d = await answer(b, d, target);
      d = await continueDive(b, d);
    }
    if (day === 2)
      for (const id of ["nitrogen", "photosynthesis", "osmosis"])
        assert.equal((await observe(b, d, id)).status, 200);
    if (day === 3) {
      assert.equal((await observe(b, d, "corporate_pipe")).status, 200);
      assert.equal((await observe(b, d, "filter", [0, 1, 2])).status, 200);
    }
    await fixturePosition(b, WORLD.spawn);
    assert.equal(
      (await b.request("/dive/extract", { diveId: d.id })).status,
      200,
    );
    let r = await b.request("/kedai/start", {});
    assert.equal(r.status, 200);
    let shift = r.data.shift;
    let state = (await b.request("/game/state")).data;
    for (let i = 0; i < shift.customers.length; i++) {
      const customer = shift.customers[i],
        item = state.player.inventory.find(
          (x: any) => x.fragmentId === customer.fragmentId,
        );
      const key = randomUUID(),
        body = {
          shiftId: shift.id,
          recipeId: customer.id,
          fragmentId: item.fragmentId,
          stars: item.stars,
        };
      r = await b.request("/kedai/serve", body, "POST", key);
      assert.equal(r.status, 200, JSON.stringify(r.data));
      assert.deepEqual(
        (await b.request("/kedai/serve", body, "POST", key)).data,
        r.data,
      );
      state.player = r.data.player;
      shift = r.data.shift;
      if (i === 0 && day === 1) {
        await b.request("/kedai/close-shift", {
          shiftId: shift.id,
          abandon: true,
        });
        shift = (await b.request("/kedai/start", {})).data.shift;
        assert(shift.served.includes(customer.id));
        assert.equal(
          (await b.request("/kedai/serve", { ...body, shiftId: shift.id }))
            .status,
          409,
        );
      }
    }
    assert.equal(
      (await b.request("/kedai/close-shift", { shiftId: shift.id })).status,
      200,
    );
    if (day === 1)
      assert.equal(
        (await b.request("/game/upgrade", { ability: "oxygen" })).status,
        200,
      );
  }
  const m = await manager();
  await change(m, u, { action: "coins", mode: "add", amount: 3000 });
  for (const ability of ["oxygen", "net"]) {
    while (
      (await s.users.findOne({ id: u.id }))!.abilities[
        ability as "oxygen" | "net"
      ] < 3
    )
      assert.equal((await b.request("/game/upgrade", { ability })).status, 200);
  }
  let boss = await start(b, "boss");
  assert.equal(boss.mode, "boss");
  for (const target of boss.targets) {
    boss = await answer(b, boss, target);
    boss = await continueDive(b, boss);
  }
  const result = await b.request("/dive/extract", { diveId: boss.id });
  assert.equal(result.status, 200);
  assert.equal(result.data.player.progress.stage, "done");
  assert.equal(result.data.victory, true);
  assert.equal(
    result.data.player.progress.missions.includes("gajah_mina"),
    true,
  );
});

test("eksplorasi memvalidasi jangkauan, hadiah sekali, gerakan, dan jala biasa tanpa kuis", async () => {
  const u = await account(),
    b = await new Browser().login(u),
    d = await start(b);
  assert.equal(
    (await b.request("/dive/position", { diveId: d.id, x: 6000, y: 500 })).data
      .code,
    "POSITION",
  );
  assert.equal(
    (await b.request("/dive/position", { diveId: d.id, x: 1120, y: 1400 })).data
      .code,
    "ZONE_LOCKED",
  );
  assert.equal(
    (await b.request("/adventure/interact", { diveId: d.id, id: "nitrogen" }))
      .status,
    409,
  );
  const state = (await b.request("/adventure/state")).data;
  assert(!JSON.stringify(state.world.puzzles).includes("correct"));
  for (const t of d.targets)
    assert(
      !WORLD.terrain.some(
        ([x, y, w, h]) => t.x > x && t.x < x + w && t.y > y && t.y < y + h,
      ),
    );
  const found = await observe(b, d, "cell");
  assert.equal(found.data.reward, 80);
  assert.equal((await observe(b, d, "cell")).data.reward, 0);
  await fixturePosition(b, d.targets[0]);
  assert.equal(
    (
      await b.request("/dive/collect", {
        diveId: d.id,
        targetId: d.targets[0].id,
      })
    ).status,
    409,
  );
  assert.equal(
    (await b.request("/dive/net/start", { diveId: d.id })).status,
    200,
  );
  const raw = JSON.parse((await s.redis.get(`dive:${u.id}`))!);
  raw.netAt = Date.now() - 800;
  await s.redis.set(`dive:${u.id}`, JSON.stringify(raw), "KEEPTTL");
  const collected = await b.request("/dive/collect", {
    diveId: d.id,
    targetId: d.targets[0].id,
  });
  assert.equal(collected.status, 200);
  assert.equal(collected.data.stars, 3);
  assert.equal(collected.data.dive.challenge, undefined);
  assert.equal(
    (
      await b.request("/dive/collect", {
        diveId: d.id,
        targetId: d.targets[0].id,
      })
    ).data.dive.weight,
    collected.data.dive.weight,
  );
  await fixturePosition(b, { x: 2000, y: 600 });
  assert.equal(
    (await b.request("/dive/extract", { diveId: d.id })).status,
    409,
  );
});
test("puzzle, bahaya, dan penemuan misi dikendalikan server", async () => {
  const u = await account(),
    b = await new Browser().login(u);
  await s.users.updateOne({ id: u.id }, { $set: { "progress.day": 3 } });
  const d = await start(b);
  const wrong = await observe(b, d, "filter", [2, 1, 0]);
  assert.equal(wrong.data.ok, false);
  assert.equal((await s.users.findOne({ id: u.id }))!.coins, 0);
  assert.equal((await observe(b, d, "filter", [0, 1, 2])).data.reward, 250);
  const before = (await b.request("/game/state")).data.dive.oxygen;
  await fixturePosition(b, WORLD.hazards[2]);
  const hit = await b.request("/dive/hazard", { diveId: d.id });
  assert(hit.data.dive.oxygen < before - 11);
  const repeat = await b.request("/dive/hazard", { diveId: d.id });
  assert(repeat.data.dive.oxygen > hit.data.dive.oxygen - 1);
  await fixturePosition(b, WORLD.spawn);
  await b.request("/dive/extract", { diveId: d.id });
  assert.equal((await b.request("/kedai/start", {})).status, 409);
  const again = await start(b);
  assert.equal((await observe(b, again, "corporate_pipe")).status, 200);
  await fixturePosition(b, WORLD.spawn);
  await b.request("/dive/extract", { diveId: again.id });
  assert.equal((await b.request("/kedai/start", {})).status, 200);
});

test("perubahan admin saat sinkronisasi posisi memuat ulang data tanpa sesi lama", async () => {
  const u = await account(),
    b = await new Browser().login(u),
    m = await manager(),
    d = await start(b);
  assert.equal(
    (await change(m, u, { action: "coins", mode: "add", amount: 30 })).status,
    200,
  );
  assert.equal(
    (await b.request("/dive/position", { diveId: d.id, x: 1120, y: 470 })).data
      .code,
    "SESSION_CHANGED",
  );
  const state = await b.request("/adventure/state");
  assert.equal(state.status, 200);
  assert.equal(state.data.dive, null);
  assert.equal(state.data.player.coins, 30);
});

test("penampilan tersimpan per akun tanpa mengubah kemampuan dan retry idempoten", async () => {
  const u = await account(),
    other = await account(),
    b = await new Browser().login(u);
  assert.equal(
    (await b.request("/game/state")).data.player.appearance,
    undefined,
  );
  for (const appearance of [
    "male_default",
    "male_nusantara",
    "female_default",
    "female_nusantara",
  ] as const) {
    const before = (await s.users.findOne({ id: u.id }))!;
    const key = randomUUID();
    const saved = await b.request(
      "/game/appearance",
      { appearance },
      "POST",
      key,
    );
    assert.equal(saved.status, 200, JSON.stringify(saved.data));
    assert.equal(saved.data.player.appearance, appearance);
    assert.equal(saved.data.player.version, before.version + 1);
    assert.equal(saved.data.player.coins, before.coins);
    assert.deepEqual(saved.data.player.abilities, before.abilities);
    assert.deepEqual(saved.data.player.inventory, before.inventory);
    assert.deepEqual(saved.data.player.progress, before.progress);
    assert.equal(
      (await b.request("/game/appearance", { appearance }, "POST", key)).data
        .player.version,
      saved.data.player.version,
    );
    assert.equal(
      (await b.request("/game/state")).data.player.appearance,
      appearance,
    );
  }
  const secondSession = await new Browser().login(u);
  assert.equal(
    (await secondSession.request("/auth/session")).data.user.appearance,
    "female_nusantara",
  );
  assert.equal(
    (await s.users.findOne({ id: other.id }))!.appearance,
    undefined,
  );
  assert.equal(
    (
      await b.request("/game/appearance", {
        appearance: "male_default",
        userId: other.id,
      })
    ).status,
    400,
  );
  assert.equal(
    (await b.request("/game/appearance", { appearance: "unknown" })).status,
    400,
  );
  const anonymous = new Browser();
  await anonymous.request("/auth/session");
  assert.equal(
    (
      await anonymous.request("/game/appearance", {
        appearance: "male_default",
      })
    ).status,
    401,
  );
});

test("penampilan ditolak selama penyelaman atau giliran kedai aktif dan akun diblokir", async () => {
  const u = await account(),
    b = await new Browser().login(u);
  await start(b);
  const diving = await b.request("/game/appearance", {
    appearance: "male_nusantara",
  });
  assert.equal(diving.status, 409);
  assert.equal(diving.data.code, "ACTIVE_DIVE");
  assert.equal((await s.users.findOne({ id: u.id }))!.appearance, undefined);
  const trader = await account();
  await s.users.updateOne(
    { id: trader.id },
    { $set: { "progress.stage": "night" } },
  );
  const serving = await new Browser().login(trader);
  assert.equal((await serving.request("/kedai/start", {})).status, 200);
  const busy = await serving.request("/game/appearance", {
    appearance: "female_nusantara",
  });
  assert.equal(busy.status, 409);
  assert.equal(busy.data.code, "ACTIVE_SHIFT");
  const blocked = await account(),
    blockedSession = await new Browser().login(blocked);
  await s.users.updateOne({ id: blocked.id }, { $set: { status: "blocked" } });
  assert.equal(
    (
      await blockedSession.request("/game/appearance", {
        appearance: "female_default",
      })
    ).status,
    403,
  );
});

async function fixtureSurface(
  user: User,
  area: "hub" | "forest",
  point: { x: number; y: number },
  agoMs = 2000,
) {
  const current = (await s.users.findOne({ id: user.id }))!;
  await s.redis.set(
    `surface:${user.id}`,
    JSON.stringify({
      area,
      ...point,
      positionAt: Date.now() - agoMs,
      playerVersion: current.version,
      layoutVersion: WORLD.landMaps[area].layoutVersion,
    }),
    "EX",
    1800,
  );
}

test("perjalanan hutan memerlukan gerbang dan gerakan daratan divalidasi server", async () => {
  const u = await account(),
    b = await new Browser().login(u);
  const initial = await b.request("/adventure/state");
  assert.equal(initial.data.surface.area, "hub");
  assert.equal(initial.data.surface.x, WORLD.surfaceSpawn.x);
  assert.equal(
    (
      await b.request("/adventure/surface-position", {
        x: WORLD.surfaceSpawn.x,
        y: WORLD.hub.height + 1,
      })
    ).status,
    400,
  );
  await fixtureSurface(u, "hub", {
    x: WORLD.surfaceSpawn.x,
    y: WORLD.surfaceSpawn.y,
  });
  assert.equal(
    (
      await b.request("/adventure/surface-position", {
        x: WORLD.surfaceSpawn.x,
        y: WORLD.surfaceSpawn.y + 70,
      })
    ).status,
    200,
  );

  assert.equal(
    (await b.request("/adventure/travel", { destination: "forest" })).status,
    409,
  );
  assert.equal(
    (
      await b.request("/adventure/surface-position", {
        area: "forest",
        x: 200,
        y: 1320,
      })
    ).status,
    409,
  );
  assert.equal(
    (await b.request("/adventure/surface-position", { x: 5000, y: 300 }))
      .status,
    400,
  );
  assert.equal(
    (await b.request("/adventure/surface-position", { x: 2100, y: 1230 }))
      .status,
    409,
  );
  await fixtureSurface(u, "hub", WORLD.forest.gate);
  const arrived = await b.request("/adventure/travel", {
    destination: "forest",
  });
  assert.equal(arrived.status, 200, JSON.stringify(arrived.data));
  assert.equal(arrived.data.surface.area, "forest");
  assert.equal(arrived.data.surface.x, WORLD.forest.entry.x);
  assert.equal(
    (await b.request("/adventure/state")).data.surface.area,
    "forest",
  );
  assert.equal(
    (
      await b.request("/adventure/surface-position", {
        area: "forest",
        x: WORLD.forest.width + 1,
        y: 1320,
      })
    ).status,
    400,
  );
  assert.equal(
    (
      await b.request("/adventure/surface-position", {
        area: "forest",
        x: 1800,
        y: 400,
      })
    ).status,
    409,
  );
  await fixtureSurface(u, "forest", WORLD.forest.entry);
  const step = await b.request("/adventure/surface-position", {
    area: "forest",
    x: 350,
    y: 1300,
  });
  assert.equal(step.status, 200, JSON.stringify(step.data));
  assert.ok((await s.redis.ttl(`surface:${u.id}`)) > 1700);
  const returned = await b.request("/adventure/travel", { destination: "hub" });
  assert.equal(returned.status, 200);
  assert.equal(returned.data.surface.x, WORLD.forest.gate.x);
  const anonymous = new Browser();
  await anonymous.request("/auth/session");
  assert.equal(
    (await anonymous.request("/adventure/travel", { destination: "forest" }))
      .status,
    401,
  );
});

test("penemuan hutan memerlukan kedekatan dan hadiah hanya tersimpan sekali", async () => {
  const u = await account(),
    b = await new Browser().login(u),
    landmark = WORLD.forest.landmarks[0];
  assert.equal(
    (await b.request("/adventure/surface-interact", { id: landmark.id }))
      .status,
    409,
  );
  await fixtureSurface(u, "forest", WORLD.forest.entry);
  assert.equal(
    (await b.request("/adventure/surface-interact", { id: landmark.id }))
      .status,
    409,
  );
  await fixtureSurface(u, "forest", landmark);
  assert.equal(
    (await b.request("/adventure/surface-interact", { id: "forest_unknown" }))
      .status,
    404,
  );
  const key = randomUUID(),
    body = { id: landmark.id };
  const found = await b.request(
    "/adventure/surface-interact",
    body,
    "POST",
    key,
  );
  assert.equal(found.status, 200, JSON.stringify(found.data));
  assert.equal(found.data.reward, landmark.reward);
  assert.equal(found.data.knowledge.title, landmark.title);
  assert.ok(found.data.adventure.discoveries.includes(landmark.id));
  const replay = await b.request(
    "/adventure/surface-interact",
    body,
    "POST",
    key,
  );
  assert.deepEqual(replay.data, found.data);
  const again = await b.request("/adventure/surface-interact", body);
  assert.equal(again.status, 200);
  assert.equal(again.data.reward, 0);
  assert.equal(again.data.alreadyFound, true);
  const saved = (await s.users.findOne({ id: u.id }))!;
  assert.equal(saved.coins, landmark.reward);
  assert.equal(saved.version, 1);
  assert.equal(
    saved.adventure!.discoveries.filter((id) => id === landmark.id).length,
    1,
  );
  assert.equal(
    (
      await b.request(
        "/adventure/surface-interact",
        { id: WORLD.forest.landmarks[1].id },
        "POST",
        key,
      )
    ).status,
    409,
  );
});

test("perubahan admin membatalkan posisi hutan lama", async () => {
  const u = await account(),
    b = await new Browser().login(u),
    point = WORLD.forest.landmarks[1];
  await fixtureSurface(u, "forest", point);
  const ownerBrowser = await manager();
  const changed = await ownerBrowser.request(`/admin/players/${u.id}/change`, {
    version: u.version,
    action: "coins",
    mode: "set",
    amount: 0,
    reason: "Menguji pembatalan posisi darat melalui aksi admin",
  });
  assert.equal(changed.status, 200);

  const result = await b.request("/adventure/surface-interact", {
    id: point.id,
  });
  assert.equal(result.status, 409);
  assert.equal((await s.users.findOne({ id: u.id }))!.coins, 0);
  const state = await b.request("/adventure/state");
  assert.equal(state.data.surface.area, "hub");
  assert.equal(state.data.surface.x, WORLD.surfaceSpawn.x);
});

test("daratan ditolak selama penyelaman atau giliran kedai aktif", async () => {
  const diver = await account(),
    b = await new Browser().login(diver);
  await start(b);
  assert.equal(
    (await b.request("/adventure/surface-position", WORLD.surfaceSpawn)).status,
    409,
  );
  assert.equal(
    (await b.request("/adventure/travel", { destination: "forest" })).status,
    409,
  );
  assert.equal(
    (await b.request("/adventure/surface-interact", { id: "forest_cache" }))
      .status,
    409,
  );
  const trader = await account(),
    serving = await new Browser().login(trader);
  await s.users.updateOne(
    { id: trader.id },
    { $set: { "progress.stage": "night" } },
  );
  assert.equal((await serving.request("/kedai/start", {})).status, 200);
  assert.equal(
    (await serving.request("/adventure/surface-position", WORLD.surfaceSpawn))
      .status,
    409,
  );
  assert.equal(
    (await serving.request("/adventure/travel", { destination: "forest" }))
      .status,
    409,
  );
});

test("ganti penampilan di hutan mempertahankan wilayah dan retry tidak mengembalikan posisi lama", async () => {
  const u = await account(),
    b = await new Browser().login(u),
    point = WORLD.forest.landmarks[0];
  await fixtureSurface(u, "forest", point);
  const key = randomUUID(),
    body = { appearance: "female_nusantara" };
  const changed = await b.request("/game/appearance", body, "POST", key);
  assert.equal(changed.status, 200, JSON.stringify(changed.data));
  let state = await b.request("/adventure/state");
  assert.equal(state.data.surface.area, "forest");
  assert.equal(state.data.surface.x, point.x);
  assert.equal(state.data.surface.playerVersion, changed.data.player.version);
  const moved = await b.request("/adventure/surface-position", {
    area: "forest",
    x: point.x + 60,
    y: point.y,
  });
  assert.equal(moved.status, 200);
  const replay = await b.request("/game/appearance", body, "POST", key);
  assert.deepEqual(replay.data, changed.data);
  state = await b.request("/adventure/state");
  assert.equal(state.data.surface.x, point.x + 60);
  assert.equal(state.data.surface.area, "forest");
  assert.equal(state.data.player.version, changed.data.player.version);
  assert.equal(
    (await b.request("/adventure/surface-interact", { id: point.id })).status,
    200,
  );
});

test("fasilitas dermaga menolak permintaan dari hutan tetapi penyelaman aktif tetap dipulihkan", async () => {
  const u = await account(),
    b = await new Browser().login(u);
  await fixtureSurface(u, "forest", WORLD.forest.entry);
  for (const [path, body] of [
    ["/dive/start", { mode: "dive" }],
    ["/game/upgrade", { ability: "oxygen" }],
    ["/kedai/start", {}],
  ] as const) {
    const denied = await b.request(path, body);
    assert.equal(denied.status, 409, `${path}: ${JSON.stringify(denied.data)}`);
    assert.equal(denied.data.code, "HUB_REQUIRED");
  }
  assert.equal(await s.redis.exists(`dive:${u.id}`), 0);
  assert.equal((await s.users.findOne({ id: u.id }))!.version, 0);
  const diver = await account(),
    diving = await new Browser().login(diver);
  const active = await start(diving);
  await fixtureSurface(diver, "forest", WORLD.forest.entry);
  const resumed = await diving.request("/dive/start", { mode: "dive" });
  assert.equal(resumed.status, 200, JSON.stringify(resumed.data));
  assert.equal(resumed.data.dive.id, active.id);
});

test("atlas membuka lapisan cerita menurut hari dan wilayah mendatang tetap terkunci", async () => {
  const u = await account(),
    b = await new Browser().login(u);
  let state = await b.request("/adventure/state");
  const regions = state.data.world.atlas.regions;
  assert.equal(
    regions.find((r: any) => r.id === "city_bandar_hujung").status,
    "open",
  );
  assert.equal(
    regions.find((r: any) => r.id === "kelp_forest").status,
    "story",
  );
  const ids = new Set(regions.map((r: any) => r.id));
  for (const road of state.data.world.atlas.roads) {
    assert.ok(ids.has(road.from));
    assert.ok(ids.has(road.to));
  }
  await s.users.updateOne({ id: u.id }, { $set: { "progress.day": 3 } });
  state = await b.request("/adventure/state");
  for (const region of state.data.world.atlas.regions) {
    if (["kelp_forest", "limestone_cave", "boss_sanctuary"].includes(region.id))
      assert.equal(region.status, "open");
    if (["forest_hulu", "mechanical_ruins", "deep_gate"].includes(region.id))
      assert.equal(region.status, "coming_soon");
  }
});

test("penghalang hutan menolak posisi dan tujuan wilayah mendatang tidak menerima perjalanan", async () => {
  const u = await account(),
    b = await new Browser().login(u);
  for (const exit of WORLD.forest.blockedExits) {
    await fixtureSurface(u, "forest", {
      x: exit.x - exit.width / 2 - 30,
      y: exit.y,
    });
    const blocked = await b.request("/adventure/surface-position", {
      area: "forest",
      x: exit.x,
      y: exit.y,
    });
    assert.equal(blocked.status, 409, JSON.stringify(blocked.data));
    assert.equal(blocked.data.code, "BLOCKED_EXIT");
    assert.equal(blocked.data.error, exit.reason);
    const kept = JSON.parse((await s.redis.get(`surface:${u.id}`))!);
    assert.notEqual(kept.x, exit.x);
  }
  for (const destination of ["forest_hulu", "mechanical_ruins", "deep_gate"])
    assert.equal(
      (await b.request("/adventure/travel", { destination })).status,
      400,
    );
});

test("posisi awal dan reset versi disimpan agar waktu berjalan antarsinkronisasi", async () => {
  const u = await account(),
    b = await new Browser().login(u);
  const state = await b.request("/adventure/state");
  assert.equal(state.status, 200);
  const initialRaw = await s.redis.get(`surface:${u.id}`);
  assert.ok(initialRaw, "state pertama harus menyimpan posisi dan waktu awal");
  const initial = JSON.parse(initialRaw);
  assert.equal(initial.positionAt, state.data.surface.positionAt);
  assert.ok((await s.redis.ttl(`surface:${u.id}`)) > 1700);
  initial.positionAt -= 2200;
  await s.redis.set(`surface:${u.id}`, JSON.stringify(initial), "KEEPTTL");
  const moved = await b.request("/adventure/surface-position", {
    ...WORLD.hub.divePoint,
  });
  assert.equal(moved.status, 200, JSON.stringify(moved.data));
  const teleport = await b.request("/adventure/surface-position", {
    ...WORLD.forest.gate,
  });
  assert.equal(teleport.status, 409);
  assert.equal(teleport.data.code, "POSITION");
  assert.equal(
    JSON.parse((await s.redis.get(`surface:${u.id}`))!).x,
    WORLD.hub.divePoint.x,
  );
  await s.users.updateOne({ id: u.id }, { $inc: { version: 1 } });
  const reset = await b.request("/adventure/state");
  assert.equal(reset.status, 200);
  const resetPoint = JSON.parse((await s.redis.get(`surface:${u.id}`))!);
  assert.equal(resetPoint.x, WORLD.hub.divePoint.x);
  assert.equal(resetPoint.playerVersion, 1);
  assert.equal(resetPoint.positionAt, reset.data.surface.positionAt);
  resetPoint.positionAt -= 2000;
  await s.redis.set(`surface:${u.id}`, JSON.stringify(resetPoint), "KEEPTTL");
  const afterReset = await b.request("/adventure/surface-position", {
    ...WORLD.hub.divePoint,
  });
  assert.equal(afterReset.status, 200, JSON.stringify(afterReset.data));
});

test("gerakan hutan mengikuti koridor jalur dan menolak rumpun di luar jalur", async () => {
  const u = await account(),
    b = await new Browser().login(u);
  await fixtureSurface(u, "forest", { x: 80, y: 180 });
  const blocked = await b.request("/adventure/surface-position", {
    area: "forest",
    x: 80,
    y: 120,
  });
  assert.equal(blocked.status, 409);
  assert.equal(blocked.data.code, "PATH_BLOCKED");
  await fixtureSurface(u, "forest", WORLD.forest.entry);
  const waypoint = WORLD.forest.walkablePaths[0][1];
  const allowed = await b.request("/adventure/surface-position", {
    area: "forest",
    x: waypoint[0],
    y: waypoint[1],
  });
  assert.equal(allowed.status, 200, JSON.stringify(allowed.data));
});

test("sinkronisasi daratan mendeteksi perubahan admin melalui versi klien dan mereset posisi lama", async () => {
  const u = await account(),
    b = await new Browser().login(u),
    ownerBrowser = await manager(),
    point = WORLD.forest.landmarks[0];
  await fixtureSurface(u, "forest", point);
  const oldState = await b.request("/adventure/state"),
    previous = oldState.data.player.version;
  const changed = await ownerBrowser.request(`/admin/players/${u.id}/change`, {
    version: previous,
    action: "coins",
    mode: "add",
    amount: 75,
    reason: "Penyesuaian saldo saat pemain menjelajah hutan",
  });
  assert.equal(changed.status, 200, JSON.stringify(changed.data));
  const stale = await b.request("/adventure/surface-position", {
    area: "forest",
    x: point.x,
    y: point.y,
    version: previous,
  });
  assert.equal(stale.status, 409);
  assert.equal(stale.data.code, "SESSION_CHANGED");
  const persisted = JSON.parse((await s.redis.get(`surface:${u.id}`))!);
  assert.equal(persisted.area, "hub");
  assert.equal(persisted.x, WORLD.surfaceSpawn.x);
  assert.equal(persisted.playerVersion, previous + 1);
  const refreshed = await b.request("/adventure/state");
  assert.equal(refreshed.data.player.coins, 75);
  assert.equal(refreshed.data.player.version, previous + 1);
  const synced = await b.request("/adventure/surface-position", {
    area: "hub",
    ...WORLD.surfaceSpawn,
    version: refreshed.data.player.version,
  });
  assert.equal(synced.status, 200, JSON.stringify(synced.data));
});

test("migrasi tata letak desa hanya mereset posisi lama tanpa mengubah progres atau inventori", async () => {
  const u = await account(),
    b = await new Browser().login(u);
  await s.users.updateOne(
    { id: u.id },
    {
      $set: {
        coins: 1234,
        version: 7,
        appearance: "female_nusantara",
        inventory: [{ fragmentId: "klorofil", stars: 3, quantity: 2 }],
        progress: { ...u.progress, day: 2, missions: ["malam_1"] },
        adventure: {
          discoveries: ["forest_canopy"],
          puzzles: [],
          keyItems: [],
        },
      },
    },
  );
  const before = await s.users.findOne({ id: u.id });
  await s.redis.set(
    `surface:${u.id}`,
    JSON.stringify({
      area: "hub",
      x: 1030,
      y: 295,
      playerVersion: 7,
      positionAt: Date.now() - 5000,
      layoutVersion: WORLD.hub.layoutVersion - 1,
    }),
    "EX",
    1800,
  );
  const migrated = await b.request("/adventure/state");
  assert.equal(migrated.status, 200, JSON.stringify(migrated.data));
  assert.equal(migrated.data.surface.layoutVersion, WORLD.hub.layoutVersion);
  assert.deepEqual(
    { x: migrated.data.surface.x, y: migrated.data.surface.y },
    nearestSafeLandPoint(WORLD.landMaps.hub, { x: 1030, y: 295 }),
  );
  assert.equal(migrated.data.player.coins, 1234);
  assert.equal(migrated.data.player.version, 7);
  assert.deepEqual(await s.users.findOne({ id: u.id }), before);
  const persisted = JSON.parse((await s.redis.get(`surface:${u.id}`))!);
  assert.deepEqual(persisted, migrated.data.surface);
  assert.ok((await s.redis.ttl(`surface:${u.id}`)) > 1700);
  assert.equal(
    (await b.request("/adventure/state")).data.surface.positionAt,
    persisted.positionAt,
  );
  delete persisted.layoutVersion;
  persisted.x = 1030;
  persisted.y = 295;
  await s.redis.set(`surface:${u.id}`, JSON.stringify(persisted), "EX", 1800);
  const unversioned = await b.request("/adventure/state");
  assert.equal(unversioned.data.surface.layoutVersion, WORLD.hub.layoutVersion);
  assert.deepEqual(
    { x: unversioned.data.surface.x, y: unversioned.data.surface.y },
    nearestSafeLandPoint(WORLD.landMaps.hub, { x: 1030, y: 295 }),
  );
  assert.deepEqual(await s.users.findOne({ id: u.id }), before);
  await fixtureSurface(u, "forest", WORLD.forest.landmarks[0]);
  const forest = await b.request("/adventure/state");
  assert.equal(forest.data.surface.area, "forest");
  assert.equal(forest.data.surface.x, WORLD.forest.landmarks[0].x);
});

test("jalur desa menghubungkan gerbang dan menolak bangunan serta tepian air", async () => {
  const u = await account(),
    b = await new Browser().login(u);
  await b.request("/adventure/state");
  for (const [x, y, width, height] of WORLD.hub.obstacles) {
    const blocked = await b.request("/adventure/surface-position", {
      area: "hub",
      x: x + width / 2,
      y: y + height / 2,
    });
    assert.equal(blocked.status, 409);
    assert.equal(blocked.data.code, "PATH_BLOCKED");
  }
  const water = await b.request("/adventure/surface-position", {
    area: "hub",
    x: 60,
    y: 1480,
  });
  assert.equal(water.status, 409);
  assert.equal(water.data.code, "PATH_BLOCKED");
  let previous: { x: number; y: number } = { ...WORLD.surfaceSpawn };
  const destinations = [{ x: 595, y: 650 }, WORLD.forest.gate];
  for (const destination of destinations) {
    for (const [x, y] of hubRoute(WORLD, previous, destination)) {
      const from = previous,
        count = Math.ceil(Math.hypot(x - from.x, y - from.y) / 80);
      for (let step = 1; step <= count; step++) {
        const stored = JSON.parse((await s.redis.get(`surface:${u.id}`))!);
        stored.positionAt -= 1000;
        await s.redis.set(`surface:${u.id}`, JSON.stringify(stored), "KEEPTTL");
        const position = {
          x: from.x + ((x - from.x) * step) / count,
          y: from.y + ((y - from.y) * step) / count,
        };
        const moved = await b.request("/adventure/surface-position", {
          area: "hub",
          ...position,
        });
        assert.equal(
          moved.status,
          200,
          `${JSON.stringify(position)}: ${JSON.stringify(moved.data)}`,
        );
        previous = position;
      }
    }
  }
  assert.equal(
    (await b.request("/adventure/travel", { destination: "forest" })).status,
    200,
  );
});

test("ekstraksi mendarat di dermaga baru dan retry tidak mengembalikan posisi setelah berjalan", async () => {
  const u = await account(),
    b = await new Browser().login(u),
    dive = await start(b),
    key = randomUUID();
  const landed = await b.request(
    "/dive/extract",
    { diveId: dive.id },
    "POST",
    key,
  );
  assert.equal(landed.status, 200, JSON.stringify(landed.data));
  const position = landed.data.surface;
  assert.equal(position.x, WORLD.hub.divePoint.x);
  assert.equal(position.y, WORLD.hub.divePoint.y - 40);
  assert.equal(position.layoutVersion, WORLD.hub.layoutVersion);
  assert.equal(position.playerVersion, landed.data.player.version);
  const state = await b.request("/adventure/state");
  assert.deepEqual(state.data.surface, position);
  const moved = await b.request("/adventure/surface-position", {
    area: "hub",
    x: position.x,
    y: position.y - 15,
    version: landed.data.player.version,
  });
  assert.equal(moved.status, 200, JSON.stringify(moved.data));
  const replay = await b.request(
    "/dive/extract",
    { diveId: dive.id },
    "POST",
    key,
  );
  assert.deepEqual(replay.data, landed.data);
  assert.equal(
    (await b.request("/adventure/state")).data.surface.y,
    position.y - 15,
  );
});

test("static game assets negotiate precompressed bytes and preserve uncompressed fallback", async () => {
  const directory = mkdtempSync(join(tmpdir(), "jalasmara-static-"));
  const original = Buffer.concat([
    Buffer.from([0, 97, 115, 109, 1, 0, 0, 0]),
    Buffer.alloc(8192, 42),
  ]);
  mkdirSync(join(directory, "game"));
  writeFileSync(
    join(directory, "index.html"),
    "<!doctype html><title>Static fixture</title>",
  );
  writeFileSync(join(directory, "game", "test.wasm"), original);
  writeFileSync(join(directory, "game", "test.wasm.gz"), gzipSync(original));
  const previous = process.env.WEB_DIST;
  let staticApp: FastifyInstance | undefined;
  try {
    process.env.WEB_DIST = directory;
    staticApp = await buildApp(s, false);
    const address = await staticApp.listen({ host: "127.0.0.1", port: 0 });
    const read = (encoding?: string) =>
      new Promise<{
        headers: import("node:http").IncomingHttpHeaders;
        status: number | undefined;
        body: Buffer;
      }>((resolve, reject) => {
        get(
          `${address}/game/test.wasm`,
          { headers: encoding ? { "Accept-Encoding": encoding } : {} },
          (response) => {
            const chunks: Buffer[] = [];
            response.on("data", (chunk) => chunks.push(Buffer.from(chunk)));
            response.on("end", () =>
              resolve({
                headers: response.headers,
                status: response.statusCode,
                body: Buffer.concat(chunks),
              }),
            );
            response.on("error", reject);
          },
        ).on("error", reject);
      });
    const compressed = await read("gzip");
    assert.equal(compressed.status, 200);
    assert.equal(compressed.headers["content-encoding"], "gzip");
    assert.match(
      String(compressed.headers["content-type"]),
      /application\/wasm/,
    );
    assert.match(String(compressed.headers.vary), /accept-encoding/i);
    assert(compressed.body.length < original.length);
    assert.deepEqual(gunzipSync(compressed.body), original);
    const plain = await read();
    assert.equal(plain.status, 200);
    assert.equal(plain.headers["content-encoding"], undefined);
    assert.deepEqual(plain.body, original);
  } finally {
    if (previous === undefined) delete process.env.WEB_DIST;
    else process.env.WEB_DIST = previous;
    await staticApp?.close();
    rmSync(directory, { recursive: true, force: true });
  }
});

test("posisi laut mengikuti kontur alami, menolak inti dan jarak dinding, serta menerima sudut terpotong dan celah", async () => {
  const user = await account();
  const browser = await new Browser().login(user);
  const dive = await start(browser);
  const key = `dive:${user.id}`;
  const allowMovementTime = async () => {
    const saved = JSON.parse((await s.redis.get(key))!);
    saved.positionAt = Date.now() - 5000;
    await s.redis.set(key, JSON.stringify(saved), "KEEPTTL");
  };
  await fixturePosition(browser, { x: 1740, y: 800 });
  await allowMovementTime();
  const core = await browser.request("/dive/position", {
    diveId: dive.id,
    x: 1920,
    y: 870,
  });
  assert.equal(core.status, 409);
  assert.equal(core.data.code, "POSITION");
  assert.deepEqual(JSON.parse((await s.redis.get(key))!).position, {
    x: 1740,
    y: 800,
  });

  const contour = WORLD.terrainContours[14];
  const top = contour.reduce((lowest, point) =>
    point[1] < lowest[1] ? point : lowest,
  );
  const wall = await browser.request("/dive/position", {
    diveId: dive.id,
    x: top[0],
    y: top[1] - 6,
  });
  assert.equal(
    wall.status,
    409,
    "Player radius cannot overlap a wall even when its center is outside",
  );
  assert.equal(wall.data.code, "POSITION");

  // This point lies inside the old 1780,820,280,100 bounding box, outside its cut corner.
  const corner = await browser.request("/dive/position", {
    diveId: dive.id,
    x: 1783,
    y: 823,
  });
  assert.equal(corner.status, 200, JSON.stringify(corner.data));
  assert.deepEqual(corner.data.position, { x: 1783, y: 823 });
  await allowMovementTime();
  const gap = await browser.request("/dive/position", {
    diveId: dive.id,
    x: 1920,
    y: 970,
  });
  assert.equal(gap.status, 200, JSON.stringify(gap.data));
  assert.deepEqual(gap.data.position, { x: 1920, y: 970 });
});

test("batang pohon desa menghalangi kaki tanpa menutup seluruh tajuk", async () => {
  const u = await account(),
    b = await new Browser().login(u),
    trunk = WORLD.hub.treeTrunks[1];
  await fixtureSurface(u, "hub", { x: trunk.x - 45, y: trunk.y + 17 });
  for (const point of [
    { x: trunk.x, y: trunk.y },
    { x: trunk.x - 16, y: trunk.y + 17 },
  ]) {
    const blocked = await b.request("/adventure/surface-position", {
      area: "hub",
      ...point,
    });
    assert.equal(blocked.status, 409, JSON.stringify(blocked.data));
    assert.equal(blocked.data.code, "PATH_BLOCKED");
  }
  await fixtureSurface(u, "hub", { x: 870, y: 650 });
  const besideCanopy = await b.request("/adventure/surface-position", {
    area: "hub",
    x: 870,
    y: 650,
  });
  assert.equal(besideCanopy.status, 200, JSON.stringify(besideCanopy.data));
  const rockMound = await b.request("/adventure/surface-position", {
    area: "hub",
    x: 800,
    y: 860,
  });
  assert.equal(rockMound.status, 409, JSON.stringify(rockMound.data));
  assert.equal(rockMound.data.code, "PATH_BLOCKED");
  assert.equal(WORLD.hub.layoutVersion, WORLD.landMaps.hub.layoutVersion);
  assert.equal((await s.users.findOne({ id: u.id }))!.version, u.version);
});

test("pelataran desa dapat dijelajahi di luar koridor tanpa menembus batang, bangunan, atau pantai", async () => {
  const u = await account(),
    b = await new Browser().login(u),
    plaza = { x: 850, y: 1080 };
  const corridorDistance = Math.min(
    ...WORLD.hub.paths.flatMap((path) =>
      path
        .slice(1)
        .map((end, index) => distanceToEdge(plaza, path[index], end)),
    ),
  );
  assert.ok(corridorDistance > WORLD.hub.walkableHalfWidth);
  await fixtureSurface(u, "hub", { x: 900, y: 1080 });
  const free = await b.request("/adventure/surface-position", {
    area: "hub",
    ...plaza,
  });
  assert.equal(free.status, 200, JSON.stringify(free.data));
  for (const point of [
    WORLD.hub.treeTrunks[0],
    { x: 560, y: 500 },
    { x: 60, y: 1480 },
  ]) {
    const blocked = await b.request("/adventure/surface-position", {
      area: "hub",
      x: point.x,
      y: point.y,
    });
    assert.equal(blocked.status, 409, JSON.stringify(blocked.data));
    assert.equal(blocked.data.code, "PATH_BLOCKED");
  }
  assert.equal(WORLD.hub.layoutVersion, WORLD.landMaps.hub.layoutVersion);
  assert.equal((await s.users.findOne({ id: u.id }))!.version, u.version);
});

test("migrasi layout mempertahankan posisi aman dan memindahkan posisi air lama tanpa mengubah akun", async () => {
  const u = await account(),
    b = await new Browser().login(u);
  const before = await s.users.findOne({ id: u.id });
  const safe = { x: 595, y: 650 };
  await fixtureSurface(u, "hub", safe);
  const old = JSON.parse((await s.redis.get(`surface:${u.id}`))!);
  old.layoutVersion = WORLD.hub.layoutVersion - 1;
  await s.redis.set(`surface:${u.id}`, JSON.stringify(old), "EX", 1800);
  const kept = await b.request("/adventure/state");
  assert.equal(kept.status, 200);
  assert.equal(kept.data.surface.layoutVersion, WORLD.hub.layoutVersion);
  assert.equal(kept.data.surface.x, safe.x);
  assert.equal(kept.data.surface.y, safe.y);
  await fixtureSurface(u, "forest", { x: 1450, y: 450 });
  const invalid = JSON.parse((await s.redis.get(`surface:${u.id}`))!);
  invalid.layoutVersion = WORLD.landMaps.forest.layoutVersion - 1;
  await s.redis.set(`surface:${u.id}`, JSON.stringify(invalid), "EX", 1800);
  const moved = await b.request("/adventure/state");
  assert.equal(moved.status, 200);
  assert.equal(moved.data.surface.area, "forest");
  assert.ok(isLandWalkable(WORLD.landMaps.forest, moved.data.surface));
  assert.notDeepEqual(
    { x: moved.data.surface.x, y: moved.data.surface.y },
    { x: 1450, y: 450 },
  );
  assert.deepEqual(await s.users.findOne({ id: u.id }), before);
});

test("sinkronisasi menolak lintasan menembus rumah dan tebing walau kedua ujung berada di lantai", async () => {
  const u = await account(),
    b = await new Browser().login(u);
  for (const [from, to] of [
    [
      { x: 1350, y: 600 },
      { x: 1350, y: 365 },
    ],
    [
      { x: 900, y: 700 },
      { x: 900, y: 850 },
    ],
  ]) {
    assert.ok(isLandWalkable(WORLD.landMaps.hub, from));
    assert.ok(isLandWalkable(WORLD.landMaps.hub, to));
    await fixtureSurface(u, "hub", from, 10000);
    const blocked = await b.request("/adventure/surface-position", {
      area: "hub",
      ...to,
    });
    assert.equal(blocked.status, 409, JSON.stringify(blocked.data));
    assert.equal(blocked.data.code, "PATH_BLOCKED");
    const kept = JSON.parse((await s.redis.get(`surface:${u.id}`))!);
    assert.deepEqual({ x: kept.x, y: kept.y }, from);
  }
});

test("server memakai footprint modular sama pada taman, atap, air dermaga dan sungai serta menerima jembatan", async () => {
  const u = await account(),
    b = await new Browser().login(u);
  for (const [area, point] of [
    ["hub", { x: 560, y: 500 }],
    ["hub", { x: 1950, y: 560 }],
    ["hub", { x: 800, y: 860 }],
    ["hub", { x: 1560, y: 1330 }],
    ["forest", { x: 1450, y: 450 }],
  ] as const) {
    await fixtureSurface(u, area, WORLD.landMaps[area].spawn, 10000);
    const blocked = await b.request("/adventure/surface-position", {
      area,
      ...point,
    });
    assert.equal(blocked.status, 409, JSON.stringify(blocked.data));
    assert.equal(blocked.data.code, "PATH_BLOCKED");
  }
  for (const bridge of WORLD.landMaps.forest.bridges ?? []) {
    const [a, bPoint] = bridge.path;
    await fixtureSurface(u, "forest", { x: a[0], y: a[1] }, 10000);
    const crossed = await b.request("/adventure/surface-position", {
      area: "forest",
      x: bPoint[0],
      y: bPoint[1],
    });
    assert.equal(crossed.status, 200, JSON.stringify(crossed.data));
    for (const railId of bridge.railIds) {
      const rail = WORLD.landMaps.forest.obstacles.find(
        (o) => o.id === railId,
      )!;
      const center = {
        x: rail.footprint.reduce((sum, p) => sum + p[0], 0) / 4,
        y: rail.footprint.reduce((sum, p) => sum + p[1], 0) / 4,
      };
      const blocked = await b.request("/adventure/surface-position", {
        area: "forest",
        ...center,
      });
      assert.equal(blocked.status, 409);
      assert.equal(blocked.data.code, "PATH_BLOCKED");
    }
  }
  await fixtureSurface(u, "forest", { x: 310, y: 700 });
  const glade = await b.request("/adventure/surface-position", {
    area: "forest",
    x: 300,
    y: 700,
  });
  assert.equal(glade.status, 200, JSON.stringify(glade.data));
});

test("lintasan belokan sah diterima tanpa meratakan jalan mengitari rumah menjadi pintasan", async () => {
  const u = await account(),
    b = await new Browser().login(u),
    from = { x: 1350, y: 600 },
    to = { x: 1350, y: 365 };
  await fixtureSurface(u, "hub", from, 10000);
  const base = JSON.parse((await s.redis.get(`surface:${u.id}`))!);
  const request = {
    area: "hub",
    ...to,
    fromPositionAt: base.positionAt,
    path: [
      { x: 1550, y: 600 },
      { x: 1550, y: 365 },
    ],
  };
  const walked = await b.request("/adventure/surface-position", request);
  assert.equal(walked.status, 200, JSON.stringify(walked.data));
  assert.equal(walked.data.surface.x, to.x);
  assert.ok(walked.data.surface.positionAt > base.positionAt);
  const replay = await b.request("/adventure/surface-position", request);
  assert.equal(replay.status, 409);
  assert.equal(replay.data.code, "POSITION_CHANGED");
  assert.deepEqual(
    JSON.parse((await s.redis.get(`surface:${u.id}`))!),
    walked.data.surface,
  );
  await fixtureSurface(u, "hub", from, 10000);
  const fresh = JSON.parse((await s.redis.get(`surface:${u.id}`))!);
  const roof = await b.request("/adventure/surface-position", {
    ...request,
    fromPositionAt: fresh.positionAt,
    path: [{ x: 1350, y: 500 }],
  });
  assert.equal(roof.status, 409);
  assert.equal(roof.data.code, "PATH_BLOCKED");
  assert.equal((await s.users.findOne({ id: u.id }))!.version, u.version);
});

test("batas breadcrumb dan total jarak mencegah lintasan berlebihan, replay serta lintasan tanpa basis", async () => {
  const u = await account(),
    b = await new Browser().login(u);
  await fixtureSurface(u, "hub", WORLD.surfaceSpawn, 10000);
  const base = JSON.parse((await s.redis.get(`surface:${u.id}`))!);
  const common = {
    area: "hub",
    ...WORLD.surfaceSpawn,
    fromPositionAt: base.positionAt,
  };
  const tooMany = await b.request("/adventure/surface-position", {
    ...common,
    path: Array.from({ length: 65 }, () => WORLD.surfaceSpawn),
  });
  assert.equal(tooMany.status, 400);
  const noBase = await b.request("/adventure/surface-position", {
    area: "hub",
    ...WORLD.surfaceSpawn,
    path: [],
  });
  assert.equal(noBase.status, 400);
  assert.equal(noBase.data.code, "POSITION_BASE");
  const loop = Array.from({ length: 16 }, (_, i) => ({
    x: i % 2 ? 1120 : 1300,
    y: 1230,
  }));
  const tooFar = await b.request("/adventure/surface-position", {
    ...common,
    path: loop,
  });
  assert.equal(tooFar.status, 409);
  assert.equal(tooFar.data.code, "POSITION");
  assert.equal(
    JSON.parse((await s.redis.get(`surface:${u.id}`))!).positionAt,
    base.positionAt,
  );
});

test("upgrade dan penampilan mempertahankan posisi hub sah beserta basis breadcrumb", async () => {
  const u = await account(),
    b = await new Browser().login(u);
  await s.users.updateOne({ id: u.id }, { $set: { coins: 2000 } });
  await fixtureSurface(u, "hub", { x: 1350, y: 635 });
  const before = JSON.parse((await s.redis.get(`surface:${u.id}`))!);
  const upgrade = await b.request("/game/upgrade", { ability: "oxygen" });
  assert.equal(upgrade.status, 200, JSON.stringify(upgrade.data));
  const state = await b.request("/adventure/state");
  assert.equal(state.status, 200);
  assert.deepEqual(
    { x: state.data.surface.x, y: state.data.surface.y },
    { x: before.x, y: before.y },
  );
  assert.equal(state.data.surface.area, "hub");
  assert.equal(state.data.surface.positionAt, before.positionAt);
  assert.equal(state.data.surface.playerVersion, upgrade.data.player.version);
  const appearance = await b.request("/game/appearance", {
    appearance: "female_nusantara",
  });
  assert.equal(appearance.status, 200);
  const moved = await b.request("/adventure/surface-position", {
    area: "hub",
    x: 1350,
    y: 640,
    version: appearance.data.player.version,
    fromPositionAt: before.positionAt,
    path: [],
  });
  assert.equal(moved.status, 200, JSON.stringify(moved.data));
});

test("versi permainan normal mempertahankan wilayah hutan dan tidak melewati larangan fasilitas hub", async () => {
  const u = await account(),
    b = await new Browser().login(u);
  await fixtureSurface(u, "forest", WORLD.forest.landmarks[0]);
  const before = JSON.parse((await s.redis.get(`surface:${u.id}`))!);
  const updated = await b.request("/game/tutorial", {});
  assert.equal(updated.status, 200);
  const blocked = await b.request("/dive/start", { mode: "dive" });
  assert.equal(blocked.status, 409);
  assert.equal(blocked.data.code, "HUB_REQUIRED");
  const state = await b.request("/adventure/state");
  assert.equal(state.data.surface.area, "forest");
  assert.equal(state.data.surface.x, before.x);
  assert.equal(state.data.surface.y, before.y);
  assert.equal(state.data.surface.positionAt, before.positionAt);
  assert.equal(state.data.surface.playerVersion, updated.data.player.version);
});

test("misi Bu Darmi: pengamatan gejala kebun di hub, sebab-akibat hutan, umpan balik fragmen salah tanpa konsumsi, dan pemulihan kebun", async () => {
  const u = await account(),
    b = await new Browser().login(u);
  await s.users.updateOne(
    { id: u.id },
    {
      $set: {
        "progress.day": 2,
        "progress.stage": "dive",
        "progress.missions": ["daun_kuning", "air_keruh", "takaran", "malam_1"],
        inventory: [
          { fragmentId: "klorofil", stars: 3, quantity: 1 },
          { fragmentId: "rasio", stars: 3, quantity: 1 },
          { fragmentId: "ekosistem", stars: 3, quantity: 1 },
        ],
      },
    },
  );
  // 1. Gejala kebun di hub memerlukan kedekatan dan wilayah hub
  await fixtureSurface(u, "hub", WORLD.surfaceSpawn);
  const farGarden = await b.request("/adventure/surface-interact", {
    id: "garden_leaf",
  });
  assert.equal(farGarden.status, 409);
  assert.equal(farGarden.data.code, "POSITION");

  for (const spot of WORLD.surface_hub.landmarks) {
    assert.ok(
      isLandWalkable(WORLD.landMaps.hub, spot),
      `Garden landmark ${spot.id} must be on walkable ground`,
    );
    await fixtureSurface(u, "hub", { x: spot.x, y: spot.y });
    const found = await b.request("/adventure/surface-interact", {
      id: spot.id,
    });
    assert.equal(found.status, 200, JSON.stringify(found.data));
    assert.equal(found.data.reward, 35);
    assert.equal(found.data.alreadyFound, false);
    assert.ok(found.data.adventure.discoveries.includes(spot.id));
    const again = await b.request("/adventure/surface-interact", {
      id: spot.id,
    });
    assert.equal(again.status, 200);
    assert.equal(again.data.reward, 0);
    assert.equal(again.data.alreadyFound, true);
  }

  // 2. Pengamatan sebab-akibat di Hutan Pesisir Wringin menolak dari hub dan berhasil di forest
  const forestFromHub = await b.request("/adventure/surface-interact", {
    id: "forest_stream",
  });
  assert.equal(forestFromHub.status, 409);
  await fixtureSurface(u, "forest", { x: 1830, y: 470 });
  const clearedStream = await b.request("/adventure/surface-interact", {
    id: "forest_stream",
  });
  assert.equal(clearedStream.status, 200, JSON.stringify(clearedStream.data));
  assert.equal(clearedStream.data.reward, 120);
  assert.match(clearedStream.data.knowledge.text, /pintu air|aliran/i);

  // 3. Kembali ke hub, selesaikan pengamatan bawah laut Hutan Lamun Wringin, lalu buka Kedai Waras
  await fixtureSurface(u, "hub", WORLD.hub.divePoint);
  const d = await start(b);
  for (const id of ["nitrogen", "photosynthesis", "osmosis"]) {
    assert.equal((await observe(b, d, id)).status, 200);
  }
  await fixturePosition(b, WORLD.spawn);
  assert.equal(
    (await b.request("/dive/extract", { diveId: d.id })).status,
    200,
  );
  const shiftRes = await b.request("/kedai/start", {});
  assert.equal(shiftRes.status, 200, JSON.stringify(shiftRes.data));
  const shift = shiftRes.data.shift;

  // 4. Memilih fragmen yang salah untuk Bu Darmi (akar) memberi penjelasan diagnostik tanpa mengurangi stok
  const wrongFrag = await b.request("/kedai/serve", {
    shiftId: shift.id,
    recipeId: "akar",
    fragmentId: "rasio",
    stars: 3,
  });
  assert.equal(wrongFrag.status, 400);
  assert.equal(wrongFrag.data.code, "WRONG_FRAGMENT");
  assert.match(wrongFrag.data.error, /Benih Hayati/i);
  const afterWrong = (await b.request("/game/state")).data.player;
  assert.equal(
    afterWrong.inventory.find((i: any) => i.fragmentId === "rasio")?.quantity,
    1,
  );

  // 5. Memilih Benih Hayati (klorofil) menyelesaikan misi akar Bu Darmi
  const served = await b.request("/kedai/serve", {
    shiftId: shift.id,
    recipeId: "akar",
    fragmentId: "klorofil",
    stars: 3,
  });
  assert.equal(served.status, 200, JSON.stringify(served.data));
  assert.ok(served.data.player.progress.missions.includes("akar"));
  assert.match(served.data.solution, /respirasi|aerasi|oksigen/i);
});

test("perjalanan menyimpan versi layout wilayah tujuan tanpa migrasi ulang", async () => {
  const u = await account(),
    b = await new Browser().login(u);
  await fixtureSurface(u, "hub", WORLD.forest.gate);
  for (const destination of ["forest", "hub"] as const) {
    const travel = await b.request("/adventure/travel", { destination });
    assert.equal(travel.status, 200, JSON.stringify(travel.data));
    const position = travel.data.surface;
    assert.equal(
      position.layoutVersion,
      WORLD.landMaps[destination].layoutVersion,
    );
    assert.equal(
      JSON.parse((await s.redis.get(`surface:${u.id}`))!).layoutVersion,
      position.layoutVersion,
    );
    const resumed = await b.request("/adventure/state");
    assert.equal(resumed.data.surface.layoutVersion, position.layoutVersion);
    assert.equal(
      resumed.data.surface.positionAt,
      position.positionAt,
      "Travel must not produce a stale version that resets the movement clock",
    );
  }
});

test("tiang bilik ganti memblokir badan dan migrasi save mempertahankan akun serta lorong masuk", async () => {
  const u = await account(),
    b = await new Browser().login(u);
  const posts = WORLD.landMaps.hub.obstacles.filter(
    (o) => o.variant === "changing_booth",
  );
  assert.equal(posts.length, 2);
  const before = await s.users.findOne({ id: u.id });
  for (const post of posts) {
    const center = { x: post.x + post.width / 2, y: post.y + post.height / 2 };
    assert.equal(isLandWalkable(WORLD.landMaps.hub, center), false);
    await fixtureSurface(u, "hub", { x: center.x - 40, y: center.y });
    const blocked = await b.request("/adventure/surface-position", {
      area: "hub",
      ...center,
    });
    assert.equal(blocked.status, 409, JSON.stringify(blocked.data));
    assert.equal(blocked.data.code, "PATH_BLOCKED");
  }
  const entrance = {
    x: posts[0].x + posts[0].width / 2,
    y: (posts[0].y + posts[1].y + posts[0].height) / 2,
  };
  assert.ok(isLandWalkable(WORLD.landMaps.hub, entrance));
  await fixtureSurface(u, "hub", { x: entrance.x - 40, y: entrance.y });
  const pass = await b.request("/adventure/surface-position", {
    area: "hub",
    ...entrance,
  });
  assert.equal(pass.status, 200, JSON.stringify(pass.data));
  const old = JSON.parse((await s.redis.get(`surface:${u.id}`))!);
  old.x = posts[0].x + posts[0].width / 2;
  old.y = posts[0].y + posts[0].height / 2;
  old.layoutVersion = WORLD.landMaps.hub.layoutVersion - 1;
  await s.redis.set(`surface:${u.id}`, JSON.stringify(old), "EX", 1800);
  const resumed = await b.request("/adventure/state");
  assert.equal(
    resumed.data.surface.layoutVersion,
    WORLD.landMaps.hub.layoutVersion,
  );
  assert.ok(isLandWalkable(WORLD.landMaps.hub, resumed.data.surface));
  assert.notDeepEqual(
    [resumed.data.surface.x, resumed.data.surface.y],
    [old.x, old.y],
  );
  assert.deepEqual(await s.users.findOne({ id: u.id }), before);
});

function checkHubActivityRoute(
  route: readonly (readonly number[])[],
  label: string,
) {
  const map = WORLD.landMaps.hub;
  const elevations = new Map(
    map.terraces.map((terrace) => [terrace.id, terrace.elevation]),
  );
  const heightAt = (point: { x: number; y: number }) => {
    for (const stair of map.stairs) {
      const [a, b] = stair.path;
      const dx = b[0] - a[0],
        dy = b[1] - a[1];
      const t =
        ((point.x - a[0]) * dx + (point.y - a[1]) * dy) / (dx * dx + dy * dy);
      if (
        t >= 0 &&
        t <= 1 &&
        landDistanceToSegment(point, a, b) <= stair.width / 2
      ) {
        assert.ok(
          elevations.has(stair.from) && elevations.has(stair.to),
          `${stair.id} must reference actual terrace elevations`,
        );
        return (
          elevations.get(stair.from)! +
          (elevations.get(stair.to)! - elevations.get(stair.from)!) * t
        );
      }
    }
    const floor = map.surfaces
      .filter(
        (surface) =>
          surface.walkable !== false &&
          landPointInPolygon(point, surface.polygon),
      )
      .sort(
        (a, b) =>
          (b.priority ?? 0) - (a.priority ?? 0) || b.elevation - a.elevation,
      )[0];
    assert.ok(floor, `${label} needs an authoritative floor`);
    return floor.elevation;
  };
  const maxSlope = Math.max(
    ...map.stairs.map(
      (stair) =>
        Math.abs(elevations.get(stair.to)! - elevations.get(stair.from)!) /
        Math.hypot(
          stair.path[1][0] - stair.path[0][0],
          stair.path[1][1] - stair.path[0][1],
        ),
    ),
  );
  for (let index = 1; index < route.length; index++) {
    const [ax, ay] = route[index - 1],
      [bx, by] = route[index];
    const length = Math.hypot(bx - ax, by - ay),
      steps = Math.max(1, Math.ceil(length / 6));
    let previous = heightAt({ x: ax, y: ay });
    for (let step = 0; step <= steps; step++) {
      const t = step / steps,
        point = { x: ax + (bx - ax) * t, y: ay + (by - ay) * t };
      assert.ok(
        isLandWalkable(map, point, 13),
        `${label} crosses a building, trunk, water or cliff at sample ${step}`,
      );
      const elevation = heightAt(point);
      assert.ok(
        Math.abs(elevation - previous) <= (length / steps) * maxSlope + 0.02,
        `${label} changes terrace elevation without traversing authored stairs/ramp`,
      );
      previous = elevation;
    }
  }
}

test("rute enam warga desa berada pada lantai bersama dan tidak memotong prop atau tebing", () => {
  const residents = WORLD.surface_hub.residents;
  assert.equal(residents.length, 6);
  assert.equal(
    new Set(residents.map((resident) => resident.id)).size,
    residents.length,
  );
  assert.equal(
    residents.find((resident) => resident.id === "npc_saras")?.cycle,
    2,
  );
  for (const resident of residents) {
    assert.ok(resident.route.length >= 2);
    assert.ok(resident.activity.startMinute < resident.activity.endMinute);
    assert.deepEqual(resident.activity.commute[0], resident.activity.work);
    assert.deepEqual(resident.activity.commute.at(-1), resident.activity.rest);
    for (const anchor of [
      resident.activity.work,
      resident.activity.rest,
      resident.activity.shelter,
    ]) {
      assert.ok(
        isLandWalkable(WORLD.landMaps.hub, { x: anchor[0], y: anchor[1] }, 13),
        `${resident.name} activity anchor must have walkable ground`,
      );
    }
    checkHubActivityRoute(resident.route, `${resident.name} workplace`);
    checkHubActivityRoute(
      resident.activity.commute,
      `${resident.name} commute`,
    );
  }
});

test("empat bangunan baru menghalangi badan dan memiliki pintu depan terhubung ke jaringan tangga desa", async () => {
  const u = await account(),
    b = await new Browser().login(u),
    before = await s.users.findOne({ id: u.id });
  for (const [id, entrance] of [
    ["balai_lurah", { x: 940, y: 310 }],
    ["rumah_ratih", { x: 465, y: 320 }],
    ["rumah_sari", { x: 1325, y: 300 }],
    ["rumah_tedi", { x: 1005, y: 975 }],
  ] as const) {
    const house = WORLD.landMaps.hub.obstacles.find(
      (obstacle) => obstacle.id === id,
    );
    assert.ok(house?.kind === "house");
    const center = {
      x: house.x + house.width / 2,
      y: house.y + house.height / 2,
    };
    assert.equal(isLandWalkable(WORLD.landMaps.hub, center), false);
    assert.ok(isLandWalkable(WORLD.landMaps.hub, entrance, 13));
    const route = hubRoute(WORLD, WORLD.surfaceSpawn, entrance);
    checkHubActivityRoute(route, `${id} entrance route`);
    for (let index = 1; index < route.length; index++) {
      assert.ok(
        isLandSegmentWalkable(
          WORLD.landMaps.hub,
          { x: route[index - 1][0], y: route[index - 1][1] },
          { x: route[index][0], y: route[index][1] },
          13,
        ),
      );
    }
    await fixtureSurface(u, "hub", entrance, 10000);
    const blocked = await b.request("/adventure/surface-position", {
      area: "hub",
      ...center,
    });
    assert.equal(blocked.status, 409, JSON.stringify(blocked.data));
    assert.equal(blocked.data.code, "PATH_BLOCKED");
    const resumed = await b.request("/adventure/state");
    assert.deepEqual(
      [resumed.data.surface.x, resumed.data.surface.y],
      [entrance.x, entrance.y],
    );
  }
  assert.deepEqual(await s.users.findOne({ id: u.id }), before);
});

test("jadwal Bu Darmi menghubungkan kebun, rumah dan tempat berlindung melalui teras yang sah", () => {
  const district = WORLD.surface_hub.districtActivities["Bu Darmi"];
  assert.ok(district);
  const activity = district.activity;
  assert.equal(activity.kind, "gardening");
  assert.ok(
    activity.startMinute >= 0 &&
      activity.startMinute < activity.endMinute &&
      activity.endMinute <= 1440,
  );
  assert.deepEqual(activity.commute[0], activity.work);
  assert.deepEqual(activity.commute.at(-1), activity.rest);
  for (const anchor of [activity.work, activity.rest, activity.shelter]) {
    assert.ok(
      isLandWalkable(WORLD.landMaps.hub, { x: anchor[0], y: anchor[1] }, 13),
      "Bu Darmi must not stand inside a house, garden bed, tree, water or cliff",
    );
  }
  checkHubActivityRoute(activity.commute, "Bu Darmi work/home commute");
  const restToShelter = hubRoute(
    WORLD,
    { x: activity.rest[0], y: activity.rest[1] },
    { x: activity.shelter[0], y: activity.shelter[1] },
  );
  checkHubActivityRoute(restToShelter, "Bu Darmi shelter route");
});
