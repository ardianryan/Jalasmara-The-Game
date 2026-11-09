# Final CI artifact review: 798a47b

Read-only GitLab API/artifact review through `glab`, completed2026-11-09UTC. No runtime, CI configuration, fixture source, shared handoff/PRD or proxy was changed. Only the two small CodeQL artifact ZIPs and job metadata were downloaded into the reviewer's ignored `.runtime` directory; no build/export archive was downloaded and no engine/browser was launched.

Final source: `798a47b00a8f471069033a0d6419cd201e7aa008`, [pipeline3046335495](https://gitlab.com/ardianryan/jalasmara-the-game/-/pipelines/3046335495). The actual job API reports all four jobs successful: verify17872568373, godot_web17872568374, build17872568375, [codeql17872568376](https://gitlab.com/ardianryan/jalasmara-the-game/-/jobs/17872568376). CodeQL finished at2026-11-09T17:53:31.354Z. Successful job status is distinct from an empty SARIF result set.

Comparison source: `480d27d329f836d90f88b79e4c21a59beb89703b`, [pipeline3046266187](https://gitlab.com/ardianryan/jalasmara-the-game/-/pipelines/3046266187), [codeql17872014867](https://gitlab.com/ardianryan/jalasmara-the-game/-/jobs/17872014867). Its actual SARIF contained five findings. Both artifacts identify CodeQL2.27.4 and201loaded rules.

| Finding | Previous artifact | Final artifact |
|---|---|---|
| `js/file-system-race` at `apps/api/src/pck-parts.ts:31` |warning |absent |
| `js/useless-assignment-to-local` at `scripts/performance/recorder-browser.mjs:275` |warning |absent |
| `js/http-to-file-access` at `scripts/loading-body-fault-browser.mjs:630` |warning |warning retained |
| `js/unused-local-variable`, `initMethods`, fixture engine-init:50 |note |note retained |
| `js/unused-local-variable`, `Preloader`, fixture preloader:6 |note |note retained |

The intended bounded single-open manifest reader and unused-phase cleanup are therefore reflected in the real final artifact: five results became three, specifically three warnings/two notes became one warning/two notes. Effective levels were resolved from each result's rule default configuration because the result-level `level` field is absent. This is **not zero-SARIF acceptance**, and no finding was suppressed or reclassified by this review.

The remaining HTTP-to-file result has security-severity6.3 in the rule metadata. Its actual code flows start at the fetched bootstrap's `config.fileSizes` and the fetched part manifest fields, then reach `JSON.stringify(result)` written to the QA artifact. The inspected sink is the fixed `results.json` under a generated UUID directory; the recorded flow does not show remote data constructing that path. This is an explanation of the actual reported flow, not a claim that the warning is resolved or permission to suppress it. Any subsequent cleanup should preserve real validation and artifact evidence. The two notes are in standalone upstream-derived loader fixtures; altering their original source merely to quiet the analyzer needs separate provenance consideration.

## Artifact identity

- Final ZIP:28,380bytes, SHA256 `442ed00b59d181a88544a34803770265f95724c0624e1e81fc197811876b8b74`.
- Previous ZIP:28,522bytes, SHA256 `ad8148b228a95ae721b76cd5d7d43eca899a05d9e5101fc4155eb0f5d34e2f90`.
- Both contain only `reports/codeql.sarif`; the JSON was read directly from the ZIP, without extracting executable content.
- Local evidence: own `.runtime/final-ci-17872568376.zip`, `.runtime/prior-ci-17872014867.zip`, corresponding `.sarif` files and filtered job metadata.

No account token, cookie, credential, environment content or raw authenticated job payload is copied into this report. This verifies artifact findings and job statuses only; it is not a public gameplay smoke, hardware performance result, deployment confirmation or independent rerun of all CI tests.
