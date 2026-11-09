import type { FastifyInstance } from "fastify";
import type { ClientSession } from "mongodb";
import { z } from "zod";
import { WORLD } from "../../../packages/shared/src/world.js";
import {
  isLandWalkable,
  isLandSegmentWalkable,
  type LandMap,
} from "../../../packages/shared/src/land.js";
import { HOMESTEAD_DEFINITIONS } from "../../../packages/shared/src/index.js";
import {
  dailyUser,
  dailyBundle,
  calendarView,
  homesteadView,
  setCalendar,
  settleCalendar,
  saveDaily,
  cropPlot,
} from "./daily.js";
import { fail, lock, once, transaction, type Store, type User } from "./db.js";
import type { Guards } from "./auth.js";
import { surfaceInvalidatedByAdmin } from "./surface-version.js";
type Point = { x: number; y: number };
type HomeWorld = {
  door: Point;
  gardenPlots: { id: string; interaction: Point }[];
  interior: LandMap & { entry: Point; exit: Point; bed: Point; chest: Point };
  market: Point;
  permitBoard: Point;
  fishPen: { interaction: Point };
};
function locations(): HomeWorld {
  const home = (WORLD as unknown as { homestead?: HomeWorld }).homestead;
  if (!home) return fail("Rumah belum tersedia.", 503);
  return home;
}
function near(at: Point, target: Point, radius = 160) {
  if (Math.hypot(at.x - target.x, at.y - target.y) > radius)
    fail("Dekati tempat kegiatan terlebih dahulu.", 409, "POSITION");
}
async function idle(s: Store, p: User) {
  const raw = await s.redis.get(`dive:${p.id}`);
  if (raw) {
    const d = JSON.parse(raw);
    if (d.playerVersion === p.version && d.expiresAt > Date.now())
      fail("Selesaikan penyelaman terlebih dahulu.", 409, "ACTIVE_DIVE");
  }
  if (
    await s.db
      .collection("shifts")
      .findOne({ userId: p.id, active: true, playerVersion: p.version })
  )
    fail("Tutup giliran kedai terlebih dahulu.", 409, "ACTIVE_SHIFT");
}
async function outside(s: Store, p: User): Promise<Point> {
  if (p.homestead!.inside)
    fail("Keluar dari rumah terlebih dahulu.", 409, "HOME_INSIDE");
  const raw = await s.redis.get(`surface:${p.id}`);
  if (!raw) fail("Dekati lokasi di desa terlebih dahulu.", 409, "POSITION");
  const point = JSON.parse(raw!);
  if (point.area !== "hub")
    fail("Kembali ke Bandar Hujung.", 409, "HUB_REQUIRED");
  if (await surfaceInvalidatedByAdmin(s, p, point.playerVersion))
    fail("Data berubah. Muat ulang.", 409, "SESSION_CHANGED");
  if (!isLandWalkable(WORLD.landMaps.hub, point))
    fail("Posisi tidak sah.", 409, "POSITION");
  return point;
}
export async function homePosition(s: Store, p: User, session?: ClientSession) {
  const h = p.homestead!;
  if (!h.inside) return h.position;
  const key = `home:${p.id}`;
  const initial = {
    ...h.position,
    positionAt: Date.now(),
    playerVersion: p.version,
  };
  await s.redis.set(key, JSON.stringify(initial), "EX", 1800, "NX");
  let point = JSON.parse((await s.redis.get(key))!);
  if (
    (await surfaceInvalidatedByAdmin(s, p, point.playerVersion)) ||
    h.interiorVersion !== HOMESTEAD_DEFINITIONS.interiorVersion ||
    !isLandWalkable(locations().interior, point)
  ) {
    point = {
      ...locations().interior.entry,
      positionAt: Date.now(),
      playerVersion: p.version,
    };
    h.position = { ...locations().interior.entry };
    h.interiorVersion = HOMESTEAD_DEFINITIONS.interiorVersion;
    await s.redis.set(key, JSON.stringify(point), "EX", 1800);
    await s.users.updateOne(
      { id: p.id, version: p.version },
      { $set: { homestead: h } },
      { session },
    );
  }
  return point;
}
export async function homesteadSnapshot(s: Store, p: User) {
  const position = p.homestead!.inside
    ? await homePosition(s, p)
    : p.homestead!.position;
  const bundle = dailyBundle(p);
  bundle.homestead.position = position;
  return {
    ...bundle,
    homesteadDefinitions: { ...HOMESTEAD_DEFINITIONS, locations: locations() },
  };
}
export async function homesteadRoutes(
  app: FastifyInstance,
  s: Store,
  g: Guards,
) {
  app.get("/api/homestead/state", { preHandler: g.authenticated }, (req) =>
    lock(s, req.user!.id, async () =>
      homesteadSnapshot(s, await dailyUser(s, req.user!.id)),
    ),
  );
  app.post(
    "/api/calendar/heartbeat",
    { preHandler: g.authenticated },
    async (req) => {
      const b = z
        .object({
          sessionId: z.string().uuid(),
          paused: z.boolean(),
          focused: z.boolean(),
        })
        .strict()
        .parse(req.body);
      return lock(s, req.user!.id, async () => {
        const p = await dailyUser(s, req.user!.id),
          now = Date.now(),
          key = `calendar:writer:${p.id}`,
          owner = `${req.sessionId}:${b.sessionId}`,
          raw = await s.redis.get(key),
          old = raw ? JSON.parse(raw) : null;
        if (!b.focused) {
          if (old?.owner === owner) await s.redis.del(key);
          return {
            calendar: calendarView(
              p,
              false,
              old?.owner !== owner && old?.expiresAt > now
                ? old.expiresAt
                : now,
            ),
            homestead: homesteadView(p),
          };
        }
        if (old && old.owner !== owner && old.expiresAt > now)
          return {
            calendar: calendarView(p, false, old.expiresAt),
            homestead: homesteadView(p),
          };
        let paused = b.paused || !b.focused;
        const diveRaw = await s.redis.get(`dive:${p.id}`);
        if (diveRaw) {
          const dive = JSON.parse(diveRaw);
          if (dive.reading || dive.challenge) paused = true;
        }
        const elapsed =
          old &&
          old.owner === owner &&
          !old.paused &&
          !paused &&
          now - old.lastAt <= 15000
            ? Math.max(0, now - old.lastAt)
            : 0;
        if (elapsed) {
          settleCalendar(p, elapsed);
          await transaction(s, async (session) => {
            const saved = await s.users.updateOne(
              { id: p.id, version: p.version },
              { $set: { calendar: p.calendar, homestead: p.homestead } },
              { session },
            );
            if (!saved.matchedCount)
              fail("Data berubah. Muat ulang.", 409, "SESSION_CHANGED");
          });
        }
        const expiresAt = now + 20000;
        await s.redis.set(
          key,
          JSON.stringify({ owner, lastAt: now, paused, expiresAt }),
          "PX",
          20000,
        );
        return {
          calendar: calendarView(p, true, expiresAt),
          homestead: homesteadView(p),
        };
      });
    },
  );
  app.post(
    "/api/homestead/position",
    { preHandler: g.authenticated },
    async (req) => {
      const b = z
        .object({
          x: z.number().finite(),
          y: z.number().finite(),
          path: z
            .array(
              z
                .object({ x: z.number().finite(), y: z.number().finite() })
                .strict(),
            )
            .max(128)
            .optional(),
        })
        .strict()
        .parse(req.body);
      return lock(s, req.user!.id, async () => {
        const p = await dailyUser(s, req.user!.id);
        await idle(s, p);
        if (!p.homestead!.inside)
          fail("Masuk rumah dahulu.", 409, "HOME_REQUIRED");
        const rawPosition = await s.redis.get(`home:${p.id}`);
        const wasInvalidated =
          rawPosition &&
          (await surfaceInvalidatedByAdmin(
            s,
            p,
            JSON.parse(rawPosition).playerVersion,
          ));
        const previous = await homePosition(s, p),
          now = Date.now();
        if (wasInvalidated)
          fail("Data rumah berubah. Muat ulang.", 409, "SESSION_CHANGED");
        const points = [...(b.path ?? []), { x: b.x, y: b.y }];
        let from = previous,
          distance = 0;
        for (const point of points) {
          if (!isLandSegmentWalkable(locations().interior, from, point, 12))
            fail("Jalur interior tidak sah.", 409, "POSITION");
          distance += Math.hypot(point.x - from.x, point.y - from.y);
          from = point;
        }
        if (
          distance >
          175 *
            Math.min(
              15,
              Math.max(0, now - (previous.positionAt ?? now)) / 1000,
            ) +
            60
        )
          fail("Posisi interior terlalu jauh.", 409, "POSITION");
        await s.redis.set(
          `home:${p.id}`,
          JSON.stringify({
            x: b.x,
            y: b.y,
            positionAt: now,
            playerVersion: p.version,
          }),
          "EX",
          1800,
        );
        return {
          homestead: { ...homesteadView(p), position: { x: b.x, y: b.y } },
        };
      });
    },
  );
  const body = z
    .object({
      action: z.enum([
        "enter",
        "exit",
        "sleep",
        "plant",
        "water",
        "harvest",
        "buy_seed",
        "permit",
        "deposit",
        "withdraw",
        "stock_kedai",
        "stock_pen",
        "feed_pen",
        "harvest_pen",
      ]),
      expectedRevision: z.number().int().min(0),
      plotId: z.enum(["plot_1", "plot_2"]).optional(),
      itemId: z.string().min(1).max(80).optional(),
      qty: z.number().int().min(1).max(99).default(1),
      stars: z.number().int().min(1).max(3).optional(),
      confirmEarly: z.boolean().default(false),
    })
    .strict();
  app.post(
    "/api/homestead/action",
    { preHandler: g.authenticated },
    async (req) => {
      const b = body.parse(req.body);
      return lock(s, req.user!.id, async () => {
        const result = await once(
          s,
          req.user!.id,
          z.string().uuid().parse(req.headers["idempotency-key"]),
          { route: "homestead", ...b },
          async (session) => {
            const p = await dailyUser(s, req.user!.id, session);
            await idle(s, p);
            const h = p.homestead!,
              c = p.calendar!,
              defs = locations();
            if (h.revision !== b.expectedRevision)
              fail(
                "Keadaan rumah berubah. Muat ulang.",
                409,
                "HOMESTEAD_CHANGED",
              );
            if (b.action === "enter") {
              near(await outside(s, p), defs.door);
              h.inside = true;
              h.position = { ...defs.interior.entry };
            } else if (
              ["exit", "sleep", "deposit", "withdraw"].includes(b.action)
            ) {
              if (!h.inside)
                fail(
                  "Masuk Griya Sasmita terlebih dahulu.",
                  409,
                  "HOME_REQUIRED",
                );
              const point = await homePosition(s, p, session);
              h.position = { x: point.x, y: point.y };
              if (b.action === "exit") {
                near(point, defs.interior.exit);
                h.inside = false;
              } else if (b.action === "sleep") {
                near(point, defs.interior.bed);
                if (
                  c.minuteOfDay >= 360 &&
                  c.minuteOfDay < 1080 &&
                  !b.confirmEarly
                )
                  fail(
                    "Tidur sekarang melewati kegiatan hari ini. Konfirmasi pilihan.",
                    409,
                    "CONFIRM_EARLY_SLEEP",
                  );
                setCalendar(
                  p,
                  c.calendarDay + (c.minuteOfDay >= 360 ? 1 : 0),
                  360,
                );
                if (h.pendingStoryAdvance) {
                  if (p.progress.day === h.pendingStoryAdvance.storyDay) {
                    if (p.progress.day < 3) {
                      p.progress.day++;
                      p.progress.stage = "dive";
                    } else p.progress.stage = "boss";
                  }
                  delete h.pendingStoryAdvance;
                }
                h.position = { ...defs.interior.entry };
              } else {
                near(point, defs.interior.chest, 180);
                if (!b.itemId || !b.stars)
                  fail("Pilih fragmen dan kualitasnya.");
                const source =
                    b.action === "deposit" ? p.inventory : h.storageLoot,
                  target = b.action === "deposit" ? h.storageLoot : p.inventory;
                const item = source.find(
                  (item) =>
                    item.fragmentId === b.itemId && item.stars === b.stars,
                );
                if (!item || item.quantity < b.qty)
                  fail("Stok fragmen tidak cukup.");
                if (
                  b.action === "deposit" &&
                  h.storageLoot.reduce((sum, item) => sum + item.quantity, 0) +
                    b.qty >
                    HOMESTEAD_DEFINITIONS.chestCapacity
                )
                  fail("Peti penuh.");
                item!.quantity -= b.qty;
                const old = target.find(
                  (item) =>
                    item.fragmentId === b.itemId && item.stars === b.stars,
                );
                if (old) old.quantity += b.qty;
                else
                  target.push({
                    fragmentId: b.itemId!,
                    stars: b.stars!,
                    quantity: b.qty,
                  });
                p.inventory = p.inventory.filter((item) => item.quantity > 0);
                h.storageLoot = h.storageLoot.filter(
                  (item) => item.quantity > 0,
                );
              }
            } else {
              const at = await outside(s, p);
              if (b.action === "permit") {
                near(at, defs.permitBoard);
                if (!p.progress.missions.includes("akar"))
                  fail(
                    "Pulihkan kebun Bu Darmi melalui misi akar terlebih dahulu.",
                    409,
                    "PERMIT_REQUIREMENT",
                  );
                if (!h.permit) {
                  h.permit = true;
                  h.seeds.benih_kangkung += HOMESTEAD_DEFINITIONS.starterSeeds;
                }
              } else if (b.action === "buy_seed") {
                near(at, defs.market);
                const crop = HOMESTEAD_DEFINITIONS.crops.find(
                  (crop) => crop.seedId === b.itemId,
                );
                if (!crop) return fail("Bibit tidak dikenal.");
                if (h.market.day !== c.calendarDay)
                  h.market = { day: c.calendarDay, bought: 0 };
                if (
                  h.market.bought + b.qty >
                  HOMESTEAD_DEFINITIONS.market.dailyStock
                )
                  fail("Stok bibit hari ini habis.", 409, "MARKET_STOCK");
                const price = b.qty * crop.price;
                if (p.coins < price) fail("Koin belum cukup.");
                p.coins -= price;
                h.market.bought += b.qty;
                h.seeds[crop.seedId] += b.qty;
              } else if (b.action === "stock_kedai") {
                const wira = WORLD.surface_hub.districts.find(
                  (district) => district.npc === "Mbah Wira",
                )!;
                near(at, wira);
                if (!b.itemId || !(b.itemId in HOMESTEAD_DEFINITIONS.servings))
                  return fail("Bahan kedai tidak dikenal.");
                const itemId =
                  b.itemId as keyof typeof HOMESTEAD_DEFINITIONS.servings;
                if (h.produce[itemId] < b.qty)
                  fail("Hasil budidaya tidak cukup.");
                h.produce[itemId] -= b.qty;
                h.pantry[itemId] += b.qty;
              } else if (
                ["stock_pen", "feed_pen", "harvest_pen"].includes(b.action)
              ) {
                const definition = HOMESTEAD_DEFINITIONS.fishPen,
                  pen = h.fishPen;
                near(at, defs.fishPen.interaction, 100);
                if (!h.permit || p.progress.day < definition.unlockStoryDay)
                  fail(
                    "Izin kebun dan siklus cerita kedua diperlukan untuk keramba.",
                    409,
                    "PEN_LOCKED",
                  );
                if (b.action === "stock_pen") {
                  if (
                    b.itemId !== definition.speciesId ||
                    b.qty !== definition.parentCount ||
                    pen.breeders
                  )
                    fail(
                      "Masukkan sepasang ikan seruni hidup ke keramba kosong.",
                    );
                  if (h.liveCatch.reef_seruni < definition.parentCount)
                    fail("Butuh dua ikan seruni tangkapan hidup Bintang3.");
                  h.liveCatch.reef_seruni -= definition.parentCount;
                  Object.assign(pen, {
                    breeders: definition.parentCount,
                    progressDays: 0,
                    fedDay: 0,
                    lastSettledDay: c.calendarDay,
                  });
                } else if (b.action === "feed_pen") {
                  if (pen.breeders !== definition.parentCount)
                    fail("Keramba belum berisi pasangan induk.");
                  if (pen.fedDay === c.calendarDay)
                    fail(
                      "Pakan hari ini sudah diberikan.",
                      409,
                      "PEN_ALREADY_FED",
                    );
                  if (pen.offspring >= definition.capacity)
                    fail(
                      "Panen hasil keramba yang penuh dahulu.",
                      409,
                      "PEN_FULL",
                    );
                  if (p.coins < definition.feedCost)
                    fail("Koin pakan belum cukup.");
                  p.coins -= definition.feedCost;
                  pen.fedDay = c.calendarDay;
                } else {
                  if (pen.offspring < b.qty)
                    fail("Hasil keramba belum cukup.", 409, "PEN_NOT_READY");
                  pen.offspring -= b.qty;
                  h.produce.ikan_seruni += b.qty;
                }
              } else {
                if (!h.permit)
                  fail(
                    "Dapatkan izin kebun dari Lurah setelah misi Bu Darmi.",
                    409,
                    "PERMIT_REQUIRED",
                  );
                const plot = cropPlot(h, b.plotId),
                  place = defs.gardenPlots.find((item) => item.id === plot.id);
                if (!place) fail("Petak belum tersedia.", 503);
                near(at, place!.interaction, 120);
                if (b.action === "plant") {
                  const crop = HOMESTEAD_DEFINITIONS.crops.find(
                    (crop) => crop.seedId === b.itemId,
                  );
                  if (!crop || plot.cropId)
                    return fail("Pilih bibit untuk petak kosong.");
                  if (h.seeds[crop.seedId] < 1) fail("Bibit habis.");
                  h.seeds[crop.seedId]--;
                  Object.assign(plot, {
                    cropId: crop.id,
                    growthDays: 0,
                    wateredDay: 0,
                    lastSettledDay: c.calendarDay,
                    needsCare: false,
                  });
                } else if (b.action === "water") {
                  if (!plot.cropId) fail("Petak belum ditanami.");
                  plot.wateredDay = c.calendarDay;
                  plot.needsCare = false;
                } else if (b.action === "harvest") {
                  const crop = HOMESTEAD_DEFINITIONS.crops.find(
                    (crop) => crop.id === plot.cropId,
                  );
                  if (!crop || plot.growthDays < crop.growthDays)
                    return fail(
                      "Tanaman belum siap panen.",
                      409,
                      "CROP_NOT_READY",
                    );
                  h.produce[crop.id] += crop.yield;
                  Object.assign(plot, {
                    cropId: null,
                    growthDays: 0,
                    wateredDay: 0,
                    lastSettledDay: c.calendarDay,
                    needsCare: false,
                  });
                }
              }
            }
            h.revision++;
            await saveDaily(s, p, session);
            return {
              transitionAt: Date.now(),
              ...dailyBundle(p),
              homesteadDefinitions: {
                ...HOMESTEAD_DEFINITIONS,
                locations: defs,
              },
              ...(b.action === "exit"
                ? {
                    surface: {
                      area: "hub",
                      ...defs.door,
                      layoutVersion: WORLD.hub.layoutVersion,
                      positionAt: Date.now(),
                      playerVersion: p.version,
                    },
                  }
                : {}),
            };
          },
        );
        const current = await dailyUser(s, req.user!.id);
        if (
          current.version === result.player.version &&
          current.homestead!.revision === result.homestead.revision
        ) {
          const target =
            b.action === "exit"
              ? "surface"
              : ["enter", "sleep"].includes(b.action)
                ? "home"
                : null;
          if (target) {
            const key = `${target}:${current.id}`,
              raw = await s.redis.get(key),
              previous = raw ? JSON.parse(raw) : null;
            if (!previous || previous.positionAt < result.transitionAt) {
              const point =
                target === "surface"
                  ? result.surface
                  : {
                      ...result.homestead.position,
                      playerVersion: current.version,
                      positionAt: result.transitionAt,
                    };
              await s.redis.set(key, JSON.stringify(point), "EX", 1800);
            }
          }
          if (b.action === "sleep") {
            const clockKey = `calendar:writer:${req.user!.id}`;
            const rawClock = await s.redis.get(clockKey);
            if (rawClock && JSON.parse(rawClock).lastAt <= result.transitionAt)
              await s.redis.del(clockKey);
          }
        }
        return result;
      });
    },
  );
}
