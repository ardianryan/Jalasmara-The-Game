# Playable pier resident pixel and gait review — 18 November 2026

Status: isolated candidate on `work/playable-resident-pixel-20261118`; **not merged, released, or tested on staging**. The tested base is `8d1684e`. This pass addresses the Gito diagonal-turn pelvis drop while keeping the original resident source pixels and exact sole contacts. It does not claim full moodboard parity.

## Finding and change

The five children and director on the playable hub use `ResidentArtRig3D`, drawing partitioned project-owned resident art. Their visible body is not the fallback voxel resident rig. At native 667×375 and 844×390, Gito remains legible beside Nala at the pier. Uniform enlargement would distort this relationship, so no sprite scale, camera zoom, or asset resolution was changed.

In an eight-heading pier walk, the original rig pulls both hips from fixed screen positions while contact feet move across a diagonal stride. Two of 128 movement ticks force the pelvis downward more than the 9×body-scale threshold (maximum 9.172 source-space units), making the legs briefly compress. The candidate shifts the pelvis horizontally toward the current foot contacts, bounded to 7×body scale, with four half-unit corrections only when a leg still requires a deep drop. Torso, head, shoulders and hands follow that same shift; feet and ground contacts stay untouched. At both viewport sizes, maximum drop is 6.207 with zero deep drops. The rig still uses one authored front-three-quarter source view, so this is a bounded gait correction rather than eight independently drawn facings.

## Original-size A/B

These are lossless WebP conversions of native Godot frames, exact output dimensions, with the same dock, light, actor positions, stride tick, and adult resident in the foreground. The earlier first baseline capture was confounded by an active `HubActor` scheduler and must not be used; the fixture now disables scheduling after parenting the actor. The compositional change in the accepted pair is subtle because the feet stay planted. Compare Gito's hip and knee relationship rather than the adult.

| View | Baseline | Candidate |
| --- | --- | --- |
| 667×375 diagonal stride | [baseline](../visual/playable-resident-pixel-20261118/baseline-667-diagonal.webp) | [candidate](../visual/playable-resident-pixel-20261118/candidate-667-diagonal.webp) |
| 844×390 diagonal stride | [baseline](../visual/playable-resident-pixel-20261118/baseline-844-diagonal.webp) | [candidate](../visual/playable-resident-pixel-20261118/candidate-844-diagonal.webp) |

The native fixture renders 25 frames per size (idle, two stride phases and returned idle over eight headings) and records all 128 legal walking ticks. Full raw frames and JSON remain local under `artifacts/godot/playable-resident-pixel-{baseline,candidate}-{667,844}/` and are deliberately not committed.

## Verification and limits

| Check | Result |
| --- | --- |
| Original rig native 667×375 / 844×390 | Expected FAIL at both sizes: 2 deep drops, max 9.172; all 128 ticks remain on legal dock. |
| Candidate rig native 667×375 / 844×390 | PASS at both sizes: 0 deep drops, max 6.207; both feet never lose the floor simultaneously. |
| Production `resident-commute-contact.gd` headless | PASS: 11,826 strict poses over six resident commutes, 158 ramp samples; no stance drift, teleport, or world mutation. |
| Actual-size visual review | Gito and Nala remain proportional and feet remain on the painted pier. Improvement is subtle and concentrated in the diagonal stride. |

Godot 4.7.2 Compatibility on Apple M2 OpenGL 4.1 Metal was used for native frames. The test used the existing project world-map fixture. No external art, shader, font, or tool dependency was added; resident pixels and license remain as recorded in the project asset provenance. This does not test Web export, Windows, Samsung S23, player interaction, or the full scene scheduler. The adult's background movement is not the subject of this test. The authored single-view art still limits directional identity and expressive gesture; a future source-pixel facing pass needs independently drawn poses and native moving proof.
