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

## Actual local browser result

Integrator explicitly granted the exclusive browser slot after merging46601cb as integratione2c4441. The command above ran against the actual existing3111 host and pinned73d runtime; no new build/export was needed. Own UUID `695fa150-9380-4880-9042-2e9ddce9cc50`. Browser session74607 exited0 and the slot was explicitly **RELEASED** before this CPU report.

**4/4 checks PASS**, outcome `completed`,73,115ms after initial attachment (below the five-minute cap),105 land-input matrix pulses and0legacy pulses. All recorded operation statuses were200;39 surface-position synchronizations were observed. The non-position action records were the actual `dive/start` and empty `dive/extract`. There were0browser errors and0gameplay API failures. Targeted Mongo/Redis cleanup completed: `ownTemporaryPlayerRemoved=true`; the existing harness asserts players/receipts/shifts/owned sessions gone. No existing account or owner data was used.

Actual checkpoint positions and requested state:

| Checkpoint | Actual logical position | Outfit / tank / net |
| --- | --- | --- |
| Declared dock approach |1360,1290|daily /false /false|
| Curtain approached from village |1428.9408,1286.5760|daily /false /false|
| Crossed to ladder side |1487.0930,1292.3564|diving /true /true|
| Curtain approached from ladder |1428.0109,1291.3083|diving /true /true|
| Crossed back to village |1362.6082,1288.3929|daily /false /false|
| Actual ocean entry |1107.3225,470|diving /true /true|
| Post-extraction village side |1362.3521,1293.0547|daily /false /false|
| Reloaded dock position |1344.3286,1291.8800|daily /false /false|

Satchel wasfalse at every dock assertion. Empty extraction intentionally advanced story stage from dive to night, retaining story day2,200coins and empty inventory. Reload recomputed daily state at the saved legal village-side position. Save/reload position tolerance is25logical units; this run differs by18.06units, so it is **not an exact-coordinate persistence claim**. The immediate reload screenshot shows the existing temporary calendar-writer lease message; this narrow wardrobe gate does not wait for lease recovery. The earlier public full6 and host-only actual writer-reacquisition proofs remain separate.

Original screenshots were inspected. The daily approach and reloaded daily player are clearly visible beside the rendered changing arch. On the eastern crossing screenshot, the booth shade/curtain partially occludes Nala; this image alone cannot approve the complete worn tank/net artwork or its front/back sorting. The underwater swimmer is present but small at this viewport. This is a functional current-browser transition PASS, **not** a new proof of all actual attachment nodes, complete modular gear visual quality, every identity/direction, or natural walking. The existing independent native node/visibility proof remains necessary and distinct.

Evidence directory in integration: `artifacts/browser/plan06-layout-695fa150-9380-4880-9042-2e9ddce9cc50/`. Log `.runtime/overnight-wardrobe-browser.log`.

| Original artifact | SHA256 |
| --- | --- |
| `results.json` |`a60c819c192e89c9bcc7f299c2a71690d0ab864ecfd4ab7dccb83c2d996b91cc`|
| `wardrobe-crossing-equips-diving-tank-and-net.png` |`3fb234b890f9e715c5c4cb0c6afca4a58b3470f609e457c90a76a43a4ff46498`|
| `wardrobe-actual-ocean-entry-diving-state.png` |`e0d464516a7ff8c997b7f1a7a0d83b41d16a29ac0438b06754b5d7bdb0c5512b`|
| `wardrobe-daily-dock-position-after-reload.png` |`e7831d33dc9f4e5fe7e1efff2dfca5f7e4c56aff8bd2fc00b533b6dbc30af1b7`|
