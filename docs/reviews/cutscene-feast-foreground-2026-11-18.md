# Phase 1 feast foreground and 16-scene native audit — 18 November 2026

The Kedai Waras confrontation still showed its residents as a row of small figures behind Ki Lurah and Raka. The earlier [667×375 close-up proof](../visual/phase-one-closeup-20261118/epilogue-feast-667x375.webp) is the historical baseline (source `76fb375`, not a same-SHA A/B). At source `ab70368`, the six feast residents still used a 1.70 actor scale. This candidate makes Mbok Ratih and Kang Tedi a distinct foreground witness pair at 2.45 scale, with a short, bounded entrance and settled feet on the painted floor. Bu Darmi, Mang Ujang, Yu Sari, and Beno remain on a second row. The dialogue, story, server authority, rewards, skip control and other beats are unchanged.

The native test captured the following representative frames for all sixteen numbered screenplay scenes at both **667×375** and **844×390**, three motion points each. I inspected every listed t2 frame at both sizes, and feast 4.5 at t0/t1/t2 at both sizes. A frame is evidence of composition, not proof of moving browser pacing.

| Scene | Native representative | Original-size finding |
| --- | --- | --- |
| 0.1, harbor lesson | `prologue-01` | Lurah readable; five children remain small in the wide diorama. |
| 0.2, capsule pitch | `prologue-04` | Raka readable on ship; receiving crowd remains small. |
| 0.3, Griya return | `prologue-06` | Nala and Beno silhouettes legible on boat/dock. |
| 0.4, inherited net | `prologue-09` | Three adults legible in Kedai; tool handoff remains limited. |
| 1.1, first dive | `first_dive-01` | Nala reads against open water; water-entry timing still needs moving review. |
| 1.2, first recovery | `first_service-01` | Pak Ranto cut-in is readable; present service adaptation differs from the requested first-customer script. |
| 2.1, garden crisis | `garden_crisis-02` plus prior beat 4 proof | Children/guards separate, foreground Lurah legible in beat 4. |
| 2.2, Saras's visit | `saras_visit-02` | Saras legible; prism handoff is small. |
| 3.1, cave warning | `cave_warning-02` | Pipe and plume clear; radio speaker has no full-body stage actor. |
| 3.2, Balai quake | `earthquake-01` | Foreground Lurah legible; council remains smaller in depth. |
| 4.1, boss reveal | `boss_intro-01` | Gajah Mina dominates the frame; Nala is communicated by radio portrait. |
| 4.2, phase change | `boss_phase_two-01` | Boss and pipe joint read; fracture motion needs moving review. |
| 4.3, purification | `victory-01` | Boss/net source reads; swimming Nala is small beside the boss. |
| 4.4, village return | `victory-03` | Dock ensemble grounded; five children remain small in the wide shot. |
| 4.5, Raka and feast | `epilogue-02` | **Changed here:** Ratih/Tedi are full-body foreground witnesses between Lurah and the smaller back row; no title/dialogue collision. |
| 4.6, abisal teaser | `epilogue-04` | Saras and projection readable; Bagas remains small at the map room side. |

## Exact-size evidence and verification

| Motion point | 667×375 | 844×390 |
| --- | --- | --- |
| Entry | [PNG](../visual/cutscene-feast-foreground-20261118/feast-entry-667x375.png) SHA-256 `ee31a5835a5bb3e82d3203d3159a733667191f90cf549fbc9708a88699086276` | [PNG](../visual/cutscene-feast-foreground-20261118/feast-entry-844x390.png) `3840f60f5a5d9189e59a8ff2f23e05ba91c49cad368c3b0299c132824fd54bfb` |
| Settled | [PNG](../visual/cutscene-feast-foreground-20261118/feast-settled-667x375.png) `129d8e9a3d23f5da74291b8cbddb195255f421acbf0b6ed80b1a9069df2d76ac` | [PNG](../visual/cutscene-feast-foreground-20261118/feast-settled-844x390.png) `8a5d612bfe42c2552fe3b50c8634f5564c6cc408dff21723892d9f3b4298ada3` |

Godot 4.7.2 Compatibility on Apple M2: final clean editor import and native run passed **166 focal size/layout checks** and **308 capture events**, with no `SCRIPT ERROR`, `ERROR:`, or parse error in the final logs. The first local import/run did expose my `stand_t` scope mistake after refactoring the feast branch; it was corrected before the final clean import and native capture. The dedicated fixture now checks the two witness entrance distances, settled floor, 90–110 px opaque height and title/dialogue clearance. `git diff --check` passed. Untracked Godot `.import`/`.uid` outputs are not package files.

The original character atlases, painted Kedai plate and code-driven drawing are the only art inputs. No moodboard bitmap, external dependency, generator output or third-party tool was introduced. The remaining small figures in wide shots, the finer choreography and real Windows/Samsung S23 motion remain open. This branch is a local source candidate only, not merged, pushed, released or staged. The integrator owns combined checks and acceptance.
