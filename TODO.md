# Open work

This list is intentionally short and updated from [the active handoff](docs/agent-handoff.md). It is not a replacement for issue ownership, PRD acceptance, or test reports. Do not mark an item done based only on a source commit or a still image.

## Priority 1 — playable core

- [ ] Rebuild and verify Nala's physical gait with tracked fixtures, flat-ground and terrain cases, native moving evidence, and browser input. Keep the current pilot off until all gates pass.
  - [x] Advance land atlas from accepted 3D travel; align opt-in torso and separate gear to planted-foot phase; pass flat32 and terrain16 source fixtures. See [12 November checkpoint](docs/reviews/nala-natural-gait-2026-11-12.md).
  - [ ] Review unobstructed native motion in all directions and on stairs, then check real Windows/S23 browser input, visual contacts, frame pacing and audio before enabling the pilot.
- [ ] Review the latest staging build on actual Windows and Samsung S23 hardware with the user's help; record frame time, input, loading, fullscreen, and HUD readability. The user has already offered device access.
- [ ] Complete a human start-to-finish playthrough and record progression, save/reload, economy, and accessibility issues.

## Priority 2 — presentation

- [ ] Compare village, forest, sea, homes, gate, terrain edges, and lighting against the project's comfy pixel moodboard using current-build screenshots. Preserve real 3D terrain and the left-to-right three-quarter camera.
- [ ] Check house/roof/deck and gate/path alignment in world space and gameplay camera; resolve any remaining route/collider mismatch.
- [ ] Verify dynamic sea current, foam, supported side rocks, swimming gaps, parallax, and depth across daylight/weather states.
- [ ] Review night HUD, dialogue, icon scale, journal, analog joystick, fullscreen and loading on narrow/landscape viewports without blocking gameplay.

## Priority 3 — maintenance

- [ ] Continue CI, backup/restore, public smoke and rollback checks for each activated build.
- [ ] Review dependencies and commission an independent security audit before any security assurance claim.
- [ ] Keep roadmap, changelog, handoff, third-party notices, and curated screenshots current as accepted work changes.
