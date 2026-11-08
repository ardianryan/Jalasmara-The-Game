import { test, before, after } from "node:test";
import assert from "node:assert/strict";
import { randomUUID } from "node:crypto";
import argon2 from "argon2";
import {
  connect,
  close,
  seed,
  opaque,
  digest,
  publicUser,
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
let ip = 0;
class Browser {
  cookies: Record<string, string> = {};
  csrf = "";
  remoteAddress = `192.0.2.${++ip}`;
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
