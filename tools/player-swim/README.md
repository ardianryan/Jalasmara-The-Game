# Swim pose authoring

`python3 tools/player-swim/build_swim_atlas.py` rebuilds four compact swim strips from the project's existing modular base portraits. It selects the three distinct poses in row two, downsamples each 418 px source cell to 112 px, applies one 64-color palette across the strip, and writes a source/output SHA-256 manifest beside the PNGs. Pillow is an offline authoring dependency; Godot loads only the generated PNGs.

The animation phase is driven by actual swim displacement in `CharacterVisual.gd`. The source has only three different poses, so this is a cadence and pixel-grid cleanup, not newly drawn eight-way underwater character art. Keep the original `*-base-v1.png` sources; the generated strips inherit the project's artwork terms. Review the strip at 1:1 and a native gameplay capture before accepting a regenerated atlas.
