# Independent segmented PCK source review

Read-only review of combined source `5c2c59d`, specifically `scripts/pck-stream.mjs`, `apps/api/src/pck-parts.ts` and the export hook. No source change or independent browser acceptance was made by this review.

No blocking ordering/cancellation/version/cache defect was found. The client retains at most four pending part requests, consumes them in index order with zero queued-stream high-water mark, verifies each exact decoded byte count/offset/total and SHA-256, and aborts pending fetches on cancellation/failure. Orphan rejections are observed. Its manifest has strict bounded size/count/hash checks and the loader patch rejects upstream-pattern drift. The server binds parts to a pinned full-file checksum verified at startup, bounds indexes/offsets and serves hash-qualified immutable cache URLs. The existing whole-PCK route remains available. Root separately owns the API/loader tests and actual browser delivery proof; those are not rerun or independently claimed here.

A capacity caveat was sent to root before rollout:1200 part requests per IP per minute permits about19 cold62-part downloads per minute. A classroom of30 students behind one NAT can reach429 even though each individual request is valid. Choose/document a bound based on intended classroom concurrency, or use byte-aware traffic policy. This is separate from ordering and from the single-client public transport diagnosis.

No proxy setting, data, upstream code, asset license, production client or server file was modified by this lane. The next acceptance is the newly exported package in the actual local browser, followed by public default-protocol acceptance after root's explicit deployment/grant.
