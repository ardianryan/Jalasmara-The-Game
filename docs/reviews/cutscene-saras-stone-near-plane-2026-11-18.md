# Saras's stone reveal: connected source pixels and near-plane blocking

The `saras_visit:2` stage actor in the [667×375 reassessment](cutscene-small-actor-reassessment-2026-11-18.md) occupied about 58–65 visible pixels. Its stone was a detached polygon, so Saras's portrait carried the scene. This local candidate moves Saras to the near floor beside the counter and replaces the detached prop with a two-pose transparent 64-pixel-grid sprite. The torso, sleeve, elbow, palm and cracked stone remain connected in both poses; her feet stay on the interior floor immediately above the dialogue panel. No story, server state, physics or other cutscene beat changed.

The 128×64 sheet is rebuilt by `python3 tools/cutscene-pixel/author_saras_stone.py` from the first 64×64 tile of project-owned `npc-facing-v2/saras-front.png`. It retains the face, hair, satchel and lower-body pixels. The script replaces the old raised hand and scroll with two connected positions, then draws an incised cyan line and three source-grid pixels of purple acid stain on grey stone. A pinned source SHA-256 aborts rebuilding if that tile changes. Pillow 11.3.0 was the only art authoring dependency; no external sprite or moodboard pixels were used.

The stage figure now occupies roughly 130–145 vertical pixels at 667×375 while the stone is about 20 pixels across. This is a specific near-plane camera blocking for one beat, not a global actor scale change. Its ground line is `view.y × 0.69`; the actor moves a short distance from `view.x × 0.54` to `× 0.51` as she presents the stone. The 844×390 view keeps the same grounded composition. The two sampled poses switch after 0.75 seconds; reduced-motion mode holds the readable reveal pose.

## Verification

- `python3 tools/cutscene-pixel/test_saras_stone.py`: 4 tests passed; exact regeneration, body-to-stone four-neighbor alpha connectivity in both poses, untouched lower body, both acid stain and cyan inscription colors.
- Godot 4.7.2 headless `scripts/tests/cutscene-saras-stone.gd`: six timing/viewport checks passed at 667×375 and 844×390.
- Native Godot Compatibility/Metal `CINEMATIC_CAPTURE=1 ... --script res://../scripts/tests/cutscene-saras-stone.gd`: six captures passed without script errors. Three lossless WebP frames are curated below from the original-size PNG captures; the complete local PNG set remains under `artifacts/godot/cutscene-saras-stone/`.

| Curated proof | SHA-256 |
| --- | --- |
| [Arrival, 667×375](../visual/cutscene-saras-stone-20261118/saras-02-arrival-667x375.webp) | `e47deb13cc94151eaf4f8517bac11a8b7c15e961828a095a6143f0ac5209b213` |
| [Hold, 667×375](../visual/cutscene-saras-stone-20261118/saras-02-hold-667x375.webp) | `a0212422d3d7c21feb6fda91be1d48bfcc9a5450563b16a3025bbbc9b5eebf` |
| [Hold, 844×390](../visual/cutscene-saras-stone-20261118/saras-02-hold-844x390.webp) | `fbb3e71f21c5ff6ebc5a21d0d739b98e9b7dadddc37c9e891d0b914a7d1bb9c7` |

This is a local source/runtime acceptance candidate awaiting integrator review and combined checks. It has not been pushed or deployed to staging. Still images demonstrate readable stone presentation and grounding, not continuous body animation or physical-device performance.
