# Validated-contact audio consumer: source candidate

Worktree `Jalasmara-overnight-contact-audio`, branch `work/overnight-contact-audio`, base root`e661bb7`. Root authorizes **WorldFoley consumer only**; character owns planner/LowerBody producer and it remains unwired/OFF. No CharacterVisual/Player/Forest/LandActors/AudioManager/world/asset edits. No engine/import/browser has run for this candidate yet; source/fixture below is unparsed pending exclusive root grant.

`WorldFoley.set_foot_contact_source(Callable)` accepts the agreed optional batch `{mode,epoch,latestSequence,paused,validated,contacts}`. Contacts use explicit positive sequence, side, landing/stop_settlement kind, finite logical/worldPlant, supportId and known material. Bootstrap or mode/epoch change is a baseline barrier: queued events are discarded, legacy queue is drained, then fresh IDs can play. Provider should attach with empty bootstrap before publishing new contacts, and use a new epoch on rig/config/area/outfit reset. Retired epochs cannot be reactivated accidentally. `paused:true` within modepilot drops pending IDs while preserving sequence continuity; a mode change is an explicit stronger barrier.

Validated events play independently in order, using event material rather than actor traversal. Whole batch is rejected before playback if a new event is malformed/out-of-order/beyond declared latest sequence; discarded latest IDs cannot become a post-correction backlog. Repeat IDs are ignored. Mute/locked/focus loss, provider pause, host/clock/actor pause, water and relocation consume/drop pending pilot events. Active pilot drains the legacy queue and resets the fallback distance/cadence, so hidden pilot travel cannot become a delayed38-distance fallback step. Invalid/freed Callable makes a fresh legacy barrier, then resumes new legacy events. The source is never wired by this package.

Without a provider, original legacy contact/distance branch is retained byte-for-byte except one nesting tab; the source check confirms this. Existing material query/cache and all underwater/ambience/SFX pitch/volume behavior remain unchanged. New diagnostics appear only when a provider is configured. No provider performs terrain queries or validates a real anatomical landing here: `validated` and plant material are the future accepted producer's contract, not a claim this consumer independently proves geometry.

## Focused actual consumer fixture

New `scripts/tests/validated-contact-foley.gd` runs actual WorldFoley, CharacterVisual queue and AudioManager play requests (Master bus muted). A fixture provider supplies declared contact batches; **it is not actual NalaFootPlant integration**. Cases cover:

- Unwired legacy CharacterVisual event and idle; provider bootstrap,3/2-contact batches and actual AudioManager voice streams, plant-materialwood while actor traversal saysstone.
- Duplicate IDs, atomic invalid-material batch, no replay after correction; real stopped settlement once.
- Both queues drained through mute, pause, host/clock/frozen, focus and locked audio; no backlog on resume.
- New/retired epoch, water, relocation, explicit legacy mode and freed Callable fallback.
- Actor without gait:60units hidden pilot travel must not cause a later distance footstep, while fresh40units legacy travel must still play.

Assertions use fail-fast quit1. Registration proposal: add `scripts/tests/validated-contact-foley.gd` beside `scripts/tests/world-foley.gd` in `scripts/verify-living-world.mjs` **after focused parse/behavior PASS**. Root owns registration; not changed here. Also run existing `world-foley.gd` and `locomotion-collision-foley.gd` to prove default regressions with current assets. Proposed invocation uses integration's existing import cache, not a new worktree import.

CPU checks performed: `git diff --check` PASS, source comparison proves unchanged legacy branch; no Godot parse or behavior PASS yet. Provider epoch lifecycle and one-process-frame publication/consumption latency still need actual producer tests after character geometry acceptance. Queue/mixing on real S23/Windows and audible sync remain open. Default legacy and physical pilot state are unchanged by an unwired optional consumer.
