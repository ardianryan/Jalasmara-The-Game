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
node --experimental-strip-types scripts/performance/recorder-browser.mjs
```

Do not use the old public5f5 package: it does not contain the newly integrated recorder/HUD. Do not run this local fixture on staging, on an existing user or through an owner login. Follow this check with the actual night-service keyboard/touch scroll flow and new garden/pen transactions; this harness does not prove those server gameplay loops.

## Focused night service mode: prepared separately

`NIGHT_SERVICE_ONLY=1` on `scripts/night-home-browser.mjs` now selects a separate local fixture at the actual walkable Wira service floor and667×375 coarse-pointer viewport. It retains the real authored day-one recipes, ingredient inventory, pantry prerequisite, keyboard serve receipts/coin/material checks, pending-story guard and owned-record cleanup. It skips unrelated home travel/sleep. This is an explicit initial fixture, never a runtime teleport or a claim that its inventory was earned by gameplay.

Before serving, it sends an actual CDP touch drag through the options scroller and captures both frames. A fixed interior opaque options-region hash must change, followed by the existing Space→Tab→Enter pantry/recipe flow and actual authoritative receipt. The frame-region check supplements mandatory screenshot inspection; it does not measure scroll offset, guarantee all recipe actions are initially visible or replace keyboard/receipt verification. The world remains paused. Existing full/home-only modes remain available. Results now distinguish overall passed/failed completion and include the failing stage even if no API/browser errors were recorded.

This mode is source-prepared and syntax-checked only, pending the new pin/browser grant. Run locally using the same required pin variables, `NIGHT_SERVICE_ONLY=1`, and `node --experimental-strip-types scripts/night-home-browser.mjs`. It does not establish new multi-crop/fish-pen gameplay acceptance.
