# NW explorer elbow cut: CPU pixel review

Reviewed website source `c5431a8`, `tools/player-gait/nw-explorer-upper-rig.py` and its JSON, against `nw-explorer-upper-rig-draft-v4/nw-explorer-isolated-arm-endpoints.png`. No art or runtime files changed in this lane.

The visible square inward notch in authored chain A is a joint cut/transform gap. The upper arm remains stationary while the forearm rotates +32° about authored elbow `(54,59)`. The original pixels `(55,58)` RGBA `(222,178,135,255)` and `(56,58)` RGBA `(217,171,128,255)` belong to the upper cutout. They therefore do not cover the rotating forearm root. Independent execution of the existing nearest-neighbor transform reproduced transparent output pixels `(55,59)`, `(56,59)`, and `(56,60)`; the stationary upper cutout is also transparent at those three positions.

The website's isolated overlap probe copies those two original colors at their original source coordinates into a separate hidden forearm-root overlap. It fills exactly those three output pixels. Neutral compositing remains byte-identical to the reference arrangement. Inspection of `nw-elbow-notch-source-v1/hidden-original-palette-overlap-probe.png` shows the square cut removed while retaining the sleeve and elbow location.

This is a bounded authored overlap proposal, not recovered anatomy or exclusive source ownership. Moving the elbow from x54 to x58 would instead move the rotation axis four source pixels. Prefer retaining the current authored pivot while recording the two duplicate overlap texels and their donors explicitly. The remaining endpoints and any later loop must still be inspected for outline bulges, double contours, and depth ordering. This review establishes the captured endpoint's pixel mechanism only; it supplies no gait, contact-phase, runtime, or anatomical-side acceptance.

CPU review used Pillow and the existing authoring module without writing its source or outputs. An initial diagnostic loop incorrectly assumed a 128-pixel-high upper crop and raised `IndexError`; rerunning over the actual image dimensions produced the exact three-pixel result above. No Godot, browser, or GPU process ran.
