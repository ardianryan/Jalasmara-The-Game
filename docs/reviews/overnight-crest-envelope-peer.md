# Peer CPU: crest orientation budget and original-foot support envelope

Read-only source/runtime evidence: character `d014f4e` (later HEAD5b14 is docs-only), failed first dock in `artifacts/godot/nala-terrain-dock-up-safe-advance-d014f4e/` and earlier early-flat curve `.../nala-terrain-dock-up-support-profile-209a49b/`. No renderer, character source, physics/world, raster, guard or tolerance changed; no engine/browser. CPU diagnostics are preserved separately under `/Users/ardianryan/Documents/Jalasmara-overnight-resident-art/artifacts/player-gait/crest-envelope-peer-d014/`.

## Model and actual angular shortage

For fixed actual ankle XY and original pixel offset p relative to that ankle, define `H(Q,XY)=max_p[terrainZ(XY+(Qp).xy)−(Qp).z]`. H excludes any clearance margin or sine lift. Feasible endpoint requires actual ankleZ≥H+.02, using existing helper's margin. This CPU model uses **60 original opaque pixel corners plus both direct sole markers** `[.5,4]`/`[10.5,4]`, source NW daily right foot, actual ramp from current manifest and actual captured paint boundary worldY−2030.031616/height48.072021. It is not a general terrain mesh/swept-volume reconstruction. Angle scan spacing0.0005rad gives approximate feasible intervals; the concrete witness below is rechecked directly at its exact angles.

At d014 accepted distance67.893066, swing8.925781, original Q angle is0.543474rad. At failed distance71.199341/swing12.232056, same actual ankle admits Q up to approximately0.0145rad once direct marker checks are included. Available travel3.306275 divided by original radius8.559046 gives only0.386290rad. Starting full-ramp Q there leaves at least0.157184, which cannot meet the final feasible interval. This is a real planning shortage under the unchanged radius×angle rule, not a reason to increase that allowance. Even starting at distance66.790894 with full-ramp Q leaves approximately0.0284rad at the failed pose, still above the observed feasible endpoint interval. A separate10.001-angle scan over the entire late-reachable interval `[.157183934,.543474009]` gives best modeled clearance margin−0.542517 at its lower endpoint, so this is not a borderline0.0005-grid result. It remains a captured-profile CPU diagnosis, not an arbitrary-terrain theorem.

## Earlier partial rotation is locally possible without raising ankle

Frozen d014 actual ankle/hip samples admit this **illustrative endpoint witness**, in order from distance59.129883 through71.199341:

`Q=[.543474,.2775,.1635,.125,.125,.125,.125,0,0,0,0]`.

Every angular change obeys `RΔθ≤Δaccepted`, all62 corners/markers clear the modeled support by the existing+.02 with minimum additional slack0.052509, and the actual ankle sequence still obeys5×accepted+.003. Q returns to flat before the last three observations. Because this is rotation about the exact same ankles, actual fixed hip/ankle distances and recorded pelvis drop do not change; recorded maximum drop is6.98757<8. This shows **no local proof that extra ankle lift is mandatory**. The number0.125 is a witness choice, not a proposed hardcoded controller angle.

It does not prove a production schedule: changing Q changes compensation C; its decay changes next-frame ankle positions, and exact intervening render/physics observations are not reconstructed. All62 points are endpoints, not an analytic swept foot. A runtime implementation must recompute the actual support envelope and coupled C/body/reach, rather than copy this frozen angle list. Simple greedily flattening fully as soon as possible is also insufficient: on frozen early-flat209, flat fits some mid-arc samples but later requires another partial ramp angle before the crest.

## Original early-flat209: clearance and reach

Frozen actual NW ankles, compared with H+existing.02:

| Swing distance | Flat-Q ankle deficit | Approximate feasible minimum angle |
| --- | ---: | ---: |
|2.439453|+0.510585|0.0900|
|3.415283|+0.123122|0.0230|
|4.517456|−0.110711|0|
|5.619507|−0.100165|0|
|6.721558|+0.140419|0.0260|
|7.823608, failed|+0.595431|0.1040|

Negative deficit means already clear. At failed209 pose, angle0.104 can clear the original geometry at the same ankle; right hip-to-ankle distance12.80050 remains between fixed radii1.22077 and28.07782. No bone length change is needed for that local orientation. Actual source209 chose flat and failed its original mask, which remains the preserved result.

## Conditional support-H plus original three-unit lift

Character confirmed the candidate's intended definition: **H excludes+.02**, and start offset is `a0=actualCurrentAnkleZ−H(Q0,actualAnkleXY0)` including current Q/C once. Do not add C.z again. Proposed ankle height is `H(Q(u),XY(u))+3sin(πu)+a0(1−s(u))`. It is continuous at captured phase0 by construction; its support geometry, the unchanged3-unit sine, and inherited airborne offset are separate terms.

Independent replay holds original209 observed ankleXY, Q sequence and hip positions fixed. At last paused start, ankleZ31.5525856 and H29.62671198 give a0=1.92587363. For moving phases0.162598/2.439453/3.415283/4.517456/5.619507/6.721558/7.823608, proposed ankle increases over captured source are **0.165678/2.296883/3.074606/3.848161/3.961315/3.993982/4.026716 world units**. This is materially different from minimum-only clearance repair of0.595431 at the failed sample; do not describe H+original lift as merely a0.2–0.7 change.

Across these sparse observations, maximum proposed ankle-distance/accepted-distance ratio is4.367191<5. Right fixed-hip distance becomes10.42794..19.64192, within1.22077..28.07782; unchanged left distance22.57144..27.97782 also remains inside its original annulus. Existing frozen pelvis-drop maximum4.22382<8. This gives a useful feasible diagnostic, **not a coupled runtime/body-drop/IK or dense curve acceptance**. New support-H max switches, Q derivative, actual paint/surface events and compensation feedback are absent from the old center-support4.9 proof. That proof must not be reused for this candidate without new derivation/tests.

## Pace consequence and handoff

While continuously moving, current angular allowance is accepted distance/R. Slowing the same spatial path gives more wall time but **does not increase total available angle across that path**; only zero-movement settlement uses24δ. Thus slower movement may help perceived cadence but cannot alone repair the present late-Q spatial budget under the same rule. Earlier feasible Q planning or a properly coupled support-aware path must be tested first. Natural stairs, cadence, arms and per-device behavior remain separate open gates.

Preserved CPU outputs: `jalasmara-crest-angle-envelope-d014.json`, `...-209.json`, `jalasmara-crest-H-209.json`, `jalasmara-crest-frozen-angle-witness.json`, plus local replay scripts. The H JSON SHA is `253926beec0bb3c72951b324a5aeb6dc44f228ca6d9d27a73d1855b1a0a9605b`; witness SHA `d493c4aaeca3df9352a980e2c72ff9cf3cdf37c45da7129f6183be9561066f61`. Parent/character received exact numbers and limitations directly. No new gameplay acceptance, runtime patch, arbitrary lift, geometry extension or guard relaxation follows from this report.
