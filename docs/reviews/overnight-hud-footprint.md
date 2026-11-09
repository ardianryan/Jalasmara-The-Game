# Persistent HUD physical-size correction

The actual native baseline confirmed the user's oversized desktop HUD report. At1440×900, persistent body text was30px, the identity plaque636.7×130px, actions126.7px square and utility buttons80px. The previous logical minimums scaled up with the960×540 canvas. Touch667×375 and390×844 already measured16.4–16.7px body and48.5–61.1px actions/utilities.

GameHud now uses18px desktop body,48px utility targets and56px actions in physical viewport units, while preserving the existing touch branches. Existing Bahari badge/button/frame art remains. Desktop shortcut captions/icons follow the smaller badges. The portrait frame becomes a46px square with both text rows beside it. Desktop oxygen uses the already measured compact stats-row layout rather than shrinking the old landscape rows through their frame. Desktop minimap/message sizing follows the same physical factor. There is no new shader, asset, quality downgrade, account or gameplay rule change.

## Native evidence

Final1440×900 measurements:18.33px body, identity390×80.7px, utility48.3px, action56.7px, oxygen300×152px. Touch measurements remain unchanged. The body check retains16px touch and18px desktop, standalone buttons48–65px, compact identity bounds, viewport containment and modal hiding. Existing `hud-oxygen`, `analog-dialogue` and private `performance-capture` regressions passed. After image review corrected the shortcut child positions and oxygen frame clearance, final footprint/oxygen checks passed again with zero engine/script/assertion errors.

Baseline is preserved in the combined integration worktree at `artifacts/godot/overnight-hud-footprint/before/1440x900-night.png` and `results.json`. Final images/results are in this lane's `artifacts/godot/overnight-hud-footprint/after/`, including1440×900 night/ocean,667×375 night and390×844 ocean. The plain background identifies this as actual HUD component proof, not an in-game world screenshot. Initial/final logs remain `.runtime/hud-footprint-size-after.log`, `.runtime/hud-footprint-size-final.log` and `.runtime/hud-oxygen-size-final.log`. Intermediate after-PNGs were overwritten by the final run; the original before directory is retained.

Run after acquiring the serialized engine slot: Godot `--path client-godot --script ../scripts/tests/hud-footprint.gd`; default phase is `after`. To capture baseline, use `HUD_FOOTPRINT_PHASE=before` only on the old GameHud source. The fixture reports real window transforms/rectangles rather than assuming a960px viewport. Existing artwork licensing is unchanged.

## Remaining acceptance

Root still needs to merge/export the candidate and inspect actual browser gameplay, including night-service keyboard/touch scrolling. The pinned long complaint leaves recipe actions below the667px viewport's fold; component bounds do not prove those actions are all initially visible or the night flow feels uncluttered. Physical Windows/S23 performance remains unmeasured until the user records actual sessions with the opt-in private recorder. No native M2 result is represented as that hardware.

## Complete-frame scaling and desktop reading follow-up

Integrator image review rejected the first smaller badges: squeezing existing8/16-logical-pixel nine-slice borders into29logical pixels fragmented the visible frame despite passing hit-rectangle checks. The final correction preserves each badge's complete local48px geometry and scales its whole control into physical pixels, including style corners, icon, padding and shortcut caption. Actions use complete56px geometry. The identity/deck frame uses the same complete-frame scaling. Physical hit rectangles and touch branches are unchanged. Final inspected1440×900 night/ocean images now show full closed badge boxes and contained action/key captions; the previous after-PNGs are replaced, while the original baseline directory remains.

Root's first headless footprint run also stalled on `RenderingServer.frame_post_draw` (43s; own process terminated, root log retained). The fixture now guards only native capture awaits/save calls when headless; all numeric/containment/modal assertions remain. The first actual headless pass was in the final batch, not earlier. That13.53s batch passed headless footprint, native footprint, headless oxygen, native dialogue, quiz, night service and book with zero errors. Logs are `.runtime/{fixture}-{headless|native}-art-final.log` in this lane.

Shared reading metrics now independently use18px when physical window width is at least1024, and16px on narrower windows. Dialogue and quiz regressions explicitly enforce that distinction. Final desktop body is18.33px and the longest authored-test dialogue remains31.48% of desktop height under its32% cap. Mobile reading sizes are unchanged. This is component/native acceptance; actual browser night scrolling and performance download remain pending the combined export.
