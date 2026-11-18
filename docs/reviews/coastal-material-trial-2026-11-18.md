# Coastal cliff material trial — rejected after original-size review

Source baseline: local `main` at `1061b4a8c4b80865b195a1dfe5642eac51549bf4`. The trial stayed in isolated `work/coastal-material-parity-20261118`; no runtime change from this trial should be merged.

The coastal rock face still repeats across long sections. I tried a narrow, cliff-only color variation in `LandMaterials.gd`: ochre mineral patches and cool green lichen using the shader's existing `patch` and `vein` values. It added no texture, hash call, mesh, physics or walkability change. The second version strengthened the effect after the first was nearly invisible.

| Camera | Baseline | Second trial |
| --- | --- | --- |
| Hub lower coast, 667×375 | [before](../visual/coastal-material-trial-20261118/before-667x375.png) | [trial](../visual/coastal-material-trial-20261118/trial-667x375.png) |
| Hub lower coast, 844×390 | [before](../visual/coastal-material-trial-20261118/before-844x390.png) | [trial](../visual/coastal-material-trial-20261118/trial-844x390.png) |

The color difference is visible at 667×375, particularly near the lower bank, without bright speckle. It does **not** sufficiently change the repeated, broad stone-face language. The small improvement is not worth another fragment-shader branch on mobile. I restored `LandMaterials.gd`; the candidate screenshots are diagnostic only. Neither candidate is part of the release source.

Both pairs came from the same `scripts/tests/terrain-facets-render.gd` camera, frozen daytime weather and Godot `4.7.2.stable.official.ed1daf0bf` Compatibility renderer on Apple M2. Baseline and second trial each completed six native hub/forest frames with no script or render error. A first attempt used an incorrect script path and never ran; the new worktree's initial editor import briefly logged missing font cache resources before finishing. The subsequent render was clean. There was no browser or physical-device frame-pacing test for the rejected shader. Source assets and map JSON were unchanged. The reference moodboard was not bundled or copied.

Image SHA-256: baseline 667 `e0d0df54c3765d9f04e3fa26d079d32c6f3e089b527e93fa75579d6dec5594a3`, trial 667 `5ba6ff186054641a0254084fde1d7492fe67f9188681ee0b27faf60435257109`, baseline 844 `3f11848de126fb4e1fbcd399ff03a2dfbae4faa9c22746eedc0d3fc45e6c1873`, trial 844 `82fa2241e64045636a78d4073bd2ae3f6092a25c69cb0a4f3f3a02e65b2f7e72`.

Next high-impact candidate: improve the **grass-to-dirt path boundary**, which occupies more of the played screen than the cliff material. The existing nonwalkable dirt trails already pass through `LandWorld3D._build_soft_ground_edge()` with a seven-unit alpha fade and `LandMaterials.get_edge_material()`. A bounded next pass can vary the transition width in world space and add sparse rooted grass tufts to that existing edge mesh, preserving the dirt path interior and server walkability. It would own `client-godot/scripts/land/LandWorld3D.gd` and, only if needed, `LandMaterials.gd`; keep `NaturalTerrainEdges3D.gd` untouched. Risks: noisy dither at 667×375, extra vertices on long trails, stair-edge overlap, and false walkable cues. Require same-camera hub/forest A/B, route/stair clearance checks, primitive/draw-call counts and reduced-motion review before acceptance.
