# Optional actual equipment-node diagnostics

Prepared source for the next coherent game package; **not exported or browser-tested**. ExistingPCK73d wardrobe4/4 actualPASS remains unchanged, including its partially occluded eastern-booth screenshot. Integrator approved this bounded diagnostic addition after that run. No new art, attachment transform, outfit rule, controller, geometry, server state or public deployment changes.

Root integrated `bef2108` and independently ran the actual focused fixture: PASS marker, exit0, zero `SCRIPT ERROR`/`ERROR:` in `.runtime/overnight-equipment-node-focused-root.log`. The four route/projection CPU tests also passed in root. The fixture is registered as the additional64th world check, and both wardrobe helper suites are registered in CI. **Root full64/64 PASS**, summed fixture runtime147,165ms, no `SCRIPT ERROR`/line-start `ERROR:`; creature verifier10species/722frames also passed. Resident commute20,785ms remains below its unchanged60second limit. This is a new local headless result, not a transfer of the preceding63-check run or device FPS. No new export or browser result is claimed.

Combined manifest `.runtime/overnight-64-world-diagnostics/world-checks.json`, SHA256 `db51408e0d55a70eb89902f4adf69d5dc176d9b2eb04b72ba1ca86398e4d6ea1`; full log `.runtime/overnight-64-world-diagnostics.log`. Existing headless audio-driver/ObjectDB warnings remain distinct from parser/runtime errors. All runtime files were fixed at `bef2108`/`4d955e1`; the runner additionally registered this fixture before execution. No physical Nala pilot files were present.

## Boundary and payload

The existing `Diagnostics.gd` opt-in is reused. On Web, it reads the existing window/parent diagnostic flag or `diagnostics=1` query; the normal production host does not enable it. Native debug builds retain their existing default. No new route, command, postMessage listener or privileged action is introduced. `set_enabled` already supports explicit test toggles.

`CharacterEquipment3D.visibility_diagnostics()` immediately returns an empty dictionary when disabled. When enabled it returns only:

- `schemaVersion=1` and `visibilityScope="scene-tree-not-pixel-occlusion"`;
- actual root `rootInTree` and `rootVisibleInTree`;
- allowlisted tank/net/satchel/vest records: `exists`, local `visible`, inherited `visibleInTree`, actual `meshCount`, actual `visibleMeshCount`.

These fields are read from the existing owned node references and their mesh descendants, not copied from requested equipment booleans. Local visibility can be true while a hidden ancestor makes `visibleInTree` false. The payload excludes account/session IDs, node paths, arbitrary node properties, material/image contents and mutable gameplay data. It does not change the tree. Visible-in-tree does **not** prove viewport activation, on-screen position, z-buffer sorting, alpha coverage or freedom from roof occlusion; keep `land.active`/`hybrid.active` and actual image review alongside it.

Land exposes this optional object as `land.actors.gearNodes` through a diagnostic copy of counts; normal counts receive no new field or per-frame descendant walk. Ocean exposes the same helper via `hybrid.gearNodes` only within its opt-in debug report. Existing Main/Forest snapshot calls already require diagnostics. Actual node/mesh iteration occurs only when the diagnostic report is requested. The retained raw frame counts are not mutated.

## Prepared focused fixture

`scripts/tests/equipment-node-diagnostics.gd` exercises the real helper and actual land/ocean wrappers: disabled/on/disabled toggles, daily/diving/explorer state, allowlist, actual descendant meshes, hidden parent versus locally-visible attachment, one explicitly hidden mesh and unchanged retained land counts. It has no render await and should complete in a small headless slot. **Not run yet**; compilation/runtime success is pending an explicit integrator engine grant. Root should register it in the coherent world runner only after that focused result passes.

## Source-derived dock frame

The helper `wardrobe-visibility-fixture.mjs` reuses the current camera basis from the existing canopy fixture and checks exact source geometry signatures before deriving a target. It conservatively projects the actual booth shade, both folded curtain bounds and support/cap bounds, then applies separating-axis tests against an idle body/gear rectangle including navigation margin. It derives a legal radius12 point from the dock boundary: **1536/1386** (`dock_main` max minus14); physical routing from the prior diving checkpoint is checked. Candidate scope is explicitly `projected-booth-geometry-only-needs-actual-image-review`.

CPU inspection of the original male_nusantara diving idle atlas via Pillow found all eight opaque alpha bounds within x−18..18 and y−86..0 relative to pivot64/104. Existing gear geometry extends roughly35view units horizontally; the candidate envelope is x±48/y−96..12. This is a conservative source model for this idle candidate, not a generic animation/actor occlusion proof. The exact current source camera/booth signatures are guarded, and actual arrival must be tested again because a nearby point1532/1382 still overlaps this envelope. Do not accept the usual five-unit arrival tolerance as automatic visual clearance. No runtime teleport or widening the floor is proposed.

**CPU4/4 PASS**: two original wardrobe-route tests, plus actual old1490/1290 sample rejected/new candidate physically reachable; changed view or geometry rejected. `git diff --check` passes. No engine, browser or GPU used for this preparation.

Next coherent export: add a narrowly flagged browser assertion for actual node visibility on the new PCK, walk to a measured clear actual point, stop, capture the original frame and inspect it. Require expected actual nodes/meshes, renderer active and geometry clearance; do not use a requested-state fallback when the new diagnostic field is absent. Reuse owned UUID cleanup and existing snapshot opt-in. Existing current73d command must remain available without pretending its payload contains these new fields.

## Actual focused engine result

After source commit09d9fc4, integrator granted a bounded necessary import and focused headless test in this isolated worktree. Godot4.7.2 stable, official ed1daf0bf. No native render, browser, full suite or export was run. Engine slot explicitly **RELEASED** after completion.

The first fresh import exited0 after9,151ms but logged seven font/theme resource errors because the project theme referenced fontdata before the empty `.godot` cache had imported it. This attempt is **FAIL**, retained at `.runtime/equipment-node-import.log`; the focused test was not started from that result. The bounded second necessary import completed2,649ms with0errors. Then the real `equipment-node-diagnostics.gd` completed485ms, exit0, emitted its explicit `EQUIPMENT NODE DIAGNOSTICS PASS` marker, with0`SCRIPT ERROR`, `ERROR:` or assertion failures. Logs `.runtime/equipment-node-import-second.log` and `.runtime/equipment-node-focused.log`.

This actual gate proves opt-in allowlist/three outfit node states/actual descendants, inherited parent hiding, individually hidden mesh, real land and ocean wrapper reports, unchanged retained counts, and off/on/off toggling. It does not turn the CPU projected dock candidate into an accepted screenshot or prove final combined export/browser behavior. Root should run the fixture in the next coherent integration suite and later verify actual node fields plus unobscured pixels on its newly pinned PCK. Generated `.godot` and two missing UID cache-side files were not staged.
