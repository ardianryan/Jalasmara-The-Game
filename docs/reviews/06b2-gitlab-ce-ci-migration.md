# GitLab CE CI migration candidate

The user selected `https://git.ppti.me/ardianryan/Jalasmara-The-Game.git` as the sole CI/CD authority. GitHub and public GitLab remain source mirrors. This report describes prepared source; authentication, project settings, runner registration, remote synchronization and activation remain root-owned. No CE pipeline or deployment has been claimed as successful.

The candidate starts from main source `9cc72e674e7f4df69420274f99e8f646ec66bdb6`, retaining its loader/WASM/canopy/gateway regression commands. It changes `.gitlab-ci.yml` as follows:

- The first workflow rule rejects any server whose `CI_SERVER_HOST` is not exactly `git.ppti.me`. A source push carrying this file to `gitlab.com` must not create a new pipeline. Existing public pipeline history remains historical evidence.
- All jobs require the explicit `jalasmara-docker` runner tag. They stay pending until a matching verified runner is available, rather than accidentally running container-oriented package commands on a shell executor.
- Verify installs `python3-pil` before the canopy alpha test, addressing the concrete missing-Pillow failure in [pipeline 3045235596](06b2-ci-artifacts-3045235596.md).
- The protected-main GitHub reporting job requests `GIT_DEPTH: "0"` and fetches an unshallow history if needed before pushing. This addresses the incomplete-history prerequisite behind the rejected mirror push; the remote result still requires a real CE execution.
- Stages, tests, dependency audits, CodeQL, artifact paths, cache keys and expiration periods remain unchanged. There is no automatic VPS deployment job. Existing GitHub Actions remain disabled.

## CE prerequisites that must be verified

1. The CE project must contain the complete source history, use `main` as its default branch, and protect it. Apply the repository file and validate it with that server's CI Lint; local YAML parsing does not prove support for every CE-version feature.
2. Register or select a verified Linux x86_64 Docker executor and assign the `jalasmara-docker` tag. It must use the Node 22 Debian image, run root-level package installation **inside containers**, and provide isolated Mongo 8/Redis 7.4 services with the existing network aliases. Do not send these jobs to an ordinary shell executor or silently substitute a macOS runner; Godot and CodeQL downloads are Linux amd64. No matching runner is assumed to exist yet.
3. Package downloads need outbound access to Debian, npm and GitHub. Existing CodeQL is configured for a 3,072 MiB budget and one thread; provision and measure runner RAM/scratch space before running build and analysis concurrently. Its archive/database, npm cache and Godot cache are substantial; existing retention instructions apply.
4. Create the existing `GITHUB_DEPLOY_KEY_B64` variable on CE as masked and protected, using a repository-scoped write deploy key. The public project's variables do not transfer automatically. No personal gh/glab token should be embedded in source, logs or CI. Protected-main rules keep that key out of ordinary merge-request jobs.
5. Keep CI's Mongo/Redis services disposable. Do not copy production database, Redis or application secrets into test variables. Existing fixture-specific databases and cleanup rules remain in force.
6. Current reporting automates the GitHub `main` source mirror and `ci-reports` branch. Root may synchronize both source remotes explicitly; use `-o ci.skip` on an initial public GitLab mirror push if needed, then retain the host-gated file there. A future authenticated public mirror job is not introduced as a new CI prerequisite. Verify that no new public GitLab pipeline/GitHub Action starts.

## Acceptance and current evidence

Local Ruby/Psych parsed the prepared YAML. CPU structural checks verified the first host-deny rule, explicit Docker-runner tag, Pillow dependency, full-history guard, existing protected-main reporting condition, unchanged stages/services, and absence of active `.github/workflows/*.yml` or `.yaml` files. No dependency installation, engine, browser, CE server lint, external push or production action was performed by this lane.

Root's unauthenticated discovery found the CE project at id 2, public but empty with no refs; HTTPS push requested login, glab was unauthenticated, and SSH port 22 did not connect. Authentication is therefore still a setup prerequisite, not a completed migration. Root is handling the user's login interaction. Never place the PAT in a tracked file, command history, CI report or plain-text variable dump.

Root still needs authenticated project/runner discovery, CI Lint on CE, the first complete CE pipeline, and artifact inspection: API 100, world 50, harness results, three audit JSON files and CodeQL SARIF. Old public pipeline 3045235596 remains failed; local test results must not be substituted for a CE run. Manual backup/build/health/hash/browser/rollback gates for VPS activation remain unchanged.
