# Worktree and branch audit — 11 November 2026

The user asked to resume worktree and branch cleanup after the earlier 12-branch retirement. Current `main` baseline was `b086b5557f630d879054e0c468ccdba204e96264`. This was a hygiene and acceptance audit, not a gameplay integration or staging deployment.

## Result

Eight `work/*` branches and their linked worktrees remain. All eight have unique patches against `main`; none met the user's rule for deleting an already-integrated branch. No unaccepted gameplay or art commit was cherry-picked merely to reduce branch count.

| Branch | Unique patch IDs vs `main` | Why retained |
| --- | ---: | --- |
| `work/gemini-character-source-audit` | 1 | Original audit includes documented false-positive direction findings; a corrected audit must be accepted before promotion. |
| `work/gemini-day01` | 12 | Coordinator history includes corrected audit, gait model and upper artwork, none accepted together in `main`. |
| `work/gemini-day01-art` | 2 | Isolated SOUTH upper-body artwork still needs final visual/animation acceptance. |
| `work/gemini-day01-audit` | 2 | Corrective audit is linked to unaccepted source audit and proof. |
| `work/gemini-day01-gait` | 118 | Experimental physical gait has unresolved view/foot gates and is not production-active. |
| `work/overnight-character` | 115 | Original gait experiment and failure evidence, also an ancestor of the Gemini gait branch; retained until the latter is resolved. |
| `work/overnight-resident-art` | 10 | Distinct resident-art, browser-proof and contact-audio review records still need scoped acceptance. |
| `work/overnight-village` | 1 | Unique fish-pen repositioning has not passed visual acceptance against the current deck. |

The three remote repositories have the same eight `work/*` names plus `main`; GitHub additionally keeps its historical `ci-reports` branch. No remote ref changed in this audit. `git worktree prune --dry-run --verbose` reported nothing stale.

## Local worktree hygiene

The three overnight worktrees had untracked `node_modules` symlinks pointing to the shared main-worktree dependency directory. Only those links were removed; the target dependency tree was not touched. The overnight-character worktree also held two generated `.pyc` files (63,936 logical bytes) under `tools/player-gait/__pycache__/`; that disposable cache was removed. No `.runtime`, `artifacts`, `.godot`, source, proof image or candidate branch was deleted or moved. Free-space change was not measured before this small cleanup, so no disk-recovery claim is made. Every linked worktree now reports a clean `git status --porcelain`.

The active staging source remains `f600b62bdbcfdd3cb870ba47679e8fc53d611cee`, image `sha256:6679c096d317912a6867f26927f101303c1a0c7b8ed6d86e502e674da6685330`, and PCK `cdbfac713fd72506e8458a9cd4fdfc0983f48f2cd805acdd0c9d61fc4f52106a`. The local cache cleanup did not touch VPS services or application health. The next meaningful branch reduction requires accepting or rejecting the held visual/physical candidates, starting with the corrected character audit and actual gait/pen views.
