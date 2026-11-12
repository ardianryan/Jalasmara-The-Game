import type { FastifyInstance } from "fastify";
import { z } from "zod";
import { WORLD } from "../../../packages/shared/src/world.js";
import { type Store, type User, fail, lock, once, publicUser } from "./db.js";
import type { Guards } from "./auth.js";
import { operationKey } from "./game.js";
import { uuid, version } from "./schemas.js";
import {
  isLandWalkable,
  isLandSegmentWalkable,
  nearestSafeLandPoint,
} from "../../../packages/shared/src/land.js";
import { surfaceInvalidatedByAdmin } from "./surface-version.js";
import { blockedByContours } from "./geometry.js";
export const publicWorld = (day = 1) => ({
  ...WORLD,
  atlas: {
    ...WORLD.atlas,
    regions: WORLD.atlas.regions.map((region) => ({
      ...region,
      status:
        region.status === "story" &&
        "requiresDay" in region &&
        day >= region.requiresDay
          ? "open"
          : region.status,
    })),
  },
  puzzles: WORLD.puzzles.map(({ correct, ...p }) => p),
});
export async function adventureRoutes(
  app: FastifyInstance,
  s: Store,
  g: Guards,
) {
  type SurfaceArea = "hub" | "forest";
  type SurfacePosition = {
    area: SurfaceArea;
    x: number;
    y: number;
    positionAt: number;
    playerVersion: number;
    layoutVersion?: number;
  };
  const initialSurface = (p: User): SurfacePosition => ({
    area: "hub",
    layoutVersion: WORLD.hub.layoutVersion,
    ...WORLD.surfaceSpawn,
    positionAt: Date.now(),
    playerVersion: p.version,
  });
  const surfacePosition = async (p: User): Promise<SurfacePosition> => {
    const key = `surface:${p.id}`;
    for (let attempt = 0; attempt < 3; attempt++) {
      const raw = await s.redis.get(key);
      if (raw) {
        const point = JSON.parse(raw) as SurfacePosition;
        if (
          point.playerVersion <= p.version &&
          !(await surfaceInvalidatedByAdmin(s, p, point.playerVersion))
        ) {
          const map = WORLD.landMaps[point.area];
          if (
            point.playerVersion === p.version &&
            map &&
            point.layoutVersion === map.layoutVersion &&
            isLandWalkable(map, point)
          )
            return point;
          const area = map ? point.area : "hub";
          const safe = nearestSafeLandPoint(WORLD.landMaps[area], point);
          const migrated: SurfacePosition = {
            ...point,
            ...safe,
            area,
            layoutVersion: WORLD.landMaps[area].layoutVersion,
            playerVersion: p.version,
            positionAt:
              point.layoutVersion === WORLD.landMaps[area].layoutVersion &&
              safe.x === point.x &&
              safe.y === point.y
                ? point.positionAt
                : Date.now(),
          };
          const saved = await s.redis.eval(
            "if redis.call('get',KEYS[1])==ARGV[1] then redis.call('set',KEYS[1],ARGV[2],'EX',1800); return 1 else return 0 end",
            1,
            key,
            raw,
            JSON.stringify(migrated),
          );
          if (saved) return migrated;
          continue;
        }
        if (point.playerVersion > p.version)
          return fail(
            "Data pemain berubah. Muat ulang permainan.",
            409,
            "SESSION_CHANGED",
          );
      }
      const initial = initialSurface(p);
      const stored = raw
        ? await s.redis.eval(
            "if redis.call('get',KEYS[1])==ARGV[1] then redis.call('set',KEYS[1],ARGV[2],'EX',1800); return 1 else return 0 end",
            1,
            key,
            raw,
            JSON.stringify(initial),
          )
        : await s.redis.set(key, JSON.stringify(initial), "EX", 1800, "NX");
      if (stored) return initial;
    }
    return fail("Posisi sedang diperbarui. Coba lagi.", 409, "BUSY");
  };
  const saveSurface = (p: User, point: SurfacePosition) =>
    s.redis.set(`surface:${p.id}`, JSON.stringify(point), "EX", 1800);
  const surfacePlayer = async (id: string) => {
    const p = await s.users.findOne({ id });
    if (!p || p.status !== "active") return fail("Akun tidak aktif.", 403);
    if (p.homestead?.inside)
      fail("Keluar dari rumah terlebih dahulu.", 409, "HOME_INSIDE");
    const raw = await s.redis.get(`dive:${id}`);
    if (raw) {
      const dive = JSON.parse(raw);
      if (dive.playerVersion === p.version && dive.expiresAt > Date.now())
        return fail("Kembali dari penyelaman sebelum menjelajah daratan.", 409);
    }
    const shift = await s.db.collection("shifts").findOne({
      userId: id,
      active: true,
      playerVersion: p.version,
    });
    if (shift)
      return fail("Tutup giliran kedai sebelum menjelajah daratan.", 409);
    return p;
  };
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
      const p = await s.users.findOne({ id: req.user!.id });
      if (!p) return fail("Pemain tidak ditemukan.", 404);
      return {
        ...game,
        world: publicWorld(p.progress.day),
        adventure: state(game.player),
        surface: await surfacePosition(p),
      };
    },
  );
  app.post(
    "/api/adventure/surface-position",
    { preHandler: g.authenticated },
    async (req) => {
      const b = z
        .object({
          area: z.enum(["hub", "forest"]).default("hub"),
          version: version.optional(),
          fromPositionAt: z.number().int().nonnegative().optional(),
          path: z
            .array(
              z
                .object({
                  x: z.number().finite().min(0).max(2400),
                  y: z.number().finite().min(0).max(1600),
                })
                .strict(),
            )
            .max(64)
            .optional(),
          x: z.number().finite(),
          y: z.number().finite(),
        })
        .strict()
        .parse(req.body);
      return lock(s, req.user!.id, async () => {
        const p = await surfacePlayer(req.user!.id),
          point = await surfacePosition(p);
        if (b.version !== undefined && b.version !== p.version)
          return fail(
            "Data pemain berubah. Muat ulang permainan.",
            409,
            "SESSION_CHANGED",
          );
        if (b.area !== point.area)
          return fail(
            "Gunakan jalur perjalanan untuk berpindah wilayah.",
            409,
            "AREA_CHANGED",
          );
        if (b.path !== undefined && b.fromPositionAt === undefined)
          return fail(
            "Lintasan memerlukan posisi awal yang sudah diterima server.",
            400,
            "POSITION_BASE",
          );
        if (
          b.fromPositionAt !== undefined &&
          b.fromPositionAt !== point.positionAt
        )
          return fail(
            "Posisi awal sudah berubah. Sinkronkan ulang lintasan.",
            409,
            "POSITION_CHANGED",
          );
        const bounds = {
          minX: 0,
          minY: 0,
          maxX: WORLD.landMaps[b.area].width,
          maxY: WORLD.landMaps[b.area].height,
        };
        if (
          b.x < bounds.minX ||
          b.x > bounds.maxX ||
          b.y < bounds.minY ||
          b.y > bounds.maxY
        )
          return fail(
            "Posisi berada di luar wilayah daratan.",
            400,
            "POSITION",
          );
        if (b.area === "forest") {
          const blocked = WORLD.forest.blockedExits.find(
            (exit) =>
              Math.abs(b.x - exit.x) <= exit.width / 2 &&
              Math.abs(b.y - exit.y) <= exit.height / 2,
          );
          if (blocked) return fail(blocked.reason, 409, "BLOCKED_EXIT");
        }
        const map = WORLD.landMaps[b.area];
        if (!isLandWalkable(map, b))
          return fail(
            "Lantai tidak tersambung atau terhalang bangunan, batu, tanaman, maupun tepi air.",
            409,
            "PATH_BLOCKED",
          );
        const now = Date.now(),
          elapsed = Math.max(0, Math.min(10, (now - point.positionAt) / 1000));
        const waypoints = [point, ...(b.path ?? []), { x: b.x, y: b.y }];
        let distance = 0;
        for (let i = 1; i < waypoints.length; i++)
          distance += Math.hypot(
            waypoints[i].x - waypoints[i - 1].x,
            waypoints[i].y - waypoints[i - 1].y,
          );
        if (distance > 175 * elapsed + 100)
          return fail(
            "Lintasan terlalu jauh dari waktu berjalan yang tersedia.",
            409,
            "POSITION",
          );
        for (let i = 1; i < waypoints.length; i++)
          if (!isLandSegmentWalkable(map, waypoints[i - 1], waypoints[i]))
            return fail(
              "Jalur memotong bangunan, batas elevasi, atau air. Gunakan jalur penghubung.",
              409,
              "PATH_BLOCKED",
            );
        const next = {
          ...point,
          x: b.x,
          y: b.y,
          positionAt: Math.max(now, point.positionAt + 1),
        };
        await saveSurface(p, next);
        return { surface: next };
      });
    },
  );
  app.post(
    "/api/adventure/reset-position",
    { preHandler: g.authenticated },
    async (req) => {
      z.object({}).strict().parse(req.body);
      return lock(s, req.user!.id, async () => {
        const p = await s.users.findOne({ id: req.user!.id });
        if (!p || p.status !== "active")
          return fail("Akun tidak aktif.", 403);
        if (p.homestead?.inside)
          return fail("Keluar dari rumah terlebih dahulu.", 409, "HOME_INSIDE");
        const rawDive = await s.redis.get(`dive:${p.id}`);
        if (rawDive) {
          const dive = JSON.parse(rawDive);
          if (dive.playerVersion === p.version && dive.expiresAt > Date.now())
            return fail("Selesaikan penyelaman terlebih dahulu.", 409, "ACTIVE_DIVE");
        }
        const previous = await surfacePosition(p);
        const activeShift = await s.db.collection("shifts").findOne({
          userId: p.id,
          active: true,
          playerVersion: p.version,
        });
        const area: SurfaceArea = activeShift ? "hub" : previous.area;
        // This dock point has been verified in the rendered scene. The generic
        // spawn sits beside the crates and can leave smaller player sprites hidden.
        const wira = WORLD.surface_hub.districts.find((district) => district.npc === "Mbah Wira")!;
        const anchor = activeShift
          ? { x: wira.x, y: wira.y }
          : area === "forest" ? WORLD.forest.entry : { x: 1000, y: 1200 };
        const safe = nearestSafeLandPoint(WORLD.landMaps[area], anchor);
        const surface: SurfacePosition = {
          area,
          ...safe,
          layoutVersion: WORLD.landMaps[area].layoutVersion,
          playerVersion: p.version,
          positionAt: Math.max(Date.now(), previous.positionAt + 1),
        };
        await saveSurface(p, surface);
        return { surface };
      });
    },
  );
  app.post(
    "/api/adventure/travel",
    { preHandler: g.authenticated },
    async (req) => {
      const b = z
        .object({ destination: z.enum(["hub", "forest"]) })
        .strict()
        .parse(req.body);
      return lock(s, req.user!.id, async () => {
        const p = await surfacePlayer(req.user!.id),
          point = await surfacePosition(p);
        if (point.area === b.destination) return { surface: point };
        const departure =
          point.area === "hub" ? WORLD.forest.gate : WORLD.forest.entry;
        if (Math.hypot(point.x - departure.x, point.y - departure.y) > 220)
          return fail(
            "Dekati gerbang hutan untuk berpindah wilayah.",
            409,
            "POSITION",
          );
        const arrival =
          b.destination === "forest" ? WORLD.forest.entry : WORLD.forest.gate;
        const next: SurfacePosition = {
          area: b.destination,
          layoutVersion: WORLD.landMaps[b.destination].layoutVersion,
          ...arrival,
          positionAt: Date.now(),
          playerVersion: p.version,
        };
        await saveSurface(p, next);
        return { surface: next };
      });
    },
  );
  app.post(
    "/api/adventure/surface-interact",
    { preHandler: g.authenticated },
    async (req) => {
      const b = z
        .object({ id: z.string().min(1).max(64) })
        .strict()
        .parse(req.body);
      return lock(s, req.user!.id, async () => {
        const key = operationKey(req),
          fingerprint = { route: "surface-interact", ...b };
        if (await s.receipts.findOne({ _id: `${req.user!.id}:${key}` }))
          return once(s, req.user!.id, key, fingerprint, async () =>
            fail("Penemuan tidak tersedia."),
          );
        const p = await surfacePlayer(req.user!.id),
          point = await surfacePosition(p),
          hubObj = WORLD.surface_hub.landmarks.find((x) => x.id === b.id),
          forestObj = [...WORLD.forest.landmarks, ...WORLD.forest.caches].find(
            (x) => x.id === b.id,
          ),
          obj = hubObj ?? forestObj,
          requiredArea = hubObj ? "hub" : "forest";
        if (!obj) return fail("Penemuan daratan tidak tersedia.", 404);
        const knowledge =
          "text" in obj ? { title: obj.title, text: obj.text } : null;
        if (
          point.area !== requiredArea ||
          Math.hypot(obj.x - point.x, obj.y - point.y) > 180
        )
          return fail(
            requiredArea === "hub"
              ? "Dekati titik kebun apung di Bandar Hujung untuk mengamatinya."
              : "Dekati objek hutan untuk mengamatinya.",
            409,
            "POSITION",
          );
        const result = await once(
          s,
          p.id,
          key,
          fingerprint,
          async (session) => {
            const current = await s.users.findOne({ id: p.id }, { session });
            if (
              !current ||
              current.status !== "active" ||
              current.version !== p.version
            )
              return fail("Sesi permainan berubah.", 409, "SESSION_CHANGED");
            const a = state(current);
            if (a.discoveries.includes(b.id))
              return {
                player: publicUser(current),
                adventure: a,
                reward: 0,
                alreadyFound: true,
                knowledge,
              };
            a.discoveries.push(b.id);
            current.adventure = a;
            current.coins += obj.reward;
            current.version++;
            current.updatedAt = new Date().toISOString();
            const saved = await s.users.updateOne(
              { id: current.id, version: p.version },
              {
                $set: {
                  adventure: a,
                  coins: current.coins,
                  version: current.version,
                  updatedAt: current.updatedAt,
                },
              },
              { session },
            );
            if (saved.modifiedCount !== 1)
              return fail("Sesi permainan berubah.", 409, "SESSION_CHANGED");
            return {
              player: publicUser(current),
              adventure: a,
              reward: obj.reward,
              alreadyFound: false,
              knowledge,
            };
          },
        );
        await saveSurface(p, {
          ...point,
          playerVersion: result.player.version,
        });
        return result;
      });
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
        if (d.playerVersion !== p.version) {
          await s.redis.del(`dive:${p.id}`);
          return fail("Sesi permainan telah berubah.", 409, "SESSION_CHANGED");
        }
        if (d.id !== b.diveId)
          return fail(
            "Sesi penyelaman sudah berganti.",
            409,
            "SESSION_CHANGED",
          );
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
        if (blockedByContours(b, WORLD.terrainContours, 12))
          return fail("Jalur terhalang batu karang.", 409, "POSITION");
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
