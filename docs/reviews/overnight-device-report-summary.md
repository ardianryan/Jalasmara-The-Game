# Offline performance-report reader

Status: source and CPU tests only; new original Node helper, no runtime/host/API changes or new engine/browser runs. Physical Samsung S23 and Windows testing remains pending user captures.

Added a bounded read-only local reader, allowlisted summary and same-PCK comparison for downloaded schema 1 recorder JSON. It preserves unknown/changed provenance, distinguishes requested from sampled effective quality, reports software renderers, and withholds deltas for Auto→Low versus manual Low. Compatible distinct-profile differences are descriptive; scene, route and thermal conditions are not recorded and cannot support causal or target-pass claims.

Validation: `node --test scripts/performance/device-report-summary.test.mjs` passed 10/10 tests. Coverage includes the exact prior AUTO30 SwiftShader capture, explicitly synthetic profile/device/window/viewport/PCK boundary cases, mixed/missing quality, paused/sparse coverage, missing metrics, schema/size limits, FIFO rejection without waiting for a writer, read-only operation and fixed parser/file errors that do not echo private values or paths. CLI execution on the exact capture succeeded and preserved its SHA. No real physical-device pair has been measured or compared.

The retained original fixture is 14,494 bytes with SHA-256 `d26f6036f2f5c4d6f40fd9cdd9ce3a4948138bfac7b7735fd3f8794b4ac38595`. A nested-key allowlist and private-value review preceded copying; no account/email/token/cookie/URL/coordinate values are present. It records software renderer SwiftShader, 30,104.5 ms, 25 active / 3 paused samples, Auto→Low and loader PCK b34d / 64,495,984 bytes. It is not a physical benchmark. See [fixture provenance](../../scripts/performance/fixtures/README.md) and [usage/interpretation](../performance/device-report-summary.md).

Tools actually used: local Node.js built-in filesystem/test/crypto modules, Git, Python for the byte-identical copy/privacy inventory, and the repository's existing Prettier. No dependency, upload service, external tool source, GPU or new art was used. Root retains ownership of the physical-device guide and release handoff.
