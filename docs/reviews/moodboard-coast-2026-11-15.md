# Coastal dock pixel-detail candidate — 15 November 2026

## Scope and status

The staging dock at 844×390 had regular plank seams but broad, nearly uniform tan board faces. This candidate gives `dock` its own material kind in `LandMaterials.gd`, with coarse wood grain, knots, nail heads, and per-board value variation. The original `wood` material still serves houses, posts, and bridges. It remains a visual candidate in `work/moodboard-coast-20261115`; it has not been merged, exported, or released.

The deck footprint, mesh count, supporting geometry, collision, and server walkability are unchanged. The detail uses one extra cached `ShaderMaterial` on the existing dock surface, with no new mesh. Actual GPU timing and visual acceptance on Windows or Samsung S23 remain unmeasured.

## Sources, tools, and license

The material continues to use the project's existing land-material atlas. New detail is code-authored in `LandMaterials.gd` and aligned to a 4-world-unit pixel grid. No external moodboard image, generated sprite, or third-party asset was added. Tools used: repository source inspection, `rg`, Git diff checks, Godot 4.7.2 native renderer, and existing staging screenshot `docs/visual/staging-hud-compact-dock-844x390-20261112.png`. Attribution and license of the pre-existing atlas remain governed by `docs/assets/provenance.md`; this change introduces no new third-party license.

## Checks and next acceptance gate

- `git diff --check`: passed.
- Godot 4.7.2 second import pass: no `SCRIPT ERROR` or `ERROR`. The first import pass logged temporary missing imported font cache entries, then generated the cache.
- Godot native 844×390 render: passed with no script or shader errors. [Image](../visual/moodboard-coast-dock-native-20261115.png), SHA-256 `c8da0aca7e07c2c2d222536d1587fead6f437009446a919a90d15a06aebf8b66`; renderer reports 57 meshes and 78 surfaces in the fixture. This test does not measure GPU draw calls or frame time.
- `npm run typecheck`: unavailable in the isolated worktree because `tsc`/`node_modules` are absent. Integrator should run combined checks after merge.
- Browser screenshot, visual acceptance on physical Windows/Android, and mobile performance: pending.
- Reject the candidate if the grid disappears at actual game scale, wood looks noisy, knots repeat visibly, or the shader raises frame time. In that case reduce detail or pre-bake a source-controlled authored texture.

The moodboard parity request is broader than this dock treatment. Grass, water, foliage, buildings, lighting, character detail, HUD, and performance require separate assessment against a coherent target view before anyone can claim parity.
