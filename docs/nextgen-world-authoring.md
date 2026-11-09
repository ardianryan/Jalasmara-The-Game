# Rencana next-gen world authoring

Prioritas aktif: [Rencana 04: HUD, fullscreen, performa, dan gerak Nala](plans/04-hud-fullscreen-performa-dan-gerak.md). Pengguna telah mengizinkan implementasi Rencana 04, kemudian penyelesaian backlog desa/hutan/laut sesuai urutan. Penyelesaian pengalaman bermain ini mendahului perluasan alat authoring.

Putaran dasar yang diimplementasikan mengikuti [Rencana 03: desa hidup dan siklus harian](plans/03-desa-hidup-dan-siklus-harian.md). Kalender, rumah, dua petak kebun, pasar/balai dan tiga pilot animasi sudah tersedia; perluasan warga, arah animasi dan playtest tetap mengikuti catatan penerimaan rencana itu. Dokumen ini tetap menjadi backlog alat authoring; perluasan tooling mengikuti kebutuhan hasil yang dapat dimainkan.

Prioritas pengguna, 9 November 2026: selesaikan perubahan desa, hutan, laut, pakaian modular, warna, dan HUD yang sedang berjalan sebelum menambah tooling baru.

Sesudah rilis tersebut diverifikasi, pengguna mengizinkan integrasi alat yang dapat digunakan. **Jalasmara WorldKit** sekarang menyediakan adapter draft OpenWorld, wrapper offline Pixel Snapper, serta konversi palet Image-to-Pixel. Kode upstream tetap diatribusikan; nama WorldKit merujuk pada lapisan integrasi kita. Panduan penggunaan ada pada [README proyek](../README.md#jalasmara-worldkit).

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
| [Sprite AI](https://www.sprite-ai.art/mcp)                                          | Konfigurasi MCP lokal terdaftar; autentikasi sesi belum terverifikasi. Tidak ada key atau aset dari layanan ini dalam repository.                                                            |

Temuan sumber dan lisensi tiga proyek pertama: [riset authoring](world/murder-authoring-reference.md). Warna target: [arah comfy](art-direction-comfy.md).

## Urutan setelah rilis berjalan selesai

1. Pilot satu area desa dengan ID objek stabil serta overlay lantai, collider, elevasi, tangga, dan rute NPC.
2. Editor atau adapter mengekspor manifest bersama yang dibaca Godot dan API. Preview visual tidak boleh menjadi sumber collision yang berbeda.
3. Validasi akses spawn–POI, endpoint portal, clearance tubuh, sambungan tangga, dan migrasi save sebelum menaikkan versi layout.
4. Uji satu aset dari alat sprite secara offline: alpha, ukuran piksel, pivot kaki, arah, konsistensi palet, dan lisensi. Catat hasil sebelum mengerjakan batch.
5. Perluas ke hutan dan laut setelah pilot lolos; pertahankan kamera tiga perempat, mesh 3D, parallax, dan perspektif atmosfer.

Bagian yang belum ditandai terpasang tetap backlog. Tidak ada migrasi engine, runtime aturan AI, atau perubahan ekonomi pemain dalam integrasi authoring ini.
