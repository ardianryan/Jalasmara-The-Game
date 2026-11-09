# Stair contact candidate

Branch `work/06g-stair-grounding`, based on combined source `3b08659`. Source only at this checkpoint; no Godot, native or browser process has run in this lane. Root owns the `LandWorld3D` integration hooks and shared map changes.

The old stair mesh has level treads, while `SurfaceTraversal` and renderer queries return a linear ramp. The whole-body 3D sprite also discards the 2D traversal offset when resolving its atlas pivot. A second geometry problem comes from applying `map_point(p,height)` independently at each tread height: its height-dependent world-Y shift makes consecutive tread plans overlap, and the existing vertical risers do not join their actual edges.

The candidate keeps global `map_point`, accepted 2D movement, server coordinates, gait distance and footstep events unchanged. `SurfaceTraversal.connector_profile` caches route/width/height metadata; `connector_ground` returns exact stair tread heights and continuous ramp heights. `StairGeometry3D` uses continuous XY stations from the original linear connector plane, with actual Z set to the tread height. Adjacent tread edges then share the same physical XY, and the vertical riser closes their height difference.

The helper provides an analytical inverse for the local stair ground plane. Root must wire `ground_point`, implicit-height host projection, ray-to-ground logical recovery, camera follow and canopy focus. The global projection helper and its existing input matrix remain unchanged. Facing should follow the continuous path gradient rather than the instantaneous height jump at a riser.

Nala's sprite, shadow and equipment root consume the same physical support point. The existing distance-driven traversal lift is now explicit in 3D, capped at 1.6 units, zero on a ramp or under reduced motion; pause holds it rather than advancing a timed bounce. NPC rig roots and Ujang sole/body/lateral basis queries use the same support hook, with fallbacks for older focused test renderers. Ordinary floors keep their existing embedding and shadow offset.

This does **not** provide independently authored left/right stair poses for the current whole-body Nala atlas. A correct support point and visible body rise do not prove anatomically natural per-leg stepping. Final acceptance requires the prepared actual-mesh ray test, inverse/ordinary-floor/input regressions, an actual ascent/descent sequence and visual review. No new art, paid API, Noxe geometry or runtime dependency is introduced.

## Integration evidence and native review checkpoint

Root integrated the helper/actor source and `LandWorld3D` hooks on the combined branch. Initial Godot execution found typed-array mismatches in dynamic `_face` calls for risers/cheeks; root fixed the helper with explicit `Array[Vector3]` locals. The first focused fixture also required explicit types. These failures preceded the passing runs and are not omitted from the history.

Root reports the focused check passed **868** actual highest-triangle/height/inverse/projection/lift checks, including all 12 authored stair treads and ramp. Existing projection/input checks passed 2,304 cases and actual left-controller checks passed 60. These are integration-reported results; this lane has not launched an engine.

The first native controller fixture reached the opposite landing in all eight normal/reduced ascent/descent cases, producing 75 images at `artifacts/godot/06b2-stair-walk/`. JSON confirms central stairs rise through 60/72/84/96 world units, ridge stairs through 112/128/144, and the dock remains a continuous ramp. Moving rows settle to north-west on ascent and south-east on descent. Reduced motion has no added body lift.

CPU image inspection found a **fixture defect**: the 2D player remained visible alongside the 3D clone, notably in `forest_ridge_steps-up-normal-016.png` and `dock_gangway-up-normal-016.png`. Therefore these first 75 images are diagnostic evidence, not clean final visual acceptance. `review-contact-sheet.png` and its SHA/crop manifest in the same directory preserve the finding. The fixture now sets `hybrid_visual=true`, matching Main's existing runtime behavior; root must rerun the sequential capture. No product visibility behavior was changed for this defect.

The actual stair silhouette now has distinct treads and joined risers, but the reused whole-body walking poses still do not establish independently planted feet. Some leg silhouettes cross in the original flat-walk atlas. Keep natural per-leg stair animation open rather than treating support-height tests or still images as its completion.

## Clean sequence and flat terrain shading

The corrected hybrid fixture now passes eight cases with **99 sequential images**, including deceleration and stop poses, at `artifacts/godot/06b2-stair-hybrid-final/`. CPU review of its images and JSON finds one visible Nala, distinct riser/tread placement, correct ascent/descent direction after the existing facing transition, and zero added lift on the ramp/reduced-motion paths. The final recorded landing speed and lift are zero. Existing pose settling can outlast the short stop capture in one reduced-motion case; this is not proof that all stop/restart poses are finished. `review-contact-sheet.png` and `review-contact-sheet.json` in the final directory preserve 24 unscaled crops with source hashes.

The clean sequence exposed regular parallel terrain stripes. Root's native bias A/B found that increasing shadow bias did not remove them; disabling shadows did, losing desired depth. Source inspection found `_build_surface_geometry` enforces positive-Z winding while `_mesh` negates the cross product, leaving flat floor vertex normals down even though the fragment shader forces lighting normals up. Root now makes flat vertex normals agree with that existing fragment contract. CPU review of `artifacts/godot/06b2-shadow-normals/current.png` confirms the stripes are gone while cast tree/building shadows remain. No shadow-resolution increase or material texture removal was required.

The focused test now inspects actual batched dirt/grass vertex normals on flat triangles, excluding vegetation and vertical faces. It asserts they face up for both lighting and shadow passes. This new regression has not yet run at the time of this source update; root owns the serialized engine slot.
