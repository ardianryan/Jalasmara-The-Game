# Candidate branch consolidation — 11 November 2026

The user asked for a safe merge or PR path that actually reduces branch/worktree clutter. This pass consolidated four redundant candidate branches into two still-retained candidate histories. No unaccepted source was merged into `main`, and no staging build changed.

| Retired branch | Coverage proof | Retained history |
| --- | --- | --- |
| `work/gemini-character-source-audit` (`f67de11`) | `git cherry work/gemini-day01` reports its patch as covered | `work/gemini-day01`, including the subsequent false-positive correction |
| `work/gemini-day01-art` (`975b894`) | Its only unique art patch is patch-equivalent to the coordinator's `744c596` | `work/gemini-day01` |
| `work/gemini-day01-audit` (`4d6d8f9`) | Both audit patches are patch-equivalent to coordinator commits | `work/gemini-day01` |
| `work/overnight-character` (`ddb409b`) | `git merge-base --is-ancestor` proves the entire branch is an ancestor | `work/gemini-day01-gait` |

All four worktrees had clean tracked/untracked status and no process using their directories. Their ignored `.runtime` and `artifacts` evidence was moved to `.runtime/retired-worktrees/2026-11-11-redundant-candidates/` (about 108 MiB total), rather than destroyed. The generated `client-godot/.godot` cache in the old character worktree (about 62 MiB) was discarded; it can be rebuilt. Each remote tip was checked against its local branch tip, then the four refs were deleted from Gitea, GitHub and GitLab without force. A fresh remote listing confirms `main` plus four `work/*` branches on Gitea/GitLab; GitHub also retains its historical `ci-reports` ref. Five worktrees remain including `main`; `git worktree prune --dry-run` found no stale registration.

The four remaining branches are **not duplicates**: `work/gemini-day01` has 12 patch IDs unique to `main`, `work/gemini-day01-gait` has 118, `work/overnight-resident-art` has 10, and `work/overnight-village` has one unaccepted fish-pen placement patch. A direct PR from these old-base branches would mix accepted historical commits with still-unaccepted gait/art or placement changes. Creating a draft PR would not itself make those changes safe; the next reviewable PR should be cut from current `main` with a bounded accepted subset and its actual visual/physical proof. The resident-art branch was examined; its runtime art and garden browser script are already in `main`, but several distinct historical review records differ from mainline reports, so it was retained rather than silently retired. The village placement and physical-gait acceptance gates are unchanged.

Validation: Git patch equivalence and ancestry checks above, clean worktree statuses, exact remote-head checks, and post-deletion local/remote branch listings. No Godot render, device FPS, PR approval, CI result or gameplay acceptance is claimed by this branch-only operation. Active staging remains source `f600b62bdbcfdd3cb870ba47679e8fc53d611cee`, image `sha256:6679c096d317912a6867f26927f101303c1a0c7b8ed6d86e502e674da6685330`, and PCK `cdbfac713fd72506e8458a9cd4fdfc0983f48f2cd805acdd0c9d61fc4f52106a`.
