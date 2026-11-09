# Validated-contact audio consumer: source candidate

Worktree `Jalasmara-overnight-contact-audio`, branch `work/overnight-contact-audio`, base root`e661bb7`. Root authorizes **WorldFoley consumer only**; character owns planner/LowerBody producer and it remains unwired/OFF. No CharacterVisual/Player/Forest/LandActors/AudioManager/world/asset edits. Initial source candidate was unparsed while awaiting the exclusive slot; the root-run focused evidence below supersedes that status. This lane did not run its own engine/import/browser.

`WorldFoley.set_foot_contact_source(Callable)` accepts the agreed optional batch `{mode,epoch,latestSequence,paused,validated,contacts}`. Contacts use explicit positive sequence, side, landing/stop_settlement kind, finite logical/worldPlant, supportId and known material. Bootstrap or mode/epoch change is a baseline barrier: queued events are discarded, legacy queue is drained, then fresh IDs can play. Provider should attach with empty bootstrap before publishing new contacts, and use a new epoch on rig/config/area/outfit reset. Retired epochs cannot be reactivated accidentally. `paused:true` within modepilot drops pending IDs while preserving sequence continuity; a mode change is an explicit stronger barrier.

Validated events play independently in order, using event material rather than actor traversal. A batch above64 contacts is rejected atomically before per-event iteration and advances its discard watermark; it is an invalid producer condition, not an allowance to drop normal contacts. Whole batch is also rejected before playback if a new event is malformed/out-of-order/beyond declared latest sequence; discarded latest IDs cannot become a post-correction backlog. Repeat IDs are ignored. Mute/locked/focus loss, provider pause, host/clock/actor pause, water and relocation consume/drop pending pilot events. Active pilot drains the legacy queue and resets the fallback distance/cadence, so hidden pilot travel cannot become a delayed38-distance fallback step. Invalid/freed Callable makes a fresh legacy barrier, then resumes new legacy events. The source is never wired by this package.

Without a provider, original legacy contact/distance branch is retained byte-for-byte except one nesting tab; the source check confirms this. Existing material query/cache and all underwater/ambience/SFX pitch/volume behavior remain unchanged. New diagnostics appear only when a provider is configured; unwired `_process` uses null and does not allocate a contact Dictionary/Array. No provider performs terrain queries or validates a real anatomical landing here: `validated` and plant material are the future accepted producer's contract, not a claim this consumer independently proves geometry.

## Focused actual consumer fixture

New `scripts/tests/validated-contact-foley.gd` runs actual WorldFoley, CharacterVisual queue and AudioManager play requests (Master bus muted). A fixture provider supplies declared contact batches; **it is not actual NalaFootPlant integration**. Cases cover:

- Unwired legacy CharacterVisual event and idle; provider bootstrap,3/2-contact batches and actual AudioManager voice streams, provided plant-event materialwood while actor traversal saysstone. Events match declared fixture surfaces, but this is a supplied-material consumer test, **not proof that the real producer resolves actual support/material correctly**.
- Duplicate IDs, atomic invalid-material/oversized batch, no replay after correction or within-epoch mode-watermark rewind; real stopped settlement once.
- Both queues drained through mute, pause, host/clock/frozen, focus and locked audio; no backlog on resume.
- New/retired epoch, water, relocation, explicit legacy mode and freed Callable fallback.
- Actor without gait:60units hidden pilot travel must not cause a later distance footstep, while fresh40units legacy travel must still play.

Assertions use fail-fast quit1. Registration proposal: add `scripts/tests/validated-contact-foley.gd` beside `scripts/tests/world-foley.gd` in `scripts/verify-living-world.mjs` **after focused parse/behavior PASS**. Root owns registration; not changed here. Also run existing `world-foley.gd` and `locomotion-collision-foley.gd` to prove default regressions with current assets. Proposed invocation uses integration's existing import cache, not a new worktree import.

Initial CPU checks: `git diff --check` PASS and source comparison proves unchanged legacy branch; parse/behavior were not claimed before the root run. Provider epoch lifecycle and one-process-frame publication/consumption latency still need actual producer tests after character geometry acceptance. Queue/mixing on real S23/Windows and audible sync remain open. Default legacy and physical pilot state are unchanged by an unwired optional consumer.


## Root-run focused acceptance, local consumer only

Root integrated source sequence into `29c05bb` (consumer76eaa28, mixer fixture cleanupd530e30, within-epoch watermark8b54b20, allocation/batch bound29c05bb). Root exclusively ran installed Godot4.7.2 `ed1daf0bf` in the integration worktree, then explicitly RELEASED. Lane read the complete three logs and compared consumer/new-fixture file bytes against root29c05bb: **identical**, source hashes WorldFoley`c7bb8f22272ccb509a769239cedfd9786726e6b329428dfac04b7cc305775e25`, focused fixture`f2bc34aace3128bd51caa51efc7f74ef3844636150dc31160d1f78c2682b8482`.

| Actual root fixture | Result | Log SHA256 |
| --- | --- | --- |
|validated-contact-foley|PASS34 actual consumer/audio assertions; mocked provider;0SCRIPT ERROR/ERROR/WARNING|`5302617840bcfa5ac2b62eab0bf9052d8fa5d9f9c2f8c4bc5832c797c1cdca99`|
|world-foley|PASS imported8surface materials/connector/idle/mute/breath/ambience;0SCRIPT ERROR/ERROR/WARNING|`4bcdb3356b579d55de4a4a39dc4c8364959e45bd549ca8b120cdcef8b1c7af2f`|
|locomotion-collision-foley|PASS actual100logical/s Player collision and3contact-synced steps;0SCRIPT ERROR/ERROR; **WARNING4ObjectDB instances leaked at exit** in existing fixture|`873b32bbc519ea2d025996d139fac0fbcb513b9493b5dd0a882a1df61300b441`|

Logs: integration `.runtime/overnight-audio-consumer-{validated-contact-foley,world-foley,locomotion-collision-foley}.log`. Do not label all three logs warning-free. No extra engine or unrelated legacy-fixture cleanup performed in this lane. These are root's actual runs inspected independently, not locally rerun results or a new full-suite claim. Root will register the new fixture as proposed check65 separately.

**Remaining contract:** actual Nala producer queue still does not exist or feed this consumer. Character must supply explicit per-contact records and only publish after full rig/Q/reach/support validation, implement lifecycle epoch/sequence barriers, and prove material from real planted support. Geometry-before-audio integration, pause/settlement timing, multi-contact producer history and native audible/device sync remain open. The34 assertions prove consumer behavior with a fixture provider, not actual gait/audio alignment. Default pilot OFF and unwired; root explicitly excludes this local source from locked export4/current staging PCK and upcoming host image. No export, browser, new SFX/library/license or economy/server-state change accompanies it.
