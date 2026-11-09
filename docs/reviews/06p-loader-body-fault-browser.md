# Loader body failure: local browser acceptance preparation

Status: source-only QA candidate. No browser or WebGL execution yet. This is an independent stream-error hardening acceptance test; it does not establish the cause of the historical public HTTP/2 download delay.

## Scope and actual changes

`scripts/loading-body-fault-browser.mjs` requires explicit `PLAN06_LOADER_FAULT=pck|wasm`, an exact PCK SHA/decoded-byte pin, and localhost API/Mongo/Redis. It downloads and validates the served export before creating its own UUID player. It requires both existing exporter hardening transforms to be present in the actual served JavaScript.

An ephemeral local HTTP server serves the first 262,144 actual decoded bytes of the chosen asset with HTTP 200 and the full declared content length, then destroys that response. Playwright rewrites only the chosen asset request to this server. Auth, APIs, the other asset, engine startup and gameplay are real. The server includes the local origin/CORP headers needed for the isolated game document.

The test requires body bytes and actual byte-progress messages, visible error/retry UI, and the existing attempt budget (PCK four; raw WASM one). It disables the fault and presses the real retry button, waits for the failed iframe to detach, then requires the replacement game to become ready with one player actor. Coins, inventory, story day/stage and the 36-minute calendar are checked. Injected asset/console failures are recorded separately from unexpected retry/API/page errors. A failed top-level assertion is explicitly marked failed in the report.

Each run cleans only its UUID player, receipts, shifts, Redis state and verified session digest. Browser/server shutdown failures do not bypass database cleanup. No owner fixture, reseed, public proxy or runtime product change is involved.

## CPU evidence

- `node --test scripts/loader-body-fault.test.mjs scripts/godot-preloader-stream.test.mjs scripts/godot-wasm-init-errors.test.mjs scripts/game-loading-bridge.test.mjs`: 25/25 passed (three new actual HTTP body tests and 22 existing loader/bridge tests).
- Both new server tests use Node's real fetch reader: HTTP 200 is received, the exact prefix is read, then body reading rejects. Headers and recorded byte counts are checked for both MIME types.
- The first CPU run failed two server-cleanup assertions because a socket close event followed the server close callback. The helper now awaits those actual socket close events; the rerun passed.
- JavaScript syntax and `git diff --check` passed. No browser result is claimed by this preparation report.

## Next run

Run serially after the granted gateway/canopy acceptance, only with the root-provided current local export pin:

```sh
APP_TEST_ORIGIN=http://localhost:3101 \
PLAN06_LOADER_FAULT=pck \
PLAN06_EXPECT_PCK=<required-current-sha256> \
PLAN06_EXPECT_PCK_BYTES=<required-current-decoded-bytes> \
node --import tsx scripts/loading-body-fault-browser.mjs
```

Repeat separately with `PLAN06_LOADER_FAULT=wasm`. Each mode has its own UUID/report and a 30-second failure-UI bound plus a 120-second real-retry readiness bound. Reports and screenshots go to `artifacts/browser/loader-body-<mode>-<uuid>/`. Browser rewrite behavior and actual Godot/host recovery remain unproven until these runs finish. Default public HTTP/2 startup and the complete public smoke remain separate open acceptance work.
