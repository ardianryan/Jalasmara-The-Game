# 06-B: Darmi and Sari tool follow-up

Isolated worktree `work/06b-tool-contact-next`, based on integration `e1bdf95`, after the accepted Ujang transition/head increment. This follow-up does not expand the NPC roster, edit shared routes, change the camera, or alter Ujang's rig. It is a bounded tool renderer change, with no farming, rewards or server mutation.

## Reproduced Darmi destination error

The shared profile places Darmi at logical `[1720,520]`. The previous water destination is `feet + Vector3(95,0,30)`, giving world X **1815**. The actual garden obstacle starts at X 1810 with width 330. The renderer's first bed centre is `1810 + 330/2 - 330*0.3 = 1876`; its soil half-width is `330*0.25/2 = 41.25`. The soil therefore begins at **1834.75**. The old destination is **19.75 units outside the first soil bed**, despite being inside the obstacle's larger rectangular footprint.

This was reproduced from the current shared `WORLD` using Node's TypeScript stripping, without running Godot. It is a geometric miss, not an assessment based only on colour or a screenshot.

The candidate caches the three actual soil surface rectangles from each `raised_beds` obstacle. It chooses the nearest soil point inset by two units, at the emitted soil top (`elevation*48 + 32`). For Darmi that point has X **1836.75** and Z **128**. Droplets approach that point from above with accelerating vertical fall, replacing the old sinusoid that could pass below the soil and return upwards near the destination. Droplets remain hidden outside the pour phase, in reduced motion, or when no supported garden surface exists.

The cache follows the existing renderer's explicit raised-bed dimensions. It does not infer that every point in a `garden` obstacle is soil and does not invent a new floor, collision, garden plot or reward.

## Contact telemetry and hidden tools

Darmi and Sari currently assign constant `gripError = 0` while their can handle or frame is built from the same hand sockets. Neither atlas has an independent `gripPixel`, tool axis or shuttle contact annotation. The candidate reports **unknown** for those unmeasured grips and omits the numeric error. It does not replace missing measurements with a new fabricated coordinate.

When any work prop becomes hidden, cached grip errors are cleared and the measurement becomes inactive. This also avoids showing a stale Ujang work measurement during travel or conversation. The accepted independently measured Ujang west rod contact remains unchanged while working.

## Three pilot handoff

| Pilot | Current source and verified scope | Work still needed |
| --- | --- | --- |
| Ujang | Eighteen parts, original rear upper body and west head/fist, independent west rod contact; accepted 1,242 contact samples including sharp turns | Fully authored side/rear limbs and torso; other-direction grip, line/float targets by orientation; physical device performance |
| Darmi | Sixteen original cutout parts; scheduled travel and pause contract already covered by previous integration; this candidate fixes the water-to-soil destination | Original directional rear/side art, independent palm/can handle annotation and can orientation, fixed-length world foot contacts and turn support |
| Sari | Sixteen original cutout parts; frame and shuttle follow computed hand sockets; no independent contact measurement yet | Stable loom frame attached to a real workstation, hand/shuttle/warp contact metadata authored after art inspection, directional art, world foot contacts and turn support |

Darmi and Sari still use the earlier screen-space gait with a heuristic knee and scaled bone sprites. This audit does not turn it into Ujang's tested fixed-length world gait. It also does not treat a torso's long skirt as permission to expose or redraw anatomy without checking the source. No gait patch is included without a focused failing runtime reproduction and appropriate visual acceptance.

## Verification status

CPU reproduction and `git diff --check` pass. Engine execution is pending the root's next slot after the final website/browser work; no runtime PASS is claimed yet.

The new `scripts/tests/village-tool-contact.gd` is prepared to build the actual `LandWorld3D` and run 480 Darmi/Sari work samples. It checks target intersection with emitted soil triangles, the old miss against those same meshes, pour/reduced visibility, above-soil drop paths, pause transform stability, unknown unannotated grips, clearing hidden tool metrics, and unchanged WORLD/player/economy snapshots. It must pass before considering integration. It is not registered in the main world runner at this pending checkpoint.
