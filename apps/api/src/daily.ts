import type { ClientSession } from "mongodb";
import { WORLD } from "../../../packages/shared/src/world.js";
import {
  CALENDAR_DAY_MS,
  freshCalendar,
  calendarRain,
  freshHomestead,
  HOMESTEAD_DEFINITIONS,
} from "../../../packages/shared/src/index.js";
import type {
  CalendarView,
  HomesteadState,
  GardenPlot,
} from "../../../packages/shared/src/index.js";
import { fail, publicUser, type Store, type User } from "./db.js";

export function ensureDaily(p: User): void {
  p.calendar ??= freshCalendar();
  p.homestead ??= freshHomestead(
    p.calendar.calendarDay,
    p.progress.missions.includes("akar"),
  );
}
export async function dailyUser(
  s: Store,
  id: string,
  session?: ClientSession,
): Promise<User> {
  const p = await s.users.findOne({ id }, { session });
  if (!p || p.status !== "active") return fail("Akun tidak aktif.", 403);
  const missingCalendar = !p.calendar,
    missingHome = !p.homestead;
  ensureDaily(p);
  if (missingCalendar || missingHome) {
    const saved = await s.users.updateOne(
      {
        id,
        version: p.version,
        ...(missingCalendar ? { calendar: { $exists: false } } : {}),
        ...(missingHome ? { homestead: { $exists: false } } : {}),
      },
      {
        $set: {
          ...(missingCalendar ? { calendar: p.calendar } : {}),
          ...(missingHome ? { homestead: p.homestead } : {}),
        },
      },
      { session },
    );
    if (!saved.matchedCount) return dailyUser(s, id, session);
  }
  return p;
}
export function settleCalendar(p: User, elapsedMs: number): void {
  ensureDaily(p);
  const calendar = p.calendar!;
  const total =
    calendar.minuteOfDay + (Math.max(0, elapsedMs) * 1440) / CALENDAR_DAY_MS;
  const days = Math.floor(total / 1440);
  setCalendar(p, calendar.calendarDay + days, total % 1440);
}
export function setCalendar(p: User, day: number, minute: number): void {
  ensureDaily(p);
  const c = p.calendar!,
    h = p.homestead!;
  for (let previous = c.lastSettledDay; previous < day; previous++) {
    for (const plot of h.plots) {
      if (!plot.cropId || plot.lastSettledDay > previous) continue;
      if (plot.growthDays < HOMESTEAD_DEFINITIONS.crop.growthDays) {
        const watered =
          plot.wateredDay === previous || calendarRain(p.id, previous);
        if (watered) plot.growthDays++;
        plot.needsCare = !watered;
      }
      plot.lastSettledDay = previous + 1;
    }
    h.revision++;
  }
  c.calendarDay = day;
  c.minuteOfDay = minute;
  c.lastSettledDay = day;
  c.calendarRevision++;
}
export function calendarView(
  p: User,
  writer = false,
  leaseExpiresAt?: number,
): CalendarView {
  ensureDaily(p);
  return {
    ...p.calendar!,
    serverNow: Date.now(),
    dayLengthMs: CALENDAR_DAY_MS,
    weather: { raining: calendarRain(p.id, p.calendar!.calendarDay) },
    writer,
    ...(leaseExpiresAt ? { leaseExpiresAt } : {}),
  };
}
export function homesteadView(p: User) {
  ensureDaily(p);
  const h = p.homestead!,
    day = p.calendar!.calendarDay;
  return {
    ...h,
    market: h.market.day === day ? h.market : { day, bought: 0 },
    plots: h.plots.map((plot) => ({
      ...plot,
      stage: !plot.cropId
        ? "empty"
        : plot.growthDays >= 3
          ? "ready"
          : (["seed", "sprout", "young"] as const)[plot.growthDays],
      watered: plot.wateredDay === day || calendarRain(p.id, day),
      ready: !!plot.cropId && plot.growthDays >= 3,
    })),
  };
}
export function dailyBundle(p: User) {
  return {
    player: publicUser(p),
    calendar: calendarView(p),
    homestead: homesteadView(p),
    homesteadDefinitions: {
      ...HOMESTEAD_DEFINITIONS,
      locations: WORLD.homestead,
    },
  };
}
export async function saveDaily(
  s: Store,
  p: User,
  session: ClientSession,
  bumpVersion = true,
) {
  const old = p.version;
  if (bumpVersion) p.version++;
  p.updatedAt = new Date().toISOString();
  const result = await s.users.updateOne(
    { id: p.id, version: old },
    {
      $set: {
        calendar: p.calendar,
        homestead: p.homestead,
        progress: p.progress,
        coins: p.coins,
        inventory: p.inventory,
        version: p.version,
        updatedAt: p.updatedAt,
      },
    },
    { session },
  );
  if (!result.matchedCount)
    return fail("Data berubah. Muat ulang.", 409, "SESSION_CHANGED");
}
export function cropPlot(
  h: HomesteadState,
  id: string | undefined,
): GardenPlot {
  const p = h.plots.find((plot) => plot.id === id);
  if (!p) return fail("Petak tidak dikenal.");
  return p;
}
