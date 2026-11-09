# SOUTH arm/torso ownership and authored pose proposal

CPU authoring candidate, not runtime-ready anatomy or natural walking. The [spec](../../tools/player-gait/south-upper-ownership.json), [exporter](../../tools/player-gait/south-upper-ownership.py) and [tests](../../tools/player-gait/south-upper-ownership-test.py) read original SOUTH daily/explorer frames 0/4. No atlas, WEST tool, actor, Lower, CharacterVisual, gear, phase or scene changed. The previous source-only ownership draft is commit `3e70b5f`; this revision addresses root's v5 waist-cavity and v6 moving-cloth findings.

## Original source and ownership

Each original 128×76 upper crop is partitioned into two sleeve/upper-arm, forearm and palm candidates plus the original head/torso remainder. Explicit polygons and daily0 boundary runs intersect only opaque source. Palm→fore→upper priority assigns one owner per texel, with 11 specifically reviewed cloth texels reserved for the torso before every arm mask. Reconstruction is byte-exact in all four cases. Head y<43 and source colors remain unchanged. This proves coverage/provenance, **not anatomical correctness**.

| Outfit/frame | Left upper/fore/palm texels | Right upper/fore/palm texels |
| ------------ | --------------------------- | ---------------------------- |
| daily0       | 114 / 48 / 63               | 83 / 45 / 49                 |
| daily4       | 85 / 51 / 40                | 60 / 41 / 48                 |
| explorer0    | 118 / 40 / 64               | 77 / 42 / 50                 |
| explorer4    | 85 / 45 / 45                | 79 / 42 / 48                 |

All eight reviewed frame 0/4 palm landmarks remain in their correct palm cutouts. Front anatomical left is viewer-right; no near/far mapping or mirror is inferred. Original daily SHA is `342724d1724490279cd0f65c0340c5b35cdf366ecc36a99af716c51f751b8fc3`; explorer SHA is `a429c378400bd5ac60a45124ac48672b4cb1360beb379cc83297b52ea48ae3b9`.

## Rejected drafts and the actual cloth-flap cause

Drafts v1–v3 filled 184 removed-arm texels inside an overly broad envelope. Root rejected the puffy/double-sleeved plate. Drafts v4–v5 reduced that to 54 but over-tapered the right waist, exposing an interior-looking notch in the authored extreme. Those images remain preserved, not accepted as source-complete.

Draft v6 extends the explicit body contour continuously: rows 46–52 x57..73 and rows 53–67 x56..75, inclusive. Rows 66–67 are explicitly authored hidden trouser-waist, not recovered shirt. The original source is opaque throughout this intended body contour, so exact rest reconstruction does not prevent filling it. The highzoom alpha grid records zero intended-body alpha holes. Existing dark original folds remain opaque rather than being mistaken for transparency.

Root and character then found a gray/teal flap below the isolated left hand. A CPU ID-coded source map, transformed with the exact same nearest-neighbor affine matrix as the arm, identified original cloth mistakenly assigned to the palm:

| Extreme output pixel | Original source pixel | Original RGBA  |
| -------------------- | --------------------- | -------------- |
| (73,64)              | (70,58)               | 91,109,107,255 |
| (73,65)              | (69,59)               | 86,106,104,255 |
| (73,67)              | (68,60)               | 82,101,99,255  |
| (74,68)              | (68,62)               | 78,93,89,255   |
| (75,69)              | (68,63)               | 99,116,110,255 |

Shelter independently traced these original texels into the visibly continuous torso cloth. V7 reserves exactly `(70,58),(71,58),(69,59),(70,59),(68,60),(69,60),(70,60),(68,61),(68,62),(68,63),(69,64)` for the original plate. Each spec record pins original RGBA; changed, duplicate, transparent or out-of-scope records are rejected. These are explicit source ownership decisions, not a palette classifier. Returning those 11 original cloth texels reduces authored repair from 104 to 93, without recoloring them.

Dark boundary `(69,61),(69,62),(69,63),(70,65)` and the three dark source texels x74..76/y67 remain arm-owned. They can be hand outline rather than cloth; source color alone does not settle that. Original tan `(76,65)` remains arm-owned. These uncertain edges are visible for review, not silently removed. The v7 isolated-arm image no longer carries the conspicuous teal wedge. Shelter independently viewed the exact v7 image and confirmed the broad flap is gone, with the retained dark pixels reading as a narrow hand perimeter rather than an obvious shirt panel. That bounded peer review does not establish the anatomy of every dark texel; final boundary/anatomy acceptance remains a separate visual decision.

## Explicitly authored torso, joints and pose

The 93 hidden repair texels lie only inside the above body contour and are fully occluded by original source arms at rest. They use 30 original owned-cloth donors on 22 same-source rows, preserving local shading. Five repair texels are tagged `hidden-trouser-waist`. Every destination, donor and exact RGBA is recorded. Outside-contour old skin/cap points `(76,65),(55,57),(55,61),(76,49)` remain alpha in the body-only plate. Point `(75,66)` is now deliberately opaque hidden waist, closing the prior abrupt notch. The verified visible cloth patch `[62,48,68,58]` retains rawRGBA SHA `4b5bea858e140c0ab4b544c5ad76f0e91ac1132bfec4a23bf54d264572fbecc4`.

Other frames are not registered recoveries: daily0 `(74,62)` is skin `[223,165,120,255]`, while daily4 is `[83,96,91,255]`; central visible cloth also differs across frames. No daily4/explorer/idle pixel is substituted into daily0. Original idle SOUTH was inspected only as a contour reference, not copied.

Six anchors remain **AUTHORED design proposals**, not measured source joints: left shoulder/elbow/wrist `(76,49)/(79,58)/(76,61)`; right `(53,49)/(51,57)/(49,63)`. The 32 original palm annotations retain null/ambiguous wrists and unknown grips. No grip axis is inferred from these points.

The two endpoints show original rest and an authored angle extreme. Upper/sleeve segments stay fixed; forearm+palm source cutouts rotate rigidly about authored elbows (left −45°, right −80°). Left is explicitly behind the torso only in this proposed depth arrangement. No mirror, stretch, recoloring or phase claim is introduced. This is seam/ownership review, not a complete articulated cycle, measured contralateral phase, contact acceptance or natural gameplay walking. The other three outfit/frame cases remain ownership inventories and do not inherit the daily0 body/pose.

## Checks and evidence

```sh
python3 tools/player-gait/south-upper-ownership-test.py
python3 tools/player-gait/south-upper-anchors-test.py
python3 -m py_compile tools/player-gait/south-upper-ownership.py tools/player-gait/south-upper-ownership-test.py
python3 tools/player-gait/south-upper-ownership.py --output artifacts/player-gait/south-upper-ownership-fresh
```

Actual CPU results: **10/10 ownership tests and 7/7 original palm tests PASS**. `py_compile` and `git diff --check` pass. Tests cover exact source/one-owner reconstruction; unchanged head/palette/hash; original palm marks; explicit reserved-cloth ownership versus retained hand boundaries; corrupt reservation rejection; 93 same-row donor records and no interior alpha holes; exact rest; and unit/orthogonal/determinant+1 transforms. The first v7 test run correctly failed the obsolete expected repair count104 before the expected count was updated to93 with independent per-coordinate ownership assertions. No native/browser/GPU test ran.

Ignored review directory: `artifacts/player-gait/south-upper-ownership-draft-v7/`. V1–v6 remain preserved.

- `south-daily0-alpha-contour-and-separate-arms.png`, 43,959 bytes; SHA `faf43f3412cfaf8dfaf2aa38d78c255fd185e8d7b49b2dd2ee5679e5d3b594b6`.
- `south-daily0-hidden-cloth-proposal.png`, 27,056 bytes; SHA `cc628a7a18194ea582d3085a1dc4c976b651bc6a61cdf3df60db47ebb4c3fea1`.
- `south-daily0-authored-extremes.png`, 10,646 bytes; SHA `64fa5dcb326489dea6b438f2f574f3faf9bec63628400dc57a59b3cc4fa5a86b`.
- `south-upper-ownership-comparison.png`, 56,940 bytes; SHA `525a31cd36a9a8b78f376e351f3bc011419ed77293d6bb3b265cdbf7fe3172f5`.
- `manifest.json`, 81,695 bytes; SHA `b942f3c573467455ace0b014846709ea5cabe72e33bfcff30a104595a9db1b0e`.
- Spec SHA `0d7481aabf52fbd61b2db02130d2d89f1dc7adc91abf69a83c7068f316183639`.

Diagnostic original source grid: `artifacts/player-gait/south-upper-contour-sources/source-left-hand-ownership-v6.png`; original waist/idle comparison is in the same folder. Manifest pins original sources, spec, exporter/helper, exact source ownership runs, repair provenance and authored transforms. It predates test/report edits, which do not affect rendered pixels.

Next: root and peers inspect the exact v7 separated arm and body contour; refine any remaining source boundary before authoring a full loop. Final validated Lower contacts, anatomical pose/depth and later native gameplay-scale review remain prerequisites for runtime work. No atlas replacement, duplicated torso/gear mesh, actor change or default activation is part of this package.

Tools actually used: local Python/Pillow, original PNG/JSON, CPU affine diagnostic rendering, image inspection and Git. New code/arrangement and authored cloth/joints are original project work. Existing original-art terms and [Pillow notice](../../tools/player-gait/LICENSE-Pillow.txt) remain. No engine/browser, API key, external image, moodboard sprite or third-party implementation was introduced.
