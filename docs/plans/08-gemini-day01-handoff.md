# Handoff satu hari kerja Gemini: Jalasmara

Tanggal penyusunan: 10 November 2026. Durasi: 24 jam kerja bertahap sejak Gemini mulai, bukan janji bahwa satu proses dapat berjalan tanpa batas sesi. Jika sesi berhenti, lanjutkan dari log commit dan checkpoint. **Utamakan hasil yang teruji; jangan menyatakan semua pekerjaan selesai karena waktu habis.**

Dokumen ini memberi cakupan pengembangan baru untuk sehari, melampaui tugas audit-only sebelumnya. Batas audit tetap berlaku pada paket audit; izin pengembangan tidak membuat seluruh repository bebas diubah. Prompt pembuka ada pada [prompt lengkap](08-gemini-day01-prompt.md); aturan dan prompt Imagen ada pada [kontrak aset](08-gemini-day01-imagen.md).

## 1. Tempat kerja yang diizinkan

| Peran | Worktree/branch | Ketentuan |
| --- | --- | --- |
| Gemini integrator | `/Users/ardianryan/Documents/Jalasmara-gemini-day01`, `work/gemini-day01` | Tempat kerja utama baru; berisi dokumen ini dan baseline integrasi terbaru |
| Gait lab, dibuat bila diperlukan | `/Users/ardianryan/Documents/Jalasmara-gemini-day01-gait`, `work/gemini-day01-gait` | Mulai dari `ddb409b`, eksperimen saja; jangan merge seluruh branch ini |
| Koreksi audit, dibuat bila diperlukan | `/Users/ardianryan/Documents/Jalasmara-gemini-day01-audit`, `work/gemini-day01-audit` | Mulai dari `f67de11`; ikuti allowlist audit, baca dokumen baru secara read-only dari worktree utama Gemini |
| Art, bila ada worker paralel | `/Users/ardianryan/Documents/Jalasmara-gemini-day01-art`, `work/gemini-day01-art` | Mulai dari commit awal day01 yang dicatat coordinator; tidak menulis runtime gait |

Checkout asli `/Users/ardianryan/Documents/Jalasmara`/main dan seluruh worktree `overnight-*`, `06-*`, serta `Jalasmara-gemini-character-audit` adalah **read-only untuk sesi Gemini**. Tidak ada reset, force checkout, amend/rebase history pihak lain, penghapusan worktree, atau checkout branch yang sedang dipakai worktree lain.

Sebelum mulai, rekam `pwd`, `git branch --show-current`, `git rev-parse HEAD`, `git status --short`, `git worktree list`, versi Node/Python/Pillow/Godot, dan waktu mulai. HEAD day01 harus mempunyai ancestor integrasi `5fcfba4d651112d92335583daaa1deb8524819a6`. Dokumen tambahan sesudah commit tersebut merupakan bagian handoff, bukan perubahan game baru.

Jangan memaksa nama worktree/branch yang sudah ada. Jika isinya merupakan sesi day01 ini, baca log dan lanjutkan. Jika bukan, laporkan konflik nama dan buat nama suffix baru hanya di namespace day01; catat path/branch aktual. Symlink `node_modules` di checkout lain bukan izin untuk men-stage atau membersihkannya.

### Membuat worktree tambahan dengan aman

Periksa `git status`, `git worktree list`, `git show --stat <base>` dan keberadaan path/branch dahulu. Jalankan hanya bila keduanya belum ada:

```sh
git worktree add -b work/gemini-day01-gait \
  /Users/ardianryan/Documents/Jalasmara-gemini-day01-gait ddb409b
git worktree add -b work/gemini-day01-audit \
  /Users/ardianryan/Documents/Jalasmara-gemini-day01-audit f67de11
```

Tidak ada `--force`. Buat hanya worktree yang akan dipakai. Jangan menyalin seluruh `.runtime`, dependency, export game, atau `.git` untuk bootstrap.

## 2. Bacaan wajib dan baseline nyata

Baca secara berurutan:

1. `AGENTS.md`, [handoff aktif](../agent-handoff.md), [laporan penutup](../reviews/overnight-0800-close.md).
2. [PRD](../PRD.md), [arah visual](../art-direction-comfy.md), [lisensi](../../THIRD_PARTY_LICENSES.md).
3. [kegagalan Nala aktual](../reviews/overnight-nala-upper-exit-831cf9b.md), [peer envelope](../reviews/overnight-stair-view-envelope-peer.md), [target exit dan pohon](../reviews/overnight-upper-exit-metric-peer.md).
4. [status 16 pasangan upper](../reviews/overnight-upper-authoring-progress.md), [rencana upper/contact](../reviews/overnight-upper-contact-authoring-plan.md).
5. [review audit Gemini](../reviews/gemini-character-audit-integration-review.md), [koreksi audit](07b-gemini-character-audit-corrections.md).
6. [panduan perangkat](../performance/overnight-device-test.md); [operasi](../operations.md) hanya untuk memahami paket, bukan izin deploy.

Baseline yang harus dipertahankan:

- Runtime **Godot 4.7.2 Compatibility/Web single-thread**, host React/Vite, Fastify/MongoDB/Redis. Jangan migrasi ke Phaser/Three.js/Noxe runtime baru.
- Kamera kiri menghadap serong kanan, 3/4, azimut −45°/elevasi35° pada konvensi proyek. Dunia dan collider tetap 3D; jangan memipihkan atau mirror seluruh peta.
- Kalender server 36 menit aktif per hari. Modal/jurnal/kuis menjeda bahaya; shader/idle tetap hidup. Jangan mengubah ekonomi/progres demi demonstrasi.
- Kaus harian, explorer, wetsuit; tabung/tas/jala/alat modular, bukan dibakar ke sprite. Direktur PT tinggal di RV/container terpisah; Inspektur Raka tetap orang berbeda; rumah pribadi lurah berbeda dari balai.
- Tema login/loading: hijau segar, air teal, cahaya lingkungan sejuk, matahari/lampu hangat, bayangan berwarna; tekstur tidak kotor berbintik padat. HUD kecil terutama malam, teks soal terbaca, joystick analog dan fullscreen tetap berfungsi.
- Staging masih export5: Docker/API `bf55342`, export Godot `72b173c`, PCK `9a1ca274b88cf65e819f1c117da2ede7992420e2128b454ef6bc3cf7f19cbb1a`, 64.500.848 byte. Kandidat day01 **belum** dirilis.
- Lokal: 67 pemeriksaan dunia dan 18 pemeriksaan browser shelter lulus sebelumnya; 13 warga dapat berdialog. Itu hasil historis source tertentu, bukan hasil commit Gemini.
- Lighting CPU `36b68af` ada dalam integrasi, belum diekspor. Pilihan upper baru masih offline. Nala physical pilot **OFF**.
- Windows/S23 belum diuji langsung; pengguna bersedia membantu nanti. Jangan mengganti bukti perangkat dengan SwiftShader/Metal atau angka RAF.

## 3. Prioritas dan pembagian satu hari

| Jendela relatif | Pekerjaan utama | Pekerjaan CPU/art paralel | Hasil minimum |
| --- | --- | --- | --- |
| Jam0–2 | Bootstrap, freeze baseline, reproduksi kegagalan sempit | Koreksi audit sumber; inventaris aset UI existing | Log awal, matriks pemilik, bukti reproduksi dan daftar delta |
| Jam2–8 | Model held-view/resume/dua kaki, kandidat gait sempit | Explorer SOUTH upper/Imagen pilot kecil | Model yang menjelaskan counterexample; satu kandidat yang bisa direview |
| Jam8–14 | Unit → FIRST7 → full16 bila gate lulus | Selesaikan satu paket art sebelum arah berikutnya | Bukti pada source sama, atau laporan blocker yang dapat direproduksi |
| Jam14–19 | Flat/raw/recovery/native jika terrain lulus; jika gagal, lanjut diagnosis bounded | Integrasi UI visual kecil yang independen, perbaikan perf yang terukur | Satu paket mandiri yang diterima lokal; tidak memaksa pilot aktif |
| Jam19–22 | Gabungkan hanya paket lolos; regresi, export lokal bila relevan | Review visual skala gameplay dan provenance | Kandidat lokal berpinned; semua kegagalan tetap terlihat |
| Jam22–24 | Bekukan scope, laporan, instruksi penerus, rapikan output sementara milik sendiri | Tidak memulai fitur besar baru | Commit lokal per paket, handoff final dan daftar belum selesai |

Waktu ini pembatas scope, bukan alasan memotong tes. Jika gait belum lolos pada jam8, simpan model/source/log, biarkan OFF, dan teruskan tugas art/UI independen yang sudah diizinkan. Jangan menghabiskan 24 jam mengulang parameter tanpa hipotesis. Tiap eksperimen harus menyebut gejala, hipotesis, delta, prediksi, dan hasil. Maksimum tiga percobaan engine gagal untuk hipotesis yang sama sebelum kembali ke model/review.

Jika alat mendukung subagent, maksimal empat worker aktif termasuk coordinator: gait, audit/peer CPU, art/Imagen, coordinator/integrasi/UI. Jika kapasitas lebih kecil, jalankan berurutan; jangan berpura-pura mempunyai subagent. Satu penulis per berkas. Audit worker dapat menjadi peer CPU setelah paketnya ditutup; art worker tidak mengambil alih physics.

## 4. Kartu A: koreksi audit, bukan repair atlas

Gunakan worktree **day01-audit baru**, bukan worktree audit lama. [Instruksi07b](07b-gemini-character-audit-corrections.md) tetap berlaku kecuali path/branch pelaksanaan diganti sesuai tabel day01; original worktree hanya dibaca. Baca review07b secara read-only dari worktree day01 karena tidak ada pada base `f67de11`.

Wajib mencabut tujuh P0 arah palsu dan mismatch diving SE, menghitung ulang hash aktual, memberi ledger visual eksplisit bagi 80 record, menandai yang belum diperiksa `unknown`, membatasi klaim gear pada cakupan nyata, serta memperbaiki exact-output allowlist/symlink/fresh-run/input-format tests. Jangan menukar/mirror atlas. Jangan menerapkan repair apa pun pada kartu ini.

Hasil: commit koreksi lokal, daftar tepat perubahan, tes aktual, hash input sebelum/sesudah, proof maksimum1MiB. Coordinator memeriksa kode tool sebelum menjalankannya dan memeriksa bukti asli; enam tes lama tidak menjadi bukti penerimaan visual. Cherry-pick hanya commit paket audit yang sudah diperiksa ke day01; jangan cherry-pick seluruh branch.

## 5. Kartu B: core gait dan transisi tangga

### Titik awal dan scope

Gunakan lab day01-gait dari `ddb409b`; runtime terakhir `831cf9b`. Lab memang memuat sejarah eksperimen yang ditolak. Jangan pernah merge seluruh lab ke day01/main. File kandidat utama: `client-godot/scripts/NalaFootPlant.gd`, `NalaLowerBody3D.gd`, `NalaStairSupportCurve.gd` serta fixture `scripts/tests/nala-stair-view-envelope.gd` dan `nala-production-terrain.gd` pada lab. Verifikasi nama/path aktual sebelum mengedit; helper pendamping perlu daftar scope tertulis dahulu. Jangan mengganti World, collider, pohon, terrain, input, panjang tulang, toleransi atau rute fixture untuk menghilangkan kegagalan.

Reproduksi pertama harus tanpa modifikasi. Binary tersedia sebelumnya di `/Users/ardianryan/Documents/Jalasmara/.runtime/godot/Godot.app/Contents/MacOS/Godot`; periksa versi4.7.2 dan ketersediaannya, jangan mengunduh engine baru diam-diam.

```sh
# Hanya dari lab gait, slot engine eksklusif, path output baru setiap run.
GODOT_BIN=/Users/ardianryan/Documents/Jalasmara/.runtime/godot/Godot.app/Contents/MacOS/Godot
NALA_LOWER_OUTPUT="$PWD/artifacts/godot/day01-unit-UNIQUE" \
  "$GODOT_BIN" --headless --path client-godot \
  --script ../scripts/tests/nala-stair-view-envelope.gd
NALA_LOWER_OUTPUT="$PWD/artifacts/godot/day01-first7-UNIQUE" \
NALA_TERRAIN_CASES=7 "$GODOT_BIN" --headless --path client-godot \
  --script ../scripts/tests/nala-production-terrain.gd
```

Ganti `UNIQUE` dengan run-id baru. Bungkus proses dengan timeout subprocess15s unit/30s FIRST7 dan simpan stdout/stderr utuh. Jangan mengandalkan utilitas `timeout` yang mungkin tidak tersedia di macOS. Periksa `SCRIPT ERROR`, `ERROR`, completion flags, fixture JSON, dan checker; exit0 saja bukan PASS.

### Masalah yang harus dijelaskan

FIRST7 sebelumnya selesai enam kasus, lalu ridge UP drop kaki kiri8,841755>8. Gate menahan original EAST, body NW; carried-resume tidak eligible, jatuh ke legacy22,75, LEFT144 terlambat. RIGHT exit belum mendarat ketika kaki kiri tidak menjangkau lagi. View recovery juga belum lolos. Model harus memuat mask asli yang benar-benar ditahan, correction/pivot C, plane Q, kedua kaki, root/body terhadap waktu, jadwal kontak, dan target `_safe` yang sebenarnya.

Pohon `hub_margin_tree_10` tidak boleh dihapus: model third-step sebelumnya salah karena41/62 sudut kaki bertabrakan. Tangga memakai `ground_point`/inverse tread bersama; bukan proyeksi XY sembarang. Catat support actual versus continuous ramp tanpa mencampurkannya.

Kontrak yang tidak boleh dilonggarkan: panjang tungkai asli, drop maksimum8 source-pixel, ankle-rate `5 × accepted displacement + 0.003`, original opaque corners/sole markers, validasi Q/C finite, collision dan validasi kedua kaki. Steady32/lead16/start10/turn20 serta batas facing yang ada bukan knob agar fixture lulus. Jangan force-facing, memperlebar eligibility begitu saja, mengubah stride dunia lewat gambar, atau menyembunyikan intermediate contact yang belum divalidasi. Perubahan algoritme yang dibutuhkan harus membuktikan kontrak yang sama, bukan menurunkan standar.

### Gerbang penerimaan berurutan

1. Reproduksi FAIL lama dan unit PASS lama pada source yang dipin.
2. CPU model meniru angka kegagalan dan menghasilkan prediksi kandidat; review peer/asumsi tertulis. Satu perubahan sempit per commit.
3. Unit kandidat dan FIRST7 source sama, tanpa guard/rute/fixture dilonggarkan.
4. Full16 empat connector × naik/turun × normal/reduced. Semua kasus benar-benar selesai; checker kontak harus lulus, bukan hanya gerak berhenti sebelum titik sulit.
5. Fresh flat32, raw daily/explorer, low analog, stop/start, turn/reverse180°, held-view recovery, pause/resume. Jangan mewarisi hasil source lama sebagai hasil kandidat.
6. Dua native sequence **bergerak**, daily desa dan explorer hutan, kamera/skala gameplay; periksa telapak, slip, lutut, torso/lengan, gear dan occlusion. Still image tidak cukup. Rekam klip pendek ignored serta pilihan frame kecil.
7. Ukur biaya modul dan regresi; integrator port patch terpilih ke day01 dengan default tetapOFF dahulu. Periksa diff dependency lengkap, ulang tes gabungan dan browser sebelum mempertimbangkan defaultON lokal.

Jika satu gate gagal, gate berikutnya belum diterima. Prototype boleh tersimpan sebagai eksperimen; jangan memasangnya ke produksi demi menunjukkan progres. Audio contact consumer baru dihubungkan setelah event kontak final tervalidasi dan idempotent; bukan memutar ulang raw trace yang bisa dibatalkan.

## 6. Kartu C: upper, outfit dan Imagen

Scope awal hanya male_nusantara daily/explorer. Ada6 loop offline, explorer SOUTH baru2endpoint,9pasangan belum diauthor; **0 diterima sebagai upper runtime baru**. Mulai dari explorer SOUTH: review41fill/duaendpoint dan tentukan depth/occlusion kontinu sebelum membuat8sample. Setelah paket ini selesai, pilih **satu** pasangan belum dibuat dari tabel progres, lakukan inventaris8WALK/IDLE sendiri → ownership → duaendpoint → loop → review. Jangan membuat sembilan arah sekaligus.

File baru milik day01: `tools/player-gait/gemini-day01/`, `assets/source-2d/gemini-day01/`, bukti ignored `artifacts/player-gait/gemini-day01/<run-id>/`. Tool upper yang sudah ada dibaca dahulu; jika perlu perubahan, lakukan commit terpisah dengan regresi pendahulunya. Jangan mengganti PNG produksi existing pada tahap authoring.

Source-frame/authoring-phase/contact-phase harus terpisah. Jangan memilih frame0/4, parity event atau offset0,5 sebagai jam upper tanpa kontrak kontak yang sudah diterima. Landmark tangan bukan wrist/grip socket. Isi tersembunyi baru harus berlabel AUTHORED dengan prompt/donor/provenance, bukan “recovered”. Jangan memasang mesh pakaian kedua di atas baju atlas.

Imagen diizinkan untuk aset kandidat dengan [kontrak Imagen](08-gemini-day01-imagen.md). Pilih aset existing dahulu; UI Bahari dan loading parallax sudah ada. Generasi baru harus menyelesaikan kekurangan yang direkam, tidak mengganti semuanya. Gambar AI tidak membuktikan arah, anatomi, ukuran sprite, animasi maupun kecocokan kamera3D. Jangan membuat satu gambar seluruh map/bangunan lalu menempelkannya untuk mengganti terrain3D.

## 7. Kartu D: finishing UI, world dan performa independen

Setelah baseline visual dibandingkan, pilih maksimal satu paket kecil per commit:

- **UI**: perbaiki gap badge/icon/frame yang nyata di `HudSkin.gd`, `GameHud.gd`, `DialoguePresenter.gd` atau `HudMiniMap.gd`; aset existing `hud-bahari-v1` jangan dihapus. Tambahkan art v2 terpisah bila lolos. Angka, teks dan progress tetap dinamis; no fake loading, teks dibakar, tombol palsu atau panel membesar. Pertahankan HUD footprint, safe area, pointer/modal, keyboard/touch/fullscreen.
- **World**: hanya finishing visual lokal yang terbukti belum benar pada sudut kamera yang sama: alignment atap/dek/gapura/jalan atau tepi batu. Jangan menggeser rumah/collider/server floor tanpa memetakan perubahan shared dan jalur migrasinya. Jangan menambah desa/pulau/NPC baru sehari ini. Ocean batu harus bertumpu; jangan menutupi collision dengan foam. Shader/cahaya mengikuti normal dan budget, bukan hanya saturasi global.
- **Performa**: pilih hotspot berdasarkan profil/rute terukur; satu hipotesis dan perbandingan A/B source/pin/perangkat sama. Jangan memperkecil kualitas default diam-diam, mengubah speed/time/calendar, menonaktifkan sistem gameplay atau menyebut penghematan mikro CPU sebagai FPS Samsung. Loading progress tetap byte nyata dan retry tetap berfungsi.

Scope awal runtime hanya berkas milik kartu yang ditulis dalam task card. Perluasan ke `packages/shared`/API/save/migrasi tidak otomatis diizinkan oleh kata “world”; catat kebutuhan itu sebagai pekerjaan lanjutan. Bug aktual di area tersebut boleh didiagnosis read-only, tanpa mengubah data atau kontrak server pada sesi ini.

## 8. Aturan integrasi, pengujian dan operasi

- Coordinator satu-satunya penulis docs bersama dan integrator day01. Setiap worker punya task card: tujuan, input SHA, allowlist, larangan, hipotesis, tes, output, exit condition. Worker berhenti setelah menyerahkan commit; coordinator memeriksa lalu menugaskan paket berikutnya.
- Semua Godot import/headless/native/export, browser WebGL dan benchmark GPU **serial**, satu pemilik slot. Bahkan `npm run check:world` dan `npm run build` mengambil slot. Catat acquire/release dan PID; hanya terminasi proses milik run sendiri. CPU murni boleh paralel.
- Reuse dependency existing hanya setelah kompatibilitas lockfile diverifikasi. Jika install memang diperlukan, gunakan lockfile existing; jangan upgrade package/plugin/engine atau menaruh token. Node>=22.12. Jangan mengklaim tool tersedia karena pernah disebut di chat.
- Tes terarah dahulu, kemudian sebelum paket integrasi ditutup jalankan `npm run typecheck`, `npm test`, `npm run check:world`, dan `npm run build` bila runtime/aset/host berubah. Cek kebutuhan fixture Mongo replica-set dari dokumentasi/test saat ini; jika lingkungan tidak ada, catat BLOCKED dan lanjut tugas independen. Jangan `npm run seed`, `owner`, `recover-owner` atau menyentuh database owner demi tes.
- Browser memakai UUID/database fixture milik run; cleanup hanya fixture sendiri. Perlakukan token/cookie sebagai rahasia; jangan masukkan ke screenshot/log tracked. Catat source/PCK/checksum, backend render aktual, cleanup dan hasil interaksi, bukan hanya transfer aset.
- Runtime yang berubah: native dan browser harus benar-benar memperlihatkan perubahan baru; bandingkan kamera/waktu/cuaca sama. Tetap laporkan screenshot yang gagal, bukan hanya terbaik. Existing 67/18/6/3 bukan hasil commit baru.
- Tidak ada merge ke main, push remote, deploy, SSH/VPS/Docker produksi, perubahan `.env`, proxy, runner, CI/CD topology atau volume pada handoff ini. Semua hasil **commit lokal di namespace day01**. Siapkan kandidat dan laporan agar integrator berikutnya bisa meninjau tanpa meminta Gemini meneruskan pekerjaan berisiko.
- Jangan hapus cache/shared worktree/bukti gagal/aset unik. Output build milik day01 yang sudah digantikan boleh dihapus setelah verifikasi tidak dipakai serta hash/bukti unik disimpan. Catat path, byte nyata, proses, alasan dan ruang bebas; tanpa prune global/volume.
- Artefak PNG pilihan tracked maksimum8MiB tambahan per hari, tidak ada video/PCK/WASM/build/dump/dependency tracked. Turunan runtime UI target delta<=2MiB terhadap PCK baseline; jika lewat, optimalkan/pilih lebih sedikit dan laporkan, jangan menaikkan anggaran diam-diam. Ini batas tugas, bukan klaim performa.

## 9. Checkpoint dan serah terima wajib

Coordinator membuat `docs/reviews/gemini-day01-progress.md` dan `docs/reviews/gemini-day01-final.md` **di worktree day01**, bukan dokumen root/checkout lama. Update handoff/status/PRD hanya pada branch day01 bila fakta berubah; beri link ke laporan baru, jangan menghapus riwayat.

Setiap paket selesai, gagal penting, pergantian worker atau sebelum compaction, simpan:

```text
Waktu/start+elapsed:
Worktree/branch/HEAD/base:
Task ID/pemilik/allowlist:
Status: planned | running | blocked | failed | reviewed-local | integrated-local
Gejala dan hipotesis:
Delta source/aset + alasan:
Input/source/PCK SHA + provenance:
Perintah tes, exit, SCRIPT ERROR/ERROR, hasil aktual:
Bukti/path/hash; failure yang dipertahankan:
CPU/headless/native/browser/perangkat asli: mana yang benar-benar diuji:
Slot engine acquired/released/PID:
Unknown/keterbatasan:
Langkah berikutnya persis dan syarat masuk:
```

Final wajib menyebut commit penuh per paket, allowlist/diff summary, hasil tes baru versus historis, lisensi/tool/model yang benar-benar dipakai, art kandidat versus runtime versus rilis, storage delta, paket ditolak dan alasannya, serta paling banyak lima prioritas penerus. Jangan tulis PASS untuk tes yang dilewati. Jangan menyebut aplikasi dirilis atau seluruh gait selesai ketika gate masih gagal. Jika terbatas waktu, bekukan perubahan dan serahkan pekerjaan parsial yang reviewable.
