# Compact Bahari HUD badge trial — 15 November 2026

The 844×390 and 667×375 component screenshots showed the land identity plaque taking more vertical space than its two text rows need. The existing 48 px utility buttons remain in their established positions; this pass trims only the short-landscape badge frame and displays the project's existing, purpose-authored 32 px map, journal, satchel, character and speaker icons. No moodboard image or third-party art is copied. The original HUD artwork and provenance remain unchanged.

The shortened plaque preserves a full brass border around both rows. Controls continue to use the same hit rectangles, sound tooltips, keyboard shortcuts and modal visibility. The game world, minigames, account state and server rules are untouched.

## Validation

The `hud-footprint.gd` fixture now includes 844×390 alongside 667×375, 390×844 and 1440×900. `hud-oxygen.gd` checks the shorter frame, contained text and imported authored icons, while `hud-region-overflow.gd` checks that the portrait, location, objective, sound and joystick hit geometry stays fixed. Before and after PNGs use the HUD component fixture's dark, plain background; they are not in-game gameplay screenshots.

The final native measurements are:

| Physical viewport | Badge height before → after | Reclaimed height | Action target after | Sound target after |
| --- | ---: | ---: | ---: | ---: |
| 844×390 | 69.31 → 60.65 px | 8.66 px | 63.53 px | 48.37 px |
| 667×375 | 66.70 → 58.36 px | 8.34 px | 61.14 px | 48.64 px |

Portrait 390×844 and desktop 1440×900 badge sizes stay unchanged. The final 667×375 and 844×390 composite captures place baseline on the left and final candidate on the right: [667×375](../visual/moodboard-hud-badge-667x375-before-after-20261115.png) (SHA-256 `37a29770faad127b8b51b1874c7a50186acbee165cc28da6f8d7033429fbfd96`) and [844×390](../visual/moodboard-hud-badge-844x390-before-after-20261115.png) (`3dde654467fe810b39efc6dad47c77729dbd7afd6fcc3e43ed7351b92e68b5d7`). Both retain the complete copper border and readable coin line. They are original project component fixtures, not the user's external moodboard or a live gameplay browser screenshot.

Godot 4.7.2 Compatibility native `hud-footprint` and headless `hud-oxygen`, `hud-region-overflow`, `hud-short-landscape` all passed with no final-run `SCRIPT ERROR` or `ERROR`. Logs are `/tmp/jalasmara-hud-{after,oxygen,region,short}-final.log`; full metric JSON and PNGs are in `artifacts/godot/overnight-hud-footprint/{before,after}/`. The initial editor import of this fresh worktree emitted missing-font-import and parse diagnostics; import completed, and subsequent focused script runs used the imported resources cleanly. The separate `hud-short-landscape` fixture required a project world-map JSON copied into this worktree's ignored `.runtime/`; it changes no tracked source.

The earlier first candidate reduced the plaque from 69.31 to 57.76 physical pixels at 844×390 and from 66.70 to 55.58 pixels at 667×375, without changing sound/action target sizes (48.37/63.53 and 48.64/61.14 pixels respectively). Image review found the coin row too close to the lower brass edge, so that first candidate is not the accepted artwork; the final candidate adds clearance and must be remeasured.

This is an isolated `work/hud-game-scale` source candidate based on `c3575c5`, not yet merged, exported, or visible on staging. Browser gameplay and physical Windows/S23 visual acceptance remain open. The five quick-access buttons still occupy the top-right row; a collapsed utility drawer would require separate interaction design and browser touch validation, so this pass does not claim full HUD or moodboard parity.
