# Epilogue witness cut-in: Ratih and Tedi

Status: accepted and merged into local `main` as `a5c5fed` on 18 November 2026; not yet released to staging.

The original native `epilogue:2` frame showed Ki Lurah and Raka clearly, but Mbok Ratih and Kang Tedi were 45–60 px stage figures. Their support during Raka's failed sealing attempt was too small to read at 667×375. This package gives only those two witnesses a near-plane entrance and readable, connected tools while leaving Lurah, Raka, dialogue, guards, and the other background residents in place. The near-plane actors stop with their feet on the Kedai floor above the dialogue panel. The previous small Ratih/Tedi calls are replaced. The beat's legacy `darmi` cutout is excluded because it uses the same Ratih source tile and would duplicate her; a distinct Bu Darmi cutout remains future art work. Ujang, Yu Sari, and Beno stay in the background.

`tools/cutscene-pixel/author_epilogue_witnesses.py` crops two 627×627 cells from the project-owned `npc-atlas.png` (SHA-256 `82d946a0df5ecb98eb5d4daa48856e8cf36644103b39f80d39d17e361ff56aec`) and downsamples each to a 192×192 pixel grid with nearest-neighbor sampling. Ratih's source plant is removed from the transparent edge of her body; a bent sleeve, hand, and connected brass dacin are authored directly as pixels. Tedi's source wrench and hand remain intact. Output hashes:

| Asset | SHA-256 |
| --- | --- |
| [`mbok-ratih-dacin.png`](../../client-godot/resources/art/cinematics-v2/close-pose/mbok-ratih-dacin.png) | `dfa090cfb88df7081dac3fd9d144b7c68bb321bf93743e924ce8ff2303b34481` |
| [`kang-tedi-wrench.png`](../../client-godot/resources/art/cinematics-v2/close-pose/kang-tedi-wrench.png) | `251ba704c7832ff526760345a9a02cf659d7a59dbcf933e23e730a1570893a0a` |

These are derivatives of Jalasmara's own art under `LICENSE` section 2. Pillow 11.3.0 was used offline; Godot 4.7.2 Compatibility rendered the captures. No external sprite, AI image generator, or runtime dependency was added.

Native original-size frames, with the scene's own dialogue and title visible:

| Viewport | Entry | United stance | Settled |
| --- | --- | --- | --- |
| 667×375 | [frame](../visual/cutscene-epilogue-witnesses-20261118/epilogue-02-entry-667x375.webp) | [frame](../visual/cutscene-epilogue-witnesses-20261118/epilogue-02-united-667x375.webp) | [frame](../visual/cutscene-epilogue-witnesses-20261118/epilogue-02-settled-667x375.webp) |
| 844×390 | [frame](../visual/cutscene-epilogue-witnesses-20261118/epilogue-02-entry-844x390.webp) | [frame](../visual/cutscene-epilogue-witnesses-20261118/epilogue-02-united-844x390.webp) | [frame](../visual/cutscene-epilogue-witnesses-20261118/epilogue-02-settled-844x390.webp) |

Verification: `python3 tools/cutscene-pixel/test_epilogue_witnesses.py` passed source pin, deterministic output pixels, and hand-to-dacin point checks. The focused Godot fixture `scripts/tests/cutscene-epilogue-witnesses.gd` passed six native viewport/time checks plus reduced-motion state. A clean second editor import and revised native fixture log contain no `SCRIPT ERROR` or `ERROR:` (`/tmp/jalasmara-epilogue-import-clean.log`, `/tmp/jalasmara-epilogue-native-revised.log`). The first import found transient font import data and a typed-variable parse error; the latter was fixed before the clean run. These tests do not establish full Phase 1 story, browser performance, or moodboard parity. The integrator must still merge and run combined checks before any release.
