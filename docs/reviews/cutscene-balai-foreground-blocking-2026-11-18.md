# Balai council foreground blocking candidate

Status: **local candidate for integrator review**, not merged, pushed, or released. Branch `work/cutscene-moodboard-fix-20261118` starts at `160f525`; the prior resident-scale package is already in that base.

The Phase 1 Balai dialogue beats 4–6 still placed three supporting residents in a flat row of small figures, despite the earlier sprite-scale pass. At the actual 667×375 game viewport, the detailed Balai plate dominated them. The [Saras baseline](../visual/cutscene-resident-scale-20261118/earthquake-04-saras-t2-667x375.webp) records the issue.

`CinematicActionLayer.gd` now gives those three supporters separate near-stage marks at 17%, 32%, and 47% of the viewport width, with foot lines at 68%, 67%, and 66% of the height. Their scene-specific scales are 2.50, 2.60, and 2.50. Each enters up to ten stage units from its mark, uses the existing short walk frame, then plants both feet and returns to idle. The speaking character stays on the existing right-side mark and remains the portrait focus. The stage map, title bar, dialogue panel, and surrounding scene art are unchanged. All sprites are existing project atlases; no raster generation, new dependency, or third-party asset was used.

| Native frame | Evidence |
| --- | --- |
| Saras beat 4, entry, 667×375 | [t0](../visual/cutscene-balai-blocking-20261118/earthquake-04-saras-t0-667x375.webp) |
| Saras beat 4, settled, 667×375 | [t2](../visual/cutscene-balai-blocking-20261118/earthquake-04-saras-t2-667x375.webp) |
| Saras beat 4, settled, 844×390 | [t2 wide](../visual/cutscene-balai-blocking-20261118/earthquake-04-saras-t2-844x390.webp) |
| Beno beat 5, settled, 667×375 | [t2](../visual/cutscene-balai-blocking-20261118/earthquake-05-beno-t2-667x375.webp) |
| Wira beat 6, settled, 667×375 | [t2](../visual/cutscene-balai-blocking-20261118/earthquake-06-wira-t2-667x375.webp) |

At both viewport sizes, the three residents have clearer body silhouettes than the baseline. Their staggered feet give perspective without hiding the painted map; they do not cross the title or dialogue boundaries. Entry and settled frames show a bounded approach rather than continuous idle sliding. This is a shot-level improvement, **not full moodboard parity** or proof of browser/physical-device animation quality.

Godot 4.7.2 Compatibility native render used `CINEMATIC_CAPTURE=1 CINEMATIC_CASE_FILTER=earthquake:4 Godot --rendering-method gl_compatibility --path client-godot --script res://../scripts/tests/phase-one-hero-staging.gd`, then repeated with filter `earthquake:5` and `earthquake:6`. Each run exited 0 with **136 existing focal/layout checks and 128 captures**; logs at `/tmp/jalasmara-cutscene-moodboard-native.log`, `-beat5.log`, and `-beat6.log` have no `SCRIPT ERROR`, `ERROR:`, or parse error. The first cold editor import briefly reported missing font import data; the repeat editor import was clean before native captures. `git diff --check` passed. Captures above are lossless WebP conversions using local `cwebp 1.6.0`, total about 1.5 MiB; the original native PNGs remain local under `artifacts/godot/phase-one-character-closeup/`.

Curated image SHA-256 in table order: `3bbcae68567815153e1429b2642bb121db65581911f9c8e4821a2fa601b873bf`, `1c2dec7da3be1c39c459790c7e22897303c30e5d5d06c79cb750eb41e013796d`, `dd77716e677e64f06bcf6425b0c32154a715fa9fcb055d0ba2d7faf91302b511`, `833ab84516ac94126add831cc83ad3fc8d9441ec8d73eec079246925b3b891ae`, `c7000886901283eede3dcf6f180d5f03fb310d1adfbcb6a1d804ee30b9585f34`.

Integrator next: compare the 667/844 A/B frames independently, cherry-pick only if accepted, run combined checks, then update active handoff and delivery status. This candidate does not alter gameplay state, dialogue timing, or hitboxes.
