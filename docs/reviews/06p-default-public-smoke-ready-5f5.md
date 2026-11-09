# Default public smoke readiness — candidate 5f5baf24

Status: CPU preparation only. No public request, browser launch, fixture insertion or proxy mutation was performed for this package. GitLab CE migration was canceled by the user; it is not a dependency of this acceptance.

## Command ready for root's post-activation grant

Run from the combined source worktree containing this candidate's renderer/atlas/helpers. The script fixes the origin to `https://staging-jalasmara.ardianryan.com`; `APP_TEST_ORIGIN` does not redirect this public test.

```sh
env -u STAGING_HTTP1_DIAGNOSTIC \
RUN_STAGING_SMOKE=plan06-public \
STAGING_STARTUP_TRACE=1 \
PLAN06_EXPECT_PCK=5f5baf243a3bf941cf34fab6c143bb9cf2bc8d65997ded6ed4e048b929353f96 \
PLAN06_EXPECT_PCK_BYTES=64333184 \
node --import tsx scripts/staging-plan06-smoke.mjs
```

This keeps Chromium's default protocol negotiation. Startup tracing records actual asset protocol/IP/timing/bytes without adding `--disable-http2`. The traced startup deadline is 120 seconds, including on reload; the physical-route budget is eight minutes after initial readiness. An untraced run uses the older 240-second startup wait but lacks the needed CDP transport evidence. Do not silently change a failed traced run into an untraced or HTTP/1 diagnostic pass.

## Source and fixture review

The current public script already uses `keyboardPulse` and `corridorTargets` with the runtime `land.view.motion` matrix, derives the canopy target through `deriveCanopyTarget` from fetched world metadata and the actual left camera, and retains reveal >0/locality/opacity/trunk assertions. It does not use the stale unobscured `(350,1250)` target.

CPU inspection of the current combined world found hub layout 10 / forest layout 6. The authored new-player hub spawn `(1120,1230)` has a valid physical route with 15 vertices to the actual forest gate `(2295,125)`, physical length 2,689.6099 units. The forest target derives to `(142,1213)`, crown 46 (`renderer_forest_border_3`) among 47 crowns, 121.7087-unit route from the authored entry. Atlas SHA-256 is `1f07437f9ff5f9cbc063c191904eecf734ffad859b3daf6f0fccf177c8aa4564`. These are CPU route/alpha facts; this preparation does not claim the full public route has been traversed on the new candidate.

`node --import tsx --test scripts/canopy-route-fixture.test.mjs scripts/land-view-navigation.test.mjs scripts/gateway-route-fixture.test.mjs` passed **16/16** on the combined source; `node --check scripts/staging-plan06-smoke.mjs` passed. The local actual gateway 7/7 and canopy 4/4 evidence is in [the local browser report](06b-local-world-browser-acceptance-5f5.md). PCK/WASM body-failure recovery is separately covered in [the loader report](06p-loader-body-fault-browser.md). Neither is a public default-protocol pass.

## Required package and execution gates

1. Root finishes its release/backup/rollback checks and activates the immutable candidate. Until then the public server still serving the previous pin must fail preflight without creating an account.
2. Public health must return `status=ok`; the complete downloaded public PCK must match both required SHA and 64,333,184 decoded bytes. This Node-fetch preflight is package identity evidence, not Chromium transport acceptance.
3. Root grants the exclusive browser/WebGL slot. No concurrent native/export/other browser may run. No existing account or owner fixture is allowed; SSH/container setup and exact production-origin guards must match.
4. Actual form login must set the secure HttpOnly SameSite Lax cookie and start one real player actor within the recorded startup bound. CDP identifies the protocol actually negotiated; there is no asset/API interception.
5. Real input must follow the fetched physical hub route, E travel into the forest, reach the derived opaque crown, reveal only local foreground crowns, operate the 667×375 touch journal, pause/resume movement, save the forest position and restore it after reload. Coins/story/calendar invariants and zero console/API failures remain required.
6. The report must explicitly read `outcome=completed`, `defaultPublicAccepted=true`, `http1Diagnostic=false`, with all five checks and cleanup `ok=true` plus zero remaining players/receipts/shifts/keys. A timeout/assertion with empty API error arrays is still a failed smoke. Verify actual screenshots and request traces before accepting the release gate.

On any failure, retain its UUID/results/failure screenshot and CDP trace, close the browser, and complete only that fixture's cleanup. Report the exact failed stage and whether asset bodies finished, failed or remained pending. Do not rerun the whole route repeatedly without new evidence or reinterpret intentional browser-close cancellation as the cause of the initial failure.

## Transport interpretation from existing evidence

The older public default trace used HTTP/2: WASM completed normally in 102.726 seconds, while PCK remained incomplete at the 120-second bound. Neither asset emitted a body-read rejection before that bound. The older `--disable-http2` diagnostic used the same observed endpoint, with PCK complete in 2.801 seconds, WASM in 57.927 seconds and real game readiness around 70 seconds; it then failed at the stale canopy target. Root's separate curl transfers were substantially faster. Those results show a client/protocol-dependent transfer discrepancy; they do not isolate an HTTP/2 server defect, compile bottleneck, network shaping rule or proxy configuration error.

The now-tested Preloader/WASM rejection forwarding closes a real stream-error recovery gap: local injected partial-body failures reach error/retry UI and recover. The historical public trace instead showed pending/continuing bodies. Therefore successful recovery tests do not establish the cause of slow public HTTP/2 loading or prove that delay is fixed. The next default run must preserve protocol/IP/cache/body-progress evidence. Further A/B diagnostics, if needed, require root coordination and stay labeled diagnostic; no proxy mutation is authorized or performed here.
