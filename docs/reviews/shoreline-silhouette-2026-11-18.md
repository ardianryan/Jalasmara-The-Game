# Coastal shoreline silhouette — 18 November 2026

Status: local candidate on `work/shoreline-silhouette-20261118`, based on `6825196c930d7529e42aef4de3b23f9ba2b456c9`. The integrator accepted the original-size A/B as a material improvement over the [rejected earlier trial](land-cliff-landform-trial-2026-11-18.md). This package is not a full moodboard-parity claim or a staging release.

`NaturalTerrainEdges3D.gd` now gives the existing grass/soil lip a wider, irregular visual overhang. Its width remains below 42% of the rooted rock shoulder. The upper and belly rings extend progressively outward so the slope does not fold back beneath the new lip. A small height variation breaks the ruler-like top edge. All changes are to the visual mesh; the authoritative walkable polygon, floor, routes, stairs, dock, collision and server map remain unchanged. Existing connector and wood exclusions still apply.

Same-camera original-size Godot 4.7.2 Compatibility captures on Apple M2:

| View | Baseline | Candidate |
| --- | --- | --- |
| Lower coast, 667×375 | [before](../visual/shoreline-silhouette-20261118/coast-before-667x375.png) | [after](../visual/shoreline-silhouette-20261118/coast-after-667x375.png) |
| Lower coast, 844×390 | [before](../visual/shoreline-silhouette-20261118/coast-before-844x390.png) | [after](../visual/shoreline-silhouette-20261118/coast-after-844x390.png) |
| Central stairs, 667×375 | [before](../visual/shoreline-silhouette-20261118/stairs-before-667x375.png) | [after](../visual/shoreline-silhouette-20261118/stairs-after-667x375.png) |

The lower coast's upper edge now follows visible small coves and rock projections instead of one nearly straight border. The stair opening and the dock approach remain clear in the reviewed captures. The forest bridge was also inspected at 667×375 and did not show a new seam. The coast still has a fairly uniform elevation and repeated material language; a later authored shoreline/boulder pass is needed for complete visual parity.

Validation: `scripts/tests/natural-terrain-edges.gd` passed with eight actual surfaces, 512 active nodes, 516 connector exclusions and 251 supported nodes. Its new assertion checks readable variation in the synthetic upper silhouette and keeps the lip inside its root shoulder. `terrain-facets.gd` and `land-cliff-strata.gd` passed. `terrain-facets-render.gd` captured six actual map frames at 667×375 and 844×390 on both baseline and candidate. The final focused tests and native renders emitted no `SCRIPT ERROR` or `ERROR:`. The fresh-worktree first editor import emitted transient missing-font cache errors before its asset import finished; subsequent tests and captures were clean. No full build, browser traversal, Windows/Samsung GPU timing, or staging activation is claimed here.

Evidence SHA-256: coast 667 before `7fce7c886bf1809ecac6c5936044445aea74f477687a90e8fb35638fb610c8f0`, after `ade71afcf49c6b612b8f3e06005929afbf445e7fc67624642d4a360adc45a571`; coast 844 before `4fbab82a0c13f41a83c7c7e8677384019d2bf3dd6dc92fc6dc8eb183c0c76f97`, after `7247a10fbc922e75e38c4c67797a0139e04bce378ae15a599e4deb5198bcce13`; stairs before `6eef6f85b35627ef99149daf0fe2891849adee04f97dc81acb7575eee7be46c5`, after `e0c82bc90a8612d56182d7a6be0b5a51441aa3f20ea964b8af03f164d8a6d392`. Full captures and `results.json` remain ignored under `artifacts/godot/shoreline-baseline-20261118/` in main and `artifacts/godot/shoreline-candidate-20261118/` in this worktree.

Tools/provenance: project-authored Godot geometry and fixture only; no external art, generated image, third-party runtime or new license. Proof PNGs are original Jalasmara game captures. The external moodboard was a visual reference and was not copied into the project.
