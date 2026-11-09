# NW explorer source-specific ownership and two authored endpoints

CPU authoring candidate on the [coherent NW0 arrangement](overnight-nw-explorer-orientation-proposal.md), not a replacement for the defective original explorer WALK atlas. New [spec](../../tools/player-gait/nw-explorer-upper-rig.json), [tool](../../tools/player-gait/nw-explorer-upper-rig.py) and [tests](../../tools/player-gait/nw-explorer-upper-rig-test.py) partition the original reference pixels and propose a rig. No atlas, runtime, Lower, gear, other identity/outfit or Gemini audit output changed. An eight-frame cycle is deliberately pending root/peer outline review.

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

The first source-boundary refinement correctly failed the neutral reconstruction guard when the body envelope extended into the far arm's x73 skin column: placing the far chain behind that newly filled column concealed its original edge. The contour was narrowed explicitly to x<73; the guard was retained. Alpha within the final intended body contour is fully opaque. The body below head cutoff has one535-texel eight-neighbor component. This verifies source coverage, not garment anatomy.

Endpoint0 is the exact neutral reference. Endpoint1 holds shoulders fixed, rotates the near forearm/hand+32° around its authored elbow and far forearm/hand−24°. The far/right chain remains behind the body in both poses. Fore and upper transforms share the elbow coordinate; all transforms are rigid determinant+1, without mirror/stretch/recolor. Near/far depth is an authored proposal and is not a measured walking swing phase.

Shelter viewed the actual v3 ownership/body, two-endpoint and isolated-arm sheets. Vest/belt stayed coherent; no broad cloth flap or obvious bright old arm remnant remained on the body. **Known visual limitation:** the near/LEFT forward elbow has a visibly square inward notch just below the cuff. It is connected in the still, but connectivity does not establish a smooth anatomical contour. The far/right source chain is extremely narrow because of occlusion. These points remain visual authoring review, not silently converted into passing anatomy. Final v4 pixels match v3; later work adds tests/provenance and prunes unused donors.

## Actual checks and evidence

```sh
python3 tools/player-gait/nw-explorer-upper-rig-test.py
python3 -m py_compile tools/player-gait/nw-explorer-upper-rig.py tools/player-gait/nw-explorer-upper-rig-test.py
python3 tools/player-gait/nw-explorer-upper-rig.py --output artifacts/player-gait/nw-explorer-upper-rig-fresh
```

**8/8 CPU tests PASS**; `py_compile` and `git diff --check` PASS. Tests cover one original owner/RGBA per texel; exact reference rest; no detached body/arm alpha islands and no intended-body alpha holes; all eight same-row/garment repair records; fixed garment versus moving sleeve ownership; unknown source measurements versus authored joint convention; unchanged head/palette; shared rigid elbows; rejecting wrong scope/source, changed/duplicate boundary, invented wrist, corrupt donor or duplicate vest flag; original source/input immutability; runtime output refusal. These tests do not accept the square elbow contour, depth, anatomical side mapping, wrist/grip or natural motion.

Actual components below y43: neutral LEFT239, RIGHT80; authored endpoint LEFT234, RIGHT80, each one eight-connected component. The five-pixel near-arm raster count change comes from nearest-neighbor rigid rotation overlap, not bone length scaling. Body component535 is unchanged. No GPU/native/browser, physics/contact, performance or runtime export ran.

Ignored final directory: `artifacts/player-gait/nw-explorer-upper-rig-draft-v4/`; earlier v1–v3 remain preserved.

| File                                     |  Bytes | SHA256                                                             |
| ---------------------------------------- | -----: | ------------------------------------------------------------------ |
| `nw-explorer-ownership-and-body.png`     | 17,908 | `41c6effc217d04bc2dd4acb704dfb20735e3a77cbfc0cfd3e6c62c170432a80d` |
| `nw-explorer-two-endpoints.png`          | 22,415 | `530fd598b69f8542e5eea0e8786cbea094a9db249be916d406e4cc407fc27564` |
| `nw-explorer-isolated-arm-endpoints.png` | 10,761 | `36ed6771848019aa171e030d26f0c7d409b68de7baf89f557d4d5cf980fc4bf6` |
| `manifest.json`                          | 27,966 | `1171fe25ec4434f8be30ac049d1b3050fcccdeb514930d98a19d4bd1f029d0c9` |

Spec SHA `7e579d21dc3ef204fd8b7870cf53095fff538903e831bb9241054a35d01a06b0`. Manifest records the reference arrangement pin, source versus authored convention, exact original arm/garment runs,41 source-boundary records, eight hidden fills, authored matrices/joints, components and zero-new-gear contract.

Next: root/character review body continuity, the near-elbow notch and the proposed side/depth convention before an eight-frame NW cycle. Any contour improvement must have explicit authored/source provenance and preserve neutral reconstruction; do not fake a measured wrist or fill the hidden far arm without authored labeling. Stops/turns, gear sockets, full NW WALK replacement and final Lower contact coupling remain pending. No other10-set Gemini source is read or edited.

Tools actually used: local Python/Pillow, original project PNG/JSON, CPU rigid raster authoring, image/source inspection and Git. New code/arrangement and hidden garment/joint proposals are original project work. Original-art terms and [Pillow notice](../../tools/player-gait/LICENSE-Pillow.txt) remain. No generated/downloaded sprite, external API/key, renderer/actor change or third-party implementation was introduced.
