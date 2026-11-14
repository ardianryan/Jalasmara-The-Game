# Neutralizer combat and discovery-led gear, 14 November 2026

## Request and implemented behavior in this source candidate

The owner asked for a direct tool attack during the Gajah Mina duel and upgrades earned by finding unique fragments. Nala now carries a distinct brass-and-teal neutralizer launcher during the boss dive. On desktop, **F** fires a capsule at a nearby open resonance target, then **Space** locks it with the Jala Kognisi to start the existing question. On touch, the existing right-hand action slot becomes **TEMBAK**, beside **JALA**. A travelling brass-and-cyan capsule, short trail, impact ring and underwater swoosh confirm a server-accepted hit. The six fixed targets, two phases, quiz answers, rewards, oxygen penalty, and boss movement remain unchanged.

The server owns the shot: it checks boss mode, active target and phase, distance from the saved dive position, cooldown, and an eight-second neutralization window. Starting the quiz consumes that window. A wrong answer requires another shot. A shot outside the range or at a later-phase target is rejected. This does **not** add body damage or a moving hitbox; the fixed resonance markers remain the attack points.

Three guaranteed discoveries grant permanent unique gear evidence: the Photosynthesis Lantern gives Bagas's lens, the corporate pipe gives a valve core, and the cracked inscription gives a UV shard. The first Jala upgrade remains coin-only; later Jala levels require the lens and shard. Beno can also upgrade the UV lamp and launcher through two tiers each, using coins plus the matching discovery. The lamp boosts existing 2D/3D headlamp energy; launcher tiers increase shot reach and shorten cooldown. Key items are not consumed, so one finding can inform more than one design. SmaraPedia lists the three unique findings. Existing accounts without a `gear` field safely use level zero; existing Jala levels stay intact. On load, accounts that already recorded a discovery before this release receive its missing permanent key item without replaying the discovery.

## Evidence and limits

- `npm run typecheck` and `npm test` passed (**123/123**, including legacy-discovery backfill, denied premature shots and six-shot victory).
- `npm run check:world` and `npm run build` passed on final source. The full world check included the five-node detachable equipment diagnostic and compact HUD contact checks. Godot 4.7.2 import/export logs contain no `SCRIPT ERROR` or `ERROR`.
- [Native HUD fixture](../visual/neutralizer-hud-boss-667x375.png) is a 667×375 Apple M2 Compatibility capture of the actual Godot HUD over the project's Tamansari cinematic background. It verifies compact touch labels only, **not** live boss gameplay or Android/Windows frame rate. The indexed PNG was reduced with ImageMagick; SHA-256 `ce93fb9f3116acff0374de1e19cbcfa7cd1769e752d10a8ba79b7063cc067b59`.
- A full public-browser fight, shot timing against the moving boss, physical Windows/S23 controls, and cross-device lamp visibility remain acceptance work. No staging activation is claimed by this candidate report.

## Source, tools, and next gate

Source branch/worktree: `work/neutralizer-combat-20261114` in `../Jalasmara-neutralizer-combat`, based on `7c15453`. Main and staging remain unchanged until review, merge, GitHub Actions verified delivery, exact-bundle activation, backup/restore and public smoke. Only existing project art and SFX were reused; the launcher meshes, capsule effect and HUD glyph are original code geometry. Godot 4.7.2, Node 26, and ImageMagick were used. No upstream asset or additional runtime library was introduced, so no new third-party license entry is needed.

Before release: merge the tested SHA, wait for GitHub CI, deploy the exact CI PCK per `docs/operations-github.md`, and perform the public six-resonance playthrough with the owner on Windows and Samsung S23.
