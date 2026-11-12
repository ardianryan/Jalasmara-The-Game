# Web audio silence after playback-mode release, 12 November 2026

The owner listened on Windows and Samsung S23 after source `7792cff` was released and reports no sound. That invalidates the earlier assumption that switching from forced Stream to the platform default was sufficient. Movement and the public game route still work. The active staging image/PCK at diagnosis were `d267a8ce3aa3`/`91acb311d896`.

## Reproduction and cause

An authenticated disposable-account browser probe on the exact active staging PCK showed `muted=false`, `unlocked=false`, `playing=false` before a canvas click. After the click, it showed `unlocked=true`, `muted=false`, track `coastal_day`, `playing=true`, and two coastal SFX calls. The host-only public smoke completed 6/6, with no browser errors and zero remaining player/receipt/shift/Redis keys. Evidence is in ignored `artifacts/browser/staging-plan06-d910ae40-b439-4d72-9751-35b68d0a4b43/results.json` and `.runtime/audio-web-probe-20261112.log`. The temporary probe source was removed. These flags establish the Godot control path, not audible output from the browser.

Godot's [Web sample-bus bug #119026](https://github.com/godotengine/godot/issues/119026) describes the same `playing=true` but silent symptom when runtime `AudioServer.add_bus()` appends at `-1`: JavaScript buses reorder, disconnecting Master from the Web Audio destination. The issue confirms 4.7.2 is affected and records `AudioServer.bus_count = i + 1` as a workaround; the fix is targeted for Godot 4.8. The exported 4.7.2 `index.js` in this project still contains the offending `Bus.addAt(index)` branch. `AudioManager._ensure_bus()` called `AudioServer.add_bus()` three times at startup. This is a stronger explanation for complete silence than the previously identified Stream crackling risk.

## Correction

`AudioManager._ensure_bus()` now grows `AudioServer.bus_count` by one before naming each bus, so the Web sample path appends buses in order without calling the broken `addAt(-1)` route. Music, environment and UI buses retain their existing names, sends, volumes and effects. `scripts/tests/audio-context.gd` checks that the four buses are ordered Master → Environment → Music → UI and that the sends reach Master. No MP3, player state or world behavior changed.

## Verification and remaining gate

- Focused Godot 4.7.2 audio-context test: PASS with the new bus order/send assertions; `.runtime/audio-bus-focused-20261112.log`.
- `npm run typecheck`: PASS; `.runtime/audio-bus-typecheck-20261112.log`.
- Full `npm run check:world`: PASS, including the revised audio-context test; `.runtime/audio-bus-world-20261112.log` has no `SCRIPT ERROR` or `ERROR:`. The headless native driver emits expected warnings for explicitly sampled UI SFX because it does not support sample playback; these warnings do not establish Web audibility.
- `npm run build`: PASS, with no `SCRIPT ERROR` or `ERROR:` in `.runtime/audio-bus-build-20261112.log`. Local Mac Web PCK SHA-256 `9aded7317e19dab6872272568a6beaeeea39de3b553d5cb9d50390dee0fe3378`, 69,775,548 bytes. CI's Linux export must be treated as a separate bundle even if the size matches.
- Local `npm test` was attempted but the default MongoDB/Redis fixture endpoints were unavailable; the first DB-backed cases timed out and the run was stopped. `.runtime/audio-bus-api-test-20261112.log` retains this failure. The GitHub workflow supplies its own services and must run the complete API suite before release.
- GitHub CI, staging release and owner listening: pending at this checkpoint. An automated browser test cannot claim the speaker is audible. A post-fix browser probe should confirm the same track/unlock state, and the owner should listen again on Windows/S23.

Next: complete the world/build checks, publish a whole CI verified-delivery bundle with backup/rollback, run public smoke, then have the owner check title music, village music, UI click and mute/unmute. If silence persists despite correct bus routing, inspect the browser Web Audio graph or use a browser-managed BGM path before changing assets.
