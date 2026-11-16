# Phase 1 action choreography — focused candidate, 16 November 2026

This local package fills the largest visual cause-and-effect gaps in the Phase 1 screenplay without changing gameplay state, rewards, combat, audio, or the Web export. It was authored on `work/phase1-final-action-choreography-20261116` from main `2b38b5d`; the commit ID is recorded by the integrator after review. **This is a local source candidate, not a staging release.**

## Changes

- Garden crisis: two corporate staff now use existing human sprites with a coded helmet and company badge. Three clay marbles arc toward them; Ki Lurah enters on the following beat and plants his staff with a ground ring and dust. The action indices follow the final 50-beat script (guard beat 3, Lurah beat 4).
- First service: a close-up shows Pak Ranto only when he is the customer. Bu Darmi receives her own atlas crop; an unknown customer receives a neutral tea-leaf vignette. The speaker from `CutsceneFrame` takes precedence, and the shift-derived first customer remains a fallback for older callers.
- Boss: the phase transition marks the upper pipe mouth at plate source `(730,132)` with a dark bore, cracked rim, falling brace, clear bubbles, and salt shards. The victory stone targets the lower outlet at `(683,244)` in the sealed plate. The red eye and purple bindings become cyan/clear; the eye follows the actual `boss_art` rectangle when Mina moves. The victory tablet moves from Mina's mouth to Nala, and a short contact glint appears when the trunk reaches her helmet. The harbor beat shows two residents dropping purple capsules.
- Kedai visit and ending: Saras stands on the painted floor. Raka and Ki Lurah become foreground actors around 74 and 73 pixels tall at 667×375, with feet on the floor instead of the window rail. Darmi, Mang Ujang, Yu Sari, Ratih, Tedi, Wira, Beno, Gito, and a Ranto bust appear across feast beats rather than crowding a single still; two guards flank Raka. Bagas and the UV lamp align toward the map projection.

All added motion is lightweight `CanvasItem` drawing over approved project art. No third-party art or generative output was introduced. Reused project sources: `npc-facing-v2`, `npc-atlas.png`, `village-residents-v1.png`, `village-expansion-v1/residents.png`, existing player gait sheets, the existing Ranto portrait, and the existing Tamansari/Kedai plates. The named external authoring tool Cinetic was **not used** for this runtime pass.

## Verification and visual evidence

- Godot 4.7.2 editor import: exit 0, no `SCRIPT ERROR`/`ERROR` in output.
- Focused Godot headless script: **54 action samples passed** at 667×375 and 844×390. This includes non-Ranto first service, beat mapping, backdrop selection, pipe coordinates, eye position after a boss shift, and reduced-motion settling.
- Native Metal captures: focused garden, feast, first service, pipe break, and seal cases passed. The three curated candidate stills are [Bu Darmi's correct cut-in](../visual/phase-one-final-action-20261116/first-service-darmi-667x375.png), [the garden confrontation](../visual/phase-one-final-action-20261116/garden-guards-667x375.png), and [the Kedai confrontation](../visual/phase-one-final-action-20261116/feast-confrontation-844x390.png). These are original game renders, not reference moodboard assets.
- Commands: `Godot --headless --path client-godot --editor --quit`; `Godot --headless --path client-godot --script ../scripts/tests/phase-one-final-action-choreography.gd`; `CINEMATIC_CAPTURE=1 CINEMATIC_CASE_FILTER=epilogue:1 Godot --path client-godot --script ../scripts/tests/phase-one-final-action-choreography.gd`. `git diff --check` passed.

Curated PNG SHA-256: feast `c6fa3e506b752dbd69e464d98e108386bbe6d7dd5e7404bfa379ab0f3760bc5f`; Darmi `dfa79aa3b8225e2307f480e4489e31cd45b0e0f921584803ac8fb13fe7ea2751`; garden `21eaab932735a9294d409278b205c843a7a44764944c8dac807f56a402e2d311`.

The action worktree did not include the concurrent `CutsceneFrame` approach/crossfade/surface sweep or dialogue portrait fallback. Consequently, the action-only victory still can show Mina occluding the lower outlet. The integrator must inspect the combined 667×375 and 844×390 boss phase-two/victory sequence, the updated feast portrait, and the full browser journey before accepting or releasing. The capsule drop and trunk contact have headless coverage but still need combined temporal visual review. No physical Windows/Samsung performance result is claimed here.

The native source screenshots are local test artifacts; no PCK or image was produced. The integrator owns the final merge, gallery curation, full checks, handoff, and staging decision.
