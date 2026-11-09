# Local gates and canopy acceptance — 5f5baf24 candidate

Status: local actual Chromium/WebGL acceptance. This report does not establish public HTTP/2 startup or physical Windows/Samsung S23 performance.

## Package and execution

Served from `http://localhost:3101`, root combined worktree `Jalasmara-06-buildings-gates`. Required HTTP PCK SHA-256 `5f5baf243a3bf941cf34fab6c143bb9cf2bc8d65997ded6ed4e048b929353f96`, decoded size 64,333,184 bytes; the harness verified both before inserting each UUID fixture. Runtime was frozen while root worked on source/CI without GPU. Browser navigation used actual screen-relative land motion, physical routes and keyboard/touch input; no runtime teleports, owner accounts or mocked API/game states.

The first shell invocation omitted `--import tsx` and failed import resolution before creating a fixture or launching a browser. The corrected invocation is shown below.

## First gateway run and bounded harness correction

UUID `2f9676af-7002-4762-8542-33834a6112cb` attached the actual hub but failed the metadata comparison before walking: Godot JSON serialized `140.1621879271594` as `140.162187927159`. The 4e-13-unit difference was a harness precision issue, not a geometry discrepancy. Own fixture cleanup passed. Artifact: `artifacts/browser/plan06-layout-2f9676af-7002-4762-8542-33834a6112cb/results.json` in the combined worktree.

Commit `d1b575b` (root integration `92c9b2e`) compares nested numeric coordinates with tolerance below 1e-7 map units, preserving exact array shape and collider IDs. Its seven CPU tests pass, including a 15-significant-digit Godot-style roundtrip, rejection of a 0.001-unit altered footprint corner and rejection of a changed collider ID. No product source or route/collision threshold changed.

## Gateway actual rerun

UUID `5267afcf-4517-444e-a1ab-2b730aa08cab`: **7/7 checks passed**, 113,287 ms route, 149 actual matrix input pulses, zero legacy pulses, 65 surface-position POSTs acknowledged with HTTP 200, zero console/API errors or 409s. Own player, receipts, shifts, Redis state and verified session were removed; `outcome=completed`, cleanup true.

Both hub and forest gateways were physically crossed forward and backward through the authored aperture. Runtime emitted mesh axes/base vertices were compared against authoritative post geometry. Sustained inward input approached and stopped at each actual post with body clearance; the player escaped along validated floor and received a position/version acknowledgement. Actual E travel entered the forest, and a reload restored its saved floor position, preserving coins/inventory/story and the 36-minute calendar.

Useful evidence under `artifacts/browser/plan06-layout-5267afcf-4517-444e-a1ab-2b730aa08cab/`:

- `hub-gateway-before-aperture.png`, `hub-gateway-inside-aperture.png`, `hub-gateway-after-aperture.png`.
- `hub-gateway-post-body-blocked.png`, `hub-gateway-post-recovered-and-acknowledged.png`.
- Forest equivalents and `gateways-forest-save-reload-keeps-real-floor-position.png`.
- `results.json` records coordinates, emitted vertices, held-input samples and actual request/ACK ledger.

Visual review: the forest supports bracket the clear passage and the roof follows the authored road frame. At the hub a foreground palm partially masks the aperture in the night view; this screenshot alone cannot prove collision/alignment, which is why the input/mesh evidence is retained. HUD and round joystick stay compact with visible action space.

## Canopy run

UUID `e1bf6558-d625-4fae-ae32-ca166ddd23fd`: **4/4 checks passed**, 42,527 ms route, 40 actual matrix pulses, zero legacy pulses, 15 surface-position POST200 acknowledgements, zero console/API errors or 409s. Own fixture cleanup passed and `outcome=completed`.

The player physically reached `(142.956832885742,1212.57116699219)` from the authored forest spawn. Target selection used actual atlas alpha/camera/world metadata: crown index 46 (`renderer_forest_border_3`) among 47 crowns, atlas SHA `1f07437f9ff5f9cbc063c191904eecf734ffad859b3daf6f0fccf177c8aa4564`. Localized reveal amount >0.99 and untouched trunk assertions passed. A real 667×375 touch opened the journal and paused movement; closing it resumed movement. The player walked back to `(199.348724365234,1317.55883789062)`, the foreground crown restored to zero reveals, a real save acknowledged the position and a reload restored that same location. Coins, inventory, story and calendar stayed intact.

Evidence under `artifacts/browser/plan06-layout-e1bf6558-d625-4fae-ae32-ca166ddd23fd/` includes `focused-canopy-667x375.png`, `focused-canopy-touch-journal-pauses-movement.png`, `focused-canopy-entrance-crown-restored.png`, `focused-canopy-physical-position-restored-after-reload.png` and the full `results.json` ledger.

Visual review: Nala is visible through only the covering foreground foliage while the trunk remains opaque. Controls are compact and usable at 667×375. The host Menu button nearly touches the left plaque edge in this viewport; no blocked action was observed, but this is a small remaining visual crowding point. These focused modes do not repeat the earlier full-night/shifts, seven-resident, house interior or public-stage acceptance.
## Reproduce

```sh
APP_TEST_ORIGIN=http://localhost:3101 \
PLAN06_ROUTE_MODE=gateways \
PLAN06_EXPECT_PCK=5f5baf243a3bf941cf34fab6c143bb9cf2bc8d65997ded6ed4e048b929353f96 \
PLAN06_EXPECT_PCK_BYTES=64333184 \
node --import tsx scripts/plan06-layout-browser.mjs
```

Use `PLAN06_ROUTE_MODE=canopy` separately. Every run creates and cleans its own fixture. Pin values apply only to this candidate, not to a later export.
