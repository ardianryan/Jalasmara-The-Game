# NW explorer authored upper loop: offline candidate

New original authoring proposal using the [source-specific NW rig](overnight-nw-explorer-upper-rig.md) from `c5431a8` and its two-texel elbow overlap repair `0b42a60`. Root viewed the actual final v6 before/after and accepted that bounded repair as an **art proposal**, then authorized this eight-frame CPU loop. New [tool](../../tools/player-gait/nw-explorer-upper-loop.py), [spec](../../tools/player-gait/nw-explorer-upper-loop.json) and [tests](../../tools/player-gait/nw-explorer-upper-loop-test.py) produce ignored review outputs. Nothing is wired into an atlas, actor, renderer, Lower, contact publisher or gear. Gemini's other ten source sets/worktree are untouched.

## Original source and authored scope

The reference is still an explicitly **AUTHORED arrangement**: original daily NW WALK0 head rows0–42 and original explorer NW IDLE column5 body rows43–75. It does not recover the wrong-facing explorer NW WALK row. Reference RGBA SHA `d7fff8ddae2d283a269411dd68ea1590707726c64f0c0e13de19a1de4e2ad95a`; rig spec SHA `22fc470fe9f6132a3bba87c29cc2ac9048db8596b8fb0e8af3089655fe448cf0`. Original atlas pins are copied into the output manifest, with the exclusive source arm/garment pixel runs, 41 manual source-boundary decisions, eight authored hidden garment fills and the two separately labelled hidden fore-root overlaps at `(55,58),(56,58)`. No new mask, source transfer, repair, palette color, pivot or output-pixel patch is added by the loop.

Original source anatomical sides remain **unknown**, source wrist/grip remain null. The stable new rig convention names visible chainA LEFT and occluded chainB RIGHT, by the previously proposed authored rear-view skeleton. It is not a measured anatomical mapping or a new inference from hand screen-X. Shoulder/elbow/wrist design anchors remain AUTHORED; gear sockets are not inferred from those anchors. All original texels still have one source owner; the two authored overlap copies remain a separate nonexclusive hidden surface, not original forearm ownership.

## Cyclic poses and current visual limits

The loop holds shoulders, body and head fixed. For independent authoring phase `t = frame/8`, LEFT fore rotation is `16 + 16*cos(2πt)` degrees and RIGHT is `-12 + 12*cos(2πt)`. This stays within the repaired endpoint envelopes. Frame0 has A/LEFT32° and B/RIGHT0°; frame4 has A/LEFT0° and B/RIGHT−24°. Each chain's bend magnitude changes opposite the other, and their transformed wrist design anchors move up/down in opposition relative to their own neutral coordinates. RIGHT remains behind the torso throughout. The original narrow far arm is not secretly expanded or reconstructed.

There are **eight timed frames and five distinct raster poses**: the return half retraces the same elbow angles. This is a bounded elbow-swing proposal with fixed shoulders, not a complete upper-body walk. The 100 ms/frame APNG is review cadence only; it is unrelated to accepted contact timing, distance, stops or turns. No Lower contact events are consumed. Anatomical motion, dynamic near/far depth, grip/gear coupling and native/gameplay smoothness are unproved.

Shelter independently viewed the actual v1 eight-detail and isolated-extreme sheets. The prior square inward A-elbow notch remains closed in all eight shown rasters; no broad teal/vest flap, detached cuff/fore block or new concrete blocking gap was observed. Fixed vest/belt/head base stays consistent; endpoint opposition reads as A-forward/B-neutral versus A-neutral/B-back. Small rotated pixel ledges remain, and the occluded B chain stays narrow. This is still-image peer review, not temporal/anatomical/contact acceptance. Final v2 uses the same image pixels; it adds complete source pins to the manifest. Root's loop/APNG review remains pending.

## Actual CPU checks

```sh
python3 tools/player-gait/nw-explorer-upper-loop-test.py
python3 tools/player-gait/nw-explorer-upper-rig-test.py
python3 -m py_compile tools/player-gait/nw-explorer-upper-loop.py tools/player-gait/nw-explorer-upper-loop-test.py
python3 tools/player-gait/nw-explorer-upper-loop.py --output artifacts/player-gait/nw-explorer-upper-loop-fresh
```

**9/9 loop tests and 10/10 rig tests PASS**; `py_compile` and `git diff --check` PASS. The loop tests verify exact original neutral reconstruction and exclusive source ownership; unchanged source/specs/body/head/palette; all intended body pixels opaque; original garment anchors fixed and absent from moving arms; one connected isolated arm in every frame; rigid shared elbow without stretching; separately authored counterphase and unknown source anatomy/contact; exact `frame8 == frame0`; bounded wrap changes and wrist-design-anchor displacement; rejecting wrong scope/pin/depth/motion/invented measurement/new pixels/gear; runtime destination refusal; and actual eight-frame APNG decode byte-for-byte against generated rasters. These checks do not turn alpha connectivity into anatomical quality.

Adjacent changed-pixel counts including wrap are `116,193,192,118,118,192,193,116`. Frame7→0 has116 changed pixels, within the existing193 maximum; its anchor step is also within other adjacent steps. Body below y43 stays one535-texel component. Isolated arm pixel counts across frames: LEFT `237,241,239,240,239,240,239,241`; RIGHT `80,80,81,79,80,79,81,80`. Raster count variation is from rigid nearest sampling/overlap, not limb scaling. Original neutral remains byte-exact. No engine/GPU/native/browser, physical-device performance or runtime export was run.

## Reproducible evidence

Final ignored directory: `artifacts/player-gait/nw-explorer-upper-loop-v2/` in `/Users/ardianryan/Documents/Jalasmara-overnight-ground-consumers`. Earlier v1 remains preserved. Spec SHA `73420907e9398f2c7bcd8a96143465ead7efefff72de6358888e790a39593174`.

| File                                        |  Bytes | SHA256                                                             |
| ------------------------------------------- | -----: | ------------------------------------------------------------------ |
| `nw-explorer-upper-eight-strip.png`         | 14,580 | `fac9606ccd1afb342251534aec804f72dc3b4ff8dd1f2570d27337486829aa76` |
| `nw-explorer-upper-eight-detail.png`        | 22,866 | `e39e6ea64259bb1428864edb759a2a91b8da174cd81ba382cf619b810c06c912` |
| `nw-explorer-upper-extremes.png`            | 19,595 | `56ccf57efcce9033cba5d14cc791c0c899c823153ae19e08d5cb2a6c08364974` |
| `nw-explorer-upper-authored-anchors.png`    | 23,133 | `eb6bb102ace00f0b4d21b9b47c1ef9dc5fde026e8b888d7ebe85f31500bccafb` |
| `nw-explorer-upper-wrap-7-0.png`            |  9,946 | `503be6d17cfe22cc767407863fb04b4f0bc238b4967c9ad07f7ed8013ef0f030` |
| `nw-explorer-upper-loop-preview.png` (APNG) | 16,437 | `d4864e59e4693cfeff8c6668bf2375d0faac76a6fb09b03dc1c7eb78ccfb555e` |
| `manifest.json`                             | 51,457 | `f33ae8ebe98b06a83fa4b1b71125577ea8e79a5a5b1dc3861406a76403f775e0` |

Next: root reviews all eight outlines, extreme separation, wrap and APNG. Any future shoulder/garment/depth revision needs its own explicit authoring provenance; current fixed-shoulder loop is not silently widened. Complete NW source-walk repair and final validated Lower coupling stay separate. Parent owns handoff/integration updates.

Tools actually used: local Python/Pillow, original project PNG/JSON, existing rigid polygon/affine helpers, CPU image inspection, APNG decode and Git. New code/loop decisions are original project work. Existing original-art terms and [Pillow notice](../../tools/player-gait/LICENSE-Pillow.txt) remain. No downloaded/generated sprite, API key, upstream implementation, third-party runtime or other identity/outfit audit was used.
