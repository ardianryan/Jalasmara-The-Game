# Route-aligned gateway candidate

Branch `work/06f-gateway-frame`, based on `f7a3b96`. This is source work, not the active public export. Root owns the combined map wiring, layout migration and release.

The old Hub arch used posts at `(2248,108)` and `(2326,108)`, displaced from the authoritative route at x2295. The Forest arch used a horizontal crossbar across an oblique trail. Roof and sign boxes stayed on global X even if their posts changed. Hub side-fence colliders measured25×110 map pixels, while `_fence` drew their short X dimension.

`createLandGateway` now derives a rigid frame from the physical ground embedding `(x,-y/cos55)`. It intersects the actual painted-road polygon along the physical perpendicular, then places18×18 physical post bases outside the road with at least4 units of clearance. A supplied fixed span must pass the same check. Returned footprints are inverse-mapped into authoritative map coordinates.

Approved placement:

| Gate | Map center | Map post centers | Physical half-span |
| --- | --- | --- | --- |
| Hub | `(2295,135)` | `(2252.5,135)`, `(2337.5,135)` |42.5 |
| Forest | `(159.75,1340.3)` | `(100.3255603,1301.5369854)`, `(219.1744397,1379.0630146)` |89.9916100 |

Root will recenter/taper the Hub terminal paint to52 pixels within the unchanged60-pixel fence opening. Its side-fence colliders stay unchanged. Root will add Forest post obstacles with ids `forest_entry_gate_post_0/1`, variant `gateway_post`, and increment the Forest layout from5 to6. The Forest station is65% along the actual first painted trail `(85,1378)→(200,1320)`; all eight physical base corners fit the existing floor there. Neither portal nor spawn moves.

`GatewayArchitecture3D` places the arch bases, columns, crossbars, roof, sign and lantern in one orthonormal `Node3D` transform. Existing Hub side fences use their real depth and both footprint edges; they no longer leave long invisible roadside walls. Gateway colliders skip generic fence drawing to prevent duplicate geometry. Materials, dimensions and palette retain the existing wood/bamboo/thatch/stone style.

`land.gateways` diagnostics include source road id, crossing endpoints, post footprints and actual emitted box transforms/vertices. Geometry is recorded before static batching; the focused test then checks the rotated roof vertices in the actual material batches.

## Verification at source checkpoint

- Factory/type/test commit: `ad26a6d`.
- Four CPU tests pass via root `tsx --test apps/api/test/gateways.test.ts`. They use the actual Forest road/floor, real radius13 collision functions, Hub fixed colliders, and a pinned legacy92-pixel Hub polygon as a failing alignment baseline. They also reject degenerate routes, off-road centers and insufficient post clearance.
- Targeted TypeScript compilation and `git diff --check` pass.
- Prepared `scripts/tests/gateway-architecture06.gd` checks real emitted architecture, collider footprints, batch preservation, compound side fences and radius13 approach/aperture/exit traversal.
- Prepared `scripts/tests/gateway-architecture06-render.gd` captures six full-world frames with the actual left camera. Output defaults to `artifacts/godot/06f-gateways/`.
- Godot/import/native/browser have not run at this checkpoint: the House lane owns the engine slot. Prepared fixtures are not visual acceptance evidence. The integration runner must register the focused geometry test once root wires map metadata.

No bitmap generation, external paid API or Noxe geometry was used. The geometry is authored in this repository; existing project materials and Godot are retained. Noxe attribution remains limited to the previously ported camera helper. Root still needs combined world/API checks, native inspection and browser traversal before release.
