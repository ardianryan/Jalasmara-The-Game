# NW daily authored eight-frame upper proposal

Root viewed the actual [daily NW source-specific endpoints](overnight-nw-daily-upper-rig.md) from `7ee9d75`, accepted them as a bounded art proposal and authorized this CPU loop. New [tool](../../tools/player-gait/nw-daily-upper-loop.py), [spec](../../tools/player-gait/nw-daily-upper-loop.json) and [tests](../../tools/player-gait/nw-daily-upper-loop-test.py) reuse that daily rig's original cutouts/affine operations. No explorer mask, source repair, joint, atlas, runtime, Lower, gear or Gemini other-ten-set audit is modified. Loop image/APNG review by root remains pending; source anatomy and natural walk are not accepted.

## SourceFrame4 stays separate from authored phase

The source remains original daily NW WALK4, crop `(512,640,640,716)` of original daily atlas SHA `342724d1724490279cd0f65c0340c5b35cdf366ecc36a99af716c51f751b8fc3`. Reference upper RGBA SHA `23448a1a3dff4da1a1ab60badbee97480eac3441c18b4c90ddb0736485d66ba7`. The loop pins daily rig spec `df6c92dde91d4fb8df712f6dd72a7ef4306e77948db41cb90e737fde8e0ee068`. **Authoring frame0 is not runtime/contact phase4**. Original frame4 supplies source pixels and cuts only; it does not establish locomotion timing or source physical side.

The original head/body/source ownership remains unchanged. The source-specific rig decisions are carried explicitly into the loop manifest and `nw-daily-upper-source-decisions.png`:

- AUTHORED LEFT elbow design revision from `(57,59)` to `(60,59)`, a three-pixel axis change that closed the first rigid-cut cavity. It is not a measured source joint. All other authored anchors remain unchanged.
- Eleven AUTHORED hidden shirt fills using eleven owned original daily NW4 same-row cloth donors. Exact destination/donor/RGBA records remain, neutral source rest still reconstructs byte-for-byte.
- Five original dark hand-edge ownership decisions at `(57,64),(58,64),(57,65),(58,65),(58,66)`, with original RGBA preserved. Their coordinates/colors are separately recorded, not silently folded into a palette classifier. No new loop repair/output pixels are added.

The source audit's anatomical side remains unknown, wrist/grip null. The stable AUTHORED rig calls visible chainA LEFT and chainB RIGHT. Wrist design anchors are authored, not recovered wrist creases or gear grips. The original bandana tail/head from frame4 is kept byte-exact; earlier NW0 crop-tip provenance is recorded separately in the endpoint report, not erased or transplanted here. Gear stays zero new nodes/pixels and no extra shirt mesh.

## Motion envelope and still review

Shoulders, head and body stay fixed; RIGHT stays behind the torso. For independent authored `t = frame/8`, LEFT fore angle is `14 + 14*cos(2πt)` degrees, RIGHT is `-10 + 10*cos(2πt)`. Frame0 has LEFT28°/RIGHT0°; frame4 has LEFT0°/RIGHT−20°. Each chain is compared against its own neutral and authored wrist anchor; hand screen-X does not establish physical side or contact. All matrices are rigid, share authored elbows and stay within the reviewed endpoint range.

Eight timed frames contain **five distinct raster poses** because the return retraces the same angles. This is an elbow-swing proposal with fixed shoulders, not a complete upper-body walk or a repaired original NW animation atlas. The100 ms/frame APNG is an art preview cadence only. No final validated Lower/contact publisher, displacement, stop, turn, terrain or grip/gear mechanism is connected.

Shelter independently viewed v1 eight-detail and separated extremes: the original square cavity stays closed through all eight shown cuff/forearm poses, no broad gray cloth flap or removed hand spur returns, and fixed head/shirt/pants anchor stays consistent. Counterpart opposition is readable. Remaining lower-left body edge is the stable original contour, not a new detached fragment. V2 images retain these exact pixels and add a source-decisions sheet/manifest fields. This is still-image peer review, not proof of anatomy, temporal/native smoothness, contact phase or runtime behavior.

## Actual verification

```sh
python3 tools/player-gait/nw-daily-upper-loop-test.py
python3 tools/player-gait/nw-daily-upper-rig-test.py
python3 -m py_compile tools/player-gait/nw-daily-upper-loop.py tools/player-gait/nw-daily-upper-loop-test.py
python3 tools/player-gait/nw-daily-upper-loop.py --output artifacts/player-gait/nw-daily-upper-loop-fresh
```

**9/9 loop tests and 10/10 rig tests PASS**, `py_compile` and `git diff --check` PASS. Loop checks retain the original neutral source/ownership, body/head/palette and fixed garment anchors; verify one connected arm in every frame and rigid shared hinges without stretch; require authored counterpart opposition with source/contact unknown; verify `frame8 == frame0`, wrap bounds and actual APNG eight-frame decode against generated rasters; reject wrong outfit/view/sourceFrame, source pin, depth, new shoulder/motion, invented source wrist/contact, sourceFrame-to-contact claims, added pixels/gear or invalid cadence; check source/spec immutability/runtime output refusal; and read the actual output manifest to verify originalSourceFrame4 versus authoringFrame0–7, all11 fills, the explicit three-pixel pivot revision and five exact hand-edge RGBA records. Tests do not turn alpha connectivity into anatomical quality.

Adjacent changed-pixel counts including wrap are `100,198,198,98,98,198,198,100`; frame7→0 has100 changed pixels against198 maximum elsewhere. Its authored wrist-anchor displacement also remains inside other adjacent steps. Body below y43 stays one486-texel component. Isolated LEFT counts are `203,204,206,209,210,209,206,204`, RIGHT `124,124,125,123,122,123,125,124`; each is one eight-connected component. Pixel count variation is nearest rigid sampling/overlap, not bone scaling. Original neutral remains210/124 and byte-exact. No Godot/GPU/native/browser, device/performance capture or runtime export ran.

## Final ignored evidence

`artifacts/player-gait/nw-daily-upper-loop-v2/` under `/Users/ardianryan/Documents/Jalasmara-overnight-ground-consumers`; v1 remains preserved. Loop spec SHA `47391daa904a3956c0da827ea952fad4193aea87335ab8138c8dae97f96afbc2`.

| File                                     |  Bytes | SHA256                                                             |
| ---------------------------------------- | -----: | ------------------------------------------------------------------ |
| `nw-daily-upper-eight-strip.png`         | 15,175 | `c4c0f0db7cdba106d23faa30ffe4bb0fecc3f461b5dbf75f18dbf24a0ad52c10` |
| `nw-daily-upper-eight-detail.png`        | 24,743 | `fba15bf6d0a3a99b8a5fe3f58923db1d563e342d129ac27250510f38b63b2393` |
| `nw-daily-upper-extremes.png`            | 19,822 | `0d5e234b1e4340c86bc9bc2708cfb1e8f7faab87225cbe5087bf306ddb41c7e7` |
| `nw-daily-upper-authored-anchors.png`    | 23,784 | `ad904cf523be1a68705525de7c6d9b511379a9846fd87ce8fe1143bca6d999c3` |
| `nw-daily-upper-wrap-7-0.png`            | 10,679 | `b4a0b0b14ee3b1c24c09de0396c832268e01edfd3a043062bf382c54cfa8e1e0` |
| `nw-daily-upper-source-decisions.png`    | 11,335 | `f081d7ea4004cb9483b9adc5f98373e6bbc4429053dc98a5b5819eea047a23a2` |
| `nw-daily-upper-loop-preview.png` (APNG) | 15,870 | `6429a938628dd62a24e6c4a47553d499f6deef03af1cdbe0963461c700b13795` |
| `manifest.json`                          | 38,870 | `288d7e5626dfb2e406dd06d379629780f367469d023161e104ca9075803b6b43` |

Next is root review of all eight outlines, isolated arms, wrap and APNG, with the sourceFrame/contact distinction retained. Full natural walking, shoulder/depth revisions, stops/turns and final contact/gear integration remain independent. Parent owns integration/handoff updates.

Actual tools: local Python/Pillow, original daily project PNG/JSON, existing daily rig/affine/pixel-run helpers, CPU image inspection/APNG decode and Git. New loop code/decisions are original project work. Original-art terms and [Pillow notice](../../tools/player-gait/LICENSE-Pillow.txt) remain. No external sprite/API key, third-party runtime or other identity/outfit source audit used.
