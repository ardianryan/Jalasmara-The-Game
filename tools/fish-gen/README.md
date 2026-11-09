# Fish Gen offline pilot

One original generated Clownfish, seed1519, is adapted to a bounded decorative school in the Godot ocean. It adds no catch target, quiz, inventory item, currency or reward. The ten existing procedural species and their722frames remain intact. The pilot is a depiction of the generator preset, not an assertion of an endemic species.

Upstream [Fish Gen](https://github.com/JacobKulberg/fish-gen), commit `0faa79003ca50a7d422b618cb59179d9834094f1`, version0.1.0, Jacob Kulberg. The original MIT notice is in `LICENSE.upstream` and packaged in `client-godot/resources/licenses/FISH-GEN-MIT.txt`. The pinned README separately permits generated sprites in commercial games. The adapter and wrapper are original Jalasmara code; naming them WorldKit does not remove the upstream provenance.

Use Python3.11 and an isolated environment; runtime players do not need Python or the generator:

```sh
python3.11 -m venv .runtime/fishgen-venv
.runtime/fishgen-venv/bin/python -m pip install --only-binary=:all: -r tools/fish-gen/requirements.txt
.runtime/fishgen-venv/bin/python tools/fish-gen/produce.py \
  --source .runtime/reference-audit/fish-gen --out .runtime/fishgen-reproduction
```

The source checkout must match the exact pin and have no modified tracked files. The wrapper refuses to overwrite a previous atlas. Native C auto-compilation is disabled. The first pilot used NumPy2.2.6/Pillow11.3.0 and the NumPy renderer; no GUI, paid service or image-generation API is involved. Provenance includes exact arguments, versions and output hashes. Only the unchanged PNG/JSON and provenance are installed under `client-godot/resources/art/fishgen/`; the `.tres` is retained as an offline output because the runtime adapter also consumes timed `next` and `yaw` metadata.

The atlas has32frames across swim-right, turn-right-to-left, swim-left and turn-left-to-right. The stateful adapter changes heading at a loop boundary and follows the non-looping turn into its declared next clip; it does not replace a turn with horizontal mirroring. Three decorative actors are capped to one on the low profile, reuse one shared atlas, respect actual water contours and disappear for boss/session exit. Their steering is cosmetic, independent of server-owned captures and fauna behavior.

Validation: `scripts/tests/fishgen-animation.gd` tests metadata/frame bounds, all four clips, pause, turns/yaw,5,400 actual water contacts, quality caps and session/boss cleanup. Native/browser evidence and release status are recorded in the active overnight review; source integration alone is not proof of a released Web asset.
