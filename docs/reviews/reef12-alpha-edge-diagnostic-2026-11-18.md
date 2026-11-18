# Reef 12 alpha-edge trial — rejected

**Decision:** No runtime or art asset from this trial should be merged. The new transparent limestone edge looked like a bright, vertically stacked insert at original game size, and it did not remove the visible atlas join. This branch contains only this report and two curated A/B captures.

Starting from local `main` at `f01b223`, I cut a 160×320 RGBA image from the project's own `ocean-terrain-atlas.png`. Deterministic per-pixel Python/Pillow code formed an irregular left contour, four water holes, and dithered top/right/bottom ends. `TerrainGeometry.gd` temporarily mounted the resulting `Sprite3D` near world `(5500,2640)`. The first variant sat behind the limestone wall at depth −145. The second sat at depth +36 with a darker tint, so it could cover the join. Neither changed the authoritative reef contour, collision, boss target, coral mount, player, pipe, or save state. The source script, texture, fixture, and runtime edit were removed after review.

| Native capture | Assessment |
| --- | --- |
| [Trial A, 844×390](../visual/reef12-alpha-diagnostic-20261118/trial-a-844x390.webp) | Rock protrusion enters the blue water, but the pale horizontal bands are too bright and the original vertical wall join remains obvious. |
| [Trial B, 667×375](../visual/reef12-alpha-diagnostic-20261118/trial-b-667x375.webp) | The front-depth overlay creates a stack of pale cut bands, sits near the coral/player lane, and still reads as a pasted layer. |

Both proofs are lossless WebP, baseline on the left and rejected trial on the right. They are original Jalasmara development evidence, not distributed art. The baseline is extracted from the previously recorded concave-entrance A/B under the same camera/viewport fixture; trial A and B differ in tint and depth, as described above. Trial A SHA-256: `0f3011990e9e7ce88cbfc42c805eaae62cffcba88e349da7ae2a35eb68b04200`; trial B: `3f7638e953bd2728b94923194eb0a4d91aab21c5e8320c4f4323855e30151461`.

Godot 4.7.2 native Compatibility on Apple M2 exited 0 for trial A at 844×390 and trial B at 667×375, with coral pivots present and unchanged oxygen 77/coins 700. A second 844×390 trial B run stalled without a frame after 30 seconds and was interrupted. First editor import emitted transient font-cache errors; that output is not a clean import result. `git diff --check` passed after reverting source. No browser, Windows, or S23 parity is claimed.

**Finding:** A derived strip from the existing atlas carries its own bright ledges and cannot conceal a front-depth wall seam simply by alpha masking. The next accepted approach needs a purpose-authored muted edge with pixel-level color/lighting matched to the wall, plus an authored irregular termination of the wall itself or another depth-safe blend. Test a moving camera sweep before integration; preserve open water and all gameplay anchors. A transparent card alone is not enough.
