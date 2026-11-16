# Phase 1 screenplay action polish — local candidate

This package adds four small, code-drawn actions to existing Phase 1 cutscene backdrops. It is a local candidate on `work/phase1-screenplay-polish-20261116`, based on `7082dbf`; it has not been merged, pushed, exported, or deployed by this package.

## Changed

- Prologue beat 1 now places Ki Lurah and three children beside a compass lesson on the harbor pier.
- Prologue beat 3 shows Pak Ranto at his hanging scale and Bu Darmi beside a wilting planter, with their memory fragments fading.
- First-service beat 2 places Raka beyond the Kedai window rail and rain, so the shot reads as his watch from outside.
- Epilogue beat 1 includes existing resident sprites, warm lanterns, and two small tables with cups before Raka's confrontation.

The action layer uses existing project atlases and code-drawn pixels. It adds no raster asset, dependency, gameplay state, collision, or server rule. No external authoring tool was used.

## Verification

Godot 4.7.2 Compatibility passed the focused screenplay test headless and native at both 667×375 and 844×390 (8 cases each). The native capture used macOS Metal/OpenGL on Apple M2 and produced no `SCRIPT ERROR` or `ERROR` after the final fix:

```sh
Godot --headless --quit-after 300 --path client-godot --script res://../scripts/tests/phase-one-screenplay-polish-capture.gd
CINEMATIC_CAPTURE=1 Godot --quit-after 300 --path client-godot --script res://../scripts/tests/phase-one-screenplay-polish-capture.gd
```

During development, an untyped table coordinate caused a GDScript inference error; explicit float conversion fixed it. A fresh worktree's first editor import also logged temporary unresolved font resources; the subsequent focused headless and native runs were clean. `git diff --check` passed. Full director QA, WebGL, Windows, Android, performance, CI, and staging remain integrator checks.

Native evidence in the local ignored artifact directory (`artifacts/godot/phase-one-screenplay-polish/`):

| Shot | 667×375 SHA-256 | 844×390 SHA-256 |
| --- | --- | --- |
| `prologue-01` lesson | `ad3323e969e83be95518244608442caa4f01c912176e167e55eab3dfb82bc077` | `280c14bdf69ee9b931b71ef2d68edc951453abb0d482f1071df1677a11f07da0` |
| `prologue-03` lost work | `cc4314dde18f14ac359cac0e69688a07dff7bc94b33f5cce49f379f33cdedf26` | `ed3fdce1da49fbb6f7a2eef03f6496ae6d64f6d408fe639e1fa586dc6358e9d0` |
| `first_service-02` Raka | `57f482c6125bca0863aa6235b0a028193019ee83df75c5a6e2de656056d87a91` | `d92cf45578ef0abcd7b0b60159b7e859b3df94856092af01cdc53366a07a51f2` |
| `epilogue-01` meal | `2933a73af27c5f6375c87b2a900d33fd2f63ffcc5a03d6c1a6b2d9536afe1fa9` | `94389f57ede101d7f6c17881a2330713a535cdf75b071a5caf3d560a1d962a92` |

The first three shots read clearly at both sizes. The feast improves occupancy but remains modest relative to the painted Kedai backdrop: residents and cup props are small, and a moving, closer meal shot would require a separate directed composition. These screenshots prove native composition only, not animated continuity or moodboard parity. The integrator should select and commit a few of the original captures to `docs/visual/` after merged-source director QA.

## Handoff

Review the action-layer diff, cherry-pick if accepted, and run the combined director QA on main. The Godot/native slot was released after these captures. The focused test file is not yet wired into the project CI runner; include it there if retaining it as a regression gate.
