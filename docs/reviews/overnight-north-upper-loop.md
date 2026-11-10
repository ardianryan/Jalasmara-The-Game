# NORTH daily/explorer authored loops: offline art proposals

## Integrator verification, 10 November 07.48 WIB

Root independently ran the shared 9-test loop suite and 10-test rig suite, plus Python compilation. Regenerated output at `artifacts/player-gait/north-upper-loop-root-review` matches all 28 submitted PNG/APNG files byte-for-byte. Root viewed each outfit's actual eight-pose detail sheet. Daily APNG SHA256 is `87d88108c99c6d6972fce9018ca80c272b7bf304da1790d7a2792e997769835a`; explorer is `2b35dd6c08de2c2105c9dcf90ed517fe4b1fb80f3428c2f11e244e0330a6cbda`. The shared tests are counted once, not twice per outfit. Both CPU suites are registered in GitLab configuration; registration is not an executed CI result. This is offline art acceptance only, with no runtime, Lower/contact-phase or gear integration.

Root viewed both final v8 [NORTH source-specific endpoints](overnight-north-upper-rig.md) from `1cfb73c` and authorized bounded eight-frame proposals for both outfits. New [tool](../../tools/player-gait/north-upper-loop.py), [spec](../../tools/player-gait/north-upper-loop.json) and [tests](../../tools/player-gait/north-upper-loop-test.py) reuse that original rig's source-specific masks/affine operations. **No atlas, runtime, actor, Lower, gear or Gemini other-ten-set audit is changed.** This package is ready for root loop/APNG review, not accepted anatomy or natural walking. No new direction will start without assignment. Parent owns integration, gallery and handoff updates.

## Preserved separate source contracts

Both rigs still use their own original NORTH WALK0 crop `(0,768,128,844)`. Original sourceFrame0 supplies pixels/cuts; authoring frame0 is not an accepted runtime/contact event. Rig spec SHA `c24e0b705116c1f1e49642abf68739804a455fc5f8609882f46bb5d4ec6415d7`. The output manifest carries all original daily/explorer WALK/IDLE atlas pins and each case's exact source runs/upper/head hashes. Original upper RGBA SHA: daily `156396e8b7b9f0036f9bb77bb3c10aebb2a879550918ceb1c739e75ce8e317a1`; explorer `b7eda57868162b06237723645a026cc24f641fda36cfd5917bf180f897b262b5`.

Each outfit keeps its own source masks, authored anchors, fixed clothing, original head/palette and exact neutral reconstruction. No mask is transferred between outfits or directions. Existing generic affine/pixel operations are reused, with no new geometric implementation. Preserved rig decisions remain explicit:

- Source anatomical sides, wrist and grip remain unknown/null; LEFT/A and RIGHT/B are stable AUTHORED rear-view rig names. Wrist design anchors are not measured source joints or sockets. Contact phase stays null.
- All four daily and three explorer **AMBIGUOUS** original inner-hand/garment boundary records stay on the fixed remainder, with exact original RGBA/status. They do not become proven pants/vest anatomy or rotate with the fist.
- The authored LEFT elbow revision `(52,61)→(54,61)` remains recorded. It is an authoring choice, not a recovered joint center.
- Zero hidden body/garment fill is added or inherited: both original fixed torso contours remain opaque. Explorer alone retains its separately labelled single AUTHORED fore-root copy at original upper-owned `(55,59)=[140,103,73,255]`. Source ownership remains exclusive upper; the duplicate hidden surface is separate. No additional loop repair pixel is authored.
- Gear remains zero new pixels/nodes with no duplicate garment mesh. Original source clothing is not made into a new gear layer.

## Motion, preview and limitations

For each outfit's independent authoring phase `t = frame/8`, LEFT fore angle is `12 + 12*cos(2πt)` degrees and RIGHT is `9 - 9*cos(2πt)`. Shoulders/head/body stay fixed; RIGHT remains behind the torso. Frame0 has LEFT24° outward and RIGHT0°; frame4 has LEFT0° and RIGHT18° inward. Bend amounts oppose, within the separately reviewed endpoint range. This does not establish anatomical forward/back swing, source physical side or contact phase.

Each outfit has **eight timed frames and five unique raster poses**: the return retraces the same elbow angles. The100 ms/frame APNG is an art preview cadence only. These are fixed-shoulder elbow-swing proposals, not a complete upper walk or natural/coupled locomotion. No distance, terrain, final validated Lower/contact publisher, stop/turn, dynamic depth or wrist/grip/gear coupling is consumed.

Shelter independently viewed actual v1 eight-detail and extremes for both outfits: cuff/fore roots stay visibly closed across all eight shown poses; the daily moving neutral-gray tab does not return, and explorer does not carry a conspicuous vest flap with its hand. Fixed shoulders/torso anchors stay stable, opposing amounts read clearly and no new detached pixel block is observed. All seven boundaries remain semantically ambiguous. This is CPU still-image review only; temporal/native smoothness, anatomy and phase remain unproved. Final v3 uses the same raster pixels; the last code change rejects unsupported outfit input before indexing its case. Root APNG/loop acceptance remains pending.

## Actual checks

```sh
python3 tools/player-gait/north-upper-loop-test.py
python3 tools/player-gait/north-upper-rig-test.py
python3 -m py_compile tools/player-gait/north-upper-loop.py tools/player-gait/north-upper-loop-test.py
python3 tools/player-gait/north-upper-loop.py --output artifacts/player-gait/north-upper-loop-fresh
```

**9/9 loop and 10/10 rig CPU tests PASS**; `py_compile` and `git diff --check` PASS. The loop suite checks both outfits' separate exclusive source ownership/exact neutral; fixed original body/head/palette/torso coverage over all16 composited frames; all seven fixed ambiguous RGBA records and existing single-overlap contract; connected isolated arms and rigid shared hinges without stretch; authored opposing amounts versus unknown source anatomy/contact; original sourceFrame versus authoringFrame distinction; exact `frame8 == frame0`, five unique rasters and bounded wrap/anchor changes; actual eight-frame decode for both APNGs byte-for-byte; manifest pins/masks/joint revision/boundaries/zero-body-fill/gear provenance; source/spec immutability/runtime output refusal; rejecting wrong outfit/view/pin/frame/count, new shoulder/depth/motion, invented source wrist/contact claim, new output/gear pixels or invalid cadence. These checks do not convert connectivity or rigid matrices into anatomical quality.

| Outfit   | Adjacent changed pixels, including frame7→0 | Wrap / maximum other step |
| -------- | ------------------------------------------- | ------------------------- |
| Daily    | 60,137,128,56,56,128,137,60                 | 60 / 137                  |
| Explorer | 72,170,162,68,68,162,170,72                 | 72 / 170                  |

Authored wrist-anchor wrap steps also remain within other adjacent steps. Daily body below y43 remains one629-texel component, explorer one609. Isolated arm raster counts across frames:

| Outfit / chain | Original neutral | Loop frames0–7                  |
| -------------- | ---------------: | ------------------------------- |
| Daily LEFT     |              193 | 185,186,190,193,193,193,190,186 |
| Daily RIGHT    |              173 | 173,173,173,173,171,173,173,173 |
| Explorer LEFT  |              179 | 177,178,177,179,179,179,177,178 |
| Explorer RIGHT |              175 | 175,175,175,174,178,174,175,175 |

Each is one eight-connected component; count differences are rigid nearest sampling/overlap, not bone scaling. No new generation/test failure occurred in this loop package; earlier rig draft failures remain in the source-specific endpoint report. No GPU/Godot/native/browser, device/performance capture or runtime export ran.

## Reproducible final evidence

Final ignored output `artifacts/player-gait/north-upper-loop-v3/` under `/Users/ardianryan/Documents/Jalasmara-overnight-ground-consumers`; v1/v2 remain preserved. Spec SHA `d7e4a51bb3a69d0ec5ca9defbd6afb517bd821a256f50e7fc77c9a75bfbd2c24`.

| File                                           |  Bytes | SHA256                                                             |
| ---------------------------------------------- | -----: | ------------------------------------------------------------------ |
| `daily-north-upper-eight-strip.png`            | 12,602 | `22718ce7e5ddb08b782db982c74d81f868276e1c7efb5b4653e2420cd9e6c3de` |
| `daily-north-upper-eight-detail.png`           | 21,692 | `728e2f9b5fdbe53c72db1f0c1b344fa0b7193bdad7add041c97e5b27a50ddc34` |
| `daily-north-upper-extremes.png`               | 20,607 | `aa8b1d54ebd76d2c2201bda99ca74c7d69975f0351e6ea4829a737373305e179` |
| `daily-north-upper-authored-anchors.png`       | 22,567 | `0317948fd1b06e72d69967dd915e6ed18f1dffb0555cc1e10b1dea4f2caa5d32` |
| `daily-north-upper-wrap-7-0.png`               | 10,494 | `c770de10f6dd59e7f2dbe55f83b89888827a4a3445646e6c33baee969e651d6b` |
| `daily-north-upper-loop-preview.png` (APNG)    | 13,229 | `87d88108c99c6d6972fce9018ca80c272b7bf304da1790d7a2792e997769835a` |
| `explorer-north-upper-eight-strip.png`         | 13,679 | `ac4c1d503db759527951659b594975cd7c3d7b9b75b19fafc4b5cab8931404a3` |
| `explorer-north-upper-eight-detail.png`        | 23,090 | `6e284c35a3224e523a1d54f7919cd4164e4df45c8f3309206514d282ad518174` |
| `explorer-north-upper-extremes.png`            | 21,487 | `cde0f95a5a4974a6db6d80e559813caeb1c8d1242583bc16d4d9d186a14eba73` |
| `explorer-north-upper-authored-anchors.png`    | 23,726 | `0c657138e67b1b8cdd0855d5924bc57ca9eb4a1d9b37a95695c04982c1559ec2` |
| `explorer-north-upper-wrap-7-0.png`            | 10,996 | `92c2ec1a2a27e87d994b0d91e16d19e47ad3cb2a0f918748feb04cce04471cac` |
| `explorer-north-upper-loop-preview.png` (APNG) | 15,537 | `2b35dd6c08de2c2105c9dcf90ed517fe4b1fb80f3428c2f11e244e0330a6cbda` |
| `manifest.json`                                | 89,687 | `cbc1ed432100b494d50519104de3f9634877e629461ab0aa0b999fa6afbf9c87` |

Next is root review/reproduction and gallery/report integration. No new direction will be authored without assignment. Complete natural motion, shoulder/depth revisions and final Lower/contact/gear coupling remain separate. Actual tools: local Python/Pillow, original daily/explorer project PNG/JSON, existing NORTH rig/affine/pixel-run helpers, CPU image inspection/APNG decode and Git. New loop decisions/code are original project work. Original-art terms and [Pillow notice](../../tools/player-gait/LICENSE-Pillow.txt) remain. No external sprite/API key, third-party runtime or other identity/outfit audit used.
