# Stair contact candidate

Branch `work/06g-stair-grounding`, based on combined source `3b08659`. Source only at this checkpoint; no Godot, native or browser process has run in this lane. Root owns the `LandWorld3D` integration hooks and shared map changes.

The old stair mesh has level treads, while `SurfaceTraversal` and renderer queries return a linear ramp. The whole-body 3D sprite also discards the 2D traversal offset when resolving its atlas pivot. A second geometry problem comes from applying `map_point(p,height)` independently at each tread height: its height-dependent world-Y shift makes consecutive tread plans overlap, and the existing vertical risers do not join their actual edges.

The candidate keeps global `map_point`, accepted 2D movement, server coordinates, gait distance and footstep events unchanged. `SurfaceTraversal.connector_profile` caches route/width/height metadata; `connector_ground` returns exact stair tread heights and continuous ramp heights. `StairGeometry3D` uses continuous XY stations from the original linear connector plane, with actual Z set to the tread height. Adjacent tread edges then share the same physical XY, and the vertical riser closes their height difference.

The helper provides an analytical inverse for the local stair ground plane. Root must wire `ground_point`, implicit-height host projection, ray-to-ground logical recovery, camera follow and canopy focus. The global projection helper and its existing input matrix remain unchanged. Facing should follow the continuous path gradient rather than the instantaneous height jump at a riser.

Nala's sprite, shadow and equipment root consume the same physical support point. The existing distance-driven traversal lift is now explicit in 3D, capped at1.6 units, zero on a ramp or under reduced motion; pause holds it rather than advancing a timed bounce. NPC rig roots and Ujang sole/body/lateral basis queries use the same support hook, with fallbacks for older focused test renderers. Ordinary floors keep their existing embedding and shadow offset.

This does **not** provide independently authored left/right stair poses for the current whole-body Nala atlas. A correct support point and visible body rise do not prove anatomically natural per-leg stepping. Final acceptance requires the prepared actual-mesh ray test, inverse/ordinary-floor/input regressions, an actual ascent/descent sequence and visual review. No new art, paid API, Noxe geometry or runtime dependency is introduced.
