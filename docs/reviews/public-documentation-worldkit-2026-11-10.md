# Public documentation, WorldKit, and branch consolidation

The owner requested a professional English-language public entry point, community and citation files, an initial `0.1.0` changelog that stays at that version until explicitly changed, a public WorldKit repository with development screenshots, and removal of historical branches that no longer carry work. This package changes documentation and the separate authoring kit; it does **not** change the game runtime or activate a new staging image.

## Main game repository

`README.md`, `CONTRIBUTING.md`, and `SECURITY.md` were rewritten in English. New root files are `CODE_OF_CONDUCT.md`, `SUPPORT.md`, `CHANGELOG.md`, `ROADMAP.md`, `TODO.md`, `CITATION.bib`, and `CITATION.cff`; `docs/architecture.md` and Gitea bug/PR templates provide contributor entry points. The README now leads with the actual prototype state, local setup, architecture, evidence and operational links. The changelog has one `0.1.0` baseline and explicitly defers future version headings until the owner asks. The security policy states that no independent audit or penetration test has been completed; CI and smoke are not security certification. Legacy technical reports remain historical records in their original language.

The root project remains split-licensed: MIT source code, separately reserved game art/lore, and third-party notices. This package does not relicense assets or distribute reference moodboards. New public prose is English; the existing `LICENSE` text was left intact to avoid silently changing legal terms.

## WorldKit repository

The previously private [JalasmaraWorldKit](https://github.com/ardianryan/jalasmara-worldkit) source was updated and published at [Gitea](https://git.ppti.me/ardianryan/jalasmara-worldkit), [GitHub](https://github.com/ardianryan/jalasmara-worldkit), and [GitLab](https://gitlab.com/ardianryan/jalasmara-worldkit). All three repository settings report public. The Gitea repository was created without an initialized commit, then populated from the existing two-commit WorldKit history; default branch is `main`. A new repository-specific Gitea deploy key lives only in the local SSH store and Gitea, not in source or reports. GitHub and GitLab copies receive the same main SHA, `9858d9d0971af5bf105cac51bd8f805f380f52e7`.

The kit now has English README, contribution/security/conduct/citation/changelog/roadmap files, a Gitea CI workflow, and disabled GitLab CI. Its three curated PNGs are byte-identical copies of original game evidence for village, stairs and forest gateway. `docs/visual/README.md` records source build/PCK, hashes and limits; the kit `LICENSE` excludes the screenshots from MIT, preserving the game's all-rights-reserved art terms. The kit does not claim its adapter generated the pictured world. The tracked history and new files were checked for obvious key/token/private-key patterns before public visibility was changed; this is a publication hygiene check, **not** a security audit.

Local kit verification: `npm run setup:images`, `npm run build:snapper`, `npm run check`, and `npm run audit:images` passed; image dependency audit reported zero vulnerabilities at check time. An initial `npm run check` without first building Snapper failed because its test fixture requires the `.cache` directory and compiled binary; the documented build-first sequence then passed. Gitea run 11 failed because the checkout container lacked CA certificates and the Rust container lacked Node. Run 12 passed the Node/Python job but its Rust job failed for missing `cc`; the workflow was corrected to install a C toolchain. [Gitea run 13](https://git.ppti.me/ardianryan/jalasmara-worldkit/actions/runs/13) on source `91b53634b26e9412e9883f5252d118ede4465ca4` completed **success** for both jobs. The final `9858d9d` commit only changes links to anonymously accessible game documentation and carries `[skip ci]`; it was not a new tool test.

Gitea metadata sets WorldKit `private: false`, but the Gitea instance currently redirects anonymous web requests to login and returns 403 for anonymous API requests, apparently due to instance-wide sign-in policy. Public GitHub and GitLab mirrors both return HTTP 200 anonymously. The Gitea setting is public; anonymous Gitea browsing is still blocked by the host configuration and is not presented as working.

## Branch inventory

[Branch retirement report](branch-retirement-2026-11-10.md) lists 38 patch-equivalent historical branch tips removed from local Git and all three game remotes after ignored evidence was moved to a central local archive. Twenty `work/*` branches remain because they contain unique candidate commits; none was merged merely to reduce branch count. The two untracked `.uid` files on the final retired branch were verified byte-identical to tracked files on `main`. The owner may review retained candidates against current acceptance gates later. Local free space increased by about 4.99 GiB at the end of retirement; moved evidence remains available. No source candidate, database, VPS volume or screenshot gallery was deleted.

## Remaining work

- Keep the three WorldKit remotes at one SHA for future changes. Gitea anonymous access requires an instance policy decision outside this repository.
- Commit and push the same main-documentation SHA to Gitea, GitHub and GitLab. Relative links and `git diff --check` passed locally before commit.
- Review the 20 retained branches individually. Gait and character-audit candidates still have known blockers in the active handoff; do not mass-merge them.

Tools actually used: Git/SSH/Gitea `tea`, GitHub `gh`, GitLab `glab`, Node/npm, Python standard library, Rust/Cargo, Ruby YAML parser, `curl`, and filesystem moves. No image generator, moodboard asset, or new game runtime dependency was used.
