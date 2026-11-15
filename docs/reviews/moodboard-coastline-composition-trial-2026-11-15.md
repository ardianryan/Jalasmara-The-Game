# Coastline composition trial rejected

Date: 15 November 2026. Branch: `work/coastline-composition`, based on `9392ec9`. This is a visual experiment, not a runtime candidate. No source, map, collision, stairs, or dock change is offered for integration.

The earlier [terrain source-quality trial](moodboard-terrain-source-quality-trial-2026-11-15.md) found that fine stone noise disappears at game size. I tried a broader treatment: increase the outward-only naturalized bank relief from 12 to 20 world units and group the existing terrain-shoulder material into wider upper stone, shaded middle, and dark lower bands. The first combined render made large flat pale stone panels more obvious, so I reverted its material changes and rendered the contour increase alone. That changed the lower-coast silhouette slightly but barely changed the forest banks. At the actual 667×375 frame size, the contour-only variant differs from baseline by 6,924 pixels (2.77%) in the hub lower-coast view, but only 871 pixels (0.35%) in the forest upper-west-bank view, counting RGB differences above 8. The lower-coast gain was not strong enough to compensate for an uneven result across the two islands. Both candidate changes were reverted.

I captured the same hub lower coast, central stairs, and forest upper-west bank at 667×375 and 844×390 in day and dusk conditions: 12 baseline frames, 12 combined-candidate frames, and 12 contour-only frames. The render fixture asserted one player, under 0.01 foot error, and unchanged world JSON. The Godot 4.7.2 Compatibility native renderer completed all passes without `SCRIPT ERROR` or `ERROR`. Focused `terrain-facets.gd` and `natural-terrain-edges.gd` tests passed after reverting; the latter still reports eight surfaces, 512 nodes, 516 exclusions, and 251 supported nodes. These were native/source checks, not a browser traversal, GPU benchmark, or physical-device review.

Diagnostic source frames and logs were reviewed in the isolated worktree, then removed with that worktree after the candidate was rejected. Representative SHA-256 values recorded during review:

| View | Baseline | Trial |
| --- | --- | --- |
| Hub lower coast, day, 667×375 | `06802ab7c520f005cb841d37ca64e29e77d88b0534957131eb6435a0f0221788` | Combined material: `6febe0567511485612c6c39b124c3320e00a7ab2f2f4f5b3d1860521b94c8a9d`; contour only: `abb2fdc6ce207a0c5d6870e9ccf855f33a5cc3104b88cdc5cf0d2894b0303471` |
| Forest upper-west bank, day, 667×375 | `7dc35697eec0c199f6570dc7e7d308f707b6ee0d7aad1405f683dce1944d3c42` | Contour only: `1412a31bb5a095292482d178893b6efcb5100c32021a102464fbb71a8b3192ea` |

Next terrain work should treat the visible island footprint as an authored composition at actual display size, with readable limestone ledges and grass-to-stone transitions, not uniformly stronger procedural displacement or random material bands. Keep the dock/stair mouths, authoritative walkable polygons, and collisions unchanged. Compare exact before/after day and dusk frames before accepting it.

Tools used: isolated Git worktree, project-authored GDScript trials, Python Pillow for pixel-difference measurement, Godot 4.7.2 Compatibility native renderer and focused tests. No external art, third-party code, or new asset license was used. The trial source was never pushed, merged, exported, or staged; only this rejected-trial report was copied into the main documentation.
