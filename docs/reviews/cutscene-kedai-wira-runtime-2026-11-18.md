# First Kedai: Wira tea-offer runtime integration

Status: local candidate, visually accepted at native size by the integrator on 18 November 2026. This is not evidence of a merged build or staging release.

The original `first_kedai:1` frame placed Mbah Wira as a roughly 47–55 px stage actor, too small to carry his tea-offer action beside Pak Ranto's portrait. The runtime now draws the project-authored 192×192 tea-offer pose once in the foreground. Its sleeve, glove, and cup are connected in the source pixels. A short eased advance moves the pose toward the customer; the counter's original fascia is repainted over Wira's lower body, aligned to the same backdrop transform, so his feet do not float in front of the counter. Existing dialogue, trigger, tea prop, and story state are unchanged.

The source pose is [`mbah-wira-tea-offer.png`](../../client-godot/resources/art/cinematics-v2/close-pose/mbah-wira-tea-offer.png), SHA-256 `456504435508f83e1d5a6cd43932255c466cb8e67830fa6d35b57eba726d3fbd`. It was authored from the project's NPC atlas using [`author_wira_tea.py`](../../tools/cutscene-pixel/author_wira_tea.py); source, pixel method, and asset rights are recorded in [`docs/assets/wira-kedai-pixel.md`](../assets/wira-kedai-pixel.md). This runtime package creates no new third-party asset or dependency. Godot 4.7.2 Compatibility rendered the frames; Pillow converted the curated PNG captures to WebP for repository documentation.

Native original-size evidence at entry, offer, and settled timing:

| Viewport | Entry | Offer | Settled |
| --- | --- | --- | --- |
| 667×375 | [frame](../visual/cutscene-kedai-wira-runtime-20261118/kedai-01-entry-667x375.webp) | [frame](../visual/cutscene-kedai-wira-runtime-20261118/kedai-01-offer-667x375.webp) | [frame](../visual/cutscene-kedai-wira-runtime-20261118/kedai-01-settled-667x375.webp) |
| 844×390 | [frame](../visual/cutscene-kedai-wira-runtime-20261118/kedai-01-entry-844x390.webp) | [frame](../visual/cutscene-kedai-wira-runtime-20261118/kedai-01-offer-844x390.webp) | [frame](../visual/cutscene-kedai-wira-runtime-20261118/kedai-01-settled-844x390.webp) |

Verification: the focused `scripts/tests/cutscene-kedai-wira.gd` Godot fixture passed six viewport/time combinations and reduced-motion state. A second editor import completed with no `ERROR:` or `SCRIPT ERROR` (`/tmp/jalasmara-kedai-wira-import-clean.log`); native fixture passed with no such errors (`/tmp/jalasmara-kedai-wira-native.log`). `git diff --check` passed. The initial editor import reported transient missing font import data; the clean second import resolved it. This fixture proves framing and script behavior, not a full game route, browser frame rate, mobile performance, or story completion. Root integrator still needs to cherry-pick, run combined checks, and decide staging release.

Remaining Phase 1 visual gaps are tracked in [`cutscene-small-actor-reassessment-2026-11-18.md`](cutscene-small-actor-reassessment-2026-11-18.md); this package addresses only Wira in `first_kedai:1` and does not claim full moodboard parity.
