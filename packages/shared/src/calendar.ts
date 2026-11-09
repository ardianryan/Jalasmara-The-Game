export const CALENDAR_DAY_MS = 36 * 60 * 1000;
export interface CalendarState {
  calendarDay: number;
  minuteOfDay: number;
  calendarRevision: number;
  lastSettledDay: number;
}
export interface CalendarView extends CalendarState {
  serverNow: number;
  dayLengthMs: number;
  weather: { raining: boolean };
  writer: boolean;
  leaseExpiresAt?: number;
}
export const freshCalendar = (): CalendarState => ({
  calendarDay: 1,
  minuteOfDay: 360,
  calendarRevision: 0,
  lastSettledDay: 1,
});
export function calendarRain(id: string, day: number): boolean {
  let hash = 2166136261;
  for (const character of id)
    hash = Math.imul(hash ^ character.charCodeAt(0), 16777619);
  return ((hash >>> 0) + day * 7) % 5 === 0;
}
