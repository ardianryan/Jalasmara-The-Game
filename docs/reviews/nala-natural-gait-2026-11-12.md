# Nala gait integration checkpoint — 12 November 2026

The owner marked the boss package complete and requested Nala's walking package before the full playthrough or visual polish. The package was built from `main` `04e5c9e32509057b8b521324667fe91b87e4d400` in `work/nala-natural-gait`, committed as `098f16e0c234186c1e349c9e29b10f91ce57d29f`, then fast-forwarded into `main`. [GitHub Actions 43255908134](https://github.com/ardianryan/Jalasmara-The-Game/actions/runs/43255908134) passed and published `verification-reports` and `verified-delivery`; GitHub, Gitea and GitLab all received the same source SHA. This is merged source, not a staging release or physical-device acceptance.

## Changes

- The eight-direction atlas now accepts traveled distance from the 3D land renderer, rather than commanded speed times elapsed time. Both land controllers feed it for the four appearances in daily and explorer outfits. The twelve-combination unit check includes diving to guard the shared atlas interface; underwater movement still uses its existing cadence. Idle, stop and turn continue to use the existing pose logic.
- The opt-in `male_nusantara` physical lower-body rig now selects its torso frame and separate equipment phase from the planted-foot swing. It no longer lets the torso run a separate logical cadence. A precise connector/surface inverse is used only when the existing local foot-support search fails at a stair or gangway seam.
- The production controller fixture now exercises the real daily and explorer controller paths. Its explorer fixture overrides the **test-only** capacity gate; the release flags in `Main.gd` and `Forest.gd` remain OFF. A new 12-combination atlas-distance check is included in the world suite.

## Verification

| Check | Result | Limit |
| --- | --- | --- |
| Production gait, flat ground | 3,104 samples / 32 daily and explorer cases PASS | Diagnostic; not default-release acceptance |
| Physical terrain, steps and gangway | 793 contact samples / 16 cases PASS | No Windows/S23 GPU or input test |
| Native Godot 4.7.2 Compatibility, Apple M2 Metal | One rightward contact sequence and one leftward occlusion case, 97 samples each, PASS | Native images are stills; the leftward case is partly behind buildings |
| Eight-way source audit | 12 sets / 768 frames and 6 audit tests PASS | Pixel analysis does not establish natural motion |
| `npm run check:world` | 72/72 PASS, including new 12-combination gait check | Godot/CPU fixtures |
| `npm run typecheck`, `npm test`, `npm run build` | PASS; API 123/123, Web and API build PASS | Local isolated MongoDB/Redis fixture; GitHub CI passed |

Before the final passing runs, the terrain diagnostic rejected a dock-gangway foot at sample 418 because the local inverse search crossed a support seam; the analytic fallback fixed that geometry without enlarging the server floor. An earlier flat32 run failed an over-strict endpoint-chord comparison; the check now tolerates 1% between a summed movement path and its sampled chord while still comparing accepted 3D travel. The failed logs remain in the ignored worktree `.runtime/` directory. The isolated test MongoDB and Redis were stopped after the API run; system database services were untouched.

[Native contact sequence](../visual/nala-gait/native-contact-sequence-2026-11-12.png) is a 480×270 native render contact sheet from before the final separate-equipment phase synchronization. [Leftward occlusion check](../visual/nala-gait/native-left-occlusion-check-2026-11-12.png) is from final source. These are original project captures, not moodboard assets. Their SHA-256 values are `e641024bd069d91f9c4e4153dbac3491ec577eaac3881ddbe60f7a6c186e9377` and `a0dc2d7d10a127a6cfeacfbdb53be2c9925e72c77e791ed4dc514a7935f660fe` respectively. Full logs and 3,104-sample JSON remain in the ignored worktree `.runtime/` and `client-godot/.runtime/` evidence directories.

No generated artwork or third-party runtime was added. Tooling actually used: local Godot 4.7.2, Node/npm, Python source-atlas audit and native Apple M2 render. The existing character atlases and modular gear remain under their recorded project provenance. The contact sheet is documentation only, not a redistributable game asset.

## Open gate and order

The physical lower-body mode is still OFF in release code. A native moving review across unobstructed directions and stairs, then a real browser run on Windows and Samsung S23, must check foot sliding, leg crossing, arm opposition, tool attachment, frame pacing and audio. If these pass, enable the pilot with a measured fallback and run the same checks again. Only then call Nala's natural gait accepted and proceed to the owner's #3 full playthrough and #4 visual/UI polish. Source pass and a still-image contact sheet alone cannot close that gate.
