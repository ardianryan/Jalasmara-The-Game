# Ramp restart reach: independent captured-failure peer

CPU/source/artifact review of `b05a211`. No engine, browser, runtime edit, fixture reset, changed guard or duration constant. This is the later restart failure after the combined ascent and the earlier body-facing reversal progressed successfully. It is not the old frozen NW failure or consumption of the earlier0.028px conditional margin.

## Actual failure

Character evidence: `artifacts/godot/nala-terrain-dock-up-down-current-foot-body-b05a211/`. The rig rejects at actual root `(1120,1171.34350585938)`, accepted distance66.791016, body and artwork desired bothSE, four accepted body-facing transitions, required pelvis drop8.56817853046477px against8. The left original SOUTH shoe remains genuinely planted at height27.435757; it has been held relative to theSE body for0.5s/22.04187accepted units. The right SE shoe is free at restart phase7.823730/10 toward the unchanged flat landing0. Neither body-facing recovery alone nor a zero right-foot hold counter establishes both-foot recovery.

The body-support helper already consumes its whole allowance: previous body8.76416358683166, accepted distance2.2041015625, actual ramp rate1.07207590381155, allowed decrease2.36296417470964, resulting body6.40119941212203. Target height is already the actual current-footprint ground minimum0. Lowering that target cannot increase a rate-limited decrease.

To fit the same current feet with the unchanged8px pelvis bound, body height would need to be≤5.707581500250812. The missing0.693617911871219world cannot be added within that same frame without violating the existing rate. It corresponds to0.64698582386303additional accepted worldXY units at the current ramp rate. Across the entire restarted swing so far, prior body14.7888323255851 minus7.82373046875×1.07207590381155 already equals6.40119941212203. The helper is also saturated over that full interval; this is not another stale-transform or missing-chunk activation problem.

## Which moving component exhausts reach

The last accepted right ankle is `(1117.86193847656,-2073.47265625,14.1939868927002)`; the rejected support-translated ankle is `(1117.13989257812,-2077.01245117188,9.32128810882568)`. Their displacement6.06586282459418world over2.2041015625accepted units is2.75207954469847×, below the unchanged5× allowance11.0205078125world.

Both samples already use the identical identity Q and the sameSE source foot. No late view or plane switch accounts for this interval. The ankle Z change−4.87269878387452 decomposes exactly as:

| Component | Change in worldZ |
| --- | ---: |
|Original-mask ground-support envelope H|−3.80075120925901|
|Existing3sin swing lift|−1.04835310556818|
|Carried start-support offset|−0.0235944564273263|
|Total|−4.87269877125452|

C also decays and changes current foot worldXY, which changes H. Its Z difference must not be added again to this exact ankle decomposition. The actual mask/H path and existing sine move the free ankle down faster than the saturated torso can follow, while horizontal original-leg geometry consumes the remaining pelvis reserve. The actual ankle5× guard is not the failing condition.

## Restart policy and a bounded retained-target comparison

At pause the same right foot is still free at11.717285/13; its current valid stop-settlement target is `(1116.667,1174.643)` at bare ground11.34078. It has not made a new contact. Resume reanchors from actual raw sole height11.48561 and starts a fresh curve toward `(1116.464,1192.027)` at flat0 with duration10 and original3sin. The other foot stays at27.435757. A duration change therefore also changes how long this high trailing stance persists; both original leg annuli and actual eventual alternation must be checked through landing.

The character lane's independent CPU `model_restart_body_budget.py`, read before its model commit, uses the actual paused Q/C and a0, original SE right mask, actual SOUTH left planted ankle, the real dock profile and heldSE body hips. It replays the rejected drop as8.56775262156488px versus actual8.56817853046477, a0.000426px difference, with body height matching the recorded allowance. I found no concrete algebra issue in that captured replay: the actor stays within the same affine ramp span, source/foot anatomy are distinct correctly, the support offset is applied once, and C decay precedes bounded Q compensation as in the source.

Its sampled retained-destination quarter grid rejects durations10..10.75 and finds feasible frozen annuli/drop at11..16. At10.75 the sampled peak is already8.005044px, showing why terminal-only or sparse acceptance is insufficient. This is a causal witness that retained-target timing can affect the reach problem; it is not a proposal to install a global11-unit constant. New durations require actual initial-ankle5× checks, angular Rθ allowance, full original-mask/landing orientation, denser and varied timing, and a duration rule derived from physical viability rather than this one successful grid entry. The model explicitly excludes changed source-view feedback, angle backtracking, actual controller scheduling and all-terrain/native acceptance.

The source fix must retain actual coordinates, the stopped foot's contact truth, fixed landing geometry,6px view admission,8px drop, source bone annuli,5× ankle continuity and pause behavior. The body helper need not be made faster to hide this failure. A successful standalone restart or frozen CPU duration does not transfer to the full combined traversal or32-case natural-walking acceptance.

- `rejected.json` SHA256 `a2b64e8a77b068c764c9d2928f3c5e59ab3995392d7450fff85d43d74cb71331`.
- `samples.jsonl` SHA256 `63c56e64d8e8a700e1b6990154a69aad40ff36d60fcf26071e0b85dd06ecb1a2`.
- `source.json` SHA256 `7a45f627570305083ad97ef6ea2a8eef9132973e207c074b2fac6f0d234d5e81`.

## Independent execution and a rejected analytical assumption

I executed the expanded character CPU replay independently, writing only this lane's ignored output `.runtime/peer-restart-body-budget-b05a211.json` (SHA256 `e326a6ec0ca2e4331997de039d1df51a20342f8162c086f0c363899ba050783e`). Actual recorded phases reproduce the body and failure described above. Across30/60/120/2000Hz and recorded-prefix mixed schedules, retained duration10 fails every grid;10.75 reaches8.052827px on the dense grid;11 has worst observed drop7.785918px and ankle ratio2.670748, with both original annuli, angular budget and landing checks valid in this frozen replay. These are CPU results, not runtime or native acceptance. Checking all six actual samples gives worst ankle reconstruction error0.005185world and drop error0.004121px; the failure sample itself is closer. The bare-profile/inverse approximation must remain visible in precision claims.

The later analytical interval prototype initially tested the single hip point at both maximum possible torso descent and the full8px pelvis drop against each limb's outer sphere. That is not a necessary condition for legal poses when the higher uphill ankle lies above that hip. I supplied this counterexample from the actual frozen feet:

- Same captured initial root worldY≈-2054.027164, actual planted left ankle `(1116.302124,-2050.205078,33.393250)`, right flat landing ankle `(1116.464,-2078.236,6.103873)` andSE body hips.
- At accepted duration17.5, optimistic body baseline0 and full8px drop, left hip-to-ankle distance28.234858 exceeds the conservative27.977815reach.
- At the **same root, feet and baseline**, a common2px pelvis drop gives left26.820511 and right27.607340, both inside the original inner1.220775/outer28.077815annuli and conservative27.977815reach. At duration18 the same common2px choice also fits (27.297519/27.425734).

Thus fixing maximum pelvis drop can falsely prune a valid duration interval. This does not invalidate the captured-duration11 witness or the saturated-body causal diagnosis. It rejects the broader label that these fixed-point outer-sphere intervals are universally necessary. The parent accepted the counterexample and asked the author to retain it as a regression and use common hip-height segment/limb vertical-interval feasibility instead. A torso-rate lower bound is still optimistic unless actual current-foot support targets permit that descent. Source view/Q/C changes, inner annuli and actual common pelvis correction remain separate requirements. No dense runtime solver or new duration constant was approved by this peer.
