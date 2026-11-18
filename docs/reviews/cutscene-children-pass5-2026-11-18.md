# Phase 1 cutscene children: foreground readability pass 5

Status: **local candidate**, based on `main` `c391130b7cf521da7dce19c22ae906fd2cb06f32`. This is a scoped composition improvement, not full moodboard parity or a staging release.

## Change and evidence

The harbor lesson now spaces Bagas, Kinasih, and Gito across distinct dock marks and enlarges their existing project sprites. Ki Lurah shifts right to preserve separate silhouettes. The victory crowd uses distinct marks for five children, Beno, and two adults, making the children readable without entering the dialogue panel. In the map room, Bagas now walks to a floor mark and holds the UV lamp that illuminates the existing hologram; the lamp no longer floats without an on-stage source. All motion is code driven. No story, gameplay, server rule, image atlas, or dialogue was changed.

Original-size, native Godot screenshots, losslessly converted to WebP for repository documentation:

| Beat | 667×375 | 844×390 |
| --- | --- | --- |
| Harbor lesson | [667](../visual/cutscene-children-pass5-20261118/prologue-01-667x375.webp) | [844](../visual/cutscene-children-pass5-20261118/prologue-01-844x390.webp) |
| Victory dock | [667](../visual/cutscene-children-pass5-20261118/victory-03-667x375.webp) | [844](../visual/cutscene-children-pass5-20261118/victory-03-844x390.webp) |
| Map room | [667](../visual/cutscene-children-pass5-20261118/epilogue-04-667x375.webp) | [844](../visual/cutscene-children-pass5-20261118/epilogue-04-844x390.webp) |

Baseline for harbor and victory: [previous harbor](../visual/cutscene-lurah-lesson-667x375-20261118.webp) and [previous victory](../visual/cutscene-victory-667x375-20261118.webp). The current map-room scene previously drew the UV beam and lamp with no Bagas actor; the new native capture is the first curated map-room proof in this series. At both sizes, the new figures are visibly larger and full-body, grounded on the dock or floor, and clear of title and dialogue. The victory boat opening and map room's two-dimensional staging remain visible stylistic gaps from the requested cinematic moodboard.

## Verification

Tool: local Godot `4.7.2.stable.official.ed1daf0bf`, Compatibility renderer. After a cold editor import, `CINEMATIC_CAPTURE=1 Godot --path client-godot --script res://../scripts/tests/phase-one-hero-staging.gd` passed **184 size/layout checks and 308 native captures**. The native run log `/tmp/jalasmara-cutscene-pass5-native.log` had no `SCRIPT ERROR`, `ERROR:`, or parse error. Cold import briefly reported missing font import data before asset reimport completed; the subsequent native run was clean. `git diff --check` passed. Source review covered motion samples t0/t1/t2 for the three edited beats at 667×375 and t2 at 844×390. These are renderer stills, not browser or physical-device motion/performance evidence.

Source assets used: existing project-owned child atlas, NPC atlas, Nala atlas, and Phase 1 painted plates; no new raster assets, outside references, or licensed dependencies entered this package. `cwebp` lossless was used only to curate proof images. Source PNGs and the other 302 fixture captures remain local ignored artifacts.

## Remaining work

The cutscenes still mix a painted backdrop with flat stage actors, and the victory dock's central boat opening is visually schematic. The on-stage figures are legible in these three beats, but full Phase 1 art-direction parity requires a broader motion and lighting review at actual browser and device sizes. The integrator must run combined checks after merge; this package has not been pushed, merged, or activated on staging.
