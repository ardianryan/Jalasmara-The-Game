# Coastal cliff visual pass — 18 November 2026

Status: local candidate on `work/land-cliff-parity-20261118`, based on `e3443eab298b5f8d047a1a06e4413e2f5d1315b3`. Not merged or released. This improves the coastal edge, but **does not establish full moodboard parity**.

The previous coast read as a pale strip of similarly sized triangular facets. `NaturalTerrainEdges3D.gd` now groups stone and shadow into longer, irregular strata; makes the lower rock value cooler and deeper; lets the upper and middle rings vary their slope more; and adds occasional tiny grass overhangs to the existing lip mesh. These are visual meshes only. The authoritative polygon, connector exclusions, stair openings, lower-floor support, toe limits and collision source remain untouched. The grass overhang uses the existing lip mesh, so it creates no new draw call; its few triangles add a small geometry cost. No new shader or texture was added in this pass.

Same-camera, actual-size captures:

| View | Before | Candidate |
| --- | --- | --- |
| Hub central stairs, 667×375 | [before](../visual/land-cliff-parity-20261118/central-before-667x375.png) | [after](../visual/land-cliff-parity-20261118/central-after-667x375.png) |
| Hub lower coast, 844×390 | [before](../visual/land-cliff-parity-20261118/coast-before-844x390.png) | [after](../visual/land-cliff-parity-20261118/coast-after-844x390.png) |

At 667×375 the darker root line and longer strata are visible, especially beside the stairs. The land still has a mostly uniform ledge height, and the triangles remain somewhat angular; a future geometry/art pass would need irregular boulder clusters and more varied shore transitions while preserving the navigable polygon. Do not present this as final visual parity.

Validation: Godot 4.7.2 Compatibility native on Apple M2 rendered six fixed hub/forest day frames via `scripts/tests/terrain-facets-render.gd`; `natural-terrain-edges.gd` and `terrain-facets.gd` passed headless. The natural-edge test checked deterministic corner fans, 512 actual nodes, 516 connector cutouts, supported toes, unchanged map JSON, and walkable stair routes. No `SCRIPT ERROR`/`ERROR` appeared. This is native-render evidence, not browser or Samsung S23 frame pacing. Scene draw calls have not been independently profiled in this second pass; geometry remains in the same five mesh buffers per surface. Combined build and actual-device performance remain for the integrator.

Inputs and provenance: project-authored Godot geometry; no external asset, installed tool, generated raster or third-party runtime used. The reference moodboard was not copied into the game or repository. Native full captures are ignored worktree artifacts at `artifacts/godot/land-cliff-final/`; baseline was captured from main at `artifacts/godot/land-cliff-baseline-20261118/`.

Evidence SHA-256: central before `1f7db627882bcb840df4fed979d8ec886fe47bd26a291739a119a0a50d526a99`, central after `c147cc3795bdb5dbc919e426feed4116d4ab9116f175a544b363548f27787e40`, coast before `6f104699c39d4bb8e8d513f65a862250647827638d7ddb2b1078764239811752`, coast after `2b3f2faa09ee3248b855fbc741fd2bbce6869bdc93e3e8949b24bcb3f03b25ac`.

Integration next: inspect both A/B pairs at original pixel size, run combined Godot/world/web checks and assess actual device frame pacing before staging. If accepted, update `docs/agent-handoff.md` and clean this worktree/branch after merge.
