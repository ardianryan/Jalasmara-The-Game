# Victory dock composition, Phase 1 cutscene

Status: **local candidate** on `work/cutscene-victory-dock-20261118`, based on `main` `928abf6069b4cc66c17006551b982c46b25623e8`. This package has not been merged, pushed, or released to staging.

The victory arrival previously put a single flat boat polygon in a bright rectangular gap cut into the dock. The gap read as a painted-stage hole, especially at 667×375. The dock now has an inset dark teal berth, side walls and fascia, pilings beneath the foreground deck, and a sampan with a tapered hull, interior, gunwale, ribs, shadow, wake and restrained vertical bob. It remains a code-drawn pixel accent over the existing project-owned harbor plate. Nala's emergence, Beno, the five children, two residents, title and dialogue coordinates are unchanged. No gameplay, server state or story text was changed.

| View | Before (native, base source) | Candidate (native, original size) |
| --- | --- | --- |
| 667×375 with dialogue | [Before](../visual/cutscene-children-pass5-20261118/victory-03-667x375.webp) | [Candidate](../visual/cutscene-victory-dock-20261118/victory-dialogue-667x375.webp) |
| 844×390 with dialogue | [Before](../visual/cutscene-children-pass5-20261118/victory-03-844x390.webp) | [Candidate](../visual/cutscene-victory-dock-20261118/victory-dialogue-844x390.webp) |
| 667×375 without dialogue | — | [Candidate](../visual/cutscene-victory-dock-20261118/victory-no-dialogue-667x375.webp) |

Original-size review found the boat, water and dock now distinguishable as three planes at both sizes. Nala and all five children remain fully visible; the title and dialogue do not overlap them. The berth still uses stylized 2D stage geometry rather than a 3D camera projection. This is a specific composition improvement, not proof of full moodboard parity.

Verification used local Godot `4.7.2.stable.official.ed1daf0bf`, Compatibility renderer on Apple M2. A cold editor import completed. The focused `scripts/tests/phase-one-victory-dock.gd` native run passed and captured t0.12, t1.4 and t3.1 at both sizes, plus dialogue at both sizes. `scripts/tests/phase-one-final-action-choreography.gd` passed 54 samples in headless mode. Final logs `/tmp/jalasmara-victory-dock-native.log` and `/tmp/jalasmara-victory-dock-choreography.log` had no `SCRIPT ERROR` or `ERROR:`. The initial cold import emitted missing-font import errors before reimport completed; the subsequent test logs were clean. `git diff --check` passed. This is native-render still evidence, not browser or physical-device animation/performance acceptance.

The three curated WebP images are lossless conversions with `cwebp 1.6.0` of original native PNG captures. Their SHA-256 values are `371efc366b37e20fd0bcbc2bd5211f076dff8d1d88c4d84154467e511c58cd12`, `15c22c92cc2d4576b1e7b873147fce0b2f38d197bd2868218e4d7d77f793d430`, and `b124e26cbef1fce66713db1d238bc26baca136d297070f8edc4ae741608d5425`, in table/candidate order. The source art is the existing project-owned harbor plate and character atlases. No new external tool, library or raster asset was added; no moodboard image entered the build.

The integrator should cherry-pick this package if the native images are acceptable, register the focused fixture in the combined world runner, run combined checks and review the victory beat in browser at real game size before staging. Broader Phase 1 screenplay and animated art parity remains a separate acceptance task.
