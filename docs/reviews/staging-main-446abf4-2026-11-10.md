# Aktivasi staging `main` 446abf4

Pada 10 November 2026, source `446abf48f73a598b25f5fdc386fa3270a3e00e14` diaktifkan di staging. Ini mengikuti konsolidasi `main` yang **tidak** memasukkan branch gait Claude. CI Gitea [run 10](https://git.ppti.me/ardianryan/Jalasmara-The-Game/actions/runs/10) lulus pada `59e916b`; selisih source ke `446abf4` hanya dokumentasi. Paket yang diaktifkan diekspor dan dikemas ulang secara lokal dari `446abf4`, bukan ZIP delivery CI. Karena itu hash context lokal berbeda dari context CI dan dicatat terpisah.

## Identitas rilis dan perlindungan data

| Komponen | Identitas terverifikasi |
| --- | --- |
| Source dan declared Godot export source | `446abf48f73a598b25f5fdc386fa3270a3e00e14` |
| Context lokal, transfer, dan ekstraksi | 118.784.000 byte, SHA-256 `a481bef693f49eefc909885b48cd4a5706e426cc8c927da01102d86700a94b66` |
| PCK baru | 64.501.312 byte, SHA-256 `5c0253f0bb9f103f6032c69b42dac6fc6fda7485a38f5b4d88380480a1eb9d7c` |
| Image aktif | `jalasmara:main-446abf4-20261110`, ID `sha256:b6c8eddfd8752ecd62a9c041ea3cd357dae56a8fc085af732f81cdc7bbe9f481` |
| Rollback | `jalasmara:rollback-before-446abf4-20261110`, ID `sha256:559451efd4c10c841ef0f2aa1f8e0dd09eba5fd76dafcbb2e779c3c095e5c7db` (export5) |
| Backup sebelum aktivasi | `/var/backups/jalasmara/jalasmara-20261110T143632Z.archive.gz`; checksum lulus; restore ke database pemeriksaan berhasil 42 dokumen, 0 gagal, lalu database pemeriksaan dihapus |

`npm run build:game`, build web dan API, serta packager lulus lokal. Context dan semua 14 aset game cocok byte/hash pada VPS sebelum build; semua 14 aset di dalam image hasil build juga cocok. `requiredReusedAssets` kosong. Backup dan restore dijalankan sebelum app diganti. Hanya service `app` direcreate; container MongoDB `7b13e58e…` dan Redis `a67512d7…` tetap sama. Checksum `.env` sebelum/sesudah `627555330e24f0159d84ca5df860fdebe2c28812cd62edec433635565dd0f68e`. Pemeriksaan internal pertama terlalu cepat dan mendapat `ECONNREFUSED` saat health masih `starting`; retry sesudah container `healthy` lulus. Kegagalan sementara ini bukan kegagalan runtime setelah siap.

## Penerimaan publik

`GET /api/health` melalui HTTPS mengembalikan `{"status":"ok"}`. `HEAD /game/pck/5c0253…/0` melalui HTTP/2 mengembalikan 200 dan `X-Pck-Length: 64501312`. Smoke `RUN_STAGING_SMOKE=plan06-public` lulus `defaultPublicAccepted: true` pada browser Chromium lokal dengan protokol publik default: unduhan PCK cocok penuh, login fixture dengan secure cookie dan game siap, gerbang fisik serta kanopi hutan, jurnal sentuh membuka/pause/menutup, dan posisi serta waktu aktif otoritatif pulih setelah reload tanpa perubahan cerita/hadiah. Tidak ada error/failure. Cleanup fixture terverifikasi: players, receipts, shifts, Redis keys masing-masing 0. Hasil lengkap dan lima screenshot ada di `artifacts/browser/staging-plan06-f8109a8d-440f-45a1-9aa8-80bc2fccd904/` (lokal, diabaikan Git). Tiga gambar terkurasi ada di [galeri](../visual/README.md).

Ini bukti browser otomatis pada mesin operator, **bukan** benchmark GPU Samsung S23 atau Windows fisik dan bukan penerimaan artistik akhir. Screenshot hutan menunjukkan kontur/kanopi dan HUD rilis ini; penilaian moodboard, arah bangunan, gait natural seluruh arah, serta performa perangkat nyata tetap pekerjaan tersisa. Pilot gait fisik tetap OFF.

## Tool, aset, dan pembersihan

Tool yang benar-benar dipakai: Godot 4.7.2 lokal melalui `npm run build:game`, Node/npm build web/API, `scripts/package-web-release.py`, Python 3 standard library untuk SHA-256, OpenSSH/SCP, Docker/Compose pada VPS, `scripts/backup.sh`, `scripts/verify-restore.sh`, `curl`, dan Playwright Chromium melalui `scripts/staging-plan06-smoke.mjs`. Aset berasal dari source proyek `446abf4`; tidak ada generator gambar/aset atau dependensi baru. Screenshot galeri adalah output game asli untuk dokumentasi dan tidak menjadi aset kit MIT. Fish Gen, Noxe, PixelDoll, Sprite AI, dan moodboard hanya referensi pada paket ini.

Pembersihan selesai setelah smoke: `/opt/jalasmara/releases/main-446abf4-20261110T1432Z/context` (116.108 KiB teralokasi), `image-game` (111.832 KiB), dan `context.tar` (116.004 KiB) dihapus; `manifest.json` tetap. Ruang bebas VPS naik dari 41.199.382.528 ke 41.551.568.896 byte pada tahap ini (+352.186.368 byte). Archive context lokal `.runtime/releases/main-446abf4-20261110T1432Z/context.tar` (116.004 KiB teralokasi) juga dihapus sesudah identitasnya dicatat; manifest lokal tetap. Dua tag image export4 lama yang tidak lagi menjadi rollback dihapus, lalu `docker image prune -f` setelah build selesai melaporkan 867,3 MB reclaimed. Ruang bebas VPS akhir 44.014.215.168 byte. Image aktif dan rollback export5 tetap dapat di-inspect; backup checksum tetap OK. Sesudah cleanup, container app masih `healthy`, `.env` identik, dan health publik masih `{"status":"ok"}`. Tidak ada volume, source, bukti browser, atau data hidup yang dihapus.

## Lanjutan

1. Lakukan pemeriksaan visual dan performa di Samsung S23/Windows fisik bersama pengguna pada source/PCK ini; rekam resolusi, FPS/GPU, input joystick, dialog/HUD malam, loading/fullscreen, dan tanggapan.
2. Kerjakan ulang kandidat gait dari fixture tracked dan gate flat32/full16/native/browser; branch Claude yang ditolak tetap hanya arsip lokal. Jangan menghidupkan pilot dari hasil CI umum.
3. Selesaikan pemolesan art terukur terhadap moodboard (rumah, daratan, hutan, laut, kontur dan HUD) dengan bukti screenshot per lokasi; status rilis ini belum mengklaim kualitas final.
