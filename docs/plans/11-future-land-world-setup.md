# Future land-world setup: corporate power, Saras's field camp, northern forest

**Status:** placement and integration contract, 16 November 2026. Thirteen original reusable assets and their editable generator are prepared in [future-world props v1](../assets/future-world-props-v1.md). A [CPU connected-floor survey](../reviews/future-camp-connected-floor-survey-2026-11-16.md) proposes locations for Saras's tent, Raka's separate quarters and the director's generator; these remain provisional until native silhouette and route review. Placement and activation remain later work. This document changes no playable map, character, mission, reward or Phase 1 cutscene. Narrative details of the later conflict have not been written.

## Canon and existing surfaces

The director and Inspector Raka are different people. The director already has a static, non-drivable `rumah_direktur` container/RV near the corporate ridge (hub footprint approximately x=1715–1825, y=135–205, door at 1770,240). Raka's `pos_cakrawala` is a separate inspection office around x=1840–2140, y=140–245; the office does **not** establish that he already has a residence. Preserve both NPC identities, office service, door, schedule, and access. Do not turn the director's RV into Raka's home or rename Raka as the director.

Saras currently appears from story cycle 2, works around hub x=1480,y=680, and visits Kedai by her existing route. Her Phase 1 archaeology/prasasti dialogue and discoveries remain canonical. Her future identity adds strong IT, communications and digital-evidence skills to that research background; it does not retroactively remove her field archaeology or alter Phase 1 progression. A future title and dialogue change needs a distinct content review.

`forest_hulu` is already `coming_soon`. The northward forest route ends at `landslide_north` (forest blocker around x=1080–1320,y=155–245); `bridge_east` and the southeastern `gate_east` are separate exits. The northern frontier is the intended future plantation area. The existing Phase 1 forest floor, tree cover, route, discoveries, and blockers must remain intact until a server-owned later-phase transition is designed and tested.

## Spatial authoring brief

| Site | Prepared design | Placement and continuity constraints |
| --- | --- | --- |
| Director's RV | A roof-mounted, legible solar-panel array and an external generator cabinet/set, with cable runs and warm powered windows or work light. Its metal/container silhouette remains distinct from village houses. | Attach to the existing RV roof and a surveyed clear pad beside it. Keep generator, cables, exhaust and light outside the validated doorway/route and away from the inspection office trigger. The RV stays static. |
| Raka's temporary quarters | A **separate** small temporary cabin or bunk container for the inspector, likewise with solar panels and a generator. The existing `pos_cakrawala` remains his workplace. | Survey a clear connected location in the corporate ridge; reserve a distinct footprint and doorway only after checking road, slope, neighboring RV/office, NPC path and server collision. Do not assign a final coordinate from a screenshot alone. |
| Saras's field camp | A weatherproof research tent, a visibly mounted satellite-internet dish/terminal (Starlink in the brief), compact worktable, laptop/rugged terminal, antenna/cables, sample/evidence storage, and room for later phase-specific devices. | Survey near Saras's existing research route and a clear view of the sky. Keep the tent footprint off her standing point, road, garden, portals and other actors. The dish silhouette must be readable at 667×375; avoid a third-party logo or product image unless distribution rights are documented. |
| Northern Hulu Wringin frontier | Preserve an intact-forest baseline, terrain/watercourse continuity, and a blocked sightline to the next area. Future art states may depict corporate damage and an oil-palm plantation after the relevant story beat. | Keep the north blocker and `coming_soon` status through Phase 1. Never turn existing forest trees into palms through a cosmetic clock change; later transformation needs an authored state, server gating, route/collider review, save migration and environmental continuity. |

Use the current 3/4 camera and nearest-neighbor pixel presentation. Power props need clear mass and attachment rather than tiny high-frequency roof noise. Keep nighttime lighting warm and readable under the comfy grade, while the corporate materials remain recognizably different. Decorative lights, fans and indicator LEDs may be client-side, but generator fuel, power availability, network connectivity, evidence access or hacking cannot become gameplay facts without an authoritative server contract. Reduced-motion settings must calm moving props and lights without hiding their meaning.

## Authored asset handoff

Prepare original, isolated transparent PNGs under `client-godot/resources/art/future-world-v1/`, with a JSON manifest carrying source-pixel canvas, bottom-center pivot, intended site, provenance and activation gate. These canvas sizes are authoring bounds, **not** world-unit footprint or collider dimensions. All placement goes through a later shared map/renderer package after a connected-floor survey.

| Asset | Suggested canvas and pivot | Intended activation |
| --- | --- | --- |
| `solar_panel_roof.png` | 64×32; (32,31), repeatable roof array | Corporate power-prop package for RV and Raka's separate cabin |
| `generator_set.png` | 64×48; (32,47) | Same; free-standing surveyed pad |
| `inspector_bunk_container.png` | 128×96; (64,95) | Raka's separate temporary residence, not the office |
| `saras_field_tent.png` | 128×96; (64,95) | Saras camp package after location/content review |
| `saras_satellite_terminal.png` | 64×64; (32,63) | Camp equipment; recognizable satellite terminal without third-party logo |
| `saras_worktable.png`, `saras_rugged_laptop.png`, `saras_evidence_case.png`, `saras_antenna.png` | 32×32 or 64×48; bottom-center | Separate camp pieces that later phases can add without replacing the tent |
| `oil_palm_mature.png` | 96×128; (48,127) | Future plantation state beyond northern blocker |
| `forest_charred_trunk.png` | 64×96; (32,95) | Future damaged-forest state only |
| `forest_fire_sheet.png` | Four 64×64 frames; bottom-center per cell | Future fire state only; never active in Phase 1 |
| `forest_smoke_sheet.png` | Four 64×64 frames; bottom-center per cell | Future fire/smoke state only; calm first frame for reduced motion |

The native game should import these with nearest filtering and stable alpha. A manifest entry marked `future_only` does not imply a runtime loader, a rendered object or a playable phase gate; the integrating package must explicitly map each entry into the world after review. A later forest transformation must distinguish intact forest, damaged forest, and planted palms rather than simply layering palms over burned trees.

## Phased implementation and acceptance

1. **Survey and layout proposal.** Capture hub/forest in daylight, dusk and rain at 667×375 and 844×390; record exact current footprint, door, NPC route and blocker coordinates from `packages/shared/src/land.ts`, `world.ts` and `village.ts`. Propose Raka's quarters and Saras's tent on connected, legal floor without touching the existing service points. Review the silhouette before placing new colliders.
2. **Authored asset package now.** Produce the pieces and manifest above in isolation, then review actual pixels and provenance. Keep the source/editable form, tool, license and any brand rights in asset provenance and `THIRD_PARTY_LICENSES.md` where applicable. This package prepares art only; Phase 1 scenery can show a limited camp only after the content gate is settled, and no future event is preplayed.
3. **World/character integration.** Add shared manifest footprints, steps/doors and grounded render transforms together, then give Raka a distinct rest destination and Saras a reachable work site. Preserve director's current route and Phase 1 dialogue. If footprints alter old legal positions, bump the layout version and migrate only displaced saves to the nearest connected floor. Test old saves, service interaction, commute, nighttime shelter and camera occlusion.
4. **Later-phase world state.** Define an explicit server-owned milestone for entering the north and, separately, for any forest-to-plantation change. Keep the intact forest as the pre-event state. Design the Nala–Saras collaboration and scientific/evidence mechanics only when the story and server contract are approved; no invented fire mission, reward, or time skip in this package.
5. **Release gate.** Run world checks, typecheck, tests, Godot import/native review and web build; inspect actual-size moving frames and physical Windows/S23 performance before declaring visual acceptance. Stage only an exact GitHub CI artifact with backup, rollback and public smoke. A documentation commit alone does not alter staging.

## Decisions held open

- The inspector's residential footprint and Saras's camp footprint require a connected-floor survey; their coordinates and interior access are uncommitted.
- Whether the director and inspector power systems are purely visual or later have resource mechanics is undecided.
- The detailed sequence, timing and consequences of the future forest fire and plantation, including Saras's digital-evidence work, are deferred to the next story design. Phase 1 already playable content and its ending stay unchanged.
