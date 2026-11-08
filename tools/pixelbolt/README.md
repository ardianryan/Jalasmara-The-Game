# Jalasmara supporting pixel effects

Pixelbolt 0.13.0 is an isolated build tool pinned in package-lock.json. It is not a game runtime dependency and installs no agent skill or global command. Pixelbolt is MIT licensed; its license is retained beside this file.

Run `npm ci --prefix tools/pixelbolt --ignore-scripts`, then `node tools/pixelbolt/build.mjs` from the repository root. The build authors four editable original recipes, validates each through the actual Pixelbolt CLI, renders each twice, and rejects different PNG hashes. PNG atlases, Godot SpriteFrames and atlas metadata go to `client-godot/resources/art/pixelbolt/`. Preview bundles remain in ignored `.runtime/pixelbolt/`.

The artwork uses Jalasmara's teal, copper and cream palette. Flames indicate functioning lanterns; steam marks a working pot; memory sparks mark a physical discovery; the splash is available for water contact. No borrowed sprite pack or reference image is used. Generated assets and recipes belong to this project; Pixelbolt's MIT license applies to the tool itself.
