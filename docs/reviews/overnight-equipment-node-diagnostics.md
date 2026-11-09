# Optional actual equipment-node diagnostics

Prepared source for the next coherent game package; **not exported or browser-tested**. ExistingPCK73d wardrobe4/4 actualPASS remains unchanged, including its partially occluded eastern-booth screenshot. Integrator approved this bounded diagnostic addition after that run. No new art, attachment transform, outfit rule, controller, geometry, server state or public deployment changes.

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
