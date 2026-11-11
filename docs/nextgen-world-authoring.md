# Rencana next-gen world authoring

Prioritas berikutnya mengikuti [Rencana 06: finishing dunia, aktivitas NPC, dan perluasan desa](plans/06-finishing-dunia-npc-dan-perluasan-desa.md). Keterbacaan hutan/laut dan dasar rutinitas warga sudah dirilis serta diperiksa di staging; bukti ada pada [laporan awal 06-A](reviews/06a-delivery.md). Profiling lokal mencakup kontrol paket lama/baru dengan canopy aktif maupun tidak aktif. Pilot tubuh, perluasan desa, sesi panjang serta Windows/S23 fisik tetap terbuka. Implementasi inti [Rencana 04](plans/04-hud-fullscreen-performa-dan-gerak.md) beserta revisi HUD/loading sudah dirilis. Penyelesaian pengalaman bermain ini mendahului perluasan alat authoring.

Putaran dasar yang diimplementasikan mengikuti [Rencana 03: desa hidup dan siklus harian](plans/03-desa-hidup-dan-siklus-harian.md). Kalender, rumah, dua petak kebun, pasar/balai dan tiga pilot animasi sudah tersedia; perluasan warga, arah animasi dan playtest tetap mengikuti catatan penerimaan rencana itu. Dokumen ini tetap menjadi backlog alat authoring; perluasan tooling mengikuti kebutuhan hasil yang dapat dimainkan.

Prioritas pengguna, 9 November 2026: selesaikan perubahan desa, hutan, laut, pakaian modular, warna, dan HUD yang sedang berjalan sebelum menambah tooling baru.

Sesudah rilis tersebut diverifikasi, pengguna mengizinkan integrasi alat yang dapat digunakan. **Jalasmara WorldKit** sekarang menyediakan adapter draft OpenWorld, wrapper offline Pixel Snapper, serta konversi palet Image-to-Pixel. Kode upstream tetap diatribusikan; nama WorldKit merujuk pada lapisan integrasi kita. Panduan penggunaan ada pada [README proyek](../README.md#jalasmara-worldkit).

## Additional offline authoring tools, 11 November 2026

- [Cinetic](../tools/cinetic/README.md) is installed as a pinned local checkout for future trailers and pre-rendered cutscenes. Its film stack is not installed into Godot or validated end to end. Film renderers and music have separate licenses.
- [Xprite Pixelate](../tools/xprite-pixelate/README.md) is installed in an isolated npm directory for automatic native-grid recovery. A synthetic 12×12-grid smoke check passed. Existing Pixel Snapper and Image-to-Pixel remain available for manual grid cleanup and palette work. Neither Xprite nor the alternatives makes pixel art photorealistic.
- [unfake.js](https://github.com/jenissimo/unfake.js/tree/663686899e8394dfda25efd7f2a947f008c6f676) was inspected but not installed: its pixel cleanup overlaps the installed tools; its browser vectorizer is outside the current asset need. Its MIT source remains a future reference.
- [TerrainGenerator](https://github.com/aidan-clyens/TerrainGenerator/tree/02799328a7b321d4ca5b22f603dfdabd12db2eeb) is a Unity generator under GPL-3.0. It is not a drop-in replacement for the current Godot terrain/grounding/collision system. No source or assets were copied into the project.

## Referensi tersimpan

| Referensi                                                                           | Status dan kemungkinan penggunaan                                                                                                                                                            |
| ----------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [Murder](https://github.com/isadorasophia/murder)                                   | Ditinjau sebagai pola editor entitas, prefab, layer, inspector, dan undo. Belum diimpor.                                                                                                     |
| [Pixprite](https://github.com/vicimpa/pixprite)                                     | Ditinjau sebagai alat penyunting sprite/animasi offline. Round-trip ke Godot belum diuji.                                                                                                    |
| [OpenWorld](https://github.com/SihanXU/openworld)                                   | Adapter offline asli WorldKit sudah menghasilkan draft floor/footprint/elevasi/portal dan memvalidasinya. Engine dan aset upstream tidak diimpor.                                            |
| [Mono-pix](https://github.com/handsupmin/mono-pix)                                  | README ditinjau: aplikasi browser untuk grid dan konversi palet, menggunakan fast-pixelizer. Belum dipasang; fungsi beririsan dengan dua alat offline yang sudah dipilih.                    |
| [SpriteFusion Pixel Snapper](https://github.com/Hugo-Dz/spritefusion-pixel-snapper) | CLI Rust MIT dikunci versinya dan dipakai melalui wrapper offline. Build serta pengujian grid, alpha, palet, dan batch lulus. Ukuran atlas tetap perlu ditinjau.                             |
| [Aseprite MCP](https://github.com/diivi/aseprite-mcp)                               | README ditinjau sebagai server MCP Python pengendali Aseprite. Executable Aseprite tidak ditemukan pada PATH atau instalasi Applications yang diperiksa; integrasi runtime belum dijalankan. |
| [Image-to-Pixel](https://github.com/Tezumie/Image-to-Pixel)                         | Paket 3.2.0 MIT dipakai pada adapter CPU offline dengan palet asli Jalasmara dan laporan hash/dimensi. Preview aset warga dibuat; PNG produksi tidak otomatis diganti.                       |
| [Sprite AI](https://www.sprite-ai.art/mcp)                                          | Referensi MCP tersimpan; tool Sprite AI tidak tersedia pada daftar tool aktif sesi overnight. API tidak dipakai dan key tidak dimasukkan ke source/laporan.                                                            |
| [Noxe Pixel Engine](https://github.com/danieljan-design/noxe-pixel-engine) | Port terbatas orbit/snap pada `LandCameraPose.gd` masuk kandidat06-B, dengan pin/MIT dikemas dan tes native. Metode cottage/pier diadopsi pada konstruksi rumah Godot orisinal. Kamera gameplay kiri −45° sudah dipasang bersama inverse input/proyeksi; rute publik desa–hutan lulus. Ini bukan editor bangunan drag-and-drop atau runtime Three.js kedua. PNG/MP4 upstream tersedia, exporter GLB belum ada. |
| [PixelDoll](https://github.com/Shilo/PixelDoll) | Kode MIT dan kontrak layer/ekspor diperiksa pada revisi terkunci. Kandidat authoring pakaian/item; ekspor Godot masih 2D dan perlu adapter billboard 3D. Gunakan Unique 8 untuk arah mandiri; generasi memakai PixelLab, bukan Sprite AI. Belum diintegrasikan. |
| [Fish Gen](https://github.com/JacobKulberg/fish-gen) | Source `0faa79003ca50a7d422b618cb59179d9834094f1` tersimpan pada clone offline lokal, MIT, keluaran PNG/JSON/Godot SpriteFrames. Generator offline dan adapter sudah dipakai: atlas orisinal32bingkai, tiga ikan dekoratif/satu pada low, reproduksi/kontak/native lulus; masuk ekspor593/PCK1315 dan tetap pada rilis PCK73d. Sepuluh spesies gameplay tidak diganti. [Pin, lisensi dan batas](world/fish-gen-reference.md). |

Temuan sumber dan lisensi tiga proyek pertama: [riset authoring](world/murder-authoring-reference.md). Warna target: [arah comfy](art-direction-comfy.md).

Temuan, pin, lisensi, batas, serta pilot bangunan/karakter terbaru: [Noxe dan PixelDoll](world/noxe-pixeldoll-reference.md). Pilot mengikuti paket 06-B/06-C sesuai kebutuhan; perluasan editor dan interior playable tidak mendahului perbaikan keterbacaan dunia 06-A.

## Urutan setelah rilis berjalan selesai

1. Pilot satu area desa dengan ID objek stabil serta overlay lantai, collider, elevasi, tangga, dan rute NPC.
2. Editor atau adapter mengekspor manifest bersama yang dibaca Godot dan API. Preview visual tidak boleh menjadi sumber collision yang berbeda.
3. Validasi akses spawn–POI, endpoint portal, clearance tubuh, sambungan tangga, dan migrasi save sebelum menaikkan versi layout.
4. Uji satu aset dari alat sprite secara offline: alpha, ukuran piksel, pivot kaki, arah, konsistensi palet, dan lisensi. Catat hasil sebelum mengerjakan batch.
5. Perluas ke hutan dan laut setelah pilot lolos; pertahankan kamera tiga perempat, mesh 3D, parallax, dan perspektif atmosfer.

Bagian yang belum ditandai terpasang tetap backlog. Tidak ada migrasi engine, runtime aturan AI, atau perubahan ekonomi pemain dalam integrasi authoring ini.
