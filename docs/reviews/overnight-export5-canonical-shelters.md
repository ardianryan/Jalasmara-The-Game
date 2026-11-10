# Export5 canonical village and shelter checks

10 November 2026, 07.05 WIB. Local browser evidence on localhost3111, Godot export72b173c/PCK `9a1ca274b88cf65e819f1c117da2ede7992420e2128b454ef6bc3cf7f19cbb1a`,64,500,848bytes. No runtime/export/deployment change in this package. Nala physical pilot remains OFF.

## Harness correction

The full village route still expected five attached roofs and seven residents from an older world. Current canonical source/API specifies seven new roofs/fourteen posts and thirteen shelter routines, including Bu Darmi. Root changed only expected inventories and diagnostic labels in `scripts/plan06-layout-browser.mjs`: exact canonical resident names, unique/minimum inventory guards, exact authored roof/post totals. Existing legacy-layout8 setup, floor migration, physical access, dialogue, save/reload and route budgets remain. This is not a reduction of coverage or a game-state repair.

`node --check scripts/plan06-layout-browser.mjs` and `git diff --check` pass. No dependency or new asset was introduced. Tools: Node26.12.1/tsx, Playwright Chromium/SwiftShader, existing isolated fixture helpers. Production image uses Node22.

## Actual runs, including failures

| UUID | Actual result | Result JSON SHA256 |
| --- | --- | --- |
| `e185acf1-773d-4de7-869d-b33af6320542` | Full route rejected stale roof count7!=5 before first check,1,724ms | `984c1fec7d3cf64143cce1d60cd141a0255c5ddf542d0ab0f0703fe4a0071ff6` |
| `706c352d-bc1e-4c84-9eff-e21e37189523` | Migration and Griya porch/interior movement/save/reload/exit pass, then stale resident count13!=7 rejects route;231,009ms,260matrix/41legacy pulses,125observed operations | `89579c82c5db343f7f4f224e302da45706fb925c734eba73625c6ce3364c2e2c` |
| `b1f54239-9043-4af8-bfce-1bdb6f130e9f` | Fresh focused shelters fixture reaches quiet approach, all13 routines reach shelter/stop, director physical access/dialogue/resume passes. Route then exceeds unchanged10minute budget while traveling to Bu Darmi;603,827ms,894matrix/0legacy pulses,395observed operations | `6037853c7a4aa7ba6b96c19f880d9f943d3d556ee49c238a47f549d355f60c8c` |

All three results are `completed=false`; none is a full-route PASS. Each records zero browser/API errors and successful own temporary-player cleanup. Harness assertion/budget failures remain in logs and are not reclassified as browser errors. Results/screenshots are retained at `artifacts/browser/plan06-layout-<UUID>/`.

The focused run declares legal hub spawn1120/1230, day2/dive-ready200coins/empty inventory and rainy evening fixture state. It is not acquisition evidence. Actual quiet position802.504456/997.856201 clears every resident station approach. Snapshot records Bagas, Bu Darmi, Cempaka, Danu, Direktur PT Cakrawala Sintetis, Gito, Kang Tedi, Ki Lurah Wirabhumi, Kinasih, Mang Ujang, Mbok Ratih, Saras and Yu Sari all `phase=shelter`, `atStation=true`, `moving=false`. Director dialogue opens at actual1772.573853/241.233398. The other twelve shelter conversations remain unverified in this run.

Do not combine independent fixtures into a claim of one completed village journey. Do not increase the route budget to hide slow execution. Last software-rendered snapshot reports3FPS/process182.1ms/drawCalls477; this is a local SwiftShader observation, not a Samsung S23/Windows device result or an isolated performance benchmark. Physical-device tests are still pending with the user.

Reproduction:

```sh
env APP_TEST_ORIGIN=http://localhost:3111 PLAN06_ROUTE_MODE=shelters \
PLAN06_EXPECT_PCK=9a1ca274b88cf65e819f1c117da2ede7992420e2128b454ef6bc3cf7f19cbb1a \
PLAN06_EXPECT_PCK_BYTES=64500848 node --import tsx scripts/plan06-layout-browser.mjs
```

Browser34617 exited1 and released the serialized engine slot. Character's isolated upper-approach tests then received GO. Next: complete remaining dialogue coverage in explicitly separate bounded fixtures when appropriate, investigate performance with measured A/B evidence, and preserve focus on full Nala terrain/contact/native acceptance before adopting the physical pilot.

## Subsequent hardware-backed local browser: all thirteen conversations

Root first ran a separate WebGL capability probe: actual Chromium reports `ANGLE (Apple, ANGLE Metal Renderer: Apple M2, Unspecified Version)`, WebGL2. This is the development Mac, not Windows/S23. The harness now accepts optional `PLAN06_ANGLE_BACKEND=metal` only on macOS, asserts the actual game canvas reports Metal, and records that identity in results. Default remains SwiftShader. Identity must remain the same after iframe reload. No game, route, walk speed, physics tolerance, calendar, fixture reward or budget changed.

Fresh fixture `cf51efb3-c3f2-49fd-9727-cb5d02a5dfdc` completed **18/18PASS**,468,786ms,1469matrix/0legacy pulses,323observed operations/322position syncs,0browser/API errors/failures. Same exact export5/PCK9a1; no predecessor fixture or teleported conversation target. All13 routine arrivals and physical shelter approaches/dialogues/resume completed in this single run. Lurah's overlapping permit board correctly opens shared service then actual named dialogue; explicit permit action grants only defined starter seeds, preserving coins/inventory/story progress. Final state assertions pass. Own-player cleanup succeeds and browser41259exit0/RELEASE.

Result `artifacts/browser/plan06-layout-cf51efb3-c3f2-49fd-9727-cb5d02a5dfdc/results.json` SHA256 `8ad5cf5702ad01e6db0c1f9bbc7f1cdfef78b6c5c2c9810d5fe687efe75b2221`; log `.runtime/overnight-export5-metal-shelters.log`. Root viewed actual667×375 Lurah dialogue: original wood/parchment frame, portrait, legible text/action, gameplay HUD hidden during modal. This does not accept every dialogue sentence/typewriter phase, natural Nala gait or device performance.

Reproduce by adding `PLAN06_ANGLE_BACKEND=metal` to the command above on a Mac with actual Metal canvas support. These are separate fixtures/backends, not a controlled GPU performance A/B or evidence that the earlier software timeout disappeared. Preserve all failed runs. Public staging remains accepted image559/PCK9a1; this focused local route is not a new public full-route smoke.
