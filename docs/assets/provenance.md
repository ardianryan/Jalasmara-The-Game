# Asal aset

| Aset                                               | Asal                                                                                                                          | Pemakaian                                                              |
| -------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------- |
| Jala Muara dan wordmark                            | SVG asli proyek; outline Lora Medium untuk wordmark                                                                           | Identitas Jalasmara                                                    |
| `muara-sungsang.png`                               | Generasi gambar untuk proyek; nama berkas warisan sebelum Bandar Hujung ditetapkan                                            | Halaman masuk dan latar laut jauh                                      |
| `nala-swim.png`                                    | Generasi gambar untuk proyek, enam frame atlas                                                                                | Animasi renang Nala                                                    |
| `gajah-mina.png`                                   | Generasi gambar untuk proyek dengan brief penjaga yang dipulihkan                                                             | Arena Tamansari                                                        |
| Empat atlas karakter `male-*` / `female-*`         | Generasi asli proyek, sembilan pose per atlas                                                                                 | Pilihan penjelajah dan animasi                                         |
| `forest-muara.png` / `coastal-village-map.png`       | Generasi asli berdasarkan brief geografis dan komposisi                                                                       | Arsip peta darat sebelum layout 4; renderer modular baru tidak memakai bitmap ini sebagai ground collision                    |
| `item-atlas.png`                                   | Generasi asli, dua putaran pemeriksaan/cleanup alfa                                                                           | Peti dan ikon koleksi; fauna runtime memakai generator procedural                                              |
| `coral-clusters.png` | Generasi bitmap asli Jalasmara melalui built-in imagegen, referensi palet atlas milik proyek, satu putaran pembersihan alpha | Tiga rumpun koral terpisah pada kisi 3 × 1; metadata ukuran, alpha, serta SHA-256 menyertai PNG |
| `ocean-atmosphere-atlas.png` | Generasi bitmap orisinal melalui built-in imagegen; referensi komposisi privat dan palet atlas proyek, tanpa pengambilan piksel game lain | Enam cutout untuk dinding jauh, pilar, reruntuhan fiksi, vegetasi, lengkung batu, dan karang; [prompt dan pemeriksaan alpha](ocean-atmosphere-prompt.md) |
| `npc-atlas.png`                                    | Generasi asli proyek, empat pemeran dermaga                                                                                   | Mbah Wira, Beno, Bu Darmi, Inspektur Raka                              |
| Instalasi, HUD, atlas wilayah, penghalang          | Gambar native melalui kode Godot                                                                                              | Dunia interaktif dan tabrakan                                          |
| `art/procedural/*.png` dan metadata                | Anatomi, rig, dan rasterisasi kode upstream Procedural Pixel Creatures (MIT), commit tersemat; adapter offline proyek         | Fauna procedural, 10 spesies / 722 frame; tanpa runtime C# di game web |
| `art/polyfork/fern-plant.png` / `bamboo-stalk.png` | Render PNG dari model Polyfork yang tercatat pada `assets/source-3d/polyfork/ATTRIBUTION.md`; CC BY 4.0; salinan byte asli render proyek, kredit runtime dalam `art/polyfork/ATTRIBUTION.txt` | Dua pakis hutan dan pakis/bambu dekoratif tepi pelataran hub           |
| `art/pixelbolt/*.png` / `.tres` / metadata | Resep piksel orisinal proyek, dikompilasi Pixelbolt 0.13.0 (MIT) tersemat; empat resep diperiksa melalui CLI dan render ulang identik SHA-256 | Api lentera, uap panci, splash air, kilau memori; integrasi hub dan hutan |
| `audio/bgm/*` / `audio/sfx/*` | Berkas audio yang ditambahkan pengguna ke proyek; asal rekaman, pembuat, dan lisensi belum disertakan, sehingga tidak diklaim sebagai rekaman orisinal atau berlisensi tertentu | Musik konteks area dan efek permainan; sumber berkas dipertahankan tanpa modifikasi |
| `resources/models/reef-rock.glb` | Small Reef Rock oleh Polyfork (CC BY 4.0), byte sumber tidak diubah; penempatan, skala, dan material runtime disesuaikan | Model runtime pada pilot laut dan renderer komponen darat; shader/palette, skala, serta pencahayaan disesuaikan, sumber GLB tetap sama |
| Mesh, shader terrain hybrid, dan HUD instrumen | Kode Godot asli proyek; memakai kontur dunia bersama dan tekstur batu proyek | Geometri 3D, cahaya, oksigen dan kontrol |
| Lora / Nunito Sans                                 | Paket Fontsource, SIL Open Font License                                                                                       | Judul dan UI web                                                       |
| Ark Pixel 12px proportional Latin                 | TakWolf/ark-pixel-font, rilis 2026.10.25, SIL OFL 1.1; berkas lisensi dan SHA-256 di `client-godot/resources/fonts`              | Tema game, HUD, dan label peta; rasterisasi tanpa antialias            |

Gambar yang dihasilkan belum merupakan bukti keaslian historis ornamen atau busana. Pedoman budaya mengatur tinjauan lanjutan. Aset Dave the Diver, Steam, RPGFan, Fandom, dan YouTube hanya untuk referensi visual lokal; direktori `moodboard/` diabaikan Git dan tidak dimasukkan ke citra Docker maupun build game.

[Brief generasi aset](generation-prompts.md) mencatat arah dan batas tiap bitmap.

[Adapter dan verifikasi fauna procedural](../../tools/procedural-creatures/README.md) mencatat seed, pin sumber, lisensi, format animasi, dan pemeriksaan determinisme. Nama kura-kura ditetapkan sebagai satwa darat; tidak disamarkan sebagai penyu atau lumba-lumba.

[Resep dan build FX Pixelbolt](../../tools/pixelbolt/README.md) mencatat versi alat, lisensi alat, resep proyek, serta uji determinisme. Lisensi MIT Pixelbolt tidak menentukan lisensi berkas audio pengguna.

Berkas lisensi proyek utama tersedia pada [LICENSE](../../LICENSE) dan [THIRD_PARTY_LICENSES.md](../../THIRD_PARTY_LICENSES.md). Berkas lisensi runtime dalam game: `resources/art/procedural/LICENSE.upstream.txt` (MIT), `resources/art/polyfork/ATTRIBUTION.txt` (kredit serta tautan CC BY 4.0), dan `resources/fonts/OFL.txt` (Ark Pixel). Preset ekspor menyertakan `*.json` dan `*.txt`, sehingga metadata sumber dan pemberitahuan tersebut ikut dalam distribusi game. Lisensi Lora dan Nunito Sans tersedia pada `docs/assets/LICENSE-*.txt`.

## Warga dan pakaian modular, 9 November 2026

`village-residents-v1.png` adalah atlas enam warga orisinal Jalasmara, dibuat dengan imagegen berdasarkan profil pengguna dan gaya atlas NPC proyek. Tokoh: Ki Lurah Wirabhumi, Mbok Ratih, Mang Ujang, Kang Tedi, Yu Sari, dan Saras. Susunan 3×2, alpha transparan diperiksa sebelum impor. Referensi Dave the Diver hanya digunakan untuk mempelajari pembagian fungsi perlengkapan dan komposisi; tidak ada sprite wiki yang dipaketkan.

Atlas tubuh/pakaian empat identitas dan perlengkapan 3D terpisah didokumentasikan di [modular-character-outfits.md](modular-character-outfits.md). Moodboard tetap privat dan diabaikan Git.

### NPC body cutout pilot — Plan03 B

Three runtime layered rigs (`resources/art/npc-rigs/{ujang,darmi,sari}.{png,json}`) derive from Jalasmara's original `village-residents-v1.png` and `npc-atlas.png`. `tools/npc-rig/generate.py` records source hashes and deterministic manual masks, then resamples original clothing/limb pixels. Covered clothing is repaired with pixels sampled from the same portrait; separate runtime fishing, watering and weaving tools replace the selected baked hand props. No commercial reference image enters these outputs.

Each pilot has sixteen cutout parts, two-bone limb posing, a shared logical foot pivot and computed hand sockets. East/west use mirrored three-quarter art; north uses a simplified rear silhouette constructed from sampled hair/clothing colors. This is a cutout animation pilot, **not** four newly illustrated directional sprite sheets. Small source-mask/sleeve remnants and the simplified rear remain art-polish limitations. The other four working villagers retain their existing portraits and activity props; their daily schedules still run.

Native evidence is kept locally under ignored `artifacts/godot/npc-body-rig/`: three recorded 15-second work → tidy → walk → interact sequences and a separate transparent-stage body-only pixel test. `scripts/tests/npc-body-animation.gd` checks clip transitions, one-shot events, distance gait, pause and reduced motion. `scripts/tests/npc-body-render.gd` requires native GPU rendering and checks changed body pixels without tools or terrain. The generator and rig are original project code; derived art retains the source artwork's existing terms.

### Plan04 side-gait and leg-volume correction

`tools/player-gait/generate.py` derives eight contact/down/passing/up side poses for four identities and three outfits from the original project outfits sheets. Output lives in `resources/art/player-gait/`; source hashes, stance feet, contacts and stride are recorded alongside each atlas. The offline asset test checks actual opaque soles within one pixel, distinct body poses and a planted stance foot in world coordinates. `CharacterVisual.set_locomotion()` uses actual velocity/displacement to advance phase; swimming and modular equipment remain separate.

These are east/west side-view cutouts, **not genuine eight-direction artwork**. North/south/diagonals expose an explicit fallback status. No Sprite AI paid job or third-party sprite was used. Native grid evidence under ignored `artifacts/godot/player-gait/` shows slow/normal movement; enlarged cutout joints still need artist cleanup before final animation quality can be claimed.

The Ujang screenshot leg defect was corrected separately: source-sampled thigh/calf gaps receive tapered original-color volume, and knee posing uses limited forward flex with connected segment endpoints instead of sideways slack-driven splay. The original peg-leg design remains. Updated native isolated evidence is `artifacts/godot/npc-body-rig/isolated/fishing-0.png`; earlier MP4s predate this leg correction and must not be presented as final leg-fix footage.

### Original daily eight-direction Nala pilot

After the side-gait prototype, the built-in imagegen tool generated a new original eight-view Nala daily reference, preserving the project's Indonesian identity, woven headband, muted teal shirt, cargo shorts and sandals. Individual inspected viewpoints then conditioned eight whole-body walk frames per direction; the south clip received one timing revision. No gallery sprite, commercial-game frame, external character pack, paid CLI job or API key was used. High-resolution authoring sheets and their hashes are preserved in `assets/source-2d/nala-daily-eightway/`, outside the runtime resource tree.

At the first pilot checkpoint, only `male_default` with the daily outfit used these64 drawn poses and eight idle views. Runtime PNGs are `resources/art/player-gait/male-default-daily-{walk,idle}-8way-v1.png`; normalization metadata records a128×128cell and fixed64,104pivot. N/W/NE/NW are actual corresponding drawings, not side-sprite flips. CharacterVisual reports the supported direction count and whether a fallback is active. Other identities/outfits at that checkpoint retained east/west cutout fallbacks. The full batch update below supersedes that checkpoint.

Native full-world evidence under ignored `artifacts/godot/player-eightway/` exercises all eight directions on collision-valid ground with3D terrain/canopy occlusion and stable logical actor placement. `tools/player-gait/test_eightway.py` checks64 unique connected silhouettes, source hashes and no frame-edge clipping. `scripts/tests/player-locomotion.gd` checks actual atlas row selection, no mirrored pilot rows, fixed pivot and separate swimming. Whole-limb art fixes the cutout joint-volume issue; final timing/contact polish remains possible, especially the restrained front/back passing poses.

### Full directional protagonist outfit batch — Plan04 D

The original daily pilot has been extended to all four player identities and three land outfits:12 sets of64 drawn walk frames and8 neutral idle views. Authoring inputs are the project's original character/outfit sheets and reviewed daily pilot, using the built-in image generation tool. Eight north rows that duplicated a diagonal were replaced with separately inspected true-back strips. The neutral poses preserve distinct male/female, loose-tied/high-bun, and Nusantara identity variants. Fieldwear in the new batch uses cropped cargo trousers and boots; the legacy3-pose fieldwear has longer trousers.

High-resolution original outputs stay outside runtime in `assets/source-2d/nala-eightway-batch/`; manifest records SHA256 for source and shipped PNGs. `tools/player-gait/assemble_batch.py` rebuilds the additional11sets with Pillow alpha/nearest normalization and original north-strip repairs; no commercial game sprite, new pack license, Sprite AI job or API-key recovery is involved. The previous one-pilot-only scope above is historical; the normal displacement-driven runtime now selects all12sets. Original three-pose standing/six-pose swim and side-cutout fallbacks remain for compatibility. Separate tank, net and satchel geometry follows the selected direction, with underwater attachment unchanged.

### Ujang rear upper body and west fishing fist: Plan06 B2 pilot

The built-in image tool generated a rear head, rear vest and one west fishing fist from Ujang's original resident portrait and existing cutout atlas. A second torso edit removed baked sleeves to keep arms articulated. The navy sailor cap, gold trim, grey hair and patched waistcoat retain his identity; the original wooden leg parts are unchanged. Sources, exact prompts and annotations are preserved under `assets/source-2d/ujang-rear-grip-v1/`. Original-art terms in `LICENSE` section 2 apply. No external character sprite, upstream code, PixelDoll output, Sprite AI job or external API credential was used.

`tools/npc-rig/ujang_rear.py` thresholds alpha, resizes with nearest sampling, quantizes to the original Ujang palette and packs `resources/art/npc-rigs/ujang-rear-grip-v1.png`. The original `ujang.png` remains intact. This adds one fist to the sixteen-part rig and replaces only the two old rear placeholders. It does not create four authored views: E/W still mirror the three-quarter source and rear limbs remain cutouts. The independently annotated fist/rod test and final actual-size native evidence are described in `docs/reviews/06b2-ujang-rear-grip.md`; mathematical contact does not imply natural walking is complete.

The subsequent turn increment adds an original west head from the same built-in tool, with `generated-west-head-v1.png`, `prompt-west-head-v1.txt` and packed `head_west.png` preserved in that source directory. Ujang now has eighteen parts and an unreflected anatomical land rig, so his wooden right leg is not exchanged when facing west. The actual west artwork looks left; other body sides remain cutouts. `docs/reviews/06b2-ujang-transition-step.md` records the final 1,242 contact samples, including the formerly failing 168 sharp turns, and sequential native evidence. This supersedes the earlier seventeen-part direction fallback description without claiming four fully authored body views.

## New music and victory jingle — 10 November 2026

**Composer / music generation:** Google Gemini. **Prompt and curation:** Ardian Ryan. Music composed with Google Gemini from prompts by Ardian Ryan and curated by Ardian Ryan. The six MP3s were supplied by the project owner from local `~/Downloads`; originals remain there. No third-party music library was used in this import. The exact Gemini model, generation session, and distribution license were not supplied, so they are not asserted here. Verify music distribution rights before a public game release.

| Original filename in `~/Downloads` | Runtime file | Use | Bytes | SHA-256 |
| --- | --- | --- | ---: | --- |
| `Bamboo_Sails_at_High_Tide-bgm_title_theme.mp3` | `client-godot/audio/bgm/bgm_title_theme.mp3` | Title/menu | 4,095,021 | `2ce9cf110bc4f8b50804419c28aff30c8985279ecda2afe3d7886343dbe6c1cb` |
| `Where_the_Roots_Meet_Water-bgm_mangrove_forest.mp3` | `client-godot/audio/bgm/bgm_mangrove_forest.mp3` | Mangrove forest | 4,111,949 | `bdaa40792a843bde8abd0cc3bac591f13aa8a1cd4937df0c7a6dfcb21e48be3d` |
| `Gold_on_the_Shoreline-bgm_coastal_dusk.mp3` | `client-godot/audio/bgm/bgm_coastal_dusk.mp3` | Coastal dusk | 4,347,678 | `685d86d1be57191e17cd55f11fe8e77facc3d54f98efa36bcef2d4d22ef1703a` |
| `Senja_di_Balai_Desa-bgm_village_hall.mp3` | `client-godot/audio/bgm/bgm_village_hall.mp3` | Village hall | 4,128,249 | `d99242df5bfb25aeefb83db62b7396a0449ab035f126853ddb0bcefe5c042b81` |
| `The_Sunken_Bronze_Ritual-bgm_underwater_cave_deep.mp3` | `client-godot/audio/bgm/bgm_underwater_cave_deep.mp3` | Deep underwater cave | 4,182,166 | `a99db5655440570c85fe30dd3f210ff9ad712ff3046491beee70b5fcb1a322dc` |
| `Arrival_at_the_Bronze_Coast-Jingle Kemenangan Misi.mp3` | `client-godot/audio/sfx/jingle_victory_fanfare.mp3` | Major quest victory | 1,511,407 | `6c9c9fa734bdaf769f1896e89102b115c55d84deeebe32f76b349116f1930abd` |

All six files were copied without transcoding or replacing the source files. Godot 4.7.2 generated corresponding `.mp3.import` files; these describe import settings and are not alternate audio masters. Existing WAV/MP3 tracks are unchanged.
