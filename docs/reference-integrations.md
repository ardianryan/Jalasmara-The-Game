# Referensi dan integrasi Jalasmara

Catatan permintaan pengguna, 8 November 2026. Dokumen ini menjadi daftar tetap agar referensi tidak hilang saat pekerjaan berpindah sesi. Baseline sebelum pekerjaan ini adalah commit `1f99c35`. Status di bawah diperbarui berdasarkan implementasi dan pengujian lokal; bukti browser/deployment dirujuk pada status pengembangan.

## Referensi teknis yang diberikan

| Referensi | Tujuan pengguna | Integrasi yang sesuai dengan Godot Web | Status implementasi |
| --- | --- | --- | --- |
| [Noxe Pixel Engine](https://github.com/danieljan-design/noxe-pixel-engine) | Rumah bervolume dan pandangan 3/4 menyudut | Port terbatas orbit/snap kamera ke `LandCameraPose.gd`; konstruksi rumah native Godot | Helper memakai notice MIT dan pin upstream. Default kamera mempunyai parity terhadap rilis; kamera kiri −45° diuji pada fixture mesh nyata, belum mengganti kontrol/proyeksi seluruh permainan. Rumah panggung memakai modul Godot orisinal. |
| [Polyfork](https://polyfork.dev/) | Prop dan bentuk alam 3D | Model GLB dimuat langsung; render ortografis dipakai untuk prop 2D | GLB batu karang dimuat pada laut dan renderer komponen darat; tahap perantara memakai SubViewport per batu, sementara layout 5 memakai scene komponen; kredit CC BY 4.0 tersedia |
| [Strata](https://github.com/carthageadev/strata) | Terrain pixel art 3D/2.5D dengan elevasi dan layering | Terapkan prinsip top/side/edge dan geometri bertingkat melalui modul Godot | Adaptasi Godot orisinal aktif melalui `TerrainLayerProfile.gd` dan `TerrainGeometry.gd`: tiga profil kedalaman, top/side/edge, dan teras. Repo Unity tidak memiliki lisensi yang dinyatakan saat diperiksa; kode/asetnya tidak disalin. Pin serta batas ada di `tools/terrain-layers/source.json` |
| [Procedural Pixel Creatures](https://github.com/idlerunner00/procedural-pixel-creatures) | Ikan dan makhluk prosedural yang hidup | Generator C# offline menghasilkan spritesheet/metadata, animator dan perilaku berjalan di GDScript | Sepuluh spesies/722 bingkai aktif. Empat kawanan memakai cohesion/separation, idle/feed/swim/flee/hunt, arus kedalaman, dan penghindaran kontur; simulasi memeriksa 43.500 sampel serta 7.200 posisi tangkapan |
| [Fish Gen](https://github.com/JacobKulberg/fish-gen) | Fauna laut dekoratif dengan animasi putar | Generator offline PNG/JSON dan adapter GDScript yang mempertahankan `next`/yaw | Kandidat overnight memakai pin `0faa79003ca50a7d422b618cb59179d9834094f1`, atlas32bingkai dan tiga ikan dekoratif dengan batas kualitas/habitat. Reproduksi hash,960langkah animasi,5.400kontak air dan40frame native lulus; browser/ekspor/rilis masih menunggu. Sepuluh spesies/722bingkai gameplay tetap. MIT/izin hasil serta provenance disertakan. [Pilot aktual](reviews/overnight-fishgen-pilot.md), [audit awal](world/fish-gen-reference.md). |
| [img2threejs](https://github.com/img2threejs/img2threejs) | Membantu mengubah referensi gambar menjadi objek 3D | Rekonstruksi melalui kode pada tahap produksi, ekspor GLB, lalu import Godot | Terpasang sebagai alat offline terisolasi di `tools/img2threejs/`: forge resmi memvalidasi spesifikasi dan menghasilkan factory, Three.js mengekspor GLB backing tablet yang dimuat Godot. Ini blockout yang diuji dari tiga sudut, bukan persetujuan delapan tahap fidelity |
| [SpriteCook: shadowcasting, torchlight, fog of war](https://www.spritecook.ai/blog/2d-shadowcasting-torchlight-fog-of-war) | Senter, bayangan dinamis, dan visibilitas | Adaptasi algoritma pada kontur dunia dan lampu Godot | Lampu dan shadow engine aktif. `LivingWater.gd` mengadaptasi prinsip occlusion memakai perpotongan ray dengan kontur aktual, termasuk kedua tepi berkas cahaya. Sumber ini artikel, bukan paket runtime; bukan salinan kode shader artikel |
| [Ark Pixel Font](https://github.com/TakWolf/ark-pixel-font) | Tipografi piksel konsisten | Font OTF pada tema game, HUD, dialog, dan atlas | Ark Pixel 12px Latin aktif, OFL dan catatan sumber tersedia |
| [Pixelbolt](https://github.com/skulitom/Pixelbolt) | Aset dan animasi efek pendukung | CLI produksi PNG/atlas dari resep JSON; pemutaran native Godot | Generator dipatok 0.13.0. Percikan masuk air, tangkapan, dampak hujan pada jalur, api lentera, dan uap memakai atlas/resipenya; angin mengubah api/uap. Jumlah efek dibatasi |
| [Dungeon Crawl Stone Soup](https://github.com/crawl/crawl) dan [koleksi tiles](https://github.com/crawl/tiles) | Referensi peta modular dan material piksel yang dapat digunakan ulang | Prinsip vault buatan tangan relevan untuk komposisi; subset tekstur CC0 dapat menjadi material 3D Godot | Engine GPLv2+ tidak disalin. Empat tekstur lantai generik dari rilis CC0 Nov-2015 dipatok `a6ea1655`, disimpan beserta bukti persetujuan artis dan daftar pengecualian di `assets/source-2d/crawl-tiles/`; berkas runtime material tersedia di `resources/art/library/crawl/` dan dimuat oleh material modular daratan |
| [Blender Kiln](https://github.com/elithril/blender-kiln) | Pemeriksaan dan pipeline produksi objek 3D | Pemeriksa GLB resmi dijalankan offline; Blender/MCP bukan dependensi pemain | Modul MIT `checks.py`/`studiolib.py` commit `e9a42146` dijalankan melalui `tools/blender-kiln/check-assets.py` terhadap dua GLB runtime, tanpa mengubah modul upstream. Pemeriksaan mencatat geometri dan saran kompresi asli. Plugin Claude/Blender tidak dipasang; pemodelan Blender belum dijalankan |


Memasang seluruh referensi berarti setiap referensi memiliki jalur pemakaian yang nyata dan dapat diperiksa. Paket Unity dan toolkit Three.js tidak dapat dimasukkan begitu saja ke runtime GDScript. Untuk sumber yang berbeda engine, catat hasil adaptasi atau aset ekspornya secara eksplisit. Jangan menamai implementasi orisinal sebagai plugin upstream yang terpasang. Jangan menyalin kode tanpa izin lisensi.

## Arah visual dan budaya

- Engine utama: Godot, ekspor Web Compatibility, single-threaded.
- Arah visual: Dave the Diver, terutama In the Jungle; kedalaman tiga perempat, layering, parallax, perspektif atmosfer, serta skala karakter yang terbaca.
- Identitas: Jala Muara; arsitektur pesisir, bambu, anyaman, kain sehari-hari, dan kehidupan maritim Nusantara. Ikuti [arah budaya](brand/cultural-direction.md).
- Screenshot/video referensi berada pada `moodboard/` dan tetap diabaikan Git. Referensi komposisi tidak menjadi sprite, tekstur, musik, atau layout level yang disalin.
- Halaman referensi: [Steam screenshots](https://steamcommunity.com/app/1868140/screenshots/), [wiki](https://dave-the-diver.fandom.com/wiki/Dave_the_Diver_Wiki), [galeri In the Jungle](https://www.rpgfan.com/gallery/dave-the-diver-in-the-jungle-screenshots/), [video Dave](https://youtu.be/0lPOcU2PY4Q), dan [video In the Jungle](https://www.youtube.com/watch?v=D8n_a1qO9S8).

## Ukuran keberhasilan dunia yang hidup

Integrasi dinilai dari perubahan yang terlihat saat bermain: makhluk punya perilaku berbeda dan bereaksi terhadap pemain; air menunjukkan arah arus serta bereaksi terhadap gerakan; cahaya berhenti pada penghalang; material dan relief menyatukan objek dengan medan; cuaca dan waktu memengaruhi atmosfer tanpa mengubah hadiah secara tidak sah. Banyak dependensi tidak membuktikan hasil tersebut.

Lihat [panduan lingkungan](dynamic-environment-guidelines.md), [catatan referensi desain](design-reference-notes.md), [produksi aset](assets/asset-pipeline.md), dan [status pengembangan](development-status.md). Setiap integrasi berikutnya perlu mencatat versi sumber, lisensi, berkas runtime atau alat produksi, perintah reproduksi, serta bukti pengujian.

## Reproduksi dan pemeriksaan

- `npm run check:world`: tiga belas pemeriksaan Godot headless, termasuk terrain, 141 transformasi peta, animasi, perilaku fauna, air/occlusion, foley, perspektif atmosfer/parallax, geometri/renderer komponen darat, jalur, air permukaan, traversal teras dan jam dunia, lalu verifikasi 722 bingkai generator.
- `tools/img2threejs/README.md`: setup Python/Node lokal, pin upstream, validasi spec resmi, ekspor GLB dan render tiga sudut. Python/Three.js hanya alat produksi, tidak ikut runtime Godot browser.
- `tools/procedural-creatures/README.md`, `tools/pixelbolt/README.md`, dan `docs/assets/polyfork.md`: jalur produksi masing-masing sumber yang sudah dipakai.
- `VERIFY_LIVING=1 VERIFY_HYBRID=1 APP_TEST_ORIGIN=http://localhost:3100 node scripts/godot-browser.mjs`: perjalanan, simulasi makhluk yang benar-benar maju, arus, clipping cahaya, foley, tangkapan, gua, dan HUD dengan fixture privat.

Fog of war penuh, dampak cuaca pada ekonomi, dan damage predator baru tidak diklaim aktif. Hunter/prey pada fauna adalah perilaku visual; resource dan progres tetap diputuskan server.

## Pekerjaan baru: komposisi latar bawah air

**Status: implementasi native, uji semantik, dan enam pemeriksaan browser Chromium lokal lulus.** Tinjauan tangkapan privat `underwater-03-vertical-canyon-descent` dan `underwater-02-harpoon-cavern` memperlihatkan pemisahan batu dekat, formasi tengah, serta siluet jauh yang lebih dingin dan rendah kontras. Yang diadaptasi adalah hubungan skala, warna, dan ruang negatif; piksel maupun susunan level referensi tidak disalin.

| Kedalaman cerita | Komposisi latar orisinal yang dibutuhkan |
| --- | --- |
| Segaran, 0–25 m | Tebing kapur pucat bertingkat membingkai jalur; pilar karst jauh berwarna biru air, tambalan koral kecil, serta cahaya permukaan. Celah diagonal dan bagian tengah tetap lega agar penyelam, biota, dan tangkapan terbaca. |
| Wringin, 25–60 m | Tiga jarak rumpun vegetasi bawah air: siluet jauh tipis, sulur ganggang tengah yang mengapit lembah, serta tepian batu dekat yang lebih hangat. Vegetasi tidak menjadi tirai pekat di atas pemain. Nama fiksi Wringin tidak menjadi klaim bahwa akar beringin hidup sebagai lamun laut. |
| Jalatunda/Tamansari, 60–100 m | Rusuk gua kapur dan lengkung ruang dalam membentuk kedalaman; struktur penampung air atau batu roboh hanya samar di kejauhan. Pipa korporasi menjadi aksen rusak yang terbatas. Tanpa menyalin candi, aksara, atau lambang sakral tertentu; latar tidak mengesankan jalan Fase 2 sudah dapat dimainkan. |

Setiap zona memerlukan sedikitnya tiga bidang dekorasi dengan respons kamera berbeda. Bidang jauh lebih dingin, kurang jenuh, dan rendah kontras; bidang dekat lebih tajam dan hangat, sedangkan pemain/objek interaksi mempertahankan kontras tertinggi. Parallax mengikuti kamera tanpa menggeser terrain, collider, titik tangkapan, atau koordinat server. Kondisi malam/awan mengubah atmosfer dari state bersama. Pengurangan gerak mempertahankan petunjuk jarak yang statis dan menghentikan gerakan tambahan yang tidak diperlukan.

Penerimaan membutuhkan bukti semantik untuk perbedaan parallax/perspektif atmosfer, batas instance, tidak adanya perubahan collision/progres, dan pengurangan gerak; kemudian tangkapan browser pada beberapa posisi kamera. Banyak lapisan atau aset baru saja belum membuktikan kedalaman terlihat saat bermain. Rincian kontrak dan bukti terbaru dicatat pada [lingkungan](world/environment.md).


Daratan layout 5 dibangun dari lantai dan prop 3D dengan kamera elevasi 35°, bukan lagi bitmap dengan mask berjalan. Manifest bersama menentukan geometry, footprint, tangga, material dan validasi API. Hub memiliki coast visual organik, pelataran luas serta 19 pohon; hutan memiliki dua daratan luas, jembatan dan 43 pohon. Coast dan overlay rumput/jalan tidak mengubah area berjalan. Jam kosmetik berputar dalam 36 menit; status cerita tetap dari server. Bukti komponen/native tersedia; harness browser memeriksa kedua jembatan, pagar dan batas lantai melalui input keyboard. Isi dermaga dan variasi tepi jalur masih perlu dipoles. Lihat [daratan modular](world/land-layering.md).


## Pemeriksaan referensi tambahan

### Sprite AI

Referensi tambahan pengguna, 9 November 2026: [MCP Sprite AI](https://www.sprite-ai.art/mcp). Konfigurasi lokal Codex memakai endpoint `https://www.sprite-ai.art/api/mcp` dan nama environment variable `SPRITE_AI_API_KEY`; kredensial tidak disimpan dalam proyek. Pada pemeriksaan ini tool belum tersedia di sesi aktif dan environment variable belum diwariskan, sehingga autentikasi belum terverifikasi dan belum ada aset Sprite AI yang diimpor. Kandidat penggunaan: prop transparan, variasi sprite, dan normal map. Hasil tetap harus cocok dengan kamera, pivot, palet, serta skala dunia; sprite bangunan tidak menggantikan terrain 3D atau footprint fisik. Periksa lisensi per aset, khususnya galeri yang dapat dibatasi untuk penggunaan nonkomersial.

Pemeriksaan 8 November 2026 memakai sumber primer: [README Crawl](https://github.com/crawl/crawl/blob/acc896bb7366d6be8ae9b2f7d7ce85749d4398bf/README.md), [lisensi engine Crawl](https://github.com/crawl/crawl/blob/acc896bb7366d6be8ae9b2f7d7ce85749d4398bf/LICENSE), [deklarasi koleksi CC0](https://github.com/crawl/tiles/blob/a6ea1655db5c044829d9eea19a232fa6fcac87b0/README.md), [README Kiln](https://github.com/elithril/blender-kiln/blob/e9a421467dd95d0de71d45b3d331f8efa4b80f26/README.md), dan [lisensi MIT Kiln](https://github.com/elithril/blender-kiln/blob/e9a421467dd95d0de71d45b3d331f8efa4b80f26/LICENSE). Crawl adalah game roguelike lengkap; referensi vault bukan generator Godot yang terpasang. Status CC0 koleksi tiles tidak mengubah lisensi GPL kode engine. Kiln adalah workflow produksi di atas Blender MCP; pemakaian checker standar pustakanya di sini merupakan integrasi alat offline, bukan klaim bahwa seluruh model telah dibuat atau dianimasikan oleh Blender.

Reproduksi pemeriksa Kiln dan batasnya ada pada [tools/blender-kiln](../tools/blender-kiln/README.md). SFX pengguna dan pemilihan material foley dijelaskan pada [suara eksplorasi](audio/exploration-sfx.md).
