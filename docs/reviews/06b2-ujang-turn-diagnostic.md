# 06-B2: anatomical facing candidate and unfinished turns

This follow-up is held in the isolated body worktree after `05a38bb`. It is **not accepted for release**. The added no-stop turn diagnostic fails; the existing commute test remains green. Keeping those facts separate avoids mistaking an improvement in a transform invariant for completed natural walking.

## Confirmed source issue and bounded changes

The previous rig reflects the entire Ujang root when facing west, while planted soles remain locked in world coordinates. Consequently the hips change screen side immediately, although their corresponding soles do not. The helper also negates its next anatomical hip targets using that same flip. This creates an avoidable crossing opportunity and reflects the original asymmetric wooden leg artwork.

The candidate retains a positive Ujang root, leaves the right leg and foot textures unreflected, and places future hip offsets through the actual camera-right vector. A local 2 × 2 finite-difference inverse of `map_point()` converts that vector to logical coordinates; it does not edit the renderer's map or camera helper. Swing lift uses the actual camera-up vector. No pelvis or fixed-length tolerance is enlarged.

The rig derives visual facing from logical motion projected onto the real `Camera3D` basis. A small cardinal hysteresis prevents switches at a noisy diagonal boundary. Actor navigation direction and server state are unchanged. The fishing rod's west angle is adjusted locally so positive-root anatomy does not make the rod point east. The authored fist still meets the independently defined rod.

The single front three-quarter head is not mirrored in this candidate. Therefore **the west head fallback still looks toward the source's east pose**. It is labelled an unmirrored fallback in the snapshot. This is an explicit visual gap, not a claim that unmirroring supplies west artwork. Four independently drawn views and correct rear limbs remain missing.

## Checks actually run

Godot 4.7.2 Compatibility, Apple M2. All processes ran sequentially under the root's engine slot, then the slot was released before documentation work.

- Default contact trace PASS: 1,074 checked samples, actual alpha-sole stance drift maximum 0.000273601 world units, quad knee join maximum 0.000272985, pelvis maximum 7.04096 within the unchanged limit 8.
- West grip PASS: 26 normal/reduced poses, actual finger-to-cylinder error maximum 0.01538721, axis error below 0.05 degrees.
- Native artwork/grip PASS: 26 work captures and sixteen directional stills on the final source. These stills are not a walking animation record. The vest and leg identity are preserved, while the west face fallback remains visibly imperfect.
- Additional turn diagnostic **FAIL**: 36 unreachable samples while traversing a collision-valid pier rectangle with immediate 90/180-degree changes, normal/reduced motion, and actual camera azimuths 0 and -45. Failure already occurs under camera azimuth 0, so it cannot be dismissed as only a camera-switch artefact. One logged requested pelvis drop is 25.86208, exceeding the unchanged bound 8.
- The actual rotated camera fixture also checks visual north/south from diagonal logical velocities. It rotates the real scene camera and calls the same production actor renderer; no projection callback is monkey-patched. Camera rotation happens between routes, not midway through one of the rectangle legs.

The diagnostic reports an explicit failure count and exits status 1. It is intentionally opt-in while unfixed, rather than weakening or removing the new case from the evidence. The default CI command still verifies the previously accepted commute; that is a narrower contract.

```sh
# Previously accepted route and the independent grip checks:
"$GODOT_BIN" --headless --path client-godot --script ../scripts/tests/ujang-foot-contact.gd

# Runnable unfinished regression; currently exits 1:
UJANG_TURNS_ONLY=1 "$GODOT_BIN" --headless --path client-godot --script ../scripts/tests/ujang-foot-contact.gd
```

Private ignored evidence/logs: `.runtime/ujang-anatomical-final.log`, `.runtime/ujang-anatomical-native.log`, `.runtime/ujang-turn-diagnostic-final.log`, and `artifacts/godot/06b-body-contact/`. Source atlas bytes are unchanged from the preceding art pilot.

## Next implementation requirement

The gait needs a reachable landing/transition step when heading changes sharply. A turn must redirect the free foot and release the supporting foot at a valid phase while keeping a grounded sole fixed in the world. Simply shortening an arbitrary prediction term, sliding a planted foot, stretching limb sprites, increasing pelvis travel, or hiding the failing diagnostic is insufficient. An attempted local free-foot replan and shorter lead were not retained because they did not satisfy the full diagnostic.

Hold this candidate for the transition-step fix and west-facing art review. The original accepted `05a38bb` increment remains independently reviewable; this follow-up does not retroactively claim that its natural walk was complete.
