# Pembersihan storage lokal dan VPS

9 November 2026. Permintaan pengguna adalah menghapus cache/hasil build yang sudah tidak dipakai untuk menghemat storage. **Pembersihan lokal telah dilakukan integrator**, kemudian reviewer memeriksa manifest dan keberadaan berkas yang dipertahankan. Reviewer tidak melakukan penghapusan tambahan, tidak menjalankan engine/browser, dan tidak mengubah handoff/operasi.

## Hasil aktual lokal

Sumber bukti final lokal: `/Users/ardianryan/Documents/Jalasmara/.runtime/cleanup-20261109-local.json`, SHA256 `451a0ce53309cd985de5a869cc0d5752d14bb806deb60a7f120b70391558419c`. Hitungan51 entri dan jumlah `allocatedBytes` dihitung ulang dari seluruh array `removed`, bukan disalin dari estimasi inventori. Pemeriksaan awal mencakup49 path; integrator kemudian menambahkan dua gzip obsolete ke manifest dan reviewer memeriksa keduanya sudah hilang.

| Jenis yang benar-benar dihapus | Jumlah path | Allocated bytes |
| --- | ---: | ---: |
|Cache import/editor Godot nonaktif, termasuk salinan cold/hero|19|1.162.543.104|
|Build aplikasi/Vite nonaktif|6|134.373.376|
|Ekspor game compiled lama|9|903.503.872|
|Arsip tar/PCK/gzip lama|16|1.931.960.320|
|Installer export templates yang sudah terpasang|1|1.281.351.680|
|**Total aktual**|**51**|**5.413.732.352**|

Manifest final mencatat5.387.189.795 logical bytes. Allocated bytes yang dihapus sekitar5,04GiB atau5,414GB. Snapshot awal free space sebelum pembersihan3.964.059.648B dan sesudah49 path8.954.580.992B: saat itu teramati kenaikan4.990.521.344B. Sesudah dua gzip tambahan dibuang, manifest diperbarui dengan free snapshot7.585.648.640B sementara arsip baru/build/browser juga memakai disk. **Jangan menyamakan selisih free snapshot akhir dengan total bytes penghapusan51 path.** APFS dan aktivitas bersamaan juga dapat memengaruhi angka free space; logical dan allocated tidak dijumlahkan sebagai reklamasi tambahan.

Pembacaan `df -k` read-only sesudahnya melaporkan7.157.572KiB tersedia atau7.329.353.728B. Itu snapshot lebih baru ketika pekerjaan build/QA telah berlanjut, bukan pengganti dua pengukuran sebelum/sesudah pada manifest. Tidak disimpulkan sebagai penghapusan gagal atau angka reklamasi baru.

Daftar51 path exact dan bytes ada pada manifest. Folder source snapshot lama tetap; hanya cache/compiled export child serta arsip yang sudah dipilih integrator dibuang. Tidak ada penghapusan seluruh worktree atau parent `.runtime`.

## Perbedaan dengan inventori sebelumnya

[Inventori read-only](06p-local-cache-cleanup-inventory.md) adalah daftar calon, bukan catatan penghapusan. Keputusan integrator lebih luas daripada subtotal generated1.411.207.168B: beberapa export/arsip bersyarat kemudian dinyatakan obsolete dan ikut dibersihkan.

`templates.tpz` semula ditahan pada inventori. Integrator memverifikasi Web templates sudah terpasang, lalu menghapus **arsip installer**1.281.351.680B, bukan installed templates. Reviewer memastikan `/Users/ardianryan/Library/Application Support/Godot/export_templates/4.7.2.stable/` masih memiliki delapan ZIP Web, termasuk `web_nothreads_release.zip`10.245.903B dan `web_nothreads_debug.zip`10.232.720B. Tidak ada Godot import/export baru yang dijalankan reviewer untuk memeriksanya.

Dua arsip lokal `06b-f319da9.tar.gz`216.114.566 logicalB dan `06b-11c7576.tar.gz`216.144.745 logicalB awalnya belum dihapus pada checkpoint49 path. Integrator kemudian menghapus keduanya, menambahkan432.263.168 allocatedB ke manifest final51 path, dan reviewer memastikan kedua path tidak ada. Ini perubahan aktual sesudah checkpoint awal, bukan kesimpulan dari inventori calon. `godot.zip` masih ada; arsip source/build f4 yang sedang dipakai juga dilindungi hingga integrator menyatakan sudah tidak perlu. Catatan penghapusan dua arsip f319/11c pada VPS adalah kejadian terpisah; status remote belum diverifikasi reviewer pada checkpoint ini.

## Pemeriksaan preservasi

Reviewer memeriksa ulang seluruh51 entri removed:44 target yang tidak ditandai `preservedGitkeep` sudah tidak ada;7 folder public/game dengan `preservedGitkeep=true` masih ada dan masing-masing hanya berisi `.gitkeep`.

Pemeriksaan keberadaan read-only juga memastikan:

-29 worktree/pointer `.git` masih utuh. Tidak ada branch atau source worktree yang dibuang.
-Root main `client-godot/.godot`, `apps/web/public/game`, `apps/web/dist`, `apps/api/dist` dan shared `node_modules` tetap ada. Ini melindungi proses aktif/API3101 dan hasil build yang dipakai QA.
-Binary Godot `.runtime/godot`, installed Web templates, standalone `.runtime/worldkit-repo/.git`, serta direktori Mongo/Redis lokal tetap ada. Shared tool/dependency dan konfigurasi tidak dipilih untuk dihapus.
-Anotasi sumber restart Nala `tools/player-gait/restart-support-east.json`, bukti `artifacts/godot/nala-restart-source/annotated-support-east.png`, worktree house-alignment dan root native `artifacts/godot/nala-gait-transitions/results.json` tetap ada.
-Manifest integrator mempertahankan seluruh source, artefak bukti PNG/JSON/log, tool sources/binaries dan database/config. Reviewer memeriksa contoh penting di atas serta29 pointer Git; tidak mengklaim melakukan hash audit seluruh isi sumber/database.

Symlink node_modules tidak diikuti untuk menghapus target shared. Tidak membaca isi `.env`, private key, kredensial atau data database. Tidak ada reseed, migrasi atau perubahan ekonomi/gameplay yang dilakukan untuk pembersihan.

## VPS: checkpoint parsial, belum hasil akhir

Menurut status integrator,24 tag image lama dan arsip f319/11c di VPS sudah dibuang; build cache masih menunggu langkah final. Reviewer **belum membaca manifest remote atau `df`/`docker system df` sesudah prune final**, sehingga tidak mencantumkan jumlah byte remote yang berhasil direklamasi atau mengklaim pembersihan VPS selesai. Penghapusan tag saja juga tidak otomatis membebaskan semua layer yang masih dipakai image lain.

Sesudah integrator memberi sinyal final prune, langkah reviewer terbatas pada SSH read-only: baca `/tmp/jalasmara-cleanup-20261109.json`, `df` dan `docker system df`, cocokkan image/arsip yang benar-benar dihapus serta current/rollback/data yang dipertahankan, lalu tambahkan hasil final pada laporan ini. Tidak ada `prune`, `rm`, penghentian service, perubahan image aktif atau penghapusan volume yang diotorisasi untuk reviewer.

Tool yang benar-benar dipakai pada checkpoint ini: pembacaan manifest JSON, Python3 untuk menjumlahkan/mengecek path, `hashlib` untuk pin manifest, metadata installed templates, `df -k`, Git dan `apply_patch` untuk laporan. Tidak memakai SSH pada checkpoint awal ini. Root tetap pemilik penghapusan, rilis, handoff, AGENTS dan operasi.
