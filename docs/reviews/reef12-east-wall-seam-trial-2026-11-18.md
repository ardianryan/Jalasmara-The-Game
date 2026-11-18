# Reef 12 / Jalatunda east-wall seam trial — rejected

**Decision:** Keep the original runtime geometry. Bending the authoritative left contour of the east wall removes the perfectly vertical line, but exposes a larger opaque triangular gap at game size. The trial fails the connected 2.5D reef requirement and is reverted; this commit contains only the report and two original-size candidate captures.

## Cause and trial

At the `deep_right` camera centered on world `(5500,2800)`, the baseline dark/blue vertical join appears at screen x≈341 on 667×375 and x≈430 on 844×390. These map to world x≈5507–5508. `WORLD.terrain[6]` is the tall `[5500,1000,644,2100]` east wall. Its generated contour has a near-vertical left chain `(5500,3040) → (5523.53,2008) → (5500,1060)`. `TerrainGeometry.configure()` renders that rectangle and the overlapping sanctuary shelf `WORLD.terrain[12]` as independent `ReefRelief6` and `ReefRelief12` meshes. The coordinate match and separate mesh construction strongly implicate their boundary; a full depth/occlusion trace would be needed to prove which triangle owns every seam pixel.

On base `dbc140985ed8e409b18416208aa6c1b4d8350ab8`, the trial kept the wall's top, right, and bottom vertices and replaced that left chain with 13 inward points, staying within x5500–6144. The purpose was to create an irregular limestone edge while opening, rather than closing, swim space. No boss target, valve, or coral source anchor changed.

The trial's focused server checks passed **2/2**: the new polygon did not self-intersect, a 10×20-unit sample grid along the wall found no newly blocked water, and the boss/valve points remained open. The first draft failed one clearance sample at `(5490,1160)` and was corrected before native capture. Godot 4.7.2 Compatibility on Apple M2 completed all four native `deep`/`deep_right` captures at 667×375 and 844×390. Each reported 43 coral pivots, 39 stone mounts, and unchanged oxygen/coins. `deep` was visually unchanged because the edit is outside that camera. These are CPU and native-project checks; no browser/device test was claimed.

## Visual result

Compare the [baseline 667](../visual/reef12-visible-contour-rejected-20261118/baseline-deep-right-667x375.png) and [baseline 844](../visual/reef12-visible-contour-rejected-20261118/baseline-deep-right-844x390.png) with the [trial 667](../visual/reef12-seam-rejected-20261118/trial-deep-right-667x375.png) and [trial 844](../visual/reef12-seam-rejected-20261118/trial-deep-right-844x390.png). The trial creates a wide, smooth-edged blue wedge, not a porous connected rock face. It reaches Nala's screen position and makes the seam more prominent. The hard visual rejection overrides the passing collision checks.

The next attempt should own the actual `ReefRelief6`–`ReefRelief12` junction in `TerrainGeometry.gd`: inspect their projected depth and overlap, then author a connected, textured rock transition with an irregular underside. Preserve the shared server collision contour unless the swim-path check is updated alongside a deliberate geometry change. Recheck both camera centers at 667 and 844; do not accept an untextured wedge, pasted front strip, or hidden-only fix.

Temporary source, focused test, and native fixture were removed. The ignored native A/B output remains local under `artifacts/godot/reef12-seam-{base,candidate}-20261118/`; the two curated PNGs above are development proof, not distributed assets. SHA-256: 667 trial `dfb48ccab45727ab24111a6d2750cb7be6036b8c60947f0bafb9eb738a33934f`; 844 trial `dbe71aebc3f148b459eba55f06f6bf3d795f93ea8aa3c18a5025ec5f18b3cd91`. Tools used: Godot 4.7.2 native renderer, Node/tsx focused test, and Pillow image inspection. No external asset or AI image was used.
