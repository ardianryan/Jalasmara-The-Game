# Frozen stair path: source-view envelope peer

CPU/source review of character `831cf9b`, followed by independent reconstruction of its actual FIRST7 rejection. No engine/browser/GPU or runtime edits in this lane. The prototype remains off; this is not natural-walk or full-terrain acceptance.

## Bounded source gate

`NalaStairSupportCurve.view_envelope` adds a remaining-path condition to the existing current-mask and frozen-landing checks. For an ascending identity-Q swept path it bounds candidate leading extent by `candidateLeading + max(0, riserNormal·C)` and its lowest corner by `candidateMinimumZ + min(0,C.z)`. Those one-sided terms cover the correction decaying toward zero; a favorable negative correction cannot be assumed permanent. They are compared with the original path's frozen leading extent and initial negative vertical correction. Invalid/nonfinite C/Q or a rotated plane is rejected; other curve families retain their prior path. Landing, duration, floor and physical guards are unchanged.

This explains why the earliest EAST→NE handover must be rejected even when the instantaneous compensated leading extent fits: its future uncompensated extent can exceed the EAST path. The gate can visibly hold EAST; it does not establish timely recovery. In particular, held EAST versus NW body is three source-view steps and deliberately falls outside the existing carried-resume eligibility. No eligibility expansion is justified by this review.

The gate iterates opaque corners whereas curve construction also includes direct sole-edge markers. An independent original DAILY check across all8 source views and both feet found every marker within the opaque-corner horizontal bounds and no lower than their bottom extent. Thus those markers do not enlarge the current identity-Q/horizontal-camera-right leading/minimum-Z bounds. This finding is limited to the current DAILY data, not future art or arbitrary rotations.

## Actual FIRST7 failure remains

Character retained `artifacts/godot/nala-terrain-first7-view-envelope-831cf9b/rejected.json` and `samples.jsonl`. The previous future-mask riser failure is no longer the reported rejection. The run now reaches the predicted carried-resume fallback: LEFT uses labelled legacy `stair_clearance`, distance22.75, because current/adjacent-view eligibility is absent. Its actual144 walking contact occurs at accepted75.752014 and body128, observed physics frame769. These are raw transition records; they do not validate intermediate contact poses.

The next RIGHT original EAST swing retains the physical upper-flat target `(1783.889,383.1063)`, duration15.25. At failure, accepted86.593506, phase10.841492, actor `(1780,381.012726)`, body138.841492, RIGHT is still airborne. Its desired NE path-fit attempt is rejected (leading6.717515 versus planned3.181981); the shoe remains EAST after1.3 recorded seconds/74.143616 accepted world units. The exit has not been contacted, so its one-shot handover has not armed.

Independent source-length reconstruction identifies the planted **LEFT144/NW** as the limiting leg:

| Quantity | CPU reconstruction |
| --- | ---: |
| LEFT horizontal hip–ankle distance |25.213705world |
| Original conservative outer reach |27.977816world |
| HipZ / ankleZ |173.023180 /150.103873 |
| Required drop |8.8417864px |
| Actual rejected drop |8.8417550px |
| Absolute difference |0.0000314px |

RIGHT's current EAST ankle gives horizontal6.259715world and signed drop−5.500154px; it does not cause the positive drop rejection. Reconstructed sole vectors were rounded in the source JSON, accounting for the tiny replay difference. The common body raises from128 while the root travels beyond the delayed LEFT plant; this repeats the trailing-stance constraint. It does not justify widening8px, forcing a foot view, broadening carried eligibility, or claiming the exit geometry has passed its whole route.

Remaining work is a coherent source-view/path/recovery trajectory under the unchanged original-mask, ankle-rate and both-leg guards, followed by actual route/contact-order and native cadence review. The current gate prevents a known future-path mismatch but is not a complete gait solution. Full16 remains unaccepted.
