# Pembagian pekerjaan HUD, daratan, dan laut

Pengguna meminta pekerjaan dipisahkan ke subagent pada 9 November 2026. Pemisahan menggunakan branch dan Git worktree lokal; tidak memerlukan fork repository ke akun lain. Baseline bersama: `3d648e8`.

## Jalur dan kepemilikan

| Jalur | Branch / lokasi | Tanggung jawab | Batas |
| --- | --- | --- | --- |
| HUD dan artwork | `main`, workspace Jalasmara | Artwork asli, badge, ikon berwarna, panel sembilan potong, dialog, buku, inventori, minimap dan joystick | Tidak mengubah map, kalender, ekonomi atau API |
| Desa dan hutan | `work/map-desa-hutan`, workspace saudara `Jalasmara-map` | Memeriksa lalu memperbaiki jalan, sambungan jembatan, atap, elevasi dan keterbacaan ruang 3D | Tidak mengubah HUD, karakter, shader air atau kontrak save/portal |
| Laut | `work/laut-dinamis`, workspace saudara `Jalasmara-laut` | Memeriksa batu yang menapak, celah berenang, arus, buih, cahaya dan kedalaman | Tidak mengubah HUD, daratan, hadiah, tangkapan atau konsumsi oksigen |
| Integrasi | Root pada workspace utama | Menentukan kepemilikan file bersama, meninjau commit, menggabungkan, menguji build dan staging | Subagent tidak menggabungkan atau melakukan deployment sendiri |

Artwork HUD dan integrasi modal sedang ditangani dua subagent. Subagent daratan berjalan pada worktree terpisah. Jalur laut memakai slot subagent setelah pembuatan artwork selesai. Batas empat agent aktif termasuk root membuat sebagian pekerjaan harus mengantre; pemisahan branch tetap tersedia selama menunggu.

## Aturan penggabungan

1. Setiap subagent membaca implementasi dan bukti penerimaan yang ada sebelum menyatakan sesuatu belum dikerjakan. Perbaikan harus menjawab kekurangan yang masih nyata.
2. Subagent hanya menulis file dalam kepemilikannya. Perubahan pada kamera bersama, material bersama, konfigurasi proyek, manifest collision atau API dibicarakan dengan root sebelum diedit.
3. Mesh dan kamera tiga perempat tetap digunakan. Daratan memakai elevasi nyata; batu laut berpijak pada dasar. Parallax dan perspektif atmosfer tidak diganti gambar latar datar.
4. Kalender tetap satu sumber waktu: satu hari game selama 36 menit nyata. ID portal, save dan progres pemain tetap kompatibel.
5. Jalur daratan dan laut menyerahkan commit mandiri beserta temuan awal, daftar file, tangkapan sebelum/sesudah serta hasil pemeriksaan yang relevan. Root menggabungkan commit yang sudah ditinjau secara berurutan.
6. Import, export dan pengujian Godot yang memakai resource bersama dijadwalkan root. Tidak ada beberapa proses yang menulis cache impor workspace yang sama.
7. Setelah penggabungan, periksa HUD di atas map daratan dan laut, kontrol sentuh, transisi area, collision, pause modal dan profil kualitas. Hasil setiap branch saja belum membuktikan integrasi benar.
8. Rilis staging dibuat dari commit gabungan yang lulus pemeriksaan. Pengujian Windows dan Samsung S23 tetap dicatat terpisah dari pengujian browser lokal.

## Urutan hasil

- HUD tetap prioritas penerimaan berikutnya: artwork harus benar-benar terpasang dan ditinjau pada ukuran tampil, bukan berhenti pada atlas atau ikon garis.
- Daratan dapat dikerjakan bersamaan tanpa menunggu HUD selesai; fokus pertama mengikuti temuan pada sambungan jalan/jembatan dan volume bangunan.
- Laut dimulai setelah slot artwork tersedia. Scope implementasi dipilih dari hasil audit, supaya tidak mengulang fitur arus dan buih yang mungkin sudah ada.
- Perluasan tool authoring menunggu kebutuhan gameplay ini. Catatan tool dan lisensi tetap di [rencana next-gen](../nextgen-world-authoring.md).
