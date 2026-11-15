# Pollution bubbles at the dock and underwater valve

Status: local candidate based on `0c0fdff`. This report covers visual effects only; it does not change server progress, oxygen, damage, rewards, or pipe interaction geometry.

## Implementation

- The dock water renders at most 18 small purple surface rings on wet cells. The rings occupy two short stretches alongside the existing pier and use the land camera projection rather than a screen overlay.
- The underwater valve renders at most 12 rising rings in the 2.5D world. Its source is derived from the server-authored `valve` puzzle location plus an outlet offset of `(-34,+112)` world pixels. This places the lowest rings at the left copper elbow in the corrected, grounded `OceanActors.gd` sprite. The 3D pool sits at depth 28, immediately in front of the reef's depth-26 front face, so the rocks no longer hide the emission. Ring radii were raised about 25% after actual-size review to keep the sparse plume readable.
- Existing server-backed state controls the effect: repairing the valve lowers its plume; completing all boss hits fades it during the victory sequence; `player.progress.bossDefeated` keeps it absent after extraction and reload. The visible effect never writes these states.
- Both pools update at about 15 Hz, cull outside the local camera region, and reduce motion with the existing `EnvironmentState.reduced_motion` preference.

## Verification

- `scripts/tests/pollution-bubbles.gd` checks the boss-hit boundary, persisted completion, valve reduction, world anchors, reduced-motion offsets, and fixed pool sizes. It is registered in `scripts/verify-living-world.mjs`.
- `scripts/tests/pollution-bubbles-render.gd` captures both 667×375 and 844×390 before/after images and checks that every dock particle lands on water, that the underwater plume changes pixels at actual display size, and that oxygen and coins remain unchanged.
- Native A/B with the companion, grounded `OceanActors.gd` change from pipe-grounding commit `3e5e4b36ca55a1146e91f2e70328e75c3f6a6801` copied into this worktree passed at both 667×375 and 844×390. All 18 dock rings appeared on wet cells; 12 underwater instances were active and a pixel assertion verified the plume was visible. Both effects faded after boss completion. The copied `OceanActors.gd` was restored before the pollution commit: the final integrated build must merge the pipe-grounding change first and recapture before release.
- `Godot --headless --path client-godot --script ../scripts/tests/pollution-bubbles.gd`: PASS. Final native render command: `/Users/ardianryan/Documents/Jalasmara/.runtime/godot/Godot.app/Contents/MacOS/Godot --rendering-method gl_compatibility --path client-godot --script ../scripts/tests/pollution-bubbles-render.gd`: PASS at 667×375 and 844×390 after the ring-size revision. It produced no script errors or ObjectDB leak warning. An earlier candidate had a two-object leak warning; freeing the fixture node before exit resolved it.

Curated native proof (667×375, project gameplay frames): [dock before](../visual/pollution-bubbles/surface-before-667x375.png) (SHA-256 `bf4e18bd`), [grounded underwater valve before](../visual/pollution-bubbles/underwater-before-667x375.png) (`79366def`), and [underwater after](../visual/pollution-bubbles/underwater-after-667x375.png) (`494b0bd3`). These are candidate screenshots with the pipe change present locally; the full uncurated 844×390 images and `results.json` remain under ignored `artifacts/godot/pollution-bubbles/`.

## Tools, assets, and release status

The rings are project-authored procedural geometry in Godot 4.7.2 Compatibility. No external artwork or plugin was added; the existing project-owned ocean prop atlas supplies the copper elbow. The source was merged into local `main` as `be58e0b` after the pipe correction `8f207b5`; it has no verified Web export or CI PCK and is not on staging yet. Native Godot on Apple M2 is the evidence level; browser WebGL, Windows, Samsung S23, and audiovisual performance remain untested.
