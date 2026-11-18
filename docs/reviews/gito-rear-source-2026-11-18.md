# Gito rear view source-pixel package — 18 November 2026

Status: bounded visual candidate **accepted for integrator review** on `work/gito-bagas-direction-source-audit-20261118`, based on main `9aa5a0c`. This package has **not** been merged, exported or staged. It addresses the most conspicuous backward-walking case in the [existing Gito/Bagas directional audit](resident-kids-directional-audit-2026-11-18.md). Bagas and Gito's east, west and south views are unchanged; complete eight-direction art remains open.

Gito previously showed his front face and vest while moving north. This candidate draws a 96×128 rear head and vest with project-owned source colors, then authors two small heel and back-strap sprites. `ResidentArtRig3D.gd` selects them **only** when Gito's logical direction is north. Existing leg pieces, path, planted-foot solver, source joint positions and prop remain. The two rear foot quads use the existing foot transforms; visual sole centroids differ from the original by at most 0.5 source pixel. Lookout/work pose still takes precedence.

Source: [`residents.png`](../../assets/source-2d/village-expansion-v1/cutouts/residents.png), SHA-256 `6dc5fbb107327c97205660817cf245661bea838d50be606735fe2c6a247d413e`. Python 3/Pillow 11.3.0 source-grid drawing is reproducible via `python3 tools/npc-rig/author_gito_rear_candidate.py`; source studies and provenance are in `assets/source-2d/village-expansion-v1/directional/`. All pixels are original project art or authored on that grid. No moodboard, upstream sprite, Sprite AI output or third-party art was copied. Licensing follows project `LICENSE` section 2.

| Evidence | Link | What it shows |
| --- | --- | --- |
| Source 1× front/rear | [PNG](../visual/gito-rear-source-20261118/front-rear-1x.png) | Original source-grid comparison, including revised heels |
| Source 4× nearest | [PNG](../visual/gito-rear-source-20261118/front-rear-4x.png) | Pixel-cluster inspection only |
| Native 667×375 | [lossless contact](../visual/gito-rear-source-20261118/gito-rear-667-contact.webp) | North stride early/late, north stop, front-facing return idle |
| Native 844×390 | [lossless contact](../visual/gito-rear-source-20261118/gito-rear-844-contact.webp) | Same four states at a wider viewport |

Native images are **1:1 crops of original-size Godot framebuffers**, not scaled renders. Full frames and `results.json` are ignored local evidence under `.runtime/gito-rear-heels-{667,844}/`. The contact sheets show a rear-facing head, vest and heels at game size; two stride phases differ and the stopped rear pose does not flip prematurely. This is a Mac native visual review, not Windows/Samsung S23 or WebGL validation. The 4× sheet helps judge pixels but must not be mistaken for in-game scale.

Verification on this branch:

- `python3 tools/npc-rig/test_gito_rear_candidate.py`: PASS; deterministic output, 96×128 grid, upper-only mask, unchanged lower-body reference and heel sole anchors.
- `python3 tools/npc-rig/test_resident_parts.py`: 2/2 PASS; 84 original parts still reconstruct their source exactly.
- Godot 4.7.2 Compatibility clean editor import: PASS, no `ERROR`/`SCRIPT ERROR` in `/tmp/jalasmara-gito-rear-heels-import-20261118.log`. An earlier first import emitted missing font import errors and exit 139; the second import was clean before both native captures.
- `playable-resident-pixel-audit.gd` native at 667×375 and 844×390: PASS, eight travel headings, north walk and stop, 6.207 max pelvis drop, no dual-loss of ground contact. Logs: `/tmp/jalasmara-gito-rear-heels-native{667,844}-20261118.log`.
- `resident-art-integration.gd` and `resident-art-rig.gd` headless: PASS, no errors; Gito now reports two authored views while other residents remain one-view.
- `git diff --check`: PASS.

The narrow result is a credible **north/rear Gito** view, not eight-direction or whole-village parity. The next art pass must draw Gito's side/diagonal views and Bagas's side/rear head, torso and feet at the same source quality, then repeat moving turn-continuity review. The integrator must review this branch, cherry-pick only if accepted, run combined checks, and update the active handoff/release status. No staging claim follows from these native images.
