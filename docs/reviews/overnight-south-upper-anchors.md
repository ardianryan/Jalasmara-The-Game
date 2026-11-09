# SOUTH original palm annotations

CPU source-authoring candidate only. Added [annotation JSON](../../tools/player-gait/south-upper-anchors.json), an original [validator/review exporter](../../tools/player-gait/south-upper-anchors.py) and [focused tests](../../tools/player-gait/south-upper-anchors-test.py). No atlas, actor, lower-body solver, runtime gear, phase, scene or game export changed.

There are 32 representative visible palm texels: eight SOUTH frames × anatomical left/right × daily/explorer. The eight previously reviewed frame 0/4 coordinates and RGBA values remain exact. FRONT left means viewer-right under that existing annotation convention; this is not a near/far rule for another view. New points were selected by reading each original coordinate grid and checked against immutable sheet and upper-frame hashes. Daily frame 3 left (80,61) and explorer frame 3 left (82,63) intentionally differ. A source palette sample is a landmark, not a palm centroid, complete hand mask, wrist joint or grip socket.

**All 32 wrists are explicitly null/ambiguous, and all 32 grips have unknown origin/axis.** Both source sheets show visible hand silhouettes but no unambiguous wrist articulation crease/joint center at this resolution. Several fists blend continuously into the forearm and explorer overlaps the vest. The character owner independently inspected the original coordinate grids and agreed not to promote a shaded boundary or palm pixel to a measured wrist. The data therefore prepares palm ownership/provenance; an authored wrist/grip contract remains required before socket or physical opposition implementation.

Sources remain original daily SHA `342724d1724490279cd0f65c0340c5b35cdf366ecc36a99af716c51f751b8fc3` and explorer SHA `a429c378400bd5ac60a45124ac48672b4cb1360beb379cc83297b52ea48ae3b9`. JSON SHA `171aad6c1f9f45743d1b33b29bfbfc86f37417714188204ef176ea9dc1dd1bdc`. Each entry pins outfit, frame, anatomical side, full source hash, original upper-frame RGBA hash, cell-local coordinate and exact RGBA. Unknown/occluded hands are rejected as visible landmarks even if an opaque texel exists at their coordinate.

```sh
python3 tools/player-gait/south-upper-anchors.py
python3 tools/player-gait/south-upper-anchors-test.py
python3 tools/player-gait/south-upper-anchors.py --output artifacts/player-gait/south-upper-fresh-review
```

**7/7 CPU tests passed**, plus `py_compile` and `git diff --check`. Tests cover all 32 original palms/source immutability, preservation of the existing eight marks, wrong outfit/frame/side/source image, stale frame/source/RGBA pins, coordinates outside the original upper cell, transparent points, unknown/occluded points, duplicates, falsely promoted wrist/grip data, runtime output rejection and no overwriting a prior review. The exporter uses only original crops, nearest scaling and diagnostic palm rings/text; no original pixel is repainted or installed.

Ignored evidence in this worktree, `artifacts/player-gait/south-upper-palms-review-v2/`:

- `daily-south-palms.png`: SHA `58899c723c5b4426ee58b0ea8ee30f240dcc9a82f003b64c43fe2add9d0d4e94`.
- `explorer-south-palms.png`: SHA `5b6fb05eaf89069baa84942db4a8bee16ec231c6bb3392c3ad09bd57a3fbf036`.
- `manifest.json`: SHA `d653c3e393b9b6f1a0ef251f1fae47d8089e6986443be527097bc7b7bff0fbe1`, tying source/spec/script/output hashes and the 32/0/0 palm/wrist/grip counts.

Original coordinate grids are retained in `artifacts/player-gait/south-upper-coordinate-review/`. The first marked v1 sheets had overly long RGBA captions; v2 shortens the caption representation to hex without changing any annotation or source. Both original and marked sheets were inspected. The character owner also reviewed both v2 sheets and found no visible side swap or marker on clothing. Explorer frame 3 left (82,63) is near the distal outer hand edge; it remains a representative visible skin texel, never a center/joint/socket. This peer review does not establish complete arm masks or contact phase. No native/browser phase or natural-walk claim follows from these CPU checks; see the [upper/contact plan](overnight-upper-contact-authoring-plan.md).

Tools actually used: existing Python/Pillow, local original PNGs/JSON, image inspection and Git. Exporter/tests/annotation arrangement are original project work. Original-art licensing and the existing [Pillow notice](../../tools/player-gait/LICENSE-Pillow.txt) remain; no reference-game sprites, new API credential, paid generation or third-party implementation was introduced.
