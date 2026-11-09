# Lazy-admin public host gate — prepared, not executed

Root activated image `a9f984ddf59fdf52aab08a897df2893346b419975ebca755c977a5580f8169d3` after verifying its web/API files and the unchanged game package. The earlier full public route6/6 PASS remains [separate evidence](overnight-export3-public-smoke.md). The next narrow run will validate the changed host without repeating that long route.

`STAGING_HOST_ONLY=1` is an explicit opt-in within the existing guarded staging smoke. It reuses the fresh real player fixture, form login, secure-cookie check, actual HTTP PCK pin, real Godot READY and actual reload at the unchanged hub spawn. The new iframe must regain writer ownership and advance authoritative active time via the existing≤35second heartbeat gate; position/story1/200coins/empty inventory/version/day-length checks remain. All guest/login/player/reload script requests are recorded by pathname, requiring a compiled main entry and **no admin chunk**.

A separate fresh browser context then loads the actual HTTPS compiled `/admin` route while **every `/api/**` request is intercepted**. The synthetic role-owner session and empty player/catalog/version responses are fixture data only. No real owner authentication, privileged API request, account mutation or authorization acceptance is performed. Unexpected API methods/paths reject instead of falling through to the real server; `/game/**` is blocked and must not be requested. The actual hashed admin JavaScript chunk must return successful JavaScript bytes, and its real component must render the empty player list. The decoded chunk size/SHA and synthetic-API paths are recorded. This is module-delivery/render proof, not an admin business-flow test.

Host success yields `hostPublicAccepted=true`, `defaultPublicAccepted=false` and an explicit host-only scope. Full default smoke retains its original six-check route body (verified identical after extraction with whitespace normalized) and eight-minute budget; host mode has a separate three-minute post-start bound. HTTP1 override is disallowed for host acceptance. Guest/player and fixture-owner requests are kept separate. A browser-shutdown exception now marks failure while still attempting the own-UUID cleanup; no successful-shutdown behavior changes.

Three CPU scope tests passed: exact same-origin admin-chunk path detection, mutual exclusion between host/full acceptance, and no acceptance for failed cleanup/outcome or HTTP1 diagnostic. The existing three actual-heartbeat protocol tests also passed. Syntax/format/diff checks passed. No new browser, API fixture, SSH action, GPU or Godot process has been launched for this mode yet; it still requires root's explicit GO.

```sh
RUN_STAGING_SMOKE=plan06-public STAGING_STARTUP_TRACE=1 STAGING_HOST_ONLY=1 \
PLAN06_EXPECT_PCK=73d45630ab69033ac36a64740ecc73ecdb7363c9f99805222b6a9237dcb2d18b \
PLAN06_EXPECT_PCK_BYTES=64494656 \
node --import tsx scripts/staging-plan06-smoke.mjs
```
