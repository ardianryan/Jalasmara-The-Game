<p align="center"><img src="assets/brand/horizontal.svg" width="420" alt="Jalasmara"></p>

# Jalasmara

**Jalasmara: Menjaring Ingatan** is a coastal exploration game set around Bandar Hujung and Palung Smara. Players guide Nala through a three-quarter-view village and forest, dive through layered marine environments, collect knowledge fragments, and help run Kedai Waras. Learning is tied to exploration, residents, and contextual challenges.

> **Development status — v0.1.0.** This is a playable early prototype, not a finished game or a security-audited release. The current staging build passed an automated public browser smoke test. Visual polish, natural gait across all directions, and performance on physical Windows and Samsung S23 devices remain open. See [development status](docs/development-status.md) and the [latest staging report](docs/reviews/staging-main-446abf4-2026-11-10.md).

[Play the staging build](https://staging-jalasmara.ardianryan.com) · [Development gallery](docs/visual/README.md) · [Architecture](docs/architecture.md) · [Roadmap](ROADMAP.md) · [Open work](TODO.md) · [Changelog](CHANGELOG.md)

## The project

| Layer | Current implementation |
| --- | --- |
| Game | Godot 4.7.2 Compatibility renderer; single-threaded Web export; real 3D land terrain with pixel upscale and layered underwater scenes |
| Web host | React and Vite for accounts, loading, settings, and administration |
| State and API | Fastify with MongoDB for authoritative progress and Redis for sessions |
| Authoring | Offline WorldKit map drafts, pixel-grid preparation, and palette previews; reviewed before integration |

The game uses a 36-minute active-time day. Story progression, economy, and saved state are server-owned. Game art and lore have different reuse terms from the MIT-licensed source code; read [LICENSE](LICENSE) and [third-party notices](THIRD_PARTY_LICENSES.md) before reusing material.

## Try it locally

You need Node.js 22.12+, npm, Docker Compose v2, Godot 4.7.2, and its single-threaded Web export templates. MongoDB must run as a replica set. The development Compose file provides local services; use a dedicated test database for integration tests.

```sh
npm ci
cp .env.example .env
docker compose -f compose.dev.yml up -d
npm run seed
npm run owner
npm run build:game
npm run dev
```

Open `http://localhost:5173`. The interactive `owner` command creates an account with credentials you choose; there is no default password. If Godot is not on `PATH`, set `GODOT_BIN` to the local executable. Generated Web export files under `apps/web/public/game/` are ignored by Git.

```sh
npm run typecheck
npm test
npm run check:world
npm run build
```

The complete CI pipeline adds Godot, browser, tooling, and dependency checks. See [contributing](CONTRIBUTING.md) for test isolation and evidence requirements.

## Repository map

| Path | Role |
| --- | --- |
| `client-godot/` | World, actors, movement, shaders, game HUD, and Web export |
| `apps/web/` | Browser host, authentication screens, and administration |
| `apps/api/` | Authoritative gameplay API, persistence, and audit |
| `packages/shared/` | Contracts, initial content, and world definitions |
| `tools/worldkit/` | In-repository map-draft adapter |
| `tools/pixel-snapper/`, `tools/image-to-pixel/` | Offline asset preparation with upstream attribution |
| `docs/` | Product requirements, art direction, operations, reviews, and evidence |

The separate [JalasmaraWorldKit](https://git.ppti.me/ardianryan/jalasmara-worldkit) repository packages the authoring tools; its [public GitHub mirror](https://github.com/ardianryan/jalasmara-worldkit) is available without a Gitea login. Its drafts do not publish maps or modify player data. [WorldKit guidance](tools/worldkit/README.md) and [integration references](docs/reference-integrations.md) explain scope and provenance.

## Development and evidence

[GitHub](https://github.com/ardianryan/Jalasmara-The-Game) is the source and [Actions](https://github.com/ardianryan/Jalasmara-The-Game/actions) CI home. [Gitea](https://git.ppti.me/ardianryan/Jalasmara-The-Game) and [GitLab](https://gitlab.com/ardianryan/jalasmara-the-game) mirror code without running CI. Verification reports and a hashed delivery candidate are retained as GitHub Actions artifacts; staging activation, backup, rollback, and public smoke are separate steps described in [operations](docs/operations-github.md).

The [gallery](docs/visual/README.md) contains selected original-game screenshots with source/PCK hashes and acceptance limits. Reference moodboards are not distributed as game assets. For current decisions and remaining blockers, use the [active handoff](docs/agent-handoff.md) and [PRD](docs/PRD.md); older review reports remain historical evidence.

## Participate

Read the [contribution guide](CONTRIBUTING.md), [code of conduct](CODE_OF_CONDUCT.md), [security policy](SECURITY.md), and [support guidance](SUPPORT.md). For academic or software references, use [CITATION.cff](CITATION.cff) or [CITATION.bib](CITATION.bib). The [changelog](CHANGELOG.md) starts at `0.1.0`; a new version entry will be added when the project owner requests one.
