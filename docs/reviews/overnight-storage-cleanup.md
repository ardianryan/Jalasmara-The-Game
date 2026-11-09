# Pembersihan cache worktree overnight

Dilakukan 10 November 2026 setelah setiap pemilik melepas output yang tidak digunakan. Source, hasil review, log, database, volume, berkas lingkungan, dependency, serta build preview aktif tetap disimpan. Tidak ada pembersihan VPS pada checkpoint ini.

| Path relatif terhadap Documents | Byte allocated sebelum dihapus | Pemeriksaan |
|---|---:|---|
| `Jalasmara-overnight-village/client-godot/.godot` | 64,999,424 | Pemilik melepas; bukan symlink; tidak tracked; lsof tanpa pemegang |
| `Jalasmara-overnight-pen-final/client-godot/.godot` | 65,015,808 | Pemilik melepas; bukan symlink; tidak tracked; lsof tanpa pemegang |
| `Jalasmara-overnight-resident-art/client-godot/.godot` | 65,048,576 | Pemilik melepas; bukan symlink; tidak tracked; lsof tanpa pemegang |
| `Jalasmara-overnight-hud-perf/apps/web/dist` | 5,025,792 | Pemilik melepas; bukan symlink; tidak tracked; lsof tanpa pemegang |
| `Jalasmara-06-nala-restart-audit/client-godot/.godot` | 64,999,424 | Pemilik melepas; bukan symlink; tidak tracked; lsof tanpa pemegang |

Total allocated yang dihapus **265,089,024 byte** (sekitar 252.81 MiB). Ruang bebas teramati 11,545,231,360 → 11,809,792,000 byte. Selisih ruang bebas dapat dipengaruhi aktivitas proses lain dan tidak dipakai sebagai ukuran file yang dihapus.

Health preview lokal3111 sebelum dan sesudah `status: ok`. Preview baseline3101, ekspor integrasi yang aktif, cache karakter aktif serta cache integrator untuk build berikutnya tidak dihapus. Manifest bukti lengkap: `.runtime/overnight-storage-released-caches.json`. Tidak menjalankan prune volume, menghapus worktree/source, atau menyentuh akun pemain.


## Sesudah smoke publik overnight diterima

Pada sekitar01.16WIB, PCK1315/image d044 sudah lulus smoke default lima pemeriksaan. Baru sesudah itu arsip transfer dan image yang digantikan dibersihkan. Build aktif serta satu rollback d60 dipertahankan.

| Output yang dihapus | Ukuran yang diverifikasi |
|---|---:|
| Lokal `.runtime/overnight-release2/source.tar` | 265.236.480 byte; 276.832.256 byte teralokasi |
| VPS `/tmp/jalasmara-overnight-480d27d` | 264.136.264 byte menurut `du -sb` |
| VPS arsip sumber, delta pertama dan kedua di `/tmp` | 265.236.480 +21.950 +24.102 byte |

Arsip lokal/VPS memiliki SHA `021ae26444e887f3e321f168517525e6b44830da3741040f02a0b24d408ba213` sebelum dihapus. Lokal bukan symlink dan tidak mempunyai pemegang terbuka menurut lsof. Source Git, manifest dan patch kecil lokal sebagai bukti tetap ada. Tidak ada source worktree atau cache karakter/integrator aktif yang dihapus.

Container gagal build `1f8d63d934ad` (exit1) dihapus. Image43bd/dua tag rollback lama dan image intermediate d811/overnight-bdc8297 tidak dirujuk container mana pun lalu dipensiunkan. `docker image prune -f` membuang layer dangling setelah build selesai, melaporkan433,2MB; builder prune0B. Tidak menjalankan container prune atau volume prune. Container mongo-init lama yang bukan output build ini tetap.

Ruang bebas VPS teramati **41.857.863.680 →44.030.980.096 byte**, selisih2.173.116.416byte. Jangan menjumlahkan ukuran layer image yang mungkin dipakai bersama sebagai byte reklamasi. Ruang bebas lokal sebelum/sesudah arsip **11.095.490.560 →11.372.355.584 byte**; aktivitas proses lain dapat memengaruhi selisihnya.

Sesudah pembersihan: API `status:ok`, seluruh PCK dalam container masih SHA1315/64.491.320byte, `.env` SHA62755533… tetap. Image aktifd044 dan rollbackd60 terverifikasi; Mongo/Redis, volume dan backup172408Z tetap. Lima image tersisa termasuk base/dependensi; tidak dihapus hanya karena angka reclaimable Docker.

Bukti: `.runtime/overnight-storage-pre-cleanup.log`, `overnight-storage-vps-cleanup.log`, `overnight-storage-post-pck.log`, dan `.runtime/overnight-release2/local-archive-cleanup.json`. Manifest release mencatat arsip sudah dihapus setelah penerimaan; path arsip lama bukan file yang masih tersedia.
