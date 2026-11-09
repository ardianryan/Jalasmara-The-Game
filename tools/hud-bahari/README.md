# Jalasmara Bahari HUD artwork

Original image generation from written project art direction only: warm brass, walnut/leather, deep teal, parchment, rope and restrained woven inlay. The user referenced IndigoLay's Pixel HUD UI for finish and function. No kit image was downloaded, edited, fed to generation, or shipped; no third-party pack license is attached to this original artwork. Project original-art terms apply.

```sh
python3 tools/hud-bahari/prepare.py
python3 tools/hud-bahari/test.py
```

Requires Pillow. Tracked original outputs and exact prompts are in `assets/source-2d/hud-bahari-v1/`; runtime sprites and extraction metadata are in `client-godot/resources/art/hud-bahari-v1/`. `source.json` records source SHA256; runtime `atlas.json` records every primary output hash and ninepatch margins.

Verification checks the committed source/runtime file hashes and rebuilds into a temporary directory. Rebuilt dimensions and every RGBA byte must match the committed sprites. PNG compression bytes may differ across Pillow/zlib versions; this does not permit pixel differences. Temporary verification keeps its preview in the temporary output instead of rewriting the source preview.

Preparation thresholds alpha at128, removes detached neighboring-cell fragments, and resizes using nearest only. Four fullscreen corners and speaker waves remain intentionally disconnected. Wide title/dialogue components extend outside nominal generated cells, so their extraction regions are explicitly widened. Rings/portrait/bar interiors retain real transparency. All text and numbers must be rendered by the engine over the images; none is baked into art.

Buttons use64px images with8px ninepatch borders; panels use128px/16px borders. Glyph defaults are48px with additional32px files. Use nearest filtering. Do not stretch circular minimap/joystick/portrait frames as rectangular ninepatches. Menu texture does not set hit target size: retain at least56logical px touch controls. Dark wood/teal centers need cream text; parchment needs dark ink.

Actual-size icon preview and runtime frame contact sheet are saved alongside sources. These verify asset readability and extraction, not final HUD placement; engine integration/browser acceptance is owned separately.
