# Raw contact diagnostic producer: source and artifact peer

Read-only CPU/source/artifact peer of character `a4d7f75`. No Godot/browser or runtime edits by this lane. This is diagnostic producer work, not the accepted contact/audio provider: physical pilot remains OFF, `audioWired=false`, `intermediateContactPosesValidated=false` and `exactContactPhysicsFrameKnown=false`.

## Buffers, phase provenance and fixed lifecycle bugs

The planner records real walking/settling transitions at their existing counter increments, with side, prior/new plant, actual source ID, accepted-distance offset and actual connector membership separately from planned ordinal. Walking accepted distance uses frame-start accepted distance plus consumed chunk distance; it therefore retains multiple events within one final snapshot. Producer ID/epoch/sequence remain distinct. The64event cap reports overflow instead of silently claiming a complete batch. Arrays are deep copies; publishing clears pending records, and a rejected prior pose/reset/unsupported identity applies a discard/epoch barrier.

The first WIP copied cached `_last` during pause, which replayed both old `contactTrace.events` and cached `contacts.rawContactEvents`. The planner-only pause test did not exercise that Lower branch. This peer reported the concrete echo; the author now preserves the frozen visual pose while returning empty diagnostics/current epoch, and added an actual-controller→published Lower batch→pause regression. Terrain pause comparison strips only these diagnostic fields and separately requires empty events, preserving the original frozen visual-pose comparison.

A second WIP edge called `publish_contact_trace()` with its default true flag on a cached reach-rejected pose during pause. This peer reported that false validation claim. Final `a4d7f75` gates publication on cached enabled+reachValid and uses `publish_contact_trace(false)` to discard/advance epoch/return false for the explicitly tested invalid-cache lifecycle. The synthesized invalid cache is labelled as a lifecycle test, not a real invalid-motion proof.

`finalPoseValidated` is explicitly scoped to the final runtime-guard-enabled Lower pose. External mesh/triangle tests and all intermediate contact anatomy remain independent. Lower computes source length error for the existing fixture to check; the diagnostic must not be read as silently adding external validation. No raw transition is routed to the existing optional WorldFoley contact consumer or accepted by the independent contact-order checker as a rendered/validated intermediate pose.

## Actual artifacts read independently

Character-owned exclusive runs report unit PASS in5.304s and FIRST3 PASS138geometry samples in7.135s, zero recorded errors. This peer read their actual output:

- Unit macro update records LEFT walking at accepted10 and RIGHT walking42; a real LEFT zero-distance settlement records54. These raw planner tests use their declared legacy support extents and do not establish original-mask intermediate pose validity.
- The separate actual Lower publication/pause path produces a nonempty guarded batch, then zero paused events with identical stripped visual pose.
- The explicit invalid cached-pause result has `finalPoseValidated=false` and no events.
- FIRST3 central raw walking ordinals are LEFT60@31.75→RIGHT72@47.75→LEFT84@64.5→RIGHT96@87.144287; a later upper-flat96contact has actual membership outside/ordinal−1 despite planned ordinal5, exposing why membership and height-derived ordinal must remain separate.
- No paused events appear in this run. Every published final sample retains `intermediateContactPosesValidated=false`.

This newly timed run does not contain the old08bbf42central stop-settlement72/backtracking observation. It therefore cannot retroactively prove that old contact-order failure fixed, and diagnostics-only changes do not constitute such a gait fix. Same-source full16, DOWN approach geometry, intermediate bone/pixel support, native cadence and physical-device results remain outstanding. The actual same-source FULL16 central DOWN horizontal failure is preserved separately.

Provenance: unit `artifacts/godot/nala-contact-trace-a4d7f75/results.json` SHA256 `7cdabff951826f636560105ff611b13ceb326cb2b4834c970245da77afd2511a`; FIRST3 `artifacts/godot/nala-terrain-first3-contact-trace-a4d7f75/samples.jsonl` SHA256 `fb41d02a46aa95051d0f49eaafadaad715177e563388966d2eacad0002d7de55`. Author owns FootPlant/Lower/fixture; this lane owns only this peer report.
