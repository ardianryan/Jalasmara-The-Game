# Six new residents: original native body candidate

Branch `work/overnight-character`, based on main `d070a7b`, following the accepted restart port and Ujang west-knee fix. Root owns merge/release and shelter owns resident identities, routes, buildings and authoritative world data. No main push, export, API or world mutation is included here.

`HubActor.configure_activity` now retains the canonical resident ID, visual profile, age and clamped visual body scale before configuring activity. `LandActors3D` chooses a new native body only for `visual.kind=child|director`. New appearance indices6–11 therefore do not index beyond the old six-cell atlas or display cloned adult portraits. Existing NPC sprites and the Ujang/Darmi/Sari rig path remain unchanged. The ordinary 2D fallback has an original age-sized shape instead of an invalid atlas region.

`VillageResidentBody3D` builds original geometry with one colored MultiMesh body batch per resident. It has separate head/hair/clothing, fixed-length arm/leg segments, feet and role-tool geometry. Child heads are proportionately larger than the director's, with the explicit body scales supplied by shelter. Glasses/striped shirt, braids/flowers, caping, cork vest/bandage and bandana/apron distinguish the children; cream corporate clothing, teal tie and briefcase distinguish the director from Raka. Tools are positioned independently at the hands rather than painted into a portrait. Profiles select telescope, snail jar, bucket, slingshot, ladle or briefcase.

The native sole planner derives from the existing displacement-driven contact planner, using world-Z lift and the native body's ground-plane lateral axis. Legs use 3D fixed-length IK and local-axis instance scaling; it does not stretch a portrait limb or reflect anatomy. Actor coordinates, movement speed, routes, server state and calendar remain untouched. Pause retains the exact model/tool pose; reduced motion preserves essential stepping while suppressing work flourishes. This is a compact original voxel style pilot, not an assertion that it already matches the final illustrated NPC style.

## Actual checks and failures

The first import was clean. A first fixture parse error (untyped ID concatenation) was fixed. The initial headless mesh-length check failed and its last assertion left the test waiting until its bounded process timeout; these logs remain. Failure exits now call `quit(1)` and yield a frame so failure cannot be mistaken for completion.

Explicit readback diagnostics established that the headless dummy renderer returns identity MultiMesh transforms: upper/lower length1 versus expected18. It was not evidence that the actual rendered native bones had length1. The production emission was also corrected to local-axis scaling, `basis * Basis.from_scale(size)`, which preserves rotated limb lengths. The fixture does not relax the0.001 length invariant.

An opt-in `native_mesh_diagnostics` flag records the **same transform arguments sent to MultiMesh**; ordinary actors do not allocate this diagnostic array. Headless CI checks those emitted inputs. Native checks additionally read each real MultiMesh transform and compare it to its emitted input before measuring geometry. These evidence levels remain distinct.

| Own executed check | Result |
| --- | --- |
| Headless native body fixture |1,266 emitted-input sole/limb samples pass; six canonical identities and props, four movement headings, actual rendered floor-triangle contacts, pause/reduced, no world/player mutation.|
| Actual native Compatibility/OpenGL on Apple M2 |1,266 real mesh readback samples pass, zero stance drift at measured planted centres, max leg length error0.000003815; one body batch/model.|
| Existing NPC state |Clip/event/tidy/pause/reduced fixture passes.|
| Existing Darmi/Sari |480 work samples,260 visible droplets and8 actual camera-facing checks pass; unknown grips remain unknown.|
| Existing Ujang |1,242 contacts/168 turns/26 grips and1,616 signed mesh-knee checks pass; unchanged pelvis limit and source identity.|

Logs are `.runtime/overnight-resident-{readback-headless,readback-native,focused-final,native-final}.log`, plus `overnight-{npc,tool,ujang}-existing-final.log`. Both final focused/native logs contain zero SCRIPT ERROR or Godot ERROR lines. `artifacts/godot/overnight-new-residents/` contains52 sequential raw480×270 PNGs and JSON from the real three-quarter village renderer. Native capture is approximately9MB, not an FPS or mobile device result.

## Pending before acceptance

The successful capture above shows the six models on the real dock, but no Nala size reference. The fixture source now adds actual `CharacterVisual` Nala beside them, and the body source adds rounded head layers and bounded work-hand motion. Those final followups still require a new focused/native run; do not relabel the earlier capture as final-source acceptance. Root requested this comparison to judge style and scale compatibility. Child native geometry must be visually reviewed beside the existing illustrated cast before any batch acceptance.

`village-routine06.gd` now requires all13 unique profiles when the six new canonical profiles are present, while retaining compatibility with the old seven-profile world. It exercises every profile in normal/reduced work–talk–home–rain routines, not just old adults. The expanded authoritative world is still shelter-owned; this branch has not run that13-profile commute yet. Root must register `resident-native-body.gd` in its world runner after acceptance.

Source-only geometry and palettes are original project code; no Noxe/PixelDoll/Sprite AI character code or third-party pixels are used. A separate built-in imagegen six-portrait draft exists outside runtime and is not used by these models. No generated portrait is claimed to supply four authored body views. This source candidate does not close the remaining full Nala gait, all child stair/commute contacts, anatomical tool grips or physical Windows/S23 acceptance.
