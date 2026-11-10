# NW daily source-specific ownership and two endpoints

New offline [tool](../../tools/player-gait/nw-daily-upper-rig.py), [spec](../../tools/player-gait/nw-daily-upper-rig.json) and [tests](../../tools/player-gait/nw-daily-upper-rig-test.py) propose original male_nusantara daily NW upper ownership and two authored endpoints. **Art proposal pending root image review**, not a source atlas/runtime repair, measured anatomy or accepted natural walk. No eight-frame daily loop is made yet. No actor, Lower, gear, atlas or Gemini other-ten-set audit changed. Parent owns integration/handoff updates.

## Direct original daily source and head fragment

Source is **original daily NW WALK frame4**, atlas crop `(512,640,640,716)`, with original head and body arrangement unchanged. Frame4 shows both continuous source arms; NW WALK0 has a large arm crossing near the waist plus a second visible hand whose proximal chain is occluded. Choosing original frame4 avoids filling or importing that hidden source chain. It is explicitly sourceFrame4, not a fabricated neutral frame0 or inferred contact phase. The tool reads only the daily atlas; it reuses generic polygon/affine/pixel-run operations, never explorer masks, body donors, joints or orientation arrangement.

Atlas `male-nusantara-daily-walk-8way-v1.png` SHA `342724d1724490279cd0f65c0340c5b35cdf366ecc36a99af716c51f751b8fc3`. Original NW4 upper RGBA SHA `23448a1a3dff4da1a1ab60badbee97480eac3441c18b4c90ddb0736485d66ba7`. Head rows0–42 and original RGBA remain exact in both endpoints; no mirror/scale/recolor is applied.

The brown fragment seen at the top of the earlier NW upper detail crop is **already in original daily NW WALK0**: `(79,42)=[73,52,43,255]`, `(80,42)=[80,45,36,255]`, `(81,42)=[79,44,36,255]`, atlas y682. Each is directly connected to opaque original row41 above; it is the bandana-tail tip cut by the detail crop. The whole source frame0 head has one627-texel eight-neighbor component. Frame4's original head has one620-texel component and a slightly different original tail endpoint. The new four-panel head/tail sheet compares original0, original4, fixed-body4 and endpoint4; it does not erase/recolor or transplant either head. The previous authored explorer head therefore retained a source feature, not a newly introduced isolated speck.

## Original ownership versus authored design

New source-specific per-row masks partition each original opaque NW4 texel exactly once. Head/remainder and fixed shirt have their own ownership. Original texel counts:

| Part                              | Original opaque texels |
| --------------------------------- | ---------------------: |
| LEFT/A cap / upper / fore / hand  |      58 / 39 / 59 / 54 |
| RIGHT/B cap / upper / fore / hand |      21 / 34 / 32 / 37 |
| Fixed shirt / original remainder  |              286 / 809 |

Source anatomical sides, wrist and grip remain **unknown/null**. The new rig explicitly names visible screen-left chainA LEFT and screen-right chainB RIGHT as an AUTHORED rear-view convention above the proposed hip sides. Hand screen-X does not become a measured side, and no Lower annotation/event is consumed. All shoulder/elbow/wrist coordinates are authored design anchors, not recovered joints or gear sockets:

| Authored chain | Shoulder | Elbow | Wrist design anchor |
| -------------- | -------- | ----- | ------------------- |
| LEFT/A         | 60,50    | 60,59 | 51,65               |
| RIGHT/B        | 76,51    | 78,60 | 80,68               |

Eleven **AUTHORED hidden shirt texels** use eleven exact original daily NW4 same-row owned-shirt donors. They cover nine collar/shoulder cut pixels at x63,y45–53 plus `(63,56)` and `(61,61)`. Donor coordinates/RGBA are explicit; no explorer cloth, flat invented palette or full old-arm-area fill is used. Only holes inside the intended body contour are filled. Original neutral reconstruction remains byte-identical because source arm pixels cover these hidden texels. Body below y43 has one486-texel component and no alpha holes inside its intended contour. Source garment/remainder pixels are not duplicated as gear; no extra mesh/node is enabled.

## First failed draft and bounded corrections

V1 neutral reconstruction passed, but actual isolated endpoint review exposed a square inward near-elbow notch and five dark hand-edge pixels left on the fixed plate. These early images remain in `artifacts/player-gait/nw-daily-upper-rig-v1/`; connectivity was never treated as contour acceptance.

The original near-arm first design pivot `(57,59)` and rigid fore cut leave inverse-nearest samples belonging to the static upper at `(60,57),(61,57),(62,56),(60,58),(61,58),(62,57)` uncovered in the bent image. A retained original-mask CPU pivot probe x56–62 at y59 showed the effect. The final **AUTHORED** elbow at `(60,59)` lies on opaque original hinge skin and removes the square cavity without adding overlap/repair pixels or changing the source cuts. This is a disclosed three-pixel authored-axis revision, not a source-measured joint. It changes the authored endpoint but leaves the original neutral/head/body/repair/source ownership exact. No explorer overlap patch is copied.

Five source dark hand-boundary texels are explicitly assigned to LEFT hand: `(57,64)=[51,36,26,255]`, `(58,64)=[48,43,35,255]`, `(57,65)=[51,39,33,255]`, `(58,65)=[51,43,33,255]`, `(58,66)=[61,50,40,255]`. They lie outside the intended shirt contour and adjoin the original hand perimeter. This preserves original RGBA and removes the old plate spur; it is manual semantic ownership, not palette-based anatomical proof. Remaining `(59,67)=[61,53,42,255]` connects to the original body edge and stays untouched; there is no basis for automatic deletion.

Shelter independently verified the six inverse-sampled upper coordinates, all five reassigned original RGBA values, the final one-component486 plate and the unchanged rest. They viewed final v2 endpoint/body sheets: the notch and prior hand spur are gone, no gray cloth transfer was observed, and endpoint/body identity looks coherent. This remains bounded still review; anatomy, grip, gait and contact phase are not proven. V3/v4 keep the same final image pixels, adding bandana provenance and stricter guards.

## Endpoints and actual tests

Neutral is exact original frame4. The second pose keeps shoulders fixed, rotates LEFT fore/hand+28° and RIGHT−20° around their separately authored elbows; RIGHT remains behind the body. Both isolated arms stay connected. Original head and palette are preserved, transforms are rigid determinant+1 with shared elbow coordinates. This is not a full upper walk, dynamic depth change or phase-coupled motion. Source wrist/grip remains unknown even though the new rig has wrist design anchors.

```sh
python3 tools/player-gait/nw-daily-upper-rig-test.py
python3 -m py_compile tools/player-gait/nw-daily-upper-rig.py tools/player-gait/nw-daily-upper-rig-test.py
python3 tools/player-gait/nw-daily-upper-rig.py --output artifacts/player-gait/nw-daily-upper-rig-fresh
```

**10/10 CPU tests PASS**; `py_compile` and `git diff --check` PASS. Tests cover direct source crop and exclusive original ownership/rest, all11 same-row hidden donor records and intended-body coverage, exact five original edge reassignments, untouched remaining body edge/head/palette/garment anchors, connected rigid endpoints/shared elbows, reproducing the initial cut/pivot cavity without changing neutral/body/source, unknown source anatomy versus authored joints/zero-gear contract, rejecting wrong outfit/frame/pins, invented source wrist/contact, duplicate/head mask ownership, corrupt donor, added shirt mesh, off-source anchor and nonfinite motion; actual export original bandana provenance; source/input immutability and runtime output refusal.

Actual arm counts: neutral LEFT210/RIGHT124; endpoint LEFT203/RIGHT122, each one eight-connected component. Raster count differences come from rigid nearest sampling/overlap, not limb scaling. No GPU/Godot/native/browser, stop/turn/contact coupling, performance benchmark or runtime export ran.

## Final reproducible evidence

Final ignored output: `artifacts/player-gait/nw-daily-upper-rig-v4/` in `/Users/ardianryan/Documents/Jalasmara-overnight-ground-consumers`. Original source coordinate grids and first pivot probe remain in `artifacts/player-gait/nw-daily-upper-source-v1/`. Spec SHA `df6c92dde91d4fb8df712f6dd72a7ef4306e77948db41cb90e737fde8e0ee068`.

| File                                  |  Bytes | SHA256                                                             |
| ------------------------------------- | -----: | ------------------------------------------------------------------ |
| `nw-daily-ownership-and-body.png`     | 19,052 | `763d35801d154d9d6d44f445980ea2255fce6dfe01733e3ca78809ef05447a07` |
| `nw-daily-two-endpoints.png`          | 16,951 | `9e28d45815c2909400060d24064c40cec77416a7089815f6b0aa1d18fc400e3e` |
| `nw-daily-isolated-arm-endpoints.png` | 10,483 | `d2fe919ab0d08927cb30586f921fcd8de3b61252cc3ab435ed721e515aeca4c6` |
| `nw-daily-original-bandana-tail.png`  |  8,842 | `6816339eaefdc2971420486647ad5a87906ef4909d3017743a09a4bc79d5ed88` |
| `manifest.json`                       | 16,619 | `38d0799c9e61f0a209abd23b13e6398e73c7e611cc19ccebc0f8cc050d3d30eb` |

Next: root reviews these two endpoints, shirt continuity, side/depth convention and body/head provenance before any daily eight-frame loop. Contact timing, stops/turns, grip sockets and complete natural walking stay separate. Tools actually used: local Python/Pillow, original daily project PNG/JSON, existing affine/pixel-run helpers, CPU source/image inspection and Git. New code/masks/joint/hidden-shirt decisions are original project work; original-art terms and [Pillow notice](../../tools/player-gait/LICENSE-Pillow.txt) remain. No API key, downloaded/generated sprite, third-party runtime or other identity/outfit audit used.
