# Offline device-report summary

Read one downloaded `jalasmara-device-performance` schema 1 report, or compare two reports from the same PCK. Requires Node.js; uses built-in modules only. It reads local files and writes JSON to stdout. It does not upload, modify captures, fetch a manifest, or start the game.

```sh
node scripts/performance/device-report-summary.mjs ./auto.json
node scripts/performance/device-report-summary.mjs ./auto.json ./ringan.json > ./summary.json
node --test scripts/performance/device-report-summary.test.mjs
```

Use separate paths for input and redirected output. Shell redirection can overwrite an input before Node opens it. Each input must be a regular local file no larger than 4 MiB, with at most 2,000 samples. Invalid JSON/schema/file errors return exit 1 and a fixed error code without printing source values or paths. A valid report returns exit 0 even if comparison is withheld: inspect `comparison.compatible` and `reasons`.

## Reading the result

- `hardware` contains allowlisted browser-reported device/GPU metadata. `reported-software` explicitly identifies renderers such as SwiftShader. An undetected software renderer is **not proof of a physical device**.
- `quality.configuredRequested` is the setting selected before capture. `activeSampled` records the requested/effective pairs actually sampled while unpaused. Missing or mixed profiles remain unknown for comparison.
- `coverage` reports active and paused sample counts. These once-per-second samples do not measure exact paused wall time. `engine` distributions are recomputed from active samples; unavailable values remain null. `raf` describes browser scheduling, not GPU frame duration.
- `provenance` is `known-loader-pin` only when both recorded boundaries have matching valid pins, the same document, and `unchanged-loader-pin`. The kind remains `all-parts-verified-manifest`, not a computed whole-file hash or runtime attestation. Older records without provenance stay `unavailable`; changed/incomplete identities cannot be assigned the current release.

Comparison requires matching recognized measurement definitions, complete matching browser/device metadata, viewport/DPR, configured duration/reason, sufficiently similar actual duration, compatible active coverage, stable sampled profiles and the exact same known PCK pin. Automatic captures must end within 5% of their configured deadline. Recorded coverage must be at least 80%, active coverage at least 70%, and the difference in active coverage at most 10 percentage points. Truncated RAF windows are rejected. These are comparison checks, not performance targets.

Auto may select `low`. Comparing that capture with requested `low` produces `distinctEffectiveProfiles: false` and no profile deltas. Compatible distinct profiles produce descriptive second-minus-first differences only. Reports do not record a controlled route, scene, thermal state or other applications, so the helper cannot establish a causal FPS improvement, a target pass, or physical-device identity. Keep the user's route and thermal notes alongside the JSON.

## Included regression capture

The [fixture notice](../../scripts/performance/fixtures/README.md) identifies the exact earlier AUTO30 software-rendered capture. It is useful for schema/reader tests, **not a Samsung S23 or Windows measurement**. Other compatibility fixtures are explicitly synthetic and constructed in the test source. No physical-device results have been fabricated.
