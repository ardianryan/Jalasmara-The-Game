# GitHub Actions: current CI and delivery source

**Decision, 12 November 2026.** GitHub `ardianryan/Jalasmara-The-Game` is the source used for CI. GitHub Actions alone runs verification and prepares a delivery candidate. Gitea and GitLab receive the same Git commit as code backups; their project pipelines stay disabled. The earlier [Gitea runbook](operations-gitea.md) and [Gitea CI addendum](plans/08c-gitea-ci-addendum.md) are historical.

## Recording a commit

From a reviewed local branch, run `npm run push:all -- <branch>`. The helper freezes one commit SHA and sends it to GitHub first, then Gitea, then GitLab. It never force-pushes. A failed GitHub push stops backup publication; a failed backup push leaves a visible error and must be retried. GitLab receives `ci.skip`, and its `.gitlab-ci.yml` forbids every pipeline. Gitea repository Actions must remain disabled because Gitea can discover workflows in `.github/workflows` when `.gitea/workflows` contains none.

Check `git ls-remote github refs/heads/<branch>`, `git ls-remote gitea refs/heads/<branch>`, and `git ls-remote gitlab refs/heads/<branch>`; all three must report the frozen SHA. A mirror push is a backup, not evidence that the game passed CI or is active on staging.

## Verification and reports

The active workflow is [`.github/workflows/ci.yml`](../.github/workflows/ci.yml). It runs on `main`, work branches, pull requests, and manual dispatch. The first job uses an isolated MongoDB and Redis, runs the source/type/API/tool checks, audits dependencies and CodeQL, exports Godot Web, checks the world, builds web/API, and packages a SHA-bound delivery bundle. `verification-reports` is uploaded even after a failed step (14-day retention); `verified-delivery` is uploaded only after the first job succeeds (3-day retention). The CodeQL SARIF is in the reports artifact; a native GitHub code-scanning alert is not implied.

The dependent `build-full-source-image` job downloads that exact bundle, verifies its source, context, game assets and PCK parts, builds the complete Linux/amd64 API/Web image, and compares **every compiled API and Web file** against the first job's SHA-256 inventory. It uploads `full-source-image` only after all checks pass (3-day retention). The image is compressed for transfer and is never deployed by CI. Read the **whole workflow conclusion**, its source SHA and both jobs in [GitHub Actions](https://github.com/ardianryan/Jalasmara-The-Game/actions). A `verified-delivery` bundle from a failed image job is not a release-ready full-source image.

For a source commit that changes API, Web or dependencies, use the complete image artifact; replacing game files in an old image would leave stale server/host code. This is necessary while the staging VPS has no route to the npm registry and no Docker build cache. After the whole workflow passes, download the two artifacts from the **same run** and verify the image bundle locally before transfer:

```sh
TASK_SOURCE="$(git rev-parse HEAD)"
TASK_RUN_ID="<successful-run-for-TASK_SOURCE>"
TASK_IMAGE_DIR="$PWD/.runtime/oci-release-$TASK_RUN_ID"
gh run download "$TASK_RUN_ID" --repo ardianryan/Jalasmara-The-Game \
  --name full-source-image --dir "$TASK_IMAGE_DIR"
python3 scripts/ci_oci_delivery.py verify-bundle \
  --directory "$TASK_IMAGE_DIR" --source "$TASK_SOURCE"
```

Confirm the run's `headSha` equals `TASK_SOURCE` and record `oci-manifest.json`, image archive SHA-256, image ID, PCK SHA-256/bytes and `release-manifest.json` hashes. Transfer the verified compressed archive to a fresh VPS directory, run `docker load --input image.tar.gz`, and require the loaded `jalasmara:ci-<full-source-SHA>` image ID and source label to match `oci-manifest.json`. The artifact contains no database, `.env` or registry credentials. Do not rebuild from an unrelated checkout or substitute a local Godot export.

The workflow deliberately does **not** deploy. Before staging activation, follow [the release/backup/rollback runbook](operations.md): validate the candidate manifest and bytes, preserve application data and `.env`, back up and restore-test MongoDB, keep one verified image rollback, then perform public smoke with an isolated fixture. Record the image, PCK and source hashes separately. Do not infer device performance from CI or browser emulation.

## Repository settings

GitHub repository Actions must be enabled. Gitea repository `has_actions` must be false. GitLab project CI must stay disabled in settings as well as by `.gitlab-ci.yml`. Repository administrators can inspect GitHub with `gh api repos/ardianryan/Jalasmara-The-Game/actions/permissions` and Gitea with `tea api repos/ardianryan/Jalasmara-The-Game`; check the `enabled` and `has_actions` fields respectively. No CI deploy key or `ci-reports` branch is needed. Never commit runner credentials.
