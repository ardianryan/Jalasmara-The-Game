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
