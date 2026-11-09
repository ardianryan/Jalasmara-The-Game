# Four-day jahe browser gate — prepared, not executed

The existing garden/pen browser proved real jahe selection/watering and pantry UI, but supplied one harvested jahe in its fixture and did not execute four growth days. The new independent `scripts/jahe-cycle-browser.mjs` covers that missing crop lifecycle with the current actual game and authority. No production UI, world, calendar or economy code changes are included.

## Declared setup and route

Only dedicated localhost/127.0.0.1:3111 is accepted, with local Mongo/Redis and a fresh own UUID. The exact HTTP PCK SHA/size must pass before fixture insertion. Setup explicitly supplies story day2/mission `akar`, permission,250coins, **one jahe seed**, calendar day2 at08:00, and a legal plot1 approach. It supplies zero produce, pantry, live catch, parents, offspring and knowledge loot; the other plot is empty. This is not acquisition/mission/permit proof.

A naturally dry UUID is selected using the actual deterministic `calendarRain` for care days2–5; there is no runtime weather override. Shared geometry derives the actual plot, home approach, and Wira district. The legal authored bed approach270/330 is used; the bed center270/250 is inside its obstacle. All movement uses actual keyboard input: emitted land motion matrix outdoors and the established interior controls. No mid-route teleport, post-setup calendar/day/harvest write, route interception or substituted action response is used.

The planned ten completed checks are:

1. Verify declared fixture has no produce/pantry/parents.
2. Actual plant consumes exactly the one seed, with growth0 and no produce.
3. Four separate care checks: each actual water action at the dry plot, actual walk through Griya/bed early-sleep confirmation, one server calendar advance and one growth day. Growth0→1→2→3→4; calendar2→6. Each cycle exits through the real door and returns to the plot.
4. Actual harvest yields exactly3jahe and clears only plot1.
5. Actual reload preserves that harvested stock and ledger.
6. Actual walk to Wira and ordinary pantry UI moves1jahe to pantry, leaving2carried.
7. A second actual reload preserves pantry1/produce2 with unchanged250coins, story2/dive, empty knowledge inventory, zero parents/live catch/offspring and empty other crop types.

There is **no direct crop-sale action** in the current homestead authority. `stock_kedai` moves produce to pantry without revenue; the test calls this stocking, not a sale. Actual serving and its12coin jahe bonus require a valid shift/recipe/knowledge flow and are not claimed here. Current watering/plant/sleep/harvest/stock actions have no coin fee; each actual response must retain250coins, so unexpected fees or invented rewards fail.

## Bounds, evidence and preparation checks

Navigation budget15minutes, unchanged450input-attempt/20-stuck checks and25second scene predicates; each actual iframe startup/reload has a240second timeout. The pre-fixture pinned PCK download is bounded180seconds. No automatic rerun or budget widening is included. An actual run will print a sanitized phase/check heartbeat every30seconds, retain action/request/revision/calendar/seed/plot/produce ledgers and original screenshots. Failure capture is bounded3seconds for snapshot and5seconds for PNG. A potentially uncertain insert is marked attempted before awaiting acknowledgement. Browser shutdown exceptions cannot skip the UUID-scoped DB/Redis/auth cleanup; zero remaining players/receipts/shifts/owned keys is asserted.

Two CPU tests passed: the current actual plot/bed/Wira routes are walkable without WORLD mutation; changed crop requirements and an unreachable authored bed reject setup. `node --check`, Prettier and `git diff --check` passed. The helper requires the actual four-day/three-yield definition instead of shortening it to fit the test. **No browser/Godot/fixture was started yet.** Root owns the next review and explicit grant.

```sh
APP_TEST_ORIGIN=http://localhost:3111 \
PLAN06_EXPECT_PCK=73d45630ab69033ac36a64740ecc73ecdb7363c9f99805222b6a9237dcb2d18b \
PLAN06_EXPECT_PCK_BYTES=64494656 \
node --import tsx scripts/jahe-cycle-browser.mjs
```
