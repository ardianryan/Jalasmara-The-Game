# 06-B: compact Bahari conversation tray

Isolated branch `work/06b-dialogue-compact`, based on integration `75e2dc2`. The current integration PCK and browser fixture are unchanged while their acceptance run completes. This is a bounded conversation layout correction using the existing Bahari artwork and fonts, not a new HUD asset batch.

## Observed problem

The actual 667 × 375 Ujang conversation screenshot places parchment from approximately Y 125 to 360, covering about 63% of the viewport. `DialoguePresenter._layout()` forces a 340-logical-unit height regardless of message length. At the observed stretch ratio that becomes about 236 physical pixels. It also imposes an 84-logical-unit button, around 58 physical pixels, and a 132 × 164 logical portrait, even for short dialogue. The screenshot currently shows a partial typewriter line, but the full message is still too short to justify that fixed empty panel area.

The existing code detects portrait from logical width rather than physical orientation. `ViewportLayout` deliberately keeps a minimum logical canvas, so that test does not reliably describe a portrait phone.

## Candidate changes

- For physical landscape windows no taller than 480 pixels, measure the complete parsed message and speaker name at the actual text width before typewriter reveal. Reserve only that content height, panel padding and the action target, capped at 42% of the logical viewport height. The target for a genuinely single-line message is at most 34%.
- Preserve at least 16 physical pixels for body/name text and 48 physical pixels for the action hit target. The compact action is right-aligned rather than stretched across the full empty row.
- Use a 72 × 92 logical portrait badge and reposition its existing emotion indicator away from the text. Keep the same portrait frame, parchment, wooden button and brass border. No new bitmap is generated.
- Keep long authored text inside the scroll container; explicitly word-wrap it and retain all parsed text. The compact scroll viewport fits a whole number of text lines, avoiding partial glyphs at the bottom. Revealing more characters does not change tray height.
- Detect portrait from the physical window orientation, preserve existing larger-window behaviour, and account for safe insets in the panel bounds. Keyboard two-stage reveal/advance remains unchanged.

Energy 2 / rhythm 2 / motion 2 follow the user's existing comfy maritime pixel direction. The parchment supplies contrast for reading; the portrait and brass frame retain character identity. Reducing unused panel area leaves more of the living world visible without shrinking the text or tap target.

## Final verification

Godot 4.7.2 Compatibility on Apple M2. The root granted a serialized engine slot after browser QA released it. A first headless measurement caught a 35.19% single-line tray; padding and gaps were tightened while keeping the body and action minimum sizes. Native review then caught a partial third line at the long-text scroll boundary; the viewport was snapped to whole text lines and all focused/native checks rerun. The final images show two complete readable lines with remaining text available by scrolling, rather than cropped glyphs.

`scripts/tests/dialogue-compact.gd` **PASS** for nine short/paragraph/long cases at 667 × 375, 844 × 390 and 390 × 844, with neutral/thinking/shock states. It verifies complete text retention and scroll reach, stable height during typewriter reveal, keyboard Space's reveal-first contract, then a real `InputEventScreenTouch` routed through the viewport to the GUI button and exactly one advance.

| Physical viewport | Single-line panel height | Paragraph / long panel height | Body text | Action height |
| --- | --- | --- | --- | --- |
| 667 × 375 | 33.33%, 125 px | 39.63%, about 148.61 px | 16.68 px | 48.64 px |
| 844 × 390 | 32.41%, about 126.39 px | 38.52%, about 150.22 px | 16.61 px | 48.37 px |
| 390 × 844 | Existing portrait cap, 34.65% | Existing portrait cap, 34.65% | 16.37 px | 49.12 px |

Final regressions **PASS**: `analog-dialogue.gd`, `legacy-forest-ui.gd`, and `kedai-focus.gd`. The final import and all five final test/capture logs contain zero `SCRIPT ERROR`, `ERROR:` or assertion failures. The first import in the new worktree needed to populate font caches; import was repeated before the clean final log. The native audio driver emitted unsupported sample-playback warnings during text blips; audio behavior was not changed or accepted by this layout test.

Nine final native component images and `results.json` are under ignored `artifacts/godot/dialogue-compact/`. The background is the project's own actual night-porch screenshot from the integration browser acceptance run, supplied through `DIALOGUE_BACKDROP`. These are clearly component fixtures over an owned screenshot, not a new live-world browser run or a performance measurement.

Main review frames are `667x375-short.png`, `667x375-paragraph.png`, and `390x844-long.png`. Existing parchment, brass, portrait frame, wooden action, emotion indicator and readable font are preserved. No asset generation or new external dependency is involved.

```sh
"$GODOT_BIN" --headless --path client-godot --script ../scripts/tests/dialogue-compact.gd
DIALOGUE_CAPTURE=1 DIALOGUE_BACKDROP=/path/to/owned-game-capture.png "$GODOT_BIN" --path client-godot --script ../scripts/tests/dialogue-compact.gd
```

The focused test needs the current shared `WORLD` exported to `.runtime/world-map.json`, as used by the other world fixtures. It should be added to the main world runner when integrated. Long dialogue remains scrollable; the larger existing desktop and portrait presentation are not redesigned by this short-landscape increment.

## Delivery gate

- Hard Gate PASS: all authored text remains available; viewport bounds, minimum 16 px text and 48 px hit targets, keyboard and actual GUI touch were checked at three sizes. No invented performance or physical-device claim.
- Purpose Gate PASS: content measurement removes unused paper area; line-aligned scrolling prevents cropped glyphs; the existing brass/portrait art retains the game's identity.
- Liveliness PASS: existing comfy maritime pixel direction, energy 2 / rhythm 2 / motion 2, and restrained typewriter/emotion behavior remain. Height does not pulse as letters appear.
- Craftsmanship PASS: native images were inspected, the half-line defect corrected, and nine focused/native cases plus three relevant regressions rerun on final source. Integration/PCK remained untouched during the separate QA run.
