# Phase 1 victory dock foreground, source-pixel candidate

Status: isolated local candidate on `work/victory-foreground-20261118`; **not yet integrated or staged**. Source base `c14f659`. This package addresses the documented small-person failure in `victory:3` only. It does not claim full cutscene moodboard parity.

## Change and visual result

The existing harbor plate and dialogue remain. A bounded foreground dock plane puts Beno and two named children close to camera, with feet and contact shadows on the planks. Bagas and Gito each have a pixel-authored connected clap/raised-arm pair from the existing 96×128 village child atlas. Their timing alternates over the existing celebration while Beno lifts with his source wrench pose. Kinasih, Cempaka, Danu, and two residents stay on the rear plane. Nala and her Prasasti stay on the sampan. The near plane improves readability without scaling every distant actor or changing any script line, trigger, quiz, reward, or server state.

The cream 30×28 square at the left edge of the dialogue is **Beno's intentional happy emote** (`DialoguePresenter.gd`, `Emote._draw`), anchored to his portrait and already present in the pre-change baseline. It is a UI element, not a missing texture or child-art artifact. The UI owner can revisit its placement separately.

Native actual-size frames (Godot 4.7.2 Compatibility, entry `0.0s`, jump `0.43s`, settled `2.25s`):

| Frame | 667×375 | 844×390 |
| --- | --- | --- |
| Entry | [PNG-derived WebP](../visual/cutscene-victory-foreground-20261118/victory-03-entry-667x375.webp) | [PNG-derived WebP](../visual/cutscene-victory-foreground-20261118/victory-03-entry-844x390.webp) |
| Jump | [PNG-derived WebP](../visual/cutscene-victory-foreground-20261118/victory-03-jump-667x375.webp) | [PNG-derived WebP](../visual/cutscene-victory-foreground-20261118/victory-03-jump-844x390.webp) |
| Settled | [PNG-derived WebP](../visual/cutscene-victory-foreground-20261118/victory-03-settled-667x375.webp) | [PNG-derived WebP](../visual/cutscene-victory-foreground-20261118/victory-03-settled-844x390.webp) |

These six curated WebPs total 485 KiB. The original PNG captures are local ignored files in `artifacts/godot/cutscene-victory-foreground/`. The WebPs are evidence, not runtime art. Visual review at both original sizes found distinct Bagas and Gito silhouettes, no child/Beno overlap, and unobstructed title and dialogue. A still cannot establish motion smoothness on a phone.

## Provenance and checks

The atlas `client-godot/resources/art/village-expansion-v1/residents.png` SHA-256 is `6dc5fbb107327c97205660817cf245661bea838d50be606735fe2c6a247d413e`. The derived sheet `client-godot/resources/art/cinematics-v2/victory-child-poses.png` SHA-256 is `be3016f1c91774df64657a58238dfa4470e23229dc0fe495546b9b1c8a11e704`. `tools/cutscene/author-victory-child-poses.py` plus Pillow produce it using hard pixel masks and source colors; it checks four-neighbor alpha connectivity. The art retains project artwork terms in `LICENSE` §2. No third-party sprite, image-generation service, or moodboard image was used.

`python3 tools/cutscene/author-victory-child-poses.py` passed. Clean second Godot headless import log `/tmp/jalasmara-victory-import-revised.log` has no `ERROR:` or `SCRIPT ERROR`. Native fixture `scripts/tests/cutscene-victory-foreground.gd` passed six timing/size checks and reduced-motion state in `/tmp/jalasmara-victory-native-revised.log`. `git diff --check` passed. This package was not tested on physical Windows or Samsung S23, and it is not a staging release. After integration, rerun combined Godot/check:world/typecheck/tests/build and inspect the complete story flow.

Next: integrator reviews this commit and evidence before cherry-pick. Remaining small-person shots and full visual parity are tracked by [the 12-shot audit](cutscene-small-actor-reassessment-2026-11-18.md); the next isolated package targets `garden_crisis:5`.
