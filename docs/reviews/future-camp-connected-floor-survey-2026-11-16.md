# Future camp and corporate quarters: connected-floor source survey

**Status:** CPU/source proposal on `work/future-camp-layout-20261116`, based on `be58e0b` (16 November 2026). No runtime, authoritative map, NPC schedule, phase gate, export or staging change was made. Native camera and browser evidence remain required before any placement is accepted.

The owner asked us to retain Saras's field IT camp, a powered director residence, Raka's separate quarters, and assets for the later northern forest. The [world brief](../plans/11-future-land-world-setup.md) and [13-piece asset manifest](../../client-godot/resources/art/future-world-v1/manifest.json) already hold original art. Every PNG in that set remains **unplaced**; `future_only` palms, charred trunks, flame and smoke are not an active Phase 1 event. The artwork is project-owned under `LICENSE` §2 and reproducible from the MIT-licensed Python authoring code in `tools/future-world-art/`; Pillow 11.3.0 was used for the original raster package. This survey used only Node 26.12.1 and the shared TypeScript map helpers. It imported no third-party scenery or reference image.

## Existing geometry and character contract

`packages/shared/src/land.ts` defines the hub at layout version 11. The director's `rumah_direktur` is a distinct 110×70 world-unit RV footprint, x=1715–1825/y=135–205 on elevation 3, with a door at (1770,240). Its existing serambi extends south of the house. `LandWorld3D.gd` already builds a **primitive** `DirectorRVSolarPanel` on the flat roof; the authored `solar_panel_roof.png` would refine or replace that element, not introduce the first panel. Raka's work site is the separate `pos_cakrawala` office (actual aligned footprint x≈1862.3–2117.7/y≈152.0–233.0), with district interaction at (1950,300). Raka is currently a district actor with idle micro-motion, not a scheduled `VILLAGE_RESIDENTS` entry. A bunk cannot imply he already commutes home; a later `districtActivities`/route package must create and validate that behavior.

Saras's authored work point is (1480,680), current commute runs through (1350,635), (900,650), (900,350), (940,310) to rest at (1020,310), and her title/dialogue remain Phase 1 maritime archaeology. The proposed camp must preserve those facts. The northern `landslide_north` blocker spans x=1080–1320/y=155–245 on the separate forest map; `WORLD.atlas.regions[forest_hulu].status` is `coming_soon`. The eastern bridge and gate are other blocked exits, not a substitute for the north route.

## Provisional footprints in hub world units

| Reservation | Proposed rectangle and elevation | Existing access and limits |
| --- | --- | --- |
| Saras tent | x=1530–1620, y=610–655; upper court/elevation 2 | Front access at (1575,585) via (1480,680) → (1490,590) → (1575,585). The footprint stays about 56 units from Saras's present work point and at least 29.6 units from the authored hub route. A nearby tree trunk begins at y=675, leaving only 20 units between trunk and proposed tent. Check canopy/roof occlusion at native 3/4 view. Equipment needs its own surveyed pads or verified tent attachment. |
| Raka bunk container | x=2145–2220, y=165–225; ridge/elevation 3 | Front access at (2182.5,250) via office (1950,300) → (2180,300) → (2182.5,250). The footprint starts about 27 units beyond the office collider, ends 20 units before the west gate post, and lies 20 units below a tree trunk. Its source art canvas of 128×96 pixels does not determine this world footprint. Actual roof/eave silhouette may still be too tight. |
| Director generator | x=1690–1720, y=280–302; ridge/elevation 3 | This is southwest of the RV, approximately 17 units beyond the serambi's outer roof line at y≈263, clear of the director's door and the (1770,310) path. Route, cable/vent direction and warm light need native review; no power or fuel mechanic is implied. |

These are **reservation candidates**, not finalized collision dimensions. The solar panel must attach to the existing RV roof transform so that its 3/4 angle matches the container. A separate Raka roof panel/generator must be attached to the bunk only if the reviewed silhouette has room. The brand-free satellite terminal, worktable, laptop, antenna and evidence case should be layered into Saras's research site only after equipment pads, camera occlusion, rain cover and route margins are checked; no Starlink logo is included. Later Nala–Saras digital-evidence mechanics need their own story and server contract.

## Reproducible CPU gate

`node --experimental-strip-types tools/future-world-art/survey_layout.mjs` returned:

```json
{"reservations":{"saras_tent":[1530,610,90,45],"raka_quarters":[2145,165,75,60],"director_generator":[1690,280,30,22]},"existingSegments":59,"accessPaths":4,"forestHulu":"coming_soon"}
```

The fixture samples every reserved rectangle at ≤4-unit spacing with a 9-unit clear-floor margin, temporarily adds all three rectangular obstacles, verifies all **59/59** existing hub route segments still pass `isLandSegmentWalkable(..., 13)`, checks four access routes, keeps six existing work/service/gate/landmark points walkable, and asserts the northern atlas gate stays closed. `python3 tools/future-world-art/test_assets.py` also passed **2/2** asset checks. This is source geometry evidence only: it cannot establish camera silhouette, door animation, 3D footing, NPC pathfinding under dynamic motion, server save migration, mobile performance, or playable access.

## Integration gate for a later package

1. Inspect actual-size daylight, dusk and rain at 667×375 and 844×390, including overlapping roofs, canopies and the gate. If the tent or bunk reads as packed against its neighbors, select another footprint and rerun the CPU fixture before building colliders.
2. Integrate any accepted footprints in the shared map **and** grounded Godot renderer with a layout-version bump and connected-floor save migration. The API imports this same shared world; a client-only decorative collider would desynchronize authoritative movement. Protect the existing director door, Raka office service, Saras work/commute, garden landmarks and forest gate.
3. Add Raka's rest destination explicitly without renaming him or moving the director. Keep Saras's Phase 1 archaeology role and existing schedule unless a separate content pass approves a new work pattern. Verify schedule movement, dialogue reach, old saves and rain shelter after placement.
4. Keep `forest_hulu` closed and the Phase 1 forest intact. Future palm, charred trunk, flame and smoke art requires a server-owned later-phase state, environmental continuity and a separate content review. A visual-only prop must not silently activate fire, plantation or rewards.
5. Repeat world/type/API/build checks and native/browser review, then GitHub CI delivery and separate staging gates. This survey commit does not appear in the game by itself.
