# Balai resident interaction regression

The permit board and Ki Lurah share the evening destination `(940, 310)`. The regression exercises the actual `Main.gd` selection, interaction and resident lookup methods, actual `HomesteadUI.gd`, actual `Player.gd` and the shared `DialoguePresenter.gd`. It attaches Main after the host node has entered the tree, avoiding startup authentication and network requests.

## Verified

`scripts/tests/balai-resident-interaction.gd` passes 19 scenarios:

- At the exact overlap, actual selection chooses Ki Lurah. At resident offsets ±1 px, selecting the resident still opens the Balai service page. With the chief at `(941, 310)` and Nala at `(940, 310)`, actual selection chooses the board and opens the same page.
- At 667×375, 844×390 and 390×844, the first action is the chief conversation; the eligible garden permit action remains enabled and reachable by Tab. Enter activates Talk and Back. Panels fit the viewport; service actions measure at least 56 px and text at least 16 px.
- Talk closes the service page and uses the existing shared dialogue presenter with the actual resident name and evening text. Enter completes Main's dialogue chain.
- A pending service operation (`busy=true`) prevents Talk from closing the panel or creating a dialogue. Releasing busy allows normal interaction.
- Daytime text is selected when the chief is nearby. An absent chief, a chief at the daytime workplace, either proximity limit, and an active dive do not create a phantom conversation action.
- Permit eligibility and already-granted states retain their existing behavior. World, player and homestead state are unchanged; `ApiClient.serial` is unchanged.

The exact-overlap expectation follows observed Godot selection order, rather than imposing new board priority. Both actual selection paths are covered.

## Commands and evidence

Run from the repository root after generating `.runtime/world-map.json` through the existing world-check setup:

```sh
.runtime/godot/Godot.app/Contents/MacOS/Godot --headless --path client-godot --script ../scripts/tests/balai-resident-interaction.gd
.runtime/godot/Godot.app/Contents/MacOS/Godot --headless --path client-godot --script ../scripts/tests/homestead-ui.gd
.runtime/godot/Godot.app/Contents/MacOS/Godot --headless --path client-godot --script ../scripts/tests/dialogue-compact.gd
```

All three exited 0 with Godot 4.7.2. Logs in the isolated worktree are `.runtime/balai-focused.log`, `.runtime/balai-homestead-ui.log` and `.runtime/balai-dialogue-compact.log`. A combined scan found no `SCRIPT ERROR`, `ERROR:` or failed assertion. The focused test uses the root's busy-guard correction through `87ce67f`.

Existing homestead coverage also passed its focus-following scroll, pending-operation recovery and reading-pause checks. Existing compact dialogue coverage passed nine size/content combinations; its separate 48 px dialogue-action contract remains unchanged.

This is component and integration evidence from the actual Godot UI. It does not replace the continuing browser shelter traversal or rendered mobile acceptance. No production file or world-check runner is changed by this regression commit. The engine slot was released after confirming no owned Godot process remained.
