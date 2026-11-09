# Accepted-motion facing pipeline: independent source review

Reviewed character sources `6704e21`, pending-handover candidate `fa2732f`, and requested-facing auditor `eae1ca2`. CPU/source only; no engine, browser, runtime edits or new acceptance threshold. The previous failure geometry is recorded separately in `overnight-ramp-reversal-handover-peer.md`.

## Four stages use different signals

| Stage | Actual input and update rule | Existing limiting condition |
| --- | --- | --- |
| CharacterVisual requestedDirection | Hysteretic nearest octant of accepted screen-facing velocity | Update after movement only; zero speed/frozen returns retain previous request |
| CharacterVisual artworkDirection | Adjacent source-image view toward requestedDirection |4logical travel units per octant, at most1octant per process frame |
| NalaLowerBody3D direction | Adjacent body view toward artworkDirection | Original fixed-bone current and4world-unit-look-ahead admission≤6px; at most1accepted body transition per process frame |
| Each original foot view | Adjacent view toward current LowerBody direction | Only free foot, phase<85% of swing, original frozen-landing fit and current full-mask clearance; preserve actual ankle pivot |

The first signal is **not raw joystick direction**. `Player.gd` passes accepted `moved_velocity` plus the projected `renderer.visual_locomotion(previous,current,delta)` to `CharacterVisual.set_locomotion`. `LandWorld3D.visual_locomotion` projects accepted logical movement with its midpoint ground gradient. Hysteresis changes the requested octant only when the accepted screen direction differs from its previous octant by more than22.5°+5°. A blocked/raw input can therefore differ legitimately from this accepted-motion request. Reports should retain raw/delivered controls as separate evidence rather than relabel requestedDirection as raw user input.

The artwork clock uses `_speed*delta`, where `_speed` is accepted **logical** velocity length; the screen-velocity argument sets direction, not this clock. The physical sole planner instead consumes actual ground worldXY distance. For the current embedding,4logical units correspond to4worldXY along flat east/west,6.973787worldXY along flat north/south, and2.755258worldXY along the authored dock ramp centerline. These are source calculations, not measured animation times. Multiple physics ticks before a draw can accumulate enough logical distance for several artwork octants, but `_last_facing_frame` still permits only one in that process frame. Stops use the existing0.05-second settlement calls and the same process-frame gate; pause does not advance source facing.

Body admission then adds a separate geometry-dependent wait. Its look-ahead distance is based on actual ground-worldXY scaling, not the4logical artwork clock. Finally, a foot may wait until its next free-foot window even after the body view is accepted. These intervals can compound. `heldFacing` covers body-versus-artwork only, and `heldFootViewSeconds/Distance` covers foot-versus-current-body only. Both can be zero while all actual components still disagree with accepted-motion requestedDirection.

## Captured reversal demonstrates hidden first-stage lag

In `artifacts/godot/nala-terrain-full16-damped-inverse-6704e21/samples.jsonl`:

| Accepted worldXY | Accepted logical | Requested screen octant | Artwork | Body | Left/right foot views |
| ---: | ---: | --- | --- | --- | --- |
|2.469849|1.416626|SE|NW|NW|NW/NW|
|15.782715|9.052612|SE|WEST|NW|NW/NW|
|29.115723|16.700073|SE|SW|NW|NW/NW|

The failure's pose desiredDirection=SOUTH is another intermediate artwork view, not the final accepted-motion SE request. CharacterVisual requested SE from the first moving observation. An auditor comparing only desiredDirection could miss this earlier request-to-artwork lag; `eae1ca2` correctly adds the recorded source request and makes legacy rows without it insufficient for requested-facing acceptance. I ran its10 CPU unit tests: all pass.

## Pending-turn scheduling: intent versus actual view

`fa2732f` requests an existing short handover while physical body direction differs from **artwork** desired. That already reaches the captured second observation before the same planner call starts the right swing, so its narrow causal opportunity remains valid. No frozen airborne target needs replacement.

For a future physical scheduling contract, the earliest known unresolved accepted turn is `bodyDirection != source.requestedDirection`, even while artwork and body still agree on the old view. That signal can arm a future short-step request without forcing an immediate body/foot view or bypassing source artwork and geometry gates. It should use the accepted-motion request, not unconstrained raw joystick angle. Any such change is a separately reviewed candidate: this peer did not edit scheduling or claim it is needed to pass the captured `fa2732f` run. A request is not an accepted body transition and must not increment that counter. Re-arming while a turn remains unresolved must not move the current frozen target or restart its phase.

Do not bypass intermediate artwork by changing body desired to the final requested octant as an incidental scheduling fix. That changes which anatomical view and source silhouette are attempted, rather than merely choosing when the next handover can help an already pending turn. If considered later, it needs its own original-source/geometry review.

## Concrete audit completion gap

I independently called `eae1ca2`'s `audit(rows,32)` with exactly one matching requested/body/left/right travel observation for each of32 arbitrary labels, no walk/stop/restart completion records. It returned `completeCaseSet=true` and `terminalRecoveryAccepted=true`. The CLI reads samples and optional rejected.json but does not require the actual completed case manifest. Thus32 observed labels alone can hide a run that reached the final case and then ended abruptly before completing it. This is a synthetic CPU counterexample, not a claim that the actual failure or current logs passed; the existing rejected run remains rejected.

Keep terminal-view accounting as a limited observation metric, but require production `cadence.json`/`complete32Cases` and exact completed case identities before claiming the32-case matrix. The current32 consists of daily/explorer × normal/reduced ×8headings, with48 walk,18 stop and30 reversed restart observations per case. It is not every arbitrary input turn. A separate terrain16 consists of4connectors × up/down × normal/reduced using actual daily Player; it does not replace the two-outfit flat32.

## Falsifiable reporting using existing evidence

- Record requested, artwork, actual body, each actual foot view and equipment facing together, with process/physics frames, accepted logical/worldXY distance and elapsed physics/wall time. Separate input request changes from intermediate artwork changes.
- Report request→artwork, artwork→body and body→foot hold intervals and eventual matches, plus each component versus the final stable accepted-motion request. Keep continuous mismatch visible across intermediate artwork changes rather than resetting it at every source-image step.
- Distinguish actual accepted body-view transitions from pending requests. For each foot, record eligible airborne opportunities and original-mask landing/clearance refusals. A phase beyond85% or a grounded foot is not an opportunity to rotate that shoe in place.
- Preserve paused intervals, incomplete phases/cases, rejected poses and inherited initial CharacterVisual facing. Zero terminal mismatch is evidence only for the trajectory and completion actually recorded; a zero foot-versus-body counter is not proof of request recovery.
- Use the unchanged6px body admission,8px final drop, original fixed-bone/inner-annulus checks,5× actual ankle continuity and whole-mask guards. This review adds no arbitrary facing timeout or relaxed geometry condition.
- Native evidence must show the whole actor at gameplay zoom through an actual turn, stop and restart, with source/pose provenance. A final aligned still or successful CPU auditor is not natural walking or32-matrix visual acceptance.
