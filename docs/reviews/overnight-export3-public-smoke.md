# Export3 public default-browser acceptance

**6/6 checks PASS** on the activated staging application using the default browser HTTP/2 path. This was actual login, gameplay input, journal, position reload and calendar heartbeats, not an asset-only diagnostic. Outcome `completed`, `defaultPublicAccepted=true`, `http1Diagnostic=false`; no browser or gameplay API failures were recorded.

## Package and scope

- Public origin: `https://staging-jalasmara.ardianryan.com`.
- Activated image supplied/verified by the integrator: `2036254db640df92f8db38a8b7b0f6cb75d39c19324613c17a2f033b48aa48b6`; Docker source `d63a10b`, export source `b0f2ef8`. Generated UID/export provenance remains separate from root's63-case source CI; see the [local export3 report](overnight-export3-left-browser.md).
- Actual HTTP PCK was hashed **before fixture creation**: SHA256 `73d45630ab69033ac36a64740ecc73ecdb7363c9f99805222b6a9237dcb2d18b`,64,494,656 decoded bytes.
- Harness launched from integration `0e446186a1e15d79a6ae1e26572c823222546c2e`, byte-identical to the reviewed `bd36d21` public/calendar scripts. The origin, guard and runtime were unchanged during this run.
- Own UUID `d07e56d3-965b-4d90-b251-72626c6cc6a4`, fresh declared200coins/story day1. No existing account, mid-route teleport, clock/lease injection, replacement API action or HTTP1 flag was used. One separate read-only lookup of this UUID's persisted surface confirmed route progress; it changed no state.

```sh
RUN_STAGING_SMOKE=plan06-public STAGING_STARTUP_TRACE=1 \
PLAN06_EXPECT_PCK=73d45630ab69033ac36a64740ecc73ecdb7363c9f99805222b6a9237dcb2d18b \
PLAN06_EXPECT_PCK_BYTES=64494656 \
node --import tsx scripts/staging-plan06-smoke.mjs
```

## Actual checks and clock proof

The six completed checks covered public health/package pin, form login/secure cookie/real game readiness, physical hub gate travel and settled alpha-backed canopy reveal, actual touch journal with movement pause and close, post-reload writer/active-time recovery, and unchanged server position/story/rewards. The alpha-backed target was142/1213; actual reached141.804794/1216.513550, one fully revealed crown index46 among47, trunks unchanged. Reload resumed those exact coordinates.

Route duration was381,635ms with560 motion-matrix keyboard pulses, within the unchanged eight-minute budget. Initial startup reached real READY/HUD33.803s after the first trace; reload reached READY33.259s after its first trace. The actual loader displayed47%/49MB and77%/80.4MB of104MB before detaching. Observed asset protocols were exclusively `h2`. These are Headless Chromium/SwiftShader/network observations, not Windows/S23 or general startup/FPS guarantees.

The new post-reload gate completed in8,898ms, below its35second bound. Both actual POST responses originated from the newly attached game iframe, HTTP200, focused=true, paused=false and writer=true. The opt-in snapshot also confirmed connected/writer-owned/unpaused. No HUD-label-only inference was used:

| Sanitized actual response field | First writer response | Later advancing response |
| --- | ---: | ---: |
| Observed timestamp | 1794255092776 | 1794255098104 |
| Server timestamp | 1794255092564 | 1794255097848 |
| Calendar day | 1 | 1 |
| Minute of day | 824.9113333333337 | 828.434666666667 |
| Calendar revision | 65 | 66 |
| Day length, milliseconds | 2160000 | 2160000 |

Authoritative calendar positions advanced by5,284.999999999968ms of equivalent active real time. The earlier instantaneous “Jam aktif di sesi lain” local screenshot therefore does not reproduce as a persistent clock failure in this public run. This proves recovery for this reload; it does not prove every multi-tab/expiry scenario.

Cleanup returned `ok=true`, with players0, receipts0, shifts0 and Redis keys0 for this fixture. The browser exited normally and its exclusive slot was released. No owner data, `.env`, volumes or shared proxy configuration changed.

## Evidence

Integration directory `artifacts/browser/staging-plan06-d07e56d3-965b-4d90-b251-72626c6cc6a4/`; log `.runtime/overnight-export3-public-smoke.log`. Raw results retain only the sanitized clock fields needed for this proof.

| Artifact | SHA256 |
| --- | --- |
| `results.json` | `12831e90de3ac72eb8e3cd2144de2665c04e94ebb20d7a4dac3ec226c9636dbf` |
| `02-public-physical-canopy-667x375.png` | `b853d7a713bfb60cb4bc711af2fd063c223b137cc97b7bf126ca6f514b20b1fe` |
| `03-public-journal-pauses-movement.png` | `b5d6a813ad7f3cec8203b289d45f68c9413d79be735f3f9b3e4bc827f3aa9e63` |
| `05-public-calendar-writer-resumes-after-reload.png` | `4c385d15b10d6a3833a438c445a61116a0a19cc9f6624f2055c32082f83fafc4` |

Actual PNG review shows readable closed badge frames, a separate Menu/touch area, the local canopy cutout and a working parchment journal. The journal contains undiscovered entries in this fresh account; this run does not add long scientific-text or natural-walking acceptance. The original five-minute local full-route failure remains preserved; its separate forest component PASS and this public smoke have their own stated scope.
