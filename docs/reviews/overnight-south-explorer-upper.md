# SOUTH explorer0 source ownership and two authored endpoints

CPU-only candidate. New [spec](../../tools/player-gait/south-explorer-upper.json), [tool](../../tools/player-gait/south-explorer-upper.py) and [tests](../../tools/player-gait/south-explorer-upper-test.py) inspect original explorer SOUTH frame0 independently from the daily proposal. No atlas, runtime, Lower, actor, gear, daily masks or WEST tool changed. This is not an eight-frame explorer loop or natural-walking acceptance.

## Source and garment contract

The normalized original atlas is `male-nusantara-explorer-walk-8way-v1.png`, SHA `a429c378400bd5ac60a45124ac48672b4cb1360beb379cc83297b52ea48ae3b9`; the crop is row2/frame0, 128×76. Tracked original authoring source `assets/source-2d/nala-eightway-batch/male-nusantara-explorer-source.png` has SHA `df724ddc89e481df009d3325e9636e2d83fcc5b6ac23a6d4fb34812e56116bc1`. Its manifest records `equipmentBaked:false`. Both source images were read locally; no generator/API ran.

Visible clothing includes the teal short-sleeved shirt, tan vest with sewn pockets, and a brown waistbelt/hanging strap. Original pixels are split into exclusive shirt, vest, belt and other/head/trouser remainder, plus six arm parts. Those semantic masks are manual ownership proposals, not measured garment segmentation. Each opaque source texel has exactly one owner; no second torso or garment is composited over the first.

Existing runtime contract, inspected rather than retested here: `CharacterVisual.get_equipment_state()` sets `vest=false` when the clothing atlas is ready, so the atlas vest is not duplicated by the detachable vest mesh. Explorer's separate satchel is constructed by `CharacterEquipment3D` and covered by prior actual node/browser evidence. This authoring tool creates no nodes, new bag/tank/net pixels, equipment flag changes or grip/socket. The existing [wardrobe source audit](overnight-wardrobe-gear-audit.md) and [node diagnostics](overnight-equipment-node-diagnostics.md) remain separate evidence. A source waist strap is not relabeled as a new satchel or reward.

## Why daily ownership cannot be copied

The earlier explorer inventory used a broad LEFT-upper polygon that includes tan vest shoulder around x70–74/y43–50. Rotating it as an arm would move clothing off the torso. The new explorer-specific LEFT sleeve cap follows the visible teal region x75–81, and the tan shoulder remains on the body. RIGHT sleeve/fore/palm use separately reviewed source coordinates. Two tan original vest-edge pixels `(56,51)=[132,111,79,255]` and `(56,52)=[127,103,74,255]` are explicitly reserved for the torso before all arm masks, rather than rotating as a cuff.

Original LEFT palm `(74,62)` and RIGHT `(49,65)` remain in their corresponding palm cutouts. SOUTH anatomical LEFT is viewer-right and RIGHT is viewer-left; this establishes no near/far convention for other directions. No daily hidden-cloth donor, repair contour or joint record is read by the new tool. It reuses only the existing source/polygon/rigid affine helper operations.

| Original layer                 |        Opaque texels |
| ------------------------------ | -------------------: |
| LEFT sleeve/upper, fore, palm  |         63 / 36 / 53 |
| RIGHT sleeve/upper, fore, palm |         50 / 47 / 51 |
| Shirt / vest / belt / other    | 78 / 302 / 130 / 707 |

Original source reconstruction is byte-exact. Head y<43 stays byte-exact in both endpoints, and all rendered opaque colors belong to the explorer source palette.

## Explicit hidden-garment and joint authoring

The neutral garment plate fills **41 newly authored hidden texels** formerly covered by source arms: 23 belt and18 vest. Each record pins destination, same-explorer/same-row/same-proposed-garment donor and exact source RGBA. Sixteen original owned donors on15 rows provide the fill. No cross-frame/outfit recovery is claimed. The initial draft correctly failed when an over-wide contour requested a donor at `(72,60)` or `(76,60)` from a garment without a visible source sample; the explicit belt/outer-body contour was revised, rather than silently falling back to daily colors or arbitrary rows.

The resulting belt reconstruction contains horizontal dark source shading. Its appearance is an authored art choice for review, not proof of the hidden original belt or pocket. At original rest all repair texels are occluded by the original arms, restoring the source RGBA exactly. Alpha outside the proposed repair stays as the original ownership result.

Explorer-specific anchors are **AUTHORED design proposals**:

| Anatomical side | Shoulder | Elbow | Wrist design anchor |
| --------------- | -------- | ----- | ------------------- |
| LEFT            | 78,49    | 79,57 | 75,61               |
| RIGHT           | 53,49    | 51,57 | 49,64               |

The two endpoints are original rest and an authored opposing-arm pose: shoulders remain fixed, LEFT forearm/palm rotates−42° about its authored elbow, RIGHT−62°. LEFT is behind the torso only in the authored endpoint. This is an explicit pose/depth proposal, not a tested ordering transition or foot phase. Original32 palm annotations still have ambiguous/null wrists and unknown grip; this tool does not promote design anchors to measured original joints.

Shelter viewed the actual v3 source/garment, body/endpoints and isolated-arm sheets. Teal sleeves stay on arms, tan vest stays on the body, the broad vest flap is absent, isolated endpoints look connected in those stills, and no clear bright old-arm remnant or body hole was found. They specifically retained the hidden horizontal belt/vest reconstruction as an art proposal, not recovered source. Final v5 rendered poses match v3; later changes add strict status/gear guards, clearer labels, and prune unused donor candidates without changing any repair/pose bytes.

## Root's follow-up: two isolated original arm-edge texels

After commit `b9935c1`, root viewed the body-only plate and found dark/brown specks. Exact eight-neighbor alpha components were one main body of1,258texels and two one-pixel islands: original `(47,69)=[60,43,32,255]` and `(83,56)=[68,47,30,255]`. Neither came from authored fill. The former adjoins original RIGHT palm `(48,69)=[56,41,25,255]`; the latter adjoins LEFT forearm skin `(82,56)=[238,181,133,255]`. Both lie outside the intended fixed torso contour. Shelter independently confirmed the source coordinates/RGBA and plausibility of their arm-outline ownership.

V6 explicitly assigns `(47,69)` to RIGHT palm and `(83,56)` to LEFT forearm, with original RGBA and manual ownership reasons in the spec/manifest. No source pixel is erased or recolored. The body now has exactly one1,258-texel alpha component;41 hidden repairs and the intended contour are unchanged. Original rest stays byte-exact. A regression reconstructs the previous masks, proves the exact `[1258,1,1]` component failure and island coordinates, then checks `[1258]` after reassignment. Remaining **attached** original dark garment folds were not automatically deleted or reassigned. This is narrow source-boundary repair, not acceptance of every dark pixel's anatomy.

## Actual checks and reproduction

```sh
python3 tools/player-gait/south-explorer-upper-test.py
python3 -m py_compile tools/player-gait/south-explorer-upper.py tools/player-gait/south-explorer-upper-test.py
python3 tools/player-gait/south-explorer-upper.py --output artifacts/player-gait/south-explorer-upper-fresh
```

**7/7 CPU tests PASS**, along with `py_compile` and `git diff --check`. Tests exercise every original texel's one-owner coverage/RGBA; exact rest; vest shoulder versus teal cap/palm ownership; all41 same-row/same-garment source donors and their occlusion; unchanged head/palette and rigid determinant+1/unit transforms; rejecting daily/wrong-source/corrupt donor/duplicate vest mesh status/measured-wrist relabeling; unchanged source/input and refusal to write runtime output. These checks do not grade joint anatomy or animation quality. No engine, browser, GPU, frame timing, gear-node run or new export occurred.

Ignored final review: `artifacts/player-gait/south-explorer-upper-draft-v6/`. Previous v5 remains preserved with its two visible specks; it is not silently relabeled as the corrected evidence.

| File                                     |  Bytes | SHA256                                                             |
| ---------------------------------------- | -----: | ------------------------------------------------------------------ |
| `explorer0-source-garment-ownership.png` | 19,403 | `1085c4ffa3c4382fc5282ea6f38ff92cbe4032edabf5d6aea1f967c876bbbc47` |
| `explorer0-two-endpoints-and-body.png`   | 23,793 | `867915cd1f07d01e29ecfe21bf8e3c1d2214bbdb43fd962a6ea1f18ecf9c4df5` |
| `explorer0-separate-arm-endpoints.png`   | 10,603 | `cbdc8e205a8556541cae1848306413ce3deb599a77aa6a649c6f30e5fb290200` |
| `manifest.json`                          | 27,126 | `e8277a29f525576fc7a1c2394894011e9fdd43f58f102f96018fd458255d86b1` |

Spec SHA `757f811d8f0dd71d965861b2f32c642c6d205f95b920e6de4231b6e1ce77f8a5`. Manifest pins original source/tool/spec/helper, exact source arm and garment runs,41 authored donor records, authored joint/matrix poses and the zero-new-gear contract. Earlier source grids and failed draft attempts remain under `artifacts/player-gait/south-explorer-source-inspect-v1/` and draft v1–v4.

Next: root/character review these exact source boundaries and the hidden belt/vest shading before extending explorer into a cyclic loop. Wrists/grips, dynamic occlusion, source completeness at different angles, native scale, stopping/turning and final Lower contact coupling remain separate work. There is no source-atlas replacement, new torso/gear geometry or default activation in this package.

Tools actually used: local Python/Pillow, original project PNG/JSON, CPU affine diagnostics, source/code inspection and Git. New code/arrangement and authored garment/joints are original project work. Original-art terms and [Pillow notice](../../tools/player-gait/LICENSE-Pillow.txt) remain; no external sprite, image generator, paid API or third-party implementation was introduced.


Root integration06.34WIB: sourceb9935c1/2502ff6 adopted as separate original-authoring tools only. Root independently viewed v5 and identified two detached body-edge texels; v6 returns exactly those original texels to moving source components, preserving rest and41 authored garment fill. Root viewed v6 and reran7CPU tests, py_compile/exporter, matching actual endpoint hash867915cd…c4df5. Test registered in existingCI source; no new CI job or runtime acceptance follows. Hidden belt shading remains a design proposal, not a recovered original surface. Website proceeds to NW source-facing audit; sourceatlas/runtime/gear unchanged.
