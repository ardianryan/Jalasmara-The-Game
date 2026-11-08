# Procedural fauna for Jalasmara

Offline adapter for [Procedural Pixel Creatures](https://github.com/idlerunner00/procedural-pixel-creatures), pinned to commit `a2207c4bd6f1be51d426684cf58f11668def7579` (MIT). Upstream's engine-independent Core supplies anatomy generation, palettes, motion rigs, fixed-step motors, CPU rasterization, spritesheet export, and PNG encoding. This adapter does not distort an AI image or ship the upstream C# runtime inside the web game.

Run from the repository root with Node.js, Git, and a .NET 8 SDK available:

```sh
node tools/procedural-creatures/generate.mjs
node tools/procedural-creatures/verify.mjs
```

The generator uses `DOTNET_BIN`, an existing `.runtime/dotnet/dotnet`, or `dotnet` on PATH. The development setup used the official Microsoft .NET SDK 8.0.425 under ignored `.runtime/dotnet`. Tool installation is separate from the web build; players do not download .NET. The first generation fetches the pinned source into ignored `.runtime/procedural-pixel-creatures`; subsequent generations work offline. MSBuild output and caches remain under `.runtime/`.

`Program.cs` defines ten fixed species seeds and curated coastal palettes in teal, ochre, and olive. Four independent upstream genome streams retain reproducible anatomy, color, pattern, and motion. The chosen archetype is sampled explicitly, then the palette and body size are adjusted through public genome APIs. Creature names are fictional; these assets do not claim to reconstruct Indonesian endemic species or sacred mythology.

The output directory is `client-godot/resources/art/procedural/`. Each creature has an RGBA PNG sheet, upstream `ppc.spritesheet` JSON, and a reproducible `ppc.creature` genome JSON. `manifest.json` records the source revision, seeds, dimensions, frame counts, habitats, and PNG SHA-256 hashes. Upstream MIT notices accompany the adapter and generated pack.

The sheets contain 12 fps idle and locomotion clips. Aquatic/tentacled bodies use their generated swim/float rigs despite the common upstream `walk` clip name. East/west directions use IDs 0/4; forest snakes and tortoises additionally include north/south 2/6. All clips retain their shared frame dimensions and pivot. Godot should render the supplied frame rectangle with nearest filtering at the entity position using `originX`/`originY`, rather than assuming a uniform atlas tile or recentering each pose. Navigation, separation, danger, and rewards remain responsibilities of Jalasmara.

To confirm reproducibility in a separate generation:

```sh
node tools/procedural-creatures/generate.mjs .runtime/procedural-repeat
node tools/procedural-creatures/verify.mjs client-godot/resources/art/procedural .runtime/procedural-repeat
```

Verification checks PNG transparency, metadata frame bounds, source hashes, genuinely changing locomotion pixels, and optionally byte-identical PNG/JSON output from a second process. It does not measure runtime FPS on physical phones.

Upstream provides crab and land-tortoise archetypes, but no dolphin or snail family. The pack therefore uses clearly labeled reef fish, rays, eels, jellyfish, octopuses, pufferfish, sharks, crabs, snakes, and tortoises. A tortoise is assigned to the forest habitat rather than labeled as a swimming sea turtle. The legacy file ID `sotong_karang` is kept for integration compatibility, while its display name correctly says “Gurita Karang”.
