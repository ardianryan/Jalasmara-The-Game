# Rilis host: panel pengelola terpisah

Checkpoint 10 November 2026,03.39WIB. Image host baru aktif dan sehat sejak03.36:45WIB. Penerimaan browser publik khusus host sedang disiapkan; **belum PASS**. Dunia/PCK tidak diekspor atau diubah ulang.

| Identitas | Nilai |
| --- | --- |
| Source Docker/host | `e17173436e1adbdd11ee29e340f3bb5b48769c61` |
| Image aktif | `sha256:a9f984ddf59fdf52aab08a897df2893346b419975ebca755c977a5580f8169d3` |
| Container aktif | `de5e4742bc59d339747883b5cbba2180f16ee93918a68667d65b3abd5ed51f7d` |
| Ekspor Godot yang dipertahankan | `b0f2ef84cc06a404ed12d1311644e106f4a5afe6` |
| PCK tidak berubah | `73d45630ab69033ac36a64740ecc73ecdb7363c9f99805222b6a9237dcb2d18b`,64.494.656byte |
| Context host-only | 4.270.080byte, SHA`4f9b69cea53612cee0136d7cf2429e6a866d8580580ffd84fc80e04b52c3b489` |
| Rollback langsung | image2036254/PCK73d, tag`jalasmara:rollback-admin-host-ground3` |

[Implementasi lazy Admin](overnight-admin-deferred-loading.md) lulus typecheck, build dan dua run browser compiled9/9. Entry awal turun24.212byte atau perkiraan gzip6.557byte; tidak mengklaim pengurangan PCK/FPS. Peran/otoritas API tetap. Role gating/loading/HTTP503/reload ditinjau [peer](overnight-admin-chunk-peer.md).

Packager original kini mendukung `--reuse-game-assets` yang eksklusif terhadap `--reuse-wasm`: semua14aset lokal tetap divalidasi hash/ukuran/PCK/part/gzip, seluruhnya dicantumkan wajib pada manifest, tetapi tidak ditransfer ulang. Delapan tes CPU PASS; paket aktual hanya70file source tracked/4,27MB. Consumer menyalin seluruh14file dari image aktif203 yang dipin, lalu memverifikasi setiap file terhadap manifest baru **sebelum build**. Tidak hanya mencocokkan PCK atau nama berkas.

Docker build VPS PASS. Verifier berjalan read-only/network-none di image baru:14aset game cocok; **62aset compiled web** cocok dengan Vitebuild di memori dari source yang sama; **46file compiled API** cocok dengan hasil lokal. Build Vite pembanding tidak menulis dist, sehingga preview lokal yang dipakai jahe tidak berubah. Log `.runtime/overnight-admin-host-{package,image-build,image-verify,image-verified}.log/json` dan manifest `.runtime/overnight-admin-host-release/manifest.json` memegang bukti rinci.

Backup baru `/var/backups/jalasmara/jalasmara-20261109T203407Z.archive.gz`, SHA`1c2e9cb2c667ca6f7ec7febec70b16fde44967b70e0fea306b2528155c9d44f0`, direstore42dokumen/0gagal ke database terpisah, jumlah setiap koleksi cocok, namespace pemeriksaan dihapus. Ini verifikasi restore/count, bukan perbandingan seluruh field aplikasi.

Aktivasi hanya retag `jalasmara:current` dan recreate app `--no-deps --no-build`, dengan rollback otomatis bila health/fullPCK/env/data-identity gagal. Mongo7b13e58eb0e6, Redisa67512d71c0d, bind10.1.0.8:3000 dan `.env`SHA627555330e24f0159d84ca5df860fdebe2c28812cd62edec433635565dd0f68e tetap. Tidak ada reseed, perubahan proxy, `.env` atau volume. Log `.runtime/overnight-admin-host-preactivation.log` dan `overnight-admin-host-activation.log`.

[Smoke6 dunia publik sebelumnya](overnight-export3-public-smoke.md) tetap khusus image203/hostd63, walaupun PCK sama. Host baru perlu bukti login/READY/reload/clock/no-admin-download pada pemain dan pengiriman chunk Admin melalui fixture API tersendiri. Jangan memindahkan hasil6 itu menjadi klaim seluruh rute diulang pada imagea9. CI3046660664/source3af verify63world/120API/CodeQL lulus; job build17875131575 tetappending tanpa runner setelah sekitar satu jam. Build actualVPS terpisah lulus; bukan seluruh CI selesai.

Konteks sementara dan image rollback dua rilis lalu tetap dipertahankan sampai host smoke diterima, lalu retensi aktif+satu rollback diperbarui. Nala physical lower-body tetap terisolasi/OFF dan tidak masuk image ini. Tidak ada library/aset upstream baru; React/Vite existing serta packager orisinal digunakan sesuai lisensi proyek.
