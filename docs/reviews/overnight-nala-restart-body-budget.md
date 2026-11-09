# Retained restart landing: conditional body-duration preview

The lower-body pilot remains OFF. Runtime source `b05a211` completed the dock ascent and passed the earlier reversal blockage, then rejected a later downhill stop/resume at requested pelvis drop 8.56817853 source pixels. The combined fixture retained its real facing and original contact history. No native or full16 acceptance follows from this investigation.

The rejected run is `artifacts/godot/nala-terrain-dock-up-down-current-foot-body-b05a211`; its log and literal command are under `.runtime/overnight-nala-*b05a211*`. World SHA is `28455e6f7ec053d8e090457cae6e747d848aa3fd994e797e32608a0710dd5743`. The right foot was still free when resume replaced its near settling destination with the frozen lower-flat landing; the opposite foot remained planted at height 27.43576. At the later failure, the body already descended at the complete allowed geometry rate toward actual current ground zero. Its remaining height deficit was approximately 0.6936 world units. Actual ankle motion was below the existing five-times-distance guard. Lowering the support target or relaxing the pelvis limit would not repair this state.

`model_restart_body_budget.py` reconstructs the retained target with the original shoe alpha corners and sole markers, plane rotation, pivot decay, H envelope, unchanged three-unit lift, current body-rate update and both original leg annuli. It reproduces the failed drop as 8.56775262. Independent peer review found a worst recorded-row ankle discrepancy of 0.005185 world units, consistent with the renderer inverse tolerance; this is a frozen replay, not an exact coupled simulation.

The dense offline comparison checks 30/60/120/2000 Hz and a recorded-prefix schedule. Duration 10 fails. Duration 11 passes those five frozen schedules with maximum drop 7.785918 and ankle ratio 2.670748; 11.25 has additional margin. These comparisons do not establish a universal minimum duration or unchanged future source-view/body admission.

The inexpensive preview caches 32 normalized foot poses using only the two original sole markers, then searches 65 quarter-unit duration candidates without additional terrain queries. Marker H never exceeds full-mask H in this replay; their largest ankle-height difference is 0.379036 world units. Each candidate intersects a **shared variable hip-height interval** with both original outer spheres and removes each inner forbidden interval. Horizontal tangency follows the runtime's strict rejection. The preview retains durations 11.25 through 18.75 and selects 11.25.

A prior fixed-eight-pixel-drop sphere estimate wrongly rejected feasible longer steps when the high planted ankle lay above the lowered hip. The explicit duration-17.5/common-two-pixel-drop counterexample is preserved. The old estimate remains labelled superseded diagnostic output; it is not a necessary bound. Nine CPU unit tests cover common and disjoint leg heights, inner bands, tangency and this distinction.

Reproduce the offline checks:

```sh
python3 -m unittest discover -s tools/player-gait -p test_body_budget_intervals.py
python3 tools/player-gait/model_restart_body_budget.py --run artifacts/godot/nala-terrain-dock-up-down-current-foot-body-b05a211 --world .runtime/world-map.json --output .runtime/restart-body-budget-common-hip-b05a211.json
```

The cached preview remains conditional on its original view, Q/C trajectory and optimistic body baseline. It does not prove continuous feasibility between its 32 samples, real body-target following, a future view switch, or full-mask clearance. It is suitable for proposing a bounded duration candidate only. The renderer must retain its full original-mask, ankle, pelvis, inner/outer reach, frozen-landing and contact guards. No runtime duration change, engine run, speed change or fixture reset was made in this CPU checkpoint. A cheap isolated runtime proposal and peer review precede the next combined ascent/descent run; full16, current32flat/raw, facing recovery, moving native sequences, arm/contact phase and actual module cost remain open.

## Isolated runtime proposal after CPU checkpoint

`NalaRestartBodyBudget.gd` ports the cached-marker/common-height preview. Its only caller is a physical-pilot `_begin` reached by resuming an unfinished settlement on a real descending ramp; descent compares actual path-ground heights rather than the airborne sole. Ordinary startup, steady steps, flat ground, authored stairs and default movement do not call it. Lower supplies the current body-leg metadata separately from each held foot's source geometry, so hip locations and fixed lengths are not confused with the planner's historically named `hips` argument, which actually contains sole offsets.

The original frozen target and H start offset remain unchanged. A selected quarter-unit duration can only increase the existing terrain curve duration; its base-curve bound is rescaled to the longer duration. If no candidate fits or a point inverse fails, the plan becomes invalid and the existing rig/fixture rejects it. This does not project a bad pose into a passing fallback. Full original-mask rendering, true body following, plane backtracking and all hard guards remain independent of the preview.

Per-plan telemetry records the helper's elapsed microseconds, 64 requested marker-point inversions, 32 cached samples, a maximum of 65 scalar candidates and the selected candidate count. The inversion count is **not** the number of underlying ground queries: each inverse can perform several terrain queries and backtracks. Timing is only measured when a new eligible plan is built. It is not an FPS or target-device cost claim. The terrain fixture pins the new helper and checks the bounded work, unchanged frozen destination and conditional status. Source/CPU review precedes the next fresh actual combined ascent/descent; this source has not yet been parsed or executed by Godot.
