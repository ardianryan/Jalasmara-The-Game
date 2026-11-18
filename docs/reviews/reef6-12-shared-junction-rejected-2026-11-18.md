# Reef 6/12 shared-junction trial — rejected

**Decision:** keep the current runtime. This isolated trial did not meet the comfy 2.5D underwater art target. No terrain, collision, server contour, atlas, or test-code change from the trial is retained in the commit.

## What was tested

From main `af4534612c8d2005ea8ad2db2c31598836b48bb0`, a temporary version of `TerrainGeometry.gd` replaced the separately rendered ReefRelief6 and ReefRelief12 with one 45-vertex visible limestone volume. Its hand-authored polygon joined the wall and shelf, with a scalloped underside near world Y 2948–3110. It reused the project's existing porous limestone atlas column. The authoritative `terrainContours` in `packages/shared/src/world.ts`, swim corridor, coral mounts, and server collision were unchanged. The source atlas SHA-256 was `4505f32bf214c2929d5c3eb05a85c01d473d9b8597ed5f96fc3fde974ea946b6`.

Godot 4.7.2 Compatibility rendered native frames at 667×375 and 844×390 for camera centers `deep` (4470,2800), `overlap` (5000,2800), and `deep_right` (5500,2800). The first cold editor import reported missing generated font cache; the second import had **zero `SCRIPT ERROR`/`ERROR:` lines**. The temporary `terrain-layers.gd` test passed with 15 contours, 565 terrace bands, and 5595 projected vertices. `npm run typecheck` passed. A CPU polygon check found valid geometry with no inset fallback. These checks establish that the candidate rendered and preserved the sampled geometric contracts; they do not establish acceptable art or gameplay.

The retained 667×375 proof frames are [deep](../visual/reef12-shared-junction-rejected-20261118/deep-667x375.webp), [overlap](../visual/reef12-shared-junction-rejected-20261118/overlap-667x375.webp), and [deep right](../visual/reef12-shared-junction-rejected-20261118/deep_right-667x375.webp). Full original PNGs remain in ignored local `artifacts/godot/reef12-shared-junction-candidate/` for this worktree only. Original PNG SHA-256, in deep/overlap/deep_right order: 667×375 `f7fcdeda8112ae620a5b80048e977aeb0f2dade5869ad428e7d1e46c5350cd60`, `d3736bfd899031fd433d257158e91b5b2621828a29e256fe9ed5debe831845da`, `e39f52360530f54b884c9a708f439732a23cf420227cccd008943e2cf7d78f82`; 844×390 `af272a840c312c02f1febc83579579d6225239b63cd847d9a1a68b4bd86f6992`, `bc55a7e0a30b827d4ccd3b4e002d6b89623fcd4279f8ffdcd2d6c9c1d0f1fe52`, `37fdbd22fd679a69022303d7d023a97f789a48e4dcf4ab8f456ccf275b4dbd1e`.

## Why the joint fails visually

- At `deep`, the new shelf starts as a long level horizontal cap; the same porous-rock motif is repeated across the entire volume, so the area reads as a manufactured band rather than a rock formation.
- At `overlap`, the underside becomes angular overlapping plates and a long linear lower edge. The joined mesh is visibly separate from the older backdrop and coral-root art.
- At `deep_right`, the open blue wedge still cuts into the rock with a conspicuous straight/angled boundary. Joining two foreground contours alone cannot paint the absent rock behind this gap.

The visible fault spans three source layers: `TerrainGeometry.gd` independently extrudes the playable contours using one tiled atlas UV/material; `OceanGeology.gd` generates rear stratum meshes from terrain rectangles, so their shape and depth do not meet this new front silhouette; and `OceanBackdrop` supplies a large blue field behind the gap. The new mesh changed only the first layer. The global atlas crop has no dedicated transition pixels for the concave junction, so extending the mesh repeats texture instead of providing an authored undercut. This is a source-composition problem, not a missing connector triangle. The proposed shared polygon also filled some visually open space while leaving authoritative swim geometry unchanged, which would risk confusing players about passability if accepted.

## Next bounded art package

Author both Reef 6 and Reef 12 silhouettes together on the source pixel grid, with a purpose-drawn limestone transition and underside in the ocean terrain atlas or a dedicated, transparently licensed project atlas region. Align the playable front lip, rear stratum and backdrop masking to that same junction in depth, keeping the server swim/collision contour unchanged unless a deliberate gameplay review proves a change is needed. Verify the art at native 667×375 and 844×390, including the full 4470→5500 camera sweep, and check coral mounts, six resonance fixtures and player readability. A single screenshot or polygon-only bridge is not sufficient. No further contour-only runtime trial should be merged as a substitute for this source-art pass.

**Tool/source disclosure:** Godot 4.7.2 native renderer, Python/Shapely for a CPU polygon validity check, Pillow only to convert selected proof PNGs to small WebP files. All visual source material in this trial came from the project; no moodboard image or third-party art was copied. The gallery images are documentation evidence, not distributable game assets.
