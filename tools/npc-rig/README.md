# Jalasmara NPC cutout pilot

`python3 tools/npc-rig/generate.py` deterministically derives three layered body atlases from the project's original NPC artwork. Requires Python 3 and Pillow. The source portraits remain unchanged.

Outputs live in `client-godot/resources/art/npc-rigs/`. The original PNGs contain sixteen parts; JSON records source SHA-256, sampled joints, foot pivot and atlas regions. Ujang, Darmi and Sari retain their original front facial/clothing pixels. Covered clothing is patched with samples from the same portrait; held net, pot and fabric roll are excluded from the torso masks. Independent runtime props attach to computed hand sockets, except the authored Ujang west fishing pilot described below.

Ujang's head and torso rear are overridden by the reviewed `ujang-rear-grip-v1` original artwork; his atlas has one additional west fishing fist, for seventeen parts. The generator applies `ujang_rear.py` after the original cutouts. Source, prompt and annotation details are in `assets/source-2d/ujang-rear-grip-v1/README.md`. Darmi and Sari retain simplified rear silhouettes using sampled colours. East/west still reuse mirrored three-quarter artwork. These are articulated cutouts, not newly illustrated four-direction animation sheets. Original cutout masks can retain small fragments of baked sleeves/props; native review remains necessary.

The generator and runtime rig are original project code. The input and derived artwork keep the project's existing original-art terms; no Dave the Diver frame, foreign character sprite or upstream tool code is included. Pillow is an external development dependency, not vendored here.

Run semantic checks with:

```sh
.runtime/godot/Godot.app/Contents/MacOS/Godot --headless --path client-godot --script ../scripts/tests/npc-body-animation.gd
```

Work clips use a tidy transition before navigation or dialogue. Walking phase follows actual distance; the rig never changes actor position, inventory or rewards. Native recordings belong under ignored `artifacts/godot/npc-body-rig/`.

Optional GPU proofs (run sequentially after regenerating `.runtime/world-map.json` via `npm run check:world`):

```sh
.runtime/godot/Godot.app/Contents/MacOS/Godot --path client-godot --script ../scripts/tests/npc-body-render.gd
.runtime/godot/Godot.app/Contents/MacOS/Godot --path client-godot --script ../scripts/tests/npc-body-sequence.gd
```

The first isolates body pixels on a transparent stage and checks alpha-foot stability. The second records 180 native frames per pilot at a simulated 12 Hz: ten seconds of work, departure on the real route graph, then conversation. It changes only the local test clock/player and never grants gameplay rewards. PNG sequences can be encoded with FFmpeg at 12 fps; screenshots and MP4s are deliberately ignored artifacts.

Current recorded evidence uses clock minute600 for the first120 frames (daylight working), then minute1300 for60 frames (night departure/talking). Thus both lighting conditions appear in each15-second recording; it does not demonstrate a complete work loop at night. Ujang, Darmi and Sari are the only articulated body pilots in this pass.
