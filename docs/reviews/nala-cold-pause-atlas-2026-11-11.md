# Nala dock visibility: cold-start pause and atlas alignment

Date: 11 November 2026. Owner report: Nala remains buried in the Bandar Hujung dock after page load and after **Reset posisi pemain**. The standing character in the owner's screenshots is Mang Ujang; the small visible shape near the stairs is Nala. Moving the saved position did not repair the rendering fault. This package does not alter owner data or the reset endpoint.

## Cause and change

`CharacterVisual.set_appearance()` initially installs a legacy 418 px clothing atlas. On the first land frame, `Player` calls `set_locomotion()` and `animate()`. If the browser host is unfocused or a menu/clock pause is active, locomotion correctly freezes the pose. Previously `animate()` returned at that point, before switching the sprite to its directional 8-way atlas. `LandActors3D` still received the directional pivot `(64, 104)` because the appearance supports that atlas. Applying that pivot to the legacy texture placed most of the body below the dock; only its upper part remained visible. A position reset changes the support coordinate but repeats the mismatched texture/pivot combination.

`client-godot/scripts/CharacterVisual.gd` now installs the appropriate directional texture, frame layout and pivot even while the pose is frozen. `set_locomotion()` continues to freeze step phase and facing motion, so a pause does not animate the character. The regression in `scripts/tests/player-locomotion.gd` covers all four appearances, daily/explorer/diving, and both cold clock and host pause: 24 cases on the first frame.

## Verification and limits

- Red/green proof: with the old early return restored temporarily, the new Godot assertion emitted `SCRIPT ERROR` (`.runtime/player-locomotion-cold-pause-red.log`); the repaired source passed (`.runtime/player-locomotion-cold-pause.log`). The intentionally failing source was restored immediately and is not committed.
- `npm run typecheck` passed. `npm test` passed **122/122** against disposable MongoDB/Redis fixture services on `staginglocaldocker`; those services and the SSH tunnel were removed. Two earlier attempts failed to connect because the local default fixture was unavailable and then the wrong test environment variable names were supplied; neither was an application-test failure. Final log: `.runtime/nala-cold-pause-npm-test-fixture.log`.
- `npm run check:world` passed, including `NALA COLD PAUSE PASS`, with no `SCRIPT ERROR` or `ERROR` in `.runtime/nala-cold-pause-world.log`.
- The old public staging PCK was reproduced in Chromium with `document.hasFocus()` forced false before first host load. [The captured first-frame result](../visual/staging-nala-unfocused-head-before-20261111.png) shows the same small head embedded in the dock near the stairs, while Mang Ujang stands in full. The disposable fixture completed with no console/API failures and was fully cleaned (players/receipts/shifts/keys all zero). Browser evidence: `artifacts/browser/staging-plan06-fc25cc40-496b-4e30-8e4e-ec5660a14ac7/results.json`; source was the active old PCK `b3ff1a4f165f6ec12bd133d1222400f6f9e358ca7a4bd853663f07b699ab77d3` (69,774,364 bytes). The screenshot is project-original test output, not a moodboard asset.
- Production export, Gitea CI, staging image activation and owner account recheck are pending at this checkpoint. Headless tests and the old-browser reproduction establish the mechanism; the corrected owner's actual browser/device still needs visual confirmation. Do not call the fix released until its PCK and image hashes are recorded below.

## Release record

Source commit: pending. PCK: pending. Gitea run: pending. Image: pending. Staging smoke: pending. Rollback: pending.

Tools actually used: Godot 4.7.2 local binary for headless regression and world checks, Node/npm for typecheck and API tests, Docker fixture containers on the SSH test host. No new asset, font, external renderer or third-party license is introduced.

Next: build and package the committed fix; activate only after CI, backup/restore, manifest verification and smoke; ask the owner to confirm in their existing session. The physical Samsung S23 and Windows performance/visual checks remain separate.
