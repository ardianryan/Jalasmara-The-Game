# Coast, pixel clarity, foliage and menu icon review — 13 November 2026

## Request and implementation

The owner asked for less blurry pixel graphics, less rectangular islands and more natural rock shores, then added wind/current motion for trees, shrubs and coral and clearer game menu icons using Pixora. This source candidate is on `work/coast-pixel-20261113`; it is not a staging release as of this report's first draft.

- Balanced-quality land and ocean SubViewports now target at most **640×360** at a 960×540 logical view; low remains **480×270**. The budget scales with other aspect ratios. Godot still presents world pixels with nearest-neighbor filtering, while text/UI stays at screen resolution. Touch auto-quality remains low.
- `CoastlineContour.gd` makes a deterministic visual mesh from the existing hub coastline and slightly extends forest banks and the lower village court toward water. Maximum extra lip is 12 world units. An initial broad court pass failed the real dock stair-foot test; the final lower-court contour fades to zero within 80 world units of stair anchors and begins blending only beyond that. Other village courts remain unchanged. The authoritative world JSON, server walkability, bridges, wooden decks, stair connectors and player physics are unchanged.
- Stone shoulder variation now uses interpolated spatial noise rather than independent per-node random values. This reduces harsh adjacent facets while retaining real thickness and support beneath elevated floors.
- `FoliageMotion.gd` gives whole-pixel, 10-pose-per-second gust motion to canopies and small land plants. Coral sprites pivot gently around their root. Reduced motion disables both. The source [SpriteCook wind article](https://www.spritecook.ai/blog/pixel-art-trees-wind-animation) informed the fixed-root, grouped foliage and staggered-gust approach; no code or art was copied from it.
- The host Menu button and its fullscreen, reset, account, logout and resume actions use six unmodified [Pixora Icons](https://github.com/tsora1603/pixora-icons) SVGs at commit `ea994cfa6dc9da1a468405d6bcb6aeffa80aa52e`. The 16×16 sources display at a crisp integer 2× scale. Text labels remain for accessibility. The upstream CC BY 4.0 license is distributed with the icons and attribution is in `THIRD_PARTY_LICENSES.md` and `docs/assets/provenance.md`.

## Tool assessment

Existing Godot 4.7.2 Compatibility, the project's authored polygons, native rendering fixtures, Python Pillow and `sips` were used. Pixora supplied menu art. [Bonfire](https://github.com/RafaelBarbosatec/bonfire) is a Flutter/Flame game framework; [ShaderGlass](https://github.com/mausimus/ShaderGlass) is a Windows desktop overlay; [isometric-cities](https://github.com/Statecraft-Labs/isometric-cities) is a map authoring reference; [osgEarth](https://github.com/pelicanmapping/osgearth) is a C++ geospatial terrain SDK; [awesome-pixel-art](https://github.com/Siilwyn/awesome-pixel-art) is a resource list; [aseprite-mcp](https://github.com/MalloyTheDev/aseprite-mcp) is a possible offline authoring helper. None was installed into the game or represented as a runtime improvement. The already available Xprite Pixelate and Pixel Snapper were inspected as asset tools, but this pass changes procedural terrain and motion, so no production bitmap was resampled.

## Evidence and checks

| Evidence | Result and limit |
| --- | --- |
| `scripts/tests/coastline-foliage.gd` | Deterministic contour, no source polygon mutation, valid synthetic and production bank triangulation, bounded shoreline displacement, quantized foliage motion; PASS. |
| `npm run check:world` | First attempt timed out during cold Godot import; after editor import the full suite passed. A later broad village-court contour failed real stair contact, so it was narrowed to an anchor-aware lower-court lip. The full suite then passed on that contour. The final live ocean-profile hook was checked separately after that suite. |
| Native Compatibility render | `scripts/tests/land-left-runtime-render.gd` passed nine views on Apple M2 OpenGL 4.1/Metal, including hub dock and forest bridge after the anchor-aware contour. This proves native geometry only, not WebGL/physical device FPS. |
| Live profile and stair contact | `ocean-resolution.gd` passed low↔balanced viewport changes; `render-performance.gd` passed the 129,600/230,400-pixel budgets; `stair-foot-grounding.gd` passed 868 actual tread/foot samples after the anchor-aware contour. |
| TypeScript and build | `npm run typecheck` and the final `npm run build` passed. The local macOS PCK is 70,062,372 bytes, SHA-256 `63c148c30b3c708476f5bb3d88a19a028ff7ba404f974c46afcf558a865261bd`; CI will export its own SHA-bound bundle. The build log has no `SCRIPT ERROR` or `ERROR:`. |
| API tests | Full `npm test` could not complete because the local MongoDB replica set at `127.0.0.1:27018` and Redis fixture are not running. The isolated no-database subset passed **22/22**; a broader 37-test run passed 33 and had four expected Mongo connection failures. GitHub CI is the authoritative integration-test gate. |
| Six Pixora icons | XML parsing passed 6/6. A local contact sheet was inspected for clear silhouettes; no recoloring or bitmap conversion is shipped. |

The [forest bridge](../visual/coast-forest-bridge-20261113.png) and [hub dock](../visual/coast-hub-dock-20261113.png) are original Godot native screenshots from this candidate, not a staging browser capture. SHA-256: `27e0b8f241e99b567ab2bd19fb3fc6291a9e8892a32ab0c958cca1781c53902f` and `12b9e8c2eb0d0135f5b5df566565135b06f2a33bd465d5f359f7fa796223761d` respectively. Source PCK and release image hashes will be recorded only after the final verified build and deployment. The visual contour is intentionally bounded; a full replacement of source tree/coral bitmaps is outside this candidate.

## Remaining acceptance

1. Review rendered low/balanced resolution and foliage/coral motion in a browser; native and headless checks cannot establish WebGL pacing.
2. Merge the candidate into `main`, require GitHub Actions to pass the Mongo/Redis integration suite, and activate only the matching CI bundle on staging with backup, restore and public smoke.
3. Ask the owner to inspect the island edge and Menu readability on Windows and Samsung S23. Measure FPS and audio pacing on those devices before calling the balanced profile a device-performance win.
