# GitHub Actions: current CI and delivery source

**Decision, 12 November 2026.** GitHub `ardianryan/Jalasmara-The-Game` is the source used for CI. GitHub Actions alone runs verification and prepares a delivery candidate. Gitea and GitLab receive the same Git commit as code backups; their project pipelines stay disabled. The earlier [Gitea runbook](operations-gitea.md) and [Gitea CI addendum](plans/08c-gitea-ci-addendum.md) are historical.

## Recording a commit

From a reviewed local branch, run `npm run push:all -- <branch>`. The helper freezes one commit SHA and sends it to GitHub first, then Gitea, then GitLab. It never force-pushes. A failed GitHub push stops backup publication; a failed backup push leaves a visible error and must be retried. GitLab receives `ci.skip`, and its `.gitlab-ci.yml` forbids every pipeline. Gitea repository Actions must remain disabled because Gitea can discover workflows in `.github/workflows` when `.gitea/workflows` contains none.

Check `git ls-remote github refs/heads/<branch>`, `git ls-remote gitea refs/heads/<branch>`, and `git ls-remote gitlab refs/heads/<branch>`; all three must report the frozen SHA. A mirror push is a backup, not evidence that the game passed CI or is active on staging.

## Verification and reports

The active workflow is [`.github/workflows/ci.yml`](../.github/workflows/ci.yml). It runs on `main`, work branches, pull requests, and manual dispatch. The job uses an isolated MongoDB and Redis, runs the source/type/API/tool checks, audits dependencies and CodeQL, exports Godot Web, checks the world, builds web/API, and packages a SHA-bound delivery bundle. `verification-reports` is uploaded even after a failed step (14-day retention); `verified-delivery` is uploaded only after the full job succeeds (3-day retention). The CodeQL SARIF is in the reports artifact; a native GitHub code-scanning alert is not implied. Read the job conclusion, source SHA, and report files in [GitHub Actions](https://github.com/ardianryan/Jalasmara-The-Game/actions). Failure reports remain useful, but a failed run does not authorize delivery.

The workflow deliberately does **not** deploy. Before staging activation, follow [the release/backup/rollback runbook](operations.md): validate the candidate manifest and bytes, preserve application data and `.env`, back up and restore-test MongoDB, keep one verified image rollback, then perform public smoke with an isolated fixture. Record the image, PCK and source hashes separately. Do not infer device performance from CI or browser emulation.

## Repository settings

GitHub repository Actions must be enabled. Gitea repository `has_actions` must be false. GitLab project CI must stay disabled in settings as well as by `.gitlab-ci.yml`. Repository administrators can inspect GitHub with `gh api repos/ardianryan/Jalasmara-The-Game/actions/permissions` and Gitea with `tea api repos/ardianryan/Jalasmara-The-Game`; check the `enabled` and `has_actions` fields respectively. No CI deploy key or `ci-reports` branch is needed. Never commit runner credentials.
