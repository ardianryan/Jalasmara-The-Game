# Phase 1 support-character staging, 18 November 2026

Status: **local source candidate** on `work/cutscene-scale-parity-20261118`, based on `9b7ce4791ddd1f308e3bd803c12933c58120a918`. It has not been merged, checked by exact-SHA CI, or activated on staging. This pass addresses three visibly miniature wide-shot compositions; it does not establish full moodboard parity.

## Result at game size

- In the prologue capsule refusal, five children now stand on distinct marks across a wider, continuous foreground pier. Their existing atlas images are drawn at about 65–95 physical pixels high, with Ki Lurah and his staff grounded to the same deck. The old 667×375 shot clustered them into a small group at far left.
- During Raka's Balai confession, Ki Lurah has a legible body at the left stage mark rather than the old miniature figure. Raka, the map and the dialogue remain visible.
- In the Kedai confrontation and Gito celebration, the six background residents are larger and more evenly spaced. They remain behind the focal Raka/Lurah/Gito action, above the dialogue panel and on the painted floor.

All three changes are localized in `CinematicActionLayer.gd`. Story text, character atlases, portrait scale, gameplay, server authority, and the title/menu layout were unchanged. The source assets are existing project-owned NPC, child and resident atlases. No generated or moodboard image entered the game.

| Beat | Original-size proof |
| --- | --- |
| Capsule refusal | [667×375](../visual/cutscene-support-stage-20261118/refusal-667x375.webp), [844×390](../visual/cutscene-support-stage-20261118/refusal-844x390.webp) |
| Balai confession | [667×375](../visual/cutscene-support-stage-20261118/balai-667x375.webp) |
| Kedai confrontation | [667×375](../visual/cutscene-support-stage-20261118/feast-667x375.webp) |

Original-size baselines are the earlier local native files `artifacts/godot/phase-one-director-qa/{prologue-05,earthquake-02,epilogue-01,epilogue-03}-{667x375,844x390}.png`. All eight new native captures, including the uncurated Balai/feast/celebration 844×390 frames, are under `artifacts/godot/phase-one-support-stage-parity/` in the worktree. Curated lossless WebP hashes: Balai `e6ade55b19722d9055ae705d77ce864b814df6858f8c81b1eb50c948c42674df`, feast `34ccf8f9593ddcc94d74fa0a078ef7f330cca32ce3d5fdfebc739415e335d13e`, refusal 667 `9620eece07ec235e2c95b74241b1374e3a518cdc70c0be1411afb09d1ea7e5cc`, refusal 844 `4da42c8db683abef0c5998684b964341c5b84893d2b578d9693fb7ab85c5f0e3`.

## Verification and limits

Godot `4.7.2.stable.official.ed1daf0bf` on Apple M2, Compatibility renderer: the focused `phase-one-support-stage-parity.gd` passed **48 checks** in headless mode and **48 checks / 8 captures** in native mode at 667×375 and 844×390. The final native run emitted no `SCRIPT ERROR` or `ERROR:`. `git diff --check` passed. The first cold editor import temporarily logged missing font import data, then completed; the subsequent focused runs were clean. The first capture fixture waited indefinitely on `frame_post_draw`; switching the fixture to the already-used `RenderingServer.force_draw(false)` pattern resolved it, and the final native run exited normally.

This proves source-controlled placement and native stills. It does not prove moving browser/device frame pacing, all Phase 1 beats, or full moodboard parity. The host/renderer journey and combined world suite must run after integration. The new fixture still needs registration in `scripts/verify-living-world.mjs` by the integrator. The remaining wide-shot palette and sprite/background integration should be judged in a continuous 667×375/844×390 playback before release acceptance.
