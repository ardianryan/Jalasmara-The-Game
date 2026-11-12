# GitHub Actions migration, 12 November 2026

The owner restored GitHub Actions capacity and chose GitHub Actions as the sole CI and report location. Gitea and GitLab are code mirrors without pipelines. This supersedes the Gitea CI decision in the historical runbook; it does not change the active staging image or player data.

## Source changes

- Moved the verification/build/delivery job to `.github/workflows/ci.yml`; retained isolated test services, source SHA record, dependency audits, CodeQL SARIF, Godot export and world checks. The job publishes `verification-reports` on both success and failure and a `verified-delivery` bundle only on success.
- Removed the Gitea workflows and the old GitLab-to-GitHub `ci-reports` relay and deploy-key known-hosts file. GitLab's workflow remains disabled. `scripts/push-remotes.mjs` now sends a frozen SHA to GitHub first and then both backups.
- Changed the isolated MongoDB bootstrap guard to GitHub Actions and updated the active operations, architecture and agent documentation. Historical reports remain historical.

## Verification and release status

Pending run: record the exact source commit, focused local checks, GitHub Actions URL/conclusion/artifact names, and three remote heads here after the workflow completes. Gitea repository Actions must be confirmed disabled and GitHub repository Actions enabled before pushing. Staging activation is a separate operation and is not part of this migration.

## Remaining work

After a successful GitHub Actions run, verify artifacts and backup remote SHAs. Keep physical Samsung S23/Windows performance and dialogue/quiz HUD acceptance as separate product gates; this CI migration does not satisfy them.
