# 06-A: penerimaan browser pada rute hutan sebenarnya

9 November 2026. Pengujian lokal memakai ekspor Godot dan API yang sebenarnya di `http://localhost:3100`, setelah penggabungan hutan, laut, dan rutinitas NPC. Source runtime yang disajikan adalah `2f7f55129c4bafacbf49449d703f3e7913917de3`; SHA-256 PCK `a9378a52c9fbb64ec96ae579bcef1ced1ab7920962823025e238a453eb8a716b` cocok dengan berkas ekspor integrator. Lane ini menambahkan harness dan laporan saja, tanpa mengubah gameplay atau renderer.

## Cara menjalankan dan isolasi

```sh
node --import tsx scripts/plan06-forest-browser.mjs
```

Harness menolak origin, MongoDB, dan Redis nonlokal serta fixture akun yang sudah ada. Ia membuat satu pemain sementara dengan UUID baru dan kata sandi acak dalam memori, kemudian masuk melalui formulir situs. Pemain mulai dari spawn desa normal dengan progres awal dan kalender 10:00. Seluruh perjalanan menggunakan tombol gerak, tombol interaksi, dan input sentuh Chromium. Snapshot hanya dibaca untuk diagnosis dan navigasi. Tidak ada teleport, injeksi posisi, pemalsuan API, intersepsi PCK, atau pemanggilan aksi langsung melalui debug.

Setelah selesai atau gagal, blok `finally` menutup Chromium dan menghapus pemain milik run tersebut, receipt berawalan UUID tersebut, shift miliknya, serta kunci sesi/surface/home/calendar/dive yang tepat. Ia tidak memakai kredensial pengelola atau berkas kata sandi. Run ini berakhir dengan `ownTemporaryPlayerRemoved: true`.

## Hasil aktual

Run selesai dengan exit 0, delapan pemeriksaan lulus, 121 respons sinkronisasi posisi, tanpa error console/page atau respons API gagal. Browser memakai Chromium WebGL melalui SwiftShader pada host pengembangan. Ukuran 667×375 dan 844×390 memakai emulasi sentuh; 1440×900 adalah konteks sentuh yang diperbesar untuk memeriksa reflow. Ini bukan pengujian mouse desktop terpisah, perangkat Samsung S23, atau benchmark GPU perangkat keras.

| Pemeriksaan | Bukti |
| --- | --- |
| Desa → gerbang → masuk hutan | Berjalan mengikuti graf jalan desa dari spawn normal, menekan interaksi di gerbang, menerima perpindahan API sebenarnya ke `[200,1320]`; renderer melaporkan satu pemain 3D. |
| Tajuk gerbang dan jurnal 667×375 | Berjalan menuju `[350,1250]`, berhenti aktual pada `[338.47,1254.20]`. Tiga dari 47 tajuk mempunyai reveal yang sudah selesai (`amount = 1`), satu mask bersama, batang tetap utuh. Jurnal dibuka lewat ikon sentuh; input gerak tidak menggeser pemain. Heartbeat jeda berhasil dan menit kalender server tetap sama setelah 6,2 detik, melewati heartbeat berikutnya. |
| Joystick 844×390 | Drag joystick bulat menghasilkan sumbu nonnol dan perpindahan fisik lebih dari dua satuan dunia; sesudah touch release sumbu kembali nol. |
| Reflow 1440×900 | Iframe memenuhi viewport, tidak ada overflow horizontal, pusat kontrol tetap di dalam layar, proyeksi kamera tetap 35°, satu pemain terlihat, dan galat proyeksi telapak di bawah 0,1. |
| Pemulihan tajuk dan reload | Berjalan ke Celah Cahaya Tajuk, berhenti aktual pada `[636.46,1051.48]`. Ketiga indeks tajuk gerbang telah pulih; jumlah reveal nol. Posisi tersimpan oleh API dan dimuat kembali pada koordinat yang sama sesudah reload halaman. |
| Jembatan atas | Melintasi dek secara fisik dari sisi barat menuju aktual `[1593.23,639.33]`, perpindahan lebih dari 250 satuan; metadata render menunjukkan dek berorientasi, rail, ketebalan, dan pivot daratan yang sah. |
| Jembatan bawah | Melintasi dek secara fisik menuju aktual `[1612.71,1076.08]` dengan pemeriksaan geometri yang sama, tanpa masuk mode menyelam. |
| Portal kembali | Berjalan kembali ke pintu hutan, berinteraksi, menerima perpindahan API sebenarnya dan spawn desa `[2295,125]`. Area server kembali `hub`; koin tetap 200, hari cerita tetap 1, dan durasi kalender tetap 36 menit. |

Kalender dan cuaca berjalan normal selama perjalanan, sehingga capture browser ini bukan pembandingan jam tetap. Capture awal hutan menunjukkan 10:31 dan cuaca cerah; capture pulang sekitar 11:41. Untuk pembandingan delapan arah, malam/hujan, dan profil Ringan/Seimbang pada kondisi tetap, gunakan [laporan native 06-A1/A2](06a-hutan-jalan.md).

## Artefak dan penilaian visual

Berkas lokal berada di `artifacts/browser/plan06-forest/` dan tidak dibundel ke source:

- `results.json`: pemeriksaan, respons perpindahan/sinkronisasi, snapshot render/HUD/cuaca setiap capture, dan hasil pembersihan.
- `01-physical-forest-entry.png`: titik masuk dengan pemain yang benar-benar dirender.
- `02-gateway-667x375.png` serta `04-gateway-844x390.png`: kepala dan torso Nala terlihat melalui reveal setempat; tajuk sekitar dan batang tidak hilang.
- `03-journal-pauses-under-canopy.png`: jurnal terbuka melalui sentuhan pada layar pendek; tombol tutup dan tab terlihat.
- `05-gateway-desktop-width-touch-context.png`: pemeriksaan ukuran lebar pada konteks sentuh yang sama.
- `06-canopy-clearing-restored-entrance-crowns.png` dan `07-forest-save-reload.png`: area celah tajuk sebelum dan sesudah reload.
- `08-bridge_upper-crossed.png` dan `08-bridge_lower-crossed.png`: pemain di ujung dek setelah benar-benar menyeberang.
- `09-return-through-real-portal.png`: kembali ke desa melalui portal sebenarnya.

Pemeriksaan manual pada gambar gerbang, jurnal, kedua jembatan, dan portal mengonfirmasi posisi pemain, keterbacaan kepala/torso, tepi dek, serta kontrol yang tidak keluar layar. Diagnostik hutan tetap menunjukkan 4.190 vertex konstruksi tepian, 47 tajuk, dan satu mask atlas; saat kembali ke desa terdapat 1.890 vertex tepian dan dua mask atlas. Tidak ada prop, collider, atau sumber cahaya baru dari lane pengujian ini.

Pemeriksaan penyampaian: perilaku kontrol yang diuji lulus melalui input aktual; reflow lulus pada ketiga ukuran; angka pengujian berasal dari hasil run; tidak ada aset atau klaim performa perangkat baru. Run ini melengkapi penerimaan rute browser untuk 06-A, bukan pernyataan bahwa seluruh Rencana 06 atau seluruh UI sudah selesai.
