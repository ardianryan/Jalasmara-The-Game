# Integrasi dan aktivasi ekspor ketiga

Checkpoint 10 November 2026, 03.15 WIB. Image baru aktif sejak03.04WIB, sehat dan [lulus6/6 browser publik default](overnight-export3-public-smoke.md).

## Perubahan dan identitas

Paket menggabungkan predicate lantai raw-float64 yang sama dengan shared server, penyaringan AABB, cache consumer traversal/Foley yang tetap mendeteksi perubahan polygon, perlindungan draft array editor, serta loading landscape pendek. Collision, prioritas lantai, aturan ekonomi dan kalender 36 menit tetap. Pilot lower-body Nala tidak dimasukkan.

| Identitas | Nilai |
| --- | --- |
| Source ekspor Godot | `b0f2ef84cc06a404ed12d1311644e106f4a5afe6` |
| Source Docker/context | `d63a10b1269f44b0721d3d0766087821ebd57435` |
| Image aktif | `sha256:2036254db640df92f8db38a8b7b0f6cb75d39c19324613c17a2f033b48aa48b6` |
| Container aktif | `ab737c25dec161259601a1737b35b046c3356f5592d834531cf8d7ecf5d9f55e` |
| PCK Mac yang dirilis | `73d45630ab69033ac36a64740ecc73ecdb7363c9f99805222b6a9237dcb2d18b`, 64.494.656 byte, 62 bagian |
| Context transfer | 69.191.680 byte; SHA `1fcce3901e205ff9996148ec6d75ea6427d30da6127a2cf63f5f6aed110829af` |
| Rollback sebelumnya | `sha256:d044202760953c6cb295df49073f9e44a788f1b672c7618a4d313f8467eb9964`, tag `jalasmara:rollback-ground3-798a47b` |

Dua UID Godot yang dihasilkan saat import dicatat pada e73abfe. Source runtime/aplikasi setelah 3af35a6 sama dengan scope yang diuji CI, kecuali metadata UID tersebut. Jangan menyamakan source Docker, deklarasi source ekspor, PCK Linux CI dan PCK Mac rilis.

## Bukti yang sudah selesai

- Full lokal 63 pemeriksaan dunia PASS, 146.978 ms, ditambah 10 spesies/722 bingkai; log `.runtime/overnight-world-ground63.log`, manifest `.runtime/world-check-ground63/world-checks.json`.
- Canonical/AABB: 20.783 pemeriksaan PASS; biaya query turun dibanding implementasi scalar pertama, tetapi masih lebih mahal daripada predicate native lama. Consumer memiliki overhead sekitar 6,8–10,1 mikrodetik per query untuk konsistensi dan deteksi mutasi; bukan klaim FPS meningkat. [Rincian](overnight-canonical-ground-peer-review.md).
- `npm run build` Godot/Web/API dan typecheck PASS. Seluruh 14 aset game, 61 aset compiled web dan 46 file compiled API di image cocok byte dengan build lokal. WASM reuse hanya setelah ukuran/SHA cocok; gzip juga diverifikasi terhadap isi WASM.
- Admin 35 dan loading pendek 16 pemeriksaan host/fixture PASS, bukan transaksi database atau unduhan Godot pada perangkat fisik.
- Rute browser kiri panjang menyelesaikan dermaga→gerbang→hutan, lalu mencapai batas 300.929 ms saat menuju jembatan. Dua pemeriksaan PASS dan hasil keseluruhan belum lengkap; 213 POST semuanya 200, cleanup selesai. [Kegagalan budget tetap disimpan](overnight-export3-left-browser.md).
- Fixture hutan terpisah 3/3 PASS dalam 58.231 ms: joystick sentuh 844×390, jembatan atas, ACK/save/reload posisi 1603,941162/637,787354. Pendekatan legal dideklarasikan ulang; bukan bukti lanjutan rute panjang yang sama. [Rincian](overnight-export3-left-browser.md).

## CI dan batas klaim

Pipeline `3046660664`, source `3af35a6bc01dc39ad9ee37735453c32b53d672e6`: verify PASS, Godot PASS 63/63 (184.465 ms), CodeQL PASS; 120 tes API tanpa kegagalan. SARIF satu warning HTTP-to-file pada harness dan dua note fixture upstream. Job build aplikasi `17875131575` masih pending tanpa runner saat checkpoint; jangan menyebut seluruh pipeline selesai. Image aplikasi dibuat dan diperiksa terpisah pada VPS.

PCK Linux CI `8c7e43e35e570a0767dd386750edbdbcbad3f453c069211c912c0bbff0b0b3e6`, ukuran sama, berbeda hash dari ekspor Mac. Artefak CI dan ringkasan disimpan di `.runtime/ci-3046660664/`.

## Operasi aktual

Backup pra-aktivasi `/var/backups/jalasmara/jalasmara-20261109T195656Z.archive.gz`, SHA `ff3f806acae7821c17a1c7ff5fbe08ecd924da539ba1dd9cd2c99d9b70172d17`, berhasil restore 42 dokumen/0 gagal pada database pemeriksaan terpisah; jumlah/isi diperiksa dan database sementara dibersihkan.

Aktivasi hanya mengganti tag `jalasmara:current` dan service app melalui compose tanpa build/dependensi. Guard rollback otomatis mengembalikan image sebelumnya jika health/identitas gagal. Full PCK setelah pergantian cocok. Mongo `7b13e58eb0e6`, Redis `a67512d71c0d`, bind `10.1.0.8:3000`, `.env` SHA `627555330e24f0159d84ca5df860fdebe2c28812cd62edec433635565dd0f68e` tidak berubah. Tidak ada reseed, perubahan proxy, volume atau data pemain. Log `.runtime/overnight-release3-{backup,pre-activation,activation}.log`.

## Berikutnya

Smoke publik default sudah lulus381.635ms/560pulsa/0error dan cleanup nol; iframe baru memegang writer dan kalender maju5.285ms setara waktu aktif. Pin panduan perangkat sudah diperbarui; konteks sementara dan image dua rilis lalu dihapus sesudah penerimaan. Pilot Nala tetap OFF: flat 32 kasus lulus, urutan tread pusat terarah lulus, tetapi full terrain 16 kasus berhenti pada opaque sole di ramp. Dua sequence native bergerak dan lengan tujuh arah belum selesai. Samsung S23/Windows fisik menunggu sesi pengguna yang sudah bersedia membantu.

Tool: Godot 4.7.2 Compatibility, Node/tsx, Python, Playwright Chromium, Git/glab, SSH/Docker dan packager original proyek. [Peer packager](overnight-web-release-packager-peer.md) 5 tes/7 probe/14 aset PASS. Tidak ada library/aset upstream baru atau Sprite AI dipakai dalam paket ini; lisensi yang sudah tercatat tetap berlaku.


## Pembersihan sesudah penerimaan publik

Arsip lokal context69.191.680byte (69.193.728allocated) dihapus setelah SHA dan tanpa handle terbuka diperiksa. Manifest/log tetap disimpan. Direktori sementara VPS `/tmp/jalasmara-ground3-d63a10b`187.784.703logicalbyte/188.108.800allocatedbyte dihapus; salinan manifest/prepared kecil disimpan bersama catatan backup. Dua tag image lama d60 dihapus setelah dipastikan tidak dipakai container; build aktif203 dan satu rollbackd044 tetap tersedia.

Ruang bebas VPS teramati42.829.238.272→43.300.188.160byte (bertambah470.949.888byte). Ruang bebas lokal teramati11.837.214.720→11.906.404.352byte; perubahan free disk tidak identik dengan ukuran arsip karena aktivitas filesystem lain. Setelah cleanup, health dan SHA seluruhPCK73d tetap cocok, `.env` serta container data tetap. Tidak menjalankan prunevolume atau menghapus source/cache worktree aktif. Log `.runtime/overnight-release3-cleanup.log` dan `.runtime/overnight-release3-local-cleanup.json`.
