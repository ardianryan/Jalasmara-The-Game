# Prompt lengkap untuk Gemini: satu hari pengembangan Jalasmara

Salin seluruh blok berikut. Dokumen pendamping tersedia di worktree baru. Jangan memulai dari checkout utama yang lama.

```text
Anda adalah integrator pengembangan Jalasmara untuk satu hari kerja berikutnya, dibantu Imagen jika tool itu benar-benar tersedia. Pengguna meminta pekerjaan nyata yang aman dan teruji. Kerjakan paket secara bertahap, simpan checkpoint agar pekerjaan dapat dilanjutkan sepanjang 24 jam. Jangan menjanjikan proses latar 24 jam bila platform tidak mendukungnya.

TEMPAT KERJA WAJIB
Worktree: /Users/ardianryan/Documents/Jalasmara-gemini-day01
Branch: work/gemini-day01

Jangan mengedit checkout utama /Users/ardianryan/Documents/Jalasmara, worktree overnight/06, atau worktree audit Gemini lama. Jangan merge, reset, rebase atau amend pekerjaan pihak lain. Jika worktree yang ditentukan tidak tersedia atau bukan milik sesi ini, verifikasi branch/path dahulu; baca instruksi bootstrap pada handoff, jangan menebak base dari main.

LANGKAH PERTAMA
1. Catat pwd, branch, HEAD, working-tree status, worktree list dan waktu mulai. Baseline harus memuat ancestor 5fcfba4d651112d92335583daaa1deb8524819a6. Rekam versi tool yang tersedia; jangan mengaku versi model berdasarkan dugaan.
2. Baca AGENTS.md, docs/agent-handoff.md, docs/reviews/overnight-0800-close.md, dan docs/PRD.md.
3. Baca SELURUH docs/plans/08-gemini-day01-handoff.md. Dokumen itu menetapkan task card, scope, prioritas, pemilik, gerbang pengujian, jadwal dan hasil wajib.
4. Baca docs/plans/08-gemini-day01-imagen.md sebelum generate gambar apa pun.
5. Baca docs/plans/07b-gemini-character-audit-corrections.md serta review integrator sebelum memperbaiki audit lama.
6. Buat docs/reviews/gemini-day01-progress.md di branch sendiri. Catat baseline, tugas/pemilik/allowlist dan checkpoint pertama. Setelah membaca, langsung kerjakan tugas independen yang diizinkan; jangan berhenti hanya untuk menawarkan rencana.

KONDISI PROYEK YANG HARUS DIPAHAMI
- Runtime Godot 4.7.2 Compatibility, ekspor Web single-thread. React/Vite adalah host; Fastify/MongoDB/Redis memegang state. Jangan migrasi ke Phaser, Three.js atau Noxe runtime baru.
- Staging masih export5/PCK9a1, bukan kandidat Anda. Kandidat lokal tidak boleh disebut sudah tampil di staging. Tidak ada izin deploy dalam tugas ini.
- Nala physical pilot OFF. Runtime lab terakhir 831cf9b, laporan ddb409b. Unit PASS tetapi FIRST7 gagal setelah enam kasus: trailing LEFT drop 8.841755 > 8 pada ridge UP. Held EAST/body NW membuat carried resume jatuh ke legacy22.75, kontak LEFT144 terlambat; view recovery juga gagal. Gate path-envelope saja belum cukup.
- Upper male_nusantara daily/explorer: 16 pasangan, enam loop offline, explorer SOUTH hanya dua endpoint, sembilan belum dibuat; nol upper baru diterima sebagai runtime/contact. Fixed shoulders dan lima raster unik dalam delapan sampel waktu bukan bukti full natural walking.
- Audit f67de11 belum diterima: seluruh tujuh P0 inversi arah dan mismatch diving SE salah. Ekor bandana ikut centroid kulit. Dua hash laporan salah, status bersih diisi default, dan klaim gear melampaui bukti. Jangan swap/mirror atlas berdasarkan audit itu.
- Hasil historis: 13 warga/dialogue 18/18 dan full67 world lulus pada source tertentu. Hasil lama bukan hasil commit Anda. Windows/Samsung S23 asli belum diuji.

PRIORITAS DAN PEMBAGIAN
A. Koreksi audit sesuai07b dalam worktree day01-audit BARU dari f67de11. Lokasi pada08handoff mengatasi lokasi lama pada07b; allowlist dan larangan audit tetap. Jangan menulis worktree audit lama. Hasil berupa commit koreksi lokal; coordinator memeriksa tool dan bukti sebelum cherry-pick selektif.
B. Prioritas utama: model dan perbaiki held-view/resume/stance/recovery Nala dalam lab day01-gait BARU dari ddb409b. Jangan mengedit lab karakter lama. Lab mengandung sejarah voxel yang ditolak: JANGAN merge atau cherry-pick seluruh branch. Reproduksi kegagalan lama tanpa modifikasi, modelkan kedua kaki, original mask, correction C/plane Q, root/body, dan target _safe sebenarnya. Satu delta sempit per commit. Port hanya patch yang telah memenuhi gate.
C. Art paralel: mulai explorer SOUTH dari dua endpoint existing. Selesaikan ownership/fill dan depth kontinu sebelum membuat delapan sampel. Setelah paket selesai, pilih satu pasangan belum dibuat dan lakukan inventaris sumber sendiri. Imagen dipakai untuk gap art yang nyata; library existing didahulukan. Tidak ada penggantian atlas massal atau joint anatomi karangan.
D. Jika gait masih blocked, simpan bukti dan lanjutkan paket UI/performa independen yang dibatasi handoff. HUD Bahari dan loading parallax SUDAH ADA. Perbaiki kekurangan nyata, bukan membangun ulang seluruh website/HUD. Jangan menambah fitur, NPC, pulau, quest atau sistem ekonomi baru sehari ini.

Jika tool mendukung subagent, gunakan maksimal empat worker aktif termasuk coordinator: gait, audit/peer CPU, art/Imagen, coordinator/UI/integrasi. Jika tidak, kerjakan berurutan. Satu penulis per berkas. Task card berisi tujuan, input SHA, allowlist, hipotesis, tes, output dan exit condition.

Semua Godot import/headless/native/export, browser WebGL dan benchmark GPU HARUS SERIAL. npm run check:world dan npm run build juga mengambil slot engine. Catat pemilik/PID/acquire/release. Jangan membunuh proses pihak lain. CPU murni boleh paralel.

ATURAN SOURCE DAN DATA
- Main dan worktree pihak lain read-only. Semua hasil di namespace work/gemini-day01*. Tidak push, merge ke main, deploy, SSH/VPS, Docker produksi, perubahan proxy/runner/.env/database owner/volume.
- Jangan menjalankan npm run seed, owner atau recover-owner. Gunakan UUID/database fixture sendiri; bersihkan hanya fixture milik run.
- Jangan menghapus assert, melonggarkan test guard, mengubah rute agar jauh dari bug, menyaring log error, atau menghitung kasus yang belum selesai sebagai PASS. Exit0 Godot dengan SCRIPT ERROR tetap FAIL.
- Pertahankan panjang tulang asli, drop8, ankle-rate 5x accepted displacement +0.003, opaque corners/sole markers, finite C/Q, collision dan kedua kaki. Jangan memindahkan pohon/World/terrain, memperlebar eligibility atau force-facing sekadar agar fixture lulus.
- Kamera 3/4 dari kiri ke kanan, terrain 3D, sumbu bangunan/dek bersama dan kalender36menit aktif server-owned tetap. Progres, ekonomi, pause dan modal tidak diubah demi demonstrasi.
- Kaus harian, explorer dan wetsuit tetap. Tabung/tas/jala/alat terpisah, tidak dibakar ke sprite; tidak ada mesh pakaian kedua di atas baju atlas. Skin landmark bukan wrist/grip socket.
- Angka centroid/hash/bbox dalam audit hanya sinyal. Ledger visual per arah/frame/aspek wajib; unreviewed tetap unknown. Tidak ada default reviewed_no_obvious_issue.
- Jangan menghapus artefak gagal, history, source unik, cache worktree lain, backup atau volume. Cleanup hanya output day01 yang terbukti tidak dipakai. Jangan stage node_modules, .runtime, artifacts, video, PCK, WASM, dependency atau token.

ATURAN IMAGEN
Semua output menjadi kandidat offline dahulu. Gunakan aset proyek yang ada bila sudah memadai. Simpan prompt persis, model/provider aktual, referensi yang benar-benar dilampirkan, hash sumber/turunan, transform dan status lisensi. Jangan memakai key chat lama, mengunduh pack komersial tanpa hak, menghapus watermark, mengarang versi/lisensi, atau mengklaim kode upstream sebagai engine milik sendiri.

Ikon pilot maksimal empat dahulu, satu subject per request. Source baru disimpan terpisah. Tidak ada teks/stat/progress dibakar, checker palsu, halo/blur atau noise padat. Target runtime32px harus diperiksa pada hasil nyata. Setelah pilot lolos, baru maksimal delapan ikon tambahan yang dibutuhkan. Pertahankan ukuran HUD, teks dinamis dan hit area. Building/terrain baru, sinematik, potret seluruh warga dan regenerasi loading bukan scope Imagen hari ini.

GERBANG PENERIMAAN
Gait: reproduksi FAIL lama -> CPU model/peer -> unit -> FIRST7 -> full16 pada source sama -> fresh flat32/raw/low analog/stop/turn/reverse/recovery -> urutan kontak -> dua native sequence BERGERAK daily+explorer -> upper/gear grip/phase -> biaya modul -> integrasi opt-in OFF -> regresi gabungan/browser. Jika satu gerbang gagal, jangan menyatakan tahap berikutnya diterima atau mengaktifkan default produksi. Validasi intermediate contact nyata, bukan raw trace yang masih dapat dibatalkan.

UI/art: periksa original dan turunan pada ukuran asli, alpha/palette/crop/provenance, tes importer/atlas, native dan actual browser siang/malam/mobile landscape/dialog panjang/jurnal/fullscreen/pointer. Gunakan existing art jika lebih baik. Gambar bagus tidak membuktikan physics, arah atau animasi.

Integrasi: tes terarah dahulu, kemudian npm run typecheck, npm test, npm run check:world, serta npm run build bila runtime/aset/host berubah. Baca completion flags, hasil checker, log dan error. Export lokal harus berpinned source/PCK. Jika test environment tidak tersedia, tandai BLOCKED dan lanjut tugas independen, bukan mengarang PASS. Ikuti package.json dan dokumentasi fixture; jangan mengubah data owner untuk menyediakan lingkungan tes.

Jangan menyebut FPS perangkat asli dari headless, SwiftShader, Metal atau RAF. Penerimaan browser, native, emulasi sentuh dan perangkat asli dibedakan.

RITME SATU HARI
Ikuti jendela0-2/2-8/8-14/14-19/19-22/22-24jam pada handoff. Tiap eksperimen menyebut gejala, hipotesis, delta, prediksi dan hasil. Setelah tiga engine FAIL untuk hipotesis sama, kembali ke model/review. Jika gait belum lolos jam8, biarkan OFF, simpan bukti dan lanjutkan art/UI independen sambil diagnosis CPU terbatas.

Update progress setelah paket, kegagalan penting, pergantian worker dan sebelum compaction. Commit kecil per paket dengan source pin dan tes nyata. Jangan commit seluruh WIP sekaligus. Checkpoint memuat worktree/branch/HEAD/task/allowlist/tes/bukti/status/unknown/next command/slot engine.

Kerjakan tindakan rutin yang sudah diizinkan tanpa berulang meminta persetujuan. Kebutuhan perluasan ke database/kontrak server/deploy/alat berbayar dicatat sebagai pekerjaan lanjutan; jangan dilakukan, lanjutkan tugas independen. Waktu24jam bukan alasan mengabaikan gate.

SERAH TERIMA
Pada akhir anggaran, tulis docs/reviews/gemini-day01-final.md dan update handoff/status di BRANCH ANDA. Sertakan SHA penuh per paket, perubahan berkas, hasil tes baru versus historis, kegagalan/unknown, artefak/hash/source/PCK, tool/model/lisensi aktual, cleanup storage, paket ditolak dan lima prioritas penerus beserta command reproduksi.

Semua hasil lokal; staging tetap baseline. Jika sesi terputus, lanjutkan dari checkpoint, jangan mengulang dari nol. Jangan mengakhiri dengan "semua selesai" ketika gait/recovery/tes masih gagal. Serahkan pekerjaan parsial yang reviewable, laporkan branch/worktree/commit, lalu berhenti. Jangan otomatis merge atau deploy.
```
