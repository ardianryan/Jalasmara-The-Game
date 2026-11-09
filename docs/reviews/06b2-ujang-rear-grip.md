# 06-B2: Ujang rear artwork and independent fishing grip

Candidate on isolated branch `work/06b-body-next`, based on main `1f097cc` with the earlier foot-contact pilot and art audit cherry-picked first. This is a reviewable Ujang-only increment. It is not a four-direction artwork pack or acceptance of natural walking for every resident.

## What changes

The north head and torso now use original rear artwork made with the built-in image tool, referencing Ujang's own portrait and existing atlas. The sailor cap with gold trim, grey hair, cream collar, brown patched waistcoat, and original wooden leg identity remain. A second torso edit removed baked sleeves so those no longer freeze the rear arms. The final rear vest is 27 × 34 pixels. The original source atlas is preserved; a versioned atlas supplies seventeen parts. Rear head/torso centres are authored separately, so the head no longer inherits the front nose offset.

One 7 × 7 west-facing fishing fist has a reviewed opaque finger `gripPixel`, wrist and rod-axis annotation. A body-local fishing rod frame defines the rod before arm IK. The right arm reaches that frame; the fist is placed from its authored wrist. Runtime measurement transforms the artwork's grip pixel independently and compares it with the endpoints of the actual rod cylinder mesh. The prop is still a separate 3D object. Returning to idle, talk or travel clears tool and grip metadata.

This resolves the previous circular measurement in the west pilot: the rod is no longer constructed from the same two hand sockets that were subsequently called a contact test. Other directions remain explicitly unmeasured. Darmi and Sari keep their prior code and art.

`tools/npc-rig/ujang_rear.py` reproduces packing with alpha thresholding, nearest resizing and the original Ujang colour palette. The full cutout generator calls it after producing the original atlases. Source images, exact prompts and provenance live in `assets/source-2d/ujang-rear-grip-v1/`. Original project art terms apply; no third-party code or character sprite was copied.

## Verification

Godot 4.7.2 Compatibility on Apple M2, in this worktree only. Import, headless checks and native capture ran sequentially after the root granted the engine slot. No browser, web export or physical device test was run. Final import and final test logs have zero script or engine errors. The first import caught an inferred-Variant boolean; the explicit boolean type was fixed before all final checks below.

| Check | Result |
| --- | --- |
| CPU packing and full generator | Reproduces the same atlas hash; seventeen nonempty bounded parts; original Ujang PNG and Darmi/Sari PNG/JSON unchanged |
| `npc-body-animation.gd` | PASS: clip/event/pause/reduced/distance-gait contract and 49 total modular parts |
| `ujang-foot-contact.gd` | PASS: 1,074 real legal trace steps; alpha-sole world drift max 0.000273601; actual quad knee join max 0.000272985; pelvis drop max 7.04096 below 8 |
| Independent west grip | PASS: 26 start/cast/wait/pull/end poses across normal/reduced motion; separately transformed opaque artwork pixel to actual cylinder endpoints max 0.01517295 world units; authored axis error below 0.05 degrees |
| Rear and stale anchors | PASS: new north parts visible, front parts hidden, head centre X = 0; actor rod/grip metadata empty outside the work clips |
| Native final atlas | PASS: the same 26 grip poses plus sixteen direction stills at the real 480 × 270 renderer resolution, zero errors |

The direction stills hold the actor position; they inspect facing artwork and layers, not moving locomotion. The 1,074-step final trace runs headless, while the earlier mechanical pilot has the separate native walking record described in `06b2-ujang-contact-pilot.md`. Do not describe these sixteen stills as a newly authored walk sheet or a new full native walk recording.

Native files are under ignored `artifacts/godot/06b-body-contact/`: `art-north-0.png` and `grip-false-work_loop-2.0.png` are the main review frames. At play size the new rear reads as the cap, grey hair and back of a patched vest. The fist and rod meet; the pose still inherits the original cutout arm and leg silhouettes. The wooden leg remains present; crossing/turn silhouettes still need the next directional-art pass.

Final runtime atlas SHA-256: `0ee49b3a08c8eb71ba6ccadfeff7807ac9017c89fcf3a072cf4555d8cc0ecf7f`. JSON SHA-256: `0d553347526f84aa582194dc367a8d5e84391ad3052407aa41da3b0b9b55ddb8`. After the final native test, rerunning the full offline generator retained the same atlas bytes and changed only the descriptive metadata method string, not coordinates or runtime art.

Reproduce with the root Godot binary, substituting its absolute path as needed:

```sh
python3 tools/npc-rig/generate.py
GODOT_BIN=/path/to/Godot
"$GODOT_BIN" --headless --editor --path client-godot --import
"$GODOT_BIN" --headless --path client-godot --script ../scripts/tests/npc-body-animation.gd
"$GODOT_BIN" --headless --path client-godot --script ../scripts/tests/ujang-foot-contact.gd
UJANG_CAPTURE=1 UJANG_ART_ONLY=1 "$GODOT_BIN" --path client-godot --script ../scripts/tests/ujang-foot-contact.gd
```

The contact test needs `.runtime/world-map.json` generated from the current shared `WORLD`, as documented in the preceding mechanical pilot. It does not modify the production manifest or player state.

## Delivery gate

- Hard Gate PASS: original assets are authorized project art; source/prompt and exact tool are recorded; no external credentials, invented device performance or unrun native claims.
- Purpose Gate PASS: rear art addresses the old front-shaped rear; the extra fist exists to put an independently annotated finger on the separate rod.
- Liveliness PASS: the existing comfy pixel direction is retained; movement remains distance-driven with the essential reduced-motion gait. Energy 2 / rhythm 2 / motion 2 apply to the character pilot, with the patched maritime clothing as its repeated motif.
- Craftsmanship PASS: final parser, metadata bounds, fixed leg geometry, independent grip and actual-size native images were checked. Camera, routes, economy, Darmi/Sari and website UI were not altered by this increment.

## Remaining scope

East/west still share mirrored three-quarter source art. Rear arms and lower body are still cutouts. This increment does not create four independently drawn views, change the camera or navigation, add villagers, move shelter anchors, or accept the entire walk animation. The mechanical world-foot contacts remain a pilot and must retain their original length, mesh contact, stop, reduced-motion and world-mutation checks.
