# Branch retirement and remaining candidates — 10 November 2026

After the accepted integration had reached `main`, 38 historical work branches were retired from the local checkout and all three Git remotes. Each retired branch had **zero unique patch IDs** relative to `main` (`git cherry main <branch>`), and its remote tip matched the local tip before deletion. This is patch-equivalence, not a claim that every historical commit is an ancestor of `main`. No experimental branch with a unique patch was merged merely to reduce the branch count.

Before removal, any ignored `artifacts/` or `.runtime/` evidence directory in those worktrees was moved, not deleted, under `.runtime/retired-worktrees/<branch>/` in the main checkout. Only generated caches/builds and verified `node_modules` symlinks were removed with the retired worktrees. The full local retirement manifest is `.runtime/branch-retirement-2026-11-10.json` (ignored by Git). Original screenshots/reviews already curated under `docs/visual/` and `docs/reviews/` remain tracked.

Local `work/*` branches: 58 → 20; local worktrees: 59 → 21. Gitea/GitLab branch heads: 59 → 21; GitHub: 60 → 22 because its historical `ci-reports` branch remains. Free space on the operator disk rose from 13,921,232 to 19,156,984 KiB at the end of retirement (+5,235,752 KiB, about 4.99 GiB). Preserved ignored evidence occupies about 1.3 GiB in its new location. Subsequent disk use by other work is outside that measurement. No VPS directory, volume, source candidate, database, or credential was removed.

## Retired branch tips

| Branch | Tip | Preserved ignored evidence |
| --- | --- | --- |
| `work/06-browser` | `c344aae4b64f` | artifacts |
| `work/06-canopy-route-qa` | `ae7b4f8e84c3` | none |
| `work/06-fish-gen-reference` | `784394bd6f1a` | .runtime |
| `work/06-left-browser` | `6e8a52a35688` | none |
| `work/06-loader-fault-qa` | `88b8f91e340a` | artifacts |
| `work/06-ocean-retest` | `5b4829816043` | none |
| `work/06-release-qa` | `03599bfe675a` | artifacts |
| `work/06-village-ground` | `b4e7582282b3` | none |
| `work/06-visual-evidence` | `19e755d59874` | none |
| `work/06a-hutan` | `3b893f59eedd` | artifacts, .runtime |
| `work/06a-laut` | `5d11c6332716` | artifacts, .runtime |
| `work/06b-balai-test` | `e258d079d09a` | .runtime |
| `work/06b-balai-ui` | `bf5a0a52f2ed` | none |
| `work/06b-body-next` | `f5792d505af5` | artifacts, .runtime |
| `work/06b-body-pilot` | `930dfb31e9cb` | artifacts, .runtime |
| `work/06b-browser-route` | `a229466a8bc4` | none |
| `work/06b-buildings-gates` | `b182103776f1` | artifacts, .runtime |
| `work/06b-ci-evidence` | `28e3160ccefd` | .runtime |
| `work/06b-house-integration` | `979dd668341e` | artifacts, .runtime |
| `work/06b-integration` | `f319da94b035` | artifacts, .runtime |
| `work/06b-nala-gait-next` | `1d1dea99985d` | artifacts, .runtime |
| `work/06b-nala-restart-audit` | `611cd104dd54` | artifacts, .runtime |
| `work/06b-rutinitas` | `6c6d0ad3c77b` | none |
| `work/06b-shelter` | `7e3f3b654992` | artifacts, .runtime |
| `work/06b-tool-contact-next` | `84036654c9bc` | .runtime |
| `work/06b-view-projection` | `4088a1973c38` | artifacts, .runtime |
| `work/06d-website` | `ca78445daa4e` | none |
| `work/06f-gateway-frame` | `db7621a6c9b6` | none |
| `work/06p-payload-audit` | `740cdffa4e00` | artifacts, .runtime |
| `work/06p-performa` | `bd7600509181` | artifacts, .runtime |
| `work/gitea-ci` | `c540ad50bbd0` | .runtime |
| `work/laut-dinamis` | `cc63a9301c05` | artifacts, .runtime |
| `work/map-desa-hutan` | `4ee73dec0e0e` | artifacts, .runtime |
| `work/overnight-hud-perf` | `e7990ce35f31` | artifacts, .runtime |
| `work/overnight-integration` | `59e916bff3be` | artifacts, .runtime |
| `work/overnight-pen-final` | `19a9bee2a0d1` | artifacts, .runtime |
| `work/website-loading` | `2ccb0371d01a` | artifacts |
| `work/overnight-ground-consumers` | `e7fddf8379f5` | artifacts, .runtime |

## Retained branches

The branches below still have unique patches and need integration review. Their histories and worktrees were left intact. Several have old or superseded work; retention is not acceptance. Review each against the current staging source and its report before any cherry-pick, merge, or deletion.

| Branch | Unique patch IDs | Reason to retain |
| --- | ---: | --- |
| `work/06-camera-pilot` | 1 | Unique candidate or review commit; acceptance unresolved. |
| `work/06-gateway-route-qa` | 1 | Unique candidate or review commit; acceptance unresolved. |
| `work/06b-dialogue-compact` | 1 | Unique candidate or review commit; acceptance unresolved. |
| `work/06b-foot-boundary-next` | 3 | Unique candidate or review commit; acceptance unresolved. |
| `work/06b-house-alignment` | 2 | Unique candidate or review commit; acceptance unresolved. |
| `work/06b-hud-portrait-next` | 1 | Unique candidate or review commit; acceptance unresolved. |
| `work/06b-natural-edges` | 1 | Unique candidate or review commit; acceptance unresolved. |
| `work/06b-npc-alpha` | 1 | Unique candidate or review commit; acceptance unresolved. |
| `work/06e-nala-restart-pilot` | 1 | Unique candidate or review commit; acceptance unresolved. |
| `work/06g-stair-grounding` | 2 | Unique candidate or review commit; acceptance unresolved. |
| `work/06p-loader-stream-error` | 1 | Unique candidate or review commit; acceptance unresolved. |
| `work/gemini-character-source-audit` | 1 | Unique candidate or review commit; acceptance unresolved. |
| `work/gemini-day01` | 12 | Unique candidate or review commit; acceptance unresolved. |
| `work/gemini-day01-art` | 2 | Unique candidate or review commit; acceptance unresolved. |
| `work/gemini-day01-audit` | 2 | Unique candidate or review commit; acceptance unresolved. |
| `work/gemini-day01-gait` | 118 | Unique candidate or review commit; acceptance unresolved. |
| `work/overnight-character` | 115 | Unique candidate or review commit; acceptance unresolved. |
| `work/overnight-contact-audio` | 1 | Unique candidate or review commit; acceptance unresolved. |
| `work/overnight-resident-art` | 10 | Unique candidate or review commit; acceptance unresolved. |
| `work/overnight-village` | 1 | Unique candidate or review commit; acceptance unresolved. |

## Next integration gate

1. Review the remaining unique commits by changed file, current-tree effect, and acceptance report. Cherry-pick only work that improves the current source and passes focused plus combined tests. Some gait and audit candidates are explicitly on hold in the active handoff.
2. The two untracked `.uid` files on the final patch-equivalent branch were byte-identical to tracked `main` files, so that branch was retired without losing unique content.
3. The documentation commit `d5bf3d935ad015a4fcb35b0c81203b6e05304c18` was read back at the same `main` SHA on Gitea, GitHub, and GitLab. Do not equate branch cleanup with a new staging deployment.

Tools: Git worktree/branch/cherry/ls-remote, Python standard library, and filesystem moves. No third-party merge service or generated asset was used.
