# Phase 1 shot transition candidate — 16 November 2026

## Scope and source state

Branch `work/phase1-shot-transitions-20261116` was cut from `007db14396c281c0a23dab1a793b4716467ac96d` in a separate worktree. This candidate changes only `CutsceneFrame.gd` and adds a focused Godot regression test. It is not merged, exported, or active on staging at the time of this report.

Before this change, `present()` replaced the backdrop texture immediately whenever a sequence moved to another painted location. The new frame keeps the outgoing 960×540 project painting over the incoming shot for 0.38 seconds, fading it out with a smoothstep curve. The old plate sits above the incoming action but below the title and skip control; the separate dialogue overlay remains readable. Both plates use nearest-neighbor filtering. A small, eased pan adjusts the framing of selected prologue, dive, boss, and epilogue shots, clamped inside the source image so no unpainted edge appears at the 667×375 and 844×390 landscape targets. The existing living-plate shader and action layer remain single instances; no shader, texture, dependency, gameplay rule, or asset was added.

Reduced-motion mode skips the blend and pan, and switching it on mid-transition releases the outgoing texture immediately. An unchanged backdrop does not restart a blend. The transition keeps two already loaded paintings resident for at most 0.38 seconds; mobile WebGL frame pacing must still be assessed after integration.

## Verification and limits

`git diff --check` passes. The new `scripts/tests/phase-one-backdrop-transition.gd` asserts the baseline first-shot behavior, distinct-versus-same backdrop behavior, midpoint opacity, completion and old-texture release, shot pan progress, image coverage at both landscape sizes, nearest filtering, UI layer order, and reduced-motion cancellation. The test would fail against the pre-change source because the outgoing plate and progress contract did not exist.

Godot import, headless regression, native visual review, browser WebGL and physical Windows/Samsung S23 checks are pending the serialized renderer slot and integration into `main`. The integrator owns registration in `scripts/verify-living-world.mjs`, combined tests, gallery evidence, final handoff, branch retirement, CI and staging. No screenshot or performance result is claimed here.

## Tool and asset provenance

This patch uses existing Godot 4.7.2 Control and TextureRect facilities. The source paintings are already documented in `docs/assets/cinematic-backgrounds-v2.md` and `docs/assets/tamansari-phase-plates.md`; no upstream visual tool, generated character sheet or new third-party asset was used. Cinetic remains a separate offline authoring reference and did not produce this transition.
