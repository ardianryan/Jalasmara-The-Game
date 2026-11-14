# Comfy world palette

## Character motion authoring, 14 November 2026

Character walk, swim, gesture and cutscene poses should be authored as controlled pixel frames or lightweight code-driven transforms of existing parts. Draw and inspect the moving silhouette frame by frame at the actual game scale; keep feet, hands, equipment sockets and loop transitions stable. Retain editable source, frame timing, provenance and license for every changed atlas, and compare runtime memory/frame pacing before release. Do not use an indiscriminately generated character sheet as a finished animation. Procedural environmental motion may use bounded shaders or transforms and must respect reduced-motion mode. This direction follows the owner's explicit preference for animation that remains light and easy to edit.

## Graphics clarity candidate, 14 November 2026

The earlier 640×360 Balanced and 480×270 Low render targets left the world coarse on large displays and touch devices. The new Sharp profile draws the 3D world at the 960×540 logical view; Auto begins there on desktop and at Balanced on touch, then falls one step after sustained low FPS. UI text is not reduced with the world. Existing 32×32 terrain textures now contribute centered, bounded contrast instead of almost no visible detail. Daylight grass and dirt are slightly cooler and less neon. See [source review](reviews/graphics-clarity-source-2026-11-14.md) and [native evidence](visual/README.md). The candidate still needs browser/physical-device acceptance; the game remains deliberately pixelated rather than photorealistic.

## Object pixel scale, 12 November 2026

For new or repaired bitmap details, use 16×16 source pixels for tiny details, 32×32 for props, and up to 64×64 for a character or a large object part as an authoring guide. Inspect each asset at its actual in-game size and preserve crisp nearest-neighbor edges. This is not a tile-size mandate for buildings, shorelines or the 3D terrain. The [village and Gajah Mina motion package](reviews/village-boss-motion-2026-11-12.md) applies the guide only to its repaired actors.

## Shoreline and vegetation candidate, 13 November 2026

The current source candidate renders the 3D world at up to 640×360 on the **balanced** profile and retains 480×270 on **low**. Both preserve the viewport aspect ratio and nearest-neighbor presentation; React text and the host menu remain separate from this internal world resolution. Visual coastline contours are generated from existing map polygons without changing server-owned walkability. Forest banks and the lower village court receive a bounded outward visual lip; the latter fades back to the authored edge around every stair landing. Bridges and wooden decks remain straight. Rock relief uses spatially smooth noise. Canopy, small plants and corals use sparse quantized wind/current motion; the player’s reduced-motion setting disables it. The [candidate review](reviews/coast-pixel-foliage-menu-2026-11-13.md) records native evidence, tests and performance limits.

## 9 November: cheerful local candidate

The user's newer target is the existing login/loading artwork: cheerful greens and teal, cool ambient light, warm sun and lamps. The 06-B2 candidate uses grass`#8CAF61`, earth`#B68F58`, sand`#E0C58C`, stone`#A8B5AA`, timber`#A57B50` and thatch`#C5A16D`. Material texture contrast is reduced before grading; changing global saturation alone is insufficient. These are chosen project colors, not sampled reference values. Native matched day/night comparisons are recorded in [the active finishing report](reviews/06b2-world-finishing-progress.md); this is not a released palette yet.

Sharp pixel silhouettes are intentional. Dense speckle, diagonal shadow stripes and dirty material patterns are not the finishing target. Flat terrain vertex normals must agree with the upward fragment normal used by the material shader: otherwise shadow-pass offsets can produce stripes even when the final lighting normal looks correct. Native bias-only variants did not remove those stripes; matching vertex normals did, while retaining tree shadows and the existing pixel budget. Character/foliage source artwork remains a separate art task.

The section below records the preceding released palette and its own earlier validation.

## Preceding palette

The latest user references suggest fresh tropical greens, ochre earth, teal water, cool shadow separation, and readable stepped rock. The swatches below are an interpretation for Jalasmara, not colors sampled from the reference images.

| Surface | Previous base | Current base | Purpose |
| --- | --- | --- | --- |
| Grass | `#70805B` | `#76A268` | Fresh leaf green with enough restraint for textured ground. |
| Dirt | `#8B765C` | `#9B7C52` | Warmer ochre paths that separate from grass. |
| Sand | `#C6B787` | `#CDBB87` | Soft pale shore ground without a white glare. |
| Stone | `#938E80` | `#969D98` | Cooler gray-green rock that separates from earth and timber. |

These are material base colors in `LandMaterials.gd`. Existing textures, surface normals, physical day/night lighting, and the subtle ComfyGrade pass determine the final displayed colors. Teal water and cool teal/plum shadow grading keep their existing implementation; this pass changes neither. Foliage sprites, geometry, collision footprints, garden recovery, character art, and HUD colors remain unchanged.

Native comparisons use the same scene fixture and camera positions as the preceding grade check. Evidence is generated locally under `artifacts/godot/comfy-palette/` and is not bundled into the game. This is a native visual check, not a claim about physical phone displays or final public-browser acceptance.

Validation: the native Compatibility renderer completed the day/night fixture without shader errors. The village and forest screenshots preserve the readable distinction between ochre paths, fresh grass, cooler stone, and unchanged teal water. The existing lamp-on/off check still passes (mean sampled ground luminance increase approximately `0.0164`). Geometry, camera positions, and lighting settings were unchanged for that comparison. Evidence includes `kedai.png`, `kedai-night.png`, `forest-entry.png`, and `forest-bridge.png` in the local artifact directory.
