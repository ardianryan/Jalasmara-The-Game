# Reef 12 visible-contour trial — rejected

**Decision:** Do not merge the trial contour. Its inward cove is measurable but barely changes the long, flat right shelf at game size. The `deep_right` view also exposes a large pre-existing vertical rectangle seam; the trial neither caused nor fixes it. This branch retains only this report and original-size evidence. No runtime, shared-world, collision, or fixture change remains.

## Trial and controls

- Base: `edde5e988472f073d96b243a3f7886b7f5076d33`; Godot `4.7.2.stable.official.ed1daf0bf`, Compatibility renderer on Apple M2; `RenderQuality=balanced`.
- Changed only Reef 12's shared top contour between world x4500–4870. The former nearly level points `(4630,2800)` and `(4740,2805)` were replaced by a continuous cove through `(4560,2815)`, `(4620,2836)`, `(4680,2839)`, `(4740,2818)`, and `(4800,2816)`. No six boss targets, valve, or coral source anchors were edited. The same `WORLD.terrainContours[12]` supplies the Godot mesh and authoritative server collision.
- Focused `reef-sanctuary-contour.test.ts` with the trial's added bounds, non-crossing, reachable boss targets, and three reachable valve-approach points: **1/1 passed**. Native fixture: **four captures passed**, `coralPivots=43`, `coralStoneMounts=39`, oxygen 77 and coins 700 unchanged. The fixture ran in 667×375 and 844×390 at `(4470,2800)` (`deep`) and `(5500,2800)` (`deep_right`).
- `npm run check:world` was attempted without `GODOT_BIN` and stopped at `spawnSync godot ENOENT`; it is **not a passing result**. The focused test and native render above completed separately. The first cold Godot editor import emitted transient missing font-import cache errors while populating `.godot`, then exited 0; the subsequent native fixture completed without `SCRIPT ERROR` or `ERROR`.

## What the images show

At `deep`, the cove lowers a narrow part of the shelf under/near the right coral, but the foreground still reads as a nearly horizontal slab rather than a continuous eroded limestone terrace. Compare the accepted [baseline 667](../visual/reef12-volume-20261118/deep-667x375.png) and [baseline 844](../visual/reef12-volume-20261118/deep-844x390.png) with the [trial 667](../visual/reef12-visible-contour-rejected-20261118/trial-deep-667x375.png) and [trial 844](../visual/reef12-visible-contour-rejected-20261118/trial-deep-844x390.png). This fails the visible-shape acceptance even though collision stays sound.

At `deep_right`, both [baseline 667](../visual/reef12-visible-contour-rejected-20261118/baseline-deep-right-667x375.png) and [trial 667](../visual/reef12-visible-contour-rejected-20261118/trial-deep-right-667x375.png) have the same vertical dark/blue divide at screen x≈341. The [baseline 844](../visual/reef12-visible-contour-rejected-20261118/baseline-deep-right-844x390.png) and [trial 844](../visual/reef12-visible-contour-rejected-20261118/trial-deep-right-844x390.png) show it at x≈430. With camera x5500 these positions map to world x≈5507–5508. This closely aligns with the left edge of `WORLD.terrain[6] = [5500,1000,644,2100]`; `TerrainGeometry.configure()` renders it as an independent reef mesh while Reef 12 spans x4300–6144 behind/in front of it. The rectangle is the likely cause of the hard join, but this trial did not isolate every overlapping geometry layer, so treat that attribution as a strong inference, not proof. The seam predates the candidate and remains unacceptable for the moodboard target.

## Next bounded pass

Inspect the actual overlap of `ReefRelief6`, `ReefRelief12`, and the cave backwall at world x≈5500 before changing art. A successful fix needs a connected limestone transition across their visible join, with the upper shelf, front face, and irregular underside designed together. If the server terrain rectangle changes, test its collision and all boss/valve approaches; a purely visual face must still meet the shared contour and cannot be a pasted strip. Capture both camera centers at 667 and 844 again and reject any remaining hard seam or flat shelf.

Evidence is native project output, not a distributed art asset; the temporary trial fixture and source changes were removed after the rejection. Tools actually used: Godot 4.7.2 native Compatibility render, Node/tsx focused server test, Pillow pixel-difference inspection. No external art tool, AI image, or third-party asset was used.
