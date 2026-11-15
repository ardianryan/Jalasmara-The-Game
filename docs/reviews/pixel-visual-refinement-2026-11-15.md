# Pixel visual refinement: underwater character and reef

The owner asked to bring the game closer to the colorful, comfortable pixel-art moodboard after the first swim/reaction release. The earlier 112-pixel swim strips mixed soft illustration edges into small game pixels, and the oxygen cylinder was barely legible behind the swimmer. This package keeps the existing source portraits and gameplay contract while changing their pixel treatment and the visibility of the existing ocean backdrop.

## Changes

- Regenerated all four three-pose swim strips from the same project portraits with one 28-color palette per appearance, firmer binary alpha and removal of isolated upscaling specks. A small cyan diving visor is drawn at each portrait's measured face anchor. The 112×112 frame and frame order are unchanged, so swim cadence, hit and shot timing are unchanged.
- Shortened and darkened the detachable oxygen cylinder, and positioned it along the swimmer's upper back where it remains visible without covering the face or net. The same modular 3D node is retained; this does not bake equipment into the character sprite.
- Raised contrast and visibility of the three existing ocean parallax layers. Card count, shader operations, parallax factors, lighting controls and reduced-motion behavior are unchanged.

The four original source portraits remain untouched. `tools/player-swim/build_swim_atlas.py` is the reproducible authoring script, and the regenerated `provenance.json` records input/output SHA-256. The 28-color cleanup and visor use Pillow offline; no image-generation service, moodboard art or new runtime dependency was used. Project artwork terms in `LICENSE` section 2 continue to apply. The Xprite Pixelate tool was reviewed as an option but not used because these portraits are painted illustrations, not upscaled pixel-grid art.

## Evidence and acceptance limits

- [Four-appearance contact sheet](../visual/swim-pixel-refinement-20261115.png) shows every generated pose at 2× nearest-neighbor scale.
- [Native Godot reef capture](../visual/ocean-pixel-refinement-20261115.png) shows the mask, tank, net and three-layer water at 1440×810 on Apple M2/OpenGL. The source fixture also captured both facings, lamp on/off and camera seams in `artifacts/godot/06a-ocean/visual-refinement-review/`.
- `python3 tools/player-swim/test_swim_atlas.py` passed for all four outputs: frame size, alpha, provenance hashes, clean top gutter and visor detail. The native eight-frame reaction fixture passed; the native six-case ocean fixture passed without changing game resources. Final `npm run check:world` passed with no `SCRIPT ERROR` or Godot `ERROR`; `npm run typecheck` and `npm run build` passed. The first bare `npm test` lacked database services and hit a connection timeout. The isolated fixture-backed rerun passed **123/123** API tests with zero failures. Its temporary MongoDB replica set on port 27019 and Redis on port 6381 were stopped; the owned fixture directory was removed (about 6.4 MiB allocated, 214,867,019 logical file bytes). No owner database or volume was touched.

This is a targeted visual improvement, **not full moodboard parity**. The four source portraits still contain only three authored underwater poses, and the land/sea world art, buildings and all residents have different sources and density. A still image cannot prove animation pacing or performance on Windows and Samsung S23. Review the current underwater player at 844×390 and 667×375 while moving, shooting and taking a hit before accepting the final visual result. Remaining work: source-quality directional swim frames, consistent detail density between character/reef/gear, and device review; do not mass-convert terrain into square tiles or reintroduce rejected resident side views.

## Completion note

Source commit, CI artifact and staging status are pending. The previous staging source remains `abfe2d4`, CI PCK `e7b07bfe1d31`, image `a08ad10df7ed` until a separate release is verified.
