# Nala lower-body articulation pilot

Branch `work/overnight-character`, based on `d070a7b`. This is an opt-in candidate, not a claim that natural walking is complete. The regular runtime still uses the accepted whole-body sprites unless an actor explicitly sets `nala_lower_body_pilot` metadata.

The original eight-view idle art supplies daily/explorer thigh, shin and foot rectangles. The authoring script records source hashes and anatomical left/right coordinates; it creates JSON only. It does not redraw, fill, mirror or recolor pixels. Overlapping profile legs reuse the same authored profile pixels and are identified as such. Other identities and diving art are untouched.

The visual-only planner holds a planted sole at its world point, alternates free-foot landings by accepted physical travel, settles a raised foot on stop and samples the existing tread contact embedding. Its contact count is separate from the unchanged legacy audio queue. No actor displacement, server position, inventory or raw CharacterVisual travel changes. Steps are currently 18 world units (24 rejected), pending actual speed review.

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

## Initial engine diagnosis — rejected

The first focused launch found two fixture-only inferred-type parse errors (`full_body_anchor`, `label`); these were explicitly typed. The next headless run exited 1 on flat east movement at `(1022,1360)`: the 24-world step requested 9.623815 source pixels of pelvis drop. Its exact pose is preserved in `.runtime/nala-lower-flat24-rejected.json`.

The 18-world candidate passed that first heading, but both headless and native rejected the diagonal transition at `(1008.485,1368.485)`, requesting 10.737638 pixels of drop. Headless `.runtime/overnight-nala-lower-step18.log` exited 1 after 1.93 seconds; native `.runtime/overnight-nala-lower-native-rejected.log` exited 1 after 4.96 seconds. Both contain one deliberate assertion ERROR and zero SCRIPT ERROR lines. `.runtime/nala-lower-failure.json` records actual hip/knee/ankle positions, fixed source lengths, world soles and the precise sample. Twelve native frames are retained under `artifacts/godot/overnight-nala-lower/`; no successful complete sequence is claimed.

The left support remained fixed, while the authored facing transition moved the left hip across the body's projected width. Its hip-to-ankle horizontal gap reached about 22.82 world units near the end of the swing. The required correction is a reach-aware support handover before this limit; a larger pelvis allowance or stretched bones is not accepted. Equipment now follows the actual lowered torso, and its real transform is checked separately. The engine slot was released immediately after this bounded diagnosis. This candidate remains OFF by default and is not ready for release.

Followup CPU corrections hold only the next adjacent authored facing row until both current and four-world-unit lookahead hip targets are reachable, with six pixels of safety margin. Actual upper-body and equipment facing share that held row. The fixture now requires facing convergence after walk plus stop, so a permanently wrong-facing sprite cannot pass. Landings lead the body by six world units, correcting the original under-body landing that left the support trailing for an entire following step. These source changes await the next focused run.

`tools/player-gait/review_lower_body_pose.py --expect-rejected` independently confirms the two recorded failures from measured joint coordinates: the old 24-world left chain exceeded its authored reach by 1.1014 world units; the old diagonal chain by 1.9579. The followup runtime now rejects before rendering any unreachable chain and displays the unchanged whole-body fallback for that sample. It never renders a stretched candidate leg. This fallback is rejection handling, not completion of the natural-gait task.

The initial native review sheet is `artifacts/godot/overnight-nala-lower/initial-rejected-contact-sheet.png`, with source-equivalent runtime `f295f9a` and hashes in the adjacent `initial-rejected-review.json`. It is a partial rejected sequence, not proof of all headings or stairs. The current triangle fixture measures the actual opaque sole centroid; heel/toe endpoints across stair edges are an additional acceptance requirement still pending. A centroid-only pass will not close the stair-foot task.

The second engine grant ran the corrected source headless. It passed the previous east and diagonal reach failures and both corresponding facing-convergence checks, then correctly rejected a sole over water at `(1000,1401.297)` while the manually driven fixture actor reached `(1000,1402)`. The south fixture leg extended outside the actual dock surface; the highest rendered mesh there was `-13.999969`, not the ground fallback's `0`. The fixture center is corrected to `(1000,1325)` so the full 48-logical-unit circle plus foot lead stays on the dock. The off-dock failure is retained in `.runtime/nala-lower-fixture-off-dock-rejected.json` and logs `overnight-nala-lower-facing-guard.log` / `overnight-nala-lower-floor-diagnostic.log` (exit 1, zero SCRIPT ERROR). No full-heading or stair pass is claimed yet. The engine slot was released without launching native again.

CPU followup now records the exact original opaque heel/toe bottom-row pixels for all 32 foot cutouts. The focused fixture tests both real sprite endpoints as well as the centroid against the highest rendered triangle. A spatial triangle index keeps this stronger check bounded; no runtime ground or limb tolerance changed. These endpoint checks are implemented but still await the next engine grant, so the preceding acceptance limit remains open.

A subsequent CPU pixel-row audit replaced the assumed uniform 14-pixel shoe windows with explicit per-view bounds. The uniform windows clipped authored toes in profile and could include an adjacent shoe fragment in diagonal views. The revised JSON keeps the original pixels and recomputes the original opaque sole centroid/endpoints; no raster is redrawn. This authoring correction is separate from the proposed stair torso weight transfer, which has not been implemented. The next focused run must establish the flat/facing result before any stair baseline change.
