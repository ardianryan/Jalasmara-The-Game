# Performance-report PCK provenance: source peer review

Scope: CPU/read-only review of `scripts/pck-stream.mjs` and `apps/web/src/performance-capture.ts` before the integrator's future provenance change. Root owns both implementations. This report changes neither file and runs no engine/browser/export. Existing physical-recorder manual/AUTO30 evidence does **not** gain a PCK identity retroactively.

The proposed allowlisted identity is useful. The adapter already validates manifest schema, each part's size/offset/total length and SHA256, delivers in order, bounds prefetch and aborts pending bodies on cancellation/error. Publishing a copied identity only at successful terminal delivery can identify the manifest used for that completed stream. Use the exact verification label **`all-parts-verified-manifest`**: the stream verifies each part against the embedded manifest, but does not compute the whole-file SHA at runtime or attest that Godot initialized successfully. `controller.enqueue(last)`/`close()` hands bytes to the consumer; engine READY remains a separate prerequisite for an actual gameplay capture.

## Requirements and edges

1. Snapshot the validated primitive SHA/byte values, rather than retaining a mutable caller-manifest reference for publication. Publish only after all ordered verified bytes have been delivered, never at fetch-response creation, speculative prefetch completion or early consumer cancellation. A checksum/body/header failure or timeout must leave no new verified identity.
2. Freeze/copy the fixed identity and expose it through a read-only property or equivalent fixed getter. This protects ordinary accidental mutation, **not** hostile same-origin JavaScript or developer-tools tampering. Do not call it secure runtime attestation. If multiple attempts can overlap, an older callback must not overwrite a newer attempt's status; isolate attempts/generations or explicitly constrain the single immutable per-frame identity.
3. Metadata publication must not throw through the stream and fail a valid game download. Property collisions/non-extensible globals or a publisher callback failure should leave provenance unavailable. They must not manufacture a candidate pin or alter ordering, backpressure, cancellation, startup progress or game loading.
4. Recorder start/end should independently read and sanitize copied values from the actual captured iframe. Validate schema/verification kind, lowercase64hex SHA and safe positive bounded byte length. Ignore extra fields; copy no URL, page path, manifest fetch result, account/token, arbitrary object graph or mutable source reference. Catch access/getter/cross-origin failures and mark unavailable.
5. Report availability at both boundaries and whether identities differ. Missing-at-start then available-at-end is incomplete provenance, not proof of an unchanged whole session; likewise present-at-start/missing-at-end. Never fill gaps using the newest host build, another API, a separate manifest request or a previous report.
6. Same iframe element navigation retains a WindowProxy. The existing recorder only checks `frame.isConnected` each second. Compare the original document identity internally as well (without exporting its URL or object), so a replaced document with the same PCK does not masquerade as an uninterrupted recording. A changed document/read failure should be flagged or terminate as the existing frame-replaced case; metric/device samples must not silently mix generations.
7. Keep schema1 old reports valid if the new block is additive and existing field semantics remain unchanged. Absence in an older report means unknown, not the current release. If a strict consumer is changed, test a genuine old schema1 fixture too. Definitions/privacy copy should explain that the SHA is the declared embedded-manifest identity tied to complete per-part verification, not a newly computed whole-file digest or physical-device performance acceptance.

## Focused tests recommended to root

Use the actual adapter stream and actual recorder sanitizer/build path. Successful full ordered drain publishes once with exact copied values; mutate the input manifest afterward and prove the published object unchanged. Partial read/cancel, prefetched-but-undelivered completion, checksum/header/body/timeout errors publish nothing. Retry and overlapping attempts cannot publish stale identity. A throwing publisher must preserve successful response bytes and never produce a false identity.

For reports: valid start/end, malformed hash/bytes/kind, extra private fields, throwing access, frozen/mutable source copies, one boundary missing, changed identity, replaced iframe document with unchanged hash, and old report without provenance. Keep the device JSON generated locally; no upload or extra asset fetch is needed.

This is design review, not a new finding that existing PCK73d loading or AUTO30 capture failed. Parent already has separate actual startup, recorder and full public route proofs. New provenance should be tested and released with the next coherent host/game package.

## Prepared future downloaded-recorder proof

The explicit `PERFORMANCE_RECORDER_PROVENANCE=1` harness addition is prepared for a **new coherent export and host**, not current73d or a retroactive reinterpretation of the historical manual/AUTO30 results. Normal recorder mode remains unchanged without the flag. The old73d hash is refused before fixture allocation. After the existing full PCK HTTP hash/byte check, a bounded15s/4MiB live `game/index.js` source probe must contain the provenance-capable segmented adapter and exactly one matching embedded manifest. Missing/old loader capability or wrong SHA/length fails before the owned player is inserted. This source preflight is explicitly labelled capability-only, **not** a loaded runtime identity proof; it executes no loader code.

The actual browser must then reach game READY with no full diagnostics/account snapshot enabled and expose its own strict allowlisted loader identity with the exact expected new SHA/bytes/part count and `all-parts-verified-manifest`. The existing UI start, selected30s duration, menu pause/resume, manual stop or actualAUTO30 completion, download and owned cleanup flow is unchanged. The downloaded JSON itself—not a constructed replacement—must carry `assetProvenance.status="unchanged-loader-pin"`, `document="same"` and exact matching start/end identities. Missing, changed, unobserved-document, wrong verification kind or private extra fields fail; no current candidate identity is inserted into the report by the harness. Existing report privacy and real-engine sample checks still run.

Three CPU gate tests PASS: explicit-mode/legacy rejection, bounded loader capability plus exact manifest parser rejection cases, downloaded JSON contract and negative cases. An additional source-only check used root's actual `withSegmentedPck` on its real Godot preloader fixture and generated manifest; the parser accepted its two-part wrapper. Harness syntax/`git diff --check` pass. No browser, engine, build or export was run for this prepared mode.

After integrator supplies the new verified package and grants its browser slot:

```sh
APP_TEST_ORIGIN=http://localhost:3111 PERFORMANCE_RECORDER_MODE=auto30 \
PERFORMANCE_RECORDER_PROVENANCE=1 PLAN06_EXPECT_PCK="$NEXT_PCK_SHA" \
PLAN06_EXPECT_PCK_BYTES="$NEXT_PCK_BYTES" \
node --import tsx scripts/performance/recorder-browser.mjs
```

The future outcome must preserve source/PCK/loader hash, actual downloaded JSON and original screenshots, browser/API errors and targeted cleanup. This will verify reporting provenance under Chromium automation; it will not supply Samsung S23/Windows physical performance measurements or GPU timing.
