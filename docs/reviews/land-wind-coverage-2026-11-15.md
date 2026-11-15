# Land vegetation wind coverage — source candidate

Date: 15 November 2026. Branch: `work/land-wind-audit-20261115`, based on `89a1f8b`. This is an isolated candidate, not a staging release.

## What was static

Broadleaf, mangrove, and palm atlas crowns already used a 10 Hz, signed `wind_x` pixel-step offset. Cluster shrubs and wet-bank fronds used the same updater. The surface-spawned fern sprites did not: they were created after the cluster path without an `_leaves` registration. The raised-bed crop heads and small ground flowers were static meshes. The fallback hand-built palm fronds and canopy mesh remain static only if the shipped atlas is missing; the atlas path is present in the project.

The surface ferns now enter the existing wind updater (43 in the hub fixture, 73 in the forest fixture). Crop heads and flower heads use a shared vertex-shader material with a 10 Hz sampled gust, pixel-rounded lateral offset, signed wind, and anchored lower vertices. Their meshes still join the normal static batch, so this does not create one draw call per plant. Reduced-motion disables both the original sprite offset and the new vertex motion. Existing trunks, collision/ground geometry, pathing, map data, weather rules, and authored art stay unchanged. The flower material retains the previous warm beige color.

## Evidence

- Godot 4.7.2 Compatibility `land-renderer.gd` passed after editor import. The first attempted test used a `res://` path for a script outside the Godot project; it was corrected to an absolute script path. A later shader error exposed the shelter cutaway's string replacement of `kind==` in vertex code; changing the new expression to `kind ==` fixed compilation. The final test log had no `ERROR` or `SCRIPT ERROR`.
- New `land-wind-coverage.gd` passed. It checks crop/flower wind materials, registration of every actual surface fern, 100 ms pixel-pose hold, and reduced-motion returning all leaves to the home pose. The test is registered in `scripts/verify-living-world.mjs`.
- Native Apple M2 Compatibility capture, 667×375 and 844×390: twelve full-scene frames for hub and forest with still/reduced, wind +22, and wind −22. The fixture counted 96/209 total leaf records in hub/forest. Review at actual output size found restrained crown/ground movement and no detached sprite or changed solid trunk. Full frames and `results.json` remain under `artifacts/godot/land-wind-review/` in this worktree.

Curated 667×375 side-by-side proofs: [hub](../visual/land-wind-hub-667x375-20261115.webp) (`3db10752ef1825182763db26a9b2890a420eb236e9e18e86757a916d13daacaa`) and [forest](../visual/land-wind-forest-667x375-20261115.webp) (`f22a6e76b243f60ebd5358ead025314da0ada02433ba12c72a359b40df13f4eb`). The frame-to-frame image difference also includes water animation, so it is not used as a vegetation-only motion metric.

The work uses existing project textures and project-authored GDScript/GLSL. No new third-party tool, generated asset, license, or runtime dependency was introduced. This does not establish full moodboard parity, physical-device frame pacing, or visual quality of every small crop at all zoom levels. Before staging, review motion in a browser at normal camera speed and run the combined world/typecheck/test/build/export checks.
