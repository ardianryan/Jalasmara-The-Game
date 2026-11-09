# Plan 06-P: perbandingan paket gabungan pertama

Status: capture selesai; atribusi regresi belum ditetapkan. Paket ini tidak dinyatakan lebih cepat dan target Samsung S23/Windows belum diuji.

- Sebelum: runtime `efdacba0e402f5acc3df174e2c27582381628f53`, PCK `818c599af11a25105b71ff77a46d132a4679d39ad197b213f0d46eabef5b98da`.
- Sesudah: runtime `1f0d040308bad93432275bf5b6cd3d359cf6ef9e`, PCK `291b31baa9affcb68e752613c414709417115bd2e4dcfaf05bae232a5adc421b`.
- Mesin/metode: M2 delapan core, RAM 8 GiB, Chromium Headless 158.0.8127.18, SwiftShader, viewport 844 × 390. Lima scene, dua profil, delapan detik pemanasan dan 15 detik sampel, urutan profil sama. CPU trace tambahan tidak berjalan pada batch sesudah.
- Sebelum dimulai 13.02 WIB; sesudah 13.22 WIB, 9 November 2026. Masing-masing sepuluh capture selesai tanpa error browser, kemudian semua akun sementara dibersihkan. Source kandidat lain tidak diekspor selama batch.

## Hasil sepuluh capture

| Scene | Profile | RAF p50 before / after ms | RAF p95 before / after ms | p95 delta ms | Draw calls p50 before / after | Rerun? |
|---|---|---|---|---:|---|---|
| village-day | low | 16.80 / 33.30 | 33.40 / 50.10 | 16.70 | 349.00 / 350.00 | No threshold flag |
| village-day | balanced | 33.30 / 50.00 | 50.00 / 50.10 | 0.10 | 407.00 / 410.00 | No threshold flag |
| forest-day | balanced | 50.00 / 66.70 | 50.10 / 116.60 | 66.50 | 399.00 / 399.00 | Investigate |
| forest-day | low | 33.30 / 50.00 | 50.00 / 66.70 | 16.70 | 355.00 / 355.00 | No threshold flag |
| ocean-reef | low | 16.70 / 33.30 | 33.40 / 33.40 | 0.00 | 178.00 / 178.00 | No threshold flag |
| ocean-reef | balanced | 33.30 / 33.30 | 33.40 / 50.00 | 16.60 | 249.00 / 249.00 | No threshold flag |
| village-night | balanced | 50.00 / 66.60 | 50.10 / 83.30 | 33.20 | 385.00 / 385.00 | Investigate |
| village-night | low | 50.00 / 66.60 | 66.70 / 83.30 | 16.60 | 384.00 / 384.00 | No threshold flag |
| forest-rain | low | 49.90 / 50.10 | 50.10 / 66.80 | 16.70 | 368.00 / 368.00 | No threshold flag |
| forest-rain | balanced | 50.00 / 66.70 | 66.70 / 83.40 | 16.70 | 421.00 / 421.00 | No threshold flag |

RAF ialah interval callback iframe yang terlihat, bukan timer GPU atau FPS perangkat fisik. Monitor process/physics Godot adalah snapshot bersampel; counter dapat berulang, sehingga p95-nya bukan distribusi frame independen. Detail p50/p95, hitches >50/100/250/1000 ms, render objects/primitives, heap JavaScript, kondisi awal/akhir dan kualitas tersedia di [06p-after.json](06p-after.json). Baseline tidak diubah.

Threshold otomatis menandai hutan siang Seimbang dan desa malam Seimbang untuk investigasi. Threshold ini tidak menangkap semua pola: misalnya median desa Ringan juga bertambah, meski p95-nya hampir tepat di batas 1,5 kali. Draw calls yang tetap sama tidak membuktikan biaya fragment/shadow/driver tetap sama.

## Rerun hutan

Rerun terpisah memakai PCK sesudah yang sama, scene `forest-day`, urutan asli Seimbang → Ringan, viewport/durasi/pemanasan yang sama, tanpa aktivitas Godot lain.

| Profil | RAF p50/p95 baseline ms | Batch sesudah ms | Rerun sesudah ms |
|---|---|---|---|
| Seimbang | 50,0 / 50,1 | 66,7 / 116,6 | 66,7 / 83,4 |
| Ringan | 33,3 / 50,0 | 50,0 / 66,7 | 50,0 / 100,0 |

Arah perlambatan median berulang; besar p95 masih berubah. Dua capture rerun selesai tanpa error, lalu akun sementara dibersihkan. Detail di [06p-after-forest-rerun.json](06p-after-forest-rerun.json). Ini belum kontrol paket lama pada kondisi mesin yang berdekatan.

## Confound dan langkah berikutnya

Read-only `uptime` pada 13.26 WIB menunjukkan load average 11,82 pada mesin delapan core. Selain proses browser benchmark, proses antarmuka Paseo sekitar 107% CPU dan remote desktop sekitar 25% CPU terlihat. Proses tersebut tidak dihentikan. `pmset -g therm` tidak mencatat thermal/performance warning; ketiadaan warning bukan bukti frekuensi GPU atau suhu stabil. Kondisi baseline 20 menit sebelumnya tidak memiliki rekaman load yang sama. Delta batch tidak dapat diklaim akibat perubahan source semata.

Cold context sesudah siap 5,833 detik dan reload context yang sama 3,548 detik, dibanding 4,949/2,951 detik sebelumnya. Progress decoded sesudah 103.764.566 byte, bertambah 7.232 byte. Startup localhost tunggal ini bukan tolok ukur jaringan pengguna atau klaim regresi loading yang terisolasi. Heap JavaScript akhir capture berkisar 21,03–97,80 MiB; bukan total WASM/VRAM/RSS. Tidak ada klaim kebocoran atau stabilitas sesi panjang.

Root menyiapkan kandidat guard shader canopy yang melewati perhitungan reveal ketika tidak aktif. Belum ada hasil kandidat guard dalam dokumen ini. Kontrol berikutnya akan menjalankan paket lama dan kandidat secara berdekatan melalui `PROFILE_OVERRIDE_PCK` pada API/WASM yang sama, tanpa mengganti serverpack. Report mode intercepted akan mengecualikan network/startup. Pengukuran hardware Windows/S23, GPU timing, node Godot dan total memori masih belum tersedia.
