# Pembersihan storage lokal dan VPS

9 November 2026. Permintaan pengguna adalah menghapus cache/hasil build yang sudah tidak dipakai untuk menghemat storage. **Pembersihan lokal telah dilakukan integrator**, kemudian reviewer memeriksa manifest dan keberadaan berkas yang dipertahankan. Reviewer tidak melakukan penghapusan tambahan, tidak menjalankan engine/browser, dan tidak mengubah handoff/operasi.

## Hasil aktual lokal

Manifest final lokal disimpan pada `.runtime/cleanup-20261109-local.json` dan salinan bukti `artifacts/maintenance/cleanup-20261109/local.json` di root main. SHA256: `9f9458ac1b097c6284a1da9b45f66b12563f9b8fe9acfc8e42ec09037cf6bb49`. Reviewer menghitung ulang 52 entri beserta totalnya dari array `removed`, bukan memakai estimasi inventori.

| Jenis yang benar-benar dihapus | Jumlah path | Allocated bytes |
| --- | ---: | ---: |
| Cache import/editor Godot nonaktif, termasuk salinan cold/hero | 19 | 1.162.543.104 |
| Build aplikasi/Vite nonaktif | 6 | 134.373.376 |
| Ekspor game compiled lama | 9 | 903.503.872 |
| Arsip tar/PCK/gzip lama dan transfer yang selesai | 17 | 2.148.126.720 |
| Installer export templates yang sudah terpasang | 1 | 1.281.351.680 |
| **Total aktual** | **52** | **5.629.898.752** |

Total aktual sekitar 5,63 GB allocated dan 5.603.355.860 logical bytes. Pada penghapusan awal teramati kenaikan ruang bebas 4.990.521.344 B. Manifest terakhir mencatat ruang bebas 14.243.237.888 B, tetapi build/QA dan penggunaan swap juga berubah selama pekerjaan. **Jangan mengatribusikan seluruh perubahan ruang bebas itu kepada 52 path yang dihapus**, atau menjumlahkan logical dan allocated sebagai reklamasi tambahan.

Daftar path dan byte exact ada pada manifest. Folder source snapshot lama tetap; hanya cache/compiled export child serta arsip yang dipilih integrator dibuang. Tidak ada penghapusan seluruh worktree atau parent `.runtime`.

## Perbedaan dengan inventori sebelumnya

[Inventori read-only](06p-local-cache-cleanup-inventory.md) adalah daftar calon, bukan catatan penghapusan. Keputusan integrator lebih luas daripada subtotal generated 1.411.207.168 B: beberapa ekspor/arsip bersyarat kemudian dinyatakan obsolete dan ikut dibersihkan.

`templates.tpz` semula ditahan pada inventori. Setelah memverifikasi Web templates sudah terpasang, integrator menghapus **arsip installer** 1.281.351.680 B. Reviewer memastikan installed templates Godot `4.7.2.stable` masih memiliki delapan ZIP Web, termasuk `web_nothreads_release.zip` dan `web_nothreads_debug.zip`. Binary dan installed templates tetap ada; reviewer tidak menjalankan Godot untuk memeriksanya.

Arsip lokal f319/11c kemudian ikut dihapus. Transfer lokal `06b-f4fac83.tar.gz` juga dihapus setelah image/PCK di VPS diverifikasi; source serta ekspor aktif tetap. Keberadaan salinan transfer f4 di VPS dibedakan dari arsip lokal ini dan masih diperlukan sampai aktivasi staging.

## Pemeriksaan preservasi

Reviewer memeriksa ulang seluruh 52 entri: 45 target sudah tidak ada; tujuh folder public/game dengan `preservedGitkeep=true` masing-masing hanya berisi `.gitkeep`.

Pemeriksaan keberadaan read-only juga memastikan:

- 29 worktree/pointer `.git` masih utuh. Tidak ada branch atau source worktree yang dibuang.
- Root main cache, public game, web/API dist dan shared `node_modules` tetap ada untuk API 3101 dan QA.
- Binary Godot, installed Web templates, `.runtime/worldkit-repo/.git` serta direktori Mongo/Redis lokal tetap ada.
- Anotasi/bukti restart Nala, kandidat house-alignment dan native sequence root tetap ada.
- Seluruh source, bukti PNG/JSON/log, tool sources/binaries serta data/config dipertahankan menurut manifest. Pemeriksaan reviewer atas contoh penting dan pointer Git tidak dianggap sebagai hash audit seluruh source/database.

Symlink node_modules tidak diikuti untuk menghapus target shared. Tidak membaca isi `.env`, private key, kredensial atau data database. Tidak ada reseed, migrasi atau perubahan ekonomi/gameplay yang dilakukan untuk pembersihan.

## Hasil aktual VPS

Reviewer membaca `/tmp/jalasmara-cleanup-20261109.json` melalui SSH read-only dan mencocokkan `df`, `docker system df`, image ID, kesehatan container dan HTTP. Salinan bukti root: `artifacts/maintenance/cleanup-20261109/vps.json`, SHA256 `be08a1eac3c65f8aedec4db518645962818faee121cbae98d3a9bd8065e71e95`.

- 24 tag image lama dihapus. Dua direktori build f319/11c dan dua arsip transfernya tidak lagi ada; keempat path diperiksa ulang.
- Ruang bebas VPS teramati berubah dari 28.129.341.440 B menjadi 43.568.685.056 B, sekitar **15,44 GB lebih longgar**. Ini perubahan teramati selama cleanup sekaligus build kandidat baru, bukan penjumlahan ukuran Docker.
- Images berubah dari 30 / 16,78 GB menjadi 5 / 2,227 GB. Build cache berubah dari 195 entri / 10,47 GB menjadi **0 B**. Lima volume data tetap ada; tidak ada volume prune.
- Log integrator mencatat builder prune 10,47 GB dan dangling image prune 1,398 GB. Angka tersebut tidak dijumlahkan dengan image sizes atau delta `df`, karena layer dapat dipakai bersama.

Image aktif/rollback `jalasmara:current` tetap `sha256:5c5a503d3d228042f457d8ddbe9785a20a7a5b49b035d5ea34f4346d01bf937a`. Kandidat `jalasmara:06b-f4fac83` tetap `sha256:43bd232ffcb651027b920b9967b0690f2631946e6ed2b582a7e9195416c462f9`. Kedua pin dicocokkan langsung dengan `docker image inspect`. App, Mongo dan Redis berstatus running/healthy; `/api/health` memberi HTTP 200. **Kandidat belum dianggap aktif di staging.**

Integrator memverifikasi PCK kandidat `43df70a9c86d4feafd18daed16297a6c5b2cc02582daa1ee0b4d32605f56d19e`, 64.307.804 B. Backup terbaru `20261109T113749Z` mempunyai SHA256 `2f62b715b8159224d9e6c461e37fefd8117ac2e922eac21e669c184fe3ae3318`; menurut pemeriksaan integrator, restore 42 dokumen cocok dan database uji dibuang. Checksum `.env` privat serta ID Mongo/Redis dibandingkan integrator dan tetap sama. Reviewer memeriksa kesehatan serta ID container sekarang; tidak membaca `.env`, private baseline atau isi data untuk mengulangi perbandingan tersebut.

Source/build directory dan arsip transfer f4 di VPS masih dipertahankan untuk aktivasi. Integrator akan mencatat penghapusan duplikat sementara itu setelah tidak diperlukan; laporan ini tidak mengklaimnya sudah dihapus. Current/rollback, source, backup, volume serta bukti tetap dilindungi.

Tool aktual reviewer: SSH read-only, pembacaan JSON, Python3/`hashlib`, metadata installed templates, `df`, `docker system df`/inspect/ps dan HTTP health. Tidak menjalankan `prune`, `rm`, engine/browser, menghentikan service atau mengubah volume. Root tetap pemilik penghapusan, rilis, handoff, AGENTS dan operasi.
