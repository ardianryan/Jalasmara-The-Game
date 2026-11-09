export function calendarResumeProof(records) {
  const active = records.filter(
    (record) =>
      record.status === 200 &&
      record.focused === true &&
      record.paused === false &&
      record.writer === true &&
      Number.isFinite(record.at) &&
      Number.isFinite(record.serverNow) &&
      Number.isSafeInteger(record.calendarDay) &&
      record.calendarDay > 0 &&
      Number.isFinite(record.minuteOfDay) &&
      record.minuteOfDay >= 0 &&
      record.minuteOfDay < 1440 &&
      Number.isSafeInteger(record.calendarRevision) &&
      Number.isFinite(record.dayLengthMs) &&
      record.dayLengthMs > 0,
  );
  for (const first of active) {
    for (const later of active) {
      if (
        later.at <= first.at ||
        later.serverNow <= first.serverNow ||
        later.calendarRevision <= first.calendarRevision ||
        later.dayLengthMs !== first.dayLengthMs
      )
        continue;
      const minutes =
        (later.calendarDay - first.calendarDay) * 1440 +
        later.minuteOfDay -
        first.minuteOfDay;
      const activeElapsedMs = (minutes * first.dayLengthMs) / 1440;
      if (activeElapsedMs >= 1000)
        return {
          writerObservedAt: first.at,
          advancingObservedAt: later.at,
          activeElapsedMs,
          revisionBefore: first.calendarRevision,
          revisionAfter: later.calendarRevision,
        };
    }
  }
  return null;
}
