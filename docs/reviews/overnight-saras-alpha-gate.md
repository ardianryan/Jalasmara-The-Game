# Current Saras alpha path and prepared browser gate

CPU/read-only source and packed-resource audit against export `1315f34672b0fc5694a5f73684ca68bfbc6b5be1f6f4560b9628cc14ac2ef5e0` (64,491,320 bytes). No engine, browser, import or renderer modification was made for this preparation.

Saras remains appearance5/cycle2 on the original `village-residents-v1.png` (SHA `09fd3e55f16b7a17c5077a1b693d4284e04437c7c19ab90ccbca8f210bc5afde`), not the new director/children resident art. `VillagePortraits` has no Saras ID, and `NpcBodyRig3D.IDS` does not select her. Main creates her custom3×2 atlas frame; LandActors selects appearance5, enables nearest sampling/alpha discard0.5, leaves the sprite unshaded with cast shadow off, and Main hides her original CanvasItem while the land renderer is active. Ground shadow uses a separate ellipse mesh. No source-cause for the historical full-browser gray rectangle was established.

The actual PCK filetable/payload MD5 was checked using the same field layout documented by the existing Godot4.7.2 inventory parser. The packed `.godot/imported/village-residents-v1.png-50094af262fda32c6fad47fbe32957da.ctex` is byte-identical to the current imported file:1,595,478 bytes, SHA `dd4b472dc8f893bc79ada08adaf42208b4236fffb8cc40058d1fa7506fa8ca45`. Pillow read its embedded RGBA WebP without executing Godot. The512×512 Saras region's alpha bytes exactly match the source:162,211 pixels alpha0 and99,933 intermediate-alpha pixels; all four source corners alpha0. At discard threshold0.5,84,905 pixels survive and their bounds are `(98,12)–(382,506)`. Legitimate clothing uses partial alpha below255, so “remove neutral colors” would damage artwork. Local evidence: own `.runtime/saras-alpha-current-pck.json`. An initial ad hoc PCK lookup used a `res://` prefix not stored in the filetable; correcting only the lookup found and verified the actual payload. No export or texture bytes changed.

The native7,762-sample result remains valid for its measured source/renderer path. The old43df browser image still lacks an unobscured silhouette. Neither becomes proof of current complete Main/browser composition merely because these current packed alpha bytes match. The historical cause remains unknown; no workaround is justified by the CPU audit.

## Prepared narrow local mode

`PLAN06_ROUTE_MODE=saras` reuses the actual pinned local plan06 browser harness, its matrix-based keyboard walking, authenticated fixture and exact cleanup. Default calendar day2 at20:00 selects a legitimately clear UUID using server calendar rules. Nala starts on checked floor `(800,1000)`, more than175units from every point of Saras's commute, then waits at most90seconds for her real scheduled rest station `(1020,310)`. No clock, NPC or weather changes occur during gameplay.

Actual walking approaches two source-checked, body-clear viewpoints `(1070,345)` and `(1050,370)`. Both keep Nala55–75units from Saras, screen-horizontal separation is checked against the real renderer motion matrix, and Saras must actually be nearest before E opens her real named dialogue. The tempting opposite viewpoint `(970,275)` was rejected during source review because the Balai board would win nearest interaction; this does not require a product fix. Original pre-dialog and dialogue PNGs are retained for visual review. Automatic check names deliberately assert real schedule, separation, interaction and no reward changes—not “gray quad fixed”. Foreground occlusion must still be judged from original images before accepting the current browser silhouette.

Optional `PLAN06_SARAS_MINUTE=600` creates a separate legitimate10:00 fixture at authored work `(1480,680)` with checked viewpoints `(1530,715)` and `(1430,645)`. This is not a runtime time override. Both modes preserve story day2, coins200, inventory/missions and prohibit legacy movement keys. An explicit5minute route bound and the existing bounded attach/request waits remain.

CPU tests passed3/3: actual night/day points and input immutability; rejection of arbitrary time settings/substituted portrait provenance; rejection of an obstructed viewpoint/proximity-stalled commute. An initial negative-test obstacle lacked the map's `footprint` field; it was corrected to the real fixture schema before the passing run. Browser script syntax and diff checks passed. Actual browser execution is pending the integrator's serialized grant.

```sh
APP_TEST_ORIGIN=http://localhost:3111 PLAN06_EXPECT_PCK=1315f34672b0fc5694a5f73684ca68bfbc6b5be1f6f4560b9628cc14ac2ef5e0 PLAN06_EXPECT_PCK_BYTES=64491320 PLAN06_ROUTE_MODE=saras node --import tsx scripts/plan06-layout-browser.mjs
```

No production renderer/Main/CharacterVisual, proxy, UI feature, account, asset or license was changed.

## Actual night rest-site result: behavior passes, visual gate remains open

The granted actual run on the pinned1315 package completed three behavior checks with zero API/browser errors. UUID `5102932f-9cda-4131-8c85-a4368a72154e` was independently cleaned, including its player/receipts/shifts/exact Redis/session keys. Actual route time was228,842ms, with273camera-matrix pulses, zero legacy pulses, and119surface-position acknowledgements. Saras reached her real clear-night rest station before Nala physically approached; no clock, weather, NPC, runtime position or economy override occurred.

Both real conversations identified Saras. The pre-dialog player points were `(1072.1615,344.6782)` and `(1048.6583,367.1101)`, sufficiently separated from the authored station and each checked against the actual renderer motion matrix. The automatic checks correctly assert schedule/interaction/no rewards. The original PNGs were inspected at their actual844×390 resolution: foreground palm foliage still covers important silhouette boundaries. These captures therefore **do not establish correct complete silhouette compositing or resolve the historical gray-quad report**. There is no justified alpha-mode, chroma-key or artwork workaround from this result.

Evidence is in integration `artifacts/browser/plan06-layout-5102932f-9cda-4131-8c85-a4368a72154e/`: `results.json`, two `saras-rest-view-*-before-conversation-needs-image-review.png`, two actual-dialogue PNGs, and the checked quiet-spawn PNG. Log `.runtime/overnight-saras-night-browser.log`. The exclusive browser slot was released immediately after completion. This real local Chromium/SwiftShader result is not a physical-device performance measurement or public acceptance.

A follow-up approved by root will use a separate legitimate20:00 fixture with Nala already near Saras's authored work spawn. Existing player attention will hold her there through normal HubActor behavior; no NPC override or new renderer mechanism is needed. This avoids repeating the long commute and uses the same unobscured work-site composition previously measured natively, now through actual Main/browser night lighting. It remains a prepared gate until its original images are inspected.

## Prepared short night work-site attention variant

`PLAN06_SARAS_ATTENTION_WORK=1` retains actual20:00/day2/clear-calendar fixture setup, but starts Nala at the validated free-floor point `(1530,715)`,61units from Saras's normal initial work spawn `(1480,680)`. Existing HubActor attention naturally prevents her pending rest commute while Nala is nearby. The browser must observe the real `walking_rest`, not-moving, not-at-station state with unchanged scheduled rest destination `(1020,310)`. It explicitly does not claim a work shift is open at night or that she arrived at rest.

Two short source-checked viewpoints `(1530,715)` and `(1540,690)` have a body-clear direct corridor and only26.93logical units of total travel. Actual matrix-based keyboard input still reaches the second point; no runtime position/NPC/clock/weather write is added. Each real E interaction must name Saras. Both original pre-dialog images still require manual unobscured-silhouette review. The additional CPU test checks the retained night calendar/scheduled destination, real initial-spawn attention range, short corridor and rejection of an obstructed path or a daytime attention flag. All four CPU tests, browser syntax and diff checks passed; no new engine/browser execution occurred for this preparation.

```sh
APP_TEST_ORIGIN=http://localhost:3111 PLAN06_EXPECT_PCK=1315f34672b0fc5694a5f73684ca68bfbc6b5be1f6f4560b9628cc14ac2ef5e0 PLAN06_EXPECT_PCK_BYTES=64491320 PLAN06_ROUTE_MODE=saras PLAN06_SARAS_ATTENTION_WORK=1 node --import tsx scripts/plan06-layout-browser.mjs
```
