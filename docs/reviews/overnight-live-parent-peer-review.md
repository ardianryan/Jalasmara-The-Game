# Read-only review: real live-parent breeding harness

Reviewed commit `1c38dd6` from the resident-art worktree against current Main/HomesteadUI, API game/homestead/daily code and the published-source ability definitions. No engine, browser, database write, renderer/UI edit, package change or shared-file edit was performed. Independent CPU execution of `live-parent-navigation.test.mjs` passed2/2; browser script syntax passed. These do not establish actual capture, feeding, sleep or breeding success.

## Fix before the first long browser run

1. **Preserve cleanup after uncertain insertion.** `created=true` currently follows awaited `players.insertOne` (browser script around line332). If the write reaches Mongo but its acknowledgement throws, finally skips this UUID. Mark creation attempted immediately before the write; existing exact UUID/email/name/role deletion remains safe even if no record was committed. No broad cleanup is needed.
2. **Do not let shutdown failure bypass cleanup.** `await browser?.close()` is before the cleanup try at line654. A browser shutdown exception prevents database/Redis deletion and result writing. Catch/report that owned shutdown failure, perform exact fixture cleanup regardless, and keep the overall outcome failed if shutdown fails.
3. **Capture the final failed state before closing.** The current catch only prints/stores the thrown error. A timeout after several minutes would lose the actual swimmer position, nearest object, modal/home/renderer state and original frame. Save a bounded failure PNG and the opt-in snapshot, or a compact position/scene/modal/nearby/quality subset, before closing. This is needed to diagnose an honest first failure without repeating the full18minute prefix.
4. **Verify shift cleanup as well as deleting it.** Cleanup deletes own `shifts` at line668 but verifies only player/receipts/Redis counts. Add the same zero-count assertion for `userId=id` used by the other accepted harnesses.

No production change is recommended by this review. These findings concern test reliability/evidence, not a demonstrated runtime bug.

## Real UI and authoritative state checks

The tested flow uses declared fixture story/calendar/permit/gear/location only. Inventory, liveCatch, breeders, offspring and produce begin at zero. Subsequent mutations originate from actual UI keyboard input. API GETs read ledgers; direct DB/Redis writes occur only during setup and exact cleanup. No seeded capture/net timestamp, fake parent, reward injection, runtime teleport or weather/clock override was found.

Source response shapes match the proposed assertions: ordinary collect returns `dive/stars/fragment`; successful extract returns `player/loot/fainted/surface`, so the harness correctly reads canonical homestead afterward rather than inventing an extract home bundle. It checks live catch stays session-only before extraction and knowledge loot remains separate from parents. Both stock and final harvest retain the server's revision/idempotency guards.

The keyboard sequence matches current HomesteadUI: stock rebuilds the page with enabled feed first; feed is followed by an explicit Escape; bed itself supplies `confirmEarly` when required; sleep rebuilds with the focused wake button; home exit waits actual land renderer readiness. After the second sleep, feed is enabled for the new day and the ready harvest button follows it, so one Tab from the first focus reaches harvest. The scroller follows focus. None of this is actual browser confirmation yet; retain exact action predicates so an unexpected focus target fails honestly.

The actual successful-extract message is a one-page `_show_message`, so the bounded Escape/Enter closer fits this route; it is not general coverage for a multistep boss cutscene. Home entry waits for actual home renderer/inside state, and exit waits for actual active land before another route. Pending story advancement is never created by this fixture's sleeps, so story day/stage should remain unchanged while the real fed calendar settles.

## Three-star timing and navigation limits

The server sets private `netAt` before returning net/start; collect gives three stars only when its own duration is600–1400ms. Holding800ms after the actual ACK is a plausible central target, with client-frame and final position-sync latency still contributing. There is no basis to weaken the real stars3 assertion or inject a quality fallback. Before the long run, add request/response timestamps—especially net/start ACK and collect send/response with target ID—to the trace so a genuine two-star outcome can be diagnosed. The private server `netAt` is intentionally absent from diveView; do not expose it in production solely for this harness.

Ocean helper clearance24 exceeds the server contour12 margin and includes static hazard avoidance. Independent dense route tests passed; this is geometric proof, not proof that real accelerated swimming stays on the path or avoids every moving actor. The hard18minute active-route budget and phase heartbeat are explicit before the first run. Natural calendar rollover or oxygen exhaustion must remain a reported actual outcome, not be repaired by changing the runtime clock, movement or inventory mid-flow. The level3 source values are oxygen220/speed185/bag24/net125; no physical-device or elapsed-time guarantee follows from those nominal values.

Root/owner received the minimal findings directly. The harness owner should implement the cleanup/failure evidence/timing changes, then run the pinned local candidate once under an exclusive browser grant. Preserve failed results and exact cleanup if any genuine UI/capture/transition assertion fails.
