# GitHub Actions migration, 12 November 2026

The owner restored GitHub Actions capacity and chose GitHub Actions as the sole CI and report location. Gitea and GitLab are code mirrors without pipelines. This supersedes the Gitea CI decision in the historical runbook; it does not change the active staging image or player data.

## Source changes

- Moved the verification/build/delivery job to `.github/workflows/ci.yml`; retained isolated test services, source SHA record, dependency audits, CodeQL SARIF, Godot export and world checks. The job publishes `verification-reports` on both success and failure and a `verified-delivery` bundle only on success.
- Removed the Gitea workflows and the old GitLab-to-GitHub `ci-reports` relay and deploy-key known-hosts file. GitLab's workflow remains disabled. `scripts/push-remotes.mjs` now sends a frozen SHA to GitHub first and then both backups.
- Changed the isolated MongoDB bootstrap guard to GitHub Actions and updated the active operations, architecture and agent documentation. Historical reports remain historical.

## Verification and release status

The first GitHub [run 43177248796](https://github.com/ardianryan/Jalasmara-The-Game/actions/runs/43177248796) failed at source recording before tests: Git rejected the container checkout as dubious ownership. MongoDB itself started. The workflow now marks only `$GITHUB_WORKSPACE` as a safe Git directory before reading its SHA. `verification-reports` uploaded on that failed run; `verified-delivery` correctly did not. Focused local push-helper tests (5/5), TypeScript typecheck, shell syntax and `git diff --check` passed. Python YAML parsing was unavailable locally; Ruby parsed the workflow and job keys. Gitea repository Actions were set to `false`, GitHub repository Actions to `true`; the first commit `aa6e74a` reached all three remotes.

The corrected source `237de953d22a39d08c2d7cc9d1996182207e296a` passed [GitHub Actions run 43177417189](https://github.com/ardianryan/Jalasmara-The-Game/actions/runs/43177417189) in 6m9s. The API/host/tool/dependency checks, CodeQL, Godot 4.7.2 Web export and world checks, web/API build, and SHA-bound packaging all passed. `verification-reports` (71,662 bytes, 14-day retention) contains `source-commit.txt` with the exact SHA, JUnit, three dependency audits, CodeQL SARIF, audio synthesis, and individual Godot world logs/JSON. `verified-delivery` (92,796,395 bytes, 3-day retention) uploaded after the successful job. Reports were downloaded into a temporary directory, inspected, and removed locally; no candidate package was installed on staging.

`git ls-remote` confirmed all three `main` heads at `237de953d22a39d08c2d7cc9d1996182207e296a`. GitHub repository Actions reported `enabled: true`; Gitea reported `has_actions: false`; GitLab reported `builds_access_level: disabled` and `.gitlab-ci.yml` denies pipelines. The local `main` upstream now tracks `github/main`. This documentation commit will trigger one final GitHub run on its own SHA; check that result before treating the final `main` as green.

The workflow uses GitHub-hosted Ubuntu with a Node 22 Debian container, an isolated MongoDB 8.0 installation, and Redis 7.4. It retrieves the CodeQL bundle and Godot 4.7.2 from upstream releases; it adds no game asset. GitHub emitted an advisory that the pinned checkout v4 and artifact v4 actions target deprecated Node 20 and are being forced onto Node 24; the run still passed. Updating those actions to supported major versions can be done in a later maintenance change.

## Remaining work

After a successful GitHub Actions run, verify artifacts and backup remote SHAs. Keep physical Samsung S23/Windows performance and dialogue/quiz HUD acceptance as separate product gates; this CI migration does not satisfy them.
