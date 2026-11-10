# NORTH daily/explorer: source inventory and two endpoint proposals

CPU/source-only authoring in new [tool](../../tools/player-gait/north-upper-rig.py), [spec](../../tools/player-gait/north-upper-rig.json) and [tests](../../tools/player-gait/north-upper-rig-test.py). **Both two-endpoint rigs are art proposals awaiting root image review**, not accepted source anatomy, a complete walk or runtime adoption. No NORTH loop is made. No original atlas, actor, Lower, gear or Gemini other-ten-set audit is modified. Parent owns handoff/integration updates.

## Original eight frames versus idle

The tool reads only male_nusantara daily/explorer WALK and IDLE originals. NORTH is WALK row6 (`y768`) and IDLE column6 (`x768`), without mirroring, remapping or rearranging the head/body. Both outfits' original WALK0–7 have a coherent straight rear-facing head/body composition. Their original IDLE also reads rear-facing; WALK/IDLE head/garment contours differ, but no NW-like opposite-facing conflict is observed in these sheets. This is visual source review, not an automatic orientation classifier or a claim that the original motion is natural.

Direct **original NORTH WALK0** is selected separately for each outfit because both arm surfaces are continuously visible from sleeve to hand. Neither needs a head transplant or a hidden proximal-chain substitution. The complete upper crop is `(0,768,128,844)`; source head rows0–42 remain untouched. Original hand surface may be palm or back of hand: no palm-center, wrist crease or grip is inferred.

| Original atlas | File SHA256                                                        |
| -------------- | ------------------------------------------------------------------ |
| daily WALK     | `342724d1724490279cd0f65c0340c5b35cdf366ecc36a99af716c51f751b8fc3` |
| daily IDLE     | `6b5e6f8b3bf19acbd5dbfe1a84429894d2f4de4fd985dc16c024a6bf1f44c054` |
| explorer WALK  | `a429c378400bd5ac60a45124ac48672b4cb1360beb379cc83297b52ea48ae3b9` |
| explorer IDLE  | `68fad4626665bb75f41c61c8e950091f3f927428ca0e81090fffa6834c411f3f` |

Original NORTH0 upper RGBA SHA: daily `156396e8b7b9f0036f9bb77bb3c10aebb2a879550918ceb1c739e75ce8e317a1`; explorer `b7eda57868162b06237723645a026cc24f641fda36cfd5917bf180f897b262b5`. Manifest records all16 original WALK-frame RGBA hashes/bboxes, both IDLE hashes, source pins and four per-outfit source inspection regions with exact patch hashes. These rectangular regions may mix garment/skin/outline; they are not limb masks or measured joints.

## Source-specific ownership and explicit uncertainty

Each outfit has independently traced per-row cap/upper/fore/hand masks. Daily and explorer source runs and authored anchors differ; neither imports SOUTH/NW masks, original body repairs or source joints. Only existing generic affine/polygon/pixel-run helper operations are reused. Every original opaque source texel has exactly one source owner; fixed shirt/vest/belt/remainder keep original RGBA.

| Source part                           | Daily original texels | Explorer original texels |
| ------------------------------------- | --------------------: | -----------------------: |
| LEFT/A cap / upper / fore / hand      |     70 / 44 / 36 / 43 |        47 / 31 / 42 / 59 |
| RIGHT/B cap / upper / fore / hand     |     58 / 44 / 35 / 36 |        48 / 31 / 36 / 60 |
| Fixed shirt / vest / belt / remainder |     412 / 0 / 0 / 638 |       5 / 443 / 90 / 513 |

Original anatomical sides, wrists and grips remain **unknown/null**. The new direct-rear rig calls screen-left chainA LEFT and screen-right chainB RIGHT as an explicit **AUTHORED naming convention**, not a transferred NW side rule or measured source identity. All shoulder/elbow/wrist design anchors below are authored, not recovered articulation centers or gear sockets. Contact phase stays null; no Lower/contact data is consumed.

| Outfit / authored chain | Shoulder | Elbow | Wrist design anchor |
| ----------------------- | -------- | ----- | ------------------- |
| Daily LEFT/A            | 53,49    | 54,61 | 50,68               |
| Daily RIGHT/B           | 75,49    | 76,61 | 77,68               |
| Explorer LEFT/A         | 53,49    | 54,61 | 51,68               |
| Explorer RIGHT/B        | 76,49    | 76,61 | 78,68               |

There is **zero hidden body/garment fill**: lateral source arm removal leaves a complete opaque intended torso contour. The original torso need not be expanded or repaired to pass the proposal. Fixed plates below y43 have one629-texel daily component and one609-texel explorer component. This is source coverage/alpha topology, not anatomical proof.

Initial mask drafts left seven original daily shoulder-outline texels and explorer outer-hand outlines on the plate. These were segmentation-draft omissions, not original atlas defects. The source coordinates/RGBA were retained and assigned to their adjacent cap/hand: daily `(51,43),(51,44),(50,45..47),(49,48..49)`; explorer `(49,59)` to upper plus left `x47,y68..71` and right `x81,y68..71` to hands. No source pixel is deleted or recolored.

### Ambiguous inner hand/garment boundaries: conservative fixed ownership

Peer original-eight-frame context showed persistent daily cargo/pants-side shapes when hands lift. The first draft made neutral-gray pixels travel with the fist; a posed tab was visible. The final proposal reserves these source pixels on the fixed remainder, preserving colors and uncertainty:

| Outfit   | Original pixel | Original RGBA   |
| -------- | -------------- | --------------- |
| Daily    | 53,66          | 137,116,98,255  |
| Daily    | 53,67          | 130,110,92,255  |
| Daily    | 74,66          | 115,116,109,255 |
| Daily    | 74,67          | 99,101,96,255   |
| Explorer | 54,69          | 58,53,38,255    |
| Explorer | 54,70          | 77,64,45,255    |
| Explorer | 74,70          | 60,48,35,255    |

Every record is marked **AMBIGUOUS**, not proven garment/finger anatomy. Three daily and three explorer pixels moved from arm ownership back to the fixed remainder; daily74,67 was already fixed. No palette threshold classified them. Shelter traced daily74,66 to output72,65 and daily53,66/67 to the moving left tab in the first draft. After the plate-first probe, they viewed actual v6 isolated arms: daily gray/tan tabs are absent, cuffs/hands stay visually connected and explorer has no clear new hole/tab. The source semantics remain uncertain despite the cleaner bounded contour.

## Two endpoints, first cut failure and one authored overlap

Neutral reconstructs each complete original source byte-for-byte. The second endpoint keeps shoulders fixed and rotates LEFT fore/hand+24° outward and RIGHT+18° inward around their authored elbows; RIGHT is behind the body. These are named **A-outward/B-inward**, not recovered forward/back or contralateral contact phases. They are pose proposals, not an eight-frame cycle or a complete upper walk.

The initial LEFT design pivot `(52,61)` was revised to `(54,61)` for each outfit after a retained original-mask x51–56 pivot probe. This two-pixel axis revision is an authoring choice, not a measured source joint. Daily then has no additional joint-surface repair. Explorer still had one actual alpha gap at output `(55,60)`: inverse sampling requires original `(55,59)=[140,103,73,255]`, which is owned by the static upper. A single **AUTHORED hidden fore-root overlap copy** at that same coordinate fills that one output alpha gap. Original exclusive ownership remains upper; the separate duplicate hidden surface is explicitly recorded. No existing opaque pixel is recolored, and source masks/body/head/matrices/neutral stay unchanged. The before/after patch sheet and regression preserve the original-cut gap. This is independently authored NORTH source coverage, not a copied NW overlap mask.

Shelter's v6 view confirms the moving gray tab is gone and no new detached block is visible; this is still-image peer evidence only. Root's two-endpoint visual review is pending. Fine contour, anatomy, source physical sides, wrist/grip, dynamic depth, stops/turns, natural gait and final contact coupling remain unproved. No clothing is added as a mesh or gear node.

## Actual CPU checks and retained failures

```sh
python3 tools/player-gait/north-upper-rig-test.py
python3 -m py_compile tools/player-gait/north-upper-rig.py tools/player-gait/north-upper-rig-test.py
python3 tools/player-gait/north-upper-rig.py --output artifacts/player-gait/north-upper-rig-fresh
```

**10/10 CPU tests PASS**; `py_compile` and `git diff --check` PASS. Tests verify original eight WALK crops/IDLE extraction with no remap, source pins, per-outfit exclusive ownership/rest, differing masks/joints, complete fixed torso contours and original edge assignment, all seven ambiguous fixed RGBA records, unchanged original head/palette/clothing anchors, connected rigid arm endpoints with shared elbows/no scaling, unknown source anatomy/zero-gear contract, exact single-overlap gap versus original-cut predecessor, actual export frame/patch/provenance manifest, input/source immutability and runtime destination refusal. Wrong view/row/path/hash/frame, invented wrist/contact, duplicate/head mask, changed ambiguous/overlap RGBA, new garment mesh, off-source joint and nonfinite motion are rejected. Alpha connectivity does not establish anatomical quality.

Draft generation correctly rejected an out-of-scope garment polygon before row43 and duplicate original ownership rows during the plate-first adjustment. Guards were retained; corrected source rows are explicit. V2/v4 show earlier mask/tab evidence; v5 was rejected before export because of the duplicate-row guard. A first temporary Python contact-sheet path expression and an initial test-file syntax typo also failed before producing accepted evidence; both were corrected before the final test run. These are authoring/test failures, not runtime game failures. No GPU/Godot/native/browser, performance benchmark or runtime export ran.

Actual isolated arm components: daily neutral LEFT193/RIGHT173, endpoint LEFT185/RIGHT171; explorer neutral LEFT179/RIGHT175, endpoint LEFT177/RIGHT178, each one eight-connected component. Counts vary under rigid nearest sampling/overlap, not bone scaling.

## Final ignored evidence

Final output `artifacts/player-gait/north-upper-rig-v8/` in `/Users/ardianryan/Documents/Jalasmara-overnight-ground-consumers`. Earlier drafts and original/pivot/overlap probes remain preserved. Spec SHA `c24e0b705116c1f1e49642abf68739804a455fc5f8609882f46bb5d4ec6415d7`.

| File                                           |  Bytes | SHA256                                                             |
| ---------------------------------------------- | -----: | ------------------------------------------------------------------ |
| `daily-north-eight-walk-idle.png`              | 53,391 | `4231995d294c0afe4511dfb9dcf65167f4709c5502b4769b0aabea41d73a85d4` |
| `explorer-north-eight-walk-idle.png`           | 56,024 | `96e2a68cfb2e91b7ff617754f5e4f82d33ea6430a863716c32b4e2a9785b49a3` |
| `daily-north-two-endpoints.png`                | 16,628 | `f1e2ff5f88b4836b147bf4ae6f612110e3af05a2ca19f03fb9476e50bb09249a` |
| `explorer-north-two-endpoints.png`             | 17,590 | `85aa7bd5a6f6a342228681c3264c2fc31e6655c6fada740e1cf492c230da10b1` |
| `daily-north-isolated-arms.png`                |  9,940 | `dd9a638bfeb89180fd37e010cde7c1fb90d0c3cb7aaaf97be58186081a6c9b4e` |
| `explorer-north-isolated-arms.png`             | 10,061 | `60cbc366b8e4ab61a4092c9affd8bae5d0646817942fc8bec37f77635fdf7afb` |
| `explorer-north-overlap-before-after.png`      |  3,867 | `8b115d754ef0ad50679ba0901c8ba4b9ae6eb571b2529b40a1f564b7daafaf1a` |
| `daily-north0-original-coordinate-grid.png`    | 25,311 | `1e5527b7ff723d0a746d264683b61b5121f4b940c1c46e31c97f207fcced1445` |
| `explorer-north0-original-coordinate-grid.png` | 26,218 | `52ae550524ccad46c86ca2c3165b19111f1d63b67ce86c76d76571a9c085d6da` |
| `manifest.json`                                | 44,719 | `8448bfa68cec4180edf1665948b54c50a4af48fcc7e88b262e0acdcc694a18fd` |

Original ownership/body sheets are also emitted: daily SHA `3e909ccd97d524017c11297cb93e672bb4358118e05003e719db7c73ecc59be7`, explorer SHA `26c8751c537a8678686dc41dc87eb452f92931355ad6877a5ca0ca67b74f9ddb`.

Next is root image review of both source-specific two-endpoint/body/isolated-arm proposals before any NORTH loop. Only then may subsequent authored poses be considered; current sourceFrame0 is not an accepted contact phase. Actual tools: local Python/Pillow, original project PNG/JSON, generic existing affine/polygon/pixel-run helpers, CPU original-image inspection and Git. New code/masks/joints/one hidden-overlap decision are original project work; original-art terms and [Pillow notice](../../tools/player-gait/LICENSE-Pillow.txt) remain. No API key, downloaded/generated sprite, external runtime or other identity/outfit audit used.
