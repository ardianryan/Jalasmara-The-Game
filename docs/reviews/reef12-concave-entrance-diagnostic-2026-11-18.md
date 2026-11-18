# Reef 12 concave entrance trial — rejected

**Decision:** The authored scalloped polygon improves the apparent rock continuity at some camera positions, but its horizontal cut lips and the remaining vertical atlas join are visible at native size. The runtime edit was reverted. This package contains a diagnostic report and six paired, lossless, original-size WebP captures; it is not a moodboard parity, gameplay, or staging claim.

The isolated branch `work/reef12-concave-entrance-20261118` started at `7e2aa71`. `TerrainGeometry.gd` temporarily placed a three-lip concave rear face behind the Reef 12 swim lane, x4880–5660/y2400–2890, depth −95. It reused the existing limestone atlas. No authoritative floor, collision, Nala sprite, coral mounts, valve, pipe, boss logic, or save state changed. Shapely 2.0.7 found the 26-point polygon valid and non-self-intersecting (216,352 world²); that CPU result did not predict the visible atlas cuts.

| Camera (world center) | Paired native proof | Assessment |
| --- | --- | --- |
| `deep` (4470,2800), 667×375 | [base / candidate](../visual/reef12-concave-diagnostic-20261118/deep-667x375.webp) | Main composition and actor visibility remain stable; far-right rock grows slightly. |
| `overlap` (5000,2800), 667×375 | [base / candidate](../visual/reef12-concave-diagnostic-20261118/overlap-667x375.webp) | New lip enters from right as a flat, sliced horizontal band. |
| `deep_right` (5500,2800), 667×375 | [base / candidate](../visual/reef12-concave-diagnostic-20261118/deep_right-667x375.webp) | Blue cavity is smaller but the new tips read as pasted rock layers. |
| `deep` (4470,2800), 844×390 | [base / candidate](../visual/reef12-concave-diagnostic-20261118/deep-844x390.webp) | Far-right entrance remains an abrupt atlas edge. |
| `overlap` (5000,2800), 844×390 | [base / candidate](../visual/reef12-concave-diagnostic-20261118/overlap-844x390.webp) | Multiple cut lips appear and the rear-wall join persists at the right edge. |
| `deep_right` (5500,2800), 844×390 | [base / candidate](../visual/reef12-concave-diagnostic-20261118/deep_right-844x390.webp) | The main void is reduced, but the atlas repeats at a hard vertical join around local x≈470; the entrance still looks assembled from sheets. |

The six pairs preserve visibility of Nala, the coral mounts, and the resonance valve. The lower reef shelf's rectangular underside and blue gap also remain; this trial was deliberately limited to the rear entrance. It must not be accepted as a fix for the complete 2.5D reef.

**Next technical approach:** Author a transparent, segmented limestone transition with irregular alpha silhouette and interior negative-space holes in the project's own pixel grid. Use separate foreground and background pieces anchored to the existing cave/rear-wall geometry, with feathered depth ordering and small parallax separation, rather than a new opaque atlas polygon. Inspect UV continuity and projected endpoints across a moving camera sweep before touching collision. Keep water pockets open and test at both native sizes; reject any visible straight atlas edge, repeated texture strip, or Nala/coral/valve occlusion. A procedural contour alone cannot make the opaque texture edge natural.

Godot 4.7.2 Compatibility (`ed1daf0bf`, Apple M2) produced native A/B at 667×375 and 844×390. The combined 844 baseline fixture stalled after two frames; it was interrupted and all 844 views were captured in independent one-camera runs with `RenderingServer.force_draw()`, each exiting 0. The 667 baseline/candidate runs exited 0. The fixture asserted coral pivots present and unchanged oxygen 77/coins 700; the baseline reported 43 pivots/39 mounts. A clean second editor import exited 0 without `SCRIPT ERROR` or `ERROR:`. `git diff --check` passed. Native stills do not establish motion quality, WebGL performance, or device acceptance.

The captures are original Jalasmara development evidence, not game assets. They were paired with Pillow and converted losslessly with local `cwebp`; no external art, shader, or upstream source was imported. Ignored PNGs and fixtures remain under `artifacts/godot/reef12-concave-{baseline,candidate,comparison}-20261118/` and `.runtime/` in this worktree for reproduction. The temporary source patch is ignored at `.runtime/reef12-concave.patch` and must not be cherry-picked.
