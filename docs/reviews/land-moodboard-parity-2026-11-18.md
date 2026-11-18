# Land material and Griya Sasmita visual pass — 18 November 2026

Status: local candidate in `work/land-moodboard-parity-20261118`, based on `08e573160d81d0229902cae98ddb380eaca63ed6`. Not merged or released. This is an incremental improvement, **not full moodboard parity**.

The grass, coast stone and rumbia roof were too flat at the game's actual 667×375 view. `LandMaterials.gd` now gives horizontal grass sparse pixel clumps, cliffs a restrained mineral grain and cooler shaded sides, and rumbia a staggered course pattern with a warmer straw base. `ShelterArchitecture3D.gd` adds roof rafters, a ridge cap, braces and small porch rails to Griya Sasmita in the house's existing local frame. The world footprint, collision and server walkable area are unchanged. Foliage wind animation already exists and was not altered in this package.

Original-size comparison (game captures, not moodboard imports):

| View | Before | Candidate |
| --- | --- | --- |
| Griya front, 667×375 | [before](../visual/land-moodboard-parity-20261118/griya-before-667x375.png) | [after](../visual/land-moodboard-parity-20261118/griya-after-667x375.png) |
| Hub shore and stairs, 667×375 | [before](../visual/land-moodboard-parity-20261118/shore-before-667x375.png) | [after](../visual/land-moodboard-parity-20261118/shore-after-667x375.png) |

The rumbia course and deeper color are readable in the Griya comparison. The cliff adjustment is modest; its silhouette remains faceted and geometric, and the house proportions are still smaller and simpler than the reference. The new roof ribs add around 1.2% rendering primitives in the fixture (`161728 → 163624` at front 844×390), with draw calls unchanged (`149 → 149`). Front 667×375 draw calls remain `137 → 137`. These are native scene counters, **not** Samsung S23 or Windows frame-rate evidence. The grass shader adds arithmetic and a hash per fragment; device frame pacing must be checked before staging. This patch is limited to two land files and can be reverted independently if it proves costly.

Validation: Godot 4.7.2 Compatibility on Apple M2 rendered four same-camera Griya frames and six hub/forest terrain frames. The Griya fixture checked one grounded Nala, max foot error below `0.01`, one Griya pile frame, and the unchanged floor. Headless `natural-terrain-edges.gd`, `terrain-facets.gd`, and `shelter-architecture06.gd` all passed; the shelter test confirmed the house axis still aligns to the deck and sampled 624 foot/torso/head rain positions. No `SCRIPT ERROR` or `ERROR` appeared in their outputs. Test output: `artifacts/godot/land-sasmita-final2/` and `artifacts/godot/land-parity-final2/` in the worktree; baselines in `artifacts/godot/land-parity-baseline/` and the main checkout's `artifacts/godot/land-sasmita-baseline-20261118/`. Combined web/world build remains the integrator's check. No third-party asset, generated raster, external engine or new dependency was introduced; this is project-authored Godot shader and geometry code. The visual references remain reference only and are not redistributed.

Evidence PNG SHA-256: `griya-before` `974498f1e19a4ede4a720e5b47bdbad008b5a4d2ffbe6f554cde79ab6400e7b6`; `griya-after` `abbb8157a79d59618c30f61309e266c46a864931d3bf665c0f9df2504e904353`; `shore-before` `07a086ff82cb650fb2f80c21757e6b03c0d338f27988adb91b3c4e2c0b0d176c`; `shore-after` `9850f7539f526c0acad8c063686453a950686c6198a64b01ca2f956bd8fdc039`.

Next: integrator should inspect the 667×375 A/B alongside ocean and cutscene changes, run the combined Godot and web checks, and evaluate actual Windows/S23 frame pacing and roof readability in gameplay. A future geometry pass should break up the uniform coastal ledge and improve full-size house volumes without altering navigation or dock alignment.
