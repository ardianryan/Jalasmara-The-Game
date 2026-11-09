# Wardrobe and modular gear: source audit and focused browser preparation

Status: source/CPU review only. No Godot, browser, proxy, API reset or production outfit behavior changed for this package. Runtime to test is export3/PCK `73d45630ab69033ac36a64740ecc73ecdb7363c9f99805222b6a9237dcb2d18b`,64,494,656 bytes. Integrator owns the GPU grant and acceptance.

## Existing behavior and evidence

`Player.gd:108` already changes daily to diving beyond x1450/y1230 and back to daily below x1390 or y1200. The hysteresis retains the last outfit in the curtain. Current authored posts have centers1430/1200 and1430/1380; the renderer builds the same changing arch. The legal midpoint1290 is within both posts and above the switching threshold. This audit found no absent booth behavior requiring a gameplay patch.

`Forest.gd` creates the avatar in explorer clothing with satchel and no tank/net. Existing export3 `artifacts/browser/plan06-layout-c2ab0b07-8681-4f15-9e8d-f255f75f0221/results.json` retains actual final snapshot outfit `explorer`, equipment `{net:false,satchel:true,tank:false}` after real joystick/upper-bridge/save/reload. This is an inspection of that retained actual result, not a new forest test. The old `godot-browser.mjs` also asserts daily/diving/forest states, but its cardinal key navigation predates the accepted left-view input contract and should not be reused unchanged.

`CharacterVisual.gd` loads equipment-free base art and separate outfit atlases. `CharacterEquipment3D.gd` constructs actual `DetachableOxygenTank`, `DetachableJala`, `DetachableFieldSatchel` and `DetachableExplorerVest` nodes. Land and ocean actor mirrors call `update_attachment` on this helper. The clothing atlas supplies the explorer vest and disables the duplicate vest mesh. Existing `character-outfits.gd` verifies four identities, three outfits, bounded actual mesh count and visibility, including the no-duplicate legacy path. Existing native `player-outfit-world.gd` explicitly sets each outfit; it proves rendering/direction samples, **not** automatic booth activation.

Current opt-in browser snapshots expose requested `outfit` and `equipment`, not `CharacterEquipment3D.debug_status()`. The proposed browser assertions and screenshots must therefore be labelled requested gear state plus visual review. They do not independently prove actual attachment-node visibility in the browser. A future diagnostics-only renderer field could expose that actual helper state on a newly exported package; this preparation does not change the runtime or pretend73d has that field.

## Bounded new gate

`PLAN06_ROUTE_MODE=wardrobe` reuses the guarded local UUID fixture, real keyboard input matrix, actual server action ledger, screenshot capture, position save/reload and targeted cleanup from `plan06-layout-browser.mjs`. It declares story2/dive,200coins,empty inventory, calendar day2 at10:00 and a UUID whose natural day2 weather is dry. Seed/gear acquisition and a full story route are not claimed. No state is written after the initial fixture setup except through the actual game.

The helper derives the booth center from both authored support footprints, validates radius12 floor clearance and segments, and rejects drift outside the production hysteresis bands. Current legal route:

1. Daily approach1360/1290 → curtain1430/1290: retains daily.
2. Cross1490/1290: diving with tank/net, no satchel.
3. Backtrack1430/1290: retains diving; cross1360/1290: removes tank/net and returns daily.
4. Real route to ladder1485/1330 → actual `dive/start` → boat and empty `dive/extract` → walk west through booth.
5. Save and reload the reached daily position; verify story2/night,200coins and empty inventory. Empty extraction intentionally changes the existing story stage to night; this is not a no-mutation route.

The route cap remains five minutes after initial attachment. Water uses the existing swim input path; land must use the current `land.view.motion` matrix. There is no teleport between checkpoints and no replay of the long hub/forest route.

Two meaningful CPU tests pass: actual current geometry/route/no mutation, and rejection of a missing support or obstructed crossing. `node --check` passes for the browser harness. Browser gate remains **PREPARED, NOT RUN** until the integrator grants its slot:

```sh
APP_TEST_ORIGIN=http://localhost:3111 PLAN06_ROUTE_MODE=wardrobe \
PLAN06_EXPECT_PCK=73d45630ab69033ac36a64740ecc73ecdb7363c9f99805222b6a9237dcb2d18b \
PLAN06_EXPECT_PCK_BYTES=64494656 \
node --import tsx scripts/plan06-layout-browser.mjs
```

No new asset, generator, library or license change. Existing character art/provenance remains unchanged. This is not acceptance of complete natural walking, anatomical arm contact or every identity's attachment occlusion.
