# Actor lighting: frame-local CPU context

10 November 2026. Root candidate only; staging remains export5/PCK9a1. This package does not change the light palette, eleven physical lanterns, shadows, atmosphere, geometry, actor motion, outfits or gear.

`LandActors3D` previously calculated `EnvironmentState.snapshot()` for every player/NPC/creature tint and repeatedly read every lamp's global position/range. That snapshot allocates a dictionary and calculates weather/clock/trigonometry/string values, although all actors in a synchronous batch share the same state. The change captures daylight and lamp position/range once per `update_actors`, uses the same original tint/falloff math per actor, then releases the context at the batch boundary. Direct tint calls create a fresh context. Invalid actor returns clear any prior context. Full daylight skips lamp collection because the original warmth multiplier is exactly zero.

The context lasts one synchronous call; it is not a persistent per-position, per-minute or per-area color cache. Moving actors, elevation, clock updates, area rebuilds and new/freed lamps are observed in the next batch. Source does not add asynchronous yields inside actor updates.

## Actual focused result

Godot4.7.2 headless `scripts/tests/actor-lighting-frame.gd`, log `.runtime/actor-lighting-frame-first.log`, exit0/zeroSCRIPTERROR/ERROR. Explicit expected RGB checks cover night center/half-range/boundary/elevation, daylight, a frozen synchronous batch, fresh direct-call clock/light state, completed-batch release and invalid-actor cleanup.

Five AB/BA CPU benchmark pairs use the exact old implementation as reference, eleven lights,240frames×24actor points and four clock phases. All five accumulated RGB checksums are identical:5268.5146484375/5349.03271484375/5257.22998046875. Median batch time39,178µs→14,508µs, or163.24→60.45µs per24actor frame in this isolated local fixture. This saves about0.103ms per measured frame; it does **not** explain or solve a multi-millisecond renderer bottleneck, prove device FPS, or reduce477 draw calls observed in the software browser. No timing threshold is imposed in CI.

Raw `artifacts/godot/actor-lighting-frame-first/results.json`, SHA256 `4ec4c32292667ee941c3ae4f6d4e848661061845517230afde5e6a65f64cb675`. Test registered in living-world runner; full combined suite/export/native/browser not yet run at this checkpoint. Python/Playwright were not used to infer native timing. No new dependency, third-party asset or license.

Subsequent root full combined suite source1448539: **67/67PASS**,140,929ms summed case durations;10species/722frames still pass. `.runtime/world-check-lighting-frame/world-checks.json` SHA256 `07b30b059b7b3cf45ab361c18af59a2d95c2c20b28525dfcae2462070021cd78`, full log `.runtime/overnight-world-lighting-frame.log`, process71002exit0 and noSCRIPTERROR/ERROR. Includes actual land renderer, actors/equipment, dynamic crop updates, thirteen routines and resident commute tests. Slot released before hardware browser. This does not update public PCK9a1; export/native movement/browser/device acceptance of the experimental physical Nala remain separate.

```sh
ACTOR_LIGHTING_REPORT="$PWD/artifacts/godot/actor-lighting-frame-first/results.json" \
/Users/ardianryan/Documents/Jalasmara/.runtime/godot/Godot.app/Contents/MacOS/Godot \
--headless --path client-godot --script "$PWD/scripts/tests/actor-lighting-frame.gd"
```
