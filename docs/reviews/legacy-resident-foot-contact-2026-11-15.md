# Legacy resident foot-contact correction — 15 November 2026

## Scope and result

The owner asked whether every resident moves dynamically, avoids backward-looking travel and has intact legs, then requested a correction. This package fixes a concrete production defect in the **Bu Darmi** and **Yu Sari** cutout rigs: their previous knees were estimated from hip/ankle midpoints, each thigh/calf sprite was scaled to fit that estimate, and the whole rig could be mirrored for a side view. Their original source-art parts now use the same real-distance, world-ground foot-contact solver already proven for Mang Ujang. Stride is limited to 82% of each character's shortest measured leg reach. The two source-pixel bone lengths remain fixed, feet alternate on travel and stop on pause, and the body transform remains anatomically positive while turning. When travelling west, only the original head and torso pixels turn horizontally; the physical legs and shoes are not reflected. Ujang retains his previous stride and turn threshold.

This is **not** acceptance of every resident's direction art. Seven older portrait residents still use front three-quarter five-frame strips; their westward mirroring does not supply an authored back view. The director and five children likewise retain one authored upper-body view. A programmatic rear-head palette experiment was inspected as a contact sheet, looked like a rectangular/dithered patch and was discarded before integration. No new character art, generated image or third-party runtime dependency was shipped. Work on the seven alternate views must use reviewed pixel-authored side/rear frames and native playback, not a blind palette transform.

## Source and verification

Candidate branch: `work/npc-facing-foot-20261115`, forked from `main` at `9b062d5`. At this report checkpoint it is local source only: **not merged, pushed or on staging**. The change is in `client-godot/scripts/NpcBodyRig3D.gd`; the world runner now includes `scripts/tests/legacy-resident-contact.gd`. The route fixture covers both residents' real work↔home commutes in normal and reduced-motion settings. `village-routine06.gd` also exercises four flat-ground direction turns for all three cutout rigs. The native `npc-body-render.gd` saves eight actual-distance walking frames per pilot and checks contact reach and fixed lengths. The optional `npc-body-sequence.gd` now saves nine selected frames by default and supports `NPC_SEQUENCE_ONLY`/`NPC_SEQUENCE_FULL=1` so a review does not generate hundreds of redundant PNGs.

Verification on Godot 4.7.2 Compatibility (Apple M2) and the local pinned Node toolchain:

| Check | Result and limit |
| --- | --- |
| `npm run check:world` | **77/77 passed**, including 37,418 route steps for 13 residents, 4,172 actual-commute contact samples for Darmi/Sari and 1,242 Ujang regression steps. Logs contain no `SCRIPT ERROR` or `ERROR:`. This verifies geometry and scripted motion, not visual quality on every device. |
| `npm run typecheck` | Passed. |
| `npm test` | **123/123 passed** using isolated temporary MongoDB replica set at 127.0.0.1:27019 and Redis at 127.0.0.1:6381. Both services were stopped; their owned data directory was removed. No owner account or persistent database was used. |
| Native `npc-body-render.gd` | Passed for Ujang, Darmi and Sari. Darmi and Sari changed 1,485 and 1,583 body pixels between work poses; eight walking frames and a west-facing still per person were visually inspected. The Sari dress hides much of the knee/stride in this view. This is an isolated native rig render, not a browser or physical-device capture. |
| Sparse native `npc-body-sequence.gd` | Passed for Yu Sari with `NPC_SEQUENCE_ONLY='Yu Sari'`. This checks the new capture selector and script path; its camera framing is not accepted as a resident visual review. |
| `npm run build` | Passed after the final west-facing change. Local Web PCK SHA-256 `a5f35650ec7cac6e2c4169a3d728023606f466274a9fd47a4b2d6b962dc0c77c`, 72,730,500 bytes. This is a candidate export, not the GitHub CI delivery bundle. |

![Native isolated Bu Darmi and Yu Sari eight-frame walk contact sheet.](../visual/legacy-resident-walk-20261115.png)

![Native isolated west-facing Bu Darmi and Yu Sari, with unreflected feet.](../visual/legacy-resident-west-20261115.png)

The original 1,536×384 contact sheet was assembled from the Godot native transparent-stage frame captures, with a documentation-only dark background. PNG SHA-256 `a4b0c2fdba62f1941d5b080f266131789919b56969efc96fb6e3bb0a678be18d`; the 384×192 west pair is `bf34f695d158993ded32fa68c844f53653c8758d5f560aefae61bfb5629bddf0`. Neither is a game texture. The input cutouts remain project-owned `npc-rigs/{darmi,sari}.png` derived from the existing `npc-atlas.png`; the generator and rig remain project code. Pillow was used only to assemble these documentation images. PixelHand, SpookyGhost, Konado and Sprite AI were not used for this package. Their earlier tool-review/license status is unchanged.

The first `check:world` attempt lacked `GODOT_BIN`; a second attempt timed out while the new worktree's Godot import cache was empty. A one-time editor import completed, then the full 77-check run passed. One new test initially used unsupported `Array.reversed()` and was corrected to `reverse()` before the passing run. The optional full-frame native sequence was stopped after an excessive 146 MiB of raw captures because its camera framed other actors on some routes; it is **not** counted as visual proof. A first sparse-sequence invocation used a `res://` path although the fixture is outside the Godot project; the corrected absolute-path invocation passed. The selected isolated contact sheet above is the valid render evidence.

## Delivery and remaining work

This source must pass GitHub Actions on its final commit before any staging deployment. If released, use the exact CI source/PCK manifest, record backup/restore, retain one verified rollback image, perform public startup and resident-route smoke, and request owner visual review on Windows/Samsung S23. No FPS or smoothness claim is made for those devices.

Next in order: (1) review the native Darmi/Sari gait in normal gameplay and at short landscape size; (2) author side and rear views for the seven portrait residents, preserving each silhouette/props and planting feet through turns; (3) review the director/five children's one-view rigs; (4) test public staging and physical devices after CI. The seven-person direction-art task belongs to `NpcSimpleSteps.gd`, its source atlas/generator and `LandActors3D.gd`, with one owner for that shared renderer. Do not treat the current single-view strips as complete four- or eight-direction art.

The worktree's raw `artifacts/godot/npc-body-rig/` capture directory (149,444 KiB) was removed after curating the image above. Free disk grew from 15,334,296 to 15,500,368 KiB across that cleanup. The temporary isolated database directory used 6,588 KiB and was removed after verified service shutdown. Active staging, its rollback image, VPS data and `.env` were untouched.
