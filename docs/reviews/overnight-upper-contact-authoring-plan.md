# Original upper-body authoring and contact contract

CPU source/visual audit and implementation proposal only. No runtime, lower-body solver, Player, CharacterVisual, production atlas, gear geometry or pixels changed. No engine, browser, image generator or external API ran. The current strict lower-body candidate remains unaccepted after its restart reach failure; this proposal cannot activate it.

## Source identity and reproduction

The existing production atlases are 1024×1024, eight separately drawn views × eight 128px frames. Daily walk SHA `342724d1724490279cd0f65c0340c5b35cdf366ecc36a99af716c51f751b8fc3`; explorer walk SHA `a429c378400bd5ac60a45124ac48672b4cb1360beb379cc83297b52ea48ae3b9`. Their metadata SHA values are respectively `b5fa070625535d94040fa95ff673cf4d3ee95a3c1477383eb97baa5d92648198` and `3a771568395c394819b9737b7820bde8d5e8178cbcefc071c6a3b5ad681d1b09`. The metadata declares no mirroring, pivot 64,104, stride 64 and contacts 0/4. Those last two are atlas/legacy timing metadata, not physical foot-contact acceptance.

Original full daily/explorer sheets and the [WEST comparison](../visual/nala-west-upper-authoring-proposal.png) were inspected directly. Read-only Pillow checks verified all ten source/output hashes from the two metadata files, all sixteen upper rows and the exact cross-outfit counterexample below. Each upper row has eight distinct RGBA crops at y0..75; distinct pixels do not prove anatomical opposition, clean torso coverage or natural motion. Machine evidence is integration `.runtime/upper-source-current-audit.json`, SHA `eae4cf6a1da43cf0dfe70730115344b2eaa057f71c3916a5950dc7e9ffb40657`.

Character-lane source `b05a211` was read without modification. Its existing `python3 tools/player-gait/test_upper_arm_annotations.py` passed eight original opaque palm marks. Annotation SHA `e4b4f92cf2cb6b9cf017047a738fce7a358bd69b88aefa233571ea085729eecc`; lower annotation generator SHA `aa2870ff8a4bf5abab87bb98c58ae2762fb19ed2ba99c3975ebc8fc8aa855910`. This source test is SOUTH-only. The [existing coverage audit](overnight-upper-source-coverage.md) and [WEST e852197 proposal](overnight-west-upper-authored-prototype.md) retain their limits.

## Sixteen authoring entries

All entries below have eight original upper crops. **None has accepted physical contact-to-arm phase.** “Source anchors” means reviewed original palms, not complete masks or grip sockets. Unknown entries remain unknown; do not mirror or copy an outfit to fill them.

| View / atlas row | Daily coverage and next step                                                                                                                                                                                          | Explorer coverage and next step                                                                                                |
| ---------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| EAST /0          | Near-arm pose changes; separate original limb ownership, joints and clean shirt first. Anatomical far arm/phase unknown.                                                                                              | Own pixels/vest overlap need independent masks and joint annotation; no inherited daily mapping.                               |
| SOUTH_EAST /1    | Front-diagonal hanging/bent poses; anatomical ownership and hidden-shirt coverage unknown.                                                                                                                            | Same review task on its own sleeve/vest pixels; no diagonal from SOUTH offset.                                                 |
| SOUTH /2         | Original frame 0/4 opposite forward-palm anchors exist. First bounded source-mask/contact candidate.                                                                                                                  | Own frame 0/4 palm RGBA anchors also exist; separate torso/masks required.                                                     |
| SOUTH_WEST /3    | No accepted complete backward near-arm extreme in the source review; phase shift cannot supply it.                                                                                                                    | Independent hidden shirt/far-arm inventory required; no daily repair transfer.                                                 |
| WEST /4          | One eight-frame authored proposal exists. Near-left/far-right is intended annotation convention only; actual contact mapping unknown. Review its explicit authored sleeve/repair and native seams before integration. | No authored loop or approved anatomical/contact mapping. Own source has different coverage; start a separate authoring record. |
| NORTH_WEST /5    | Rear overlap/depth and limb identity unknown; annotate visible source ownership before phase.                                                                                                                         | Vest/back silhouette and arm fragments require independent ownership/depth review.                                             |
| NORTH /6         | Central back shirt visible; out-of-plane swing and attachment coverage unknown.                                                                                                                                       | Separate back/vest plate and arm depth needed. Repaired NORTH source is not proof of full arm swing.                           |
| NORTH_EAST /7    | Original pose changes exist; anatomical side/joints/hidden shirt remain unannotated.                                                                                                                                  | Own coverage/anchors required; not a mirrored NORTH_WEST.                                                                      |

The daily WEST frame 7 pixel (50,57) is skin `[218,163,115,255]`; explorer at the same view/frame/pixel is transparent `[0,0,0,0]`, verified against current originals. A daily palm mask, cloth repair or shoulder cannot be relabelled explorer. WEST lower metadata also marks both profile legs `occludedReuse=true`; cross-view hip continuity is an intended convention, not an independently visible asymmetric anatomical marker.

## Authoring proposal, before runtime work

Use the existing 128px cell/pivot and upper cut y76. Annotate each outfit/view separately: immutable source SHA/frame/pixel runs; shoulder, elbow, wrist and independently authored grip origin/axis; depth ownership; and a full-name provenance record for any newly authored hidden cloth or limb. A palm landmark is neither a complete hand mask nor a grip center. Retain the original head/identity and avoid scaling/recoloring borrowed limbs.

Require exact source-only rest reconstruction where all pixels exist. Where art is genuinely missing, explicitly author and mark it rather than reporting a recovered clean shirt. WEST e852197 already does this for its repaired torso, compact near sleeve, far extension and seals; that approval is confined to one daily view and is not permission to repair fourteen other outfit/view entries. Preserve far-arm→shirt→near-arm depth and inspect sleeve joins/hand occlusion at gameplay scale. No duplicate torso, sleeve, hand or shadow geometry.

The smallest useful next authoring unit is one SOUTH daily plate plus source limb masks/anchors, followed by its explorer counterpart, while WEST daily remains a separately reviewed authored loop. A reusable authoring manifest could carry the fields above and fail closed on unknown sides/phase anchors; it should extend the existing WEST exporter rather than introduce another renderer or phase solver. **No new tool/schema has been installed:** root/character coordination is required before implementation.

## Proposed contact-driven consumer

The source SOUTH convention proposes right-foot contact→upper frame 0(left arm forward), left-foot contact→upper frame 4(right arm forward), separately for both outfits. This is not accepted gameplay opposition. Do not apply a global +0.5 offset to the seven unknown directions, and do not assign WEST phase from screenX or near/far labels.

The future producer must be the **final validated Lower pose**, after reach, bones, original-foot coverage and body checks succeed. A raw `NalaFootPlant.snapshot()` can exist before Lower rejects that pose; consuming it would animate the upper body against invalid support. Prefer a single published pose identity shared by upper, gear and any future audio consumer. It needs explicit valid/paused/idle/moving/settling/rejected state, displayed body direction, anatomical swing/support side, accepted progress, discontinuity/transition identity and classified contact side. These are proposed semantics, not new fields added by this audit.

Existing planner `contacts` is an aggregate count: both locomotion landing and zero-XY stop settlement increment it. It cannot safely determine anatomical side by parity. `swingDistance` can reset during turns/re-anchoring and `landingDistance` varies with actual terrain. Therefore neither `acceptedDistance %64` nor a reset progress fraction is a universal arm clock. A steady single step may map between two reviewed source anchors, but transitions must retain the last displayed joint/grip pose and approach the next valid anchor continuously. No synthetic contact, root motion or additional distance is introduced by the upper consumer.

Required transition behavior:

- **Pause/rejection:** freeze local articulation during pause; reject an unsupported upper pilot rather than consuming a failed Lower pose or pretending it passed. No animation clock advances from a rejected planner snapshot.
- **Blocked input:** zero accepted travel does not run a walking cycle. It may consume an explicitly classified authorized settlement, without creating a locomotion contact or swapping arm identity.
- **Stop:** settle arms and grip from the last accepted pose to authored neutral using a separate bounded visual transition; do not reset an arm to frame 0 just because speed becomes zero.
- **Resume/reverse/sharp turn:** preserve anatomical identity and current joint pose through the handover; select only reviewed neighboring-view data. No phase reset from requested facing and no near/far reassignment from screenX.
- **Terrain:** root/body lift and held-facing decisions come from the same final Lower pose. Upper/gear cannot move the actor, lengthen feet, change reach constraints or patch support geometry.

## Gear/socket contract

Current production `CharacterVisual.get_equipment_state()` supplies displayed direction and legacy pose phase; `CharacterEquipment3D.land_layout()` uses fixed offsets plus `sin(phase*TAU)` bob. The optional Lower branch adds its torso `attachmentOffset`, but current gear still does not use an authored palm/grip transform. Node visibility proof already accepted on b34d is distinct from hand/contact alignment.

Keep the existing detachable tank/net/satchel/vest nodes; do not bake gear into new arm pixels or create a second set of meshes. Clothes such as the explorer atlas vest remain clothing, with the existing extra vest node hidden. Body-carried tank/satchel sockets belong to the torso; a held net uses an explicitly authored hand grip with local orientation. No palm-marker pixel is silently promoted to a handle socket.

Map authored points through the actual existing upper sprite transform: for a 128×76 upper texture, its centered local point is `(x−64,38−y,depth)`. Apply the actual upper transform/parent scale once, rather than reconstructing a second camera projection or mirroring the gear by screen side. Hierarchical arm transforms from the WEST authoring manifest must transform the grip origin **and axis** together. Do not add the Lower attachment offset again after using that upper host transform. Unknown socket/depth data remains unsupported until authored and reviewed.

## Acceptance sequence after terrain passes

1. Review one source-complete SOUTH daily reconstruction and joint/grip annotations; retain explicit unknowns. Review the existing WEST authored seams separately.
2. Approve the final Lower-pose publication contract with the character owner; only then implement one opt-in contact consumer. Neither art uniqueness nor passing metadata validates it.
3. Record native start→steady→stop→resume→reverse/turn at gameplay scale, tracing accepted body displacement, final anatomical contact, actual upper joints and actual gear matrices. Verify opposite-arm extremes at contacts without a side swap or jump. Include paused/blocked and zero-XY settlement cases.
4. Extend to SOUTH explorer only after own source reconstruction and socket proof, then annotate other views individually. Keep unknown or rejected views outside the pilot; do not pass an eight-way suite through a legacy fallback.
5. Fresh focused physical flat/terrain regressions plus browser gear/visibility review are required before any coherent export. No current b34d or prior node screenshot inherits this future gait claim.

Only local source reads, existing image inspection, read-only Python/Pillow/hash checks, the existing front-palm CPU test and Git were used. Existing original-art terms and Pillow notice remain; no upstream code or new licensed asset is copied.
