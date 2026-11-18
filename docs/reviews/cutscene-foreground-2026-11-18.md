# Phase 1 foreground focal shots — 18 November 2026

The garden staff confrontation and Balai quake council remained difficult to read at the game's native 667×375 size after the previous blocking pass. This candidate gives Ki Lurah a foreground full-body silhouette in each shot. In the garden he walks a short distance to the staff mark and plants it on the deck. In the council he stands slightly forward of four residents, whose existing sprites are scaled enough to read as people around the map. Their feet remain on the painted floor; the upper title and lower dialogue stay clear. All other beats retain their earlier composition.

The change reuses project-owned 64×64 facing sprites and scripted Godot drawing. It adds no generated sheet, external art, runtime dependency, story gate, physics, reward, or dialogue change. The portrait in the dialogue box remains a separate speaker close-up. This is a focal-composition improvement, not full cinematic moodboard parity; other residents and many screenplay shots still need authored animation and browser/device review.

## Native evidence

Godot 4.7.2 Compatibility on Apple M2 rendered the source-exact shots at **667×375** and **844×390**. The native fixture passed **90 focal size/layout checks** and saved **122 captures** including three motion points for both edited beats. The clean second editor import and native run contained no `SCRIPT ERROR`, `ERROR:`, or parse error. Both edits were reviewed at t0/t1/t2 at both sizes. Ki Lurah's visible full-body height is about 125 px at 667×375, versus the previous roughly 95 px focal staging; his feet stay above the dialogue panel. The garden guards remain behind him, and Balai's supporting figures remain separate silhouettes around the map.

Curated exact-frame PNGs:

| Beat | 667×375 | 844×390 |
| --- | --- | --- |
| Garden Lurah | [native frame](../visual/cutscene-foreground-20261118/garden-lurah-667x375.png) (`ec860c40e3bb095177436713bb1dedeadce1244d175bdbd23eab89fe493598fa`) | [native frame](../visual/cutscene-foreground-20261118/garden-lurah-844x390.png) (`dd03c9e2f540fc40d3fc09f1716368018e216d2af9fa70db7c53f569ec4f036a`) |
| Balai council | [native frame](../visual/cutscene-foreground-20261118/balai-council-667x375.png) (`fd3d84c820fde04cfb147619712fbe5a94656dd7331fb078d67792c2edf32f22`) | [native frame](../visual/cutscene-foreground-20261118/balai-council-844x390.png) (`f9cf90ac575c90af74d528fe8dc9a4782582e5c96f24ffc62c929a83a245c694`) |

The full raw motion frames remain under the ignored `artifacts/godot/phase-one-character-closeup/` directory in the local worktree. The fixture now includes garden beat 4 in its representative 17-beat capture set, tests the garden entrance/settled feet and the Balai floor marks, and enforces a 115–145 px foreground ink-height band for these two Lurah shots. `git diff --check` passed. The integrator still needs combined repo checks and real browser playback on Windows/Android; these native stills do not prove motion smoothness or device performance.

Source base: `main` `a22da5f`; candidate branch: `work/cutscene-foreground-20261118`. Commit, integration, CI, and staging status must be recorded by the integrator after review. No moodboard image was distributed or used as a texture.
