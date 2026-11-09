# Website loading: Bandar Hujung

9 November 2026. Independent website lane, branch `work/website-loading`.

The initial screen now shows original Bandar Hujung artwork, the existing Jalasmara brand, an accessible progress bar, downloaded megabytes and the download percentage when the engine reports a valid total. Unknown totals stay indeterminate. Finishing the download does not dismiss the screen: the host waits for the actual world-ready message while showing the separate preparation stage.

The harbor and transparent foreground use separate CSS layers. Pointer parallax is bounded to a few pixels and the slow tide movement uses CSS transforms. Both are disabled on coarse touch devices and for reduced motion. No canvas, extra game render or animation loop was added. Runtime artwork totals 567,756 bytes before HTTP compression. Original PNGs, exact generation prompts and source hashes are in `assets/source-2d/loading-bandar-hujung-v1/`. The root agent generated these original assets using built-in `image_gen`; this lane integrated them. No commercial asset pack pixels are included.

## Progress and recovery

- `scripts/game-loading-bridge.mjs` instruments the default exported shell's existing progress, preparation and error callbacks. It makes no additional requests for the game bundle. `scripts/export-game.mjs` applies this source-controlled bridge before extracting and compressing the bootstrap scripts.
- Each expected shell hook must occur exactly once. An upstream shell change fails the export instead of silently producing a loader without progress. Non-engine inline scripts pass through unchanged.
- Loading messages require the exact iframe window, the current origin, protocol version 1, a recognized phase and valid integer byte counts. The existing engine-ready protocol is retained. Preparing cannot regress to downloading after a late transfer message.
- Thirty seconds without a new progress observation shows an honest stalled notice. No ETA or time-based fake percentage is shown. Returning from a hidden tab resets the stall observation window.
- Failure and stalled states offer a real reload and direct game link. Reload replaces the single iframe, resets the loading state and uses normal browser asset caching. Old frame messages cannot control the new frame. A load failure never exposes arbitrary technical exception text in the product.
- Menu, fullscreen, saved quality, safe areas, viewport updates and host pause behavior remain in place. Loading text is at least 16 CSS pixels; recovery controls are at least 48 pixels high.

## Verification

Commands, run in this worktree:

```sh
npm run typecheck
npm run build -w @jalasmara/web
node --test scripts/game-loading-bridge.test.mjs
PLAY_HOST_ORIGIN=http://localhost:5175 node scripts/loading-screen-browser.mjs
PLAY_HOST_ORIGIN=http://localhost:5175 node scripts/play-host-browser.mjs
```

Typecheck and production web build passed. Four bridge tests passed, covering real callback forwarding, unknown totals, error, standalone use and changed shell rejection. The actual previously exported bootstrap was also passed through the bridge and parsed successfully with all three hooks present. No new Godot export was run in this lane because the engine slot is shared; the root must export after integrating this commit.

The loading browser suite passed 24 grouped checks with zero page errors across desktop 1440×900, touch landscape 667×375, touch portrait 390×844 and reduced-motion desktop 1024×768. It covers known/unknown byte counts, source/origin/version and malformed count rejection, 100% download versus actual ready, preparation ordering, stalls, error recovery, one-frame retries, readable text, zero horizontal overflow and disabled motion when required. The existing seven host checks also passed, including actual browser fullscreen entry/exit and rejection, keyboard menu focus, quality persistence, blocked-storage fallback and orientation changes.

The game iframe and authenticated session are fixtures in these browser suites. Their screenshots show a **fixture download of 25 MB from 100 MB**, not the actual release size. They do not establish live engine startup time, Windows or Samsung S23 frame rates, or physical-device thermal behavior. The root must verify the new bridge with the real exported game before release.

Screenshots and JSON results, ignored local artifacts:

- `artifacts/browser/website-loading/desktop-download.png`
- `artifacts/browser/website-loading/landscape-download.png`
- `artifacts/browser/website-loading/portrait-download.png`
- `artifacts/browser/website-loading/portrait-stalled.png`
- `artifacts/browser/website-loading/landscape-error.png`
- `artifacts/browser/website-loading/reduced-motion-download.png`
- `artifacts/browser/website-loading/results.json`
- `artifacts/browser/play-host/results.json`

Manually inspected the desktop download, portrait download and stalled screen, and landscape stalled/error screenshots. Artwork remains visible around the loading panel, the menu stays clear, text wraps and controls stay inside the viewport. Parent review also inspected the desktop, landscape error and portrait download captures before integration.

## Antislop delivery gate

- **Hard Gate PASS:** User explicitly authorized themed loading art and parallel implementation; no invented statistics, testimonials, links or controls. Genuine download observations drive the displayed numbers. Browser fixtures found no overflow or clipped text at four layouts. Native HTML progress and status text preserve accessibility; recovery buttons and the existing keyboard menu are functional. Text contrast on the opaque panel measures 11.48:1 for primary text, 9.37:1 for secondary text, 9.33:1 for warning/percentage and 7.67:1 for the recovery button.
- **Purpose-Gate PASS:** The original tropical stilt harbor establishes the requested maritime setting. The dark jade panel gives dependable text contrast over detailed art; its brass edge ties it to the game theme. The single bottom shade preserves the scene while grounding the status panel. Existing Lora branding and Nunito Sans body text preserve identity and readability. Motion separates foreground foliage from the harbor and stops for touch or reduced motion. No decorative metrics or generic feature cards were added.
- **Liveliness PASS:** Design read: cozy Nusantara maritime village, jade/teal water, terracotta roofs and warm brass sunrise. ENERGY 2, RHYTHM 2, MOTION 1. The harbor is the visual focal point; the loading panel is the information focal point. Open water provides structural space rather than filler. The brass progress and frame provide one deliberate accent. Lanterns, tiled stilt homes and the existing sail/fish brand keep the scene specific to Jalasmara.
- **Craftsmanship PASS:** Production build, typecheck, four bridge tests, 24 loading checks and seven existing host checks passed. Real recovery actions, unknown size, download, preparing, stalled, error and ready states are implemented. The scoped CSS preserves the rest of the website. No claims about live game performance or physical hardware are inferred from fixtures.

## Separate website backlog

Account, landing and admin page redesign are outside this loading request and were not changed. The website lane can own those independently if prioritized. This change does not modify HUD, map, ocean, game scripts, API, authentication, player data or deployment configuration.
