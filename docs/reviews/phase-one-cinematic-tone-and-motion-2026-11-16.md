# Phase 1 cinematic tone and motion — 16 November 2026

This source candidate refines the existing Godot cutscene frame without changing server progression, dialogue, rewards, boss resonances, or assets. It is based on `main` `2b38b5de355d96d75af3549a15fc5df2a0571f68` and is limited to `CutsceneFrame.gd` plus one focused transition test.

## Changes

- The cutscene shade now starts transparent before the first shot and starts each newly opened sequence at its authored color. The default white `ColorRect` no longer fades over the opening harbor. Between beats, the shade approaches the next warm/plum/teal/deep grade using a frame-rate-independent time constant of 0.42 s.
- Prologue pollution motes remain over the polluted harbor shots (0.1–0.2) but stop when the shot moves to Nala's Griya dock and the warm Kedai (0.3–0.4).
- The first purification shot overlays the corrupted Gajah Mina atlas with the already approved healed atlas for a 1.2 s crossfade, synchronized by atlas cell. The art itself is unchanged. Reduced-motion mode shows the settled healed sprite immediately.
- In the second purification shot, Gajah Mina swims left over 1.15 s so the painted lower pipe outlet around x≈0.67W is clear before the foreground slab reaches it. This is coordinated with the independent action-layer seal geometry; reduced-motion mode uses the settled left position.
- On the harbor return (4.4), a bounded purple fog field clears from left to right over 2.7 s. It uses 16 small pixel bands, one partial tint rectangle, and one advancing light edge; it does not add a full-screen postprocess or new texture. Reduced-motion mode shows the clear harbor immediately. `CinematicActionLayer.gd` is owned by the separate choreography package and will supply its own foreground light rays, without duplicating this fog.
- The frame forwards each beat's speaker to the action layer when that property exists. This lets the parallel choreography package show the actual first customer instead of assuming Pak Ranto. The property guard keeps the standalone frame test compatible with the earlier action-layer source.

## Audio cue audit

All eight distinct BGM identifiers and all three authored beat SFX identifiers in `PhaseOneCutscenes.gd` match `AudioManager.gd` registrations and existing files. `Main.gd` starts sequence BGM, plays beat SFX, ducks BGM during the victory jingle, and returns to context music after a cutscene. This package adds no sound, so it does not double-trigger the boss roar, first dive splash, Beno's workshop blast, or the jingle. Audibility and mix balance still need runtime listening on the final integrated build.

## Verification and limits

`git diff --check` and the source-only audio registration/file audit passed. `scripts/tests/phase-one-frame-transitions.gd` checks first-frame shade, a gradual pollution-grade change, corrupted-to-healed sprite opacity, the pipe-clearing position, a visible-then-fully-cleared fog overlay, and reduced-motion behavior. Godot 4.7.2 headless and native Metal runs both printed `PHASE ONE FRAME TRANSITIONS PASS`, with no `SCRIPT ERROR` or `ERROR` in the focused runs. The first editor import in this fresh worktree logged transient missing-font/theme errors before importing assets; focused reruns after import were clean.

The native run saved eight 667×375 PNGs in ignored `artifacts/godot/phase-one-tone-motion/`. Human inspection of `healing-start.png` and `healing-settled.png` found the boss still inside the frame and the dialogue above it. `pipe-outlet-clear.png` shows the lower-right painted pipe outlet unobscured by the shifted boss, ready for the separate action-layer slab. `harbor-fog-start.png`, `harbor-fog-mid.png`, and `harbor-fog-clear.png` show a gradual tint sweep over the returned harbor; the existing dialogue frame stays above the fog. Long text uses its existing **Gulir** control at this size. Selected SHA-256 evidence: `pipe-outlet-clear.png` `743c5ce5deaa40adcb9c1ee0229282f605291eaaf69d71df1b02213ac85a724d`; `harbor-fog-mid.png` `9103e3e17963c8e7ad102903c1af2a63d01d8f005db2d7a31803641491d14db8`.

The screenshots are from this isolated source candidate and the earlier action-layer revision. Final integrated captures, browser WebGL, audio listening, and device tests remain with the integrator; this package alone does not establish moodboard parity. No new tool or third-party art was used: only existing Godot 4.7.2 code, project plates/atlases, the built-in cinematic shader, and approved BGM/SFX registrations were inspected. Cinetic did not generate or render these shots.
