# Location-name overflow

Status: source candidate with focused native and headless acceptance. The actual baseline and first visually failed U+2026 attempt are preserved. No badge, portrait, resource, menu or control geometry changes. This is not included in the released b34d PCK.

The actual 667×375 public screenshot ended with `Hutan Pesisir Wrin` without an ellipsis. A native component fixture reproduced the same image with the current `GameHud`: actual font 24, logical label width 228, measured full-name width 242. The primary TextServer was ICU/HarfBuzz/Graphite. A parallel `TextLine` configured with that Label's font/size/width/overrun produced one ellipsis glyph at trim 18, so missing shaping support is not established. It is explicitly not the private Label shaped RID. The Ark font also contains an outlined U+2026 glyph.

BEFORE native run: exit 0, 5,517 ms, no `SCRIPT ERROR` or `ERROR`; integration `.runtime/hud-region-before.log` and `artifacts/godot/hud-region-overflow/before/{results.json,667-wringin.png}`. Four names were measured; `Bandar Hujung` and `Dangkalan Segaran` fit unchanged. The screenshot was inspected and confirms the clipped ending. This proves the visible regression, not an engine-internal root cause.

First AFTER on integrated 5064b1d exited 0 in 2,996 ms with no engine errors. All node/width/grapheme/resize assertions passed; `Hutan Pesisir Wrin…` measured 226≤228. **Visual acceptance failed:** its PNG remained byte-identical to BEFORE, SHA `dd760e00137d40f20b30490cdfe54d9efb53fbfa2dfe86ff75c410568903cc3a`. Both original files and `.runtime/hud-region-after.log` are retained. Shaping/size assertions therefore did not prove a visible correction.

Updated candidate: preserve the full area name separately and fit the displayed string using the actual font, size and label width. Use measured ASCII `...` in this pixel font after the U+2026 rendering attempt failed visually; no replacement font or custom drawing. It is appended only at composite-character boundaries returned by `TextServer.string_get_character_breaks`; names that fit remain intact. Layout/resize recomputes from the full name. Mouse filtering remains IGNORE: no new hover, tap or input interception is introduced. The pre-existing full-name tooltip remains stored; its accessibility is not newly claimed.

Prepared AFTER assertions cover four names, unchanged measured baseline rectangles, combining accents/emoji clusters, short-name preservation and narrow→wide→narrow refitting without new state. Default phase is `after`; headless execution skips image awaits/capture. Geometry assertions use the actual recorded baseline constants and need no ignored artifact. Native mode additionally requires a changed image if the original BEFORE PNG is present. `HUD_REGION_PHASE=after-ascii` preserves the first failed AFTER files. ASCII acceptance ran against integrated source `32914ae` plus the root-added final PASS print: native exit 0 in 2,672 ms and default headless exit 0 in 642 ms, both with PASS markers and no `SCRIPT ERROR` or `ERROR`. Four actual names, twelve combining/emoji width cases, all seven baseline rectangles and narrow→wide→narrow restoration passed. Wringin displays `Hutan Pesisir Wri...` at 222≤228 logical pixels; the long synthetic place name fits at 218≤228. Two shorter names remain complete. Native PNG inspection confirms three spaced visible dots; this is a component proof, not new browser/PCK release acceptance. Relevant primary API reference: [TextServer composite-character boundaries](https://docs.godotengine.org/en/stable/classes/class_textserver.html#class-textserver-method-string-get-character-breaks).

Tools: existing Godot 4.7.2 native Compatibility runtime, Python fontTools for the existing font's cmap/outline metadata, local source/Git and official Godot documentation. No asset, dependency, browser, export or account mutation was added.

Final evidence in the integration worktree:

- `.runtime/hud-region-native-ascii.log` and `.runtime/hud-region-headless.log`.
- `artifacts/godot/hud-region-overflow/after-ascii/667-wringin.png`, SHA-256 `1fd3f94a599811bf6dbd56e6b73272454d8c2d546671bb12266f809f95a09a08`.
- `after-ascii/results.json`, SHA-256 `22f6387f1b402d892db1e996ec5bc677465ea716406b1843da6cacc98eb7e21e`.
- The first U+2026 failed PNG and `hud-region-after.log` remain original. Default headless execution refreshed `after/results.json`; the earlier log retains the first attempt's complete node measurements. No original failure is relabelled as PASS.

GPU ownership was released after each authorized batch. No import/export, browser interaction, account access or published package change was performed for this fix. Root owns final combined-suite registration and any later export/release.


Root independently viewed all three native images: baseline and explicitU+2026 remained visually identical without a marker; final ASCII image displays the three dots. Source width tests alone were not accepted as a visual fix. The final fixture is registered as world check66, headless-safe and independent of ignored baseline artifacts. Focused native/headless acceptance does not replace a future full66 or actual Web export/browser check. The last full65 source run predates this narrow HUD change; active staging remains b34d, without this fix.


Root focused regressions on the corrected source: `hud-footprint.gd`, `hud-oxygen.gd` and `dialogue-compact.gd` all PASS/exit0, no SCRIPTERROR/ERROR. The old unsupported sample-playback warning remains in dialogue-compact; the other two logs contain no warning. Logs `.runtime/overnight-region-regression-*.log`, summary `overnight-region-regressions.json`. No new browser/export or full66 acceptance is implied.
