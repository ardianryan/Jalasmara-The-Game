# Peer CPU: paket konteks rilis Web

Review read-only pada integration HEAD `779be9e5128172724c2f81e50c04ecd750ec0ab0`. Source milik root tidak diubah. Hash `scripts/package-web-release.py`: `264e4a03d31108967791b08dd3839ff501238969a05f3ce7ea8fbe8299ee7f10`; hash tes: `3ff23a86a071f2259c5614c314f68990de02694f1abf07425316f977edcf5957`.

**Tidak ditemukan blocker aktivasi dalam scope review ini.** Lima tes CPU packager PASS (0,480 detik). Tujuh probe `TarInfo` independen juga menolak `.env.production`, traversal `..`, absolute path, `node_modules`, `.runtime`, symlink dan hardlink. Tidak ada engine, browser, SSH, build, atau paket baru dijalankan/dibuat.

Source Docker diambil dari `git archive HEAD` setelah dirty check scope yang sama, sehingga untracked `.env` dan symlink/cache dependency lokal tidak ikut. Member archive hanya regular file/directory dan menolak komponen `.env*`, `.git`, `node_modules`, `.runtime`; ini bukan pemindaian isi rahasia umum atau janji menolak setiap nama cache. `.dockerignore` tetap ikut paket. Aset export memakai allowlist nama, harus regular file tanpa symlink, dan generated export tracked selain placeholder kosong ditolak agar tidak menimpa aset dari archive.

Sebelum output dibuat, PCK diverifikasi melalui ukuran, SHA-256 keseluruhan, ukuran part 1MiB dan setiap part hash. Setiap gzip harus mempunyai original dan decompression dibatasi ukuran original, lalu ukuran/hash hasilnya harus sama. Output existing ditolak, tar memakai mode exclusive-create, dan manifest mencatat hash/ukuran context serta daftar aset lengkap termasuk dua WASM yang sengaja tidak dikirim. Validasi ulang aset reuse dan seluruh `gameAssets` sebelum build dinyatakan sebagai kewajiban consumer.

Pemanggilan read-only `asset_records()` pada export aktual sekarang juga PASS: **14 aset**, PCK **64.494.656 byte**, SHA-256 `73d45630ab69033ac36a64740ecc73ecdb7363c9f99805222b6a9237dcb2d18b`; reuse adalah `index.wasm` dan `index.wasm.gz`. Ukuran context 69.191.680 byte yang dilaporkan root bukan ukuran PCK ini.

Batas review:

- `declaredExportSource` memang hanya commit penuh yang ada dan dideklarasikan saat export; tidak mengklaim membuktikan hubungan biner PCK dengan source. `source` adalah HEAD untuk input Docker, keduanya boleh berbeda secara eksplisit.
- Aset di-hash sebelum `tar.add`, tidak di-hash ulang dari tar. Export bersamaan dapat mengubah bytes di antara tahap itu; tidak ada concurrent export yang diamati. Validasi seluruh `gameAssets` pada context hasil ekstraksi tetap diperlukan dan menurut root sudah dijalankan di server. Ini bukan hasil verifikasi VPS/image independen dari lane peer.
- Tidak memverifikasi image `203625…`, hash context `1fcce…`, konfigurasi deploy atau aktivasi publik. Tidak mengubah guard operasi maupun menambah approval flow.


## Perluasan host-only sesudah ekspor3

Root menambah opsi eksplisit `--reuse-game-assets` untuk rilis host/API dengan export tidak berubah. Ini bukan hasil peer5tes di atas. Root8tes CPU PASS: mode penuh menghilangkan seluruh generated payload dari tar dan tetap mewajibkan record byte/SHA setiap aset; perubahan PCK dan gzip tetap ditolak, mode reuse eksklusif, dan mode biasa tetap membawa semua aset. Penggunaan aktual/ukuran context berikutnya harus dicatat terpisah; belum klaim transfer atau image baru dari opsi ini.
