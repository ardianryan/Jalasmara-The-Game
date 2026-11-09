# SOUTH arm/torso ownership and authored pose proposal

CPU authoring candidate, not runtime-ready anatomy or natural walking. The original [spec](../../tools/player-gait/south-upper-ownership.json), [exporter](../../tools/player-gait/south-upper-ownership.py) and [tests](../../tools/player-gait/south-upper-ownership-test.py) read existing SOUTH daily/explorer frames 0/4. No original atlas, WEST tool, actor, Lower, CharacterVisual, gear, phase or scene changed.

## Source ownership

Each original 128×76 upper crop is partitioned into two sleeve/upper-arm, forearm and palm candidates plus the original head/torso remainder. Explicit polygons and daily0 boundary row-runs intersect only opaque source. Palm→fore→upper priority assigns one owner per texel; source reconstruction is byte-exact in all four cases. Head y<43 and all original visible clothes/colors remain intact. This proves RGBA coverage/provenance, **not anatomical correctness**: visual mask review remains separate from a partition's recomposition invariant.

| Outfit/frame | Left upper/fore/palm texels | Right upper/fore/palm texels |
| ------------ | --------------------------- | ---------------------------- |
| daily0       | 114 /48 /74                 | 83 /45 /49                   |
| daily4       | 85 /51 /40                  | 60 /41 /48                   |
| explorer0    | 118 /40 /64                 | 77 /42 /50                   |
| explorer4    | 85 /45 /45                  | 79 /42 /48                   |

All eight previously reviewed frame 0/4 palm landmarks lie in the correct palm cutouts. Front anatomical left remains viewer-right; no near/far mapping or mirrored view is introduced. Sources remain daily SHA `342724d1724490279cd0f65c0340c5b35cdf366ecc36a99af716c51f751b8fc3` and explorer SHA `a429c378400bd5ac60a45124ac48672b4cb1360beb379cc83297b52ea48ae3b9`.

## Hidden cloth and the revised daily0 proposal

Under the bent left palm, daily0 (74,62) is skin `[223,165,120,255]`; daily4 at that coordinate is `[83,96,91,255]`. That is a potential cloth observation, not a registered recovery: even visible central cloth (65,53) differs, `[90,109,108,255]` versus `[88,107,107,255]`. Explorer has a separate vest/belt and palette. No cross-frame/outfit pixel is silently substituted.

The first draft painted 184 removed-arm texels inside an overly broad envelope. Root viewed it and rejected the visibly puffy/double-sleeved plate and old palm-area widening. Draft v1–v3 images remain preserved. Byte-exact rest did not establish a usable arm-free shirt.

The revised body-only row contour follows the visible torso/waist: rows 46–52 x57..72, rows 53–63 x56..72, row 64 x57..71 and row 65 x60..70, inclusive. Sleeve caps and old arm/palm area outside those rows remain alpha in the neutral plate. Daily0 skin/outline fringes including (76,65), (75,66), (55,57), (55,61) are reassigned to original arm ownership, not painted as cloth. Source sleeve-cap point (76,49) also remains alpha on the body-only plate.

Only 54 hidden cloth texels are now **newly authored**, confined to that body contour and occluded by the original arms at rest. Each repair records its destination, same-row original owned-cloth donor and exact RGBA. Eighteen source rows and 24 actual donors preserve row/edge shading instead of repeating one flat patch. Donor candidates are explicit original palette samples; only visible source plate texels can supply them. The earlier verified central cloth patch `[62,48,68,58]` remains pinned to rawRGBA SHA `4b5bea858e140c0ab4b544c5ad76f0e91ac1132bfec4a23bf54d264572fbecc4`. This is newly designed covered cloth, never recovered original art. Full original rest reconstruction remains byte-identical after the repair.

Six shoulder/elbow/wrist anchors are explicitly **AUTHORED design proposals**, not measured original joints: left (76,49)/(79,58)/(76,61), right (53,49)/(51,57)/(49,63). Existing 32 source palm records keep their wrists null/ambiguous and grips unknown. The new design does not overwrite that uncertainty.

## Two pose endpoints for seam review

The exporter presents original rest beside an authored angle extreme. Original sleeve/upper segments stay fixed; source forearm+palm cutouts rotate rigidly about the authored elbow anchors (left−45°, right−80°). The left arm is explicitly placed behind the torso in the second authored depth proposal, with the other in front. No source limb is mirrored, scaled, stretched or recolored. Matrix/head/palette checks pass, and the two endpoints differ visibly.

The images were inspected: the neutral shirt no longer expands into the old palm area, the known skin fringes are gone, and the original-rest composite retains identity/clothes exactly. These are **authoring review endpoints**, not measured contralateral phase or a complete articulated cycle. Rigid cutout seams, hidden-arm coverage and authored pivot/depth choices still need root/character acceptance and later native gameplay-scale review. No wrist/grip or contact-phase acceptance follows from these pictures. Other three outfit/frame cases remain source-ownership inventories; they do not inherit the daily0 repair or pose.

## Checks and reproduction

```sh
python3 tools/player-gait/south-upper-ownership-test.py
python3 tools/player-gait/south-upper-ownership.py --output artifacts/player-gait/south-upper-ownership-fresh
```

**8/8 CPU tests passed**, along with `py_compile` and `git diff --check`. They check four exact RGBA/one-owner reconstructions; unchanged head/source hashes; pre-reviewed palm ownership; all 54 donor records on the same row inside the body contour; no source hand fringe/cap on the neutral plate; corruption/frame/coordinate rejection; unchanged old ambiguous-wrist records; and two authored endpoints with original head/palette and determinant+1, unit-length orthogonal transforms. These tests do not grade anatomy, cloth artistry, interpolation or natural walking.

Ignored final review files in this worktree: `artifacts/player-gait/south-upper-ownership-draft-v5/`.

- `south-upper-ownership-comparison.png`, 56,952 bytes; SHA `2a238f8a8aa4db0ba11f246d04fab6a5462f6af76d47a6f4da392589b90aad23`.
- `south-daily0-hidden-cloth-proposal.png`, 26,865 bytes; SHA `78a46e74eb157762491173341ed5d991b17e3485e1af46dac20b4cfa64748e37`.
- `south-daily0-authored-extremes.png`, 10,658 bytes; SHA `bd18cfe3ba4d4154d4a7d98de88b17bac23be1f00db4bbb462d06496c13951ee`.
- `manifest.json`, 63,159 bytes; SHA `15c8bfe698391e2b1c2becf33a697a35f969c6083b19ee3221617531b99f8b88`, with source/spec/helper/script pins, original pixel runs, 54 donor records and authored joint/matrix provenance.
- Spec SHA `14fe42f559a4f34d4ce2947dff85b93d6fc262a77027ed15f822e24e470b2fc3`.

Next: root/character inspect these exact endpoint/ownership files; refine any remaining boundary, pivot or depth issue as authored data. Then review an authored full loop against the final validated Lower contact producer. No runtime adoption, duplicated torso/gear meshes, source-atlas replacement or default activation is part of this package.

Only local Python/Pillow, original PNG/JSON, diagnostic output, image inspection and Git were used. New arrangement/code and authored joint/cloth proposals are original project work; existing original-art terms and [Pillow notice](../../tools/player-gait/LICENSE-Pillow.txt) remain. No engine/browser, API key, external image, reference sprite or third-party implementation was introduced.
