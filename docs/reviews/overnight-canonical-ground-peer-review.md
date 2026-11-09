# Independent review: canonical ground query

Scope: CPU/source-only review of integration `75b866a399e8b22f9df34030395ee46bfc51e84f` plus typed-index fixture correction `cf28881`. No root source edits, Godot/import/browser, preview restart or performance benchmark were run by this lane.

## Predicate and frozen authority

The scalar edge projection/clamp, zero-length denominator fallback, strict boundary `<1e-7`, ray crossing and parity match the shared `landDistanceToSegment`/`landPointInPolygon` formulas for the finite current manifest. Controller points are float32 `Vector2`; generator `Math.fround` preserves that input domain while polygon coordinates stay raw scalar values. This matters: 198/394 hub vertices and 62/112 forest vertices contain coordinates that change if rounded to float32. This is not a blanket bit-identical claim for every IEEE floating-point value: JavaScript uses `Math.hypot` and the port uses `sqrt(x*x+y*y)`.

The generator was executed with its output argument pointing to this lane's ignored `.runtime/ground-query-canonical-review.json`. It regenerated **324 positions +12 polygon cases byte-identically** to the committed corpus, SHA256 `434c2207818bbb7ab3dae82432e3a23642dc5ff4d922b674a3f422911e42b618`. Current shared WORLD and integration `.runtime/world-map.json` match: hub layout11,78surfaces,4stairs,222cases; forest layout6,24surfaces,0stairs,102cases. Current connectors have integer endpoints, nonzero length and positive widths. The generator's endpoint offsets are along the current vertical connectors; this review does not extend that coverage to a future diagonal connector.

Expected membership is produced by the actual shared function, not the Godot predicate under test. Ground override values are independently calculated from manifest connectors, and the GDScript fixture also has three explicit48-unit dock endpoint assertions independent of regenerating JSON. Metadata checks freeze layout version and surface IDs/order; they do not hash every polygon/priority field. Geometry edits that retain those metadata values can only be caught at sampled points, not by a full-manifest identity guarantee.

## Hot path and scope

Raw polygon `duplicate(true)` and PackedVector conversion happen in `_cache_ground_queries`, called from `set_area`, rather than each `ground_height` call. The new predicate has no explicit per-query polygon rebuild, dictionary construction or deep copy. Existing `Traversal.connector_ground` dictionary queries remain in `ground_height`/`ground_point`. Compiler treatment of loop iteration/Variant handling and runtime timing were not measured, so this review does not call the path allocation-free or recommend an optimization. No new correctness blocker was confirmed by source review.

The change corrects **renderer floor selection** only. `SurfaceTraversal._surface_at`, `WorldFoley.material_at`, and collision predicates retain their existing Geometry2D paths; they are not globally canonicalized by this commit.

## Exact residual consumer consequence

At `(1135.271484375,1124.9990234375)`, dock connector progress is `1.0000150240384615`, so it is no longer active. The existing actual legacy diagnosis `Jalasmara-overnight-character/artifacts/godot/nala-physical-dock-priority-59b9c84/endpoint-diagnostic.json` records Geometry2D still matching dock floor priority30/height0 there. Shared authority instead selects `village_dirt_lower_court_segment_5_0` priority4/height48/material dirt.

`Player` calls real `SurfaceTraversal.sample` every land physics tick. Its legacy `_surface_at` can therefore retain stale `elevation=0`, `groundHeight=0`, `floor=dock`, `footstepMaterial=wood` in the thin strip. Outside a connector, however, `paceScale=1`, `footBob=0`, and `bodyLift=0`; the incorrect elevation does not feed those values. `LandActors3D._sprite` gets support/height from renderer `ground_point`/`ground_height`, adding only traversal bodyLift. Facing uses actual motion and renderer connector gradient, not traversal floor elevation. This source path does **not** reintroduce a body-height/facing jump after the renderer correction.

WorldFoley only trusts traversal material while `onConnector=true`. Outside it, Foley independently rebuilds packed polygons and calls Geometry2D, so a foot contact exactly in this strip can choose `footstep_wood` rather than dirt. This is a concrete conditional source path; no new audible footstep, actual consumer invocation or post-fix body rendering was measured in this review.

## Prepared focused reproduction

`scripts/tests/ground-query-consumers.gd` invokes actual SurfaceTraversal and WorldFoley material queries plus renderer height at five frozen points approaching, on and just past the dock upper endpoint. Expected materials come from actual shared `mapFootMaterial`/`landPointInPolygon`; ramp heights are independently derived from the authored0→48 connector. It stores all actual/expected samples before failing, checks bodyLift/pace, restores static world state and checks player/dive unchanged. It does not play sound, move a physics actor, use account data, or claim browser/physical-device behavior.

The fixture is **prepared, not executed**; no runtime patch or CI registration is included while this residual is unmeasured. After an explicit engine grant and cherry-pick into integration, run the absolute script with integration `--path client-godot`, preserve its first JSON failure, then decide whether a narrow consumer correction is justified. Root retains engine serialization and runner ownership.


## Actual consumer reproduction and scoped candidate

After the explicit serialized grant, Godot4.7.2 headless ran the frozen5-point fixture on integration4795d28. It exited1 with **exactly3 mismatches at1135.271484375/1124.9990234375**: actual traversal ground0/materialwood and Foleywood vs expected48/dirt, while renderer48, connectorfalse, bodyLift0 and pace1 matched. The4other points passed. No SCRIPT ERROR/leak appeared. Actual JSON `Jalasmara-overnight-integration/artifacts/godot/ground-query-consumers-1794251481-32572/results.json` SHA256 `58f953552afbc5da93088cd66a843d7e65567c1f15e2fadef1543e6b729d57ee`; log `.runtime/ground-query-consumers-actual-first.log`. Initial command used a missing local binary path and exited127 before engine startup; `.runtime/ground-query-consumers-first.log` is retained, not treated as a product failure. The successful engine invocation used main's `.runtime/godot/Godot.app/Contents/MacOS/Godot`. Slot released after exit.

A scoped source candidate now lives in separate `Jalasmara-overnight-ground-consumers`, based4795d28. New `LandSurfaceQueryCache.gd` compares live polygon Arrays exactly against cached deep copies using native Array equality, rebuilding raw copy/bounds only for new/changed index slots. This avoids a hash-collision assumption and catches in-place geometry, same-count replacement and reordering. SurfaceTraversal resets/warms cache in configure; Foley has one cache per area. Both query live priority/material/elevation; SurfaceTraversal retains last equal-priority winner, Foley retains higher-elevation/first tie semantics. Connector/traversal overrides, collision and global Geometry2D are unchanged.

The focused fixture additionally prepares10 mutation/tie/override checks with actual consumer methods. A separate17-second bounded AB/BA benchmark uses the same324 canonical positions for both consumers, comparing actual new bodies against overrides containing exact prior function bodies from4795d28. Baseline body SHA256, source/corpus hashes, complete pairs and warm cache exclusions are recorded. This is point-query timing, not full sample/render/FPS/device evidence. **Candidate correctness and performance have not yet run**; no claim that the extra native deep comparison is free or faster. Root owns the next grant, acceptance and runner registration.
