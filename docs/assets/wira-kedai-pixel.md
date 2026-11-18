# Mbah Wira tea-offering close pose

The source is the top-left 627×627 tile of the project-owned `client-godot/resources/art/npc-atlas.png`, whose full-file SHA-256 is `82d946a0df5ecb98eb5d4daa48856e8cf36644103b39f80d39d17e361ff56aec`. `tools/cutscene-pixel/author_wira_tea.py` reduces that tile by nearest-neighbor sampling to a 192×192 RGBA working grid, removes the original hanging metal forearm, and authors a connected bent sleeve, brass glove, ceramic cup, tea surface, handle and steam as explicit pixel polygons and lines. The finished file is `client-godot/resources/art/cinematics-v2/close-pose/mbah-wira-tea-offer.png`, SHA-256 `456504435508f83e1d5a6cd43932255c466cb8e67830fa6d35b57eba726d3fbd`.

Rebuild with `python3 tools/cutscene-pixel/author_wira_tea.py`. Validate with `python3 tools/cutscene-pixel/test_wira_tea.py`; its three CPU checks cover source pin, deterministic image pixels, four-connected body-to-cup contact, and preservation of the lower source pixels outside the hand edit. The small steam wisps are intentionally detached from the cup.

Artwork is a derivative of Jalasmara's own character atlas and follows the artwork terms in `LICENSE` section 2. Pillow was used offline for pixel editing. No external sprite pack, moodboard image, or AI generation was used for this pose. No runtime or cutscene sequence references the pose until the integrator places it.
