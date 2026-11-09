# Local superseded-cache inventory after candidate 5f5

Status: read-only inventory; **nothing deleted**. Prepared for root to execute a bounded cleanup after release. Observation window: 2026-11-09 13:45–13:47 UTC.

## Scope and evidence

Enumerated the 40 registered Git worktrees and only these generated-cache paths in each: `client-godot/.godot`, `apps/web/public/game`, `apps/web/dist`, `apps/api/dist`, `packages/shared/dist`. No dependency, source, artifact, `.env`, database or reference-tool contents were scanned for deletion. Symlinks were not followed. Sizes below sum filesystem-reported allocated blocks (`st_blocks × 512`) for regular files, deduplicating inodes within each target; `du -sk` corroborated the one cleanup candidate.

Process cwd inspection via `lsof -a -d cwd -Fpcn` found the main workspace and current `Jalasmara-06-buildings-gates` in use. Main API/Vite/Redis processes and combined-worktree Node processes were present. No process cwd referred to the old house-integration worktree. Root must repeat the cwd/open-handle check immediately before deletion because this inventory is a point-in-time observation.

## Single bounded cleanup candidate

| Exact path | Allocated bytes | Logical bytes | Files | Last file write UTC |
|---|---:|---:|---:|---|
| `/Users/ardianryan/Documents/Jalasmara-06-house-integration/client-godot/.godot` | 64,995,328 | 63,433,515 | 499 | 2026-11-09 12:21:31.603 |

`du -sk` reported 63,472 KiB, or 61.984375 MiB allocated. `git check-ignore client-godot/.godot` confirmed it is ignored; no tracked files were in this cache. Directory owner UID 501 matches the current user (`ardianryan:staff`). Worktree source HEAD `979dd668341e0621883abf66953203526baccd78`; status showed only the existing untracked `node_modules` symlink. `lsof +D <exact-cache-path> -Fpcn` returned exit 1 with zero open-handle records.

This cache predates the accepted current combined house/gate/terrain export and can be rebuilt by import if that historical worktree is reopened. Only this exact `.godot` directory is a candidate; the worktree, source, screenshots, reports and symlinked dependencies are not included. No recursive wildcard or whole-worktree deletion is proposed.

## Explicitly preserved

| Worktree | Generated paths preserved | Allocated regular-file bytes |
|---|---|---:|
| `Jalasmara` | `.godot`, public game export, web/API dist | 300,724,224 |
| `Jalasmara-06-buildings-gates` | `.godot`, public game export, web/API dist | 298,717,184 |

Actual PCK identities rechecked locally:

- Main export: `43df70a9c86d4feafd18daed16297a6c5b2cc02582daa1ee0b4d32605f56d19e`.
- Active combined export: `5f5baf243a3bf941cf34fab6c143bb9cf2bc8d65997ded6ed4e048b929353f96`.

All Nala/restart/audit working lanes remain protected, together with the historical integration worktree, source, artifacts, installed dependencies, credentials, database/Redis storage and reference clones. Other inspected superseded worktrees have no nonempty generated cache at the listed paths; their `apps/web/public/game` contains only tracked zero-byte `.gitkeep`. Removing those placeholders would reclaim nothing and alter source.

## Execution handoff

Root may remove the single exact candidate after release and a fresh ownership/process check. Record the actual deletion and before/after `df` separately; this inventory does not claim reclaimed space. At observation, `df -k /Users/ardianryan/Documents` reported 10,415,444 KiB available. Filesystem allocation is the measured cache size, not a promise of identical newly available volume space. No browser/Godot process was launched by this inventory.
