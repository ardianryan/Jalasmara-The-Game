# Plan 06-P: baseline dan batas pengukuran

Paket ini memisahkan fixture pengujian lokal, pengumpulan telemetri, dan perubahan runtime. Tidak ada optimasi renderer dalam paket ini. Baseline yang dilayani API lokal adalah rilis `efdacba0e402f5acc3df174e2c27582381628f53`; source kandidat hutan/laut yang belum diekspor tidak menjadi dasar klaim hasil.

## Metode

`scripts/performance/browser-baseline.mjs` membuat lima akun sementara berbeda di MongoDB/Redis localhost: desa siang, hutan siang, terumbu laut, desa malam, dan hutan hujan. Titik awal/jam/cuaca merupakan fixture, bukan pembuktian rute gameplay. Laut tetap dimulai melalui endpoint penyelaman biasa. Semua akun dan kunci sesi yang dibuat harness dibersihkan secara spesifik; owner tidak disentuh.

Setiap adegan diuji Ringan dan Seimbang dengan urutan bergantian, viewport 844 × 390, DPR 1, Chromium dan SwiftShader. Pemanasan delapan detik berada di luar sampel 15 detik. Pemain diam; NPC, fauna, air, kalender, dan cuaca tetap hidup. Posisi, jam, cuaca, kualitas, konfigurasi renderer, source harness, dan hash PCK disimpan. Karena kalender berjalan, dua profil tidak memiliki jam yang identik; angka ini penyaringan awal, bukan eksperimen kausal yang mengisolasi setiap fitur kualitas.

RAF iframe mengukur jarak callback browser pada tab yang terlihat. Angka p50/p95 dan hitungan interval di atas 50/100/250/1000 ms tidak diberi nama waktu GPU. Counter Godot FPS, process, physics, draw calls, object, primitive, dan antrean path diambil dari snapshot opt-in yang sudah ada, maksimal sekali per 100 ms. Nilai monitor dapat bertahan pada beberapa snapshot; jumlah sampel ini bukan jumlah pengukuran frame CPU independen. Diagnostik menambah overhead dan aktif pada seluruh profil.

CDP menyediakan heap JavaScript dan jumlah node DOM. Keduanya bukan heap WASM atau node Godot. Waktu GPU, VRAM, memori proses total, dan node Godot belum tersedia. Tidak ada pengukuran Windows atau Samsung S23 fisik. Target 30 FPS S23 pada Plan 06 tetap belum diverifikasi.

Startup mencatat cold context dan reload hangat pada context yang sama. ResourceTiming memisahkan `transferSize`, `encodedBodySize`, dan `decodedBodySize`; progress unduhan host tidak disamakan dengan transfer jaringan. Tidak ada simulasi jaringan seluler.

## Menjalankan ulang

API lokal memerlukan konten published dan Mongo/Redis localhost. Jangan jalankan bersamaan dengan render native atau browser GPU agen lain. Pastikan root mengonfirmasi PCK yang dilayani sebelum menambahkan label revisi.

```sh
node --test scripts/performance/metrics.test.mjs
PROFILE_RUNTIME_SHA=efdacba0e402f5acc3df174e2c27582381628f53 \
PROFILE_PCK_FILE=/absolute/path/to/served/game/index.pck \
PROFILE_CPU=1 APP_TEST_ORIGIN=http://localhost:3100 \
node --import tsx scripts/performance/browser-baseline.mjs
node scripts/performance/report.mjs artifacts/performance/06p-baseline/results.json
```

Hasil mentah, CPU profile, dan screenshot berada di direktori `artifacts/performance/06p-baseline` yang diabaikan Git. `PROFILE_OUTPUT` memilih direktori baru; `PROFILE_SCENARIOS` membatasi adegan ketika diagnosis diperlukan. Jangan membandingkan hasil sebelum/sesudah dari PCK yang sama dengan source label berbeda.

## Kandidat audit source, belum bottleneck terbukti

- `Diagnostics.gd:20` (`performance_sample()`) membaca counter dan memeriksa property actor; Main/Forest menyerialisasi snapshot 100 ms ketika diagnostik aktif.
- `GameHud.gd:338` (`_layout()`) mengukur teks dan menerapkan ukuran/font; frekuensi aktual perlu trace sebelum diubah.
- `land/LandActors3D.gd:26` (`_scan()`) mencari turunan Node2D setiap dua detik. Ini bukan pencarian setiap frame.
- `land/LandWorld3D.gd:1122` (`_process()`) memperbarui kamera, aktor, daun, dan kain ketika aktif.
- `hybrid/OceanActors.gd:19` (`update_actors()`) mengunjungi fauna dan props dengan culling jarak. Jumlah loop saja tidak membuktikan biaya CPU dominan.

Trace CPU terpisah lima detik tersedia dengan `PROFILE_CPU=1`, sesudah pengukuran utama desa Seimbang. Tidak ada perubahan performa runtime yang dibenarkan hanya oleh inspeksi source ini.

## Hasil baseline aktual

Pengambilan 9 November 2026, mulai 13.02 WIB, selesai dengan sepuluh capture, nol error browser, dan pembersihan lima akun sementara. Mesin: macOS Darwin 27, Apple M2 delapan core, RAM 8 GiB; Chromium Headless 158.0.8127.18 / SwiftShader. Screenshot desa, hutan, laut, malam, dan hujan diperiksa: pemain serta renderer adegan aktif. Semua capture memakai PCK `818c599af11a25105b71ff77a46d132a4679d39ad197b213f0d46eabef5b98da` dari runtime `efdacba`; tidak ada angka kandidat source baru.

| Adegan | Profil | RAF p50 / p95 ms | Interval >50 ms | Godot process p50 / p95 ms | Draw calls p50 |
|---|---|---|---:|---|---:|
| Desa siang | Ringan | 16,8 / 33,4 | 2 | 27,6 / 127,2 | 349 |
| Desa siang | Seimbang | 33,3 / 50,0 | 13 | 42,1 / 189,4 | 407 |
| Hutan siang | Seimbang | 50,0 / 50,1 | 42 | 31,5 / 172,5 | 399 |
| Hutan siang | Ringan | 33,3 / 50,0 | 9 | 24,9 / 50,4 | 355 |
| Laut | Ringan | 16,7 / 33,4 | 2 | 25,3 / 157,7 | 178 |
| Laut | Seimbang | 33,3 / 33,4 | 0 | 26,8 / 31,0 | 249 |
| Desa malam | Seimbang | 50,0 / 50,1 | 47 | 51,5 / 187,1 | 385 |
| Desa malam | Ringan | 50,0 / 66,7 | 75 | 59,9 / 346,8 | 384 |
| Hutan hujan | Ringan | 49,9 / 50,1 | 39 | 29,1 / 163,7 | 368 |
| Hutan hujan | Seimbang | 50,0 / 66,7 | 120 | 38,5 / 273,3 | 421 |

Tabel ini satu batch, satu sampel per kombinasi. Ringan tidak selalu lebih cepat: malam menunjukkan variasi berlawanan. Draw calls lebih sedikit juga tidak otomatis memberi p95 lebih baik. Interval maksimum 416,6 ms muncul pada desa malam Ringan; tidak ada interval di atas satu detik. Jangan mengubah hasil RAF menjadi klaim FPS GPU atau membandingkan p95 counter process sebagai distribusi frame independen.

Cold context siap dalam 4,949 detik; reload context yang sama 2,951 detik. WASM 39.514.754 byte decoded / 10.054.758 encoded, PCK 64.242.580 byte; total progress decoded 103.757.334 byte. ResourceTiming melaporkan transfer pada kedua run, sehingga reload lebih cepat ini bukan bukti seluruh aset berasal dari cache. Jaringan localhost tidak mewakili unduhan pengguna internet.

Heap JavaScript setelah capture berkisar 22,67–143,61 MiB. Hutan hujan Seimbang meningkat dari 107,24 ke 143,61 MiB selama sampel, sedangkan beberapa capture lain turun karena GC. Sampel pendek ini tidak membuktikan kebocoran ataupun kestabilan sesi panjang. Nilai tepat, data sebelum/sesudah, object/primitive counters, dan batas unknown ada di [06p-baseline.json](06p-baseline.json). Node Godot dan memori WASM/GPU tetap unknown; node DOM tidak dipakai sebagai penggantinya.

Trace CPU desa Seimbang yang terpisah berlangsung 5,110 detik; leaf `getParameter` mencakup sekitar 4,374 detik sampled. Nama fungsi WASM belum bersimbol dan tidak dipetakan ke GDScript. Ini alasan memeriksa biaya sinkronisasi driver/query pada profil berikutnya, bukan alasan mengubah HUD, fisika, atau renderer sekarang. Trace mentah tersedia di artefak lokal; tidak ada bounded runtime fix yang terbukti perlu dalam lane ini.

## Status dan kelanjutan

Selesai: harness lokal, tiga regresi statistik, sepuluh capture aktual, startup cold/context-warm, dan review gambar. Belum selesai: pengukuran sesudah pada PCK gabungan baru, pengulangan untuk variasi, soak test resource, serta Windows/S23 fisik. Sebelum/sesudah harus memakai fixture, viewport, durasi, diagnostik, dan urutan yang sama serta mencatat hash PCK baru. Target performa Plan 06 belum dinyatakan lulus.
