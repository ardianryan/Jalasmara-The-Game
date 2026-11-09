# Next native verification for the area-preserving house candidate

Prepared CPU-only after `de80e12`, on `work/06b-house-alignment`. These commands have **not run**. The website lane owns the shared GPU until it releases public smoke. Current release geometry stays frozen at layout 9; this separate candidate emits layout 10. The integrator must explicitly grant the engine slot before import, headless checks, native captures or export.

The active choice preserves area, physical axis aspect, center, height and elevation for seven houses. It does not enlarge all buildings to their old bounding boxes. Checkpoint A `a8d03e6` remains historical; current source includes option B `de80e12`. The complete 86-test CPU/API suite and typecheck passed before this capture fixture was added. No runtime source is changed by the fixture.

## Prepare the exact source fixture

Run from `Jalasmara-06-house-alignment`. If the integrator first rebases onto its final race/Nala package, repeat typecheck/API tests and record that resulting source SHA. Do not merge layout 10 into the current release only to obtain screenshots.

```sh
git rev-parse HEAD
mkdir -p .runtime
node --experimental-strip-types --input-type=module \
  -e 'import {WORLD} from "./packages/shared/src/world.ts"; process.stdout.write(JSON.stringify(WORLD))' \
  > .runtime/world-map.json
npm run typecheck
npm test
```

The frozen `apps/api/test/fixtures/hub-layout9.json` supplies the before geometry. Its hash is recorded in the candidate review. It is not fetched from staging or reconstructed from layout 10. There is one Godot renderer throughout; no extra engine or bitmap assets are introduced.

## Execute only after the engine grant

Use the repository's installed Godot 4.7.2 binary; the absolute path below is the existing local installation. No browser may run concurrently.

```sh
/Users/ardianryan/Documents/Jalasmara/.runtime/godot/Godot.app/Contents/MacOS/Godot \
  --headless --editor --path client-godot --quit \
  > .runtime/house10-import.log 2>&1

/Users/ardianryan/Documents/Jalasmara/.runtime/godot/Godot.app/Contents/MacOS/Godot \
  --headless --path client-godot --script ../scripts/tests/hub-house-alignment.gd \
  > .runtime/house10-frames.log 2>&1

/Users/ardianryan/Documents/Jalasmara/.runtime/godot/Godot.app/Contents/MacOS/Godot \
  --headless --path client-godot --script ../scripts/tests/shelter-architecture06.gd \
  > .runtime/house10-roofs.log 2>&1

/Users/ardianryan/Documents/Jalasmara/.runtime/godot/Godot.app/Contents/MacOS/Godot \
  --headless --path client-godot --script ../scripts/tests/village-routine06.gd \
  > .runtime/house10-routines.log 2>&1

GODOT_BIN=/Users/ardianryan/Documents/Jalasmara/.runtime/godot/Godot.app/Contents/MacOS/Godot \
  WORLD_REPORT_DIR=.runtime/house10-world npm run check:world \
  > .runtime/house10-world.log 2>&1

/Users/ardianryan/Documents/Jalasmara/.runtime/godot/Godot.app/Contents/MacOS/Godot \
  --path client-godot --script ../scripts/tests/hub-house-alignment-render.gd \
  -- --output=res://../artifacts/godot/06b-house-alignment \
  > .runtime/house10-native.log 2>&1
```

Run these sequentially and inspect each exit status and full log before proceeding. A PASS line beside a `SCRIPT ERROR`, `ERROR:` or assertion is a failed run. The world runner now contains 46 checks; inspect its generated JSON and per-script logs. A timeout or parse failure must stop the pipeline, not leave an assertion process running indefinitely. Release the shared slot after closing every owned Godot/native process, even if acceptance fails.

## What each proof must establish

1. `hub-house-alignment.gd`: eight actual native building frames, including unchanged Griya, are orthogonal and follow the common map axes. All 32 transformed footprint corners agree with the emitted manifest and the client's real collider. Five physical awning plans share their building axes; all ten supports exist. The camera remains azimuth −45° / elevation 35°.
2. `shelter-architecture06.gd`: all seven NPC bodies fit beneath actual roof geometry using the actual camera basis, with cutaway limited to the covering panel. This is stronger than checking a station dot against a bbox. Do not move stations or enlarge roofs merely to conceal a failure.
3. `village-routine06.gd` and the complete suite: real activity navigation, pause/resume, rain destinations and occupied-floor constraints remain valid. Roof metadata alone does not prove citizens arrive.
4. The 28-frame native fixture compares **old layout 9 metadata and new layout 10 metadata using the same current renderer**, seven unchanged building identities, day/night, the same default left view and the same player markers. It is not an old-runtime replay. Every frame must report one rendered Nala and foot error below 0.01. There are no artificial NPC teleports or server mutations; the stationary component marker is not claimed as gameplay traversal.

The fixed comparison markers below were checked CPU against both layouts at 13 px clearance. The native fixture independently checks them with `LandCollision.is_walkable` before capturing.

| Building | Identical comparison marker in both layouts |
| --- | --- |
| Kedai | 560, 650 |
| Beno | 1300, 615 |
| Corporate post | 1990, 300 |
| Balai | 940, 320 |
| Ratih | 465, 330 |
| Sari | 1325, 300 |
| Tedi | 1005, 995 |

Inspect each before/after pair for a visible front and side, unchanged center/height, believable proportions, roof/wall seams, attached porch beams and posts, a usable door approach and night lamp placement. Reject a comparison if the facade, roof or marker is clipped outside the image; a passing transform assertion does not repair framing. Check Griya with the existing accepted fixture so its deck alignment is not silently changed.

After native review, export a separately pinned candidate package and rerun actual-game house approaches and all seven rain conversations through input and API saves. Confirm layout 8/9 reload migrations, actual movement after recovery and position ACKs against the new package. The current release's API/browser evidence cannot automatically accept layout 10. Do not claim comfy finishing or physical Windows/S23 performance from these component frames.
