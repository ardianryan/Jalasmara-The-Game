# Ocean moodboard review — rejected accent candidate

Date: 15 November 2026. Branch: `work/moodboard-ocean-20261115`. This is a **review record, not a released ocean change**. The runtime, tests and generated asset were restored or removed after visual rejection. No ocean art from this branch should be cherry-picked.

## Observation at gameplay size

The existing reef view, [`ocean-alpha-cut-native-20261115.png`](../visual/ocean-alpha-cut-native-20261115.png), has a wide nearly flat teal area to Nala's right. Fine painterly detail in the distant karst contrasts with coarser character and reef pixels. At 844×390, the same open area occupies much of the playable frame. The passage view has painterly rock faces, bright coral masses and a busy central rock, so adding more shapes without source-art alignment risks cluttering navigation.

## Rejected experiment

A reproducible six-cell, 384×256 RGBA atlas was drawn with Python Pillow at source-pixel resolution (10-color palette, no interpolation, transparent gutters). Its output was 4,814 bytes, SHA-256 `3b2fd9013b70d4b9a8fce6a3335e970d4e1d5ab7127884ec45eec7d65d262010`. It was original project work; no moodboard pixels or third-party sprites were copied. Six existing painterly atmosphere cards were substituted with six code-authored cards, preserving 48 cards and all collision/gameplay. A focused alpha, palette, parallax, and state test passed under Godot 4.7.2; a six-capture native render also passed mechanically at 1440×810 and 844×390 with no script errors.

The actual 844×390 image, [`moodboard-ocean-rejected-slab-20261115.png`](../visual/moodboard-ocean-rejected-slab-20261115.png), failed art review: the large right-side karst looked like a flat slab and its cluster scale clashed with surrounding source art. Moving the shallow placements to smaller rooted kelp/coral removed the slab in the first 844×390 passage frame, but added little visible improvement. That second run stalled after the first frame for more than two minutes and was stopped; there is no complete second six-shot pass. The runtime patch and generated asset were therefore discarded, and the baseline remains authoritative.

## Concrete next art pass

Improve the existing **source** ocean terrain/karst silhouette rather than layering unrelated shapes over it. Author a small set of coherent pixel-cluster formations with the same outline thickness, light direction, and density as the near reef; review them side by side at 667×375 and 844×390 before wiring them into the world. Place formations against named navigation landmarks so the center swim lane remains clear, and use one color/value ramp across far, mid and near planes. Validate moving water, cave light, target visibility, and reduced-motion in the actual browser. Preserve original source and provenance; do not accept a color-quantized copy of a painterly atlas merely because it has fewer colors.

The public PCK cold-load issue is independent of this visual experiment. Full moodboard parity remains unverified and open.
