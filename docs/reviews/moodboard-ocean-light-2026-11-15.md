# Underwater light shafts — source candidate

Date: 15 November 2026. Branch: `work/moodboard-ocean-source-next-20261115`, based on `6f2e413`. This is a **local integration candidate**, not a staging release or a claim of full moodboard parity.

The previous ocean atlas-card and rear-root trials were rejected: one formed an unrelated slab and the other was invisible at gameplay size. The reef capture still showed a large, uniform teal swim lane beside Nala. This pass changes the existing `OceanBackdrop.gd` water plane only. A bounded, world-anchored light-shaft term is evaluated on an 8-unit grid, shifts slowly underwater, attenuates with depth, daylight and clouds, and stops drifting under reduced motion. No texture, card, mesh, collider, route, fish, resonance target, oxygen, or reward changed. The original water gradient remains underneath the light.

## Actual-size review

| View | Baseline | Candidate | Observation |
| --- | --- | --- | --- |
| Reef 844×390 | [before](../visual/ocean-shafts-baseline-844x390-20261115.png) | [after](../visual/ocean-shafts-candidate-844x390-20261115.png) | A shallow cyan shaft now crosses the otherwise flat central/right water without masking Nala, fish or coral. |
| Reef 667×375 | [before](../visual/ocean-shafts-baseline-667x375-20261115.png) | [after](../visual/ocean-shafts-candidate-667x375-20261115.png) | The shaft remains visible at a smaller landscape viewport and the sprite grid remains crisp. |

The four source PNGs total about 512 KiB. Their SHA-256 values, in table order, are `9e63a7ffed55b90fd89ed36532059c08c8f4b462c2639d1f1d31ca020a221d4a`, `e0c23a4cf19634dbbf33582348c0d4ea340f1fd300768cc5edff5980b777ce9d`, `7c901811174c23dbdb9a3e210815141df4caa375fec5092843abbcebde5ded68`, and `eacc06aa8a3508bfede22bb41739eab867942f55851204fe074c1c8838c6a7c2`. In an open-water rectangle without foreground geometry, mean RGB intensity rose by 19.5/255 at 844×390 and 19.9/255 at 667×375. This is a local screenshot measure, not a perceptual-quality score. Identical passage cameras were also captured at both sizes in ignored `artifacts/godot/moodboard-ocean-shafts/{baseline,candidate-final}/`; the shafts light only open water beside the rock, leaving the passage itself readable. A first, weaker shaft trial raised the same mean by only about 9/255 and was rejected as too subtle; its runtime parameters were replaced before this handoff.

## Verification and limits

- Godot 4.7.2 Compatibility editor import completed cleanly on the second pass. The first import emitted transient missing font-cache messages while constructing a new worktree cache; those were absent on the second import.
- `scripts/tests/moodboard-ocean-shafts-render.gd` produced four native full-scene screenshots per variant with no `SCRIPT ERROR` or `ERROR`; source state retained oxygen 77 and coins 700. The final native pass used the stronger second candidate.
- Existing `scripts/tests/ocean-backdrop.gd`, expanded to test daylight, cloud and reduced-motion wiring, passed. It also checks 48 existing cards, parallax, alpha gutters, unchanged collision and unchanged progression.
- Full world suite, integrated browser/WebGL and physical Windows/Samsung S23 frame pacing remain for the integrator. The shader adds arithmetic on the existing water plane, including one low-frequency sine; no new draw call was introduced. Do not infer mobile performance from native Apple M2 captures.

The pixel-cluster treatment of foreground reef, distant karst and character readability still needs a coordinated art pass. The screenshots support a bounded improvement of open-water depth, not full parity with the owner's colorful/comfy references.

Tools: project Godot 4.7.2 Compatibility and Python 3/Pillow for read-only screenshot luminance measurement. The shader and fixture are original project code; no outside image, prompt, generated atlas or new third-party license was introduced.
