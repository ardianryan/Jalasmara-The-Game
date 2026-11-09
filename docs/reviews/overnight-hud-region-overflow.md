# Location-name overflow

Status: narrow source candidate; actual baseline reproduced, AFTER acceptance pending. No badge, portrait, resource, menu or control geometry changes. This is not included in the released b34d PCK.

The actual667×375 public screenshot ended with `Hutan Pesisir Wrin` without an ellipsis. A native component fixture reproduced the same image with the current `GameHud`: actual font24, logical label width228, measured full-name width242. The primary TextServer was ICU/HarfBuzz/Graphite. A parallel `TextLine` configured with that Label's font/size/width/overrun produced one ellipsis glyph at trim18, so missing shaping support is not established. It is explicitly not the private Label shaped RID. The Ark font also contains an outlined U+2026 glyph.

BEFORE native run: exit0,5,517ms, no `SCRIPT ERROR` or `ERROR`; integration `.runtime/hud-region-before.log` and `artifacts/godot/hud-region-overflow/before/{results.json,667-wringin.png}`. Four names were measured; `Bandar Hujung` and `Dangkalan Segaran` fit unchanged. The screenshot was inspected and confirms the clipped ending. This proves the visible regression, not an engine-internal root cause.

Candidate: preserve the full area name separately and fit the displayed string using the actual font, size and label width. An explicit ellipsis is appended only at composite-character boundaries returned by `TextServer.string_get_character_breaks`; names that fit remain intact. Layout/resize recomputes from the full name. Mouse filtering remains IGNORE: no new hover, tap or input interception is introduced. The pre-existing full-name tooltip remains stored; its accessibility is not newly claimed.

Prepared AFTER assertions cover four names, unchanged measured baseline rectangles, combining accents/emoji clusters, short-name preservation and narrow→wide→narrow refitting without new state. Native image review and focused execution remain required before acceptance. Relevant primary API reference: [TextServer composite-character boundaries](https://docs.godotengine.org/en/stable/classes/class_textserver.html#class-textserver-method-string-get-character-breaks).

Tools: existing Godot4.7.2 native Compatibility runtime, Python fontTools for the existing font's cmap/outline metadata, local source/Git and official Godot documentation. No asset, dependency, browser, export or account mutation was added.
