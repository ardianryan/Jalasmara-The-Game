import { dailyUser, ensureDaily, dailyBundle, setCalendar } from "./daily.js";
import { HOMESTEAD_DEFINITIONS } from "../../../packages/shared/src/homestead.js";
import { homesteadSnapshot } from "./homestead.js";
import { surfaceInvalidatedByAdmin } from "./surface-version.js";
import type { FastifyInstance, FastifyRequest } from "fastify";
import type { ClientSession } from "mongodb";
import { randomInt, randomUUID } from "node:crypto";
import { z } from "zod";
import type {
  Catalog,
  ContentVersion,
  DiveView,
  Loot,
  Player,
  Question,
  ShiftView,
  Subject,
} from "../../../packages/shared/src/index.js";
import {
  type Store,
  type User,
  fail,
  publicUser,
  currentContent,
  lock,
  once,
} from "./db.js";
import type { Guards } from "./auth.js";
import { uuid, ability } from "./schemas.js";
import { WORLD } from "../../../packages/shared/src/world.js";
interface Dive extends Omit<DiveView, "challenge"> {
  playerVersion: number;
  updatedAt: number;
  reading?: boolean;
  netAt?: number;
  challenge?: {
    id: string;
    targetId: string;
    question: Question;
    startedAt: number;
    answered: boolean;
    result?: NonNullable<DiveView["challenge"]>["result"];
  };
  questionIds: string[];
  lastHazard: number;
}
interface Shift extends ShiftView {
  userId: string;
  playerVersion: number;
  active: boolean;
  createdAt: Date;
}
export const addLoot = (bag: Loot[], item: Loot) => {
  const old = bag.find(
    (x) => x.fragmentId === item.fragmentId && x.stars === item.stars,
  );
  if (old) old.quantity += item.quantity;
  else bag.push({ ...item });
};
export const countLoot = (items: Loot[]) =>
  items.reduce((n, x) => n + x.quantity, 0);
function diveView(d: Dive): DiveView {
  const {
    playerVersion,
    updatedAt,
    questionIds,
    lastHazard,
    netAt,
    reading,
    ...v
  } = d;
  if (v.challenge) {
    const { correctIndex, explanation, source, ...question } =
      v.challenge.question;
    return { ...v, challenge: { ...v.challenge, question } };
  }
  return v;
}
function shiftView(s: Shift): ShiftView {
  return {
    id: s.id,
    contentId: s.contentId,
    customers: s.customers,
    served: s.served,
    earnings: s.earnings,
  };
}
export const operationKey = (req: FastifyRequest) =>
  uuid.parse(req.headers["idempotency-key"]);
export async function gameRoutes(app: FastifyInstance, s: Store, g: Guards) {
  const shifts = s.db.collection<Shift>("shifts");
  await shifts.createIndex(
    { userId: 1 },
    { unique: true, partialFilterExpression: { active: true } },
  );
  await shifts.createIndex({ createdAt: 1 }, { expireAfterSeconds: 7 * 86400 });
  const user = async (id: string, session?: ClientSession) => {
    const p = await dailyUser(s, id, session);
    if (!p || p.status !== "active") return fail("Akun tidak aktif.", 403);
    return p;
  };
  const requireHub = async (p: User) => {
    if (p.homestead?.inside)
      fail("Keluar dari rumah terlebih dahulu.", 409, "HOME_INSIDE");
    const raw = await s.redis.get(`surface:${p.id}`);
    if (!raw) return;
    const surface = JSON.parse(raw);
    if (
      surface.area === "forest" &&
      !(await surfaceInvalidatedByAdmin(s, p, surface.playerVersion))
    )
      return fail(
        "Kembali melalui gerbang Bandar Hujung untuk menggunakan fasilitas dermaga.",
        409,
        "HUB_REQUIRED",
      );
  };
  const content = async (id: string) => {
    const c = await s.contents.findOne({ id });
    if (!c) return fail("Versi konten tidak tersedia.", 503);
    return c;
  };
  const value = (c: Catalog, p: Player, id: keyof Player["abilities"]) => {
    const a = c.abilities.find((x) => x.id === id)!;
    return a.values[Math.min(p.abilities[id], a.values.length - 1)];
  };
  async function loadDive(id: string, p: Player) {
    const raw = await s.redis.get(`dive:${id}`);
    if (!raw) return null;
    const d = JSON.parse(raw) as Dive;
    if (d.playerVersion !== p.version) {
      await s.redis.del(`dive:${id}`);
      return fail(
        "Data pemain telah berubah. Sesi penyelaman dibatalkan; muat ulang progres.",
        409,
        "SESSION_CHANGED",
      );
    }
    if (d.expiresAt <= Date.now()) {
      await s.redis.del(`dive:${id}`);
      return null;
    }
    const c = await content(d.contentId),
      now = Date.now();
    if (!d.challenge && !d.reading)
      d.oxygen = Math.max(
        0,
        d.oxygen -
          ((now - d.updatedAt) / 1000) *
            c.catalog.balance.oxygenDrainPerSecond *
            (d.mode === "boss" ? 1.4 : 1),
      );
    d.updatedAt = now;
    return d;
  }
  async function saveDive(id: string, d: Dive) {
    const remaining = Math.ceil((d.expiresAt - Date.now()) / 1000);
    if (remaining <= 0) return fail("Sesi telah kedaluwarsa.", 410);
    await s.redis.set(`dive:${id}`, JSON.stringify(d), "EX", remaining);
  }
  async function update(p: User, session: ClientSession) {
    const v = p.version;
    p.version++;
    p.updatedAt = new Date().toISOString();
    const { _id, ...data } = p as User & { _id?: unknown };
    const r = await s.users.replaceOne({ id: p.id, version: v }, data, {
      session,
    });
    if (!r.matchedCount) fail("Data berubah. Muat ulang dan coba lagi.", 409);
    return publicUser(p);
  }
  app.get("/api/game/state", { preHandler: g.authenticated }, async (req) =>
    lock(s, req.user!.id, async () => {
      const p = await user(req.user!.id),
        c = await currentContent(s),
        d = await loadDive(p.id, p);
      if (d) await saveDive(p.id, d);
      const shift = await shifts.findOne({ userId: p.id, active: true });
      const validShift = shift?.playerVersion === p.version ? shift : null;
      return {
        ...(await homesteadSnapshot(s, p)),
        catalog: { ...c.catalog, questions: undefined },
        contentId: c.id,
        dive: d ? diveView(d) : null,
        shift: validShift ? shiftView(validShift) : null,
      };
    }),
  );
  app.post(
    "/api/game/appearance",
    { preHandler: g.authenticated },
    async (req) => {
      const body = z
        .object({
          appearance: z.enum([
            "male_default",
            "male_nusantara",
            "female_default",
            "female_nusantara",
          ]),
        })
        .strict()
        .parse(req.body);
      return lock(s, req.user!.id, async () => {
        const before = await user(req.user!.id),
          surfaceRaw = await s.redis.get(`surface:${before.id}`);
        const result = await once(
          s,
          req.user!.id,
          operationKey(req),
          { route: "appearance", ...body },
          async (session) => {
            const p = await user(req.user!.id, session);
            if (await loadDive(p.id, p))
              return fail(
                "Ganti penampilan setelah kembali ke dermaga.",
                409,
                "ACTIVE_DIVE",
              );
            if (
              await shifts.findOne({ userId: p.id, active: true }, { session })
            )
              return fail(
                "Tutup giliran kedai sebelum mengganti penampilan.",
                409,
                "ACTIVE_SHIFT",
              );
            p.appearance = body.appearance;
            return { player: await update(p, session) };
          },
        );
        if (surfaceRaw && result.player.version === before.version + 1) {
          const surface = JSON.parse(surfaceRaw);
          if (surface.playerVersion === before.version) {
            surface.playerVersion = result.player.version;
            await s.redis.set(
              `surface:${before.id}`,
              JSON.stringify(surface),
              "KEEPTTL",
            );
          }
        }
        return result;
      });
    },
  );
  app.post("/api/game/tutorial", { preHandler: g.authenticated }, async (req) =>
    lock(s, req.user!.id, () =>
      once(
        s,
        req.user!.id,
        operationKey(req),
        { route: "tutorial" },
        async (session) => {
          const p = await user(req.user!.id, session);
          p.progress.tutorial = true;
          return { player: await update(p, session) };
        },
      ),
    ),
  );
  app.post("/api/dive/start", { preHandler: g.authenticated }, async (req) => {
    const b = z
      .object({ mode: z.enum(["dive", "boss"]).default("dive") })
      .strict()
      .parse(req.body);
    return lock(s, req.user!.id, async () => {
      const p = await user(req.user!.id),
        existing = await loadDive(p.id, p);
      if (existing) {
        await saveDive(p.id, existing);
        return { dive: diveView(existing) };
      }
      await requireHub(p);
      const shift = await shifts.findOne({
        userId: p.id,
        active: true,
        playerVersion: p.version,
      });
      if (shift) fail("Tutup giliran kedai sebelum menyelam.", 409);
      if (p.progress.stage === "done")
        fail(
          "Cerita demo sudah selesai. Gunakan penyelaman biasa melalui reset progres admin.",
          409,
        );
      if (
        b.mode === "boss" &&
        (p.progress.stage !== "boss" ||
          p.abilities.oxygen < WORLD.boss.requiredUpgrades.oxygen ||
          p.abilities.net < WORLD.boss.requiredUpgrades.net)
      )
        fail(
          "Selesaikan tiga malam; tingkatkan tabung napas dan Jala Kognisi ke level 3.",
          409,
        );
      const c = await currentContent(s),
        now = Date.now();
      const subjects = c.catalog.fragments;
      const targets = Array.from(
        { length: b.mode === "boss" ? c.catalog.balance.bossHits : 24 },
        (_, i) => {
          const f = subjects[i % subjects.length];
          const bossSubjects: Subject[] = [
            "Kimia",
            "Lingkungan",
            "Kimia",
            "Biologi",
            "Kimia",
            "Matematika",
          ];
          const bossFragments = [
            "netralisasi",
            "ekosistem",
            "netralisasi",
            "klorofil",
            "netralisasi",
            "rasio",
          ];
          const day = p.progress.day;
          const x =
            b.mode === "boss"
              ? 3380 + (i % 3) * 240
              : (day === 1 ? 1250 : day === 2 ? 2200 : 1500) +
                (i % 6) * (day === 1 ? 260 : day === 2 ? 520 : 540);
          let y =
            b.mode === "boss"
              ? 3060 + Math.floor(i / 3) * 200
              : (day === 1 ? 530 : day === 2 ? 1200 : 2200) +
                Math.floor(i / 6) * 125;
          for (const [rx, ry, rw, rh] of WORLD.terrain)
            if (
              x > rx - 35 &&
              x < rx + rw + 35 &&
              y > ry - 35 &&
              y < ry + rh + 35
            )
              y = ry - 65;
          return {
            id: randomUUID(),
            fragmentId: b.mode === "boss" ? bossFragments[i] : f.id,
            subject: b.mode === "boss" ? bossSubjects[i] : f.subject,
            x,
            y,
            caught: false,
          };
        },
      );
      const maxOxygen = value(c.catalog, p, "oxygen");
      const d: Dive = {
        id: randomUUID(),
        mode: b.mode,
        contentId: c.id,
        oxygen: maxOxygen,
        maxOxygen,
        weight: 0,
        capacity: value(c.catalog, p, "bag"),
        speed: value(c.catalog, p, "speed"),
        net: value(c.catalog, p, "net"),
        expiresAt: now + 30 * 60000,
        targets,
        loot: [],
        position: { ...WORLD.spawn },
        playerVersion: p.version,
        updatedAt: now,
        hits: 0,
        requiredHits: c.catalog.balance.bossHits,
        questionIds: [],
        lastHazard: 0,
      };
      await saveDive(p.id, d);
      return { dive: diveView(d) };
    });
  });
  app.post(
    "/api/dive/challenge",
    { preHandler: g.authenticated },
    async (req) => {
      const b = z
        .object({ diveId: uuid, targetId: uuid })
        .strict()
        .parse(req.body);
      return lock(s, req.user!.id, async () => {
        const p = await user(req.user!.id),
          d = await loadDive(p.id, p);
        if (!d || d.id !== b.diveId)
          return fail("Penyelaman tidak tersedia.", 410);
        if (d.challenge) {
          if (d.challenge.targetId !== b.targetId)
            fail("Selesaikan kuis yang sedang terbuka.", 409);
          return { dive: diveView(d) };
        }
        if (d.oxygen <= 0) fail("Oksigen habis. Kembali ke perahu.", 409);
        const t = d.targets.find((x) => x.id === b.targetId && !x.caught);
        if (!t) fail("Fragmen tidak tersedia.", 409);
        if (
          d.mode === "boss" &&
          d.targets.indexOf(t!) < Math.ceil(d.requiredHits / 2) !==
            d.hits < Math.ceil(d.requiredHits / 2)
        )
          fail("Titik resonansi ini terbuka pada fase berikutnya.", 409);
        const pos = d.position ?? WORLD.spawn;
        if (Math.hypot(pos.x - t!.x, pos.y - t!.y) > d.net + 110)
          fail("Dekati fragmen sebelum menggunakan jala.", 409);
        const c = await content(d.contentId),
          f = c.catalog.fragments.find((x) => x.id === t!.fragmentId)!;
        if (d.mode === "dive" && d.weight + f.weight > d.capacity)
          fail("Tas penuh. Kembali ke perahu.", 409);
        let pool = c.catalog.questions.filter(
          (q) => q.fragmentId === f.id && !d.questionIds.includes(q.id),
        );
        if (!pool.length)
          pool = c.catalog.questions.filter((q) => q.fragmentId === f.id);
        if (!pool.length)
          return fail("Soal untuk fragmen ini tidak tersedia.", 503);
        const q = pool[randomInt(pool.length)];
        d.questionIds.push(q.id);
        d.challenge = {
          id: randomUUID(),
          targetId: t!.id,
          question: q,
          startedAt: Date.now(),
          answered: false,
        };
        await saveDive(p.id, d);
        return { dive: diveView(d) };
      });
    },
  );
  app.post(
    "/api/dive/net/start",
    { preHandler: g.authenticated },
    async (req) => {
      const b = z.object({ diveId: uuid }).strict().parse(req.body);
      return lock(s, req.user!.id, async () => {
        const p = await user(req.user!.id),
          d = await loadDive(p.id, p);
        if (!d || d.id !== b.diveId)
          return fail("Penyelaman tidak tersedia.", 410);
        if (d.challenge || d.reading || d.oxygen <= 0)
          fail("Jala belum dapat digunakan.", 409);
        d.netAt = Date.now();
        await saveDive(p.id, d);
        return { ok: true };
      });
    },
  );
  app.post(
    "/api/dive/collect",
    { preHandler: g.authenticated },
    async (req) => {
      const b = z
        .object({ diveId: uuid, targetId: uuid })
        .strict()
        .parse(req.body);
      return lock(s, req.user!.id, async () => {
        const p = await user(req.user!.id),
          d = await loadDive(p.id, p);
        if (!d || d.id !== b.diveId)
          return fail("Penyelaman tidak tersedia.", 410);
        if (d.mode === "boss" || d.challenge || d.reading || d.oxygen <= 0)
          fail("Jala belum dapat digunakan.", 409);
        const target = d.targets.find((t) => t.id === b.targetId);
        if (!target) return fail("Fragmen tidak tersedia.", 404);
        if (target.caught) return { dive: diveView(d) };
        const pos = d.position ?? WORLD.spawn;
        if (Math.hypot(pos.x - target.x, pos.y - target.y) > d.net + 110)
          return fail("Fragmen berada di luar jangkauan.", 409);
        const duration = Date.now() - (d.netAt ?? Date.now());
        if (!d.netAt || duration < 250 || duration > 6000)
          return fail("Tahan jala sebentar, lalu lepaskan.", 409);
        const c = await content(d.contentId),
          f = c.catalog.fragments.find((f) => f.id === target.fragmentId)!;
        if (d.weight + f.weight > d.capacity)
          return fail("Tas penuh. Kembali ke perahu.", 409);
        const stars = duration >= 600 && duration <= 1400 ? 3 : 2;
        target.caught = true;
        addLoot(d.loot, { fragmentId: f.id, stars, quantity: 1 });
        if (
          stars === 3 &&
          ["ekosistem", "netralisasi"].includes(target.fragmentId)
        ) {
          d.liveCatch ??= { reef_seruni: 0 };
          d.liveCatch.reef_seruni++;
        }
        d.weight += f.weight;
        delete d.netAt;
        await saveDive(p.id, d);
        return { dive: diveView(d), stars, fragment: f };
      });
    },
  );
  app.post("/api/dive/catch", { preHandler: g.authenticated }, async (req) => {
    const b = z
      .object({
        diveId: uuid,
        challengeId: uuid,
        selectedOption: z.number().int().min(0).max(3),
      })
      .strict()
      .parse(req.body);
    return lock(s, req.user!.id, async () => {
      const p = await user(req.user!.id),
        d = await loadDive(p.id, p);
      if (!d || d.id !== b.diveId)
        return fail("Penyelaman tidak tersedia.", 410);
      const ch = d.challenge;
      if (!ch || ch.id !== b.challengeId)
        return fail("Tantangan tidak tersedia.", 409);
      if (ch.answered) return { dive: diveView(d) };
      const q = ch.question,
        c = await content(d.contentId),
        correct = b.selectedOption === q.correctIndex,
        stars = correct
          ? Date.now() - ch.startedAt <= q.timeLimitMs
            ? 3
            : 2
          : 1;
      ch.answered = true;
      ch.result = {
        correct,
        stars,
        explanation: q.explanation,
        source: q.source,
        answer: q.options[q.correctIndex],
      };
      const target = d.targets.find((t) => t.id === ch.targetId)!;
      if (!correct)
        d.oxygen = Math.max(0, d.oxygen - c.catalog.balance.wrongPenalty);
      if (d.mode === "dive") {
        target.caught = true;
        addLoot(d.loot, { fragmentId: q.fragmentId, stars, quantity: 1 });
        if (
          stars === 3 &&
          ["ekosistem", "netralisasi"].includes(target.fragmentId)
        ) {
          d.liveCatch ??= { reef_seruni: 0 };
          d.liveCatch.reef_seruni++;
        }
        d.weight += c.catalog.fragments.find(
          (f) => f.id === q.fragmentId,
        )!.weight;
      } else if (correct) {
        target.caught = true;
        d.hits++;
      }
      await saveDive(p.id, d);
      return { dive: diveView(d) };
    });
  });
  app.post(
    "/api/dive/continue",
    { preHandler: g.authenticated },
    async (req) => {
      const b = z
        .object({ diveId: uuid, challengeId: uuid })
        .strict()
        .parse(req.body);
      return lock(s, req.user!.id, async () => {
        const p = await user(req.user!.id),
          d = await loadDive(p.id, p);
        if (!d || d.id !== b.diveId) return fail("Sesi berakhir.", 410);
        if (d.challenge) {
          if (d.challenge.id !== b.challengeId || !d.challenge.answered)
            fail("Jawab kuis terlebih dahulu.", 409);
          delete d.challenge;
        }
        d.updatedAt = Date.now();
        await saveDive(p.id, d);
        return { dive: diveView(d) };
      });
    },
  );
  app.post("/api/dive/hazard", { preHandler: g.authenticated }, async (req) => {
    const b = z.object({ diveId: uuid }).strict().parse(req.body);
    return lock(s, req.user!.id, async () => {
      const p = await user(req.user!.id),
        d = await loadDive(p.id, p);
      if (!d || d.id !== b.diveId) return fail("Sesi berakhir.", 410);
      const pos = d.position ?? WORLD.spawn;
      const hazard = WORLD.hazards.find(
        (h) => Math.hypot(pos.x - h.x, pos.y - h.y) <= h.radius + 20,
      );
      const nearBoss =
        d.mode === "boss" &&
        Math.hypot(pos.x - WORLD.boss.x, pos.y - WORLD.boss.y) < 720;
      if (
        (nearBoss || hazard) &&
        !d.challenge &&
        !d.reading &&
        Date.now() - d.lastHazard >= 3000
      ) {
        d.oxygen = Math.max(
          0,
          d.oxygen -
            (nearBoss
              ? (await content(d.contentId)).catalog.balance.bossDamage
              : hazard!.damage),
        );
        d.lastHazard = Date.now();
      }
      await saveDive(p.id, d);
      return { dive: diveView(d) };
    });
  });
  app.post(
    "/api/dive/extract",
    { preHandler: g.authenticated },
    async (req) => {
      const b = z.object({ diveId: uuid }).strict().parse(req.body),
        key = operationKey(req);
      return lock(s, req.user!.id, async () => {
        const cached = await s.receipts.findOne({
          _id: `${req.user!.id}:${key}`,
        });
        if (cached)
          return once(
            s,
            req.user!.id,
            key,
            { route: "extract", ...b },
            async () => fail("Tidak terjangkau."),
          );
        const p = await user(req.user!.id),
          d = await loadDive(p.id, p);
        if (!d || d.id !== b.diveId)
          return fail("Penyelaman tidak tersedia atau dibatalkan.", 410);
        if (d.challenge && !d.challenge.answered)
          fail("Jawab kuis sebelum kembali.", 409);
        const pos = d.position ?? WORLD.spawn;
        if (
          d.oxygen > 0 &&
          !(d.mode === "boss" && d.hits >= d.requiredHits) &&
          Math.hypot(pos.x - WORLD.spawn.x, pos.y - WORLD.spawn.y) > 220
        )
          fail("Kembali ke tangga selam sebelum naik ke dermaga.", 409);
        const loot =
          d.oxygen > 0
            ? d.loot
            : countLoot(d.loot)
              ? (() => {
                  const n = randomInt(countLoot(d.loot));
                  let offset = 0;
                  const l = d.loot.find((x) => {
                    offset += x.quantity;
                    return n < offset;
                  })!;
                  return [{ ...l, quantity: 1 }];
                })()
              : [];
        const result = await once(
          s,
          p.id,
          key,
          { route: "extract", ...b },
          async (session) => {
            const u = await user(p.id, session);
            if (u.version !== d.playerVersion)
              fail(
                "Sesi dibatalkan karena data berubah.",
                409,
                "SESSION_CHANGED",
              );
            for (const l of loot) addLoot(u.inventory, l);
            if (d.oxygen > 0 && d.mode === "dive" && d.liveCatch) {
              u.homestead!.liveCatch.reef_seruni += d.liveCatch.reef_seruni;
              u.homestead!.revision++;
            }
            if (d.mode === "boss" && d.hits >= d.requiredHits && d.oxygen > 0) {
              u.progress.stage = "done";
              u.progress.bossDefeated = true;
              u.progress.missions.push("gajah_mina");
              u.coins += WORLD.boss.reward;
              u.adventure ??= { discoveries: [], puzzles: [], keyItems: [] };
              u.adventure.keyItems.push(WORLD.boss.keyItem);
            } else if (d.mode === "dive" && u.progress.stage === "dive")
              u.progress.stage = "night";
            const player = await update(u, session);
            return {
              player,
              loot,
              fainted: d.oxygen <= 0,
              victory: u.progress.bossDefeated,
              surface: {
                area: "hub",
                x: WORLD.hub.divePoint.x,
                y: WORLD.hub.divePoint.y - 40,
                playerVersion: player.version,
                layoutVersion: WORLD.hub.layoutVersion,
                positionAt: Date.now(),
              },
            };
          },
        );
        await s.redis.set(
          `surface:${p.id}`,
          JSON.stringify(result.surface),
          "EX",
          1800,
        );
        await s.redis.del(`dive:${p.id}`);
        return result;
      });
    },
  );
  app.post("/api/kedai/start", { preHandler: g.authenticated }, async (req) =>
    lock(s, req.user!.id, async () => {
      const p = await user(req.user!.id);
      await requireHub(p);
      if (await loadDive(p.id, p))
        fail("Kembali dari laut terlebih dahulu.", 409);
      ensureDaily(p);
      if (p.homestead!.pendingStoryAdvance)
        fail(
          "Pulang dan tidur untuk melanjutkan cerita.",
          409,
          "SLEEP_REQUIRED",
        );
      if (p.progress.stage !== "night")
        fail("Belum waktunya membuka kedai.", 409);
      const discoveries = p.adventure?.discoveries ?? [];
      if (
        p.progress.day === 2 &&
        !["nitrogen", "photosynthesis", "osmosis"].every((id) =>
          discoveries.includes(id),
        )
      )
        fail(
          "Temukan Koral Nitrogen, Lentera Fotosintesis, dan Kerang Osmosis sebelum meracik untuk petani.",
          409,
        );
      if (
        p.progress.day === 3 &&
        (!discoveries.includes("corporate_pipe") ||
          !p.adventure?.puzzles.includes("filter"))
      )
        fail(
          "Catat bukti pipa korporasi dan pulihkan penyaring Jalatunda sebelum membuka kedai.",
          409,
        );
      const old = await shifts.findOne({ userId: p.id, active: true });
      if (old?.playerVersion === p.version) return { shift: shiftView(old) };
      if (old)
        await shifts.updateOne({ id: old.id }, { $set: { active: false } });
      if (p.calendar!.minuteOfDay < 1080) {
        setCalendar(p, p.calendar!.calendarDay, 1080);
        await s.users.updateOne(
          { id: p.id, version: p.version },
          { $set: { calendar: p.calendar, homestead: p.homestead } },
        );
        await s.redis.del(`calendar:writer:${p.id}`);
      }
      const c = await currentContent(s);
      const shift: Shift = {
        id: randomUUID(),
        userId: p.id,
        playerVersion: p.version,
        active: true,
        contentId: c.id,
        customers: c.catalog.recipes.filter((r) => r.day === p.progress.day),
        served: c.catalog.recipes
          .filter(
            (r) =>
              r.day === p.progress.day && p.progress.missions.includes(r.id),
          )
          .map((r) => r.id),
        earnings: 0,
        createdAt: new Date(),
      };
      await shifts.insertOne(shift);
      return { shift: shiftView(shift) };
    }),
  );
  app.post("/api/kedai/serve", { preHandler: g.authenticated }, async (req) => {
    const b = z
      .object({
        shiftId: uuid,
        recipeId: z.string().max(64),
        fragmentId: z.string().max(64),
        stars: z.number().int().min(1).max(3),
        gardenIngredient: z.boolean().default(false),
        gardenItemId: z.enum(["kangkung", "jahe", "ikan_seruni"]).optional(),
      })
      .strict()
      .parse(req.body);
    return lock(s, req.user!.id, () =>
      once(
        s,
        req.user!.id,
        operationKey(req),
        { route: "serve", ...b },
        async (session) => {
          const p = await user(req.user!.id, session),
            shift = await shifts.findOne(
              { id: b.shiftId, userId: p.id, active: true },
              { session },
            );
          if (!shift || shift.playerVersion !== p.version)
            return fail("Giliran kedai telah berubah.", 409, "SESSION_CHANGED");
          const r = shift.customers.find((x) => x.id === b.recipeId);
          if (
            !r ||
            shift.served.includes(r.id) ||
            p.progress.missions.includes(r.id)
          )
            return fail("Pelanggan tidak tersedia.", 409);
          if (r.fragmentId !== b.fragmentId) {
            const c = await content(shift.contentId),
              needed = c.catalog.fragments.find((f) => f.id === r.fragmentId),
              chosen = c.catalog.fragments.find((f) => f.id === b.fragmentId);
            const reason =
              r.id === "akar"
                ? `Fragmen ${chosen?.name ?? b.fragmentId} belum menjawab akar masalah kebun apung Bu Darmi. Tanaman yang layu karena media tergenang memerlukan ingatan biologi tumbuhan (${needed?.name ?? "Benih Hayati"}) tentang respirasi akar, osmosis, dan fotosintesis.`
                : `Fragmen ${chosen?.name ?? b.fragmentId} belum sesuai untuk keluhan ${r.customer}. Gunakan fragmen ${needed?.name ?? r.fragmentId} (${needed?.subject ?? "terkait"}) yang menjawab masalah ini.`;
            return fail(reason, 400, "WRONG_FRAGMENT");
          }
          const item = p.inventory.find(
            (x) =>
              x.fragmentId === b.fragmentId &&
              x.stars === b.stars &&
              x.quantity > 0,
          );
          if (!item) return fail("Stok fragmen tidak cukup.");
          const c = await content(shift.contentId),
            earned = Math.round(
              r.reward * c.catalog.balance.starMultipliers[b.stars - 1],
            );
          ensureDaily(p);
          const gardenItemId = b.gardenItemId ?? "kangkung";
          const serving = HOMESTEAD_DEFINITIONS.servings[gardenItemId];
          if (b.gardenIngredient) {
            if (p.homestead!.pantry[gardenItemId] < serving.quantity)
              fail("Stok bahan budidaya kedai tidak cukup.");
            p.homestead!.pantry[gardenItemId] -= serving.quantity;
            p.homestead!.revision++;
          }
          item.quantity--;
          p.inventory = p.inventory.filter((x) => x.quantity > 0);
          const gardenBonus = b.gardenIngredient ? serving.bonus : 0;
          p.coins += earned + gardenBonus;
          p.progress.missions.push(r.id);
          shift.served.push(r.id);
          shift.earnings += earned + gardenBonus;
          const player = await update(p, session);
          shift.playerVersion = player.version;
          await shifts.updateOne(
            { id: shift.id },
            {
              $set: {
                served: shift.served,
                earnings: shift.earnings,
                playerVersion: shift.playerVersion,
              },
            },
            { session },
          );
          return {
            shift: shiftView(shift),
            solution: r.solution,
            earned: earned + gardenBonus,
            gardenBonus,
            ...dailyBundle(p),
          };
        },
      ),
    );
  });
  app.post(
    "/api/kedai/close-shift",
    { preHandler: g.authenticated },
    async (req) => {
      const b = z
        .object({ shiftId: uuid, abandon: z.boolean().default(false) })
        .strict()
        .parse(req.body);
      return lock(s, req.user!.id, () =>
        once(
          s,
          req.user!.id,
          operationKey(req),
          { route: "close-shift", ...b },
          async (session) => {
            const p = await user(req.user!.id, session),
              shift = await shifts.findOne(
                { id: b.shiftId, userId: p.id, active: true },
                { session },
              );
            if (!shift || shift.playerVersion !== p.version)
              return fail(
                "Giliran kedai telah berubah.",
                409,
                "SESSION_CHANGED",
              );
            if (!b.abandon && shift.served.length < shift.customers.length)
              fail(
                "Layani semua pelanggan atau tutup sementara untuk mencari stok.",
              );
            ensureDaily(p);
            if (!b.abandon) {
              const marker = `malam_${p.progress.day}`;
              if (!p.progress.missions.includes(marker))
                p.progress.missions.push(marker);
              p.homestead!.pendingStoryAdvance = {
                storyDay: p.progress.day,
                shiftId: shift.id,
              };
              p.homestead!.revision++;
            }
            await shifts.updateOne(
              { id: shift.id },
              { $set: { active: false } },
              { session },
            );
            await update(p, session);
            return { ...dailyBundle(p), sleepRequired: !b.abandon };
          },
        ),
      );
    },
  );
  app.post(
    "/api/game/upgrade",
    { preHandler: g.authenticated },
    async (req) => {
      const b = z.object({ ability }).strict().parse(req.body);
      return lock(s, req.user!.id, async () => {
        const p = await user(req.user!.id);
        await requireHub(p);
        if (await loadDive(p.id, p))
          fail("Peningkatan dilakukan di permukaan.", 409);
        const active = await shifts.findOne({
          userId: p.id,
          active: true,
          playerVersion: p.version,
        });
        if (active) fail("Tutup giliran kedai sebelum meningkatkan alat.", 409);
        return once(
          s,
          p.id,
          operationKey(req),
          { route: "upgrade", ...b },
          async (session) => {
            const u = await user(p.id, session),
              c = await currentContent(s, session),
              def = c.catalog.abilities.find((a) => a.id === b.ability)!,
              price = def.prices[u.abilities[b.ability]];
            if (price === undefined) return fail("Kemampuan sudah maksimal.");
            if (u.coins < price) return fail("Koin belum cukup.");
            u.coins -= price;
            u.abilities[b.ability]++;
            return { player: await update(u, session) };
          },
        );
      });
    },
  );
}
