# Phase 1 focal-character staging — candidate, 16 November 2026

The action figures in the ship, garden, Balai, first dive, and final veranda were too small beside the existing dialogue portraits. This candidate gives each speaking/action figure a scene-specific scale while leaving distant villagers small. It changes only `CinematicActionLayer.gd`; no gameplay, server state, hitbox, boss proportions, or source atlas is changed.

At 667×375, projected **opaque figure height** is 62.7 px for Raka on the ship, 65.3 px for Darmi, 61.6 px for Gito, 65.0 px for Ki Lurah in the garden, 64.5 px for Nala in the first-dive atlas, and 66.2 px for Nala on the veranda. These values use each atlas cell's alpha bounds, the draw destination, the action-layer unit, and Godot's final viewport transform; they are not full rectangle heights. At 844×390 the same figures remain within the test's 59–80 physical-pixel band. The first-dive crop contains every nontransparent pixel in the four existing diving appearances in both used directions. The daily crop likewise contains all four appearances.

The native inspection caught a composition fault that the size check alone could not: enlarged Balai speakers appeared to stand on the stone map. Raka, Saras, Beno, and Mbah Wira now speak from the wooden floor to its right. Gito stands on the garden planks with his marble trajectory starting at his position. Nala remains visible to the left of the final card. The dialogue portrait remains the close view; the in-world actors are visible at readable scale without covering its text.

## Verification and evidence

- Godot 4.7.2 headless editor import: exit 0, no `ERROR` or `SCRIPT ERROR` on the final run.
- `scripts/tests/phase-one-hero-staging.gd`: **30/30** focal size/layout checks across 667×375 and 844×390; all 16 daily/diving atlas direction crops checked for clipping. Native run: **32 captures**, exit 0, no `ERROR` or `SCRIPT ERROR`. A final filtered native rerun covered both garden resolutions after Gito's position changed.
- The first attempt at the new test used a static preload before SceneTree autoload registration, causing a test fixture compile failure and repeated follow-on errors. The fixture now loads the action script after initialization; the final headless and native runs are clean. The first editor import reported missing cached font data before reimport; a second editor run completed without errors.
- Inspected full-size 667×375 native frames for ship Raka, Bu Darmi, Gito, Ki Lurah, Balai speakers, first-dive Nala, and veranda Nala; also inspected 844×390 garden and final card. The files below are **lossless WebP copies** of Godot's original native PNGs. No account, credential, or moodboard image appears in them.

| Native proof | SHA-256 |
| --- | --- |
| [Raka on the ship](../visual/phase-one-hero-staging-20261116/prologue-04-667x375.webp) | `e6ea3ae668447aab77850ccebd703e1161e6314249f4687326d4dc284a555865` |
| [Bu Darmi in the garden](../visual/phase-one-hero-staging-20261116/garden_crisis-01-667x375.webp) | `57dbb0dc9a9093acdd8b74d210bda2228b6c9d39da73bf404f67a8fd4c9f35c1` |
| [Gito and the Laskar Kognisi](../visual/phase-one-hero-staging-20261116/garden_crisis-02-667x375.webp) | `bbf7898954f607c9ef087c24bda78278317abefd5de75560e80ec3ec43a28535` |
| [Ki Lurah at the gate](../visual/phase-one-hero-staging-20261116/garden_crisis-04-667x375.webp) | `f96b38f63df20b1a196c5b9751ad52c22aaa2e84e4a7dd7eb411eb3eb039f58f` |
| [Saras speaking beside the Balai map](../visual/phase-one-hero-staging-20261116/earthquake-04-667x375.webp) | `d3f50169423f44979057d5c88630573d3262839267009be1a9a4435509bb388d` |
| [Nala's first dive](../visual/phase-one-hero-staging-20261116/first_dive-01-667x375.webp) | `05fa4732d2d9f4a4513931686f46ca932bd678dadd9542b05ddf77a8680a1dd0` |
| [Nala beside the final card, 667×375](../visual/phase-one-hero-staging-20261116/epilogue-08-667x375.webp) | `244af5f946bd6feb9dbdf092d4e14126401197ddc68ce64f2da60438f84d2cab` |
| [Final card, 844×390](../visual/phase-one-hero-staging-20261116/epilogue-08-844x390.webp) | `b992d71185786abee371d901df9725a1b6964d49ae1c64b5e3a92e0e6794d0a3` |

Base source: `d90665fb7b709e581bcfaaff6a7ca9dd09c02b32`. This is a **local candidate** until integration, the combined world suite, build, and release checks pass; it is not a staging claim. The main atlas, `npc-facing-v2`, village child atlas, and cinematic plates are existing project assets with provenance in [the asset register](../assets/provenance.md). This pass used Godot 4.7.2 and Pillow for lossless documentation conversion; Cinetic, Sprite AI, and image generation were not used. The project art keeps its existing project-art terms, separate from code/tool licenses.

The integrator should register the focused test in `scripts/verify-living-world.mjs`, cherry-pick this branch, rerun the combined checks, inspect the selected screenshots, then update the active handoff and clean the branch/worktree. Browser and physical-device playback remain outside this isolated packet.
