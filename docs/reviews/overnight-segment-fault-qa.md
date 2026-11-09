# Segmented loader fault acceptance: prepared

The loader fault harness now detects the actual local PCK manifest before creating its own UUID fixture. It validates the manifest against the required live whole-PCK SHA/byte pin and fetches the real versioned part2, checking its size, offset, total and SHA. The injected body uses that actual part's first256KiB. Legacy exports without the manifest retain direct-PCK fault support; WASM fault selection is unchanged.

The fault helper accepts only a validated local asset path. Versioned parts require consistent whole-pack length/index/part size. It sends200 and correct `Content-Length`, `X-Pck-Offset`, `X-Pck-Length`, plus CORS-exposed metadata, writes the partial body in timed chunks, then destroys the socket. This avoids an artificial missing-header rejection before body reading. Five focused Node tests passed, including actual valid versioned-part headers followed by a rejected reader with the exact received prefix and bounded invalid-metadata/path cases. Browser source syntax passed. No new external dependency or production loader/API edit was made here.

The browser harness retains four upstream PCK attempts, the single raw-WASM attempt, actual byte-driven percentage, visible failure/retry, healthy real-game restart, unchanged resources/story and verified own UUID/session cleanup. It now intercepts versioned part2, traces all actual part requests and requires partial progress containing the preceding verified PCK parts. Root owns normalization of the existing tracked-stream-error patch for the new exported loader; that preflight must remain satisfied by the candidate itself, not patched by the browser harness.

This package is prepared, not an actual browser PASS. Required next command from the combined worktree, after root grants its browser slot and provides the new package pin:

```sh
APP_TEST_ORIGIN=http://localhost:3111 \
PLAN06_LOADER_FAULT=pck \
PLAN06_EXPECT_PCK=<new-sha256> \
PLAN06_EXPECT_PCK_BYTES=<new-byte-count> \
node --import tsx scripts/loading-body-fault-browser.mjs
```

Run WASM mode separately afterward if granted. These are explicitly injected local network body failures; they are not a production server failure, a public HTTP2 fix, a real-device performance result or an excuse to relax image/byte/cleanup assertions.
