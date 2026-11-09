# Export3 local left-view acceptance: partial, budget exhausted

The actual browser reached the forest through the hub gate, but the full left-view flow **failed its five-minute harness budget** before the forest joystick, upper bridge and reload checks. This is not a complete route PASS or evidence of a product collision failure. The first failure and successful prefix are preserved; no retry or public staging run was started.

## Package and execution

- Origin: `http://localhost:3111`, root-owned preview; no restart, build or API/source mutation by this lane.
- Export source: `b0f2ef84cc06a404ed12d1311644e106f4a5afe6`.
- Root full-world CI/source reference: `3af35a6`,63/63 in146978ms, reported separately by the integrator. `git diff 3af35a6 b0f2ef8 -- client-godot/scripts client-godot/scenes apps/api/src apps/web/src` was empty. This browser run does not replace that suite or claim a CI run on generated export files.
- PCK SHA256: `73d45630ab69033ac36a64740ecc73ecdb7363c9f99805222b6a9237dcb2d18b`, **64,494,656 decoded bytes**. The harness fetched/hashed the actual HTTP package before creating its temporary player.
- WASM SHA256: `fc74679e3b97f76878947fcd4fbe1268cbfa6188182a2e33bbc3f5dc9bfa57d0`.
- Generated export UIDs, recorded separately in `.runtime/overnight-build3-manifest.json`: `LandGeometry.gd.uid` SHA256 `8ff4f2b7b3dec0f2f5af0be3b1b420344ccef72260d2acaf157e2e3a058466e2`; `LandSurfaceQueryCache.gd.uid` SHA256 `74b3f7ecb39cf9622bcb620f34c04eb7ae642bd17ef904ce3afd77744c8d6e80`.
- Browser harness launched from integration HEAD `e3a9182e2daf05f8e3470015b92969044b797a0d`; later root CPU-only commits did not change this running package. Actual route: Headless Chromium/SwiftShader with the existing mobile/touch context, not a physical Windows/S23 test.

```sh
APP_TEST_ORIGIN=http://localhost:3111 \
PLAN06_ROUTE_MODE=left \
PLAN06_EXPECT_PCK=73d45630ab69033ac36a64740ecc73ecdb7363c9f99805222b6a9237dcb2d18b \
PLAN06_EXPECT_PCK_BYTES=64494656 \
node --import tsx scripts/plan06-layout-browser.mjs
```

## Actual result

Own UUID: `8c70f2ba-14e8-465c-8068-63b2e9ea4990`. The declared fixture began on the actual hub floor at1120/1230, story day2 and200coins. All movement used real keyboard input and the emitted renderer motion matrix; there was no runtime teleport, clock/weather override or account reuse.

- **2 completed checks**,496 matrix pulses,0 legacy pulses.
- The screen-right keyboard probe moved logically34.6968/19.9015, projecting to49.0689 horizontal pixels and0.000167 vertical pixels under actual azimuth−45°.
-213 recorded POST responses were all HTTP200. They include the actual hub→forest travel and surface-position acknowledgements. There were0 browser errors and0 gameplay API failures.
- At19:39:24.497Z, actual E travel reached forest200/1320. The following physical path continued to323.395355/1262.840942.
- At19:39:36.728Z, `budget()` asserted `Bounded left route exceeded 5 minutes` inside the route toward650/1050. `routeElapsedMs=300929`, exit1, `outcome="failed"`, `completed=false`.
- `ownTemporaryPlayerRemoved=true`; the existing finally cleanup removed only this UUID's player/receipts/shifts and verified its owned Redis keys were absent. Browser process exited; engine/browser slot was explicitly released.

The forest joystick direction/release, upper bridge crossing and save/reload assertions **were not reached**. The successful gate travel is an observed intermediate assertion/screenshot, not an additional completed aggregate check. Empty error/failure arrays do not override the explicit failed outcome.

## Evidence and next gate

Integration directory: `artifacts/browser/plan06-layout-8c70f2ba-14e8-465c-8068-63b2e9ea4990/`; log `.runtime/overnight-export3-left-browser.log`.

| Artifact | SHA256 |
| --- | --- |
| `results.json` | `ddb5245945e6d4a7cb6d0172183f94f9f7fcde6c363ea6fdc23ebb70b3df317b` |
| `left-real-forest-entry.png` | `3bf5e7587dea5795e064fc4112102d0d762c8a3dea282dd11f8ab8ee62bb59eb` |
| `failure.png` | `4ff965ec81fc234bcd52605b7bd735104849eafe0bf199a34a303ba8b562a496` |

Actual PNG review: badge frames are closed and text/controls remain separate at667×375; the forest entry shows the gate and Nala, and the last image shows Nala standing on the forest path. This is a night/rain composition, not cheerful daylight color or gait-in-motion evidence. The location badge intentionally truncates the long forest name. No screenshot demonstrates the still-pending joystick/bridge/reload checks.

The next acceptance should retain this prefix and use a separately declared, physically validated continuation fixture at the already reached forest point, or an explicitly granted longer full-flow budget. It must continue with actual input and preserve the bridge/touch/save assertions. No harness threshold, map geometry, product control or proxy was changed to force a pass.

## Prepared narrower forest component gate — not run yet

The integrator subsequently approved a fresh **forest-only component fixture**, rather than another long hub prefix or a runtime teleport. New `PLAN06_ROUTE_MODE=left-forest` derives a clear authored pre-upper-bridge route vertex from the shared/current HTTP world. Current map yields1200/730: the nearer1260/660 vertex does not have the required55-unit joystick probe clearance. Sixteen radial probes and their shared-authority segments, the approach route and the complete upper-bridge segment must remain walkable; malformed/missing bridge metadata or a blocked approach/crossing rejects setup. The initial Redis surface is declared before login; there is no in-game position override.

The existing left flow now calls the extracted same forest remainder. New mode retains actual touch screen-right/release, keyboard traversal to the bridge, >250-unit actual crossing, emitted rail/orientation checks, actual save acknowledgement, reload, camera contract and unchanged coins/story/inventory/calendar checks. Its final check explicitly says `left-forest-real-bridge...`, without claiming a new gate crossing. Five-minute budget and collision/arrival thresholds are unchanged. Setup and full derived metadata are recorded in the result.

Three CPU tests passed against current WORLD: legal derived approach/complete route with no WORLD mutation; real synthetic authoritative obstacle across the bridge rejected; blocked approach and malformed bridge metadata rejected. The first negative-test draft omitted the obstacle footprint and failed with TypeError; correcting the fixture to the actual obstacle schema produced3/3. `node --check` and `git diff --check` passed. **No browser PASS is claimed for this new mode before its next explicit grant.**

```sh
APP_TEST_ORIGIN=http://localhost:3111 \
PLAN06_ROUTE_MODE=left-forest \
PLAN06_EXPECT_PCK=73d45630ab69033ac36a64740ecc73ecdb7363c9f99805222b6a9237dcb2d18b \
PLAN06_EXPECT_PCK_BYTES=64494656 \
node --import tsx scripts/plan06-layout-browser.mjs
```
