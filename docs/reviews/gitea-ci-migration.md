# Migrasi repo dan pipeline ke Gitea

10 November 2026. Dikerjakan pada worktree `/Users/ardianryan/Documents/Jalasmara-gitea-ci`, branch `work/gitea-ci`, base `9c4af6e`. Runtime/aset game, staging, database dan worktree Gemini tidak diedit.

## Penerimaan final

**[Run6 SUCCESS](https://git.ppti.me/ardianryan/Jalasmara-The-Game/actions/runs/6)** pada source `2fb54aacb3abf8a1032b11cf133c7ab0d14dc224`, mulai12.08.00 dan selesai12.15.59WIB (479detik). Verify/typecheck/API/tooling/audit, gate CodeQL, Godot/export/67world checks/audio, web/API build, packager dan kedua upload artefak semuanya selesai dalam job yang sukses. Gate CodeQL tidak diturunkan; PASS berarti tidak ada error menurut gate, bukan klaim nol warning/notes atau audit keamanan menyeluruh.

- Context delivery118.876.160byte, SHA256 `2e353136c0505e3c1d01bba31862d8ab073276341e2bbd8268f3f2147dbed4ce`; `requiredReusedAssets: []`, sehingga tidak mengandalkan WASM dari image lama.
- Upload `verified-delivery`:2file (context+manifest),118.878.900byte raw/87.560.826byte transfer, finalized sukses. Upload `verification-reports`:75file,363.209byte raw/55.361byte transfer, finalized sukses. Ukuran transfer bukan ukuran ZIP unduhan yang sudah diverifikasi.
- Log akhir618.949byte, SHA256 `40bdf7c8718f5b1334964ac0c405509c25a0cc72a85dd768649b19a5ffa5e360`, tersimpan ignored pada `.runtime/gitea-migration/run6.log`. ZIP tidak diunduh melalui REST karena batas v3 di bawah; source/context dan hasil upload diverifikasi dari log serta conclusion API.
- Snapshot59refs lokal pada2fb54aa cocok SHA-nya di Gitea, GitHub, GitLab: missing0/different0. Satu ref tambahan GitHub dipertahankan. Record `.runtime/gitea-migration/backup-checkpoint-2fb54aa.json`. Perubahan docs penutup dipush setelahnya memakai helper checkpoint yang sama.
- Health staging sesudah konfigurasi CI tetap `{"status":"ok"}`. Tidak ada aktivasi image, perubahan data, atau hasil perangkat asli baru.

Hasil ini menerima **konfigurasi migrasi pada baseline integrasi**, bukan menerima perubahan game di branch Gemini yang baru dibackup. Eksperimen Nala dalam baseline ini tetapOFF. Bagian berikut menyimpan kronologi kegagalan dan perbaikan; status pending lama tidak mengatasi penerimaan final ini.

Setelah review diff dan run6, branch `work/overnight-integration` di-fast-forward9c4af6e→c540ad5, lalu checkpointc540ad5 sukses dikirim ke tiga remote. Gitea default branch diatur ke `work/overnight-integration`, privat/Actions tetaptrue; upstream branch integrasi mengarah ke Gitea. `main` tetap `d070a7b67b9f42986da2e4650f7c4110713ae73b`, worktree Gemini bersih pada `e4336741037a8f20c9f2d0fa2a5caf59a9ae55c7`. Tidak ada merge main atau perubahan berkas Gemini. Commit dokumentasi penutup sesudahnya memakai `[skip ci]` karena tidak mengubah konfigurasi/kode yang diuji pada2fb54aa.

## Konfigurasi yang benar-benar diterapkan

- `tea`0.16.0, login `gitlocal`, user `ardianryan`, Gitea API mengembalikan versi28.3.0. Repo privat baru [Jalasmara-The-Game](https://git.ppti.me/ardianryan/Jalasmara-The-Game) dibuat, Actions aktif.
- Runner existing `gitea-runner` id1 online, label ubuntu-latest/24.04/22.04. Tidak memasang runner atau mengubah host runner.
- Push HTTPS awal gagal413; tidak ada perubahan reverse proxy. SSH port2212 memakai deploy key write khusus repo dan alias lokal `jalasmara-gitea`. Autentikasi serta push SSH berhasil. Token tea tidak dicetak/disimpan dalam repo; credential Git HTTPS memakai credential manager OS yang telah dikonfigurasi.
- Remote `gitea` ditambahkan dan `remote.pushDefault=gitea`. GitHub/GitLab tetap. Helper push tiga remote lulus empat tes, termasuk kegagalan primary, kegagalan satu backup, skip GitLab dan dry-run tanpa force/delete.
- GitLab project88651634 `builds_access_level=disabled` dan GitHub Actions `enabled=false`, terverifikasi melalui API. Konfigurasi GitLab pada branch migrasi juga menolak pipeline.
- Commit116d32e berhasil dipush ke tiga remote; commit3c6cbc8 juga berhasil dipush ke tiga remote. Snapshot main dan integration awal sudah diterima Gitea. Kesamaan SHA final dan cakupan branch backup dicatat setelah pemeriksaan akhir.

Snapshot awal mencakup59refs lokal, seluruh push `--all`/`--tags` ke tiga remote exit0, tanpa force/mirror/delete. Verifikasi menemukan satu branch bergerak: Gemini menambah commit di antara transaksi remote. Ini bukan divergence yang ditimpa. Helper diperbaiki pada1f183d2 agar freeze satu SHA dan mengirim checkpoint sama ke semua remote; lima tes termasuk perubahan branch di tengah push lulus. Checkpoint Gemini `e4336741037a8f20c9f2d0fa2a5caf59a9ae55c7` kemudian sukses dikirim ke tiga remote. Tidak membaca hasil Gemini sebagai penerimaan game, tidak mengedit worktree-nya, dan tidak menggabungkan history game baru.

## Eksekusi pipeline

Run pertama [1](https://git.ppti.me/ardianryan/Jalasmara-The-Game/actions/runs/1), source116d32e, **FAIL**. Job node slim belum mempunyai Git ketika checkout action berjalan; action memakai source archive, sehingga pencatatan SHA gagal `not a git repository`. Mongo disposable sudah berhasil start. Bukan kegagalan tes game; tahap berikutnya belum dijalankan. Log dipertahankan di `.runtime/gitea-migration/run1.log`.

Commit3c6cbc8 memindahkan install Git sebelum checkout. [Run2](https://git.ppti.me/ardianryan/Jalasmara-The-Game/actions/runs/2) source `3c6cbc89b08d8cc1a0dd8c0385ae7f66cee5ad0e` sudah diambil runner1; saat penulisan awal, checkout/Mongo lulus dan verifikasi sedang berjalan. Ini **belum klaim pipeline PASS**; hasil final ditambahkan setelah membaca conclusion/log/artifact.

Tes lokal awal: empat tes helper push PASS, lalu lima setelah regresi concurrent checkpoint ditambahkan; `bash -n` dua script PASS; YAML syntax PASS; `git diff --check` PASS. Perbandingan independen terhadap `.gitlab-ci.yml` base9c4af6e membuktikan seluruh37command verify lama dipertahankan dalam `ci/verify.sh`. Tidak mengulang gameplay lokal yang tidak berubah. Tahap Godot/build/CodeQL/packager tetap menjadi gate sebelum delivery. Run3 pada1f183d2 dijadwalkan untuk kandidat helper final; hasil final dicatat sesudah selesai.

Run2 kemudian **FAIL pada gate CodeQL: satu error**, sesudah verify/Godot/build. Tidak menurunkan gate; commitf56747a menambahkan rule/message/location pada log penolakan. Run3 superseded dihentikan dan API akhirnya menegaskan `conclusion: cancelled`, bukan PASS. Run4 menjalankan kandidat dengan log terperinci. Workflow manual `security.yml` pada42f69b0 menghasilkan run5 khusus CodeQL untuk diagnosis tanpa export ulang; bukan pengganti pipeline penuh.

Upload laporan run2 pada artifactv3 melaporkan75file/363.627byte raw/55.219byte transfer berhasil. Namun RESTv1 artifact-list mengembalikan daftar kosong. Ini sesuai [batas API artifactv3 yang dilaporkan upstream](https://github.com/go-gitea/gitea/issues/36973); jangan menyebut artefak hilang atau REST download terverifikasi dari daftar kosong. UI Actions adalah jalur unduh v3, sedangkan log API dipakai untuk mengikat hasil/source. Detail gate CodeQL diperoleh dari log terperinci, bukan mengarang isi SARIF yang belum diunduh.

Run5 mengungkap `js/bad-code-sanitization` di `scripts/performance/recorder-provenance-gate.test.mjs:34`: helper fixture membentuk sumber JavaScript melalui interpolasi `JSON.stringify`. Pembacaan source memperlihatkan hasilnya hanya diteruskan ke parser/assertion, tidak dieksekusi atau dimasukkan ke HTML; ini bukan bukti eksploit runtime produksi. Perubahan2fb54aa menghapus konstruksi dinamis yang tidak diperlukan, memakai fixture source statis dan tetap mempertahankan penolakan SHA/byte/identity yang salah. Delapan tes terarah (tiga provenance+lima push) lulus. Tidak mengubah parser produksi, query CodeQL, pengecualian path atau severity.

Run4 yang memakai fixture lama dihentikan sebagai superseded; run6 menguji2fb54aa dengan gate CodeQL diletakkan sebelum export untuk fail-fast. Hasil run6 harus dibaca sebelum klaim penerimaan final; run2/5 tetap FAIL dan3/4 cancellation bukan PASS.

## Batas delivery dan handoff

Gitea menghasilkan laporan14hari dan paket delivery3hari, bukan mengaktifkan staging otomatis. Key server produksi tidak diberikan kepada runner. Aktivasi tetap membutuhkan pin/backup/health/rollback sesuai operasi; tidak ada deployment atau reseed dalam migrasi ini.

[Aturan operasi baru](../operations-gitea.md) dan [addendum Gemini](../plans/08c-gitea-ci-addendum.md) mencatat keputusan pengguna terbaru. Gemini tetap pada worktree sendiri; addendum dapat dibaca secara read-only dari worktree CI sampai pemilik branch mengintegrasikan konfigurasi baru.
