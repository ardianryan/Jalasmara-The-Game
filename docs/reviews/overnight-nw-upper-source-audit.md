# NW upper source audit: explorer walk orientation mismatch

**Source defect confirmed visually:** the original explorer WALK row5 labeled `north_west` shows a rear-right head/ear/shoulder, while explorer IDLE column5 and daily WALK/IDLE NW show rear-left. Root independently viewed both canonical eight-view comparisons and confirmed the mismatch. Explorer WALK row7 also shows rear-right, so an automatic row5/7 swap or mirroring is not an acceptable fix.

This is a bounded CPU/source inventory, not a repaired atlas or anatomical/contact acceptance. New [tool](../../tools/player-gait/nw-upper-source-audit.py), [spec](../../tools/player-gait/nw-upper-source-audit.json) and [tests](../../tools/player-gait/nw-upper-source-audit-test.py) preserve original pixels, explicit unknown sides and source provenance. No runtime, atlas, Lower annotation, actor, gear or GPU state changed.

## Original evidence and canonical layout

Canonical order in the original manifest/preparation tools is `east, south_east, south, south_west, west, north_west, north, north_east`. NW is WALK row5 (y640), IDLE column5. The audit reads eight original128×76 NW upper crops per outfit, plus all eight WALK frame0 and IDLE views for comparison. It does not infer heading from a manifest label alone.

| Source        | SHA256                                                             |
| ------------- | ------------------------------------------------------------------ |
| Daily WALK    | `342724d1724490279cd0f65c0340c5b35cdf366ecc36a99af716c51f751b8fc3` |
| Daily IDLE    | `6b5e6f8b3bf19acbd5dbfe1a84429894d2f4de4fd985dc16c024a6bf1f44c054` |
| Explorer WALK | `a429c378400bd5ac60a45124ac48672b4cb1360beb379cc83297b52ea48ae3b9` |
| Explorer IDLE | `68fad4626665bb75f41c61c8e950091f3f927428ca0e81090fffa6834c411f3f` |

Paths are the existing `client-godot/resources/art/player-gait/male-nusantara-{daily,explorer}-{walk,idle}-8way-v1.png`. The source manifest and `prepare_outfit.py`/`prepare_idle_outfits.py` establish layout and normalization, not that every painted viewpoint is correct. Canonical comparison also shows limited E/SE and SW/W angular distinction; that observation is documented, not expanded into an unrelated repair.

In daily NW's eight frames, the rear torso and head continue facing screen-left while hands change screen position. Explorer NW's eight WALK frames instead keep the head/ear/shoulder toward screen-right; its corresponding IDLE has screen-left rear orientation. Explorer clothing changes and the opposite-facing head make a daily anatomical side convention unsafe to reuse.

## Frame0/4 boundary inventory, full8 review and unknown hands

The two full8 sheets expose hand/forearm silhouettes, short-sleeve caps, daily back-shirt contour and explorer vest/belt boundaries. Enlarged frame0/4 regions separately inspect the visible sleeve, a large arm/hand area and a secondary-hand area. The12 rectangles record exact original crop RGBA hashes and opaque source pixel runs. They **can overlap and include nearby garment/outline**, so they are inspection patches, not complete segmented limb masks or exclusive ownership.

No opaque back-hand texel is relabeled as a palm surface, wrist or grip center. Rear-view skin can be palm, back of hand or forearm. The audit deliberately keeps `anatomicalSide:unknown`, wristnull and gripnull for every frame/patch. Daily frame0's visible arm crosses toward the lower screen-right; at frame4 the large hand reaches screen-left. Screen-left/right ordering therefore does not establish stable physical limb identity across the cycle.

There is a possible **future authored convention**, not source proof: in a repaired coherent rear-left NW pose, assign an upper chain above authored Lower LEFT hip x59 and another above RIGHT hip x70, then verify actual anatomical source/pose intent with character/root. This can establish a new authored skeleton consistently; it cannot retroactively prove which source hand was physical LEFT. Explorer's mismatched WALK orientation must be repaired or replaced by a separately authored NW source before this convention can be evaluated. No such upper mapping is implemented here.

## Existing Lower annotations read as data

Read-only inspection used `annotate_lower_body.py`, `upper_arm_annotations.json` and the two existing `player-lower-body/male-nusantara-{daily,explorer}-v1.json` files in the character worktree. Lower uses the **IDLE** source, NW column5, upperCutY76, authored LEFT hip `(59,76)` and RIGHT `(70,76)`, with `occludedReuse:false` for NW. The spec pins the exact inspected JSON SHA and NW records:

- Daily Lower JSON `f46253f21b32fc5e4ff027c4dce5e36c9be317ade6feffb1a7174fd1774b8d48`.
- Explorer Lower JSON `2da32a0cfec23794965cd5592bc7fc1d2db550f46d5c3d02452461c44a2d7169`.

These are existing authored labels/data, **not upper-side verification, published physical contact phase or Lower acceptance**. The current upper-arm source annotations still list NW among unverified views. A Lower idle leg label cannot identify upper hand sides in an opposite-facing WALK image. No phase offset, parity rule, wrist/grip or mesh attachment was inferred.

## Actual checks and output

```sh
python3 tools/player-gait/nw-upper-source-audit-test.py
python3 -m py_compile tools/player-gait/nw-upper-source-audit.py tools/player-gait/nw-upper-source-audit-test.py
python3 tools/player-gait/nw-upper-source-audit.py --output artifacts/player-gait/nw-upper-source-audit-fresh
```

**5/5 CPU tests PASS**, `py_compile` and `git diff --check` PASS. Tests compare all16 crops byte-for-byte with original row5; require eight distinct source crops per outfit without treating uniqueness as gait proof; verify12 exact patch hashes/opaque runs and unknown socket fields; reject wrong row/view/source/frame/invented side/wrist; preserve the inspected idle Lower data without adding an upper mapping; and guard source input/runtime output. No engine/native/browser/physics/performance test ran.

Ignored final evidence directory: `artifacts/player-gait/nw-upper-source-audit-v2/`. Initial coordinate-grid inspection remains separately under `nw-upper-source-inspect-v1/`.

| File                                           |  Bytes | SHA256                                                             |
| ---------------------------------------------- | -----: | ------------------------------------------------------------------ |
| `daily-canonical-eight-views-walk-idle.png`    | 91,419 | `29b7dd4090e75b63fd1963ff90dd945cfd74d7f19785fa780e7fce509771b86b` |
| `explorer-canonical-eight-views-walk-idle.png` | 96,467 | `76dabb25ddf9578719a8c8f3264374964648e0adc70b9d3b5672d7073e913997` |
| `daily-nw-eight-upper.png`                     | 52,690 | `c781d3f59fd642174cb44c8cb90f1d9f4f2d07d12f8da7da64e463430201618d` |
| `explorer-nw-eight-upper.png`                  | 54,649 | `a63bc6599585b2e3691d741e81fd1aa487f042b5aada1d43f4b1ee2afad05297` |
| `nw-frame0-4-source-boundary-regions.png`      | 32,654 | `9a9695105a0277da0920995e0b0b229b6c3d85bf263ecadfb445dcbaaeac78f9` |
| `manifest.json`                                | 27,614 | `ec7af54a50df9aabe451846cb673c0c7d88d2001559a7ce3b9b10431e47f20e2` |

Manifest includes every original upper crop hash, source/tool/spec pins, exact patch records, orientation findings and the read-only Lower data snapshot. Original upper PNGs are also retained for independent source pixel inspection. The tool refuses overwriting prior evidence or writing under runtime resources.

## Next bounded authoring proposal

Root authorized an original explorer NW upper repair after this inventory. Use original daily NW identity/head orientation and original explorer NW IDLE garment as **references**, with explicitly AUTHORED new arrangement/pixels/masks where necessary. Keep it in a separate proposal/output and report original versus authored coverage. Do not present this as recovered hidden art, silently swap row5/7, mirror the atlas, transfer SOUTH viewer-right labels, or modify Lower/runtime/gear to conceal the mismatch. First review a source-complete coherent rear-left body/head and two endpoints before a full loop or contact coupling.

Tools actually used: local Python/Pillow, original project PNG/JSON, source/manifest inspection and Git. No generator/API key, downloaded art, GPU/browser, engine, atlas replacement or third-party implementation was used. Original-art terms and [Pillow notice](../../tools/player-gait/LICENSE-Pillow.txt) remain. New audit code/arrangement is original project work.
