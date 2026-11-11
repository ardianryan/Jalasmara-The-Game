# Branch integration and retirement — 11 November 2026

The user asked to keep one mainline: remove branches whose work is already in `main`, safely cherry-pick missing accepted work, and retain anything that still needs review. This pass reviewed 20 local `work/*` branches. It does not activate a new staging build.

## Integrated into `main`

Four bounded commits were cherry-picked without runtime changes:

| Original | Mainline | Content |
| --- | --- | --- |
| `42634cf` | `3a89af5` | Narrow natural-terrain marker assertion to its proven clear-floor case |
| `3e9bcc6` | `3bde443` | Historical Saras alpha browser review and limits |
| `8150a63` | `26a5d7e` | Contact diagnostic and upper-approach review |
| `f93f376` | `22eaec6` | Historical local cache inventory |

The preloader branch `work/06p-loader-stream-error` was semantically superseded: `main` already contains `withTrackedStreamErrors` in `scripts/godot-preloader-stream.mjs` and calls it from `scripts/export-game.mjs`, alongside later WASM and segmented-PCK handling. The two focused loader suites passed 18/18. No old preloader patch was reapplied.

## Retired local branches and worktrees

`work/06b-natural-edges`, `work/06b-npc-alpha`, `work/overnight-contact-audio`, `work/06-gateway-route-qa`, and `work/06p-loader-stream-error` were retired after the above integration/supersession check. Seven more branches had exact-subject mainline counterparts and later mainline evolution: `work/06-camera-pilot`, `work/06b-dialogue-compact`, `work/06b-foot-boundary-next`, `work/06b-house-alignment`, `work/06b-hud-portrait-next`, `work/06e-nala-restart-pilot`, and `work/06g-stair-grounding`. Their original commits were not replayed over newer source. The old GitLab CE CI edit in the stair branch is obsolete under the Gitea decision.

All 12 linked worktrees had no tracked edits. The only untracked dependency was a symlink to the main worktree's `node_modules`; it was removed without touching its target. Ignored `.runtime` and `artifacts` evidence was moved under `.runtime/retired-worktrees/2026-11-11-branch-integrated/` before removing worktrees. This archive is local, outside Git, and was not treated as disposable cache. Remote tips on Gitea, GitHub, and GitLab matched local retired tips before remote cleanup.

## Held for separate acceptance

Eight branches remain: `work/gemini-character-source-audit`, `work/gemini-day01`, `work/gemini-day01-art`, `work/gemini-day01-audit`, `work/gemini-day01-gait`, `work/overnight-character`, `work/overnight-resident-art`, and `work/overnight-village`. The Gemini audit contains documented false-positive direction findings, and the gait branches include unaccepted physical/view recovery. The resident-art branch retains distinct review/proposal records. The village branch's one unique patch moves the fish pen beyond deck occlusion; its current mainline position differs, so a visual acceptance pass is required before merging it. No Claude gait work was cherry-picked. Retain these branches and worktrees rather than deleting or silently archiving their unfinished content.

## Verification and release boundary

`git diff --check` passed. `node --test scripts/godot-preloader-stream.test.mjs scripts/pck-stream.test.mjs` passed 18/18. This package changes documentation and one test assertion only; the active staging source remains `f600b62bdbcfdd3cb870ba47679e8fc53d611cee`, image `sha256:6679c096d317912a6867f26927f101303c1a0c7b8ed6d86e502e674da6685330`, and PCK `cdbfac713fd72506e8458a9cd4fdfc0983f48f2cd805acdd0c9d61fc4f52106a`. The next gameplay task is visual/physical acceptance of the held branches, especially gait and pen occlusion; S23/Windows measurements remain owner-assisted.

Tools used: local Git, Python 3 for evidence-preserving worktree retirement, Node's test runner, and existing project scripts. No new asset, third-party code, license, or production image was added.
