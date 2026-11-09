# Comfy world palette

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
