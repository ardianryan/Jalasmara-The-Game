# Ramp reversal: pending body-facing handover peer review

CPU/source review of character runtime `6704e21` and its source-only follow-up `fa2732f`. No Godot, browser, renderer, controller or fixture changes were made in this lane. The physical pilot remains separate from accepted default walking.

## Actual failure and timing

Evidence: character worktree `artifacts/godot/nala-terrain-full16-damped-inverse-6704e21/{rejected.json,samples.jsonl,source.json}`. This is the combined traversal run, not the standalone descent result. The failure is check48, `dock_gangway/true/false travel`, actor `(1120,1122.65600585938)`, requested pelvis drop **8.88371948356765px**, guard8 unchanged.

| Observation | Accepted worldXY travel | Body / artwork desired | Active foot / phase |
| --- | ---: | --- | --- |
| New descent idle | 0 | NW / NW | none, initial distance10 |
| First moving observation | 2.4698486328125 | NW / NW | left2.46985/10 |
| Next observation | 15.78271484375 | NW / WEST | right5.78271/32 |
| Last accepted observation | 29.11572265625 | NW / SW | right19.11572/32 |
| Rejected observation | 30.7823486328125 | NW / SOUTH | right20.78235/32 |

`NalaLowerBody3D.update_pose` evaluates desired artwork/body mismatch before `NalaFootPlant.update`. At the second moving observation, WEST is already requested when that same planner call completes the remaining initial left10 and starts the right swing. The existing body-facing admission rejects an adjacent view unless its current and look-ahead fixed-bone drop are both≤6px. `note_body_facing_transition` therefore never runs here; its accepted-transition counter remains0. Without a request hook the newly started right swing uses steady32, although the body is still waiting to turn.

The rejected foot's **current** logicalY is1140.439; its frozen **destination** is1164.227. Those are different positions. The right target was fixed before the eventual failure and is not a moving-target bug. The fixture creates a fresh lower-body rig for each case; the NW artwork carried by actual CharacterVisual from the ascent is the meaningful difference from a standalone descent. Resetting that facing would erase this case instead of solving it.

## Independent geometry checks

Reconstructing the original NW right leg using the actual camera vertical factor `1/cos(35°)`, source hip/knee/ankle distances12+11px and the recorded final support-translated ankle gives:

- hip≈`(1124.242641,-2030.084761,79.182055)`;
- ankle=`(1124.98986816406,-2041.33239746094,42.7305450439453)`;
- outer available reach=`23/cos(35°)-0.1`≈27.977816world;
- required drop≈8.883749px, reproducing recorded8.883719 within float/rounded-source error;
- at the unchanged maximum8px drop, hip-to-ankle distance≈28.968493world: **0.990678world beyond available reach**.

Thus changing the knee solver alone cannot legitimately accept this frozen pose. Bone lengths and the6px admission/8px final drop guards should stay unchanged.

The prior accepted actual right ankle was `(1124.90686035156,-2037.03527832031,47.5217208862305)`. Its displacement to the recorded final support-translated ankle is6.436419world over1.6666259765625 accepted worldXY, ratio3.861946. The5× allowance is8.333130world, leaving1.896711world in this particular interval. This reconstructs the ankle candidate in the rejected pose; it is not a final enabled-rig acceptance. The actual blocker reported here is fixed-bone reach, rather than exhausted ankle-rate budget.

The old frozen path has57.999512worldXY. Splitting at the actual crest yields≈30.9805world flat plus a27.019worldXY ramp segment dropping28.9673world. Its piecewise XYZ length is≈70.5928world, about21.7% longer than XY alone. This is relevant to anatomical reach, but it does not justify replacing the whole locomotion contract: `_ramp_duration` already uses the actual ground slope for its center-curve bound. Its recorded bound4.28036 explicitly excludes the original-mask support envelope H and Q/pivot effects.

## Bounded source candidate

`fa2732f` adds `request_body_facing_handover()` to the planner and calls it before update whenever the physical body direction still differs from artwork desired. It only arms the existing `_transition_next` flag. It does not increment `bodyFacingTransitions`, alter accepted coordinates, modify current swing progress, rotate a planted foot or replace a frozen target. Persistent held facing rearms a later update rather than treating a consumed request as an accepted body turn. The default nonphysical path is unchanged.

Using the captured next-begin right source and original short-step algebra:

`ceil(1.5 * (16 - trailingProjection) / 2.5)` with projection≈-9.999 gives minimum16. The existing forward policy then chooses32worldXY ahead of its base rather than48. Rounded recorded knots independently give target worldY≈-2040.948, height≈36.18643, actual path≈41.999worldXY /47.13484piecewiseXYZ. Applying the unchanged ramp center-curve formula gives distance21 and base bound≈4.84696≤4.9. Character's manifest-derived CPU model reports the corresponding logicalY≈1140.997.

This is a causal opportunity to choose a nearer landing **before that right swing begins**, not permission to shorten an already airborne target. I found no concrete source/algebra blocker to this narrow candidate. It does not prove the final anatomy: the changed landing changes when the free foot enters the ramp, body-height transfer, the original-mask H trajectory, Q adjustment and subsequent body-facing admission. In particular, substituting the nearer endpoint into the old failed frame cannot establish a new final drop or ankle bound.

## Required next evidence

Run the actual combined ascent→descent with its real carried NW artwork, unchanged geometry and unchanged guards; retain the old failure. Require fixed target until contact, source-bone/inner-annulus validation, whole original-mask clearance,5× actual ankle displacement, body transfer rate,6px facing admission and8px final drop. Inspect both body desired-versus-actual recovery and free-foot view recovery; zero accepted transition counters or foot-versus-body lag alone cannot show successful turning. Paused/request-only states must emit no accepted transition/contact. The full16 matrix and actual visual walking remain pending until measured.

Evidence hashes are recorded below so this CPU review remains tied to the failure rather than a later regenerated result:

- `rejected.json` SHA256 `7f291bd6db53f2849b345ce5edbc2918e44cdd431724fd26b26abf55ed77c27e`.
- `source.json` SHA256 `e747bf2dcdaa5deb8c65e5e9b2b4e113a663711051ee831a1d9cd8a969758d25`.
- `samples.jsonl` SHA256 `76a652f55f44c8b2118f0b5cf280d0915cd19d63522531a57836ec5d4db4d942`.
