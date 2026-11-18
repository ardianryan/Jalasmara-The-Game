# ReefRelief6/12 topology union — rejected

**Decision:** Keep the existing renderer. A visual-only union of the east wall and sanctuary shelf removes neither the long straight edge nor the occlusion problem. The trial source and native fixture were reverted; this package contains only the failure report and original-size proof.

The trial started from main `993981bca2d8e9504b4a6d055c47cd78b6341a8a`. `TerrainGeometry.gd` used `Geometry2D.merge_polygons` for `world.terrainContours[6]` and `[12]`, drew the result as one `ReefRelief6`, and skipped the separate `ReefRelief12` mesh if the union succeeded. The server world, collision contours, coral mounts, boss targets, and valve were untouched. A CPU polygon check found two valid contours, a positive overlap of about 67,510 world², and one valid 36-vertex union. This establishes a connected 2D polygon, not a successful 2.5D render.

Godot 4.7.2 Compatibility (`ed1daf0bf`, Apple M2) completed four native frames: `deep` and `deep_right` at 667×375 and 844×390. The second editor import and the focused render log had no `SCRIPT ERROR`/`ERROR`. The fixture found the merged mesh and no separate `ReefRelief12`; it retained 43 coral pivots, 39 stone mounts, oxygen 77, and 700 coins. No browser, device, server collision, or integrated build acceptance is claimed for this reverted trial.

| `deep_right` camera `(5500,2800)` | Accepted baseline | Rejected union |
| --- | --- | --- |
| 667×375 | [baseline](../visual/reef12-visible-contour-rejected-20261118/baseline-deep-right-667x375.png) | [union](../visual/reef12-topology-rejected-20261118/candidate-deep-right-667x375.png) |
| 844×390 | [baseline](../visual/reef12-visible-contour-rejected-20261118/baseline-deep-right-844x390.png) | [union](../visual/reef12-topology-rejected-20261118/candidate-deep-right-844x390.png) |

The upper wall remains an almost perfectly vertical edge at screen x≈341/430 because that edge is **external to the union**, running along world `(5500,1060) → (5523.53,2008) → (5504.71,2833)`. Merging removes only the internal overlap border. Worse, the merged front surface uses `_build_reef`'s `FRONT_DEPTH=26` plus relief and draws in front of Nala's sprite depth 12 near the join; Nala is partially/mostly hidden in both right-camera frames. The resulting rock remains a broad flat slab rather than a naturally eroded 2.5D terrace. It is not acceptable despite the green fixture assertions.

A safe next pass needs a **bounded authored outer-wall silhouette** plus explicit depth ordering at Nala's swim lane. Treat the outer wall as rear scenery at z<12 where the player can pass in front, and keep collision-bearing ledges tied to the authoritative contours. Merely merging the two filled front faces, adding a separate strip, or moving the server contour inward repeats the failure modes documented in the earlier seam reports. Before implementation, add a targeted depth/triangle ownership diagnostic at `(5500,2800)` and prove at actual game size that the sprite remains visible and the wall blends into the shelf. Any renderer-only overhang must be visibly non-solid so it does not imply a false collision boundary.

Candidate PNG SHA-256: 667×375 `20447ca451e1055b5c1286003c3b3e3ba4a2aa02ecd3a1600a4d2dca2fe17df2`; 844×390 `f3fe60b5a078d39b004101cbb5d84d4abe56a84316ff305b8698cecc8fdc947e`.
