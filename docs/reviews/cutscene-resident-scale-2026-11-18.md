# Phase 1 cutscene resident scale: harbor lesson and Balai council

Status: **local candidate**, not merged or released. Worktree `work/world-pixel-clarity-20261118`, based on `e6c9898`; this package follows the rejected land-atlas trial report in commit `3b37079`. The gameplay and staging builds have not been changed by this worktree.

## Problem and change

At the actual 667×375 viewport, the three children in the prologue harbor lesson and the background council in the Balai earthquake scene were small relative to the detailed painted plates. The baseline [harbor lesson](../visual/cutscene-lurah-lesson-667x375-20261118.webp) and [Balai scene](../visual/cutscene-balai-quake-667x375-20261118.webp) show the problem. The 844×390 [Balai baseline](../visual/cutscene-balai-quake-844x390-20261118.webp) has the same imbalance.

`CinematicActionLayer.gd` now draws the harbor children at 2.05 rather than 1.75, moves their grounded marks to 7%, 18%, and 29% of the frame, and moves Ki Lurah and his compass slightly right to leave clear silhouettes. The Balai council support scale rises from 1.65 to 2.10, with the background Lurah at 2.50 and beat-one council actors at 2.25. Feet still share the original deck/floor heights. No new texture, generated sprite, shader pass, output-resolution change, or third-party material was added.

The source-size guard in `phase-one-hero-staging.gd` now requires the harbor child's visible ink to reach at least 78 pixels at 667×375 and the council support actors to reach at least 72 pixels. It also checks the first child's frame margin, adjacent silhouette clearance, and clearance from Ki Lurah. On 667×375 the source bounds leave 11.8 pixels at the left edge, 3.7 pixels between child drawing rectangles, and 7.1 pixels before Ki Lurah's rectangle; 844×390 leaves more space. Native inspection confirms their actual ink silhouettes are distinct.

## Native evidence and verification

| Shot | 667×375 candidate | 844×390 candidate |
| --- | --- | --- |
| Prologue harbor lesson | [image](../visual/cutscene-resident-scale-20261118/prologue-01-t2-667x375.webp) | [image](../visual/cutscene-resident-scale-20261118/prologue-01-t2-844x390.webp) |
| Balai council, beat 1 | [image](../visual/cutscene-resident-scale-20261118/earthquake-01-t2-667x375.webp) | [image](../visual/cutscene-resident-scale-20261118/earthquake-01-t2-844x390.webp) |
| Balai council, Saras beat | [image](../visual/cutscene-resident-scale-20261118/earthquake-04-saras-t2-667x375.webp) | [image](../visual/cutscene-resident-scale-20261118/earthquake-04-saras-t2-844x390.webp) |

The native Godot 4.7.2 Compatibility fixture `CINEMATIC_CAPTURE=1 Godot --path client-godot --script res://../scripts/tests/phase-one-hero-staging.gd` passed **196 focal size/layout checks** and saved **308 captures**. The log at `/tmp/jalasmara-cutscene-resident-scale-native.log` contains no `SCRIPT ERROR`, `ERROR:`, or parse error. I inspected both sizes and motion samples `t0` and `t2` for these shots. Full bodies remain visible, the title/skip controls and dialogue do not cover the actors, and the painted floor marks remain legible. `git diff --check` passed.

The six curated images are lossless WebP copies of native capture PNGs, encoded with local `cwebp 1.6.0`. Their SHA-256 values in table order, left then right, are:

| Shot | 667×375 SHA-256 | 844×390 SHA-256 |
| --- | --- | --- |
| Prologue harbor lesson | `c0339e6e47a060e6e294cfe025e44fa7035183a1e6d80a62ebb17ee75e4cd558` | `31f7b30e0ba08cc54dff0503abe4e254e868887c4ebb38889f243332f45a93df` |
| Balai council, beat 1 | `a0569a3b6345f4d9740c089a6186bc9968f70a2855d9d0447690ade0059ecca2` | `e6044837c3225505a41f9c61a09a7899e7ca628028746decae052a3ecd19f510` |
| Balai council, Saras beat | `d10711b5ecc6bb89f6cb9da8b4afa59513f4cdd930e31bf71c2f5e5af8fbaaba` | `f40a82d33468f60eb87d19532b9427d3ad8202e0440de7f3cb8ce67160c0d8df` |

Their source is the project's existing cinematic and character art; no moodboard image was imported. Existing asset provenance and licenses remain in force.

## Limits and next step

This is a shot-level scale/composition correction, not proof of full moodboard parity, animation smoothness, browser behavior, or physical-device frame rate. The actor ink still comes from the current atlas, and the detailed background retains its own painterly pixel density. The integrator should independently inspect these six images, cherry-pick the candidate if accepted, run combined checks, and update the active handoff. The renderer slot was released to `route_art_rework` after capture; no push or staging activation was performed.
