# Day-loop gameplay check — 12 November 2026

The owner confirmed WASD works and requested a gameplay test. No runtime, account, release, or server configuration was changed. Test source was `main` `5f124fc72a0abbc0566d786f2b3b424929b14231`; the local served PCK and public staging PCK both matched SHA-256 `a2206c8993cc55469d45627417891b1e9290fc757c49c6b871749f27fb1e43f6` at 69,774,796 bytes. This is the released game from source `128fc592f9fe15cc2803a1a734a8200f39ee1422`.

## Results

| Check | Result | Evidence and scope |
| --- | --- | --- |
| Kedai → home → sleep → reload | **PASS 7/7** | Local Chromium/SwiftShader, one isolated player. Three real service receipts, shift close, physical walk to Griya, real bed action, story/calendar day 1→2, 100→525 coins, then home exit and reload. Zero page/console errors or unexpected API failures; own player removed. Local result: `artifacts/browser/night-home-7667ee53-b077-4e0e-b599-86e26ef834e1/results.json`, SHA-256 `d5192973167067c7a6f3cfa73e3d92d35c7b127d36b9f62aa0d65d56cbdee292`. |
| Dive → capture → extraction → fish pen → sleep → harvest → reload | **PASS 8/8** | Local Chromium/SwiftShader, a second isolated player. Two actual three-star captures, live extraction, two parents stocked, two fed bed sleeps, one offspring harvested, 250→246 coins, two knowledge fragments retained, canonical state unchanged after reload. Zero page/console errors or unexpected API failures; own player and auth keys removed. Local result: `artifacts/browser/live-parent-35ccbd85-ed86-4c52-9525-f092c53085aa/results.json`, SHA-256 `2731d6badca168e4f8338712d0a11cca83a10f0196c7a0262c53f1cc1b474c8a`. |
| Public HTTPS staging → village/forest → journal → reload | **PASS 6/6** | Fresh disposable staging player; actual downloaded PCK pin, secure form login, physical forest gate/canopy, touch journal pause, saved forest position and authoritative active clock after reload. Zero browser/API failures. SSH cleanup verified **0** players, receipts, shifts, and Redis keys. Local result: `artifacts/browser/staging-plan06-32e2e45a-2bb4-4c26-b0a7-cff7d160aada/results.json`, SHA-256 `4fb3bb4c9053e16bea248c6dd9afe6b936a8d5043e00aaad776de50348cd0667`. |

The isolated local fixtures intentionally differed: the Kedai case began at story day 1/night with the three required recipe fragments and one kangkung already supplied; the dive case began at story/calendar day 2 with a lawful permit and level-3 gear, but no live catch, parents, offspring, produce, or inventory. The public forest case began at story day 1. The actions and persistence within each case were genuine browser/game/API interactions. **These three passes do not prove one uninterrupted forest → dive → Kedai → sleep journey by a single newly created player.** The full owner-account journey also remains untested. The image captures were reviewed for the tested visible states, not final artistic acceptance or motion quality.

Original project evidence is curated in the [visual gallery](../visual/README.md): [capture](../visual/day-loop-local-capture-20261112.png), [morning after reload](../visual/day-loop-local-morning-20261112.png), and [public forest](../visual/day-loop-staging-forest-20261112.png). Raw screenshots/results stay in ignored `artifacts/browser/`. No owner credentials or account data were used.

## Commands and cleanup

The local test server used the existing compiled API/Web build and an isolated MongoDB replica set on `127.0.0.1:27018` plus Redis on `127.0.0.1:6380`. It was seeded with the project's published fixture catalog, never with owner data. The two existing browser harnesses ran serially against `http://localhost:3111` with `PLAN06_EXPECT_PCK=a2206c8993cc55469d45627417891b1e9290fc757c49c6b871749f27fb1e43f6` and `PLAN06_EXPECT_PCK_BYTES=69774796`:

```sh
VERIFY_COMPACT_NIGHT=1 APP_TEST_ORIGIN=http://localhost:3111 node --import tsx scripts/night-home-browser.mjs
APP_TEST_ORIGIN=http://localhost:3111 node --import tsx scripts/live-parent-cycle-browser.mjs
RUN_STAGING_SMOKE=plan06-public PLAN06_EXPECT_PCK=a2206c8993cc55469d45627417891b1e9290fc757c49c6b871749f27fb1e43f6 PLAN06_EXPECT_PCK_BYTES=69774796 node --import tsx scripts/staging-plan06-smoke.mjs
```

Each local command also received the same pinned PCK variables. The first local route took 299,623 ms; the public route took 291,330 ms. The live-parent route stayed within its eighteen-minute bound. All isolated fixture players were removed by their harnesses. Afterward, the local API, MongoDB, and Redis were stopped; the **own** 2,824 KiB test database directory was removed. All three ports were closed, while logs and evidence were kept (240 KiB local service/log directory). Staging production database, `.env`, deployment, active image, rollback image, and other accounts were untouched. Public health remained HTTP 200.

Tools actually used: existing Node/tsx harnesses, Playwright Chromium with ANGLE SwiftShader, MongoDB 8 and Redis test processes, SSH for the staging fixture lifecycle, local hash utilities, and image viewer. No image generation, third-party asset, new dependency, or new license was introduced. SwiftShader elapsed time is **not** a Samsung S23 or Windows GPU FPS measurement.

Next: build and run a bounded single-fixture public or local journey that earns the recipe fragments during diving after forest exploration and then serves Kedai before sleeping; do not claim this from the separate fixtures above. Independently measure real S23/Windows frame pacing, startup, fullscreen, and joystick with the owner-assisted devices. The captured underwater notification panel at 844×390 occupies substantial central space and merits a separate HUD visibility review, without altering the functional pass here.
