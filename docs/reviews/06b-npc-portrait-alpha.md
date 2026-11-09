# NPC portrait transparency investigation

Worktree `Jalasmara-06-npc-alpha`, branch `work/06b-npc-alpha`, base `f319da9`. The current native diagnostic does **not** reproduce the historical gray rectangles. No runtime workaround, artwork edit or release is claimed. Landscape geometry, collisions, server state and Nala artwork are outside this change.

## Source evidence

- `npc-atlas.png`: original project generation, four cast members, SHA-256 `82d946a0df5ecb98eb5d4daa48856e8cf36644103b39f80d39d17e361ff56aec`, RGBA 1254×1254, four 627×627 cells.
- `village-residents-v1.png`: original Jalasmara generation from the user’s character profiles, SHA-256 `09fd3e55f16b7a17c5077a1b693d4284e04437c7c19ab90ccbca8f210bc5afde`, RGBA 1536×1024, six 512×512 cells. Provenance remains in `docs/assets/provenance.md`; no new artwork or third-party pixels have been added.
- Pillow read-only pixel inspection finds transparent corners and proper silhouette-shaped alpha throughout both atlases. Full alpha-mask inspection shows holes between arms/legs, rather than an opaque central portrait backplate. Saras has alpha0 outside her body, alpha1–2 in arm gaps, and alpha247–253 in legitimate clothing and equipment. Neutral clothing colors must therefore remain untouched.
- The imported village `.ctex` in the integration worktree contains an RGBA WebP image whose background samples retain alpha0. This does not prove every historical export imported the same bytes.
- Historical browser evidence: `Jalasmara-06-integration/artifacts/browser/plan06-layout-6174b6a2-be3c-47ab-a8ed-cb8e82e8a201/home-porch-night-667x375.png`. A gray quad extends outside Saras’s body. This capture predates the current candidate and is a reproduction lead, not proof of a current runtime failure.

`LandActors3D._sprite` currently uses unshaded Sprite3D, alpha discard at0.5, nearest sampling, no material override and shadow casting off. SpriteBase3D defaults to `transparent=true` ([official documentation](https://docs.godotengine.org/en/stable/classes/class_spritebase3d.html)). Its separate ground shadow is an ellipse mesh, not a vertical portrait rectangle. `HubActor._draw` draws the source texture and two small ground-shadow rectangles; `Main._process` marks all surface actors `land_hidden` while the 3D renderer is active. Source inspection has not yet identified a missing visibility assignment or an opaque source backplate.

## Actual native verification

The native diagnostic fixture `scripts/tests/npc-portrait-alpha-render.gd` isolates the existing Sprite3D path over a known background, hides its ground shadow, then compares atlas sampling, a byte-preserving cropped texture and alpha blending. It records transparent source samples against a sprite-hidden image, excluding samples within three source pixels of an alpha edge. The source mask is therefore independent of the rendered comparison.

Command, executed locally on Godot 4.7.2 `ed1daf0bf`, native Compatibility/OpenGL 4.1 Metal on Apple M2:

```sh
/Users/ardianryan/Documents/Jalasmara/.runtime/godot/Godot.app/Contents/MacOS/Godot \
  --path client-godot --script ../scripts/tests/npc-portrait-alpha-render.gd
```

| Non-rig portrait | Transparent samples | Changed by existing atlas Sprite3D | Changed by crop / blend |
| --- | ---: | ---: | ---: |
| Ki Lurah | 1,898 | 0 | 0 / 0 |
| Mbok Ratih | 1,898 | 0 | 0 / 0 |
| Kang Tedi | 1,994 | 0 | 0 / 0 |
| Saras | 1,972 | 0 | 0 / 0 |

All four bodies render, with 1,250–1,348 opaque samples changing the background in the existing atlas path. The measured 7,762 transparent samples remain unchanged. `transparent=true` and alpha cut mode 1 are read from the actual Sprite3D. The first diagnostic invocation had a fixture parse error because `Projection` is a built-in type; renaming the local stub `ViewFixture` resolved it. The completed log has no script/render errors, and the process exits 0.

The same fixture renders **Saras at her authored work position (1480, 680)** in the actual LandWorld at 20:00, azimuth −45°, with normal grade, terrain, lighting and nearest upscale. This component fixture keeps her there for a controlled image; it does not claim night scheduling or actual Main/browser acceptance. Original HubActor CanvasItem visibility is asserted false. Four captures independently hide the Sprite3D, hide the ground shadow, or replace its frame with an exact RGBA crop. The atlas capture has no visible gray rectangle. Pixel differences against it cover 3,201 pixels when hiding the sprite, 184 when hiding the ground shadow and 66 when using the crop; the crop is not pixel-identical because sampling rounds differently. No native defect justifies its additional texture allocation.

Evidence: `.runtime/npc-alpha-native.log`, `artifacts/godot/06b-npc-alpha/minimal-results.json`, twelve `minimal-*.png` images and eight `night-saras-*.png` images (presentation and raw world). The atlas world image was visually inspected. All owned Godot processes were closed and the engine slot was released to the integrator.

The historical rectangle also appears near Nala and a bench/palm in that older browser capture. Its cause remains unresolved: this native test does not exercise the complete Main CanvasItem composition or WebGL/browser path. Next reproduce on the current browser package at the same night scene, then toggle the actual 2D/sprite/shadow contributions before choosing a fix. Do not add chroma-keying, extra image copies or an alternative renderer without that evidence. This is a native diagnostic, not a default headless CI script because it waits for frame rendering. Comfy finishing remains open.

## Separate orientation audit, no edits

The Griya footprint remains orthogonal and aligned with its deck. Seven other house footprints retain the earlier shear. Applying the actual map embedding to their two footprint axes gives angles 92.256° (Kedai), 94.474° (Beno), 98.661° (corporate post), 96.165° (Balai), 86.086° (Ratih/Sari), 86.834° (Tedi), versus 90° (Griya). This measures source geometry only, not a new visual acceptance result. Correcting these footprints requires synchronized collider, roof, porch, access, routing and save checks; this transparency task does not rotate their models independently.
