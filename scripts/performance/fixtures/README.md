# Device report fixture

`device-auto30-swiftshader-b34d.json` is the exact, unfiltered JSON downloaded by the earlier actual AUTO30 recorder browser test. It is a **HeadlessChrome/SwiftShader software-rendered capture**, not physical Windows or Samsung S23 evidence.

- Original evidence: `artifacts/browser/performance-recorder-e0dd5e08-1fb3-4d4a-8629-286f1471f2b7/downloaded-performance.json` in the integration worktree; [accepted test report](../../../docs/reviews/overnight-recorder-provenance-browser.md).
- Bytes: 14,494; SHA-256: `d26f6036f2f5c4d6f40fd9cdd9ce3a4948138bfac7b7735fd3f8794b4ac38595`.
- Loader PCK:`b34d95211a61354eebf9cd218455d1c2f4e4b99723b57e4cfbe2b0a113f0ba26`, 64,495,984 bytes / 62 parts.
- Actual duration 30,104.5 ms; reason `duration-completed`; 28 samples, 25 active / 3 paused; requested `auto`, sampled effective `low`.

The fixture was reviewed before copying: every nested key belongs to the recorder allowlist; there are no account identifiers, email addresses, tokens, cookies, URLs or gameplay coordinates. Static privacy definitions mention excluded field names but contain no such private values. Browser/GPU metadata and allowed timestamps are retained as recorded. The copy matches the original byte-for-byte; do not run formatters on it.

The test source constructs and clearly labels synthetic comparison/boundary cases. Those are not additional device captures. Project licensing applies; no third-party asset or engine code was copied for this helper.
