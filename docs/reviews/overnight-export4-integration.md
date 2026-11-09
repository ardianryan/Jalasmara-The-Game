# Ekspor keempat: bukti perlengkapan dan laporan perangkat

Checkpoint 10 November 2026, 05.13 WIB. **Image baru aktif dan sehat sejak 04.45.14 WIB; smoke publik default baru lulus 6/6.** Source ekspor `28a3c6d`, PCK `b34d`/64.495.984 byte; source context Docker `0bc6479`. Image VPS diverifikasi read-only sebelum aktivasi dan backup pra-aktivasi berhasil restore/count. Image a9/PCK73d tersedia sebagai rollback langsung. Bukti publik berasal dari sesi baru, terpisah dari bukti lokal.

| Identitas kandidat | Nilai |
| --- | --- |
| Source ekspor Godot | `28a3c6d03908581e47843c7ceaa453d83550b5df` |
| Source Docker/context | `0bc6479c9c7fe5dfbc693128493cd6f6aec1e18b` |
| PCK | `b34d95211a61354eebf9cd218455d1c2f4e4b99723b57e4cfbe2b0a113f0ba26`,64.495.984byte/62bagian |
| Image kandidat | `sha256:898666e937a550016b1bdfb359e696e127feea11baf57dcfcada323a2b6bfa0b` |
| Container aktif | `d6e83291e30b334c70c150c58d0a574f4bc8b520f9ea63f79d59e60de67cae11`, sehat |
| Context | 69.201.920byte, SHA`beb444d50f04987d1e42b6f97caa9523fac8527b84095c147b706c6e85580ce0` |
| Rollback yang dipertahankan | imagea9f984/PCK73d, host e171734 |

Paket menambahkan diagnostik perlengkapan actual-node yang hanya berjalan opt-in dan identitas aset pada JSON rekaman performa. Default collision, kalender36menit, pakaian, attachment transform, ekonomi, progres dan API gameplay tetap. PCK bertambah1.328byte dibanding73d; WASM/gzip identik. Ini bukan pengurangan payload/FPS atau perbaikan gait.

## Bukti kandidat lokal

- Full64world PASS/147.165ms dan10species/722frame, termasuk actual opt-in equipment fixture; [laporan](overnight-equipment-node-diagnostics.md). Source consumer audio baru sesudah ekspor ini **tidak** termasuk hasil64/PCKb34d.
- [Loader/recorder provenance](overnight-performance-asset-provenance.md):28stream dan31performa CPU, typecheck serta build Vite PASS. Seluruh bagian lolos hash sebelum getter identitas terisi; ini bukan whole-file digest atau READY attestation.
- [Perlengkapan aktual](overnight-actual-gear-browser.md):7/7 browser/93.125ms, realbooth/land/ocean/extraction/reload. Tank6/net12 mesh aktif ketika diving dan0ketika daily. Frame idle1536,8105/1385,0293 bebas atap; tubuh dan tank terlihat. Bukan semua facing/identity/mesh pixel-occlusion.
- [AUTO30](overnight-recorder-provenance-browser.md):7/7 browser, otomatis30.104,5ms; JSON yang benar-benar diunduh memiliki pin b34d/ukuran62bagian yang sama di awal/akhir serta dokumen tetap.28sampel/3paused; bukan hasil perangkat fisik Windows/S23.
- [Explorer](overnight-explorer-node-browser.md):5/5 browser/55.483ms, joystick sentuh→jembatan→save/reload. Satchel4mesh aktif di ketiga checkpoint; tank/net/vest mesh tersembunyi. Posisi reload yang ditampilkan sama1602,09155/637,330505; lease grace tidak diukur ulang pada rute singkat ini.

Ketiga browser mempunyai UUID berbeda, tanpa error, seluruh operasi teramati200 dan cleanup miliknya selesai. Tidak ada state/gear yang disuntik di tengah rute, toleransi atau budget diperbesar, atau FPS perangkat fisik diklaim. Nala physical lower-body **tetap OFF**.

## Persiapan image

Packager existing memvalidasi seluruh14aset dan menghilangkan hanya WASM/gzip dari context. Consumer VPS menyalin kedua file dari active imagea9 yang dipin, memverifikasi14file/ukuran/SHA serta dekompresi gzip sebelum build. Konteks bersih tidak membawa `.env`, sourcecache, `.git` atau dependency lokal.

Docker build PASS. Verifier image read-only/network-none memeriksa14gameassets,62compiledwebassets,HTMLhost serta46compiledAPIfiles terhadap hasil lokal. APIbytes tetap sama dengan kandidat host sebelumnya; tidak ada reseed. Bukti `.runtime/overnight-export4-{context-verify,image-build,image-verified}.log/json`, manifest/context `.runtime/overnight-export4-release/`, preview3111session3783. Tool existing Godot4.7.2, Vite6.4.5, Node/TypeScript, Python, Playwright dan SSH/Docker; tambahan kode original proyek, tanpa dependency/lisensi/aset upstream baru.

## Aktivasi, penerimaan publik dan pembersihan

Backup `/var/backups/jalasmara/jalasmara-20261109T214343Z.archive.gz`, SHA`f1648278eae0ce7a0b8d16918ec4ac7c5e9249727e30454dc955c7080d76e0d3`, berhasil restore42dokumen/0gagal pada namespace pemeriksaan terpisah; jumlah seluruh koleksi cocok dan namespace dibersihkan. Bukan perbandingan setiap field. Aktivasi hanya app dengan `--no-deps --no-build`, trap rollback aktif selama health/fullPCK/env/dataidentity diperiksa; hasil semuanya PASS. `.env`SHA627555330e24f0159d84ca5df860fdebe2c28812cd62edec433635565dd0f68e, Mongo7b13e58eb0e6, Redisa67512d71c0d serta bind10.1.0.8:3000 tetap. Tidak ada reseed atau perubahan sharedproxy. Log `.runtime/overnight-export4-{preactivation,activation}.log` dan `overnight-export4-active-identity.txt`.

[Smoke publik b34d](overnight-b34d-public-smoke.md) **6/6 PASS**, UUID `026638de-980d-4686-a966-d7037b1f1b3c`, default HTTP/2, 413.657 ms di bawah batas 480.000 ms, 612 pulsa input aktual, tanpa error. Rute desa–hutan, reveal kanopi, sentuhan jurnal/pause, save/reload dan pemulihan writer/jam server benar-benar dijalankan. Monitor reload 8.910 ms mengamati 5.197 ms waktu aktif otoritatif. Cleanup akun fixture dan objek miliknya nol; browser ditutup. Root memeriksa hasil mentah secara independen. Hasil ini bukan pengukuran FPS perangkat fisik.

Sesudah penerimaan, context VPS `/tmp/jalasmara-export4-0bc6479` (187.817.592 byte logis; 188.141.568 byte teralokasi) dan image203 beserta dua tag lamanya dihapus. Ruang bebas VPS teramati 41.832.349.696 → 42.228.682.752 byte, bertambah 396.333.056 byte; angka tersebut pengamatan filesystem, bukan penjumlahan ukuran layer. Image aktif898 dan satu rollbacka9 tetap. Pemeriksaan ulang health, seluruh hash PCK dan `.env` PASS; Mongo/Redis tetap berjalan.

Arsip context lokal dihapus setelah SHA cocok dan tidak ada handle terbuka: 69.201.920 byte logis/teralokasi. Ruang bebas lokal 11.630.895.104 → 11.700.084.736 byte; manifest, expected hashes, laporan dan log disimpan. Bukti `.runtime/overnight-export4-cleanup.log` serta `overnight-export4-local-cleanup.json`. Source, cache kerja aktif, konfigurasi, backup dan volume data tidak dihapus.

CI build3af sebelumnya gagal penjadwalan tanpa runner; source baru ini belum mempunyai seluruh pipeline PASS.

Consumer audio foot-contact baru sesudah source ekspor sudah lulus34assertions terarah dan dua regresi lama, tetapi masih unwired/lokal dan tidak masuk image ini. Full runner65 sesudah ekspor ini sudah65/65PASS145.475ms lokal; tetap bukan producer aktual, CI atau bagian image898. Gait masih memerlukan fullterrain16, freshflat32, upper/gear contactphase dan dua native movingsequence; pengujian fisik menunggu bantuan pengguna yang sudah bersedia.
