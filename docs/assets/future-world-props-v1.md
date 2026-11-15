# Future land-world props v1

Thirteen original, transparent, nearest-neighbor pixel sprites are in [`client-godot/resources/art/future-world-v1/`](../../client-godot/resources/art/future-world-v1/). Their exact source canvases, bottom-center pivots, frame sizes, sites, gates and SHA-256 hashes are in [`manifest.json`](../../client-godot/resources/art/future-world-v1/manifest.json). The PNGs are all-rights-reserved Jalasmara game art under [LICENSE §2](../../LICENSE); the reproducible Python drawing code is MIT under §1. No third-party sprites, logos or generated images were copied. Pillow 11.3.0 performed offline rasterization only.

| Asset family | Source canvas | Use after integration |
| --- | --- | --- |
| `solar_panel_roof`, `generator_set` | 64×32, 64×48 | Modular electricity props for the director's existing RV and the inspector's separate quarters |
| `inspector_bunk_container` | 128×96 | Raka's future residence, distinct from his current office and the director's RV |
| `saras_field_tent`, `saras_satellite_terminal` | 128×96, 64×64 | Research shelter and brand-free satellite link |
| `saras_worktable`, `saras_rugged_laptop`, `saras_evidence_case`, `saras_antenna` | 64×48, 32×32, 32×32, 32×48 | Separate, additive field equipment for later phases |
| `oil_palm_mature`, `forest_charred_trunk` | 96×128, 64×96 | Future plantation and damaged-forest states north of the blocked route |
| `forest_fire_sheet`, `forest_smoke_sheet` | Four 64×64 frames per sheet | Future hazard art; frame zero is a valid static reduced-motion pose |

The 3/4 shapes use deep plum/blue shadows, copper highlights, sand canvas and teal electronics. Roof panels intentionally have attachment legs; the container has roof points for independent repeated modules. The oil palm has a scarred trunk, radial feather-leaf crown and orange fruit bunches to distinguish it from the coastal coconut. All runtime PNG backgrounds are fully transparent; checkerboard appears only in the [contact sheet](../visual/future-world-props-v1-20261115.png). No source canvas defines a collider or footprint in world units.

`python3 tools/future-world-art/generate.py` reproduces the assets. `python3 tools/future-world-art/test_assets.py` validates hashes, alpha, dimensions, pivots, gate state and frame uniqueness. The assets are **unplaced**. The approved [future world brief](../plans/11-future-land-world-setup.md) requires a connected-floor survey and later renderer/manifest integration; the northern fire and plantation need an explicit server-owned phase transition. The source art does not change the Phase 1 story, schedules or rendered scene.
