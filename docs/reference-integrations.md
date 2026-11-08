# Referensi dan integrasi Jalasmara

Catatan permintaan pengguna, 8 November 2026. Dokumen ini menjadi daftar tetap agar referensi tidak hilang saat pekerjaan berpindah sesi. Baseline sebelum pekerjaan ini adalah commit `1f99c35`. Status di bawah diperbarui berdasarkan implementasi dan pengujian lokal; bukti browser/deployment dirujuk pada status pengembangan.

## Referensi teknis yang diberikan

| Referensi | Tujuan pengguna | Integrasi yang sesuai dengan Godot Web | Status implementasi |
| --- | --- | --- | --- |
| [Polyfork](https://polyfork.dev/) | Prop dan bentuk alam 3D | Model GLB dimuat langsung; render ortografis dipakai untuk prop 2D | GLB batu karang aktif pada laut; pakis dan bambu pada daratan; kredit CC BY 4.0 tersedia |
| [Strata](https://github.com/carthageadev/strata) | Terrain pixel art 3D/2.5D dengan elevasi dan layering | Terapkan prinsip top/side/edge dan geometri bertingkat melalui modul Godot | Adaptasi Godot orisinal aktif melalui `TerrainLayerProfile.gd` dan `TerrainGeometry.gd`: tiga profil kedalaman, top/side/edge, dan teras. Repo Unity tidak memiliki lisensi yang dinyatakan saat diperiksa; kode/asetnya tidak disalin. Pin serta batas ada di `tools/terrain-layers/source.json` |
| [Procedural Pixel Creatures](https://github.com/idlerunner00/procedural-pixel-creatures) | Ikan dan makhluk prosedural yang hidup | Generator C# offline menghasilkan spritesheet/metadata, animator dan perilaku berjalan di GDScript | Sepuluh spesies/722 bingkai aktif. Empat kawanan memakai cohesion/separation, idle/feed/swim/flee/hunt, arus kedalaman, dan penghindaran kontur; simulasi memeriksa 43.500 sampel serta 7.200 posisi tangkapan |
| [img2threejs](https://github.com/img2threejs/img2threejs) | Membantu mengubah referensi gambar menjadi objek 3D | Rekonstruksi melalui kode pada tahap produksi, ekspor GLB, lalu import Godot | Terpasang sebagai alat offline terisolasi di `tools/img2threejs/`: forge resmi memvalidasi spesifikasi dan menghasilkan factory, Three.js mengekspor GLB backing tablet yang dimuat Godot. Ini blockout yang diuji dari tiga sudut, bukan persetujuan delapan tahap fidelity |
| [SpriteCook: shadowcasting, torchlight, fog of war](https://www.spritecook.ai/blog/2d-shadowcasting-torchlight-fog-of-war) | Senter, bayangan dinamis, dan visibilitas | Adaptasi algoritma pada kontur dunia dan lampu Godot | Lampu dan shadow engine aktif. `LivingWater.gd` mengadaptasi prinsip occlusion memakai perpotongan ray dengan kontur aktual, termasuk kedua tepi berkas cahaya. Sumber ini artikel, bukan paket runtime; bukan salinan kode shader artikel |
| [Ark Pixel Font](https://github.com/TakWolf/ark-pixel-font) | Tipografi piksel konsisten | Font OTF pada tema game, HUD, dialog, dan atlas | Ark Pixel 12px Latin aktif, OFL dan catatan sumber tersedia |
| [Pixelbolt](https://github.com/skulitom/Pixelbolt) | Aset dan animasi efek pendukung | CLI produksi PNG/atlas dari resep JSON; pemutaran native Godot | Generator dipatok 0.13.0. Percikan masuk air, tangkapan, dampak hujan pada jalur, api lentera, dan uap memakai atlas/resipenya; angin mengubah api/uap. Jumlah efek dibatasi |

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

- `npm run check:world`: enam pemeriksaan Godot headless, termasuk terrain, 141 transformasi peta, animasi, perilaku fauna, air/occlusion, dan foley, lalu verifikasi 722 bingkai generator.
- `tools/img2threejs/README.md`: setup Python/Node lokal, pin upstream, validasi spec resmi, ekspor GLB dan render tiga sudut. Python/Three.js hanya alat produksi, tidak ikut runtime Godot browser.
- `tools/procedural-creatures/README.md`, `tools/pixelbolt/README.md`, dan `docs/assets/polyfork.md`: jalur produksi masing-masing sumber yang sudah dipakai.
- `VERIFY_LIVING=1 VERIFY_HYBRID=1 APP_TEST_ORIGIN=http://localhost:3100 node scripts/godot-browser.mjs`: perjalanan, simulasi makhluk yang benar-benar maju, arus, clipping cahaya, foley, tangkapan, gua, dan HUD dengan fixture privat.

Fog of war penuh, dampak cuaca pada ekonomi, dan damage predator baru tidak diklaim aktif. Hunter/prey pada fauna adalah perilaku visual; resource dan progres tetap diputuskan server.
