# Pengiriman awal Rencana 06: hutan, laut, dan dasar rutinitas

9 November 2026. **Paket awal 06-A dan dasar B1 sudah dirilis serta diperiksa di staging** pada source `9ba21c6bdcb86de1b1732fe4d646fc5a27099eec`. Runtime terakhir yang berubah ialah `2f7f55129c4bafacbf49449d703f3e7913917de3`; commit sesudahnya menambahkan harness dan bukti. PCK lokal, image aplikasi, host staging, serta unduhan HTTPS publik cocok pada SHA-256 `a9378a52c9fbb64ec96ae579bcef1ced1ab7920962823025e238a453eb8a716b`. Hasil pipeline baseline atau kandidat awal `1f0d040` tidak dianggap sebagai CI final shader guard.

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

## CI dan staging

[Pipeline 3043718567](https://gitlab.com/ardianryan/jalasmara-the-game/-/pipelines/3043718567) lulus seluruh lima job untuk source rilis `9ba21c6`: verify, ekspor Godot, build, CodeQL dan laporan GitHub. Artefak nyata mencatat 77 tes API tanpa gagal/skip, 14 tes harness performa, 37 pemeriksaan dunia, serta 14 pemeriksaan sintesis SFX. CodeQL menjalankan 201 aturan tanpa temuan; tiga audit dependensi mencatat nol kerentanan. GitHub `ci-reports` menunjuk SHA/pipeline yang sama; Actions tetap nonaktif.

Pemeriksaan tambahan pada commit dokumentasi/harness `c175725` menemukan satu warning pada alur angka ukuran unduhan ke laporan lokal, meskipun job CodeQL sukses. Harness diperketat dengan batas ukuran release serta validasi ukuran/hash sebelum menyimpan metadata konstanta yang cocok; tidak ada suppression. Kelima pemeriksaan publik diulang pada source harness yang diperbaiki dan kembali lulus, dengan fixture baru dibersihkan. [Rincian pengujian ulang](06a-staging-smoke.md#pembatasan-metadata-unduhan-dan-pengujian-ulang) memisahkan hasil ini dari CI source runtime yang dirilis; game dan paket staging tidak berubah.

Staging memakai image `sha256:5c5a503d3d228042f457d8ddbe9785a20a7a5b49b035d5ea34f4346d01bf937a`. Build dilakukan terpisah sebelum aktivasi. Hanya container aplikasi diganti; container/volume MongoDB dan Redis, bind `10.1.0.8:3000`, serta konfigurasi lingkungan dipertahankan. Tidak ada reset akun, seed ulang, atau perubahan proxy. Health upstream dan publik berhasil. Lima pemeriksaan [smoke HTTPS](06a-staging-smoke.md) lulus tanpa error browser/API: hash paket, login/ready, gerbang/tajuk, jurnal, serta posisi setelah reload. Fixture publik dan seluruh sesinya dibersihkan; integrator juga memeriksa gambar tajuk 667×375 secara langsung.

Backup `/var/backups/jalasmara/jalasmara-20261109T070111Z.archive.gz` mempunyai SHA-256 `259ff2559672967501aa714ba160237f39297298eb0033a95e1ed6588f1d5d3e`. Restore terpisah memulihkan 29 dokumen tanpa gagal, membandingkan jumlah per koleksi dengan data hidup, lalu menghapus database pemeriksaan. Image rollback `jalasmara:pre-06a-9ba21c6` tetap menunjuk image baseline `b18a2852`.

Percobaan aktivasi awal kembali ke image lama karena probe host mengandalkan `curl`, yang tidak tersedia di VPS. Probe diganti dengan Node di container aplikasi; metadata source host dan hash paket kemudian dicocokkan kembali. Untuk menjalankan probe melalui skrip SSH/stdin, tutup stdin `docker compose exec -T` dengan `</dev/null` agar perintah tersebut tidak mengambil sisa skrip. Status akhir di atas diperiksa sesudah aktivasi dan finalisasi, bukan disimpulkan dari exit code deployment saja.

## Peninjauan desain oleh integrator

- **Hard Gate PASS dalam ruang lingkup paket:** source visual, hasil build, gambar native dan browser diperiksa; portal, joystick, jurnal, bag dan tidur benar-benar berfungsi. Tidak ada aset, metrik produk, kontrol atau halaman baru. Angka berasal dari hasil run dan state server; tidak ada klaim perangkat yang belum diuji. Perubahan tidak menambah teks UI atau mengganti sistem kontras/font yang sudah diterima.
- **Purpose Gate PASS:** reveal setempat memperjelas pemain sambil menjaga tajuk sebagai foreground; collar dan relief menunjukkan volume batu yang bertumpu. Tepi piksel menyatukan bahan tanpa menambah penghalang atau lampu. Warna dan pencahayaan mengikuti arah comfy tropis yang diberikan pengguna.
- **Liveliness PASS:** ENERGY 2, RHYTHM 2, MOTION 1 mengikuti arah yang sudah ditetapkan. Nala menjadi fokus saat berjalan; gerak daun, cahaya dan kedalaman tetap terlihat. Peralihan reveal dibatasi 140 ms masuk, 180 ms tahan, dan 240 ms pulih. Tidak ada ornamen HUD baru yang mengambil ruang permainan.
- **Craftsmanship PASS:** kelulusan geometri dilengkapi inspeksi gambar; fixture yang belum menginisialisasi pemain atau belum menyelesaikan fade dibuang dan diulang. Gambar malam dan rute sentuh diperiksa pada ukuran bermain. Pengujian membedakan simulasi jadwal, input browser nyata, serta keterbatasan perangkat.

## Pekerjaan berikutnya

06-B2 masih terpisah: kandidat mekanik Ujang `f7d3f0d50d5f970c92c53fcddfe0aa21c66b3bad` berada di cabang `work/06b-body-pilot`, tidak digabungkan ke paket publik. Sebanyak 1.074 pemeriksaan kontak/tangga native lulus, tetapi gambar empat arah, siluet langkah, dan kontak genggaman independen belum diterima. Audit menunjukkan tujuh tujuan hujan berada di luar atap fisik; perbaikannya belum masuk paket ini. Pilot Darmi/Sari serta aktivitas tubuh warga berikutnya mengikuti hasil Ujang. [Audit pilot dan shelter](06b2-pilot-preparation.md).

06-C masih terbuka: rumah pribadi lurah, direktur tersendiri dengan kontainer/RV yang sesuai peran, serta Laskar Kognisi beserta rute/dialog. [Persiapan C](06c-preparation.md) mencatat identitas, lot yang belum sah, serta risiko interaksi dan migrasi; belum menambahkan bangunan/pemeran. 06-D mencakup perluasan rumah/kebun/keramba/interior dan UI website. [Noxe/PixelDoll](../world/noxe-pixeldoll-reference.md) sudah diperiksa source dan lisensinya; belum ada kode/aset upstream yang disalin. Noxe bukan editor drag-and-drop dan belum mempunyai exporter GLB; PixelDoll memerlukan adapter billboard serta validasi arah, anatomi dan anchor sebelum batch pakaian.
