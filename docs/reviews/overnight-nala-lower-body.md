# Nala lower-body articulation pilot

Branch `work/overnight-character`, based on `d070a7b`. This is an opt-in candidate, not a claim that natural walking is complete. The regular runtime still uses the accepted whole-body sprites unless an actor explicitly sets `nala_lower_body_pilot` metadata.

The original eight-view idle art supplies daily/explorer thigh, shin and foot rectangles. The authoring script records source hashes and anatomical left/right coordinates; it creates JSON only. It does not redraw, fill, mirror or recolor pixels. Overlapping profile legs reuse the same authored profile pixels and are identified as such. Other identities and diving art are untouched.

The visual-only planner holds a planted sole at its world point, alternates free-foot landings by accepted physical travel, settles a raised foot on stop and samples the existing tread contact embedding. Its contact count is separate from the unchanged legacy audio queue. No actor displacement, server position, inventory or raw CharacterVisual travel changes. Steps are currently 24 world units, pending actual speed review.

The rig calibrates fixed leg lengths from source vertical pixels into the Z-up world using the real camera basis. Hips sit vertically above the actor ground point; the original upper-body screen position is preserved. Actual sprite mesh endpoints, original foot-sole pixels and rendered terrain triangles are measured by the focused fixture. Requested pelvis drop beyond eight source pixels is a rejection, not permission to stretch a limb.

CPU annotation verification passed 96 original cutouts, including 32 measured original sole pixels, exact source hashes and the explicit opt-in scope. No new raster was installed. Two imagegen gait drafts were inspected and rejected because contact frames remained broad and almost identical. Native/headless testing of this new pilot is pending the shared engine slot; no result from the earlier narrow stop/restart pilot is attributed to this code.

Run after the integrator grants the engine slot:

```sh
python3 tools/player-gait/test_lower_body.py
Godot --headless --path client-godot --script res://../scripts/tests/nala-lower-body.gd
NALA_LOWER_CAPTURE=1 Godot --path client-godot --script res://../scripts/tests/nala-lower-body.gd
```

The fixture uses actual Player, LandWorld, sprite transforms and floor triangles. It covers eight movement headings, daily/explorer, normal/reduced motion, stop/restart/turn, each authored stair up/down and pause. It must exit nonzero on reach/mesh failures. Native captures still need visual review for knee direction, skirt/short seams, fingertip clipping at the upper-body cut and actual speed. Four original resident views and full-cast motion remain separate unfinished work.

The initial annotation check rejected an assumed bottom row for the south-east left foot. The corrected manifest measures the real opaque bottom row and sole centroid from each original crop. Subsequent source review also corrected foot bases to those measured sole pixels, used the actual continuous stair XY embedding, and preserved the free-foot pose before a sharp turn. These changes still await engine validation.
