# Side-gait pilot

Original offline cutout processing of Jalasmara's four original `*-outfits-v1.png` atlases. Run `python3 tools/player-gait/generate.py` with Pillow installed. Sources remain unchanged; output PNG/JSON files are under `resources/art/player-gait/`.

Eight poses follow contact, down, passing and up twice per stride. Support feet travel backwards relative to the body by exactly the same distance the controller advances; swing feet clear the floor, knees bend and arms counter-swing. Metadata records support feet, source hash, stride and foot pivot. Body poses never alter collision or actor position. Equipment remains separate.

**Directional limitation:** these sources depict a side/three-quarter view. East and mirrored west are supported artwork directions. Requested north/south/diagonal movement still uses the side fallback, explicitly reported in `locomotion_state()`. This is not the complete eight-direction artwork required by Plan04. Genuine additional directional source images must be supplied/generated and reviewed before that requirement can pass.

Integration: call `CharacterVisual.set_locomotion(actual_velocity, delta)` before `animate()`. Consume `consume_foot_contacts()` once for material-aware footsteps; do not also run an independent timer. `locomotion_state()` exposes phase, frame, requested/artwork directions, fallback status and stride. Legacy callers without displacement input retain the existing animation; swimming keeps its existing clip.

All code and cutout processing here are original. Derived art retains the source project's original-art terms. No Sprite AI job, commercial reference sprite or paid service was used.

## Reviewed daily eight-direction pilot

`male_default` in the daily outfit now has eight **drawn** viewpoints and eight whole-body frames per direction, plus eight directional idle poses. This pilot uses original built-in image generation conditioned on the project's Nala; it does not mirror side art into rear/front views. Source sheets and SHA-256 records live in `assets/source-2d/nala-daily-eightway/`. Unused high-resolution authoring images stay outside Godot resources.

Preparation:

```sh
python3 tools/player-gait/prepare_directions.py
python3 tools/player-gait/assemble_pilot.py --out .runtime/player-gait-staging/assembled
python3 tools/player-gait/test_eightway.py
```

The assembly preserves whole drawn limbs, applies alpha threshold128 and nearest normalization, and aligns per-clip baseline/head position. Runtime frames are128×128, authored foot pivot64,104, stride64world pixels; the Nala-only3D branch uses that fixed pivot rather than recomputing the lowest pixel each frame. `directional_pilot_enabled` can disable this pilot. It requires displacement-driven `set_locomotion()` input. This was the first pilot stage. The full batch described below now supplies the other11identity/outfit combinations; the east/west assets remain compatibility fallback only. Swimming stays separate.

Native proof:

```sh
.runtime/godot/Godot.app/Contents/MacOS/Godot --path client-godot --script ../scripts/tests/player-eightway-render.gd
```

The full-world recording walks eight short collision-valid rays using the actual land renderer and mirrored CharacterVisual frames. Source pose timing and individual sandal contacts can still receive artist polish; authored pivot correctness does not prove every painted sole is perfectly planted between frames. This first recording covers the daily pilot only; the later batch recording covers all four identities and three outfits.

## Full identity/outfit batch

The daily pilot now extends to all four identities and three outfits. Runtime uses96 genuinely drawn direction clips (8frames each) and96 neutral idle views. Tracked authoring sources, eight corrected north strips, manual direction review and source/output hashes live in `assets/source-2d/nala-eightway-batch/manifest.json`. The original daily pilot source stays in its own directory. Existing east/west cutouts remain a compatibility fallback, not the normal displacement-driven land path.

## Existing-art transition candidate

`CharacterVisual` separates requested facing from the displayed authored view. Turns visit neighboring octants over accepted displacement, capped at one new view per render frame even when physics updates arrive in a batch; equipment follows the displayed view. The male_nusantara daily/explorer stop pilot uses existing lowering frames3→2→1 and7→6→5 before neutral,50ms perframe, with no root displacement or extra footstep event. A paused landing freezes its frame/queue. Other identities/outfits retain their previous stop behavior. Normal walking and restart retain the exact distance phase; painted sole locking and a dedicated restart cycle remain open animator work.

Run the registered `player-locomotion.gd` fixture with `NALA_GAIT_CAPTURE=1` in native mode for sequential runtime component frames under `artifacts/godot/nala-gait-transitions`. Review and honest scope are in `docs/reviews/06e-nala-gait-transitions.md`; this candidate is separate from releasef319da9 until integrator acceptance. No source atlas is regenerated by this change.

```sh
python3 tools/player-gait/assemble_batch.py --out .runtime/rebuilt-gait
python3 tools/player-gait/test_eightway.py
```

The clean-checkout batch builder requires Pillow, reads only tracked sources, and never needs an API key. It preserves whole connected drawings and the common128px cell/pivot64,104. Normal land movement is100px/s with the authored64px stride (~3.125contacts/s); the native32/100/175 proof includes former175px/s as a stress case without silently clamping phase away from displacement. Individual painted sole contacts and transition interpolation remain animator-polish work. The simple directional equipment attachments are independent geometry; underwater attachment remains unchanged.
