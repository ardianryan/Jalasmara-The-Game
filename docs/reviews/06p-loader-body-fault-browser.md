# Loader body failure: local browser acceptance preparation

Status: local real Chromium/WebGL acceptance completed for both PCK and WASM body failures on the exact package below. This is an independent stream-error hardening acceptance test; it does not establish the cause of the historical public HTTP/2 download delay.

## Scope and actual changes

`scripts/loading-body-fault-browser.mjs` requires explicit `PLAN06_LOADER_FAULT=pck|wasm`, an exact PCK SHA/decoded-byte pin, and localhost API/Mongo/Redis. It downloads and validates the served export before creating its own UUID player. It requires both existing exporter hardening transforms to be present in the actual served JavaScript.

An ephemeral local HTTP server serves the first 262,144 actual decoded bytes of the chosen asset with HTTP 200 and the full declared content length, then destroys that response. Playwright rewrites only the chosen asset request to this server. Auth, APIs, the other asset, engine startup and gameplay are real. The server includes the local origin/CORP headers needed for the isolated game document.

The test requires body bytes and actual byte-progress messages, visible error/retry UI, and the existing attempt budget (PCK four; raw WASM one). It disables the fault and presses the real retry button, waits for the failed iframe to detach, then requires the replacement game to become ready with one player actor. Coins, inventory, story day/stage and the 36-minute calendar are checked. Injected asset/console failures are recorded separately from unexpected retry/API/page errors. A failed top-level assertion is explicitly marked failed in the report.

Each run cleans only its UUID player, receipts, shifts, Redis state and verified session digest. Browser/server shutdown failures do not bypass database cleanup. No owner fixture, reseed, public proxy or runtime product change is involved.

## CPU evidence

- `node --test scripts/loader-body-fault.test.mjs scripts/godot-preloader-stream.test.mjs scripts/godot-wasm-init-errors.test.mjs scripts/game-loading-bridge.test.mjs`: 25/25 passed (three new actual HTTP body tests and 22 existing loader/bridge tests).
- Both new server tests use Node's real fetch reader: HTTP 200 is received, the exact prefix is read, then body reading rejects. Headers and recorded byte counts are checked for both MIME types.
- The first CPU run failed two server-cleanup assertions because a socket close event followed the server close callback. The helper now awaits those actual socket close events; the rerun passed.
- JavaScript syntax and `git diff --check` passed.

## Actual browser evidence — 2026-11-09

Root granted one exclusive browser/WebGL slot after the gateway and canopy runs. Both fault runs were serial and verified the actual served loader before inserting their fixture. Required pin:

- PCK SHA-256 `5f5baf243a3bf941cf34fab6c143bb9cf2bc8d65997ded6ed4e048b929353f96`, 64,333,184 decoded bytes.
- WASM SHA-256 `fc74679e3b97f76878947fcd4fbe1268cbfa6188182a2e33bbc3f5dc9bfa57d0`, 39,514,754 decoded bytes.
- Patched served loader SHA-256 `a72d94cabd4b5cedcf66bebd84c97b6e8c3173c6b269f2fdfa887fd47597ad05`.

PCK UUID `58170688-a1e1-47ad-afed-8322b35a5bab`: **3/3 checks passed**, outcome completed, cleanup true. The own QA worktree `Jalasmara-06-loader-fault` ran commit `ab94b37`, byte-identical to root cherry-pick `f3d2f84`. CDP observed all four PCK attempts as HTTP 200 plus exactly 262,144 received body bytes, then `net::ERR_CONTENT_LENGTH_MISMATCH`. Healthy WASM finished normally. The actual error notice replaced the progress indicator and exposed one retry button. Clicking it replaced the failed iframe and reached the real game in **11,466 ms**, with exactly one player actor. No further injected requests occurred.

WASM UUID `fd305b1a-cdaa-41fb-ad69-e49be2542b91`: **3/3 checks passed**, outcome completed, cleanup true. This run used the root combined worktree `Jalasmara-06-buildings-gates`. One raw WASM HTTP 200 response delivered exactly 262,144 body bytes before the same real content-length failure; healthy PCK finished normally. The actual error/retry UI appeared and real retry reached the game in **10,495 ms**, with one player actor.

Both runs recorded zero unexpected retry asset failures, retry console errors, unhandled page errors or API failures. Coins, inventory, story stage/day and calendar invariants passed. Injected network/console errors remain recorded as intentional fault evidence; they are not described as server failures. Own player/receipt/shift/session/cache cleanup passed, and all browsers and ephemeral fault servers closed before releasing the slot.

Artifact roots:

- `/Users/ardianryan/Documents/Jalasmara-06-loader-fault/artifacts/browser/loader-body-pck-58170688-a1e1-47ad-afed-8322b35a5bab/`
- `/Users/ardianryan/Documents/Jalasmara-06-buildings-gates/artifacts/browser/loader-body-wasm-fd305b1a-cdaa-41fb-ad69-e49be2542b91/`

Each contains `01-real-partial-byte-progress.png`, `02-real-body-error-and-retry.png`, `03-real-ready-after-retry.png` and `results.json`. The report includes real CDP byte/failure records, loading messages, DOM progress values, request attempts and cleanup status. Screenshots reviewed: the themed harbor remains visible, the partial download shows actual received MB and percentage, and the error state presents readable retry/home actions without a stale progress bar.

No public HTTP/2 request was made by these tests. Public default-protocol startup/full smoke and physical-device performance remain open; local recovery evidence cannot close those gates.

## Reproduce

Run serially under the exclusive browser slot, only with the root-provided current local export pin:

```sh
APP_TEST_ORIGIN=http://localhost:3101 \
PLAN06_LOADER_FAULT=pck \
PLAN06_EXPECT_PCK=<required-current-sha256> \
PLAN06_EXPECT_PCK_BYTES=<required-current-decoded-bytes> \
node --import tsx scripts/loading-body-fault-browser.mjs
```

Repeat separately with `PLAN06_LOADER_FAULT=wasm`. Each mode has its own UUID/report and a 30-second failure-UI bound plus a 120-second real-retry readiness bound. Reports and screenshots go to `artifacts/browser/loader-body-<mode>-<uuid>/`. Actual browser rewrite/body failure and Godot/host recovery passed on the package recorded above; a different export requires its own pin. Default public HTTP/2 startup and the complete public smoke remain separate open acceptance work.
