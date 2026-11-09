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
