# Local cache cleanup, 18 November 2026

The owner requested storage recovery while the moodboard work continued. Before cleanup, the Mac data volume reported **5.5 GiB available** (`df -h`, 228 GiB volume, 98% capacity). The local checkout was `main` at `a5c5fed`; three visual worktrees were active and their source, Godot import caches, and evidence were left alone. A process check showed only the Gito native test using Godot. No local web build or browser test was running.

The following obsolete generated directories were removed by an exact-path Python cleanup after confirming they were directories rather than symlinks:

| Removed cache/output | Allocated size before removal |
| --- | ---: |
| Playwright Firefox `1555` and WebKit `2370` | 607,680 KiB |
| `.runtime/cold-export-test` and `.runtime/cold-import` | 117,180 KiB |
| `.runtime/hero-build` | 83,048 KiB |
| `apps/web/dist` (to be rebuilt from the final source) | 133,064 KiB |

The installed Playwright 1.65.0 registry uses Chromium/headless shell `1254`, Firefox `1572`, and WebKit `2388`; those versions were retained. The following superseded build archives were removed with exact-file `unlink`, while their JSON manifests, image proofs, logs, and source review reports remained: `image.tar.gz` and `context.tar` under `.runtime/oci-release-44249439199`, duplicate `context.tar` under `.runtime/verified-release-44249439199`, and four `build.zip`/`godot_web.zip` files from `.runtime/retired-worktrees/work__06b-ci-evidence/.runtime/ci-{3044287626,3044205000}`. Their combined file bytes were **817,286,825**. The newer complete local OCI archive for run `44285677254` was retained. The removed OCI run represented source `7c9936a`; its manifest and proof JSON remain locally and its verified image remains tagged on the VPS as `jalasmara:rollback-20261118-7c9936a`.

The targeted directories plus archives accounted for approximately **1,780,842,153 bytes** by `du`/file sizes; APFS available space measured **8.2 GiB** afterward (`df -h`, 96% capacity). This is a filesystem observation, not a sum of Docker shared layers. Source files, `.git`, active worktrees, test-service data, `.env`, backups, curated `docs/visual` evidence, and all currently installed tools were preserved.

Read-only VPS inspection found `/opt/jalasmara` on a 49 GiB volume with **42 GiB available** (11% used), zero Docker build cache, and a healthy active `jalasmara:current` image ID `sha256:aa66e069103addfea38a6d8672c1a4434fe6f4b59e13553a5a6e60c95a771612`. The active source tag is `ci-e6c9898bdec1e57feadd1a1f5eeb2667ddeddef6`; the rollback tag retains image ID `sha256:9fa52d0140da2d0e9fb4eea82858239aaa7fb57d9727e8e95c27480d3c678b36`. The public `/api/health` response was `{"status":"ok"}`. Docker images, volumes, containers, and VPS files were **not** pruned because the host has ample space and the rollback must remain available. No release or staging activation occurred.

## Additional npm cache pass

A later check while three visual worktrees were active showed 6.9 GiB available. The global npm `_npx` cache held 1.6 GiB of generated one-off package installs. With no npm/npx process running, an exact-path cleanup removed **38 cache directories last modified before 1 November 2026**, containing **1,741,361,987 file bytes**; eight November cache directories were retained. `~/.npm/_npx` now occupies 44 MiB. APFS reported 7.6 GiB available immediately afterward. This global cache can be recreated by npm; no project `node_modules`, active build, source, or test evidence was deleted. APFS free-space changes are lower than summed logical file sizes because other processes continue writing and the filesystem may reclaim snapshots asynchronously.

After the accepted visual packages were merged or their diagnostics recorded, their isolated worktrees and branches were removed through Git. A subsequent `df -h /System/Volumes/Data` showed **12 GiB available** (95% capacity in the reported APFS accounting). The required final Godot Web/Vite/API build then left **11 GiB available**. Only the main worktree remains; no active package source was deleted. These are filesystem observations, not guarantees against later build or snapshot growth.

A final size scan found `.runtime/retired-worktrees` at about 1.5 GiB, but its largest entries include older gait/body proof artifacts. They were retained because the evidence is not interchangeable with a disposable import or package cache. Current Playwright browser revisions, Google/Antigravity application caches, installed Godot and tool runtimes, and the complete newer OCI release archive were likewise retained pending specific replacement or usage checks.

## Second audit after development build

The owner asked for a second scan to avoid filling the Mac during further development. At the start of this scan, `df -h /System/Volumes/Data` reported **14 GiB available** (APFS had reclaimed space since the first report). A targeted scan showed the largest remaining project-local directory, `.runtime/retired-worktrees` (about 1.5 GiB), contains source candidates and gait/body visual proof, so it remains. Current Playwright browsers (about 1.2 GiB), installed Godot, project `node_modules`, the latest `apps/web/dist`, the newer complete OCI archive and release rollback remain available. Google/Antigravity caches belong to active applications and were left alone.

With no Godot, npm, npx, Playwright or test process running, four proven disposable paths were removed by exact-path checks: `~/.cache/prisma` (181,102,216 file bytes; a 2025 cache with no Prisma dependency in this project), `.runtime/python312.tar.gz` (the installed `.runtime/python312/bin/python3.12` reports 3.12.16), `~/.cache/retroverse-test-tools/ffdec-26.4.0.zip` (the extracted `ffdec.jar` remains), and `~/Library/Caches/@getpaseodesktop-updater/update.zip`. The latter's SHA-256 matched the preserved `pending/Paseo-0.16.1-arm64.zip`, and the running installed Paseo app reports version 0.16.1. Combined removed file bytes: **410,024,062**. The pending updater archive and metadata were retained. Afterward the Mac reported **15 GiB available**; no repo source, test evidence, current build, live service data or backup was removed. This second pass did not change VPS state.

During future packages, inspect `.runtime`, `~/.npm/_npx`, and `~/Library/Caches/ms-playwright` by exact revision before deleting. Keep the active build, one verified rollback, source candidates not yet reviewed, and curated proof; do not recursively prune `.runtime/retired-worktrees` or Docker volumes. Free space should be checked before Godot Web export and again after stale worktrees are merged and removed.
