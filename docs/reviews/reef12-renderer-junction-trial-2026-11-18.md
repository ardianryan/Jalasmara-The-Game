# ReefRelief6/12 renderer junction trial — rejected

Base: `aa0e8abbbc4986459dc150cdd260d111c50ef7f4`. This was a renderer-only trial in `TerrainGeometry.gd`; `world.ts`, server collision, coral mounts, boss anchors, and resources were untouched. The trial source was reverted. This commit contains documentation only.

At the `deep_right` camera center `(5500, 2800)`, the baseline has a nearly vertical dark/blue seam near screen x≈341 at 667×375 and x≈430 at 844×390. The seam corresponds to the left boundary of `ReefRelief6` (world x≈5500), where its independently built mesh meets `ReefRelief12` across the y=2800–2960 overlap. A separate textured rear shoulder at x5448–5570, y2470–3050, z−245…−90 hid a small part of the gap but created a narrow pasted vertical ribbon and shifted the hard edge left. It did not make the two reef masses read as a connected limestone face, so it fails visual acceptance.

| View | Baseline | Rejected candidate |
| --- | --- | --- |
| 667×375 | [baseline](../visual/reef12-visible-contour-rejected-20261118/baseline-deep-right-667x375.png) | [candidate](../visual/reef12-renderer-junction-rejected-20261118/candidate-deep-right-667x375.png) |
| 844×390 | [baseline](../visual/reef12-visible-contour-rejected-20261118/baseline-deep-right-844x390.png) | [candidate](../visual/reef12-renderer-junction-rejected-20261118/candidate-deep-right-844x390.png) |

Native Godot 4.7.2 Compatibility (`ed1daf0bf`, Apple M2) rendered both camera sizes without `SCRIPT ERROR`. Fixture results retained the same 43 coral pivots, 39 stone mounts, oxygen 77, and 700 coins. These checks do not establish visual or gameplay acceptance. No `check:world` claim is made for this reverted trial.

Next attempt should alter the mesh topology itself: construct a continuous shared rear wall or stitch overlapping boundaries within `TerrainGeometry.gd`, preserving existing server contours and coral/boss placement. It must be checked at both original sizes and the `deep_right` camera; another overlay strip is not a solution.
