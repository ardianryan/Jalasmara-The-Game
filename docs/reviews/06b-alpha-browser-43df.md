# Saras browser transparency follow-up

Read-only image and source review, 9 November 2026. No Godot, browser, import, export or runtime modification was started by this review lane.

The website continuation produced `shelter-Saras-before-conversation.png` and `shelter-Saras-conversation.png` in `Jalasmara-06-release-qa/artifacts/browser/plan06-layout-2a722949-3dfb-48d7-91dc-c4f8f6718f7b/`. Both were visually inspected at their original 667×375 size. Its final `results.json` identifies package SHA-256 `43df70a9c86d4feafd18daed16297a6c5b2cc02582daa1ee0b4d32605f56d19e`, 64,307,804 decoded bytes.

The pre-dialog image shows 21:58 and light rain. Nala is at `(1016.54284667969, 313.098114013672)` according to the actual run log; Saras's shelter destination is `(1020, 310)`. The dialogue image names Saras and displays her portrait and dialogue. These are actual current-browser scene and speaker observations.

No conspicuous gray rectangle like the historical porch capture is visible in this frame. However, Nala almost overlaps Saras and foreground palm foliage covers much of the body and its outer boundary. The screenshot therefore cannot establish that the entire portrait silhouette composites correctly. It is **not** all-NPC alpha acceptance, proof of the historical cause, or evidence that a transparency defect has been fixed. The Tedi pre-dialog image likewise has the player overlapping the target, limiting its silhouette evidence.

The historical `home-porch-night-667x375.png` in run `6174b6a2-be3c-47ab-a8ed-cb8e82e8a201` visibly contains a quad outside Saras's silhouette at 18:56, with additional gray regions elsewhere. The controlled native Saras test had no such quad, and all 7,762 measured transparent background samples across four portraits remained unchanged. Different positions, lighting and occlusion in the new browser frame prevent a direct pixel comparison. The discrepancy remains unresolved; there is still no evidence supporting a crop allocation, neutral-color deletion or alpha-mode workaround.

Image SHA-256 values:

- Before conversation: `da4dec9d0e68e1b225326a27bfe4f0f6876e0fe15ef0d1ac528ceeac482f87ae`.
- Conversation: `5a7f5eb2e5ca0161be3a74f39cbfc4a2db9aa78e896397adc5f8eac6c96cd720`.

The completed results artifact was read directly: ten checks, no console errors or API failures, all recorded operation statuses 200, and `ownTemporaryPlayerRemoved=true`. It records all seven residents reaching shelter stations, five actual conversations (Tedi, Ujang, Lurah, Saras, Ratih), the shared chief service, and the permit action awarding only the defined starter seeds. Darmi/Sari were explicitly carried from predecessor package `592dc75b…` run `291db231-c58a-41a0-ad4c-0be759386cec`; they were not rerun on `43df`. This is a cross-package continuation, not seven freshly tested conversations on one package. Navigation records 787 matrix pulses and zero legacy pulses. The final calendar remains day 2 at minute 1402.8133 with rain active. These behavior checks do not change the image-review limitation above.

## Balai acceptance review

Current Main resident lookup and interaction routing, HomesteadUI's Balai action, and the merged 19-case actual-component regression were read without modification. No new concrete production defect was found in this scope. The busy guard is inside the Talk callback. Both actual resident-selected and board-selected paths enter the same page; the permit action remains reachable alongside the conversation.

The regression deliberately does not activate the server permit mutation or exercise NPC commute. Positive selection cases exercise actual `_find_nearby` → `_interact` → UI → shared presenter. Negative proximity/dive scenarios exercise the actual lookup and service page directly. Those limits must remain distinct from the website continuation's route and server-mutation evidence.
