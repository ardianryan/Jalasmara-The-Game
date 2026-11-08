import type { FastifyInstance } from "fastify";
import { z } from "zod";
import { WORLD } from "../../../packages/shared/src/world.js";
import {
  type Store,
  fail,
  lock,
  once,
  currentContent,
  publicUser,
} from "./db.js";
import type { Guards } from "./auth.js";
import { operationKey } from "./game.js";
import { uuid } from "./schemas.js";
export const publicWorld = () => ({
  ...WORLD,
  puzzles: WORLD.puzzles.map(({ correct, ...p }) => p),
});
export async function adventureRoutes(
  app: FastifyInstance,
  s: Store,
  g: Guards,
) {
  const state = (p: any) =>
    p.adventure ?? { discoveries: [], puzzles: [], keyItems: [] };
  app.get(
    "/api/adventure/state",
    { preHandler: g.authenticated },
    async (req) => {
      const injected = await app.inject({
        method: "GET",
        url: "/api/game/state",
        headers: { cookie: req.headers.cookie ?? "" },
        remoteAddress: req.ip,
      });
      if (injected.statusCode !== 200) {
        const data = injected.json();
        return fail(data.error, injected.statusCode, data.code);
      }
      const game = injected.json();
      return { ...game, world: publicWorld(), adventure: state(game.player) };
    },
  );
  app.post(
    "/api/dive/position",
    { preHandler: g.authenticated },
    async (req) => {
      const b = z
        .object({
          diveId: uuid,
          x: z.number().min(0).max(WORLD.width),
          y: z.number().min(WORLD.surface).max(WORLD.height),
        })
        .strict()
        .parse(req.body);
      return lock(s, req.user!.id, async () => {
        const p = await s.users.findOne({ id: req.user!.id });
        const raw = await s.redis.get(`dive:${req.user!.id}`);
        if (!p || !raw) return fail("Penyelaman tidak tersedia.", 410);
        const d = JSON.parse(raw);
        if (d.id !== b.diveId || d.playerVersion !== p.version)
          return fail("Sesi permainan telah berubah.", 409, "SESSION_CHANGED");
        const old = d.position ?? WORLD.spawn,
          now = Date.now(),
          elapsed = Math.min(10, (now - (d.positionAt ?? d.updatedAt)) / 1000),
          distance = Math.hypot(b.x - old.x, b.y - old.y);
        const maxY =
          p.progress.day === 1
            ? 1100
            : p.progress.day === 2
              ? 2080
              : WORLD.height;
        if (b.y > maxY)
          return fail(
            "Selesaikan misi warga untuk membuka jalur kedalaman berikutnya.",
            409,
            "ZONE_LOCKED",
          );
        if (d.challenge && distance > 10)
          return fail("Gerakan berhenti selama kuis.", 409);
        if (distance > d.speed * Math.max(0, elapsed) * 1.5 + 100)
          return fail(
            "Posisi terlalu jauh dari keadaan terakhir.",
            409,
            "POSITION",
          );
        d.position = { x: b.x, y: b.y };
        d.positionAt = now;
        await s.redis.set(`dive:${p.id}`, JSON.stringify(d), "KEEPTTL");
        return { position: d.position };
      });
    },
  );
  app.post(
    "/api/dive/reading",
    { preHandler: g.authenticated },
    async (req) => {
      const b = z
        .object({ diveId: uuid, paused: z.boolean() })
        .strict()
        .parse(req.body);
      return lock(s, req.user!.id, async () => {
        const p = await s.users.findOne({ id: req.user!.id }),
          raw = await s.redis.get(`dive:${req.user!.id}`);
        if (!p || !raw) return fail("Penyelaman berakhir.", 410);
        const d = JSON.parse(raw);
        if (d.id !== b.diveId || d.playerVersion !== p.version)
          return fail("Sesi berubah.", 409, "SESSION_CHANGED");
        const c = await s.contents.findOne({ id: d.contentId });
        const now = Date.now();
        if (!d.reading && !d.challenge)
          d.oxygen = Math.max(
            0,
            d.oxygen -
              ((now - d.updatedAt) / 1000) *
                (c?.catalog.balance.oxygenDrainPerSecond ?? 0.18),
          );
        d.updatedAt = now;
        d.reading = b.paused;
        await s.redis.set(`dive:${p.id}`, JSON.stringify(d), "KEEPTTL");
        return { ok: true };
      });
    },
  );
  app.post(
    "/api/adventure/interact",
    { preHandler: g.authenticated },
    async (req) => {
      const b = z
        .object({
          diveId: uuid,
          id: z.string().max(64),
          settings: z.array(z.number().int().min(0).max(2)).max(3).optional(),
        })
        .strict()
        .parse(req.body);
      return lock(s, req.user!.id, async () => {
        const key = operationKey(req),
          fingerprint = { route: "adventure-interact", ...b };
        if (await s.receipts.findOne({ _id: `${req.user!.id}:${key}` }))
          return once(s, req.user!.id, key, fingerprint, async () =>
            fail("Tidak terjangkau."),
          );
        const raw = await s.redis.get(`dive:${req.user!.id}`);
        if (!raw) return fail("Penyelaman tidak tersedia.", 410);
        const d = JSON.parse(raw),
          obj = [...WORLD.landmarks, ...WORLD.puzzles, ...WORLD.caches].find(
            (x) => x.id === b.id,
          );
        if (!obj || d.id !== b.diveId)
          return fail("Penemuan tidak tersedia.", 404);
        if (d.challenge) return fail("Selesaikan kuis terlebih dahulu.", 409);
        if (Date.now() > d.expiresAt)
          return fail("Penyelaman kedaluwarsa.", 410);
        const position = d.position ?? WORLD.spawn;
        if (Math.hypot(obj.x - position.x, obj.y - position.y) > 180)
          return fail("Dekati objek untuk mengamatinya.", 409);
        const puzzle = WORLD.puzzles.find((x) => x.id === b.id);
        if (
          puzzle &&
          JSON.stringify(b.settings) !== JSON.stringify(puzzle.correct)
        )
          return {
            ok: false,
            error:
              "Aliran belum tepat. Amati petunjuk lingkungan dan coba susunan lain.",
          };
        const result = await once(
          s,
          req.user!.id,
          key,
          fingerprint,
          async (session) => {
            const p = await s.users.findOne({ id: req.user!.id }, { session });
            if (!p || p.status !== "active" || p.version !== d.playerVersion)
              return fail("Sesi permainan berubah.", 409, "SESSION_CHANGED");
            const a = state(p),
              list = puzzle ? a.puzzles : a.discoveries;
            if (list.includes(b.id))
              return {
                player: publicUser(p),
                adventure: a,
                reward: 0,
                alreadyFound: true,
              };
            list.push(b.id);
            p.adventure = a;
            p.coins += obj.reward;
            p.version++;
            p.updatedAt = new Date().toISOString();
            await s.users.updateOne(
              { id: p.id, version: d.playerVersion },
              {
                $set: {
                  adventure: a,
                  coins: p.coins,
                  version: p.version,
                  updatedAt: p.updatedAt,
                },
              },
              { session },
            );
            return {
              player: publicUser(p),
              adventure: a,
              reward: obj.reward,
              alreadyFound: false,
            };
          },
        );
        d.playerVersion = result.player.version;
        await s.redis.set(`dive:${req.user!.id}`, JSON.stringify(d), "KEEPTTL");
        return result;
      });
    },
  );
}
