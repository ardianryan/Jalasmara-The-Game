# Natural stone edges: source candidate

9 November 2026. Worktree `Jalasmara-06-natural-edges`, branch `work/06b-natural-edges`, base `3b0865945e053c6b0cc09b7d028db63d6cb9b232`. Current gateway metadata `eb58f3c` is applied locally as `5bc5f72` for the fixtures. Root owns LandWorld hooks and cross-area backing; this lane adds only the natural-edge helper, two focused fixtures and this review. **No engine, import, browser, native capture, export or deployment has run for this candidate.**

## Actual source problem

`LandWorld3D._build_surface_geometry` emits every exposed nonwood edge as coplanar `TerraceFace` strips 32 px long, with a fixed 32/44 px vertical depth. Subdivision does not alter the rectangular upper silhouette or polygon corners. On a higher terrace, subtracting 44 from the world height also need not reach the actual lower floor. Adding separate rock props would leave that flat wall visible.

`NaturalTerrainEdges3D.gd` replaces that skin with one connected contour: a shallow material-matched lip, ochre soil, noncoplanar stone shoulders and a darker rooted toe. Each convex polygon corner becomes a shared three-facet fan; adjacent segments reuse the same ring vertices. Deterministic coordinate noise varies the outer silhouette and shoulder depth without frame-time RNG, camera dependence or separately floating rocks. Wooden docks, wood floors and bridges explicitly decline handling so the original straight construction remains.

The original walkable top, polygon, floor elevation, collider, route and stair data remain unchanged. The lip is a bounded visual extension outside the authoritative edge, not extra walkable land. The toe seeks an actual lower surface in world XY and extends 5 px into it. This search uses `ground_projection` at each candidate floor height: the existing map embedding moves XY when height changes, so querying the same logical point would select the wrong physical support. If there is no lower surface, the coastal mass extends beneath the water to −45 px; it does not pretend that a separate seabed collider exists there.

Existing connector and shared-floor checks still control exposed segments. The expanded skin is also checked against stair/ramp mouths at the upper, middle and lower plane. Active runs taper to zero expansion at cutout ends. The original forest bank bounds remain; backing and decorative trail top geometries are not rewritten. Four meshes per eligible surface enter the existing material batching; there is no per-frame geometry, new renderer, imported asset or crown-count change. Floor polygons are cached per generated profile for support queries.

## Exact integration hooks for root

Root remains the only LandWorld writer. Add the helper alongside the other construction helpers:

```gdscript
var _natural_edges = preload("res://scripts/land/NaturalTerrainEdges3D.gd").new()
```

Reset it once in `set_area`, before `_build_landmass()`/surface construction, alongside the other per-build counters/helpers:

```gdscript
_natural_edges = preload("res://scripts/land/NaturalTerrainEdges3D.gd").new()
```

In `_build_surface_geometry`, retain top generation, priority/decorative returns, forest-backing exclusions and the wooden-dock branch. Immediately after `if is_forest_backing: return`, insert:

```gdscript
if _natural_edges.build_surface(self, surface, polygon, height):
    return
```

That return is essential: it replaces the old stone `TerraceFace` loop rather than drawing rocks over it. Wood/dock/bridge handling returns false and therefore follows the existing architecture path. The helper itself applies the existing forest-bank mask plus `_connector_at`/`_shared_floor_edge` checks. Optional diagnostic status is `_natural_edges.debug_status()`; no HUD or external API change is required.

Register `scripts/tests/natural-terrain-edges.gd` in the existing world runner after map/terrain renderer checks. This lane does not edit the shared runner or LandWorld.

## Prepared acceptance, not yet executed

`natural-terrain-edges.gd` tests the actual helper and renderer. A controlled two-floor contour must produce four connected corner fans, deterministic geometry, varied real facet normals and roots meeting the real lower floor; a fixed 44 px cutoff fails. Wood/bridge/dock handling must remain untouched. Actual hub/forest profiles then check the renderer hook, stair/ramp cutouts at real vertex heights, supported roots, existing stair walkability and unchanged authoritative world JSON.

`natural-terrain-edges-render.gd` prepares 18 actual-world day/night frames: western/central/ridge stairs, lower/corporate coastline and both banks of both forest bridges. The nine stationary markers were checked CPU against the current gateway manifest at 13 px clearance; all are legal. The renderer and collision checks independently verify them again. Every image must contain one actual Nala at −45°/35° with foot error under 0.01. These component stills are not browser traversal or performance acceptance.

After root applies the hooks and grants the engine slot, generate `.runtime/world-map.json`, import this active worktree, then run sequentially:

```sh
GODOT=/Users/ardianryan/Documents/Jalasmara/.runtime/godot/Godot.app/Contents/MacOS/Godot
"$GODOT" --headless --path client-godot --script ../scripts/tests/natural-terrain-edges.gd
"$GODOT" --path client-godot --script ../scripts/tests/natural-terrain-edges-render.gd
```

Inspect every log for parse/script/render errors, then inspect images for continuous broken corners, solid roots, no residual rectangular stone wall, no strip gaps, visible stair mouths and unaltered wooden decks. The current source has not passed that gate. Root must repeat the full combined world suite and player-driven hub/forest stair/bridge/coast movement before accepting the package. Cross-area continuity and gateway backing are separate root work, not claimed solved by this helper.

Tools so far: Git, Node's TypeScript loader for existing map-clearance queries, Python availability check, source editing/review. The geometry is original Godot code using the existing project materials and renderer. No third-party pixels/code were added, and existing license notices remain unchanged.

## Integrator check and rejected first visual result

The integrator subsequently applied the hook in candidate `b694824` and reported the actual focused test passing: seven surfaces, 493 active nodes, 472 cutouts and 316 supported nodes in `.runtime/06b2-natural.log`. The integrator's native fixture also completed 18 frames at `artifacts/godot/06b2-natural-color/`. This lane did not launch that engine/browser session. It visually inspected `hub-central-steps-day.png` and `forest-upper-west-bank-day.png` directly. The higher hub terrace still reads as a near-vertical concrete wall: correctness of the first connected bands did not satisfy the requested natural-rock appearance. That visual result is rejected, not called finished.

The new source iteration changes the narrow fixed-width shoulder into six joined rings. Toe width depends on the physical drop (bounded at 150 world units); upper/middle stone tiers have staggered vertices and alternate existing stone/shade/root materials. Shade colors derive from the current stone palette rather than imposing a hardcoded gray. Convex corners keep their shared fans. The expanded skirt stops before re-entering its own contour and before lower authored route corridors; existing connector guards remain. Focused tests now require a broad slope for a controlled 96 px drop, six monotonically descending rings, and narrowing against a real lower-route corridor. **This iteration has not run in Godot or native rendering yet.** Root must apply it after its active suite, rerun the focused test without weakening cutout checks, then inspect the same central-steps/coast/bank images.

## Read-only seam peer review

The integrated natural hook correctly returns before the old stone `TerraceFace` loop; wood still falls through to its existing path. No duplicate preview tree was found on an authoritative local walking floor in a CPU transform check: all eight selected forest trees in the hub preview and the one selected hub tree in the forest preview lie outside local walkable ground. The `vista` flag also avoids registering their canopies as local foreground blockers.

Two concrete seam limitations were found in root-owned `LandAreaSeam3D.gd`:

- Remote terrain is emitted by `_top()` only, bypassing the natural side/root skin. The hub preview's clipped forest terrain lies at world Z 144 beyond the local landmass; its exposed clipping border remains a flat unsupported sheet.
- Exact frame transformation and polygon intersection find 48,678.84 logical square units of remote `garden_wing` in the forest preview at world Z −48 (remote floor96 minus portal144). Local opaque water planes are at −14/−20 and the forest backing is at 0, so this slice cannot read as visible village terrain. The clipped remote ridge, 122,212.5 logical square units, remains at Z 0.

These are source/CPU geometric findings, not a new native screenshot acceptance claim. They were sent to the integrator; seam transforms, preview support and cross-area continuity remain root ownership. The natural bank helper deliberately preserves the old outer/top/bottom forest-bank exclusions and only shapes exposed river-facing runs; the inspected upper-bank frame therefore does not prove every outer forest corner has been softened.

## Final CPU visual/source peer review

The integrator applied the wider iteration as `2a343f8` and subsequently corrected flat terrain vertex normals to agree with the existing shader's upward-facing flat-ground normal. The integrator reports that its bias/shadows A/B comparison removed the diagonal stripe artifact through this normal correction, with shadows retained. This lane reviewed the resulting source and images; it did not run that experiment or any new engine/browser session.

Directly reviewed artifacts in `Jalasmara-06-buildings-gates/artifacts/godot/`:

- `06b2-natural-wide-normals/`: all 18 day/night images across nine terrain positions, inspected through a diagnostic contact sheet, plus original-size central-step, lower-coast and upper-west-bank images.
- `06b2-gateways-rooted/`: all six before/aperture/after images for the hub and forest gates, plus original-size hub aperture and forest-after images.
- `06b2-final-grass-houses/`: all 28 layout-9/layout-10, day/night house comparisons, inspected through a diagnostic contact sheet. These use the same current renderer for both metadata layouts; they are not a replay of the released old renderer.

The central-step and lower-coast images now show broad, connected angular stone shoulders rather than the rejected narrow concrete-like wall. Their visible faces reach the lower ground/coast and vary along the boundary; stair mouths and straight wooden docks remain distinct and open in these views. Both forest bridge approaches retain visible continuous paths into the wooden decks. Daytime ground and foliage are brighter while night lamps, teal water and shaded depth remain distinguishable. House footprints continue to read along the common map/deck axes. No new concrete visual route blocker was found in these reviewed stills. Some doors, heads and body areas remain partly hidden by foreground foliage or roofs, so the review does not certify an unobscured view of every doorway or actor.

The results JSON files were read directly, without rerunning their fixtures. Terrain records 18 entries and house comparisons 28, all with one player; each set's maximum recorded foot error is 0.00006103515625 px. The six gateway records all contain one player and have maximum foot error 0.0001220703125 px. Diagnostic sheets were generated only in this lane's ignored `artifacts/review-final/`; original evidence was not modified or packaged into the game.

Root-owned `LandAreaSeam3D` now supplies the same natural side/root skin to clipped priority-0 remote terrain, and excludes remote surfaces below the portal datum minus two pixels. Those source changes address both concrete peer findings above. The forest preview also builds the actual corporate container house using its transformed footprint/frame. This remains a bounded visual vista with no new authoritative collision; it is not a newly traversable shared-map region or proof of a seamless scene transition.

**Integrator-reported validation, not executions by this lane:** focused natural test passed with 485 active nodes, 480 cutouts and 237 supported nodes; native terrain 18, gateway six and house 28 fixtures passed. After an actual Ujang ramp regression was fixed by the character lane, root reports the complete 50-check world suite, 100 API tests, 40 harness tests and full build passing. Candidate PCK is `5f5baf243a3bf941cf34fab6c143bb9cf2bc8d65997ded6ed4e048b929353f96`, 64,333,184 bytes; actual browser acceptance is owned by the website lane and was still running at this review checkpoint. No deployment or default-public-browser acceptance is claimed here.

This closes the bounded source/image peer review without further production changes after the freeze. Authored rock texture richness, broader village content, every outer forest boundary, long-session physical Windows/S23 performance and actual player-driven route/transition acceptance remain separate work. They do not justify indefinitely reopening the now-readable core cliff geometry before completing the candidate's browser checks.
