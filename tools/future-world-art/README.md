# Future-world pixel props

`python3 tools/future-world-art/generate.py` redraws the 13 transparent RGBA sprites in `client-godot/resources/art/future-world-v1/` and updates their SHA-256 manifest and contact sheet. `python3 tools/future-world-art/test_assets.py` checks size, alpha, pivot, phase gates and animation frames.

Every pixel is authored through Pillow drawing primitives in `generate.py`; no image model, game screenshot, commercial kit, brand logo or external texture is sampled. Pillow 11.3.0 is an offline authoring dependency and is not bundled into the Godot game. Do not place the sprites in the current world by importing this folder alone. The fire and damaged-forest sprites require a future server-owned state transition. See [asset contract](../../docs/assets/future-world-props-v1.md).

`node --experimental-strip-types tools/future-world-art/survey_layout.mjs` checks the [provisional connected-floor reservations](../../docs/reviews/future-camp-connected-floor-survey-2026-11-16.md) against the current shared hub map. It temporarily models proposed obstacles in memory; it does not place assets or change the game.
