# Four-day jahe browser gate

**Actual complete lifecycle:10/10 PASS** after the integrator's exclusive browser grant. The preparation notes below remain explicit about supplied seed/permission; actual evidence and its limits follow.

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

## Actual browser result

The command above ran from the integrated `aee7f64` harness (integration HEAD477047d at initial inspection) on root's unchanged localhost3111 compiled host/API and PCK **73d456…/64,494,656bytes**. Full HTTP SHA/size verification preceded fixture insertion. Own UUID `35dea638-7b48-450d-9335-2ae81ac6d210`; actual844×390 touch-capable Headless Chromium/SwiftShader, with real keyboard UI/input. No runtime/API substitution or calendar/harvest injection occurred.

Outcome passed,10checks,0 browser/API failures, browserClosed=true, ownTemporaryPlayerRemoved=true and0 owned auth keys remaining. The recorded elapsed time, including post-start reload/action/cleanup waits, was**698,691ms**, independently verified below the900,000ms budget. The running harness was not altered and no retry/budget increase occurred. Parent review correctly noted that loop budgets do not preempt every response/attach wait; this acceptance uses actual measured elapsed time, not just that source guard.

Independent post-run inspection checked **actual response trace**, not merely the successful helper counters:19 `/api/homestead/action` responses, all HTTP200,19 distinct receipt keys and player versions exactly1→19. Counts: plant1,water4,enter4,sleep4,exit4,harvest1,stock_kedai1.

| Actual care | Watered calendar day | Growth before sleep | Sleep response calendar day | Growth after sleep | Ready |
| --- | ---: | ---: | ---: | ---: | --- |
| 1 | 2 | 0 | 3 | 1 | false |
| 2 | 3 | 1 | 4 | 2 | false |
| 3 | 4 | 2 | 5 | 3 | false |
| 4 | 5 | 3 | 6 | 4 | true |

All four actual bed requests carried confirmEarly=true; their server responses advanced exactly one calendar day to06:00. Harvest response version18/revision22 cleared plot1 and produced exactly3jahe. The first actual reload retained that stock. Wira's ordinary stock response version19/revision23 moved one to pantry, leaving produce2; the second reload retained pantry1/produce2,250coins,story2/dive,empty inventory,zero live catch/parents/offspring,empty plot2 and no other crop/fish produce. All these invariants were asserted on actual responses; seed1→0 happened only at planting. There is no sale/revenue or serving-bonus acceptance.

Cleanup verified only this UUID's player, receipts, shifts, surface/home/calendar/dive and owned auth keys were absent. One separate read-only lookup of this fixture's persisted surface confirmed progress near Wira; it changed no state. The browser slot was explicitly released after process exit and result inspection. This closes the crop lifecycle component; it adds no physical Windows/S23 FPS or natural-walking claim.

## Actual images and provenance

Integration directory `artifacts/browser/jahe-cycle-35dea638-7b48-450d-9335-2ae81ac6d210/`; log `.runtime/overnight-jahe-cycle-browser.log`.

| Artifact | SHA256 |
| --- | --- |
| `results.json` | `ffba41f900f68c4163904765da4d73b05a09bfafbc5e233c42948588d1c729d8` |
| `05-jahe-real-growth-day-4.png` | `86ff1d544f80f743676e56aca8f5765f2b3b4a3f5feb509c0b3599b12da2104c` |
| `08-wira-actual-harvested-jahe-stock-option.png` | `40aaf753dd401520be2a5411183e3c4bbd292bdd17affe1879b4772796683410` |
| `09-jahe-pantry-two-produce-persists.png` | `a32e1ba3ab415d58a7f17d0546c0dc7b36c7b4c739ba01ba1dd4157a90ed2eb7` |

Actual PNG review:01 shows the planted seed/real water control;02–05 show **bed settlement confirmations**, not rendered crop-stage visuals. Growth counts are authoritative response/ledger evidence.08 clearly shows Jahe dibawa3/stok0 and the actual stock button; keyboard focus has scrolled the pantry header above view, while the relevant quantities/button remain readable and reachable.09 shows the returned game HUD at250coins/H6 after reload; precise final produce/pantry quantities come from the asserted server ledger. These images are not evidence of a complete crop-animation/mesh-stage review.
