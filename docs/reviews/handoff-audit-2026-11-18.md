# Handoff and repository audit — 18 November 2026

Scope: read-only cross-check of the active handoff, PRD, development status, Phase 06 plan, Git graph, local worktrees, recent package reports and release procedure. This is a status audit, not a source-level security review or a new visual acceptance. No source, game asset, remote branch or staging service was changed by the audit.

## Verified state

| Area | Observation | Limit |
| --- | --- | --- |
| Local source | `main` at `4f06e0e`; one worktree, no active package branch; `git diff --check` passed before documentation edits. | The checkout has untracked Godot `.import`/`.uid` files and unrelated untracked `.agents/`, documents and image. They were left untouched and are not part of this SHA. |
| Mirrors | Read-only `git ls-remote` returned `76160a7f51db6d96a67f7b037d02f59e3fb186b2` for `main` on GitHub, Gitea and GitLab. Local `main` is 27 commits ahead. | No push was made. The successful CI run for `76160a7` does not cover the 27 later commits. |
| Staging | The latest release record documents source `e6c9898bdec1e57feadd1a1f5eeb2667ddeddef6`, image `sha256:aa66e069103addfea38a6d8672c1a4434fe6f4b59e13553a5a6e60c95a771612`, and CI PCK `823cf8e76e9472956983beb525c1c36683a5987fb8e0344e7f25eaab95e70d48`. | This audit did not perform a live VPS hash/health check or public browser smoke. See [release proof](moodboard-cutscene-release-2026-11-18.md). |
| Accepted local work | Saras near-plane reveal, Wira/Kedai and prologue props, epilogue/victory/garden actions, Gito and Bagas rear source pixels are integrated; rejected hub and reef experiments entered as diagnostics only. | Native package evidence is in the linked handoff reports. It is not a final-source browser or device pass. |

The first paragraph of `development-status.md` still identified `7c9936a` as the current staging build despite the later `e6c9898` release. It was corrected. The handoff has multiple dated historical headings; only its new top checkpoint and actual Git state should be used for current branch/release decisions.

I inspected the original-size [hub A/B](../visual/hub-site-composition-20261118/hub-central-stairs-ab-667x375.webp) and [Reef 12 A/B](../visual/reef12-concave-diagnostic-20261118/deep_right-667x375.webp) directly. The hub candidate replaces the route join with a broad uniform stone area; the reef candidate retains a visible horizontal shelf and hard atlas join. These images support the recorded rejection of those trials, but are still captures rather than moving gameplay acceptance.

## Acceptance gaps and order

1. Finish same-source local checks and a source/PCK-pinned browser journey, including the new cutscene beats and real loading path. Prior native stills and headless fixtures do not prove browser cadence or audio.
2. Review the accepted local SHA for publication, then use `npm run push:all -- main` and require GitHub Actions and both artifacts from that **same SHA**. Follow `docs/operations-github.md` and keep mirror pipelines disabled.
3. Before any staging switch, verify the exact image/PCK manifest, perform backup and isolated restore, retain one rollback, then run public PCK verification and disposable-account smoke. No staging activation is claimed here.
4. Resolve full visual parity separately: the broad hub V/Y route, Reef 12 shelf and seam, remaining resident directional pixels, live character/light motion, and Windows/S23 physical frame/input review. Nala physical gait pilot stays OFF pending its own moving-contact gates. A full human playthrough remains open.

## Local verification from this audit

`npm run typecheck` passed on `4f06e0e`. A first bare `npm test` reached database-backed tests with no fixture MongoDB/Redis listening on its default ports and was stopped after repeated ten-second failures; this is a missing test-service prerequisite, not evidence of a code regression. The partial log is `/tmp/jalasmara-handoff-audit-test-20261118.log`.

A fresh isolated MongoDB replica set on port 27041 and Redis on port 6384 were started only for this audit. With `TEST_MONGO_URL` and `TEST_REDIS_URL` pointing to those instances, `npm test` passed **127/127** (`/tmp/jalasmara-handoff-audit-test-isolated-20261118.log`). `npm run check:world` passed, including ten swim species/722 frames (`/tmp/jalasmara-handoff-audit-world-20261118.log`). `npm run build` passed Godot Web export, Vite and API TypeScript (`/tmp/jalasmara-handoff-audit-build-20261118.log`). Neither final world nor build log has `SCRIPT ERROR` or `ERROR:`. The generated local PCK is 81,863,896 bytes, SHA-256 `b7b2442a56e4a10a51f319393ce5bc1e18369aa7fcff7dc643e3cbbabee327cc`; the generated manifest matches. This is a **local** export, not a GitHub CI artifact or staged PCK.

After testing, both fixture services were shut down and their dedicated data directories were removed (about 6.9 MiB Mongo plus 4 KiB Redis before removal); no owner, staging, existing database or volume was touched. Godot 4.7.2 Compatibility was found under `.runtime/godot`. `docker` is unavailable in this local shell. APFS reported 37 GiB available during and after the audit, up from the 15 GiB observation in the earlier cleanup report; no additional storage cleanup was performed. Tooling used: Git, Node/npm, Godot, MongoDB 8.0.34, Redis 8.10.1 and local shell utilities. No new asset, dependency or external tool was added.
