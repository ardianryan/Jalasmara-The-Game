# Garden crisis Kinasih clue, source-pixel candidate

Status: isolated local candidate on `work/garden-kinasih-close-20261118`, based on main `61d8981`; **not yet integrated or staged**. This package addresses one remaining Phase 1 cutscene actor-size failure in `garden_crisis:5`, not the full moodboard gap.

The original shot placed Kinasih as a ~55–60 px figure beside the hydroponic racks. She is now a nearer focal actor on the original deck, with a two-pose source-pixel gesture: she holds a glass clue jar at her side, raises it while pointing toward the forest/sea clue, then lowers it. Her sleeve, hand and jar remain connected. Existing guards, garden plate, title, dialogue, story trigger/line and server rules remain. A provisional flat foreground plank was rejected during visual review and removed; the accepted candidate uses the already grounded deck in the source painting. The parchment square left of her feet is the existing `DialoguePresenter.gd` happy emote anchored to her portrait, visible in the baseline too, not a leaked texture.

Actual-size Godot 4.7.2 Compatibility captures at entry `0.0s`, point `0.85s`, settled `2.25s`:

| Frame | 667×375 | 844×390 |
| --- | --- | --- |
| Entry | [WebP](../visual/cutscene-garden-kinasih-20261118/garden-05-entry-667x375.webp) | [WebP](../visual/cutscene-garden-kinasih-20261118/garden-05-entry-844x390.webp) |
| Point | [WebP](../visual/cutscene-garden-kinasih-20261118/garden-05-point-667x375.webp) | [WebP](../visual/cutscene-garden-kinasih-20261118/garden-05-point-844x390.webp) |
| Settled | [WebP](../visual/cutscene-garden-kinasih-20261118/garden-05-settled-667x375.webp) | [WebP](../visual/cutscene-garden-kinasih-20261118/garden-05-settled-844x390.webp) |

Six curated WebPs total 568 KiB. Original PNG captures remain ignored locally in `artifacts/godot/cutscene-garden-kinasih/`. This shows legibility and contact at native sizes, but does not measure phone motion quality or game frame rate.

The source `client-godot/resources/art/village-expansion-v1/residents.png` SHA-256 is `6dc5fbb107327c97205660817cf245661bea838d50be606735fe2c6a247d413e`. Derived `client-godot/resources/art/cinematics-v2/garden-kinasih-clue.png` SHA-256 is `79a52a1c460ab4f41bc4e0d6f647b3d263dcd4910d735f7cae5b40c2499f2cf4`. `tools/cutscene/author-garden-kinasih.py` uses Pillow hard-pixel primitives and checks four-neighbor connectivity; the two isolated hair-glint source pixels are retained. The original project art terms in `LICENSE` §2 apply. No external sprite or image generation was used.

Generator and `git diff --check` passed. The second editor import `/tmp/jalasmara-garden-kinasih-import-clean.log` had no `ERROR:` or `SCRIPT ERROR`; first-pass transient font import-data messages cleared on rerun. `scripts/tests/cutscene-garden-kinasih.gd` passed six native-size/timing checks plus reduced-motion state with no errors in `/tmp/jalasmara-garden-kinasih-native-revised.log`. Integrator should rerun combined checks after accepting the patch. This local package is not a staging release.

Next: integrator checks the actual-size frames and diff, cherry-picks accepted source and proof, reruns combined checks, then removes the branch/worktree. The wider cutscene and world-art parity backlog remains in [the 12-shot audit](cutscene-small-actor-reassessment-2026-11-18.md).
