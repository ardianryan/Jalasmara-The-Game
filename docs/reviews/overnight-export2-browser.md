# Export2: actual night service and segmented-loader recovery

Actual local browser acceptance completed on 2026-11-09 UTC (2026-11-10 WIB), serially with the exclusive browser/WebGL slot. Integration source was `593dc7912b4b691363633f198a898196cd18fc5b`; the live localhost:3111 PCK was independently hashed before each fixture: `1315f34672b0fc5694a5f73684ca68bfbc6b5be1f6f4560b9628cc14ac2ef5e0`, 64,491,320 bytes, 62 versioned parts of at most 1 MiB. WASM was 39,514,754 decoded bytes, SHA `fc74679e3b97f76878947fcd4fbe1268cbfa6188182a2e33bbc3f5dc9bfa57d0`; the served patched loader SHA was `e0f98e788a26bd533f9307972d609bafc6765bb1509cb5c16160fa48e524b0c6`.

Each run used a newly created local UUID fixture and real Chromium/SwiftShader gameplay or loading. Each independently verified deletion of its player, receipts, shifts and exact Redis/session keys. No owner account, reset/reseed, proxy change, additional server, PCK override or mocked game was used. The fault server intentionally interrupted only the specified real asset body. Those expected injected network errors are separated from unexpected retry and API errors. The browser slot was explicitly released after all three runs.

| Run | Actual result | Cleanup |
|---|---|---|
| Focused night `a132bec9-ced2-4f7b-be7b-4f1942d22529` | 11 checks, six real kedai operations, 45,923 ms after game attach; zero browser/API errors |verified true |
| PCK part 2 `cc38682b-f39b-4e61-b4a0-1bf26376e79d` | 4 checks, four expected partial-body failures, real UI retry to actual game in 12,258 ms |verified true |
| WASM `aa791920-25d6-4029-a5d0-f76dff71068d` | 3 checks, one expected partial-body failure, real UI retry to actual game in 11,942 ms |verified true |

## Actual night interaction

At 667×375, a real touch drag advanced the measured option scroller and changed its opaque pixel region while the actual pinned header stayed fixed. Escape closed the panel; holding ArrowRight for 450 ms retained the acknowledged service point and produced no forbidden surface write. E reopened the same unserved shift through authenticated `/kedai/start`, closing both gaps described in [the resume review](overnight-kedai-resume.md). The only surface-position request in this run preceded the initial shift and returned 200. The historical 409 remains documented as a fixed earlier-package failure, rather than being erased from its report.

The first recipe used the actual checkbox and keyboard flow; the second used a real CDP touch tap at the focused recipe's measured physical rectangle; the remaining recipe used normal keyboard input. Three authoritative serve responses returned 145/140/140 coins, with the first consuming one real kangkung pantry item and awarding the expected 5 coin bonus. Correct ingredient consumption and recipe receipts were asserted. The shift closed normally, its receipts persisted, and story advancement remained pending home sleep. No direct server call substituted for a UI action.

The result dialogue, ordinary nighttime HUD and bag opening/closing were checked at 667×375 and 390×844. Actual screenshots were inspected: the central landscape service panel has readable pinned context and opaque options; the portrait result dialogue stays within the screen, has readable body text and a reachable continuation action. This actual short day-one complaint does not replace the separate longest-complaint native fixture. Recipe options may require scrolling for long context; there is no claim that all actions remain simultaneously visible. The fixture started at the real Wira service point; this focused mode does not prove an entire walking route or home/sleep flow.

Local evidence under integration `artifacts/browser/night-home-a132bec9-ced2-4f7b-be7b-4f1942d22529/`: `results.json`, `00-service-667-pinned-context-before-touch-scroll.png`, `00-service-667-options-after-real-touch-scroll.png`, `01-focused-recipe-before-actual-touch-tap.png`, both `02-night-result-dialogue-*` and bag/clear-gameplay captures. Ordered request trace and all eleven check names are retained in the JSON. Log: `.runtime/overnight-night-service-export2.log`.

## Actual PCK part 2 body error and recovery

The preflight fetched the real versioned part 2 and verified its content length 1,048,576, offset 2,097,152, total 64,491,320 and manifest SHA before using its actual 256 KiB prefix. Four upstream attempts each received HTTP 200 with correct metadata, consumed 262,144 bytes, then lost the body socket. This is a body-failure proof, not a metadata rejection.

The loading bridge reported 41,611,906 actual bytes before the error: 39,514,754 WASM plus 2,097,152 earlier verified PCK bytes. It did not count unverified part 2 as completed. The visible themed error removed the percentage/progressbar and offered one clear “Muat ulang permainan” action. The real retry button replaced the failed iframe, requested healthy origin assets, and started the actual game with one rendered player. Coins, inventory and story state stayed unchanged. There were four expected injected asset failures/five expected injected console messages, zero unhandled page errors, zero API failures, and zero asset/console errors during healthy retry.

Evidence: integration `artifacts/browser/loader-body-pck-cc38682b-f39b-4e61-b4a0-1bf26376e79d/`, containing `results.json`, actual-progress, handled-error and ready-after-retry PNGs. The actual handled-error image was inspected: themed scene remains visible, the message is readable, and the retry target is clear. Log: `.runtime/overnight-pck-body-fault-export2.log`.

## Actual WASM body error and recovery

A separate UUID and browser received one raw WASM HTTP 200 response with correct full content length and the actual 262,144 byte prefix, followed by a socket abort. The error reached the visible host UI without an unhandled rejection or repeated raw-consumer attempt. The normal retry button replaced the iframe and started the actual game from healthy assets. The economic/story invariants and one rendered player were checked again. There was one expected injected asset failure/two expected injected console messages; unhandled page, API and healthy-retry errors were all zero.

Evidence: integration `artifacts/browser/loader-body-wasm-aa791920-25d6-4029-a5d0-f76dff71068d/` with the same three screenshot stages and full result/transfer records. Log: `.runtime/overnight-wasm-body-fault-export2.log`.

## Reproduction and limits

Run from the combined integration worktree, using its existing localhost:3111 server:

```sh
APP_TEST_ORIGIN=http://localhost:3111 PLAN06_EXPECT_PCK=1315f34672b0fc5694a5f73684ca68bfbc6b5be1f6f4560b9628cc14ac2ef5e0 PLAN06_EXPECT_PCK_BYTES=64491320 NIGHT_SERVICE_ONLY=1 node --import tsx scripts/night-home-browser.mjs
APP_TEST_ORIGIN=http://localhost:3111 PLAN06_EXPECT_PCK=1315f34672b0fc5694a5f73684ca68bfbc6b5be1f6f4560b9628cc14ac2ef5e0 PLAN06_EXPECT_PCK_BYTES=64491320 PLAN06_LOADER_FAULT=pck node --import tsx scripts/loading-body-fault-browser.mjs
APP_TEST_ORIGIN=http://localhost:3111 PLAN06_EXPECT_PCK=1315f34672b0fc5694a5f73684ca68bfbc6b5be1f6f4560b9628cc14ac2ef5e0 PLAN06_EXPECT_PCK_BYTES=64491320 PLAN06_LOADER_FAULT=wasm node --import tsx scripts/loading-body-fault-browser.mjs
```

These are actual local, emulated-touch browser results. They do not establish physical Samsung S23/Windows performance, public HTTP2 delivery, a deployed release, new garden/pen transactions, or broad world traversal. The previously accepted private-recorder download remains scoped to its own earlier 1d3 package/report. No new assets or licenses were introduced. Root owns final integration, release and any public smoke; no public browser request was made in this acceptance batch.
