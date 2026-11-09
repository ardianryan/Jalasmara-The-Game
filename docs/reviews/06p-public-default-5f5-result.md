# Default public browser smoke — 5f5 candidate

9 November 2026. **Failed at the bounded 120-second startup deadline. Default public acceptance remains open.** No HTTP/1 diagnostic rerun or proxy/product change was performed. The browser/WebGL slot was released after own-fixture cleanup.

## Release identity and execution

Root activated source `b5b459ea448bc8799bebb771e56df20ce5e8f039`, image `d60aab21ec405f85cd3c35b7c1cecd70b331142e280953364aa00de7f3e3e81b`, after its CI/backup checks. This smoke independently downloaded public health and the full PCK before inserting its account: health returned `status=ok`; SHA-256 `5f5baf243a3bf941cf34fab6c143bb9cf2bc8d65997ded6ed4e048b929353f96`, exactly 64,333,184 decoded bytes.

Executed the [prepared command](/docs/reviews/06p-default-public-smoke-ready-5f5.md) from `Jalasmara-06-buildings-gates`: startup trace enabled, `STAGING_HTTP1_DIAGNOSTIC` unset, default Chromium protocol negotiation, required current pin, fixed staging origin. No asset/API interception was installed. One exclusive browser ran; no other Godot/native/browser work overlapped this run.

UUID `152bacc6-39a7-4068-99bc-6d430c31f538` logged in through the real form. It reached Engine function/canvas creation but never actual game ready/HUD/snapshot. It did not begin a physical route or test the new canopy target. The final report explicitly records:

- `outcome=failed`, `completed=false`, `defaultPublicAccepted=false`.
- Failure: `stage=game-startup`, `AssertionError`, `ERR_ASSERTION`; exact message: `Public startup trace reached its bounded120-second deadline.`
- One completed check: public health/downloaded PCK identity. Zero matrix pulses.
- Zero console errors and zero failed API responses; those empty arrays do not make this a passed smoke.
- Cleanup `ok=true`: remaining players, receipts, shifts and Redis keys all zero. Browser closed; no other account/data was modified.

## Actual transfer observations

WASM and PCK both received HTTP 200 over `h2` from `45.198.149.181:443`, without disk cache or service worker. Both began at epoch `1794232860610` and received response headers at `1794232861164`. JS/bootstrap and the replacement iframe HTML finished normally. An initial iframe HTML request was canceled during replacement and followed by a successful HTML 200; that cancellation is not evidence for the later slow asset bodies.

At the last periodic trace, about 111 seconds after the first startup sample, the visible loader read **28%, 29.5 MB of 103.8 MB**. Both bodies were still pending, with no `loadingFailed`, body rejection or `loadingFinished` before the bound. Later screenshot/final event delivery advanced further while failure capture ran:

| Asset | Last periodic CDP data length | Final CDP data length | Final reported encoded data length |
|---|---:|---:|---:|
| WASM | 28,499,175 | 31,052,533 | 7,312,790 |
| PCK | 1,022,493 | 1,119,800 | 1,105,628 |

The actual failure screenshot shows the themed loader still active at **30%, 32.1 MB of 103.8 MB**, not an application error/retry notice. These are the recorded CDP fields, not interchangeable disk/gzip payload measurements. Neither body had a normal completion or read-error record in the final trace. Readiness remained false; canvas was still the initial 300×150 bootstrap size.

## Evidence and limits

Original artifacts (not copied into the curated accepted gallery):

- `Jalasmara-06-buildings-gates/artifacts/browser/staging-plan06-152bacc6-39a7-4068-99bc-6d430c31f538/results.json`
- The adjacent `failure.png`, visually inspected: active harbor loading screen, real percentage/MB, no game scene.
- `Jalasmara-06-buildings-gates/.runtime/public-default-5f5-browser.log`

The [local gateway/canopy acceptance](/docs/reviews/06b-local-world-browser-acceptance-5f5.md) and [actual body-error recovery](/docs/reviews/06p-loader-body-fault-browser.md) remain valid independent evidence. This public run did not reach those gameplay checks. Its pending asset bodies do not demonstrate that the tested stream-rejection recovery failed; no rejection occurred. Nor do the existing curl/client differences prove a specific HTTP/2/proxy defect.

Next bounded diagnostic proposed by the source reviewer: drain a single real PCK response in a same-origin blank browser document without Godot, iframe or WASM compilation, for at most 20 seconds. Record actual protocol/byte progress, then abort/close. This can separate pure browser transport from the parallel loader/compile path. It requires root coordination before execution, changes no product/proxy, and is diagnostic rather than a full-smoke replacement.
