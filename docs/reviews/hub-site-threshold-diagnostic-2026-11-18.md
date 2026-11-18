# Hub stair-site threshold trial — rejected visual candidate

The central hub still reads as a broad angular dirt V at the main staircase. I tested five small, bounded stone thresholds at the upper and lower stair landings, authored on the existing court elevations. The trial produced grounded stone shapes, but it did **not** change the dominant V silhouette. No terrain or test source from this trial is retained, merged, or released.

| Actual viewport | Baseline on main | Trial candidate | Judgment |
| --- | --- | --- | --- |
| 667×375 | [Before](../visual/hub-site-threshold-diagnostic-20261118/baseline-667x375.webp) | [After](../visual/hub-site-threshold-diagnostic-20261118/candidate-667x375.webp) | The stones read as disconnected small paving at the stair lips; the long diagonal dirt arms remain the visual subject. |
| 844×390 | [Before](../visual/hub-site-threshold-diagnostic-20261118/baseline-844x390.webp) | [After](../visual/hub-site-threshold-diagnostic-20261118/candidate-844x390.webp) | The same V remains, with added geometry but no stronger site composition. |

The CPU trial passed 9/9 focused `village-ground.test.ts` checks and `npm run typecheck`, including convexity, court containment, stair avoidance, material priority, and idempotency. Godot 4.7.2 Compatibility native fixture passed all six hub/forest captures at 667×375 and 844×390 with player grounding error below 0.01. A cold editor import emitted transient missing font import-data errors; its second pass and the native fixture logs contained no `SCRIPT ERROR` or `ERROR:`. These checks establish geometry validity, not art acceptance. Native captures were made from local source only; no WebGL, device, CI, or staging check was run.

The next route package should compose the **whole activity site** around the stair rather than attach more small patches to its edges: e.g. a single authored, walkable irregular packed-earth landing whose foot traffic flows from the house threshold to the stair tread, with two grounded stone wear zones and mostly uninterrupted lawn elsewhere. It must preserve server floor polygons and compare the original-size hub frame before accepting. This is an art-direction recommendation, not a change present in the game.

Evidence provenance: four lossless WebP images converted from original Godot PNG captures with `cwebp 1.6.0`; baseline used main `56798df` and trial used branch `work/hub-site-composition-20261118` based on `1a68c72`. No external assets or runtime tools were added. The trial source and test edits were restored before this diagnostic commit. SHA-256 values are in the adjacent [manifest](../visual/hub-site-threshold-diagnostic-20261118/manifest.json).
