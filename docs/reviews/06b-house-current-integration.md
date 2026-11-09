# Seven-house alignment on the current release source

CPU checkpoint, 9 November 2026. Branch `work/06b-house-integration`, worktree `Jalasmara-06-house-integration`, base `f7a3b96c1c129d165b78743f22b9e573535d9158`. This is isolated candidate source, not the staging package. No Godot import, headless engine check, native render, browser or export has run at this checkpoint.

The earlier house candidate was applied as `afbb1c5` → `d1d6ad9` → `34ba78b` (originals `a8d03e6` → `de80e12` → `3ee6bd7`). The only cherry-pick conflict was the already-copied historical review document. Final runtime source uses option B: seven house footprints become orthogonal to the actual map/deck axes while preserving their occupied area, physical-axis aspect, center, height, elevation and identity. Griya's accepted footprint is unchanged. Roof, facade, door, collider and attached shelter geometry still derive from the same emitted footprint through the existing renderer. No assets, runtime, independent model rotation, gate geometry or LandWorld source are added or changed.

The hub becomes layout 10. The shared Ratih/Balai waypoint moves from `(760,350)` to `(760,325)` to preserve real support clearance; the tree remains in its original location. Recovery requires 13 px client clearance; API movement checks retain their existing 12 px rule. The frozen layout-9 migration fixture was compared structurally against `LAND_MAPS.hub` from the current main base and matches exactly, so the old-layout proof still describes the current release geometry.

## Completed CPU evidence

- `npm run typecheck`: exit 0, `.runtime/house-current-typecheck.log`.
- Full `npm test`: **86 passed, zero failed/cancelled/skipped**, exit 0, 29.59 seconds, `.runtime/house-current-full-api.log`.
- Migration geometry covers all 416 old legal grid positions newly occupied by option B, keeps their floor elevation and 13 px clearance, and proves a connected perimeter path to authored routes. Maximum correction remains bounded to 32.001 px.
- Two independent API fixtures each migrate 14 old saves (layout 8 supports/Griya corners and layout 9 house corners), then verify persistence, unchanged player state, reload, stale-save rejection, rejection of the blocked old destination and real legal movement. Ten already-valid old deck saves remain unchanged across the two fixtures.
- Current Main, HomesteadUI and accepted Nala source have no diff from the base. The Balai interaction regression remains registered in the combined world runner. `git diff --check` passes.

Dependencies use an untracked `node_modules` symlink to the existing root installation; it is not part of the candidate. No build/cache duplication was created. API fixtures use their own database/UUID and cleanup; no account owner or deployment data was used.

## Pending engine and gameplay acceptance

The shared engine slot must be explicitly granted before continuing. Follow [the prepared native sequence](06b-house-next-native.md), using this worktree and current source SHA. The combined runner now has **47 checks**, because current main already contains the actual Balai UI regression and this candidate adds the house-frame check. The older sequence's 46-check count predates that integration.

Required next evidence: actual native house/deck axes and collider corners; all seven body/roof coverage and routine routes; complete world suite; the prepared 28 old-layout/current-layout comparison images under the same left camera and day/night conditions; unchanged Griya. Inspect facade, door approach, roof/wall/porch/support seams and framing directly. A CPU rectangle or an unexecuted capture fixture is not visual acceptance.

After native acceptance, the integrator must combine the independent gate lane, repeat route/save checks on that combined manifest, and obtain browser movement/shelter evidence from a separately pinned package. The existing public startup transport issue remains separate. No layout-10 release or broad comfy finishing claim is made here.
