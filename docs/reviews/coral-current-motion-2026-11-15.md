# Rooted coral sway — source candidate

Date: 15 November 2026. Branch: `work/coral-current-motion-20261115`, based on `7476373`. This report describes an isolated source candidate; it is **not yet merged or released on staging**.

## Change and reason

The hybrid ocean's existing coral rotation used the Y axis around a pivot placed behind the sprite in depth. At the fixed 3/4 camera it produced almost no legible tip movement. The coral now uses its original atlas and placement, with the pivot at the image's opaque bottom edge in the XY plane. A code-driven 10 Hz current phase rotates the full cluster around the camera-normal Z axis, capped at 0.048 radians. The sampled world current supplies the directional bias; the player's reduced-motion setting holds angle zero. The coral card no longer billboards, so the root rotation remains visible under the fixed ocean camera. No atlas pixels, placement count, fish, targets, collisions, oxygen, or rewards change.

The original `coral-clusters.png` source was inspected: each of its three cells reaches the bottom of its 634 px crop, confirming that the new anchor is at the visible base. The new helper is project-authored GDScript; no external library, generated art, or new runtime texture was added. Existing project-art license and provenance remain in effect.

## Evidence and validation

- Godot 4.7.2 Compatibility: second editor import had no `ERROR` or `SCRIPT ERROR`. The first fresh-worktree import emitted transient missing font-cache messages before reimport; it was not counted as clean. The focused `coral-current-motion.gd` test passed after its SceneTree autoload lookup was corrected. It checks the angle bound and phase, directional current, root/plant depth, opaque alpha discard, disabled billboard, and reduced motion. It is registered in the world-check runner.
- Native Apple M2 render fixture passed at 667×375 and 844×390: six full-scene frames, 43 original coral pivots, fixture oxygen 77 and coins 700 unchanged. The invalid dummy-renderer headless attempt was stopped and discarded; the accepted frames used `--rendering-method gl_compatibility` without `--headless`.
- At 667×375, sway phase A to B changed 2,124 of 9,450 pixels by more than 8 RGB levels in the visible coral region, while equally sized open-water and player controls changed zero. The maximum measured root-to-tip horizontal excursion in the fixture was about 3.95 world pixels for either sampled phase. The still and motion frames preserve the same anchored base and alpha silhouette when inspected at native size.

Native evidence: [still](../visual/coral-current-still-667x375-20261115.png) (`84e921d3c9d0469fdcfe09e7d8da346309e95c3862cb923fa0514e1f45d592a6`), [phase A](../visual/coral-current-sway-a-667x375-20261115.png) (`e8f2da58a751f0eb81dd6a54a18f3f82b6c80e4fc6a1995d0f21e5978e60359c`), and [phase B](../visual/coral-current-sway-b-667x375-20261115.png) (`5baf460243edbfd151080190fa13fc192e51ca0436f997da6f41618450af2299`). Full-resolution 844×390 frames, logs and measured JSON are local under `artifacts/godot/coral-current-motion/` in this worktree, not in the release package.

The test establishes a bounded, visible code-driven sway, not full moodboard parity or natural motion on a physical Samsung S23/Windows GPU. Before staging, the integrator should review a moving browser scene, confirm no card-like rocking at typical current, run the combined Godot/world/typecheck/API/build suite, and compare mobile frame pacing. If the motion looks rigid at speed, keep the previous placement and reject this candidate rather than increasing amplitude blindly.
