# LivingWater contour hash: isolated native measurement

The detector is inexpensive on this machine. Keep the production water invalidation and quality behavior unchanged. This result does not identify the reported Windows or Samsung S23 slowdown.

## Measured input and result

The actual generated WORLD contains 15 terrain contours and 159 points. Godot serializes those contours to 2,569 bytes, SHA-256 `f87f2f5009dd3edade643a445986b24b805d24971f2d51ccef8f94b9c13c20a4`. The earlier Node preparation counted 2,237 bytes; numeric serialization differs, so the native report records its own byte count and hash.

On Apple M2 / macOS / Godot 4.7.2 stable, nine warmed rounds of 10,000 calls produced:

| Operation | Median microseconds/call | Round minimum | Round maximum |
| --- | ---: | ---: | ---: |
| Actual contour hash + source-style lookup/comparison | 2.5405 | 2.5264 | 2.6717 |
| Cached integer read/comparison reference | 0.0311 | 0.0301 | 0.0353 |

The measured rounds completed in 235 ms. The full-hash median equals about 0.015% of a 16.67 ms budget. That arithmetic is context for this one CPU operation, not a measured frame-time improvement. The reference loop is not a production cache or a validated invalidation strategy.

The serialized engine slot was explicitly granted and released. The isolated minimal project has no game autoloads, rendering, assets, network or account state. The process exited zero with no script/engine/assertion errors. The script checks a five-second round deadline; the external process had an eight-second timeout. Results and the complete log remain ignored at `.runtime/water-hash-cost.json` and `.runtime/water-hash-cost.log` in the HUD/performance worktree. The committed probe is `scripts/performance/living-water-hash.gd`.

To reproduce after acquiring the repository's engine slot, create an ignored minimal Godot project (only `config_version=5` is required), then invoke Godot headless with `--path` pointing there and `--script` pointing to the probe. Set `WORLD_HASH_INPUT` to an absolute generated WORLD JSON path and optionally `WORLD_HASH_OUTPUT` to an ignored report path. Do not use an account dump or start the game for this probe. Keep an external eight-second process timeout.

## Scope and next checks

No production water/current/profile change has been made. The probe measures no rendered game frame, GPU work, particle update, API work, Windows hardware or Samsung S23 hardware. The next useful evidence is the opt-in actual gameplay recorder on those physical devices, followed by profiling the expensive subsystem found there.

Source audit also confirms that land-water elapsed time advances during menus and hybrid ocean/backdrop shaders use engine `TIME`. LivingWater cosmetic particles intentionally pause advection while reading. Existing water/current tests cover those separate contracts. This audit is not a new animated visual acceptance run and does not justify rebuilding the existing ocean effects.
