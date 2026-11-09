# Public asset-only browser transport diagnostic

9 November 2026. Diagnostic only: **no gameplay acceptance**, authentication, database fixture, Godot, iframe, WASM compilation, product change or proxy mutation. Root explicitly granted the serialized single-PCK drain and a separate WASM drain, each with a 20-second reader budget. Both browsers closed before releasing the slot.

## Controlled scope

`scripts/staging-asset-transport-browser.mjs` requires `STAGING_TRANSPORT_DIAGNOSTIC=plan06-read` and explicit `PLAN06_TRANSPORT_ASSET=pck|wasm`. It fixes the staging origin. One synthetic same-origin minimal HTML document is fulfilled inside the browser; that document has no scripts, canvas or iframe. Only the selected real `/game/index.pck` or `/game/index.wasm` request is allowed through; it is not rewritten, mocked or fulfilled. A continuously drained fetch reader discards each body chunk.

Chromium uses default protocol negotiation and the preceding smoke's 844×390 touch context and launch arguments. Cache is disabled with CDP and fetch `cache=no-store`; neither observed response came from disk cache or a service worker. The page aborts its own fetch at 20 seconds; a separate 25-second watchdog closes an unexpectedly stuck consumer. Reports distinguish an intentional incomplete drain from normal full-body completion and always state `gameplayAccepted=false`. No account/cookie/session data is created or copied.

## Observed results

| Measurement | PCK, UUID `68e2775d-0d0f-417b-bdab-1b3c5d623d2e` | WASM, UUID `68797c33-ada5-45f5-bc0a-71a48a93fa4e` |
|---|---:|---:|
| Consumer outcome | Aborted at planned 20-second budget | Body completed |
| Reader elapsed | 20,007 ms | 387.4 ms |
| Decoded bytes drained | 1,505,785 | 39,514,754 |
| Reader chunks | 73 | 739 |
| HTTP status / protocol | 200 / h2 | 200 / h2 |
| Observed endpoint | 45.198.149.181:443 | 45.198.149.181:443 |
| Content-Encoding | Absent | gzip |
| Content-Length header | 64,333,184 | 10,054,758 |
| CDP dataLength total | 1,505,785 | 39,514,754 |
| CDP encodedDataLength total | 1,475,493 | 10,034,529 |
| CDP loadingFinished encodedDataLength | No normal completion | 10,066,641 |
| Page errors / diagnostic assertion failures | 0 / 0 | 0 / 0 |
| Browser closed / fixture created | true / false | true / false |

The PCK's `net::ERR_ABORTED`, canceled=true record was produced by this test's deliberate budget abort; it is not an independently observed body/transport rejection. The WASM's normal `loadingFinished` was recorded. Header compressed lengths, decoded reader bytes, incremental CDP encoded fields and final encoded completion fields are kept distinct rather than forced into one interchangeable byte count.

PCK request started at epoch `1794233246781`; planned abort was recorded at `1794233266795`. WASM request started at `1794233283627`, finished at `1794233284015`. These were two sequential fresh browser contexts, not a simultaneous or repeated controlled population. Temporal routing/load/client effects remain possible.

## What this establishes and what remains open

Slow PCK transfer occurred while the consumer continuously read it without the game, loader, iframe or WASM compilation. Those game components are therefore not necessary for that observed slowdown. The separate WASM response completed quickly over HTTP/2, so these observations also do not support a blanket claim that all public HTTP/2 asset transfers are slow.

This pair does not isolate a stable per-asset rule, HTTP/2 server defect, proxy policy, browser flow control or network shaping condition. It does not show that the [failed default gameplay startup](/docs/reviews/06p-public-default-5f5-result.md) is fixed. PCK integrity was not reverified by a partial body; package identity remains the complete preflight hash from that smoke. Further runs require root coordination and a concrete question, such as whether the same single-PCK drain repeats under otherwise identical conditions. No HTTP/1 fallback or server configuration was changed here.

## Evidence and reproduce

Own QA worktree `Jalasmara-06-gateway-qa`:

- `artifacts/browser/transport-pck-68e2775d-0d0f-417b-bdab-1b3c5d623d2e/results.json`
- `artifacts/browser/transport-wasm-68797c33-ada5-45f5-bc0a-71a48a93fa4e/results.json`
- Original logs `/tmp/jalasmara-pure-pck-transport.log` and `/tmp/jalasmara-pure-wasm-transport.log`.

Each result includes consumer/body outcome, CDP protocol/IP/allowlisted headers/bytes, five-second samples, the two document/asset request records, errors, and browser cleanup. No screenshots are useful for this intentionally blank document.

```sh
STAGING_TRANSPORT_DIAGNOSTIC=plan06-read \
PLAN06_TRANSPORT_ASSET=pck \
node scripts/staging-asset-transport-browser.mjs
```

Use `wasm` only as a separately authorized second mode. CPU syntax, Prettier and `git diff --check` passed; invoking without the explicit diagnostic guard was verified to exit 1 before any browser or artifact creation. Actual browser execution then completed both diagnostic scopes above. Tools used: existing Playwright/Chromium, Node, CDP, Git and JSON review; no new library or service.
