# Pengiriman awal Rencana 06: hutan, laut, dan dasar rutinitas

9 November 2026. Status kandidat: penerimaan lokal selesai, CI akhir dan staging belum diverifikasi. Runtime terakhir yang berubah ialah `2f7f55129c4bafacbf49449d703f3e7913917de3`; commit sesudahnya menambahkan harness dan bukti. PCK yang diuji memiliki SHA-256 `a9378a52c9fbb64ec96ae579bcef1ced1ab7920962823025e238a453eb8a716b`. Staging masih memakai baseline `efdacba` ketika laporan ini disiapkan. Hasil pipeline baseline atau kandidat awal `1f0d040` tidak dianggap sebagai CI final shader guard.

## Hasil yang dapat dinilai

- Hutan: kepala dan badan Nala terlihat melalui bukaan piksel hanya pada tajuk yang menghalanginya. Tajuk pulih setelah dilewati; batang dan collision tetap utuh. Mask alpha disimpan sekali per frame atlas, tanpa pembacaan GPU per frame. Tepian patch memakai strip dither terbatas, bukan tessellation seluruh lantai. [Perubahan native](06a-hutan-jalan.md), [rute browser](06a-forest-browser.md).
- Laut: collar platform 13 tersambung pada batu sumber/tujuan sebenarnya dan dibedakan dari dinding jauh. Outline gua mempunyai tiga pita relief yang bertemu tanpa celah internal. Seluruh tambahan berada di belakang bidang berenang; tiga model batu perpustakaan tetap tertanam pada reef. [Bukti geometri dan gambar](06a-ocean-collar-and-cave.md).
- Dasar aktivitas warga: perjalanan tetap tersedia pada reduced motion; pause dan penghalang menghentikan perpindahan serta fase langkah. Pemulihan rute memakai graf sah dan backoff terbatas. Tujuh profil diuji pada kerja, dialog, istirahat, hujan, pulang, pause dan halangan. Ini belum membuktikan berteduh di bawah atap atau animasi tubuh lengkap. [Laporan B1](06b1-village-routines.md).

Kamera ortografis 35°, terrain bertingkat, ruang 3D, perlengkapan terpisah, layout, posisi save, kalender 36 menit dan transaksi server dipertahankan. Tidak ada dependensi, gambar generatif, atau runtime authoring baru pada paket ini.

## Pemeriksaan kandidat gabungan

| Pemeriksaan | Bukti dan batas |
| --- | --- |
| Build dan tipe | Export Godot, build web dan typecheck lulus lokal. Guard akhir diperiksa lagi melalui native serta ekspor web tanpa error shader/script. |
| Kontrak dunia | 37 pemeriksaan Godot lulus pada paket gabungan; generator 10 spesies/722 frame tetap sah. Guard akhir juga melewati regresi occlusion terfokus. |
| API | 77 tes lulus, tidak ada gagal atau skip. Tidak ada kode API atau manifest otoritatif yang diubah. |
| Harness performa | 14 tes CPU lulus, termasuk pemisahan titik aktif/tidak aktif dan sumber PCK yang diintersep. |
| Hutan browser | Delapan pemeriksaan lulus, 121 respons posisi, nol error console/page atau API gagal; gerbang, kedua jembatan, joystick, jurnal/pause, restore tajuk, save/reload dan portal dilewati dengan input aktual. |
| Malam dan rumah | Tujuh pemeriksaan dan delapan operasi utama lulus: tiga pelayanan, tutup shift, rumah, tidur sekali dan reload. HUD/bag pada 667×375 serta 390×844 tetap bekerja; inset aman diemulasikan melalui host. [Laporan malam](06a-night-regression.md). |
| Profiling lokal | Baseline/kandidat lima scene × dua profil, rerun hutan, delapan capture kontrol tidak aktif dan empat aktif. Median lama/guard hampir sama. Spike guard 366,7 ms tetap dicatat; tidak ada klaim speedup. [Data dan metode](../performance/06p-comparison.md). |

Semua pemain uji lokal dibuat khusus dengan UUID dan dibersihkan bersama sesi/receipt miliknya. Akun pengelola tidak dipakai. Pemeriksaan browser memakai Chromium/SwiftShader dan emulasi sentuh, bukan Windows atau Samsung S23 fisik. RAF adalah interval callback browser, bukan timer GPU. Pengukuran memori WASM/VRAM, sesi panjang, thermal dan input latency belum tersedia.

## Peninjauan desain oleh integrator

- **Hard Gate PASS dalam ruang lingkup paket:** source visual, hasil build, gambar native dan browser diperiksa; portal, joystick, jurnal, bag dan tidur benar-benar berfungsi. Tidak ada aset, metrik produk, kontrol atau halaman baru. Angka berasal dari hasil run dan state server; tidak ada klaim perangkat yang belum diuji. Perubahan tidak menambah teks UI atau mengganti sistem kontras/font yang sudah diterima.
- **Purpose Gate PASS:** reveal setempat memperjelas pemain sambil menjaga tajuk sebagai foreground; collar dan relief menunjukkan volume batu yang bertumpu. Tepi piksel menyatukan bahan tanpa menambah penghalang atau lampu. Warna dan pencahayaan mengikuti arah comfy tropis yang diberikan pengguna.
- **Liveliness PASS:** ENERGY 2, RHYTHM 2, MOTION 1 mengikuti arah yang sudah ditetapkan. Nala menjadi fokus saat berjalan; gerak daun, cahaya dan kedalaman tetap terlihat. Peralihan reveal dibatasi 140 ms masuk, 180 ms tahan, dan 240 ms pulih. Tidak ada ornamen HUD baru yang mengambil ruang permainan.
- **Craftsmanship PASS:** kelulusan geometri dilengkapi inspeksi gambar; fixture yang belum menginisialisasi pemain atau belum menyelesaikan fade dibuang dan diulang. Gambar malam dan rute sentuh diperiksa pada ukuran bermain. Pengujian membedakan simulasi jadwal, input browser nyata, serta keterbatasan perangkat.

## Pekerjaan berikutnya

06-B2 masih terpisah: pilot Ujang untuk telapak yang tertanam, panjang anggota tubuh tetap, arah yang benar, dan pengukuran kontak alat yang independen. Audit menunjukkan tujuh tujuan hujan berada di luar atap fisik; perbaikannya belum masuk paket ini. Pilot Darmi/Sari serta aktivitas tubuh warga berikutnya mengikuti hasil Ujang. [Audit pilot dan shelter](06b2-pilot-preparation.md).

06-C masih terbuka: rumah pribadi lurah, direktur tersendiri dengan kontainer/RV yang sesuai peran, serta Laskar Kognisi beserta rute/dialog. 06-D mencakup perluasan rumah/kebun/keramba/interior dan UI website. [Noxe/PixelDoll](../world/noxe-pixeldoll-reference.md) sudah diperiksa source dan lisensinya; belum ada kode/aset upstream yang disalin. Noxe bukan editor drag-and-drop dan belum mempunyai exporter GLB; PixelDoll memerlukan adapter billboard serta validasi arah, anatomi dan anchor sebelum batch pakaian.
