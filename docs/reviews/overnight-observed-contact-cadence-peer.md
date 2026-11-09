# Observed stair contact clocks:7e14c09 CPU artifact peer

Read-only analysis of actual character samples in `artifacts/godot/nala-terrain-first3-remaining-stair-resume-7e14c09/`. No engine, controller edits, new cadence threshold or natural-motion acceptance. This run completes two normal dock directions and rejects central ascent before96contact. It is not a full16 run.

`nala-production-gait._production_tick` derives `physicsDelta` from actual observed physics-frame increments divided by `Engine.physics_ticks_per_second`, and accumulates `elapsedPhysics`; this fixture records60ticks/s. These are **simulated fixture seconds**, not wall time or physical-device FPS. Each sample separately records elapsed headless wall seconds. Accepted contact counters can advance within a multi-tick observation batch; a sample timestamp is not an exact per-contact timestamp.

Central contacts are genuine alternating new plants. Initial idle frame203 has both feet planted48/counter0/reset0. At216 the left plants a new48 position/counter1 and right is free; at224 right plants another48 position/counter2 and left is free; at229 left plants60/counter3; at247 right plants72/counter4; at276 left plants84/counter5. Reset remains0. Thus they are not initial both-planted bookkeeping, but their observed rates require care:

| Newly observed pair | Simulated observation interval | Wall observation interval | Accepted motion between observations | Interpretation |
| --- | ---: | ---: | ---: | --- |
|Right48@224→Left60@229|0.083333s|0.066915s|6.30530world|Observation rate12/s, **not a full swing/contact cadence**|
|Left60@229→Right72@247|0.300000s|0.242236s|21.27710world|Observation rate3.333/s; mean accepted rate70.9237world/s|
|Right72@247→Left84@276|0.483333s|0.487435s|20.09509world|Includes explicit stop/pause/restart; not steady cadence|

The first pair illustrates the batching problem. At224 the left has already advanced11.448974609375/17.73095703125, carried after the right contact inside the preceding8-tick observation. At229 the next right swing has advanced0.0233154296875. Subtracting the newly active swing phase from cumulative accepted distance locates the right48 contact at accepted21 and left60 contact at38.73095703125: their contact-aligned travel gap is17.73095703125world, not the6.30530world observation gap. Calling12/s an actual startup cadence would therefore overstate what the snapshots prove. This correction was sent immediately to root/character after inspecting phases.

The60→72 contact-aligned gap is20.730957world, matching that planned step duration. This still does not establish an exact per-contact wall timestamp or a complete steady cycle. Stop/restart can reanchor phase without contact; recorded free/grounded/plant transitions and unchanged counters remain necessary. A future validated-contact producer should retain accepted-distance/epoch/side and contact-time information after the complete lower-body pose passes, rather than infer cadence solely from final counter differences.

Nominal100/D estimates remain source estimates. The current central accepted movement around70.9world/s is materially different from100, and headless wall scheduling differs from simulated physics time. Native motion review needs actual contact timestamps, pose transitions, audio alignment and the render timeline. Geometry bounds do not make the brief startup handover or a6Hz nominal stair policy natural by themselves.

Own read-only extraction `.runtime/actual-contact-cadence-7e14c09.json` records14 observed contacts across the partial run; no complete-matrix or device-performance claim is attached. Underlying samples SHA256 `b684302d0b5e5f264759a7b332fd7defd410f75f7a9c90d9862a9731784e75fe`.
