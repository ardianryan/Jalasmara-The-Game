# Authored explorer NW0 orientation proposal

First bounded authoring step after the [NW source defect audit](overnight-nw-upper-source-audit.md). This **new original arrangement** uses original daily NW WALK0 head pixels and original explorer NW IDLE garment/body pixels. It is not recovered WALK artwork, a full upper rig, an eight-frame repair or a runtime replacement. New [tool](../../tools/player-gait/nw-explorer-orientation-proposal.py), [spec](../../tools/player-gait/nw-explorer-orientation-proposal.json) and [tests](../../tools/player-gait/nw-explorer-orientation-proposal-test.py) only write fresh ignored review output.

## Exact source choices and authored boundary

The original explorer WALK row5 is labeled NW but faces rear-right, opposite the coherent rear-left daily NW and explorer NW IDLE references. Root independently confirmed that discrepancy. Row7 also faces rear-right, so neither a row swap nor bitmap mirroring is used.

The candidate is128×76. Rows0..42 are byte-exact daily NW WALK frame0; rows43..75 are byte-exact explorer NW IDLE column5. Both are identity transforms: no scale, mirror, offset, raster recoloring or source-atlas mutation. Selecting and joining these references is explicitly **AUTHORED**, even though the contributing texels are original project pixels.

| Reference                    | SHA256                                                             |
| ---------------------------- | ------------------------------------------------------------------ |
| Original daily WALK atlas    | `342724d1724490279cd0f65c0340c5b35cdf366ecc36a99af716c51f751b8fc3` |
| Original explorer IDLE atlas | `68fad4626665bb75f41c61c8e950091f3f927428ca0e81090fffa6834c411f3f` |

The comparison contains original defective explorer WALK0, original daily NW0, original explorer NW IDLE and the authored hybrid. A pink line marks the authored y43 reference boundary. A separate enlarged neck/provenance sheet shows original head texels in gold and body texels in cyan. All rendered colors belong to the union of the two original reference palettes. The new upper does not claim to preserve the defective explorer WALK frame byte-for-byte.

Shelter viewed the actual four-panel probe: the candidate now has the same rear-left orientation as the daily/idle references, without an obvious head/neck detachment at the guide line. Neck/hair silhouette differs slightly between the two original reference poses, while identity, hairstyle and headband stay recognizable. This is bounded still review, not complete anatomy or natural motion acceptance.

## Deliberate limits

Only candidate frame0 is covered. Frames1–7 remain explicitly unresolved. Upper anatomical sides, source wrists/grips and contact phase stay unknown/null. No daily SOUTH viewer-right convention is transferred. No shoulder/elbow/wrist rig, arm mask or new Lower phase adapter is part of this step.

The explorer IDLE source already supplies one coherent garment/body set. No second torso, duplicate vest mesh, new bag/tank/net pixel or runtime node is created. Existing detachable equipment remains unchanged and is not tested by this CPU image.

## Actual checks and evidence

```sh
python3 tools/player-gait/nw-explorer-orientation-proposal-test.py
python3 -m py_compile tools/player-gait/nw-explorer-orientation-proposal.py tools/player-gait/nw-explorer-orientation-proposal-test.py
python3 tools/player-gait/nw-explorer-orientation-proposal.py --output artifacts/player-gait/nw-explorer-orientation-proposal-fresh
```

**4/4 CPU tests PASS**; `py_compile` and `git diff --check` PASS. Tests verify exact original head/body chunks and palette union; actual42 opaque neighbor contacts across source rows42/43; explicit single-frame/unknown side/phase scope; rejecting mirror, shifted split, fabricated side or widened frame coverage; unchanged input/original source hashes; and runtime output refusal. Boundary contacts establish an alpha connection, not neck anatomy or automatic visual heading correctness. Source orientation is reviewed visually, not detected by those tests. No engine/native/browser/GPU, physics, Lower or runtime export ran.

Ignored review directory: `artifacts/player-gait/nw-explorer-orientation-proposal-v1/`.

| File                                              |  Bytes | SHA256                                                             |
| ------------------------------------------------- | -----: | ------------------------------------------------------------------ |
| `authored-explorer-NW0-upper.png`                 |  4,722 | `e917457e5feb1d0bfe58a83b485d3f6718989ebffe858621471ddb819f7fc36e` |
| `nw-explorer-authored-orientation-comparison.png` | 27,093 | `beb1161d1f49f948babe2488673a191ed68b4d65f458bb4faef887e3d90a915d` |
| `nw-explorer-authored-neck-and-provenance.png`    |  6,810 | `e9c483c47878d74b9764dfdc3ab43c69e0cbac8fa28e8122f395b5aa430790fe` |
| `manifest.json`                                   |  8,299 | `c2fc4368c9339a7148609cb5127391e761b294adb21a66e4c93220e6c0060df2` |

The earlier raw exploratory sheet remains under `artifacts/player-gait/nw-explorer-repair-probe-v1/`; it has the same source arrangement. The final manifest pins source/tool/spec, output RGBA, original head/body chunk hashes, source opaque runs and exact boundary contacts.

Next: root/character review this coherent original arrangement and neck silhouette, then author explorer NW sleeve/garment masks and two separate endpoint poses with explicit new joints/side convention. Source uncertainty must stay distinct from any new anatomical decisions. A full periodic cycle, stops/turns, dynamic depth, grip/socket integration and final Lower contacts remain separate pending work. No original atlas, runtime flag, Lower/gear source or other identity/outfit was touched; Gemini's isolated other10-set audit is outside this lane.

Actual tools: local Python/Pillow, original project PNG/JSON, CPU compositing, image/source inspection and Git. The new arrangement/code is original project work; original-art terms and [Pillow notice](../../tools/player-gait/LICENSE-Pillow.txt) remain. No generated/downloaded sprite, external API/key or third-party implementation was used.


Root integration06.46WIB: Root independently passed4CPU tests and exporter; comparison SHAbeb1161d…90a915d matches. Root viewed the complete four-panel source/proposal image: coherent rear-left orientation and no obvious detached neck in this still, not full gait or side/grip acceptance. Curated original-byte evidence is linked from [the gallery](../visual/README.md). Test registration in CI source is not a new CI run.
