# Phase 1 return and garden dialogue fidelity — 16 November 2026

This source candidate restores three speaking turns from the owner's Phase 1 screenplay without changing story triggers, the Kedai customer, rewards, calendar time or the six-resonance boss contract. It is local branch `work/phase1-dialogue-fidelity-finish-20261116` based on `9fd056f`; it has not been merged, pushed or released.

| Scene | Change | Presentation consequence |
| --- | --- | --- |
| 0.3, Griya return | After Beno's workshop blast, Nala asks what exploded and why villagers looked dazed; Mbah Wira invites her into Kedai Waras in his own speaking turn. | Prologue now has 12 beats. `CutsceneFrame.gd` keeps beats 6–8 on the Griya dock, then switches to the warm Kedai at beat 9. |
| 2.1, Bu Darmi's raft | A corporate guard explicitly blames Darmi's salt/nutrient calculation and threatens to dismantle the raft between Gito's protest and Ki Lurah's intervention. | Garden crisis now has five beats. The existing server permit remains on the Balai board; the dialogue does not promise an automatic or timed unlock. |
| 3.2, quake | The first shot and Ki Lurah's line place the quake in the morning after the third Kedai night. | This is an explicit adaptation of the owner's dusk scene to the server-owned sleep advance (`apps/api/src/homestead.ts`). The cutscene does not move the calendar or fake a dusk presentation. |
| 4.2, interrupted reload | At 3/6 resonances, an unseen Phase 2 transition now takes priority over an unseen boss intro. | A reload cannot replay the earlier phase over the currently active attack state; local seen flags remain cosmetic and no server reward is changed. |

All twelve sequence IDs remain; the total authored beat count is **50**. The intended old→new map is prologue 1–6 unchanged, old 7→9, 8→10, 9→11 and tutorial 10→12; garden 1–2 unchanged, old Lurah 3→4 and Kinasih 4→5. `CinematicActionLayer.gd` has a separate owner and must apply this same map before the combined native capture. The existing shared `scripts/tests/phase-one-cutscenes.gd` has fixed counts and indices from the 47-beat source; the integrator must update it when merging.

**Checks performed in this worktree:** `git diff --check` passed. A CPU source sanity check found 12 sequences, exactly 50 shot records, and a longest authored dialogue of 174 characters against the existing 180-character limit. New `scripts/tests/phase-one-dialogue-fidelity.gd` checks speaker order, threat content, morning story gate, interrupted 3/6 reload priority and Griya→Kedai backdrop mapping; it has not yet run because the Godot/native slot belongs to the final-action agent. No screenshots, WebGL, device or audio acceptance is claimed here.

**Tools and provenance:** existing Godot 4.7.2 GDScript source, Git, `rg` and Python 3 were used. No raster, external code, generated art or third-party tool output was added. The dialogue adapts the screenplay supplied by the owner in this conversation; Cinetic was not used. The prior [visual review](phase-one-visual-acceptance-2026-11-16.md) still lists separate motion and composition blockers outside this source package.
