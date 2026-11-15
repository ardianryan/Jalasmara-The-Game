# Coastal cliff facet trial, 15 November 2026

This is a local candidate in `work/moodboard-terrain-edges-20261115`, based on `0a94d985445f9e59e44ba6f126b7645f9a1b594d`. It is not merged or released. The owner asked for full cozy pixel-art moodboard parity; this narrow trial addresses the block-like cliff skin only. It does not change authoritative floors, stairs, collision, routes, server state, or wood/dock geometry.

## What the first native comparison rejected

The first iteration replaced per-segment rock tones with world-coordinate tones and laid narrow stone strata on top. Existing `natural-terrain-edges.gd` passed on the actual hub and forest map: eight surfaces, 512 active nodes, 516 excluded segments, 251 supported nodes, and unchanged authoritative world JSON. A second Godot 4.7.2 editor import was clean; the first import emitted transient missing-font import errors while its cache was being built. Native Compatibility rendering produced six actual-world day images at 844×390 and 667×375, with no `SCRIPT ERROR` or `ERROR` in either render log.

Matched baseline and first-candidate images are under the ignored local paths `artifacts/godot/terrain-strata-{baseline,candidate}/`. Compare `hub-central-stairs-844x390.png` and `hub-lower-coast-667x375.png`. The added strata were barely visible; the cliff still read as rectangular stone panels. This candidate was rejected and its stratum mesh was removed. The local images are diagnostic artifacts, not shipped assets or proof of browser/device parity.

## Source diagnosis and accepted bounded candidate

`LandWorld3D._build_surface_geometry()` creates the top walkable mesh from the source polygon before invoking `NaturalTerrainEdges3D`; therefore a cliff helper cannot replace the actual floor silhouette. The existing `CoastlineContour.naturalize()` already modifies only the backing, lower court, and forest-bank visual outlines. `NaturalTerrainEdges3D` draws a narrow cap outside the original floor, then broad sloped stone bands. Its prior per-index material switch painted full 34-unit quads, accounting for much of the apparent rectangular pattern.

The revised candidate keeps the cap bounded by `toe × 0.26` but gives it more coordinate-driven relief and less vertical drop. It groups base stone tone by world position and splits select broad stone quads into two triangular material facets, retaining the existing stone/shade meshes and materials. No new shader, atlas, material draw call, runtime animation, imported pixels, or third-party code is added. `scripts/tests/terrain-facets.gd` checks the exact face area, outward winding, and deterministic bounded lip; `scripts/tests/terrain-facets-render.gd` captures three same-camera locations at both target sizes.

`terrain-facets.gd` passed; the existing actual-world `natural-terrain-edges.gd` passed again with eight surfaces, 512 active nodes, 516 excluded segments, 251 supported nodes, and unchanged source world JSON. The native fixture passed 6/6 with no Godot `SCRIPT ERROR` or `ERROR`. Matched original-size comparisons show a visibly irregular top rim and triangular rock facets in the hub central stair and lower coast scenes. The forest bank is almost unchanged because its exposed drop is shallow. The stair mouth remains clear, Nala remains on one supporting floor, and recorded foot error is at most `0.00006103515625` px. The hub still reports 57 meshes and the same five NaturalTerrain mesh groups before and after. This bounded appearance change is accepted for integrator review, **not full moodboard parity**.

Curated original PNGs from the native fixture (baseline source `0a94d98`, candidate this branch; no PCK/export):

| Camera | Before | Candidate |
| --- | --- | --- |
| Central stairs, 844×390 | [PNG](../visual/terrain-facets-before-stairs-844x390-20261115.png), SHA-256 `4f36323d633b00203efb25318e09465378770a46b007de52e27e8cface29a87d` | [PNG](../visual/terrain-facets-after-stairs-844x390-20261115.png), SHA-256 `da81b968f41cb0a3a2e2cb2f60e281e9dd5278883d4a6f0b84f3caf631727a33` |
| Lower coast, 667×375 | [PNG](../visual/terrain-facets-before-coast-667x375-20261115.png), SHA-256 `07259989afc326096574d892a5a0521f25ae4b2723ad62c806dfebf5ae880e06` | [PNG](../visual/terrain-facets-after-coast-667x375-20261115.png), SHA-256 `7f5a07c0376bc4472681eb30fd8070e0777fd1330b587c1b676db1fad65b1f05` |

The test images are project-generated evidence, not runtime assets and not a license transfer to any kit. The change has not been checked in an actual browser or on Windows/Samsung S23, and no measured device FPS or GPU cost is claimed. If the top line remains too straight in other areas, the next bounded change belongs in the top visual-outline path of `LandWorld3D`/`CoastlineContour`, not an increasingly noisy rock overlay. Such a change needs its own collision/route and native/browser review.

Tools actually used: Git worktree, Godot 4.7.2 Compatibility native renderer and headless test, existing Godot GDScript, source images from this repository. The owner's external moodboard was inspected as a reference only and was not copied. There is no asset provenance or license change because this trial adds no raster, library, or dependency. No CI, web export, browser, physical Windows/S23 run, push, or staging activation is claimed.
