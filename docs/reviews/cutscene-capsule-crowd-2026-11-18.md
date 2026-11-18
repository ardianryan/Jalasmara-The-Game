# Phase 1 capsule-pitch crowd scale and 16-scene review

Status: **local candidate** on `work/cutscene-scale-pass-20261118`, based on `main` `6825196`. No push, merge, CI, Web export, or staging activation is claimed here.

## Result

In scene 0.2, five named adults receiving Raka's capsules occupied a compressed strip at the far-left pier. Their source sprites were drawn at `1.30` stage scale, with only `0.057` viewport width between feet. At the actual 667×375 game size, they read as one small, overlapping crowd beside a much larger Raka. This pass draws the same approved sprites at `1.68` scale on five pier marks separated by `0.080` viewport width. The feet remain on the pier, each body is distinguishable, and neither the title nor dialogue is covered. The capsule hand accents and Raka/ship remain unchanged.

Same-base native Godot A/B at the settled motion point:

| Viewport | Before | After |
| --- | --- | --- |
| 667×375 | [Before](../visual/cutscene-capsule-crowd-20261118/before-667x375.webp) (`d4f717eb`) | [After](../visual/cutscene-capsule-crowd-20261118/after-667x375.webp) (`7d7067c6`) |
| 844×390 | [Before](../visual/cutscene-capsule-crowd-20261118/before-844x390.webp) (`46004298`) | [After](../visual/cutscene-capsule-crowd-20261118/after-844x390.webp) (`aa4943cf`) |

Hash prefixes above are SHA-256 of the lossless WebP documentation copies. Source PNG captures are retained only as ignored local artifacts. These are unzoomed original-size renderer frames, not moodboard assets or physical-device recordings.

## Sixteen-scene scale audit

The strict native director fixture captured 100 frames across all 16 numbered screenplay scenes at 667×375 and 844×390. I inspected one representative frame per scene at both sizes and the 0.2 A/B at t0, t1 and t2. This is a composition audit; it cannot establish natural movement or device performance.

| Scene | Foreground reading at game size |
| --- | --- |
| 0.1 harbor lesson | Ki Lurah and dock children separate; harbor remains a deliberately wide view. |
| 0.2 capsule pitch | **Corrected here:** five adults now separate visually while Raka remains the focal speaker. |
| 0.3 Griya arrival | Nala and Beno are full-body on boat/dock, clear of dialogue. |
| 0.4 net inheritance | Nala, Wira and Beno are legible in the Kedai. |
| 1.1 first dive | Nala reads against the open sea; motion timing still needs moving review. |
| 1.2 first service | Ranto's cut-in and Wira's stage figure read at size. |
| 2.1 garden crisis | Darmi, guards, children and foreground Lurah remain distinct in their respective beats. |
| 2.2 Saras visit | Saras has a readable full-body stage mark. |
| 3.1 cave warning | Pipe dominates the scene; Saras speaks through the radio portrait. |
| 3.2 Balai quake | Lurah reads in front, council figures remain a smaller depth row. |
| 4.1 boss reveal | Dark reveal emphasizes Mina's eyes; Nala's speaker portrait carries the dialogue. |
| 4.2 phase change | Mina and pipe joint remain the focus. |
| 4.3 purification | Mina dominates; Nala remains smaller by design in this boss-scale shot. |
| 4.4 village return | Dock children/adults read as separate silhouettes after the earlier staging pass. |
| 4.5 Raka confrontation | Raka, Lurah and the foreground witness pair read; back-row adults stay smaller. |
| 4.6 epilogue | Saras, Bagas and the UV-lit map remain legible; fine handoff animation remains limited. |

## Verification and provenance

- Godot `4.7.2.stable.official.ed1daf0bf`, Compatibility renderer. A cold worktree import first logged missing font import data; a second editor import completed without `ERROR:` or parse errors.
- Filtered native `phase-one-hero-staging.gd` A/B: candidate **132 focal size/layout checks, 128 captures, exit 0**, no `SCRIPT ERROR`, `ERROR:`, or parse error. The fixture now guards the larger opaque actor height and minimum pier-mark separation.
- Full native `phase-one-director-capture.gd` with strict composition: **100 frames, 12 sequences, 16 numbered scenes, two resolutions, exit 0**, no `SCRIPT ERROR`, `ERROR:`, or parse error.
- Code changes are limited to `CinematicActionLayer.gd` and the existing focused staging fixture. Source art is the project-owned NPC-facing atlas and existing Phase 1 painted harbor; no new raster, external generator output, third-party dependency, dialogue or gameplay rule was introduced. `cwebp` was used only for lossless proof copies.

The improved crowd does not complete full moodboard parity. Painted backgrounds and sprite actors still differ in detail and depth, and the 16-scene motion/camera review on Windows and Samsung S23 remains open. The integrator owns combined validation, CI and release decisions.
