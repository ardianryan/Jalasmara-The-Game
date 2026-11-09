# Post-reload clock acceptance

The source-only gate below was subsequently executed in the [export3 public smoke](overnight-export3-public-smoke.md): full6/6 PASS, actual writer recovery plus5,285ms equivalent authoritative active advancement within8,898ms. The prepared-source notes are retained to distinguish the earlier instantaneous screenshot from the later actual proof.

The actual export3 forest component passed touch/bridge/position reload, but its first reload PNG displayed “Jam aktif di sesi lain.” That instantaneous image does not prove a stuck clock. The existing server retains a different page's writer lease for20seconds; CalendarSync generates a page UUID and sends normal heartbeats every5seconds. No production calendar change is made from this observation.

The next explicitly granted public smoke now keeps its existing position/story/coins/configuration assertions and adds a separate **≤35second** post-reload gate, within the unchanged eight-minute overall route budget. It listens only to actual `/api/calendar/heartbeat` POST responses from the newly attached game iframe. No direct replacement heartbeat, lease injection, clock mutation, alternate account or extra gameplay action is introduced.

`weather.clockWriter`, `clockConnected` and `clockPaused` are observable through the existing opt-in snapshot, but a HUD label alone is insufficient. The gate requires a real HTTP200 focused/unpaused writer heartbeat, then a later writer response with increasing server timestamp and calendar revision. `calendarDay`/`minuteOfDay` must advance by at least1second of active real-time equivalent using the authoritative `dayLengthMs` conversion. There is no server `activeElapsed` field; the report names this value `activeElapsedMs` derived from authoritative calendar positions, rather than inventing a response field. The snapshot must also be connected, writer-owned and unpaused. This covers20seconds lease grace plus5second cadence and subsequent active advancement without assuming the first writer response itself advances time.

Only sanitized timing/calendar/boolean/status fields enter result observations. The listener excludes the old iframe, records no page-session UUID, request headers, cookie, email, password or player document, and is detached in finally. A timeout records failure stage `post-reload-calendar-writer`; existing own-UUID cleanup still runs. A successful check has its own explicit name and screenshot `05-public-calendar-writer-resumes-after-reload.png`.

Three CPU sequence tests passed: ownership without active advance is rejected; paused/unfocused/non-writer/error/unchanged-revision or changed-day-length responses cannot substitute; real day rollover produces the correct elapsed equivalent while invalid data rejects. Syntax, formatting and diff checks passed. These are harness tests, **not actual clock reacquisition proof**. No new browser, public request, SSH fixture or Godot process was launched for this source change.

The next command remains the existing fixed-origin public smoke, only after the integrator activates/verifies its package and explicitly grants the slot:

```sh
RUN_STAGING_SMOKE=plan06-public STAGING_STARTUP_TRACE=1 \
PLAN06_EXPECT_PCK=73d45630ab69033ac36a64740ecc73ecdb7363c9f99805222b6a9237dcb2d18b \
PLAN06_EXPECT_PCK_BYTES=64494656 \
node --import tsx scripts/staging-plan06-smoke.mjs
```

No HTTP1 diagnostic flag or shared proxy change is part of this acceptance.
