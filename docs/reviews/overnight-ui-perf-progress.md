# Overnight UI, device capture and environment review

Scope requested: compact night/book/quiz/dialog UI across viewports, usable opt-in physical-device capture, then bounded forest/ocean animation review. Worktree `Jalasmara-overnight-hud-perf`, branch `work/overnight-hud-perf`, base `d070a7b`. This progress report is partial; production deployment and full overnight acceptance are not claimed.

## Device capture and host-menu source candidate

The browser Menu uses the existing Bahari pixel button texture and a 64×48 CSS target instead of 88×48. The host sends its measured actual rectangle, and native land HUD reserves an eight-physical-pixel gap rather than assuming a fixed unrelated center control. Older viewport messages without coordinates still get a centered rectangle from their declared width/height. Portrait HUD keeps its existing top reservation.

The Menu includes explicit 30-second or five-minute performance recording. Starting closes the host menu so the player can continue moving; opening it again allows early stop and JSON download. No report is uploaded. A small nonanimated corner marker indicates active/ready capture without adding a gameplay panel. Completion presents the local download action in Menu.

The report contains browser-reported user agent/platform/core count/optional device memory, actual WebGL renderer/vendor where the browser permits it, viewport, optional JS-heap observations, visible unpaused iframe RAF interval distributions/hitches, once-per-second Godot monitors and per-second samples. Missing values remain null/empty; device/hardware names are not fabricated. Menu/hidden samples are explicitly excluded from active distributions. Long sessions cap retained intervals at 60,000 and record discarded counts.

The opt-in bridge samples only the small performance dictionary once per second. It does not enable the full debug snapshot path that contains game/account state; stopping restores independent QA diagnostics. The download allowlists numeric monitor/profile fields, excludes account/email/cookie/token/inventory/world coordinates/API responses/page URL, and remains entirely client-side. RAF measures browser scheduling, JS heap is not total process/WASM/VRAM, and GPU duration is not measured.

Actual CPU checks: five new meaningful capture tests passed (pause/resume boundaries, visible hitches, bounded long capture, private-field exclusion, missing metrics/percentiles). API/web TypeScript checking and the production Vite web build passed. The reused pixel button adds an existing 9.22 kB image to the web bundle, with no new dependency. Prettier and `git diff --check` passed. No Godot/browser was run for these changes at this checkpoint.

Prepared focused fixture: `scripts/tests/performance-capture.gd` verifies opt-in monitors without full snapshots, stop preserving QA state, and real HUD/Menu clearance at 667×375, 844×390, 390×844 and 1440×900. Existing `hud-oxygen.gd` reads the host rectangle contract rather than the obsolete 88-pixel assumption. Integrator owns runner registration; native/headless/browser remain pending slot grant.

## Remaining source and actual checks

1. Run import/focused HUD/analog/device-capture checks, inspect actual Menu and report/download in browser after a new export, and use the recorder on real Windows/S23 only when the user supplies the resulting file. No physical-device result is claimed.
2. Compact the actual night-service reading tray while preserving recipe/quiz/server behavior and accessible notes; inspect all FieldBook tabs/detail, long dialogue and quiz on narrow/portrait/desktop viewports. Existing tests are a baseline, not proof every branch is polished.
3. Add authoritative multi-crop/fish-pen/pantry UI through the village lane's locked shared/API contracts. HomesteadUI and Main UI/action hooks are owned here; shared world/API and LandWorld3D remain village ownership.
4. Measure current renderer profiles before changing quality behavior. Existing touch-auto low shadow policy remains. Forest/ocean current/foam/canopy/parallax need animated native/browser review; good base geometry is not being rebuilt speculatively. CreatureAnimator/FishGen adapter remains root ownership.

Tool/skill use: local Git/worktree, Node/TypeScript/Vite, existing Playwright availability, source review, antislop/UI/human/mobile rules with the user's already selected during-work mode, and EYD V for Indonesian UI copy. Existing project art only; split licensing and notices unchanged. No image generation, new UI library, proxy or loading-transport product change, account mutation, push or deployment.
