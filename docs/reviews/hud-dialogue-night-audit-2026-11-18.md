# Night HUD and dialogue audit — 18 November 2026

Status: local candidate on `work/hud-dialogue-audit-20261118`, based on `cd6714ceac56b24ed03f211e38a281eb5c5b7227`. Not merged or released.

The 667×375 and 844×390 audit reproduced one obstruction: a temporary teal HUD notice remained visible after opening a dialogue or night Kedai modal. `GameHud.set_modal(true)` hid the identity, action buttons and minimap, but did not hide `_status_panel`; `message()` could show a fresh notice while the modal was open. The notice was especially prominent on a short landscape viewport. `GameHud.gd` now keeps the notice hidden during modal interaction and restores an unexpired notice on close. The pending message text and expiry remain intact.

| Actual-size view | Before | Candidate |
| --- | --- | --- |
| Ki Lurah dialogue, 667×375 | [notice leaking](../visual/hud-dialogue-night-audit-20261118/dialogue-before-667x375.png) | [notice hidden](../visual/hud-dialogue-night-audit-20261118/dialogue-after-667x375.png) |
| Ki Lurah dialogue, 844×390 | [notice leaking](../visual/hud-dialogue-night-audit-20261118/dialogue-before-844x390.png) | [notice hidden](../visual/hud-dialogue-night-audit-20261118/dialogue-after-844x390.png) |

The [667×375 gameplay HUD](../visual/hud-dialogue-night-audit-20261118/gameplay-667x375.png) shows the notice when no modal is open. The top controls, circular joystick, action button and minimap remain in their existing layout. The dialogue portrait, complete nameplate, wrapped body copy, scroll cue and button fit in both captured sizes. At 667×375 the dialogue tray uses 29.3% of viewport height, body text measures 16.7 physical pixels, the dialogue button is 48.6 pixels at its narrowest dimension, and the touch action target is 61.1 pixels. At 844×390 these values are 28.5%, 16.6, 48.4 and 56.3 pixels. The long dialogue intentionally scrolls, rather than reducing readable type.

Method and limit: `scripts/tests/hud-dialogue-night-audit.gd` overlays the real Godot HUD and DialoguePresenter on the tracked night-world screenshot `docs/visual/moodboard-daylight/land-night-667x375.png`. Baseline ran against main with `HUD_AUDIT_EXPECT_FIXED=0`, reproducing `statusHidden=false`; candidate ran in this worktree and asserted `statusHidden=true`. Both rendered natively with Godot 4.7.2 Compatibility on Apple M2. This is a composite UI layout test, **not** a live Kedai shift, browser WebGL, or Samsung S23 performance test. No source screenshot from the supplied moodboard was redistributed.

Focused checks: the fixture asserts in-bounds dialogue, 48px or larger controls, readable body text, hidden status during modal, and restoration of a new unexpired status after close. All three Godot 4.7.2 headless scripts passed: `scripts/tests/hud-dialogue-night-audit.gd`, `scripts/tests/hud-short-landscape.gd`, and `scripts/tests/dialogue-compact.gd`. Logs had no `SCRIPT ERROR` or `ERROR:`; the existing dialogue test printed a two-object leak warning at exit. The new fixture still needs an entry in the explicit `scripts/verify-living-world.mjs` CI runner when the package is integrated. No external tool, asset, shader, font or license was added; only project-owned Godot UI code and a test fixture changed.

Evidence SHA-256: 667 before `f1dd8ea4396b97e9ef30576f8dcef2c9f2dabf1facd9cb319742848ce6f77422`, 667 after `833e6d362f48f1aa637a5e9ecd4421f54420d9ebe069ff0d73dfd341bb12471f`, 844 before `4a8956a56c9b48e131e53d0d7d97878a3ec2da559150e2acbbce3bdc3feebdcb`, 844 after `5679e3a6142d57ce6f68e43160371fff765f0b07c3309250bb513b4703afce57`, gameplay `d444891ae33d30ebd9b4e5b9a5619c35b83944957753808891916762b3befaa8`.

Next: the integrator should inspect the A/B captures, run combined checks after other agents merge, then verify the same modal interaction in a live night shift at 667×375 and on physical mobile. The dialogue layout may need future art polish to match the moodboard exactly, but no clipping was demonstrated here, so it was not changed.
