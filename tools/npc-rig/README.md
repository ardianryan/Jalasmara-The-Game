# Jalasmara NPC cutout pilot

`python3 tools/npc-rig/generate.py` deterministically derives three layered body atlases from the project's original NPC artwork. Requires Python 3 and Pillow. The source portraits remain unchanged.

Outputs live in `client-godot/resources/art/npc-rigs/`. The original PNGs contain sixteen parts; JSON records source SHA-256, sampled joints, foot pivot and atlas regions. Ujang, Darmi and Sari retain their original front facial/clothing pixels. Covered clothing is patched with samples from the same portrait; held net, pot and fabric roll are excluded from the torso masks. Independent runtime props attach to computed hand sockets, except the authored Ujang west fishing pilot described below.

Ujang's head and torso rear are overridden by the reviewed `ujang-rear-grip-v1` original artwork; his atlas adds a west fishing fist and original west head, for eighteen parts. The generator applies `ujang_rear.py` after the original cutouts. Source, prompt and annotation details are in `assets/source-2d/ujang-rear-grip-v1/README.md`. The land rig keeps Ujang's anatomical root positive and selects his newly drawn west head without reflecting the wooden right leg. Darmi and Sari retain simplified rear silhouettes and a front three-quarter side view. Their leg rig now plants the original opaque soles on the rendered ground, preserves source thigh/calf pixel lengths and turns without reflecting the whole anatomical body. These are articulated cutouts, not newly illustrated four-direction animation sheets. Original cutout masks can retain small fragments of baked sleeves/props; native review remains necessary.

The generator and runtime rig are original project code. The input and derived artwork keep the project's existing original-art terms; no Dave the Diver frame, foreign character sprite or upstream tool code is included. Pillow is an external development dependency, not vendored here.

Run semantic checks with:

```sh
"$GODOT_BIN" --headless --path client-godot --script "$PWD/scripts/tests/npc-body-animation.gd"
"$GODOT_BIN" --headless --path client-godot --script "$PWD/scripts/tests/legacy-resident-contact.gd"
```

Work clips use a tidy transition before navigation or dialogue. Walking phase follows actual distance; the rig never changes actor position, inventory or rewards. Native recordings belong under ignored `artifacts/godot/npc-body-rig/`.

Optional GPU proofs (run sequentially after regenerating `.runtime/world-map.json` via `npm run check:world`):

```sh
"$GODOT_BIN" --path client-godot --script "$PWD/scripts/tests/npc-body-render.gd"
NPC_SEQUENCE_ONLY='Bu Darmi' "$GODOT_BIN" --path client-godot --script "$PWD/scripts/tests/npc-body-sequence.gd"
```

Set `GODOT_BIN` to the local Godot 4.7.2 executable. The first native fixture isolates body pixels and saves eight actual-distance walking frames per pilot. The second simulates 180 frames per selected pilot at 12 Hz: ten seconds of work, departure on the real route graph, then conversation. It saves nine selected frames by default to conserve storage; set `NPC_SEQUENCE_FULL=1` only when a complete sequence is needed. Its camera can frame another actor on some routes, so inspect the captured PNGs before using them as proof of the named resident. These fixtures change only local test state and never grant gameplay rewards. Raw PNGs and MP4s belong in ignored artifacts; curate only useful, accurately labeled contact sheets into `docs/visual/`.

Current recorded evidence uses clock minute600 for the first120 frames (daylight working), then minute1300 for60 frames (night departure/talking). Thus both lighting conditions appear in each15-second recording; it does not demonstrate a complete work loop at night. Ujang, Darmi and Sari are the only articulated body pilots in this pass. Seven other adults still use the five-frame front three-quarter portrait strips; they need reviewed rear/side art before backward-facing travel can be accepted visually. A palette-only rear-head conversion was rejected after contact-sheet review and was not shipped.
