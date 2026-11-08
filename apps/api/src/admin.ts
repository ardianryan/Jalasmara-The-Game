import type { FastifyInstance } from "fastify";
import { randomUUID } from "node:crypto";
import { z } from "zod";
import {
  freshAbilities,
  freshProgress,
  type ContentVersion,
} from "../../../packages/shared/src/index.js";
import {
  type Store,
  fail,
  publicUser,
  lock,
  once,
  audit,
  currentContent,
  digest,
} from "./db.js";
import type { Guards } from "./auth.js";
import { adminChange, uuid, reason } from "./schemas.js";
import { operationKey, addLoot } from "./game.js";
import { catalogSchema, questionSchema } from "./content.js";
export async function adminRoutes(app: FastifyInstance, s: Store, g: Guards) {
  app.get("/api/admin/players", { preHandler: g.admin }, async (req) => {
    const q = z
      .object({
        search: z.string().max(100).default(""),
        status: z.enum(["active", "blocked", "all"]).default("all"),
        page: z.coerce.number().int().min(1).max(10000).default(1),
      })
      .parse(req.query);
    const escaped = q.search.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
    const filter = {
      ...(q.status === "all" ? {} : { status: q.status }),
      ...(escaped
        ? {
            $or: [
              { email: { $regex: escaped, $options: "i" } },
              { name: { $regex: escaped, $options: "i" } },
            ],
          }
        : {}),
    };
    const [players, total] = await Promise.all([
      s.users
        .find(filter)
        .sort({ createdAt: -1 })
        .skip((q.page - 1) * 20)
        .limit(20)
        .toArray(),
      s.users.countDocuments(filter),
    ]);
    return { players: players.map(publicUser), total, page: q.page };
  });
  app.get("/api/admin/players/:id", { preHandler: g.admin }, async (req) => {
    const { id } = z.object({ id: uuid }).parse(req.params);
    const u = await s.users.findOne({ id });
    if (!u) return fail("Pemain tidak ditemukan.", 404);
    const [audits, dive, shift] = await Promise.all([
      s.audits.find({ target: id }).sort({ at: -1 }).limit(30).toArray(),
      s.redis.get(`dive:${id}`),
      s.db
        .collection("shifts")
        .findOne({ userId: id, active: true, playerVersion: u.version }),
    ]);
    const d = dive ? JSON.parse(dive) : null;
    return {
      player: publicUser(u),
      audits,
      activeSession: {
        dive:
          d?.playerVersion === u.version
            ? { id: d.id, mode: d.mode, expiresAt: d.expiresAt }
            : null,
        shift: shift ? { id: shift.id } : null,
      },
    };
  });
  app.post(
    "/api/admin/players/:id/change",
    { preHandler: g.admin },
    async (req) => {
      const { id } = z.object({ id: uuid }).parse(req.params),
        b = adminChange.parse(req.body);
      return lock(s, id, () =>
        once(
          s,
          req.user!.id,
          operationKey(req),
          { route: "admin-change", id, ...b },
          async (session) => {
            const actor = await s.users.findOne(
              { id: req.user!.id },
              { session },
            );
            if (
              !actor ||
              actor.status !== "active" ||
              !["owner", "admin"].includes(actor.role)
            )
              return fail("Hak pengelola telah berubah.", 403);
            const p = await s.users.findOne({ id }, { session });
            if (!p) return fail("Pemain tidak ditemukan.", 404);
            if (p.role === "owner" && actor.role !== "owner")
              return fail("Admin tidak dapat mengubah owner.", 403);
            if (p.version !== b.version)
              return fail(
                "Data pemain berubah. Muat ulang sebelum mengirim ulang.",
                409,
                "VERSION_CONFLICT",
              );
            const before = publicUser(p),
              c = await currentContent(s, session);
            if (b.action === "coins") {
              if (b.amount === undefined || !b.mode)
                return fail("Nilai dan mode saldo diperlukan.");
              p.coins =
                b.mode === "set"
                  ? b.amount
                  : b.mode === "add"
                    ? p.coins + b.amount
                    : p.coins - b.amount;
              if (p.coins < 0 || p.coins > 100000000)
                return fail("Saldo harus antara 0 dan 100.000.000.");
            } else if (b.action === "inventory") {
              if (
                !b.fragmentId ||
                !c.catalog.fragments.some((f) => f.id === b.fragmentId) ||
                !b.stars ||
                b.amount === undefined ||
                !b.mode
              )
                return fail("Fragmen, kualitas, jumlah, dan mode diperlukan.");
              const old = p.inventory.find(
                  (x) => x.fragmentId === b.fragmentId && x.stars === b.stars,
                ),
                count = old?.quantity ?? 0,
                next =
                  b.mode === "set"
                    ? b.amount
                    : b.mode === "add"
                      ? count + b.amount
                      : count - b.amount;
              if (next < 0 || next > 1000000)
                return fail("Jumlah fragmen di luar batas.");
              if (old) old.quantity = next;
              else if (next)
                addLoot(p.inventory, {
                  fragmentId: b.fragmentId,
                  stars: b.stars,
                  quantity: next,
                });
              p.inventory = p.inventory.filter((x) => x.quantity > 0);
            } else if (b.action === "ability") {
              if (!b.ability || b.level === undefined)
                return fail("Kemampuan dan level diperlukan.");
              const a = c.catalog.abilities.find((a) => a.id === b.ability)!;
              if (b.level >= a.values.length)
                return fail("Level di luar rentang kemampuan.");
              p.abilities[b.ability] = b.level;
            } else if (b.action === "progress") {
              if (!b.progress) return fail("Progres diperlukan.");
              const allowed = new Set([
                ...c.catalog.recipes.map((r) => r.id),
                "malam_1",
                "malam_2",
                "malam_3",
                "gajah_mina",
              ]);
              if (
                b.progress.missions.some((x) => !allowed.has(x)) ||
                new Set(b.progress.missions).size !== b.progress.missions.length
              )
                return fail("ID misi tidak valid atau berulang.");
              if ((b.progress.stage === "done") !== b.progress.bossDefeated)
                return fail(
                  "Status selesai harus sesuai dengan kemenangan boss.",
                );
              p.progress = b.progress;
            } else if (b.action === "reset") {
              p.coins = 0;
              p.inventory = [];
              p.abilities = freshAbilities();
              p.progress = freshProgress();
              p.adventure = { discoveries: [], puzzles: [], keyItems: [] };
            } else if (b.action === "block") {
              if (id === actor.id || p.role === "owner")
                return fail(
                  "Owner atau akun sendiri tidak dapat diblokir.",
                  403,
                );
              p.status = "blocked";
              p.authVersion++;
            } else if (b.action === "unblock") p.status = "active";
            else if (b.action === "revoke") p.authVersion++;
            else if (b.action === "role") {
              if (
                actor.role !== "owner" ||
                id === actor.id ||
                p.role === "owner" ||
                !b.role
              )
                return fail(
                  "Hanya owner dapat mengubah peran pemain/admin lain.",
                  403,
                );
              p.role = b.role;
              p.authVersion++;
            }
            p.version++;
            p.updatedAt = new Date().toISOString();
            const { _id, ...replacement } = p as typeof p & { _id?: unknown };
            await s.users.replaceOne({ id, version: b.version }, replacement, {
              session,
            });
            const after = publicUser(p);
            await audit(
              s,
              session,
              actor.id,
              id,
              `player.${b.action}`,
              b.reason,
              before,
              after,
              req.id,
            );
            return { player: after, cancelledSession: true };
          },
        ),
      );
    },
  );
  app.get("/api/admin/audit", { preHandler: g.admin }, async (req) => {
    const q = z
      .object({ page: z.coerce.number().int().min(1).max(10000).default(1) })
      .parse(req.query);
    return {
      audits: await s.audits
        .find()
        .sort({ at: -1 })
        .skip((q.page - 1) * 30)
        .limit(30)
        .toArray(),
      total: await s.audits.countDocuments(),
    };
  });
  app.get("/api/admin/content", { preHandler: g.admin }, async () => ({
    versions: await s.contents
      .find({}, { projection: { catalog: 0, _id: 0 } })
      .sort({ createdAt: -1 })
      .limit(100)
      .toArray(),
  }));
  app.get("/api/admin/content/:id", { preHandler: g.admin }, async (req) => {
    const { id } = z.object({ id: uuid }).parse(req.params),
      c = await s.contents.findOne({ id }, { projection: { _id: 0 } });
    if (!c) return fail("Konten tidak ditemukan.", 404);
    return { content: c, hash: digest(JSON.stringify(c.catalog)) };
  });
  app.post("/api/admin/content/draft", { preHandler: g.admin }, async (req) => {
    const b = z
      .object({
        sourceId: uuid,
        label: z.string().trim().min(3).max(100),
        reason,
      })
      .strict()
      .parse(req.body);
    return once(
      s,
      req.user!.id,
      operationKey(req),
      { route: "draft", ...b },
      async (session) => {
        const source = await s.contents.findOne(
          { id: b.sourceId },
          { session },
        );
        if (!source) return fail("Sumber tidak ditemukan.", 404);
        const c: ContentVersion = {
          id: randomUUID(),
          label: b.label,
          state: "draft",
          catalog: source.catalog,
          createdAt: new Date().toISOString(),
        };
        await s.contents.insertOne(c, { session });
        await audit(
          s,
          session,
          req.user!.id,
          c.id,
          "content.draft",
          b.reason,
          null,
          { id: c.id, label: c.label },
          req.id,
        );
        return { content: c, hash: digest(JSON.stringify(c.catalog)) };
      },
    );
  });
  app.put("/api/admin/content/:id", { preHandler: g.admin }, async (req) => {
    const { id } = z.object({ id: uuid }).parse(req.params),
      b = z
        .object({ catalog: catalogSchema, hash: z.string().length(64), reason })
        .strict()
        .parse(req.body);
    return lock(s, "content", () =>
      once(
        s,
        req.user!.id,
        operationKey(req),
        { route: "save-content", id, ...b },
        async (session) => {
          const c = await s.contents.findOne(
            { id, state: "draft" },
            { session },
          );
          if (!c) return fail("Hanya draft dapat diedit.", 409);
          if (digest(JSON.stringify(c.catalog)) !== b.hash)
            return fail("Draft diubah pengelola lain. Muat ulang.", 409);
          const before = digest(JSON.stringify(c.catalog));
          await s.contents.updateOne(
            { id },
            { $set: { catalog: b.catalog } },
            { session },
          );
          await audit(
            s,
            session,
            req.user!.id,
            id,
            "content.save",
            b.reason,
            { hash: before },
            { hash: digest(JSON.stringify(b.catalog)) },
            req.id,
          );
          return {
            content: { ...c, catalog: b.catalog },
            hash: digest(JSON.stringify(b.catalog)),
          };
        },
      ),
    );
  });
  app.post(
    "/api/admin/content/:id/publish",
    { preHandler: g.admin },
    async (req) => {
      const { id } = z.object({ id: uuid }).parse(req.params),
        b = z
          .object({ hash: z.string().length(64), reason })
          .strict()
          .parse(req.body);
      return lock(s, "content", () =>
        once(
          s,
          req.user!.id,
          operationKey(req),
          { route: "publish", id, ...b },
          async (session) => {
            const c = await s.contents.findOne(
              { id, state: "draft" },
              { session },
            );
            if (!c) return fail("Draft tidak ditemukan.", 409);
            if (digest(JSON.stringify(c.catalog)) !== b.hash)
              return fail("Draft telah berubah. Tinjau ulang.", 409);
            catalogSchema.parse(c.catalog);
            const old = await currentContent(s, session);
            const ids = new Set(c.catalog.fragments.map((f) => f.id));
            if (old.catalog.fragments.some((f) => !ids.has(f.id)))
              return fail(
                "Fragmen lama harus dipertahankan agar inventori tetap valid.",
              );
            for (const a of old.catalog.abilities) {
              const next = c.catalog.abilities.find((x) => x.id === a.id)!;
              if (next.values.length < a.values.length)
                return fail(
                  "Level kemampuan yang sudah ada tidak boleh dihapus.",
                );
            }
            if (
              old.catalog.recipes.some(
                (r) =>
                  !c.catalog.recipes.some(
                    (n) => n.id === r.id && n.day === r.day,
                  ),
              )
            )
              return fail(
                "ID dan hari pelanggan lama harus dipertahankan untuk progres yang sudah tersimpan.",
              );
            await s.contents.updateOne(
              { id: old.id },
              { $set: { state: "archived" } },
              { session },
            );
            await s.contents.updateOne(
              { id },
              {
                $set: {
                  state: "published",
                  publishedAt: new Date().toISOString(),
                },
              },
              { session },
            );
            await audit(
              s,
              session,
              req.user!.id,
              id,
              "content.publish",
              b.reason,
              { previous: old.id },
              { published: id },
              req.id,
            );
            return { ok: true };
          },
        ),
      );
    },
  );
  app.post(
    "/api/admin/content/:id/archive",
    { preHandler: g.admin },
    async (req) => {
      const { id } = z.object({ id: uuid }).parse(req.params),
        b = z.object({ reason }).strict().parse(req.body);
      return once(
        s,
        req.user!.id,
        operationKey(req),
        { route: "archive", id, ...b },
        async (session) => {
          const c = await s.contents.findOne({ id }, { session });
          if (!c || c.state === "published")
            return fail(
              "Konten aktif tidak dapat diarsipkan tanpa pengganti.",
              409,
            );
          await s.contents.updateOne(
            { id },
            { $set: { state: "archived" } },
            { session },
          );
          await audit(
            s,
            session,
            req.user!.id,
            id,
            "content.archive",
            b.reason,
            { state: c.state },
            { state: "archived" },
            req.id,
          );
          return { ok: true };
        },
      );
    },
  );
  app.post(
    "/api/admin/questions/validate",
    { preHandler: g.admin },
    async (req) => {
      const questions = z
        .array(questionSchema)
        .min(1)
        .max(2000)
        .parse(req.body);
      if (new Set(questions.map((q) => q.id)).size !== questions.length)
        return fail("ID soal berulang.");
      return { questions, count: questions.length };
    },
  );
}
