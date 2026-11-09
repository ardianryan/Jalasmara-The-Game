# Balai page: reach the resident without losing the permit action

Branch `work/06b-balai-ui`, worktree `Jalasmara-06-balai-ui`, base `5683e52`. Scope is `HomesteadUI.gd` only plus this review. This source increment is not a tested export or deployment.

Ki Lurah and the permit board share `(940,310)`, so the existing interaction opens the Balai page. `_balai()` now asks the host's `service_resident("balai")` for an actual nearby resident. When that method exists and returns a nonempty `{name,text}` dictionary, the first button is **Bicara dengan Ki Lurah**. Its callback closes the page, then calls the host's existing `_talk` sequence with the returned resident name/text. It does not manufacture dialogue, bypass proximity checks or introduce another presenter.

All permit, eligibility, pending-story text and Back actions remain. A host without the method, or an empty result because the resident is absent, gets the previous Balai page. The existing `_button` helper supplies responsive dimensions, focus styling and deferred first-button focus; `open_for` also focuses the first action. Other permit and Back buttons remain in normal keyboard Tab order.

Validation so far: source inspection and `git diff --check` pass. No Godot/import/browser was started because the website lane owns the engine slot. The integrator owns `Main.service_resident`, the focused actual-UI regression, full parse/check, export and browser continuation. Required cases: nearby Lurah with permit eligible/ineligible/already granted, absent Lurah/unsupported host, first keyboard focus and Tab reachability, close-to-existing-presenter transition, unchanged permit API action and return/resume behavior. No new assets, dependency or license changes.
