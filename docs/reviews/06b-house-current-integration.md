# Seven-house alignment on the current release source

CPU checkpoint, 9 November 2026. Branch `work/06b-house-integration`, worktree `Jalasmara-06-house-integration`, base `f7a3b96c1c129d165b78743f22b9e573535d9158`. This is isolated candidate source, not the staging package. No Godot import, headless engine check, native render, browser or export has run at this checkpoint.

The earlier house candidate was applied as `afbb1c5` → `d1d6ad9` → `34ba78b` (originals `a8d03e6` → `de80e12` → `3ee6bd7`). The only cherry-pick conflict was the already-copied historical review document. Final runtime source uses option B: seven house footprints become orthogonal to the actual map/deck axes while preserving their occupied area, physical-axis aspect, center, height, elevation and identity. Griya's accepted footprint is unchanged. Roof, facade, door, collider and attached shelter geometry still derive from the same emitted footprint through the existing renderer. No assets, runtime, independent model rotation, gate geometry or LandWorld source are added or changed.

The hub becomes layout 10. The shared Ratih/Balai waypoint moves from `(760,350)` to `(760,325)` to preserve real support clearance; the tree remains in its original location. Recovery requires 13 px client clearance; API movement checks retain their existing 12 px rule. The frozen layout-9 migration fixture was compared structurally against `LAND_MAPS.hub` from the current main base and matches exactly, so the old-layout proof still describes the current release geometry.

## Completed CPU evidence

- `npm run typecheck`: exit 0, `.runtime/house-current-typecheck.log`.
- Full `npm test`: **86 passed, zero failed/cancelled/skipped**, exit 0, 29.59 seconds, `.runtime/house-current-full-api.log`.
- Migration geometry covers all 416 old legal grid positions newly occupied by option B, keeps their floor elevation and 13 px clearance, and proves a connected perimeter path to authored routes. Maximum correction remains bounded to 32.001 px.
- Two independent API fixtures each migrate 14 old saves (layout 8 supports/Griya corners and layout 9 house corners), then verify persistence, unchanged player state, reload, stale-save rejection, rejection of the blocked old destination and real legal movement. Ten already-valid old deck saves remain unchanged across the two fixtures.
- Current Main, HomesteadUI and accepted Nala source have no diff from the base. The Balai interaction regression remains registered in the combined world runner. `git diff --check` passes.

Dependencies use an untracked `node_modules` symlink to the existing root installation; it is not part of the candidate. No build/cache duplication was created. API fixtures use their own database/UUID and cleanup; no account owner or deployment data was used.

## Pending engine and gameplay acceptance

The shared engine slot must be explicitly granted before continuing. Follow [the prepared native sequence](06b-house-next-native.md), using this worktree and current source SHA. The combined runner now has **47 checks**, because current main already contains the actual Balai UI regression and this candidate adds the house-frame check. The older sequence's 46-check count predates that integration.

Required next evidence: actual native house/deck axes and collider corners; all seven body/roof coverage and routine routes; complete world suite; the prepared 28 old-layout/current-layout comparison images under the same left camera and day/night conditions; unchanged Griya. Inspect facade, door approach, roof/wall/porch/support seams and framing directly. A CPU rectangle or an unexecuted capture fixture is not visual acceptance.

After native acceptance, the integrator must combine the independent gate lane, repeat route/save checks on that combined manifest, and obtain browser movement/shelter evidence from a separately pinned package. The existing public startup transport issue remains separate. No layout-10 release or broad comfy finishing claim is made here.

## Engine and native checkpoint

The integrator subsequently granted the exclusive engine slot for this worktree. Godot 4.7.2 `ed1daf0bf` ran locally; native output used Compatibility/OpenGL 4.1 Metal on Apple M2. The first fresh-cache import encountered the theme's not-yet-imported font. The completed second import exited 0 with no error/parse matches; no project setting or source change was needed.

`GODOT_BIN=/Users/ardianryan/Documents/Jalasmara/.runtime/godot/Godot.app/Contents/MacOS/Godot WORLD_REPORT_DIR=.runtime/house-current-world npm run check:world` completed **47/47**, followed by ten species/722 frames verified. Child-check elapsed time totals 65.84 seconds. `.runtime/house-current-world/world-checks.json` records every check passed; `.runtime/house-current-world.log` has no `SCRIPT ERROR`, `ERROR:` or assertion. Two existing ObjectDB cleanup warnings remain in UI/controller fixtures and are not described as a warning-free run.

Actual engine coverage includes eight orthogonal house frames and 32 transformed collider corners; five attached roof plans/ten authoritative posts; 336 foot/torso/head rain samples; unchanged Griya/deck axes; seven real routines with 21,806 collision-checked steps; current Nala's 192 transition samples; Balai's 19 actual UI cases; Ujang's 1,242 contact/168 turn samples and 26 authored west grip poses. These checks do not replace player-driven browser travel.

The initial 28-frame capture exited 0, but zoom 1 clipped Kedai/Balai roof ridges. Those frames in `artifacts/godot/06b-house-alignment/` are rejected as framing acceptance. A first attempt to collect actual pre-batch mesh bounds through an inline subclass failed before autoload initialization (`GameState` unavailable); its bounded subprocess was stopped at 40 seconds. The final fixture loads a separate test-only renderer subclass after initialization. It records actual transformed mesh AABB corners before calling the unchanged static batching method. Every house bound and attached roof plan must project at least eight internal pixels inside the frame. Both layouts use the identical marker and zoom 0.5; runtime camera zoom is unchanged.

The corrected capture completed **28/28** with no script/render errors. Every frame reports one Nala, azimuth −45°/elevation 35°, and maximum foot error **0.00006103515625 px**. Evidence:

- `.runtime/house-current-import-final.log`, `.runtime/house-current-native-framed.log`.
- `artifacts/godot/06b-house-alignment-framed/results.json`.
- `before9-<house>-day.png`, `after10-<house>-day.png`, and corresponding `night.png`, for Kedai, Beno, corporate post, Balai, Ratih, Sari and Tedi.
- `contact-day.png` and `contact-night.png`: diagnostic comparison sheets made from the unchanged originals for review, not game assets.

Both contact sheets and original Kedai/Balai/Beno frames were visually inspected. Corrected house side/front and roof directions now follow the map/deck axes; roof/wall connections, porch supports and night lamp positions remain coherent. The target buildings fit inside the frame. Existing foreground palms/broadleaf crowns still partially cover some service door fronts, so this comparison does not claim an unobscured view of every doorway or actual approach/gameplay acceptance. Geometry, routine and CPU access checks pass separately. No tree, roof, actor or collider was hidden to manufacture a cleaner image.

All owned Godot processes were confirmed absent and the engine slot was released. No export, browser, deployment, new artwork or gate edit occurred. Root review and combination with the independent gate manifest remain next, followed by actual browser movement/save/shelter checks on that combined package.
