# Coastal cliff strata candidate — 18 November 2026

Status: local source candidate on `work/land-parity-20261118b`, based on `ab70368164c8303e47c575535d699d7784974b65`. Not merged, pushed, or released.

At actual game size, the lower hub coast still read as one long, pale polygon strip. The earlier geometry pass added irregular faces and rooted toes, but its stone material lacked a readable layered surface. This pass adds stepped mineral beds and short, interrupted seams to **cliff-side stone only**. Its three existing side buffers share the existing spatial shader. Ordinary stone paths, props, terrain top, camera, walkable polygons, stairs, collision and server floor data are unchanged. There are no new nodes, textures, meshes or draw calls. The shader uses the existing mineral `vein` value for short seams; the added arithmetic applies only when `cliff_strata` is enabled on an exposed face.

| Same-camera lower coast | Baseline | Candidate |
| --- | --- | --- |
| 667×375 | [before](../visual/land-cliff-strata-20261118/before-667x375.png) | [after](../visual/land-cliff-strata-20261118/after-667x375.png) |
| 844×390 | [before](../visual/land-cliff-strata-20261118/before-844x390.png) | [after](../visual/land-cliff-strata-20261118/after-844x390.png) |

The first trial used frequent connected lines and looked like masonry, so it was discarded. The final trial uses wider beds with discontinuous seams. It adds a modest readable layering along the lower edge, but the shore is still made of broad angular facets with a fairly uniform overall ledge height. This is an incremental material correction, **not full comfy moodboard parity**. The next large visual gain would require a separately reviewed geometry/landform pass, with the current stair and shoreline support invariants preserved.

Method: the project-owned `scripts/tests/terrain-facets-render.gd` captured six fixed hub/forest frames at 667×375 and 844×390 through Godot 4.7.2 Compatibility on Apple M2. The baseline used local `main` at `ab70368`; candidate used this isolated worktree. Both selected images came from the same `hub-lower-coast` camera. First run in the fresh worktree lacked Godot imports and emitted missing-resource errors; a headless editor import completed, then the final native render passed with no `SCRIPT ERROR` or `ERROR:`. Full captures remain ignored under `artifacts/godot/land-strata-baseline-20261118/` and `artifacts/godot/land-strata-candidate3-20261118/`.

Focused Godot checks pending the shared native slot: `scripts/tests/land-cliff-strata.gd` checks that only cliff-side stone opts in to the material, all three side buffers share the existing shader, and the edge helper reports no physics changes. Existing `natural-terrain-edges.gd` and `terrain-facets.gd` check deterministic geometry, connector cutouts and stair travel. The native A/B render passed; it does not substitute for these focused checks. No browser WebGL or physical Windows/Samsung S23 GPU timing was measured; the shader arithmetic still needs device frame-pacing review before release.

Evidence SHA-256: before 667 `d325b12a01a383ac3199a0732e7b130ede69ffe50825dea7f25000f1d9b1784f`; after 667 `fea5b98edb5b041c68259aa268ee4ca832c8f106be875bba3c06ab4123995e54`; before 844 `00a74bcb3d2c2d91fac518daa7efdbe0f3f44dcb23bd084f18cb07b920700315`; after 844 `c3aebbf0cc4a8f17e01b0247f1ac145216316ddc5b41db02201bcc0e62051ad8`.

Tools and provenance: project-authored Godot material and geometry code only; no new image, third-party tool, asset, runtime package or license. The external moodboard was used as a visual reference and was not copied into the game. Integrator should review the A/B at original size, run combined checks, update the active handoff, and only then decide whether to integrate and remove this worktree/branch.
