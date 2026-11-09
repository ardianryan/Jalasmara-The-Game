# 06-B2: Ujang transition steps and original west head

This follows `38e88f6` and supersedes its held diagnostic result. No pelvis limit, fixed-length tolerance, world-contact tolerance or collision rule was relaxed. The default contact test now includes the formerly failing sharp-turn route, so it is covered by the existing registered CI invocation.

## Mechanical cause and correction

The old swing landing stayed on the old heading until its phase wrapped. On a sharp heading change, the body continued to consume the 25-unit distance cycle; the new support could be far from the reversed path before the scheduled lift. Reflecting the whole root at west facing also immediately exchanged hip screen sides while soles stayed world-locked.

The rig retains positive anatomical scale. A turn greater than 60 degrees starts a short **6 physical-unit transition step** using the free foot. Its landing is redirected onto a legal point ahead of the new heading, while the supporting foot remains planted in world coordinates. On landing, the arriving foot becomes support and the previous support begins its swing immediately in that same frame. The phase restarts with the correct anatomical side in stance.

That same-frame handover matters: an earlier version delayed `begin_swing()` until the next frame, leaving a newly free foot at its old position while its phase advanced. One remaining sample requested pelvis drop 8.27656. Beginning the released foot's swing at the handover removed it while preserving the original maximum drop 8. A planted foot is never slid or relabelled to hide an error.

Facing and lateral foot placement use the actual camera basis and a local finite-difference inverse of `map_point()`. The camera helper, WORLD, routes, actor root position and server state are unchanged. Tests rotate the actual 3D camera to 0 and -45 degrees; they do not patch projection callbacks.

## Original west head

An original 29 × 27 west head now replaces the wrong-facing fallback. The built-in image tool referenced Ujang's original portrait and approved rear cap. The navy cap, gold trim, grey hair and aged face remain recognisable; the nose and eyes actually point left in the new art. The wooden right leg remains the original unreflected artwork.

Source, exact prompt and derived part are stored under `assets/source-2d/ujang-rear-grip-v1/`; the project's original-art licence applies. The atlas contains eighteen Ujang parts, fifty total across the three existing pilots. No external character asset, PixelDoll result, paid API key or third-party code is used.

## Final verification

Godot 4.7.2 Compatibility on Apple M2, isolated worktree. Import, tests and native captures ran serially under the assigned engine slot. Complete final logs were scanned for `SCRIPT ERROR`, `ERROR:` and assertion failures; none are present.

| Final check | Result |
| --- | --- |
| Default `ujang-foot-contact.gd` | PASS: 1,242 checked samples, comprising the original 1,074 commute/stop/stair/boundary samples and 168 sharp-turn samples |
| Actual alpha-sole stance drift | Maximum 0.000306342 world units in the default run |
| Actual thigh/calf quad knee join | Maximum 0.000272985 |
| Pelvis drop | Maximum 7.04096 in the full run, below the unchanged limit 8 |
| Native focused sharp turns | PASS: 168 sequential 90/180-degree samples at camera 0/-45, normal/reduced motion; stance drift maximum 0.000309897, pelvis maximum 5.00486 |
| Support and identity | Every measured sample retains a grounded support foot; root determinant positive; right prosthetic lower leg and foot are not reflected |
| Independent grip | PASS: 26 poses, finger-to-actual-cylinder distance maximum 0.01538721 and axis error below 0.05 degrees |
| Body animation contract | PASS: fifty modular parts, pause/reduced, clip/event and distance-gait contract |
| World/player mutation | None in the compared snapshots |

Final ignored logs: `.runtime/ujang-transition-import.log`, `.runtime/ujang-transition-final-full.log`, `.runtime/ujang-transition-final-native.log`, `.runtime/ujang-transition-animation.log`. Earlier logs containing failed experiments are historical and are not the final evidence.

Runtime atlas SHA-256: `be0ba626ad727a0c76eb078ecf6c4d73aa9bfb049efdc552e684f84ba5cb7d80`. Final JSON SHA-256: `43d26cb579f6b97e0178f315ba46beeee6cf54cd1a36ea6035ba9e835597406b`. Repacking after native validation retained the atlas bytes; only explanatory metadata strings were updated afterwards.

Native evidence: `artifacts/godot/06b-body-contact/0000.png` through `0175.png` form a sequential 17.6-second record at the fixture's 10 Hz simulation rate, including eight initial settled samples and 168 turn samples. `transition-contact-sheet.png` shows eight points from each camera/motion combination. `grip-false-work_loop-2.0.png` shows the new west head and independent fishing prop at actual 480 × 270 resolution. These are moving turn samples, not sixteen repeated direction stills presented as locomotion proof.

The full log is the default CI command. `UJANG_TURNS_ONLY=1` remains a convenience for the same focused cases and now exits 0; it no longer hides an unfixed case from CI. `UJANG_CAPTURE=1 UJANG_TURNS_ONLY=1` records the native sequence.

## Remaining scope and gate

The head, torso rear and fist additions do not create a fully authored four-direction body. Rear legs and side torso remain cutouts; silhouette and timing may still benefit from a complete directional art pass. No Darmi/Sari expansion, new shelters, performance benchmark or physical Windows/S23 result is claimed here.

- Hard Gate PASS: authorised original art with source/prompt/licence; final runs were executed and errors checked, without invented performance claims.
- Purpose Gate PASS: new head fixes visible direction; the transition changes support timing rather than disguising limb reach.
- Liveliness PASS: existing comfy maritime pixel direction retained, with essential distance-driven gait in reduced motion. Energy 2 / rhythm 2 / motion 2 remain the pilot direction.
- Craftsmanship PASS: the original trace and newly failing turn cases both pass unchanged geometry limits, and sequential actual-size native captures show the source being committed.
