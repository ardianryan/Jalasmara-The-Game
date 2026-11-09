# Inventori lokal cache/build Jalasmara

9 November 2026. Permintaan pengguna: bersihkan cache/hasil build yang sudah tidak dipakai di PC dan VPS. Tugas reviewer ini **inventori lokal read-only**, tanpa penghapusan dan tanpa akses VPS. Integrator memutuskan serta menjalankan penghapusan path spesifik. Root main berada pada87ce67f saat inventori awal; integrator sedang memeriksa paket Balai berikutnya.

## Kandidat yang dapat direklamasi

Inventori metadata105 path pada29 worktree. Ukuran di bawah adalah **allocated bytes** (`st_blocks×512`, dengan pemeriksaan nested memakai `du -sk×1024`), bukan janji ruang bebas aktual pada APFS yang mungkin memakai clone/snapshot. Root perlu mencatat `df` sebelum/sesudah penghapusan. Symlink tidak diikuti dan tidak dihitung sebagai salinan dependency.

| Kelompok | Allocated bytes | Alasan/batas |
| --- | ---: | --- |
|15 cache Godot worktree non-root yang sudah tidak aktif|977.055.744|Cache dapat diimpor ulang. Alpha `balai-test` sudah RELEASE setelah focused19PASS menurut integrator. Source/log/bukti tetap.|
|Build lama integration: web dist + public game + API dist|233.545.728|Server integration lama sudah berhenti; sourcef319 dan ekspor5f superseded. Sisakan `.gitkeep` pada public/game.|
|Dist/Vite dari `06-site-next` dan `Jalasmara-web`|15.118.336|Dua web/dist dan dua apps/web/node_modules yang hanya berisi `.vite`/`.vite-temp`; bukan shared dependency root.|
|Cache nested eksperimen cold/hero lama|185.487.360|Empat path cache terpisah; jangan menghapus parent source snapshot atau laporan eksperimen.|
|**Subtotal generated inactive**|**1.411.207.168**|Tidak termasuk root main, source kandidat, binary, templates, dependency atau artefak bukti.|
|Dua arsip06b lama yang integrator nyatakan superseded43df|432.263.168|`06b-11c7576.tar.gz`216.145.920B + `06b-f319da9.tar.gz`216.117.248B. Root mengizinkan masuk daftar penghapusan setelah ekspor pengganti tersedia.|
|**Total kandidat generated + dua arsip**|**1.843.470.336**|Sekitar1,72GiB; belum ada penghapusan oleh reviewer.|

Path exact dan bytes per path tersedia pada `artifacts/maintenance/local-cleanup-20261109/jalasmara-curated-cleanup-20261109.json` di worktree `Jalasmara-06-nala-restart`, serta `/tmp/jalasmara-curated-cleanup-20261109.json`. Field `safeGeneratedCandidates` merupakan daftar calon untuk keputusan root, bukan script penghapusan. `authorizedOldArchiveCandidates` hanya dua arsip yang telah dinyatakan obsolete oleh integrator. Tidak ada wildcard penghapusan.

### Cache Godot inactive

Semua path berikut berakhiran `/client-godot/.godot` dan berada di `/Users/ardianryan/Documents/`. Hapus cache saja, bukan worktree, source, `.runtime` atau `artifacts`.

| Worktree | Allocated bytes |
| --- | ---: |
|Jalasmara-06-body-next|64.995.328|
|Jalasmara-06-camera|64.974.848|
|Jalasmara-06-dialogue-next|64.995.328|
|Jalasmara-06-hutan|67.149.824|
|Jalasmara-06-integration|65.064.960|
|Jalasmara-06-laut|64.974.848|
|Jalasmara-06-nala-next|64.995.328|
|Jalasmara-06-npc|64.974.848|
|Jalasmara-06-npc-alpha|64.638.976|
|Jalasmara-06-shelter|64.974.848|
|Jalasmara-06-tools-next|64.995.328|
|Jalasmara-06-view|64.995.328|
|Jalasmara-laut|64.303.104|
|Jalasmara-map|64.303.104|
|Jalasmara-06-balai-test, sesudah RELEASE|66.719.744|

Empat cache nested root `.runtime/`: `hero-build/client-godot/.godot`51.953.664B; `cold-export-test/client-godot/.godot`44.552.192B; `cold-import/.godot`44.490.752B; `cold-import-initial-cache`44.490.752B. Subfolder `imported` adalah bagian parent `.godot`, **tidak dijumlahkan dua kali**.

## Rincian `.runtime` root dan kandidat bersyarat

Root `.runtime` memakai6.943.621.120 allocatedB pada snapshot inventori. Jangan menghapus seluruh direktori: ia mencampur binary/tool, database, source repo, provenance, laporan dan ekspor lama.

| Path relatif root `.runtime/` | Allocated bytes | Perlakuan |
| --- | ---: | --- |
|templates.tpz|1.281.351.680|PROTECT: templates shared yang diminta integrator.|
|dotnet|631.947.264|PROTECT: shared toolchain; tidak dibuktikan unused.|
|godot|353.714.176|PROTECT: binary Godot aktif bersama.|
|06b-f319da9.tar|259.653.632|Arsip lama tambahan; root memutuskan terpisah, tidak dimasukkan otomatis bersama izin dua.gz.|
|hero-build|238.399.488|Parent campuran source. Cache51.953.664 dan export101.408.768 dapat dipisah, parent tetap.|
|worldkit-repo|212.840.448|PROTECT: repository sendiri dengan `.git`, tools dan notice; bukan cache engine.|
|release-ed6494b|207.347.712|Snapshot source campuran, jangan hapus parent. Export108.949.504 dapat dipertimbangkan terpisah.|
|village7-release|206.856.192|Snapshot source campuran; export108.855.296 bersyarat.|
|village-release|206.565.376|Snapshot source campuran; export108.838.912 bersyarat.|
|cold-export-test|198.651.904|Cache44.552.192 masuk daftar generated; export94.101.504 bersyarat; source tetap.|
|performance-packs|192.745.472|Input benchmark lama. Pastikan tidak perlu rerun versi ini sebelum membuang PCK/export; bukti JSON/PNG/log tetap.|
|release-f0e7080|186.568.704|Snapshot source campuran; export101.408.768 bersyarat.|
|release-ed70cad|186.306.560|Snapshot source campuran; export101.404.672 bersyarat.|
|godot.zip|170.622.976|Installer download lama; belum diperintah dihapus, binary/shared templates tetap dilindungi.|
|brand-venv|115.929.088|PROTECT shared authoring environment sampai pemilik menyatakan unused.|
|cold-import|104.484.864|Hanya `.godot`44.490.752 masuk daftar; resource/source di parent tetap.|
|python312|71.073.792|PROTECT authoring runtime.|
|player-gait-staging|35.549.184|PROTECT source/provenance original karakter; jangan perlakukan semua staging sebagai hasil build.|

Delapan export `apps/web/public/game` dalam snapshot runtime lama berjumlah789.213.184B. Ini **tambahan bersyarat**, belum dimasukkan subtotal generated1.411GB; daftar exact terdapat pada `oldExportCandidates` JSON. Folder performance-packs juga mempunyai dua PCK sekitar64MB masing-masing di luar export child; statusnya tetap bersyarat. PNG aset compiled di dalam export dapat dibangun ulang, tetapi PNG/JSON/log **bukti inspeksi** di luar export tidak masuk daftar penghapusan.

Enam belas arsip root `.tar`/`.gz`/`.pck` lama berjumlah1.931.960.320B sebelum memisahkan dua.gz yang diizinkan. Nama/pin terdapat pada metadata JSON. Jangan otomatis membuang arsip source/rollback lainnya hanya berdasarkan umur; root memeriksa kebutuhan rollback/pin terlebih dahulu. Dua unduhan CI lama (`build.zip` dan `godot_web.zip` pada masing-masing ci3044287626/ci3044205000) berjumlah347.992.064B. Itu juga bersyarat: laporan inspeksi JSON/TXT dan hash harus tetap, serta root menentukan apakah unduhan bukti CI masih diperlukan. Dua installer download Godot/Python312 total195.661.824B tidak dimasukkan daftar aman otomatis.

## Yang dilindungi

- Root main cache Godot67.170.304B, public game114.290.688B, web dist118.730.752B dan API dist524.288B; root API3101 serta proses pemeriksaan/ekspor masih aktif. Jangan menghapus folder output yang sedang dilayani.
- Root `node_modules`179.470.336B merupakan dependency nyata shared. Sembilan symlink node_modules worktree menunjuk ke sana; allocated0B, logical50B per link. Menghapus link tidak mereklamasi179MB dan jangan pernah mengikuti link untuk menghapus target.
- Root `apps/web/node_modules`3.121.152B hanya cache Vite, tetapi lane root/QA aktif sehingga tetap dilindungi saat ini.
- Seluruh `artifacts` lintas worktree:1.142.136.832B. Simpan PNG/JSON/MP4/contact-sheet dan laporan native/browser, termasuk hasil gagal serta root/native terbaru. `.runtime` logs dan source fixtures juga tetap.
- Source/pointer `.git` semua worktree, branch restart `b93719d`/`5cc90ac`, marks/model/annotations, kandidat house-alignment, QA source serta standalone WorldKit. Worktree house-alignment/restart tidak mempunyai `.godot` pada snapshot ini; bila muncul cache baru karena tugas aktif, jangan ikut dihapus.
- Root `.runtime/godot`, templates, SDK/Python, shared npm dependencies, database Mongo/Redis dan kredensial/keys. Tidak membaca isi `.env` atau file kredensial; profil terperinci tidak menelusuri folder keys/mongo/redis.
- `apps/web/public/game/.gitkeep` terlacak Git. Untuk path public/game, bersihkan generated contents sambil mempertahankan file ini.

Tool aktual: Python3 `lstat`/`scandir` untuk metadata dan klasifikasi symlink, `du -sk` pada nested generated folders, `git worktree list`, `git ls-files`/`check-ignore`, dan Git untuk laporan. Tidak menjalankan Godot/browser, tidak memakai kredensial/VPS, dan tidak mengubah/menghapus cache atau hasil build. Empat snapshot JSON inventory disimpan di artifacts maintenance worktree restart dan salinannya pada `/tmp`; bukti itu tidak di-stage sebagai source.
