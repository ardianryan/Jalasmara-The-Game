# Reef 12 shared rock volume candidate — 18 November 2026

Status: **local candidate for integrator review, not merged or staged**. This branch started at `e6c9898` and changes the single shared `WORLD.terrainContours[12]` used by server collision and Godot rendering. The previous broad 1844×160 rectangle produced a ruler-straight, almost black face beneath the waste valve. Earlier separate crests, strips, tint changes and steep shared slopes failed original-size visual review; their reports remain in `docs/reviews/reef12-connected-crest-diagnostic-2026-11-18.md`.

The candidate authors a tapered, gently undulating 26-point shoulder within the original terrain rectangle. The existing `ReefRelief12` mesh and its mounted coral roots use the project's porous limestone atlas column throughout the same connected rock volume. It adds no detached overlay, collider expansion, boss rule, asset, dependency or extra runtime mesh. Its left edge slopes into the adjoining reef; its lower edge undulates into the water. Both server swim blocking and visual geometry read the same outline.

At original game size, compare the [667×375 baseline](../visual/ocean-reef12-diagnostic-20261118/baseline-deep-667x375.png) with the [667×375 candidate](../visual/reef12-volume-20261118/deep-667x375.png), and the [844×390 baseline](../visual/reef-contour-parity-20261118/baseline-844x390.png) with the [844×390 candidate](../visual/reef12-volume-20261118/deep-844x390.png). The candidate removes the black slab and gives the coral a readable continuous rock face. The long ledge is still present because it is a world obstacle; the remaining broad silhouette and moving-browser appearance need integrator and owner review. These stills do not prove full moodboard parity or Samsung S23/Windows performance.

Verification on this isolated worktree:

- `npm run typecheck` passed after linking the main worktree's installed dependencies temporarily; the link was removed and is not tracked.
- `apps/api/test/reef-sanctuary-contour.test.ts` passed: the contour has no crossing edges, a 40-unit server-blocking grid from the cave approach reaches all six resonance targets, and the valve remains outside the solid.
- Godot 4.7.2 Compatibility `ocean-platform06.gd` and `ocean-pipe-grounding.gd` passed. The pipe base remains 20.5 world units above its shelf and the hazard markers are unchanged.
- Native `coral-rock-render.gd` passed shallow/deep at 667×375 and 844×390, preserving oxygen 77, coins 700, 43 coral pivots and 39 mounts. The final native pass took about 14 seconds on Apple M2 and logged no `SCRIPT ERROR` or `ERROR:`. Curated frame SHA-256: 667 `738c7d74e14635a8657c45967e89be4af6512e16885304f866b1914aac6f2f2c`; 844 `7f56d7538828ce84e5e68bfe506f8cddb745f4e983508333bab86f381398e544`.

One intermediate underside trial increased the contour to 30 points and stalled before its deep frame for over 75 seconds. It was terminated and replaced with the final 26-point topology; no stalled variant is in this commit. The first editor import emitted transient missing font-cache messages; the second import completed without errors before the focused/native checks. Raw local logs and captures are under `.runtime/reef12-*` and `artifacts/godot/reef12-volume-final26/` and remain ignored.

An isolated direct `tsc` invocation without that dependency link failed on missing packages and Node types, then the final `npm run typecheck` passed with the link restored temporarily. The direct invocation was an environment setup failure, not a source diagnostic.

Tools used: project-authored Godot mesh and atlas, Node/TypeScript source tests, Godot 4.7.2 Compatibility native/headless rendering, Git worktree. No external source code or moodboard pixels were copied. The atlas retains its existing project provenance and license. If accepted, the integrator should run the combined world/API/build checks and a source/PCK-pinned browser pass, then review moving gameplay before staging.
