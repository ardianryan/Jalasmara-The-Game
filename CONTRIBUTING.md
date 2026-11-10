# Contributing to Jalasmara

Jalasmara is an active prototype. Small, reviewable contributions are welcome when they preserve the game's cultural direction, authoritative state, and licensing boundaries. Open a Gitea issue before a large feature or asset set so its scope and ownership can be agreed on.

## Workflow

1. Read [the active handoff](docs/agent-handoff.md), [PRD](docs/PRD.md), [roadmap](ROADMAP.md), and relevant art or operations notes. Older reports may describe a superseded staging build.
2. Create a focused branch from `main`. Use a separate worktree if another contributor is editing the same repository. Give shared files one writer.
3. Make the smallest change that satisfies the acceptance criteria. Do not silently change story, rewards, ownership, or server contracts while polishing visuals.
4. Run the relevant checks: `npm run typecheck`, `npm test`, `npm run check:world`, and `npm run build` for core changes. Use dedicated MongoDB/Redis fixtures, never live player data. Tool-only changes should run their focused tests.
5. Include before/after screenshots or a short capture for visual changes. State source commit, build/PCK hash, test environment, and what the evidence does *not* prove. Emulated touch and SwiftShader do not count as physical-device performance.
6. Submit a Gitea pull request that explains the trigger, resulting behavior, tests, limits, and any migration or rollback implications. Integrators decide when to merge and release.

Never commit `.env`, credentials, personal data, database backups, generated exports, or private moodboards. Record each new asset's source, author, generation/edit steps, license, and distribution rights. Original source code is MIT licensed; Jalasmara characters, art, audio, maps, and lore are separately reserved under [LICENSE](LICENSE). Upstream components retain the notices in [THIRD_PARTY_LICENSES.md](THIRD_PARTY_LICENSES.md).

For UI, include loading, empty, error, keyboard-focus, and mobile-landscape states. For game movement, show actual moving frames and contact on terrain; a still image or passing socket test alone is insufficient. Report security concerns privately under [SECURITY.md](SECURITY.md), not in a public issue. All participants are expected to follow the [code of conduct](CODE_OF_CONDUCT.md).
