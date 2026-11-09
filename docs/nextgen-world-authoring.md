# Rencana next-gen world authoring

Prioritas pengguna, 9 November 2026: selesaikan perubahan desa, hutan, laut, pakaian modular, warna, dan HUD yang sedang berjalan sebelum menambah tooling baru.

## Referensi tersimpan

| Referensi | Status dan kemungkinan penggunaan |
| --- | --- |
| [Murder](https://github.com/isadorasophia/murder) | Ditinjau sebagai pola editor entitas, prefab, layer, inspector, dan undo. Belum diimpor. |
| [Pixprite](https://github.com/vicimpa/pixprite) | Ditinjau sebagai alat penyunting sprite/animasi offline. Round-trip ke Godot belum diuji. |
| [OpenWorld](https://github.com/SihanXU/openworld) | Ditinjau untuk peta berbasis data, portal, dan adapter offline. Format aktif bukan impor Tiled JSON langsung. |
| [Mono-pix](https://github.com/handsupmin/mono-pix) | Referensi baru pengguna; fungsi, lisensi, kompatibilitas, dan biaya adopsi belum diaudit. Belum dipasang. |
| [Sprite AI](https://www.sprite-ai.art/mcp) | Konfigurasi MCP lokal terdaftar; autentikasi sesi belum terverifikasi. Tidak ada key atau aset dari layanan ini dalam repository. |

Temuan sumber dan lisensi tiga proyek pertama: [riset authoring](world/murder-authoring-reference.md). Warna target: [arah comfy](art-direction-comfy.md).

## Urutan setelah rilis berjalan selesai

1. Pilot satu area desa dengan ID objek stabil serta overlay lantai, collider, elevasi, tangga, dan rute NPC.
2. Editor atau adapter mengekspor manifest bersama yang dibaca Godot dan API. Preview visual tidak boleh menjadi sumber collision yang berbeda.
3. Validasi akses spawn–POI, endpoint portal, clearance tubuh, sambungan tangga, dan migrasi save sebelum menaikkan versi layout.
4. Uji satu aset dari alat sprite secara offline: alpha, ukuran piksel, pivot kaki, arah, konsistensi palet, dan lisensi. Catat hasil sebelum mengerjakan batch.
5. Perluas ke hutan dan laut setelah pilot lolos; pertahankan kamera tiga perempat, mesh 3D, parallax, dan perspektif atmosfer.

Ini backlog, bukan klaim fitur terpasang. Tidak ada migrasi engine, runtime aturan AI, atau perubahan ekonomi pemain dalam pencatatan referensi ini.
