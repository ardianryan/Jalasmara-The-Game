# Central stair resume: captured trailing-stance reach peer

CPU/source/artifact review of character candidate `ced9a6d`. No Godot, browser, runtime edits, altered guard or new duration constant. The full16 run completed its first two dock cases, then rejected central normal ascent. Earlier targeted central passes do not establish this combined runtime result.

## Captured failure and independent reconstruction

Evidence directory in the character worktree: `artifacts/godot/nala-terrain-full16-restart-body-preview-ced9a6d/`. Check125 rejects at logical root `(1370,758.618225097656)`: requested pelvis drop8.58855529494517px exceeds8. Body and requested artwork both NW, baseline72; the left foot is free at phase14.96044921875/17.73095703125 toward actual tread84, while the right foot remains genuinely planted on72. This is an unfinished stair settlement resume, outside the descending-ramp restart preview.

The last accepted root is `(1370,759.951538085938)`. Its right ankle is `(1375.30322265625,-1463.21704101562,75.6623229980469)` and its measured hipXY is `(1374.24267578125,-1444.89929199219)`. Advance that hip by the next accepted worldXY distance1.18212890625 along this captured straight local span. Restore its pre-pelvis hipZ from actual baseline72 plus28 times reciprocal calibration1.22077456956372. Using source segment lengths14.6492948532104 and13.4285202026367, and the existing conservative reach subtraction0.1, yields:

| Quantity | Independent CPU value |
| --- | ---: |
| Right hip/ankle horizontal separation |19.5286968061world|
| Required vertical pelvis decrease |10.4846915970world|
| Required decrease in source pixels |8.58855669045px|
| Actual rejected decrease |8.58855529495px|

The reconstruction identifies the **grounded trailing right leg**, not the nearly landed free left leg, as the limiting outer reach. At the same frozen body/view/support geometry the8px boundary occurs near left phase14.1939469, approximately0.7665023accepted world units before rejection. This is a local captured-span calculation, not proof for the entire route, source-view transitions or another duration.

## Why the resumed landing is delayed

Before stopping, the left foot was already free on a legitimate next-tread trajectory. Zero-motion settling raised the baseline to72 while that foot remained free. Resume reanchors from its actual raw sole at `(1369.545,-1468.843,85.07488)` toward the next actual landing `(1366.464,-1445.132,84)`, logical `(1366.464,765)`. The remaining physical XY path is23.9102001190186world. It has not made an84 contact yet.

`NalaFootPlant._begin` currently calls `_terrain_duration` with the **entire new tread depth**17.73095703125 as its minimum even for this unfinished resume. The remaining raw vertical change is only−1.07488world. Independently executing the existing curve derivative/curvature equations gives certified bound2.32048023 at that duration. Starting the same bounded duration search from the already established `_start_distance`10 gives bound4.11443352, with a dense20,001-point derivative check4.10322081, below the unchanged4.9 curve budget. This does not prove the actual ankle5× limit, Q/C continuity, full-mask clearance, both annuli or final contact.

A bounded stair-resume-only choice of the existing starting minimum, followed by the existing retained-target curve budget, is therefore causally justified for testing. It must preserve the frozen next-tread destination, actual60→72→84 contact order and contact truth. It is not a new global10 constant and must not change fresh full-tread movement. Lengthening this free swing would hold the trailing72 stance still longer. Raising the current72 body baseline also worsens that trailing leg's outer reach. Neither a larger pelvis allowance nor an invented contact addresses the recorded cause.

The character author received these numbers before implementing a follow-up. Native torso motion, exact stopped/resumed continuity, the original guards and full16 completion remain required. No runtime success is claimed here.

## Frozen dock helper fixture peer

The separately prepared `scripts/tests/nala-restart-body-budget.gd` and `fixtures/nala-restart-body-b05a211.json` were read without running Godot. The mapping uses the NEW retained flat-landing D10 plan, original paused body14.7888323255851 and rate1.07207590381155. Raw planner soles are reconstructed as rendered soles minus captured C, while actual foot source/Q remains distinct from current BODY-leg metadata. Initial ankle reconstruction is asserted within0.001; helper output is expected11.25 with64 marker inverse requests,32 cached phases and6 tested candidates. No concrete mapping issue was found. This is helper-only replay: the earlier selected dock rerun retained D10 because its paused body was lower, so it is not causal acceptance of the old b05 failure or whole coupled motion.

## Provenance

- `rejected.json` SHA256 `c6a6da718a5cf722faec264b95952aff3f86eef39a2af409b921537cf05978c4`.
- `samples.jsonl` SHA256 `95a39b2f964780a4cdb37a059315bcc2babf35a546716f738b57e13b58a96a53`.
- `source.json` SHA256 `3183bb85210ee03a25283783c21a79b9381616dcf0b4213cf0c5c0c7c18ad2cf`.
- Curve equations read from character `NalaFootPlant._terrain_duration` and its existing offline `model_stair_curve_budget.py`; the latter was imported for pure CPU calculations. No artwork, geometry, server state or runtime source changed.

## Actual frozen helper and first-three follow-up:7e14c09

The character-owned exclusive engine run has now produced actual artifacts, which this peer read without launching an engine. The frozen original-b05 helper run exits0 in2.060877834s with no recorded errors. Original body14.7888323255851, D10 input plan, separate held SOUTH left foot/SE body and immutable flat target are retained. Actual helper selects11.25 with32 cached phases,64 marker inverse requests and6 tested algebra candidates. Its internal elapsed time is7755µs; this one cold fixture value is not a frame-time/device benchmark. `conditionalPreview=true`, `fullMaskProof=false` and `fullRuntimeProof=false` correctly retain the limited claim.

The following unchanged FIRST3 terrain fixture exits1 in7.009707583s. Both normal dock directions complete, then central ascent rejects **later** at root `(1370,743.951782226562)`, body84, requested drop9.0479564921973. The resumed left foot really lands on84 at duration10 with curve bound4.11443367824; its prior fresh-tread minimum no longer causes the old failure. Contact-order evidence observes60→72→84 and leaves96 missing; no completed central or full16 claim is justified.

The new limiting limb is the grounded LEFT84 foot while the RIGHT72→96 swing is at17.9630126953125/20.73095703125. The right target and actual tread remain unchanged. From the prior actual hip/ankle and next1.18200683594world advance, the left horizontal separation is22.1959228516, raw hipZ118.181687948 and planted ankleZ90.103874207. The same original conservative leg reach reproduces9.04795768968px, within0.000002px of rejection. The free right ankle lies near its hip and is not the outer-reach limiter.

At frozen body84/NW the trailing-left8px threshold occurs around swing phase16.9199339. The actual fresh curve needs duration20.730957 to certify4.899675; blindly reducing it to a full tread17.730957 would instead give bound4.929335, above the unchanged4.9 certificate. Thus the resume-only change is causally supported, but a global shorter-duration change is not. Current torso baseline rises72→84 by phase12.0527 while the next96 foot is still free. At the single rejected pose, baseline≤82.72068 would satisfy the existing8px bound with the same feet; this is a conditional pose witness, not a viable temporal body trajectory, natural crouch or new lower-height policy. Both original annuli, actual body rate, clearance and later contact must constrain any follow-up.

- Frozen-helper results SHA256 `56c8c76d2cc3ae752504008363ba5ee2586aacf3d72b2d988d0ab867d9125cbb`.
- Later FIRST3 rejection SHA256 `f54fe4bd530822c4ab75591d4383273f6c54b8df2a89969d0703f5b0ad508648`.
- Character command/log records preserve exits, source7e14c09 and the explicit central reach error. No source guard changed in this peer.

## Independent current-shadow stair-policy counterexample

The character author next proposed testing current-foot shadow ground as the body target, as used for the ramp. I independently replayed the frozen fresh RIGHT72→96 curve through landing with20,000distance subdivisions, original NW right62unique opaque corners/sole markers, identity Q and the actual stair contact embedding. For this authored connector the inverse is `logicalY=(worldY+537*tan55)/(-1/cos55+0.6*tan55)`; actual shadow height is the discrete tread beneath that logical point, not continuous linear elevation. Body starts72, targets the minimum of this current right footprint and the genuine left84support, and remains limited to1world per accepted unit. No future96contact is invented.

The replay ends at body81.9498228271 and trailing-left required drop10.973191445px. Character's separate model ends81.95086/drop10.97361; the small difference is numerical sampling. At the same terminal feet/root the original8px bound permits body baseline≤78.3202263206, leaving3.6295965world too much ascent under the proposed shadow rule. The original left stance horizontal distance is24.9638672. This is a concrete conditional counterexample to treating the current-shadow policy alone as a stair fix. It does not establish an alternate torso trajectory or solve the full common-body/inner-annulus interval. The root and character received the result before any new runtime patch. Hard guards and actual contact order remain unchanged.
