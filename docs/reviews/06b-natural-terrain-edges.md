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
