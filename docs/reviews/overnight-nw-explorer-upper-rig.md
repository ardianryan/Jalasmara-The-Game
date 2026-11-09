# NW explorer source-specific ownership and two authored endpoints

CPU authoring candidate on the [coherent NW0 arrangement](overnight-nw-explorer-orientation-proposal.md), not a replacement for the defective original explorer WALK atlas. New [spec](../../tools/player-gait/nw-explorer-upper-rig.json), [tool](../../tools/player-gait/nw-explorer-upper-rig.py) and [tests](../../tools/player-gait/nw-explorer-upper-rig-test.py) partition the original reference pixels and propose a rig. No atlas, runtime, Lower, gear, other identity/outfit or Gemini audit output changed. An eight-frame cycle is deliberately pending root/peer outline review. Commit `c5431a8` v4 was rejected for its square elbow notch; the follow-up below repairs that measured gap as explicitly authored hidden overlap.

## Source arrangement and original ownership

The reference remains the explicitly **AUTHORED** arrangement: original daily NW WALK0 head y<43 plus original explorer NW IDLE column5 body y≥43, without mirror/scale/offset. The arrangement RGBA SHA is `d7fff8ddae2d283a269411dd68ea1590707726c64f0c0e13de19a1de4e2ad95a`. Source atlas pins/provenance remain in the orientation proposal. This rig reads no SOUTH mask, body repair, joint or donor data. Only generic polygon, rigid affine and pixel-run helper operations are reused.

New NW-specific masks assign each opaque reference pixel exactly once to four garment/remainder layers or sleeve-cap/upper/fore/hand on two chains. The head y<43 remains with the original remainder. Vest, shirt and belt source ownership is exclusive; no duplicate torso or gear layer is composited. The visible near sleeve is teal, the vest/back remains tan, and the far sleeve has only a narrow strip in the original occluded view.

| Original source part                           |       Opaque texels |
| ---------------------------------------------- | ------------------: |
| Authored LEFT chain cap / upper / fore / hand  |   76 / 41 / 55 / 67 |
| Authored RIGHT chain cap / upper / fore / hand |   13 / 22 / 21 / 24 |
| Original vest / shirt / belt / other           | 304 / 14 / 75 / 761 |

Forty-one explicit source-boundary records preserve original RGBA at sleeve edges, near-hand fingertips, the far arm's skin edge x73 and its hand outline. They are manual ownership decisions with coordinates/RGBA/status, never automatic palette classification. Source texels are reassigned, not erased or recolored. In particular `(51,56)=[35,29,21,255]` originally remained a detached body speck next to the upper arm; it now belongs to that arm. Original near-hand bottom `(51,74)=[182,138,89,255]` moves with the hand. Original garment pixels such as vest `(63,50),(68,56)` and belt `(65,62)` remain on the body.

## Authored anatomical convention, not measured sides

The source audit still has anatomical side unknown and source wrist/grip null. The new skeleton uses an **AUTHORED naming convention**: chainA (visible screen-left sleeve) is named LEFT above the existing authored rear-left Lower hip x59; chainB (occluded screen-right sleeve) is named RIGHT above hip x70. This is a choice for a coherent new rig, not proof of source physical identity. Hand screen-X alone is not used to identify sides across motion. No Lower data or contact event is consumed or modified.

| Authored chain | Shoulder | Elbow | Wrist design anchor |
| -------------- | -------- | ----- | ------------------- |
| LEFT / chainA  | 56,50    | 54,59 | 51,68               |
| RIGHT / chainB | 74,51    | 75,59 | 76,67               |

Every joint is explicitly authored. Source wrist/grip uncertainty remains unchanged; a design wrist anchor is not a measured source crease, palm center or grip/socket. Contact phase stays null.

## Body plate, rest and the two endpoints

Only **eight hidden garment texels** are newly authored: three vest, five belt. Seven original explorer-IDLE donors on seven same-source rows provide exactly recorded RGBA of the same proposed garment category. No daily cloth or SOUTH repair is copied. Each repair is occluded at neutral reference, which reconstructs the arrangement byte-for-byte.

The first source-boundary refinement correctly failed the neutral reconstruction guard when the body envelope extended into the far arm's x73 skin column: placing the far chain behind that newly filled column concealed its original edge. The contour was narrowed explicitly to x<73; the guard was retained. Alpha within the final intended body contour is fully opaque. The body below head cutoff has one 535-texel eight-neighbor component. This verifies source coverage, not garment anatomy.

Endpoint0 is the exact neutral reference. Endpoint1 holds shoulders fixed, rotates the near forearm/hand+32° around its authored elbow and far forearm/hand−24°. The far/right chain remains behind the body in both poses. Fore and upper transforms share the elbow coordinate; all transforms are rigid determinant+1, without mirror/stretch/recolor. Near/far depth is an authored proposal and is not a measured walking swing phase.

Shelter viewed the actual v3 ownership/body, two-endpoint and isolated-arm sheets. Vest/belt stayed coherent; no broad cloth flap or obvious bright old arm remnant remained on the body. **V3/V4 visual failure:** the near/LEFT forward elbow had a visibly square inward notch just below the cuff. It is connected in the still, but connectivity does not establish a smooth anatomical contour. The far/right source chain is extremely narrow because of occlusion. These points remain visual authoring review, not silently converted into passing anatomy. V4 pixels matched v3; root explicitly rejected that outline for a loop. Those images remain historical failed visual evidence.

## Root-rejected notch: measured source cause and bounded overlap repair

The labelled source grid identifies the actual old gap at output `(55,59),(56,59),(56,60)`. The +32° forearm inverse-nearest map samples original source `(55,58)=[222,178,135,255]` and `(56,58)=[217,171,128,255]`. Both are owned by the static upper segment, so the moving fore root has no pixels there while static upper edge x57..58 extends downward. This is a cut/hinge coverage defect; eight-connectivity alone did not detect its visual quality.

CPU alternatives were inspected and retained in `artifacts/player-gait/nw-elbow-notch-source-v1/`: moving four source upper texels to fore worsened the gap; a pivot sweep can hide it at x58 but shifts the authored axis four pixels from54. Neither was adopted. The selected repair keeps shoulder, elbow `(54,59)`, wrist, masks, source ownership and all matrices unchanged.

Instead, two **AUTHORED hidden fore-root overlap surface texels** copy the above exact upper-owned RGBA at the same source coordinates. These are **not exclusive original forearm ownership** and are not measured/recovered anatomy. Original source masks still assign each texel once; the separately recorded authored overlap deliberately duplicates two samples for covered joint surface. At neutral they coincide with identical original upper colors, leaving the whole reference byte-identical. At the authored endpoint they fill exactly the three previously transparent output pixels, recoloring no existing opaque pixel. The body, head, eight garment fills, original arm/garment partitions, all matrices and gear remain unchanged.

Shelter independently reproduced the inverse map, exact two donor values, three output gaps and byte-identical neutral. They viewed the overlap probe and found the conspicuous square inward notch removed without shifting the axis/sleeve or broadening the whole arm. This is still bounded endpoint/contour review; future loop silhouettes and anatomy remain unaccepted. Final v6 provides reproducible before/after and labelled coordinate sheets. Root's final visual review is pending.

## Actual checks and evidence

```sh
python3 tools/player-gait/nw-explorer-upper-rig-test.py
python3 -m py_compile tools/player-gait/nw-explorer-upper-rig.py tools/player-gait/nw-explorer-upper-rig-test.py
python3 tools/player-gait/nw-explorer-upper-rig.py --output artifacts/player-gait/nw-explorer-upper-rig-fresh
```

**10/10 CPU tests PASS**; `py_compile` and `git diff --check` PASS. Tests cover one original owner/RGBA per texel; exact reference rest; no detached body/arm alpha islands and no intended-body alpha holes; all eight same-row/garment repair records; fixed garment versus moving sleeve ownership; unknown source measurements versus authored joint convention; unchanged head/palette; shared rigid elbows; rejecting wrong scope/source, changed/duplicate boundary, invented wrist, corrupt donor or duplicate vest flag; original source/input immutability; runtime output refusal. New tests also disable the authored overlap to reproduce the exact prior notch, verify only those three output alpha gaps change, and reject changed/duplicate/unlabelled overlap. They do not establish anatomical contour, depth, side mapping, wrist/grip or natural motion.

Actual components below y43: neutral LEFT 239, RIGHT 80; authored endpoint LEFT 237, RIGHT 80, each one eight-connected component. The original posed arm had 234 texels; the two authored surface texels fill three raster gaps, producing 237. The neutral remains 239. Raster overlap/count changes are not bone length scaling. Body component 535 is unchanged. No GPU/native/browser, physics/contact, performance or runtime export ran.

Ignored final directory: `artifacts/player-gait/nw-explorer-upper-rig-draft-v6/`; earlier v1–v5 remain preserved, including root-rejected v4.

| File                                     |  Bytes | SHA256                                                             |
| ---------------------------------------- | -----: | ------------------------------------------------------------------ |
| `nw-explorer-ownership-and-body.png`     | 17,908 | `41c6effc217d04bc2dd4acb704dfb20735e3a77cbfc0cfd3e6c62c170432a80d` |
| `nw-explorer-two-endpoints.png`          | 22,410 | `4c0170785c3f8164ff19b79e7d1550e2529cd57931616ee580019898686ac5f2` |
| `nw-explorer-isolated-arm-endpoints.png` | 10,750 | `3bd12688c740d002649d3b961aaa89232a048e35793abd21bfadca2360925424` |
| `manifest.json`                          | 28,982 | `969c7ba20031ec962cc12ec39eb5af8d646483832320a2676b57d0f67b7616da` |

Additional review sheets: `nw-explorer-elbow-labelled-grid.png`, 11,750 B SHA `a1f3656794861251c828c864b9203884b6e4bf664541a59cc23a4391bc9c151e`; `nw-explorer-elbow-overlap-before-after.png`, 15,981 B SHA `4bbabc52c371db9900072e335bfa9414fa832092dc867ecc191b686499ed2ef3`.

Spec SHA `22fc470fe9f6132a3bba87c29cc2ac9048db8596b8fb0e8af3089655fe448cf0`. Manifest records the reference arrangement pin, source versus authored convention, exact original arm/garment runs, 41 source-boundary records, eight hidden garment fills, separately labelled two-texel authored joint overlap, authored matrices/joints, components and zero-new-gear contract.

Next: root/character review the repaired elbow, body continuity and proposed side/depth convention before an eight-frame NW cycle. Any contour improvement must have explicit authored/source provenance and preserve neutral reconstruction; do not fake a measured wrist or fill the hidden far arm without authored labeling. Stops/turns, gear sockets, full NW WALK replacement and final Lower contact coupling remain pending. No other10-set Gemini source is read or edited.

Tools actually used: local Python/Pillow, original project PNG/JSON, CPU rigid raster authoring, image/source inspection and Git. New code/arrangement and hidden garment/joint proposals are original project work. Original-art terms and [Pillow notice](../../tools/player-gait/LICENSE-Pillow.txt) remain. No generated/downloaded sprite, external API/key, renderer/actor change or third-party implementation was introduced.
