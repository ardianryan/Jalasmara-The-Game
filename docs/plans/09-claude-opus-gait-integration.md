# Handoff Claude Opus 5.5: verifikasi dan integrasi gait Nala

**Status 10 November 2026: ditutup, jangan dijalankan ulang.** Kandidat Claude tidak diterima dan branch-nya telah dihapus atas arahan pengguna. Lihat [laporan konsolidasi](../reviews/main-consolidation-2026-11-10.md) untuk bukti kegagalan dan langkah baru yang dimulai dari `main`. Isi di bawah dipertahankan sebagai catatan instruksi historis.

Dokumen ini adalah instruksi kerja siap pakai. Tujuannya menghasilkan kandidat gait Nala yang dapat ditinjau dalam game, bukan menganggap lulusnya fixture sebagai bukti jalan alami. Baca `AGENTS.md`, `docs/agent-handoff.md`, `docs/PRD.md`, `docs/art-direction-comfy.md`, dan laporan yang disebut di bawah sebelum mengubah source.

## Keadaan awal dan hasil yang diminta

- Basis integrasi: `/Users/ardianryan/Documents/Jalasmara-overnight-integration`, branch `work/overnight-integration`, pin `fb50edff5ceaae09b39141e1daa3123bd03d737f`. Periksa ulang HEAD/status sebelum membuat worktree; bila sudah bergerak, catat SHA aktual dan diff terhadap pin.
- Kandidat Gemini: `/Users/ardianryan/Documents/Jalasmara-gemini-day01-gait`, branch `work/gemini-day01-gait`, pin `ab5574bc6e0c76a50e4d3db6b4bbd26f9ebaab7a`. Laporan `/Users/ardianryan/Documents/Jalasmara-gemini-day01/docs/reviews/gemini-day01-final.md` menyatakan 16 kasus medan/814 sampel lulus. Itu klaim kandidat, belum hasil review integrator. Commit runtime kandidat `010832a` dan `ab5574b` berdiri di atas sejarah eksperimen `ddb409b`; jangan merge seluruh cabang.
- Rilis staging tetap export5: source host `bf55342d82b439119f48aee3a5a7189a33b26357`, source Godot `72b173c5f04d986e365fa34fd19daea62fb65125`, PCK `9a1ca274b88cf65e819f1c117da2ede7992420e2128b454ef6bc3cf7f19cbb1a`. Pilot kaki fisik belum aktif. CI Gitea run 6 lulus pada source `2fb54aacb3abf8a1032b11cf133c7ab0d14dc224`, **sebelum** hasil Gemini.
- Hasil akhir: branch kandidat sendiri, diff minimal yang ditinjau, bukti tes baru pada source gabungan yang sama, dua rekaman bergerak skala gameplay, laporan status jujur, dan daftar gate yang masih gagal. Jika gate gagal, serahkan diagnosis yang dapat direproduksi dan pertahankan pilot OFF.

## Worktree, kepemilikan, dan batas perubahan

1. Dari repository yang bersih, verifikasi `git worktree list`, `git status --short`, `git rev-parse HEAD`, dan keberadaan path/branch. Bila belum ada, buat `/Users/ardianryan/Documents/Jalasmara-claude-gait` dengan branch `work/claude-gait-integration` dari pin integrasi. Jangan memakai `--force`, reset, rebase, amend, atau mengubah worktree milik agen lain. Jika nama sudah dipakai, pilih suffix baru di namespace `work/claude-gait-*` dan catat nama sebenarnya.
2. Satu penulis untuk source gait kandidat: `client-godot/scripts/NalaFootPlant.gd`, `NalaLowerBody3D.gd`, `NalaStairSupportCurve.gd`, beserta fixture gait yang memang diperlukan. Perluasan ke World, terrain, collider, API, save, atau input membutuhkan alasan teknis tertulis dan commit tersendiri; jangan memakainya sebagai jalan pintas agar tes lulus. Dokumen milik Claude: `docs/reviews/claude-gait-integration.md` dan ringkasan baru di atas `docs/agent-handoff.md` **hanya pada branch Claude**.
3. Semua worktree Gemini, `main`, dan branch integrasi asal dibaca saja. Jangan stage symlink `node_modules`, `.runtime`, PCK/WASM/build, dump, video mentah, atau rahasia. Jangan deploy, mengubah default branch, menyalakan CI GitHub/GitLab, atau push ke `main`.
4. Godot import/headless/native/export, browser WebGL, dan benchmark GPU berjalan serial lintas worktree. Periksa siapa pemilik slot, umumkan acquire/release, dan hentikan hanya proses yang dibuat sendiri. Tes CPU murni boleh berjalan sejajar.

## Urutan kerja dan gerbang penerimaan

### A. Audit sumber sebelum port

- Baca `docs/reviews/overnight-0800-close.md`, `docs/reviews/overnight-nala-upper-exit-831cf9b.md`, `docs/plans/08-gemini-day01-handoff.md`, kode tiga modul di lab Gemini, dan fixture `scripts/tests/nala-production-terrain.gd`, `nala-stair-view-envelope.gd`, `nala-stair-carried-resume.gd`. Buat peta dependensi per commit; tunjukkan apa yang benar-benar dibutuhkan dari riwayat eksperimen dan apa yang pernah ditolak.
- Tinjau secara matematis perubahan toleransi vertikal 1 piksel sumber, sertifikasi held-mask resume, airborne descent, pembatas jarak landing 21 unit, plane touchdown, dan cutoff arah 0,70/0,85. Pastikan keduanya berlaku pada mask opaque/offset pergelangan asli, dua kaki, inverse tread, dan target `_safe`. Pertahankan pohon `hub_margin_tree_10`.
- Kontrak tetap: panjang tungkai asli; drop maksimum 8 piksel sumber; ankle rate `5 × accepted displacement + 0.003`; corner, sole marker, Q/C finite, collision dan urutan tread. Jangan mengganti gerak dengan gambar kaki lebih panjang, mirror seluruh karakter, force-facing, atau melonggarkan guard/route fixture.

### B. Verifikasi kandidat Gemini secara mandiri

- Bekukan SHA lab `ab5574b` dan jalankan unit carried resume, unit view envelope, FIRST7, lalu full 16 medan pada **SHA yang sama**, dengan path output baru untuk setiap run. Binary lokal: `/Users/ardianryan/Documents/Jalasmara/.runtime/godot/Godot.app/Contents/MacOS/Godot`; verifikasi versinya 4.7.2. Gunakan `GODOT_BIN` bila lokasi berubah. Contoh dari CWD lab, setelah mendapat slot engine:

```sh
NALA_LOWER_OUTPUT="$PWD/artifacts/godot/claude-unit-UNIQUE" \
  "$GODOT_BIN" --headless --path client-godot \
  --script ../scripts/tests/nala-stair-view-envelope.gd
NALA_LOWER_OUTPUT="$PWD/artifacts/godot/claude-first7-UNIQUE" \
  NALA_TERRAIN_CASES=7 "$GODOT_BIN" --headless --path client-godot \
  --script ../scripts/tests/nala-production-terrain.gd
NALA_LOWER_OUTPUT="$PWD/artifacts/godot/claude-full16-UNIQUE" \
  NALA_TERRAIN_CASES=16 "$GODOT_BIN" --headless --path client-godot \
  --script ../scripts/tests/nala-production-terrain.gd
```

Ganti `UNIQUE` dengan run ID yang belum ada. Jalankan `nala-stair-carried-resume.gd` dengan pola Godot yang sama. Periksa stdout/stderr, JSON completion/rejection, `SCRIPT ERROR`/`ERROR`, dan `python3 tools/player-gait/check_stair_contacts.py --help` sebelum memanggil checker sesuai argumennya. Exit 0 sendiri bukan PASS. Simpan baseline gagal terdahulu sebagai bukti historis, bukan hasil terbaru.

- Lanjutkan pada source yang sama: 32 kasus datar baru, raw daily dan explorer, analog lambat, stop/start, turn/reverse 180°, held-view recovery, pause/resume, serta dua arah naik/turun. Jangan mewarisi PASS dari commit sebelumnya. Jika fixture belum mencakup skenario tertentu, tambahkan tes bermakna pada branch Claude tanpa mengubah syarat tes lama. Kegagalan satu gerbang menghentikan klaim gerbang berikutnya.

### C. Port terkurasi ke branch Claude

- Hanya setelah B dapat ditinjau, pindahkan perubahan yang diperlukan dari lab ke branch Claude dalam commit kecil dengan asal SHA tertulis. Jangan cherry-pick seluruh `work/overnight-character` atau seluruh `work/gemini-day01-gait`. Periksa tiap commit `git show --stat`, diff, dan dependensinya sebelum port; adaptasi manual boleh bila lebih kecil dan terbukti setara.
- Awalnya pertahankan pilot OFF. Jalankan ulang unit/FIRST7/full16/flat/raw di branch hasil port; hasil lab tidak menjadi hasil branch baru. Cocokkan SHA fixture, atlas, World, dan geometri terrain agar tes benar-benar mengukur kondisi produksi yang sama.
- Jalankan `npm run typecheck`, `npm test`, `npm run check:world`, dan `npm run build` pada source gabungan bila kode runtime berubah. Periksa log Godot, bukan hanya exit code. Bila infrastruktur fixture Mongo/Redis belum tersedia, catat tepat tes yang blocked; jangan memakai akun owner, reseed, atau menghapus volume.

### D. Bukti gerak nyata dan keputusan integrasi

- Uji dua sekuens **bergerak** pada kamera dan skala gameplay: pakaian harian di desa serta explorer di hutan. Masing-masing harus mencakup jalan datar, naik dan turun tangga/ramp, berhenti dan lanjut, serta belok. Periksa telapak menapak tanpa slide, kaki tidak saling menggunting, anatomi lutut/badan, lengan kontra-kaki, facing, occlusion, tas dan alat modular. Rekaman asli disimpan di output ignored; pilih frame/contact sheet kecil untuk galeri dengan provenance dan lisensi yang benar.
- Uji browser lokal dengan fixture UUID milik run, simpan source/PCK hash, backend WebGL, hasil interaksi, error console/API, dan bukti cleanup. Bandingkan biaya CPU/modul dengan baseline pada mesin/rute sama. Jangan menyebut SwiftShader/Metal sebagai FPS Samsung S23 atau Windows.
- Pilot boleh diusulkan ON **hanya jika** semua guard fisik, regresi gabungan, native bergerak, dan browser lulus serta kualitas visual ditinjau. Jika belum, biarkan OFF dan nyatakan gate tersisa. Producer suara kontak dan loop upper tidak otomatis dihubungkan oleh paket ini; catat interface/event yang diperlukan jika kontak final sudah stabil.

## Laporan, push, dan kriteria berhenti

Laporan wajib memuat source SHA penuh, commit asal/hasil port, daftar file, hasil PASS/FAIL/BLOCKED tiap gerbang, jumlah kasus dan sampel sebenarnya, output proof/hash, perbandingan visual, tool/versi/lisensi yang sungguh dipakai, serta keterbatasan. Bedakan CPU, headless, native, browser, dan perangkat fisik. Perbarui handoff pada branch Claude tanpa menimpa riwayat. Tulis perintah reproduksi pertama bagi penerus. Jika bukti belum cukup, berhenti dengan kandidat terisolasi dan diagnosis konkret; jangan menyebut natural walking selesai.

Commit branch Claude setelah laporan dapat ditinjau. Gunakan `npm run push:all -- work/claude-gait-integration --dry-run` lalu `npm run push:all -- work/claude-gait-integration` dari branch sendiri untuk Gitea dan backup GitHub/GitLab; bila memakai suffix, ganti nama branch pada perintah. Push bukan penerimaan CI. CI Gitea pada SHA hasil port harus diperiksa `conclusion: success`, bukan sekadar `completed`. Integrator berikutnya memutuskan merge ke `main` dan rilis setelah review; Claude tidak melakukan keduanya dalam tugas ini.

## Pekerjaan lain yang tetap terbuka

HUD malam/dialog/buku/kuis dan kesesuaian moodboard memerlukan penerimaan visual pada ukuran game; upper delapan arah/pakaian lain dan kopling fase lengan-kontak masih offline; performa Windows/Samsung S23 fisik belum diukur. Kerjakan di branch/pemilik berkas lain setelah paket gait, agar hasil Claude tidak tercampur dengan perluasan UI/dunia.
