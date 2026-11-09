# House alignment candidate, layout 10

Branch `work/06b-house-alignment`, worktree `Jalasmara-06-house-alignment`, base `0e31988`. This is the next isolated package, **not part of the current release and not accepted for integration**. No engine or browser has run for this candidate yet.

## Scope and source dependency

Seven hub buildings retain the skew originally baked into their map footprints. `LandWorld3D._house` constructs its local frame from those same edges, preserving their nonorthogonal angle. The left camera should reveal actual volume; it should not be countered with an extra fake-isometric footprint.

| Existing ID | Actual embedded axis angle before | Orthogonal target |
| --- | ---: | ---: |
| `kedai_waras` | 92.256° | 90° |
| `galangan_beno` | 94.474° | 90° |
| `pos_cakrawala` | 98.661° | 90° |
| `balai_lurah` | 96.165° | 90° |
| `rumah_ratih` | 86.086° | 90° |
| `rumah_sari` | 86.086° | 90° |
| `rumah_tedi` | 86.834° | 90° |

Griya already measures 90° and retains its accepted deck footprint. Forest hut geometry is outside this bounded hub change. No character, camera, identity, new building or director substitution is involved.

The shared footprint is the source of the collider and rendered house frame. All `_house_parts` walls, floors, roofs, doorposts, windows and lanterns inherit that frame. `attachedShelter` then derives its roof and support coordinates from the same footprint; `ShelterArchitecture3D` consumes those coordinates. Independent mesh rotations would break this contract. The change therefore belongs in `packages/shared/src/land.ts`, with the one related commute update in `village.ts`; the existing renderer needs no second transform implementation.

`hubRoutes[11]` and Ratih's matching commute must replace `(760,350)` with `(760,325)`. Otherwise the new Balai post intersects both adjoining route segments. The surface path decoration is derived from the route. Work/rest/shelter service anchors, portal, dive point and home door remain at their existing coordinates. Walkable floor polygons and stair geometry remain unchanged.

## Two bounded geometry options

**Checkpoint A, full old bounding boxes:** keep old manifest x/y/width/depth and replace the skew polygon with a rectangle. This makes the physical occupied area **52.35% larger**, despite preserving the old bounding box and center. It also requires moving `hub_margin_tree_0` from `(340,390)` to `(330,405)` to keep 28 px clear of the new Ratih support. It is an investigated checkpoint, not the preferred final solution.

**Option B, preserve physical area and aspect:** embed old footprint axes with the unchanged mapping `(x, -y/cos(55°))`. Let their physical area be `A = abs(cross(a,b))` and aspect `r = length(a)/length(b)`. Use width `sqrt(A*r)` and physical depth `sqrt(A/r)`, converting depth back to logical map units with `cos(55°)`. Center, height and elevation remain fixed. This removes shear while preserving the original occupied area and aspect; it also keeps the old tree position legal.

| ID | Option B logical width × depth |
| --- | ---: |
| Kedai | 345.817 × 132.868 |
| Beno | 361.210 × 129.750 |
| Corporate post | 255.333 × 80.979 |
| Balai | 325.471 × 111.124 |
| Ratih / Sari | 201.726 × 93.550 |
| Tedi | 148.838 × 67.475 |

The CPU comparison uses frozen layout 9, all seven NPC profiles, unchanged shelter reaches and the corrected shared waypoint. Both options keep 21 work/rest/shelter anchors legal and fit 336 body-plan samples beneath actual roof plans. All authored route edges pass 13 px clearance. On an 8 px grid near the seven old house bounds, newly blocked positions fall from **1,685 in A to 416 in B**; this comparison keeps the old tree unchanged in both transient maps. The implemented checkpoint A has four additional affected samples due to moving the tree, for 1,689 in its migration test. Native size, facade, door and roof acceptance remains mandatory for either option. Option B is recommended; its runtime implementation has not yet replaced checkpoint A in this commit.

## Checkpoint A migration and CPU/API evidence

Layout is incremented to **10**. Do not rewrite public/candidate layout 9 in place. The frozen authoritative fixture `apps/api/test/fixtures/hub-layout9.json` comes from base `0e31988` and has SHA-256 `b393dac4f9a8514802a74837bc78e9d001aca0eac231ca775f89b48915c7b046`. Tests reconstruct the earlier Griya/support layout 8 from that fixed layout 9, rather than deriving historical geometry from the new map.

The recovery helper uses 13 px clearance, matching `LandCollision.WALK_CLEARANCE`. The existing API path validation still uses its existing 12 px body margin. A preliminary probe found that 460 recoveries selected with the old 12 px helper would be unusable by the actual 13 px client. The helper change addresses recovery only and does not relax movement, routing or obstacle validation.

Completed CPU/API checks on checkpoint A:

- Three geometry/route/migration tests pass. **1,689** previously legal layout 9 positions recover to client-clear points on their original real floor elevation, with a sampled 13 px perimeter path to an authored front route. Maximum correction is 160 px; no reset to spawn is accepted. Connectivity uses local flood traversal and checked segments, rather than accepting the first radial walkable point as proof.
- Existing shelter/source checks plus the new tests pass **9/9**. Two independent database/UUID fixtures exercise **13 layout 8 saves** and **14 layout 9 saves**, with migration, unchanged player/economy, reload, stale timestamp rejection, blocked old destination rejection and legal post-migration movement. Each fixture also preserves five old deck positions. The 14 layout 9 cases cover two newly blocked corners of each changed house.
- The first expanded API fixture hit HTTP429 because the combined cases exceeded the unchanged production 180 requests/minute limit. Splitting the two old-layout cases into independent fixtures resolved the test setup problem; no production limiter was changed or disabled.
- An earlier support count assertion expected 49 from the previous geometry. The frozen old map proves 45 of the new support-offset samples were legal there; the other five intersect its old Ratih tree/floor clearance. Exact expected coverage is updated for the changed layout, without relaxing path/body tolerances.

Evidence: `.runtime/house-layout10-api.log`, `.runtime/house-layout10-cpu.log`, `.runtime/house-alignment-options.json`. Tools used are Node/TypeScript, Fastify injection, isolated MongoDB/Redis fixtures and Git. Original geometry code only; existing Noxe camera attribution is unchanged, with no new library or artwork.

## Remaining acceptance, in order

1. Implement and compare option B while preserving checkpoint A and its results. Update legacy migration samples to positions genuinely blocked by B; do not keep A's test points if they remain legal in B.
2. Run complete typecheck and API suite after final source selection. `npm test` includes the new geometry tests. No full-suite result is claimed from the focused nine checks.
3. Obtain the shared engine slot. Run the new `hub-house-alignment.gd` (registered in the world runner), existing 336-sample roof/cutaway test, real NPC commute routine and complete world suite. The new native source fixture checks eight actual house frames, 32 transformed footprint/collider corners, five roof plans and ten supports; it is prepared, not yet executed.
4. Capture before/after from the default left camera: service facade/door access, side depth, roof/support joins and night lamps. Check actual player movement around each changed footprint and all seven rain destinations. Do not accept source orthogonality alone as visual evidence.
5. Have the integrator review the candidate as a separate package. Export/browser/release only after combined route, API, migration, native and gameplay checks. The current release package must not acquire layout 10 accidentally.
