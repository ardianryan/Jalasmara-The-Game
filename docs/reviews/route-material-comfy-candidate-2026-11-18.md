# Packed-earth material candidate — 18 November 2026

The land path in the current native view is a bright, nearly uniform orange strip. This bounded source candidate changes only `LandMaterials.gd`: the `dirt` material gets a warmer, less saturated packed-earth base, smooth broad color compression using noise already computed by the shader, and sparse small grit. The existing 32×32 project dirt texture remains the source of pixel detail. No route polygon, floor, collision, pathfinding, stair, lighting, or server map is changed.

Source branch: `work/route-material-comfy-20261118`, based on `659dfdf`. The candidate is local and has not been merged, pushed, or staged. The first trial used hard 42-unit cells; native A/B exposed a conspicuous checkerboard, so that code was discarded before this candidate. The revision reuses the existing smooth `patch` value; only two extra sparse-grit hash samples are added to the dirt fragment path. No external tool, third-party art, or moodboard image enters the asset/runtime.

Godot 4.7.2 Compatibility rendered fresh baseline and revised source through `scripts/tests/terrain-facets-render.gd` at 844×390 and 667×375 for lower coast, central stairs and forest bank: 6 frames per variant, all without `SCRIPT ERROR`/`ERROR`. `results.json` reports a maximum player foot error of 0.000061 px for both variants. `git diff --check` passed. The revised six-frame process took 9.25 seconds wall clock, which is **not** a GPU frame-time or Windows/Samsung S23 performance measurement. Full render results/logs remain ignored under `artifacts/godot/route-material-{baseline,revised}-20261118/` and `.runtime/route-material-*.log` in this worktree.

Original-size visual comparisons:

| Scene | Baseline | Candidate | Review |
| --- | --- | --- | --- |
| Lower coast, 667×375 | [WebP](../visual/route-material-comfy-20261118/hub-lower-coast-base-667x375.webp) | [WebP](../visual/route-material-comfy-20261118/hub-lower-coast-candidate-667x375.webp) | Quieter earth and visible grit; dock branch is still thin/angular. |
| Central stairs, 844×390 | [WebP](../visual/route-material-comfy-20261118/hub-central-stairs-base-844x390.webp) | [WebP](../visual/route-material-comfy-20261118/hub-central-stairs-candidate-844x390.webp) | Less fluorescent path; wide V-shaped junction remains. |
| Forest bank, 667×375 | [WebP](../visual/route-material-comfy-20261118/forest-bank-base-667x375.webp) | [WebP](../visual/route-material-comfy-20261118/forest-bank-candidate-667x375.webp) | Softer soil against grass; corridor width remains broad. |

The candidate is an incremental material improvement, **not full moodboard parity**. The remaining blocker is the authored shape and transition of the route around the house, stairs and dock. A later area-composition pass must preserve authoritative walking surfaces and prove natural path/grass/stone joins at original size. A WebGL frame-time sample and physical Windows/S23 review are still required before a full performance claim. All curated lossless WebP captures are original Godot game renders used as documentation, not distributed or copied reference art.
