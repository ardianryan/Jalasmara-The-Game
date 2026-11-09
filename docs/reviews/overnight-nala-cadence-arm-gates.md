# Nala cadence and arm coordination gates

This reviews the optional lower-body candidate only. Production keeps whole-body rendering. It is not natural-walk acceptance and does not replace the independent rendered-foot, fixed-bone or eight-pixel anatomical rejection tests.

`Player.gd` retains `LAND_WALK_SPEED = 100` logical units/second. `CharacterVisual.gd` advances its unchanged raw distance from logical velocity and uses a 64-logical-unit full cycle, emitting a legacy foot contact every 32 logical units. `NalaFootPlant.gd` currently lands one foot per 18 accepted physical world units. These are different units and different rhythms.

On an ordinary floor, `LandWorld3D.map_point` embeds logical motion `(dx,dy)` as `(dx,-dy/cos(55°))`. At the same 100 logical speed, the optional planner therefore makes approximately 5.56–9.69 contacts/second across logical headings, while the legacy audio queue makes 3.125. The unchanged upper-body source cycles approximately 1.56 times/second; the new leg pair cycles approximately 2.78–4.84 times/second. These are source-derived steady-state estimates, not a measured production recording or a recommendation for natural cadence.

The native prescribed fixture uses two logical units per simulated 1/30-second tick. It establishes actual geometry and source continuity at that input, but native frame presentation is not forced to that simulation rate. A sheet of those frames cannot establish real-time production cadence.

## Proposed bounded implementation order

1. Finish the current independent shoe-clearance and fixed-joint gates first. The pending terrain-aware trajectory changes timing, not world authority, leg lengths or tolerance.
2. Drive the optional renderer's upper walking frame and modular gear phase from the actual anatomical swing side/progress. Right swing spans the original left-contact frame 0 toward right-contact frame 4; left swing spans frame 4 toward frame 0. Confirm this opposition against the original authored arm pixels in every view. Keep raw `CharacterVisual` distance and its existing event queue unchanged. Stopping must settle through adjacent displayed frames rather than switch from the planner phase to an unrelated legacy phase. Pause and repeated physics updates in one displayed frame must retain the existing motion bounds.
3. Review a longer steady physical step with leading placement and a shorter start/turn transition. A proposed 32-world steady step and 16-world lead are hypotheses, not accepted constants. They must pass the same exact source-pixel support, anatomical reach, foot continuity and actual Player movement tests. A longer step cannot be justified by stretching, skating or moving the actor root.
4. If the optional planner is adopted, route its actual contacts to the existing audio system once per landing. Drain the legacy queue without playing duplicate contacts while the optional renderer owns feet; retain the legacy source for the whole-body fallback. Handle new rig/outfit epochs, teleports and pauses explicitly. This requires coordination with the audio owner; no audio code has been changed here.
5. Validate outfit changes and leaving/re-entering the optional renderer without freeing it. The current test constructs a fresh rig for each outfit and therefore does not prove that lifecycle.
6. Expand stair coverage from daily/reduced to daily/explorer and normal/reduced; add real tread-boundary stops and 45°, 90° and 180° corners. A threshold that only reanchors above 60° does not cover ordinary 45° keyboard corners. Retain the actual terrain and all independent endpoint/ankle measurements.

## Production-speed evidence required

Use actual `Player._physics_process`, its unchanged screen-relative input transform, LandCollision, accepted displacement and a fixed physics clock. Record input, real delta, accepted logical/physical travel, original source frame, anatomical swing state and modular gear state. Capture moving sequences at a declared rate, including start, steady walk, stop, restart and direction changes, at both outfits and both motion settings. Preserve full context frames as well as nearest-neighbor crops; flush exact pose metadata during capture so failures remain reviewable. Stills alone do not close cadence or arm opposition.

The last native sheet keeps identity coherent and makes support more grounded than the original high-knee poses, but calf/short seams still need visual review. Original joint-pixel overlap masks may repair actual gaps; do not install decorative raster changes or claim a four-view art expansion from reused profile pixels. All other identities and diving remain unchanged.

## Production-controller diagnostic candidate

`scripts/tests/nala-production-gait.gd` is a source-only candidate awaiting a serialized engine slot. It has not been parsed or run by Godot and is not registered as an accepted CI gate. It inherits the independent bone-length, actual opaque sole/ankle, terrain-triangle and equipment checks from the existing strict fixture.

Daily movement runs the actual `Player` physics loop with the production terrain/input/visual callbacks and camera zoom 0.88. Explorer movement runs the actual `Forest` controller and its `ForestAvatar`, camera zoom 1.05, collision and acceleration. The fixture prevents Forest position synchronization with `syncing = true`; it disables the audio consumer so it can count, then drain, the existing contact queue without playing or duplicating sound. It does not rewrite either movement controller or replace accepted displacement with prescribed targets. A fresh authoritative flat-floor origin must pass a 105-logical-unit radial clearance search before the case runs.

Each case starts from idle, applies 48 actual physics observations of walking, 18 stopping and 30 restarting in the opposite screen direction. Eight headings, both outfits and both reduced-motion settings give 32 cases. Delta comes from observed `Engine.get_physics_frames()` divided by the configured physics rate, rather than assuming a render call represents 1/30 second. Actual physics delta and elapsed wall time are both retained; neither is a device FPS benchmark. Case paths remain well below the existing path-buffer limit and are reset between cases without sending API requests.

Every successful observation flushes `samples.jsonl`: input, real physics frame/delta, accepted logical and physical distance, original source phase, legacy contact count and the actual lower-body pose. Each case also separates walk, stop and restart contact/distance/time windows in `cadence.json`, avoiding a steady-cadence claim from a rate averaged across stops. Optional native captures flush their exact frame/pose index immediately, preserving preceding proof if a later geometry rejection stops the run. Source hashes include the controllers, helper, renderer adapter and both fixtures. Existing output directories are rejected rather than overwritten.

Bounded diagnostics may select an explicit contiguous slice with `NALA_PRODUCTION_FIRST` (0–31) and `NALA_PRODUCTION_CASES`; for example first 16, count 1 exercises the first explorer case. A slice remains marked incomplete. `naturalWalkingAccepted`, `armOppositionAccepted` and per-case `cadenceAccepted` remain false even when geometry passes. No source speed, planner cadence, audio routing or default renderer setting is changed by this fixture.

CPU checks after preparing this candidate: original lower-body source test passes all 96 original opaque cutouts; whitespace check passes. Engine parsing, real controller execution, source-phase interpretation, actual camera framing and native sequences remain unverified until an explicit slot is granted. The pending terrain-aware trajectory 4556efb also remains untested and off by default.

## Input and distance units

`LandViewProjection.input_motion` inverts the projected ground-plane matrix, then normalizes that result in logical coordinates. It preserves the screen direction and the existing 100-logical-unit server budget. It does not normalize the actual ground-world velocity. On a flat floor, the Jacobian is `(dx,dy) → (dx,-dy/cos55°)`; arbitrary logical headings therefore span 100–174.345 world units per second. The camera then foreshortens that ground velocity rather than making screen speed constant.

`python3 tools/player-gait/derive_production_units.py` derives the matrix independently from the actual camera/controller constants and records source hashes. This CPU calculation has passed its nondegenerate-matrix and direction-preservation assertions. It is not an engine measurement. At the current left camera (azimuth −45°, elevation 35°), the eight screen-input headings yield:

| Screen headings | Ground-world speed | Projected view speed | Optional 18-world contacts/s |
| --- | ---: | ---: | ---: |
| 0 and 4 | 122.674 | 122.674 | 6.815 |
| 1 and 5 | 163.322 | 114.919 | 9.073 |
| 2 and 6 | 122.674 | 70.363 | 6.815 |
| 3 and 7 | 102.377 | 72.036 | 5.688 |

The earlier 5.56–9.69 range describes all possible logical headings; this table describes the eight actual screen inputs. The production fixture must record its observed accepted distance/time after acceleration, stopping and terrain pacing, so its short-window rates need not equal these steady-state numbers. Child gait has the same issue: 26 logical units/s with a 10.8-world contact distance would give 2.41–4.20 contacts/s across all logical headings. That is an illustrative distance choice, not a measured rate or a natural-gait acceptance of every child.

For a future physical-speed contract, keep authoritative positions and path-validation budgets in logical coordinates, but define the desired movement speed in continuous surface-world units. Invert the screen ground-plane matrix to obtain the direction, then normalize that direction using the surface tangent's world length before applying speed and slope pacing. Do not subsequently normalize screen length: genuine ground-depth foreshortening should remain. The logical authority cap still applies, especially where connector XY compression would otherwise require greater logical velocity.

For gait distance, use accepted continuous surface-path length; exact tread Z remains the sole-contact authority. Counting discrete 12- or 16-world riser jumps as immediate traveled distance would introduce artificial contacts. If movement remains intentionally logical-speed based, derive contact placement from the measured world rate and actual fixed-leg reach rather than choosing a constant that only looks reasonable in one heading. A longer steady contact distance also needs an initial lead-establishing transition: a 32-world step with 16-world lead has steady support ranging +16 to −16 world, whereas starting both feet under the root and immediately taking 32 world leaves the first stance foot 32 world behind and exceeds the source legs. Those are geometric examples, not installed constants.

No speed/input/server/cadence constants were changed during this audit. Such a contract change requires separate gameplay-feel, server-path, route-duration, slope and native cadence review; it must not be hidden inside a foot-rendering patch.
