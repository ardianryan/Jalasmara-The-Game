# Pak Ranto first-service portrait

This is one **original static** bust portrait for Pak Ranto's first Kedai Waras service cut-in. The project owner supplied the Phase 1 screenplay and art direction; a Codex agent prompted and curated the image with the built-in image generation tool on 16 November 2026. No moodboard image, commercial game frame, third-party sprite pack, or other resident's portrait was used as the source. It does not provide character animation or a walking atlas.

| File | Dimensions | SHA-256 |
| --- | ---: | --- |
| `assets/source-2d/pak-ranto-portrait-v1/pak-ranto-imagegen-source.png` | 1274×1235 RGBA | `ebc0ade1aa794a0bdaf92f4133748693632f03872be4e6d97425777c245f3f17` |
| `client-godot/resources/art/cinematics-v2/pak-ranto-portrait.png` | 160×160 RGBA, 96 colours | `43973327164a8c4de969b0dc2c4f591950ec64a317efd9227b9874f93b998106` |

The source has faint red pixels at its bottom fringe and semi-transparent background noise. The selected runtime cutout trims that fringe, samples to a fixed grid, thresholds alpha to hard-edged pixels, and limits the palette without dithering. Rebuild with ImageMagick 7.1.2-31 from the repository root:

```sh
magick assets/source-2d/pak-ranto-portrait-v1/pak-ranto-imagegen-source.png \
  -crop 1274x1215+0+0 +repage -filter Point -resize 160x152! \
  -gravity center -background none -extent 160x160 \
  -channel A -threshold 35% +channel +dither -colors 96 -strip \
  client-godot/resources/art/cinematics-v2/pak-ranto-portrait.png
```

Installed Xprite Pixelate 0.1.2 was evaluated on the source. Its automatic detector returned `reliable: false` and a 1×1 grid, so no inferred Xprite grid was applied. The explicit point-sampled 160-pixel grid is the curated output. The portrait is shown with nearest-neighbour sampling in Godot. The 32×32 code sketch was rejected after a native 844×390 review and is not included.

Godot 4.7.2 Compatibility imported the selected PNG and passed both `scripts/tests/phase-one-cutscenes.gd` and `scripts/tests/day-one-ranto-capture.gd` headlessly. Native Metal capture on Apple M2 at **667×375** and **844×390** shows the cap, face, hand, apron, and scale clearly within both the center tasting cut-in and the dialogue portrait; the frame and button remain visible. The proof images are [667×375](../visual/phase1-ranto-first-service-667x375.png) (SHA-256 `ceaf962f952e1829bcb273271bb48b5c498d771d62bb1895bde51b3ff0636391`) and [844×390](../visual/phase1-ranto-first-service-844x390.png) (SHA-256 `6e6aa1c52ac14e04be7310cc75c1aa0926c801db069546d191598ddeeee91967`). The capture utility also checks that an in-progress legacy shift retains Bu Darmi's name and portrait and a missing snapshot does not borrow another resident's portrait. These are native rendering checks, not browser, Windows, or Samsung S23 performance claims.

The selected portrait is project artwork under the game-asset terms in [LICENSE](../../LICENSE), separate from the MIT code license. The built-in image generation service, ImageMagick, and Xprite were authoring/evaluation tools only; no third-party art license is imported.

## Exact generation prompt

> Create one ORIGINAL static half-body dialogue portrait sprite for the Indonesian coastal educational adventure game Jala Smara. Character: Pak Ranto, a middle-aged Javanese fish-market vendor with warm brown skin, alert kind eyes, slightly weathered cheeks, short dark hair with a little gray, and a simple brown fisherman cap. He wears a faded teal work shirt and warm brown woven market apron; a small brass hanging fish scale (dacin) is tucked beside him. Expression: sudden delighted recognition of chlorophyll and photosynthesis, eyes bright, a natural open smile, one hand lightly touching his chest. Chest-up 3/4 view turned slightly toward screen-left. Art direction: premium handcrafted cozy RPG pixel art portrait, 1990s painted pixel-cluster craft at a disciplined underlying approximately 96x96 pixel grid; distinct intentional 1-pixel and 2-pixel clusters, no faux-pixel noise, no blur, no photographic rendering, no smooth vector lines. Deep warm ink outlines; coherent clusters of coral tan, terracotta, muted jade/teal, dark cocoa and brass highlights; soft warm key light from upper left and cooler teal rim on right. Polished expressive face and silhouette, correct human anatomy and hands. One person only, one pose only. Transparent background, no panel or scenery, no letters, no text, no watermark. Leave a few pixels of transparent margin on all sides so the crop will not clip his hat or apron. This is an original game asset, visually compatible with richly shaded 2D pixel RPG resident portraits rather than a simplified 32x32 icon.
