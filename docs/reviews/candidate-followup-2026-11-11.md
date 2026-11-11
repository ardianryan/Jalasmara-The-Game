# Candidate branch follow-up — 11 November 2026

This follow-up tested the remaining candidate work against the current `main` after [the initial acceptance review](candidate-acceptance-2026-11-11.md). No physical gait, village anchor, resident runtime, or staging deployment was promoted.

## One bounded acceptance

The source-only peer diagnosis `8d06075` from `work/overnight-resident-art` was cherry-picked as `9e75b27`: [central-ascent ankle analysis](overnight-central-ascent-ankle-peer.md). It reconstructs a recorded ankle speed overshoot from actual samples, distinguishes the curve from pivot/gear effects, and explicitly does not claim a gait fix. `git show --check 9e75b27` passed. No executable source or asset changed.

## Gait reproduction contradicts the old PASS

The `work/gemini-day01-gait` tip remains `ab5574b`. Godot 4.7.2 headless ran `scripts/tests/nala-production-terrain.gd` with the ordinary 16-case setting and a fresh output path. Three attempts rejected the physical lower-body pilot:

| Run | Completed cases | Rejection |
| --- | ---: | --- |
| `.runtime/gait-review-2026-11-11/` | 5 | `western_stone_steps/true/false`, fixed-length **inner** reach; left hip–ankle distance 0.504 world units against minimum 1.221 |
| `.runtime/gait-review-western-repro/` (case 5 alone) | 0 | `western_stone_steps/true/false`, outer reach; requested drop 20.123 px against 8 px limit |
| `.runtime/gait-review-repeat-2026-11-11/` | 2 | `central_stone_steps/false/false`, outer reach; requested drop 10.699 px against 8 px limit |

The full-run `source.json` hashes match the historical `artifacts/godot/full16-clean-1794285472/source.json` **for every listed file** and for the world map (`28455e6f7ec0…`). The same source can therefore produce a historical 16-case pass and current failures. The sample streams show different physics-frame spacing and pose histories; the causal mechanism has not yet been proven. The fixture updates the renderer after awaiting a physics and a process frame, so scheduling and body/support transfer need instrumented review. Do not relax the 8-pixel reach guard or move the authoritative floor to make the test green. A native moving review would be premature while this headless gate fails.

The coordinator's standalone Gate 2 CPU model was also run against its preserved baseline artifact and produced its documented `8.841863` px reconstruction and `7.180` px candidate bound. That model is a diagnosis of one recorded pose, requires NumPy and a historical ignored artifact, and does not repair the current nonrepeatable controller run. It was not promoted.

## Other branches

`work/gemini-day01` still contains historical checkpoint documents and the Gate 2 model; its accepted audit and SOUTH upper art are already in `main`. `work/overnight-resident-art` retains historical browser/benchmark notes and prototype work; its production rig and browser script are already present in `main`. `work/overnight-village` contains the older `(360,1030,-11)` fish-pen anchor, superseded by the tested `(275,990,-11)` anchor. All four linked candidate branches remain available; none was rewritten, merged wholesale, archived, or deleted.

## Next acceptance gate

1. In `work/gemini-day01-gait`, instrument per-update accepted movement, renderer update interval, bodyHeight, both hip–ankle distances and the selected support before/after each rejection. Reproduce from a fresh output directory across repeated full16 runs; add a regression that fails on variable frame spacing.
2. Repair gait scheduling/support without changing authoritative collision, floor geometry, original pixels or the 8-pixel reach bound. Require repeatable full16, flat32, raw input, stop/restart and pause/recovery results with identical source hashes.
3. Only then run native moving ascent/descent clips and inspect sole contact, ankle continuity, arm cadence and modular gear. Keep the default pilot OFF until those visual and audio gates pass.

Evidence is in the three ignored `.runtime/gait-review*` directories of the gait worktree and its historical `artifacts/godot/full16-clean-1794285472/`. These files are retained for diagnosis, not distributed as game assets. Tools used: Git, Godot 4.7.2, Python 3.9 with NumPy/Pillow already present in the local authoring environment. No new third-party asset or license was added. `main` source is not active on staging until a separate release is built and verified.
