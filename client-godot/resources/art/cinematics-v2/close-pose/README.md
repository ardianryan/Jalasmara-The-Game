# Ki Lurah harbor close pose

This 128×128 transparent pose is a reduced, manually staged copy of the existing project-owned `village-residents-v1.png` Ki Lurah portrait. The source tile is the top-left 512×512 cell. The original village atlas has SHA-256 `09fd3e55f16b7a17c5077a1b693d4284e04437c7c19ab90ccbca8f210bc5afde`; the derived PNG has SHA-256 `964072e88aaeed74459f2d431f9c9ab5279f0ac4588553f6a26bb78f7ca23f9a`. It is not a scaled copy of the existing 64×64 locomotion sprite. There are 64 RGBA colors and a 73×123 visible-pixel box in the 128×128 cell.

Rebuild from the repository root with ImageMagick 7.1.2-31:

```sh
magick client-godot/resources/art/village-residents-v1.png -crop 512x512+0+0 +repage -filter Lanczos -resize 128x128 -alpha on -dither None -colors 64 PNG32:client-godot/resources/art/cinematics-v2/close-pose/ki-lurah-teaching.png
```

The actor's feet remain on the original painted harbor pier; `CinematicActionLayer.gd` controls a bounded whole-silhouette lean, staff-bell pulse and compass response. It uses nearest texture sampling at runtime. This source art retains the project's existing artwork terms in `LICENSE`; the visual reference moodboards are not bundled.

## Articulated teaching and sling poses — 18 November 2026

`build_gesture_poses.py` (Python/Pillow 11.3.0) authors two bounded, transparent source-pixel variants. `ki-lurah-teaching-point.png` modifies the close pose above by lifting the free hand and extending one finger; `gito-sling-release.png` starts from Gito's 96×128 cell at `(96,128)` in the project-owned `village-expansion-v1/residents.png`, removes the resting forearm, and paints a connected raised forearm. The sling and marbles are drawn by game code from the raised wrist. Source PNGs are generated deterministically with:

```sh
python3 client-godot/resources/art/cinematics-v2/close-pose/build_gesture_poses.py
```

The base Ki Lurah portrait SHA-256 is `964072e88aaeed74459f2d431f9c9ab5279f0ac4588553f6a26bb78f7ca23f9a`; the Gito source atlas SHA-256 is `6dc5fbb107327c97205660817cf245661bea838d50be606735fe2c6a247d413e`. The generated outputs are `2f40f407390a94e0c8bbb5319e94ee242665d929e206f9472ba75f4f9888bc30` and `c5feecc0edcc22c3810d05727d0756bdbb3603de4966db74878c47a432a6b15e`, respectively. Their terms remain the project's original art terms in `LICENSE` section 2; Pillow is offline authoring software, not a runtime dependency. The gesture is modest at native resolution and does not constitute full skeletal articulation.
