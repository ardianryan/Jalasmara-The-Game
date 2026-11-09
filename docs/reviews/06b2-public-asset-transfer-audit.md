# Public startup transfer: read-only source and header review

The current public browser startup remains slow; this review does **not** identify a proven application or proxy cause. Root's current 5f5 browser observation records both asset response bodies pending, with no console/request error. Root also observed a slow Python HTTP/1.1 PCK transfer alongside faster curl transfers, so an HTTP/2-only explanation is not established. No proxy, application, export or browser setting was changed by this lane.

The source review used current main through `cc6b514` and its unchanged application/bootstrap delivery code. Only four public HEAD requests were added, using HTTP/2 and explicit identity or browser-style Accept-Encoding. No asset body, game engine, browser, authentication flow or database fixture was started by this lane.

## Established source behavior

- `apps/api/src/app.ts` registers `@fastify/static` with `preCompressed: true`. It contains no User-Agent or HTTP-version branch, dynamic compression hook, download delay or configured static throughput limit. API authentication/CSRF hooks return early for non-API paths. A global request-count rate limiter exists, but the observed asset responses are 200, not a demonstrated 429 rejection.
- The installed static/send implementation selects existing `.br`/`.gz` files through Accept-Encoding negotiation, falls back to the original file, adds Vary: accept-encoding, and delivers a filesystem read stream. HEAD sets the file's content length without streaming its body. This inspection does not establish how the deployed nginx/network buffers the body.
- `scripts/export-game.mjs` compresses assets ahead of deployment. PCK gzip is omitted if savings are below 5%; this is not runtime recompression. The current public PCK responses below have no Content-Encoding.
- The Godot preloader counts decoded response chunks against configured decoded file sizes. The React 103.8 MB denominator is not a wire-byte measurement. The bridge reuses existing requests; it does not start a second download. The host's stalled indicator does not reload the iframe automatically; only the explicit retry handler increments its key.
- `startGame` starts WASM initialization and PCK preload concurrently. The tracked stream reads and enqueues each source chunk without awaiting the UI progress callback; progress reporting runs separately. The WASM startup also clones a response for instantiation. These mechanisms add browser streaming/compilation work compared with curl, but source alone does not show that they caused the observed throughput difference. In particular, independent PCK body progress should be measured before blaming WASM compilation or decompression.

## Current public HEAD evidence

All four requests completed with HTTP/2 200 and nginx as the public server. Both assets advertise byte ranges, `Cache-Control: public, max-age=0`, and `Vary: accept-encoding`.

| Asset | Request Accept-Encoding | Content-Length | Content-Encoding | ETag |
| --- | --- | --- | --- | --- |
| WASM | `identity` | 39,514,754 | Absent | `W/"25af282-1a1c0935b08"` |
| WASM | `gzip, deflate, br, zstd` | 10,054,758 | `gzip` | `W/"996c66-1a1c0935b08"` |
| PCK | `identity` | 64,333,184 | Absent | `W/"3d5a580-1a1c0935b08"` |
| PCK | `gzip, deflate, br, zstd` | 64,333,184 | Absent | `W/"3d5a580-1a1c0935b08"` |

Thus this comparison shows expected encoding negotiation, with no conflicting content length or Vary header. It says nothing about sustained body throughput. The PCK size here belongs to the current public export; the earlier 43df export's 64,307,804-byte size must not be used for this comparison. Root's current release hash remains authoritative.

## Controlled browser comparison and remaining boundary

Website owns the browser slot. This lane proposed a fresh same-origin `/api/health` JSON document, followed by a fetch of **only** `/game/index.pck`, draining its `ReadableStream` reader and discarding chunks. This avoids Godot scripts, the iframe, WASM and the loading illustration while keeping the exact public asset URL and normal browser headers. The diagnostic must cancel its reader at the planned time limit so it cannot leave a background download.

Root subsequently reported website's actual result: HTTP 200, HTTP/2, the same public IP, **1,505,785 bytes in 73 chunks over 20,007 ms**, then the planned abort. This is a partial transfer, not a completed download. Website owns the forthcoming raw diagnostic artifact; this lane did not launch the browser and has not independently opened that artifact.

This reproduces slow transfer without the game loader, WASM compilation or React loading UI. PCK is uncompressed under both measured encoding headers, so its slow byte delivery also does not require WASM gzip decompression. It does not identify whether the remaining difference is client networking, request headers, path behavior, connection conditions or another delivery layer. Root's faster curl result and slower Python HTTP/1.1 result remain separate client observations, not a controlled protocol attribution.

A next minimal comparison, if needed, is curl using the exact browser User-Agent and Accept-Encoding against the same URL/IP, while recording protocol and connection timing, then comparing it with curl's original header set. Preserve cache/service-worker and CDP wire-byte facts in website's report. This proposed comparison was not run by this lane. No HTTP/2 disablement, proxy tuning, arbitrary timeout increase, loader rewrite or extra production instrumentation is justified by the current evidence alone.
