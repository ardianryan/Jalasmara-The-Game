# SOUTH daily upper-body loop candidate

CPU-only original authoring proposal based on the corrected [v7 ownership](overnight-south-upper-ownership.md), commits `3e70b5f` and `ef9be46`. New [loop tool](../../tools/player-gait/south-upper-loop.py), [spec](../../tools/player-gait/south-upper-loop.json) and [tests](../../tools/player-gait/south-upper-loop-test.py) are separate from the original atlas and runtime. They render eight upper crops, not new full-body gait frames. No actor, Lower, FootPlant, CharacterVisual, gear, scene, contact producer or default flag changed.

## Source and authored data

The source is original `male_nusantara` daily SOUTH frame0, row2, 128×76 upper crop. Atlas SHA remains `342724d1724490279cd0f65c0340c5b35cdf366ecc36a99af716c51f751b8fc3`. The tool refuses other outfits, views, source frames, frame counts or a changed v7 ownership spec (SHA `0d7481aabf52fbd61b2db02130d2d89f1dc7adc91abf69a83c7068f316183639`). This does not author the other seven views or the explorer outfit.

Original source RGBA stays in its segment under rigid nearest-neighbor transforms. Head y<43 is byte-identical in every frame. All output colors belong to the original source palette. The body plate stays fixed, including the separately documented 93 **authored hidden body texels** from v7. The 11 reviewed original teal-cloth texels remain on the torso and are excluded from every moving source arm mask.

The shoulder/elbow/wrist design anchors are **AUTHORED**, not measured original joints:

| Anatomical side             | Shoulder | Elbow | Wrist design anchor |
| --------------------------- | -------- | ----- | ------------------- |
| LEFT, viewer-right in SOUTH | 76,49    | 79,58 | 76,61               |
| RIGHT, viewer-left in SOUTH | 53,49    | 51,57 | 49,63               |

Upper segments rotate about authored shoulders; forearm and palm share one rigid transform about the corresponding elbow. The two transforms agree on the elbow coordinate. That is a mathematical attachment check, **not anatomical validation**. Original palm marks `(74,62)` left and `(49,65)` right are projected separately for motion review; they remain representative skin texels, not wrist/grip centers. Grip stays null, and original32 palm records retain their ambiguous wrists.

## The eight-frame motion proposal

For independent authored phase `p = frame/8`, shoulder angles are LEFT `−3 sin(2πp)` degrees and RIGHT `+3 sin(2πp)` degrees. Relative forearm angles are LEFT `−30 −25 cos(2πp)` and RIGHT `−35 −30 cos(2πp)` degrees. These ranges and pivot locations are explicit design choices.

The first probe used the opposite RIGHT cosine sign. Peer review correctly found both hands low at frame0 and both higher at frame4. That probe is retained and not accepted. The revised cycle visibly opposes the hands: at frame0, LEFT source palm projects to `(79.409,64.390)` and RIGHT to `(57.405,62.194)`; at frame4, LEFT is `(74.368,62.421)` and RIGHT `(49.705,65.144)`. These are authored projections, not proof the palm is unoccluded in the composite.

Depth ordering is fixed across all eight samples: LEFT arm behind the torso, RIGHT in front. There is no discrete side/depth switch at frame7→0. This prevents a new ordering pop, but dynamic occlusion and front/back swing remain unproved. The preview APNG uses 100ms per frame for review only. No foot contact, walking distance, movement speed, stop/turn or runtime timing consumes that phase.

## Six original boundary texels and the raster seam

Peer review identified six dark/brown texels left on the body-only viewer-left edge: `(54,59),(55,59),(54,60),(55,62),(55,63),(55,64)`. The source color alone cannot prove their anatomy. For this loop **only**, they are explicitly proposed as RIGHT forearm boundary ownership, with exact source RGBA in the spec. They lie outside the intended neutral-shirt contour and next to original forearm pixels. The v7 source spec itself is unchanged.

This is an authored ownership choice, not recovered anatomy or a color classifier. Original pixels are retained, not erased/recolored. Recombining the extended source arms at original rest over the body remains byte-exact. Inside-shirt cloth cannot be reassigned through this path; wrong RGBA, duplicates and already arm-owned pixels are rejected.

Before that reassignment, nearest-neighbor rotation detached the original dark outline texel `(55,61)` in four RIGHT-arm samples. Probe v1 tried four one-pixel authored output bridges. The final proposal needs **no new output pixels**: the six explicit original boundary texels maintain one eight-connected arm component in every sample. The unused bridge implementation was removed. This topology test does not prove a correct elbow, wrist silhouette or muscle shape.

Shelter viewed the actual v2 strip, extremes and seam panels: hands now oppose, the previous teal flap stays gone, the six dark texels read as a narrow arm edge, and no clear new cloth flap or joint detachment was found in those stills. Their anatomical ownership and full gait acceptance remain open. Final v5 artwork matches those reviewed v2 pixels; later revisions only add provenance, annotated joint overlays, checks and APNG output.

## Cycle and source checks

Actual commands:

```sh
python3 tools/player-gait/south-upper-loop-test.py
python3 tools/player-gait/south-upper-ownership-test.py
python3 tools/player-gait/south-upper-anchors-test.py
python3 -m py_compile tools/player-gait/south-upper-loop.py tools/player-gait/south-upper-loop-test.py
python3 tools/player-gait/south-upper-loop.py --output artifacts/player-gait/south-upper-loop-fresh
```

**9/9 loop, 10/10 ownership and 7/7 palm CPU tests PASS.** `py_compile` and `git diff --check` pass. The actual exported APNG was independently reopened: eight frames, 100ms duration each, every decoded RGBA byte equal to its corresponding exported frame PNG.

Checks cover source scope/pins; eight distinct frames; unchanged head/body/palette; fixed original cloth ownership; source rest reconstruction after the six explicit assignments; unit/orthogonal/determinant+1 transforms; shared elbow positions; null grip/unmapped contact; actual source-palm opposition; connected arm masks; rejecting corrupted/duplicate/inside-shirt assignments; output guards and unmodified spec input.

Frame8 wraps to frame0 byte-for-byte, rather than exporting a duplicated ninth frame. Frame7→0 changes 178 RGBA texels; the other adjacent changes are 163, 224, 213, 138, 142, 190 and 207. The seam is within the cycle's observed changes. Authored wrist-anchor step across7→0 is 1.045px LEFT and0.620px RIGHT, below other steps (max1.502/2.543px). These are bounded discontinuity diagnostics, not motion-quality thresholds or a smooth/native gait claim.

## Review files and provenance

Ignored output: `artifacts/player-gait/south-upper-loop-candidate-v5/`. Earlier probes v1–v4 remain preserved. The tool only writes to a fresh directory under ignored `artifacts/` and refuses overwriting a review or writing to runtime paths.

| File                                               |  Bytes | SHA256                                                             |
| -------------------------------------------------- | -----: | ------------------------------------------------------------------ |
| `south-daily-upper-eight-strip.png`                | 18,826 | `8e71cf7ae9dfd11d173c13e38d37457b9510df768d43016f36bf5fdbe83cb944` |
| `south-daily-upper-eight-detail.png`               | 27,302 | `6c9669ba365cf7f30de57274f6a47238abba4d8e7032bba80816e194bf932702` |
| `south-daily-upper-extremes-and-separate-arms.png` | 21,379 | `73ecd6b836bddb88cabe3755441e355c9d6a4cdcb34f2e8b486080b8630bfaf3` |
| `south-daily-upper-authored-joints.png`            | 26,708 | `19e5abc3099335a07815d7ea854b7499bfbe2cad21031c2fbe1ed4238d0ccaea` |
| `south-daily-upper-wrap-7-0.png`                   | 12,736 | `919b0cb534cdcc20e45d76c480c7c20be99e8cd6805c5fe524dda92351a5ef84` |
| `south-daily-upper-loop-preview.png` (APNG)        | 15,673 | `0247e364733e4e5db951094e90fb16a600ffbbf6f5de8418b24ee8b8c288dbb3` |
| `manifest.json`                                    | 42,889 | `26dab1f15bd182560e0d32b50a7810d08d88535c2120ca6559287da4f12527a6` |

Loop spec SHA `0b7c001996bcd56d8623d1b6add6c4872b8c2a06054df84cc062f631f0c8f3d0`. Manifest also pins source upper RGBA, tool/ownership helper, all per-frame matrices, authored joints, original palm projections, six source boundary assignments and component diagnostics.

Next: root/character review the actual eight-frame art and APNG, particularly small shoulder/elbow silhouette shifts, fixed depth/hand occlusion and original dark edges. Any further edits stay in original authoring data until accepted. Runtime/native cadence, stopping/turns, gear sockets and coupling to the final validated Lower contact publisher are separate pending work. This package cannot be called natural walking, an eight-direction solution or a released game change.

Actual tools: local Python/Pillow, original PNG/JSON, CPU affine raster rendering, image inspection and Git. New code and authored arrangement are original project work; original-art terms and [Pillow notice](../../tools/player-gait/LICENSE-Pillow.txt) remain. No image generator, external API, downloaded sprite, GPU/browser, engine, runtime export or source-atlas replacement was used.
