# Portrait alpha follow-up on browser package 592

Read-only CPU review, 9 November 2026. The website lane owns the browser/GPU. No Godot, browser, source patch or export was started for this follow-up.

The package is PCK `592dc75ba391302aff22fce0f1c3c31d2d894ed46df52e6eb1f90c4917545b2b`, 64,307,052 bytes, runtime source `fc0d563` according to the QA lane's report. `git diff f319da9 fc0d563` confirms no changes to `LandActors3D.gd`, `npc-atlas.png` or `village-residents-v1.png`. The native investigation in [the alpha review](06b-npc-portrait-alpha.md) is therefore relevant source evidence, but does not substitute for the browser composition.

The reviewed directory is `Jalasmara-06-release-qa/artifacts/browser/plan06-layout-291db231-c58a-41a0-ad4c-0be759386cec/`.

- `left-seven-shelters-player-clears-station-approaches.png`: actual night/rain scene; Nala is visible on the path. This is an approach frame, not the missing non-rig portrait comparison.
- `shelter-Bu-Darmi-before-conversation.png`: visually inspected at native screenshot size, with the corresponding interaction label visible. Roof, palm and nearby actors overlap in the scene.
- `shelter-Yu-Sari-before-conversation.png`: visually inspected at native screenshot size, likewise an actual pre-dialog scene. Neither this nor the Darmi frame exercises Saras's original non-rig portrait path; these two citizens use the body rig.

At this review checkpoint, **no `shelter-Saras-before-conversation.png` exists**. The results JSON records four checks: a valid spawn, all seven residents reaching shelter stations, and the Darmi/Sari conversation-resume cases. It records no console/API failures and confirms fixture cleanup, but it does not contain all seven completed conversations. Do not promote a partial run to complete browser acceptance merely because the failure arrays are empty.

The historical `home-porch-night-667x375.png` from run `6174b6a2-be3c-47ab-a8ed-cb8e82e8a201` visibly has a rectangle outside Saras's silhouette, with additional gray regions near Nala and a bench/palm. Current native source produces zero changed background samples at all 7,762 measured transparent points across four non-rig portraits, and the controlled actual night-world Saras image has no rectangle. The new two rig captures do **not** resolve that discrepancy.

Next: inspect the current package's pre-dialog Saras frame once the QA continuation produces it. Identify the visible actor and compare the area outside her silhouette with the historical rectangle. If the rectangle remains, isolate actual Main CanvasItem, 3D sprite and shadow contributions in the browser before adding any texture copy or color removal. Preserve opaque neutral clothing pixels. If it is absent, report the specific package and scene as no-reproduction; that still does not prove the historical mechanism or every browser/device path is fixed.

Separately, the isolated layout 10 house branch has a committed native command/proof sequence and a prepared 28-frame old-layout/new-layout comparison, `3ee6bd7`. Those commands have not run and the layout is excluded from the current release. See `Jalasmara-06-house-alignment/docs/reviews/06b-house-next-native.md`.
