# Swept original-foot stair path: independent CPU peer

Read-only review of the character lane's `model_stair_swept_support.py`, using the actual7e14c09 FIRST3 central failure. No runtime edits, Godot, browser, guard changes or gait acceptance. The physical rig remains OFF. This model is an alternative free-foot path for the fresh RIGHT72→96 step; LEFT remains genuinely planted84.

The model derives the actual84/96riser world lines from `central_stone_steps` and the original NW right shoe's62opaque corners/sole markers. With current identity Q and zero C, original corners have no negative vertical offset below sole `[5.5,4]`. Each waypoint raises the sole to the next tread before its leading original corner crosses that riser, retaining the frozen96landing. The resulting knots are:

- `(1374.95,-1462.864,72)`.
- `(1374.801694,-1457.907010,84)`.
- `(1374.271204,-1440.175851,96)`.
- `(1373.889,-1427.401,96)`.

Polyline XYZ length47.1816415688 parameterizes the moving foot with the existing cubic progress and original3sin lift. The certificate `(1.5*Lxyz+3π)/D` bounds speed even where the polyline tangent changes, because position stays continuous and each segment's arc progress has that bounded speed. **D and all anatomical/continuity guards still use accepted ACTOR worldXY**, not the foot's XYZ length. The84waypoint is not an additional RIGHT contact. Body transfer remains the recorded72→84 policy; no new torso trajectory, lower landing, extra toe height or source-pixel stretch is introduced in this comparison.

I reran the CPU model with additional in-memory measurements of horizontal outer-reach rejection and actual post-common-pelvis outer distance. The character source was not edited. All10,000phases per tested duration retain the original source bones and shared pelvis correction:

| Accepted actorXY duration | Certified speed | Maximum drop px | Minimum inner slack world | Result in frozen model |
| --- | ---: | ---: | ---: | --- |
|16|5.01233|7.17138|9.12340|Speed certificate fails|
|16.25|4.93521|7.38862|9.12339|Speed certificate fails|
|16.5|4.86044|7.61166|9.01176|Conditional geometry fits|
|16.75|4.78789|7.84075|8.65207|Conditional geometry fits|
|17.730957|4.52301|8.80373|7.89490|Original pelvis/outer reach fails|

No horizontal separation reaches the conservative outer radius in either conditional passing case. Their actual post-pelvis outer excess is at most1.07e−14world numerical roundoff. At the nominal full-tread duration17.730957, actual outer excess is0.6181516world, confirming that nominal cadence remains incompatible with this frozen stance/body trajectory even though speed is valid. A shorter duration changes contact cadence and requires explicit integration review; these results do not authorize quietly replacing the nominal step distance.

The source draft initially derived a pelvis drop using `sqrt(max(.001,outer²-horizontal²))` and checked inner slack without explicit horizontal/actual-outer rejection. I flagged that proof gap; the author added the horizontal and post-pelvis outer checks. The independent instrumentation found no hidden outer failure in16.5/16.75, so this was a model completeness issue rather than evidence that those two cases fail.

## Remaining proof gates

- The current model proves sampled **nonpenetration**, with gap≥−0.02, and allows zero gap at the final grounded endpoint. The real free-foot guard requires+0.02clearance. At tiny nonterminal phases the3sin contribution can be below0.02; existing floor stitching/full-original-mask clearance must be modeled and verified separately. No tolerance relaxation or airborne acceptance is implied by a nonnegative gap.
- Frozen NW/source/Qidentity/C0 is not changing-view, stopped/resumed or rotating-foot coverage. Another Q can place original corners below the sole; center-height waypoints alone then do not establish clearance.
- Other stairs, actual DOWN anatomy, mixed physics timing, stop/restart, real controller/root movement and the whole16case matrix remain unproved. The reversed path comparison is geometry only and says so.
- Native torso, leg bend, cadence and upper-arm opposition still require visual review. A CPU annulus fit does not establish natural walking.

The author and root received these constraints before runtime adoption. Own diagnostic output `.runtime/peer-stair-swept-support-7e14c09.json` SHA256 `4b5f41028c710006fa859f4cd5531e6b09a2d94c9a9a285f01b70f9abe390b38`. Current character model source readback SHA256 `1ade87972e916f6ba60b0b74bc400c0beb94e4b12551f18332bcf68b5dab9dc5`; it was still a CPU candidate at this checkpoint. Existing original atlas and world hashes remain in the model output. No artwork or library attribution changed.
