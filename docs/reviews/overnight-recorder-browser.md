# Actual private-recorder browser acceptance: prepared

The standalone `scripts/performance/recorder-browser.mjs` is ready and syntax-checked. It has not yet run: root owns the new combined export, PCK hash and serialized browser grant. This preparation does not close the browser/private-download acceptance gate.

The harness only accepts a localhost origin and local Mongo/Redis. Before creating a UUID player, it downloads the live PCK under a30s abort signal and verifies its required SHA-256 and exact byte count. It creates only its own named fixture, uses actual login and Godot canvas, and does not enable full diagnostic/account snapshots. It starts the real30-second menu option, closes the menu into gameplay, provides a short actual keyboard input, records real monitor samples, opens the menu for2.2s, resumes, manually stops and downloads the actual browser-generated JSON. There is no mocked game, monitor value or hardware string.

Assertions cover real samples and browser metadata, paused callback/sample presence, actual download filename/schema, manual-stop reason, locally generated report without UUID/email/password/account/page URL, and no engine/API errors. It records the actual software-renderer metadata as a local browser test; it does not claim physical Windows or Samsung S23 performance. The configured30-second capture is manually stopped, so neither automatic expiry nor5-minute completion is covered. CPU privacy/distribution tests already cover exact pause exclusion; this browser check establishes actual UI wiring and download behavior.

The finally block closes its browser and removes only the fixture's named UUID player, receipts, shifts, surface/home/dive/writer keys and hashed auth session after validating session ownership. It checks zero remaining fixture records/keys. Results include passed/failed outcome, sanitized failure stage, actual errors and explicit cleanup status; screenshots/download remain ignored artifacts. Cleanup failure cannot report an overall pass.

After root grants the browser slot and provides the new pin, run from the combined worktree with local DB/Redis configuration:

```sh
APP_TEST_ORIGIN=http://localhost:3111 \
PLAN06_EXPECT_PCK=<required-new-64-character-sha256> \
PLAN06_EXPECT_PCK_BYTES=<required-new-byte-count> \
node --import tsx scripts/performance/recorder-browser.mjs
```

Do not use the old public5f5 package: it does not contain the newly integrated recorder/HUD. Do not run this local fixture on staging, on an existing user or through an owner login. Follow this check with the actual night-service keyboard/touch scroll flow and new garden/pen transactions; this harness does not prove those server gameplay loops.

## Focused night service mode: prepared separately

`NIGHT_SERVICE_ONLY=1` on `scripts/night-home-browser.mjs` now selects a separate local fixture at the actual walkable Wira service floor and667×375 coarse-pointer viewport. It retains the real authored day-one recipes, ingredient inventory, pantry prerequisite, keyboard serve receipts/coin/material checks, pending-story guard and owned-record cleanup. It skips unrelated home travel/sleep. This is an explicit initial fixture, never a runtime teleport or a claim that its inventory was earned by gameplay.

Before serving, it sends an actual CDP touch drag through the options scroller and captures both frames. A fixed interior opaque options-region hash must change, followed by the existing Space→Tab→Enter pantry/recipe flow and actual authoritative receipt. The frame-region check supplements mandatory screenshot inspection; it does not measure scroll offset, guarantee all recipe actions are initially visible or replace keyboard/receipt verification. The world remains paused during the swipe. It then closes with Escape and reopens the same unserved shift through the actual E interaction, restoring authored keyboard focus before checking the Space→Tab→Enter sequence; it does not claim that arbitrary focus retained after touch is the initial checkbox. Existing full/home-only modes remain available. Results now distinguish overall passed/failed completion and include the failing stage even if no API/browser errors were recorded.

This mode is source-prepared and syntax-checked only, pending the new pin/browser grant. Run locally using the same required pin variables, `NIGHT_SERVICE_ONLY=1`, and `node --import tsx scripts/night-home-browser.mjs`. It does not establish new multi-crop/fish-pen gameplay acceptance.

## Actual local candidate checkpoint

Root granted the serialized browser slot on source `1b67a9b`, PCK `1d3c94a5a449fe1e21ea6346da56f0684a1c3ccd0677100361296fc46923a2d8`,64,488,008 bytes, localhost3111. The first native-strip-types command failed at module resolution before creating a fixture: shared TypeScript uses `.js` import specifiers. Re-running with the repository's existing `node --import tsx` resolver succeeded; commands above are corrected. The failed invocation is retained in the combined worktree `.runtime/overnight-recorder-browser-strip-types.log`.

The actual recorder passed all four checks with zero browser/API errors and verified own UUID/session cleanup. It started the real30s option without enabling full diagnostic snapshots, paused through the menu, resumed, manually stopped and downloaded the actual private JSON. Duration10,953.7ms,10 monitor samples (6 unpaused engine samples),139 eligible callbacks and73 paused callbacks. Actual renderer metadata is Google ANGLE/SwiftShader, explicitly software rendering, not physical Windows or Samsung S23 performance. Artifacts: combined `artifacts/browser/performance-recorder-3e9706b8-6d78-4949-b3ac-5de2e3f7b2a0/results.json`, `downloaded-performance.json` and actual-game/menu/download PNGs. Inspecting the actual844×390 gameplay capture shows compact HUD targets with the world/player visible and the64×48 host Menu clear of the HUD.

Focused night did not pass the whole flow. UUID `9832868f-3d9a-4888-b6a8-e35818854879` reached the actual667×375 Wira service and passed the real touch-scroll interior-region change check, with before/after PNGs. The actual first complaint is Bu Ratri's shorter day-one line, not the native worst-case akar line. After Escape, E could not reopen the active shift: `/api/adventure/surface-position` returned409 `INVALID`, “Tutup giliran kedai sebelum menjelajah daratan.” No serve receipt was made or claimed.

Trace order: `/kedai/start`200 sequence4; paused heartbeat200 sequences5/6; Escape heartbeat paused=false200 sequence7; unchanged-point595,650 surface sync409 sequence8 (version0, fromPositionAt1794242117171; request1794242125853, response1794242126132); no second `/kedai/start`. Source inspection confirms `_npc_interact` calls `_sync_surface` before its Wira/night branch, so the existing active-shift server guard blocks reopening. This is a real resume interaction gap, reported immediately to root, not stale-version arithmetic or a hidden loading timeout. Root owns the production correction; this lane made no Main/API workaround.

Night failure/results and exact trace remain in combined `artifacts/browser/night-home-9832868f-3d9a-4888-b6a8-e35818854879/`. Overall outcome is failed, one partial check, one actual API409/browser resource error; fixture cleanup is verified true and the browser closed. The serialized slot was explicitly released. Required next work: fix and test the legitimate active-shift resume interaction, export/pin the new candidate, rerun focused night, then run segmented PCK/WASM body-fault recovery. Recorder's earlier pass remains scoped to the stated package; no public or physical-device pass is claimed.
