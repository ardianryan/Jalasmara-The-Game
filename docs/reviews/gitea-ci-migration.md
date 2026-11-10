# Migrasi repo dan pipeline ke Gitea

10 November 2026. Dikerjakan pada worktree `/Users/ardianryan/Documents/Jalasmara-gitea-ci`, branch `work/gitea-ci`, base `9c4af6e`. Runtime/aset game, staging, database dan worktree Gemini tidak diedit.

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

## Batas delivery dan handoff

Gitea menghasilkan laporan14hari dan paket delivery3hari, bukan mengaktifkan staging otomatis. Key server produksi tidak diberikan kepada runner. Aktivasi tetap membutuhkan pin/backup/health/rollback sesuai operasi; tidak ada deployment atau reseed dalam migrasi ini.

[Aturan operasi baru](../operations-gitea.md) dan [addendum Gemini](../plans/08c-gitea-ci-addendum.md) mencatat keputusan pengguna terbaru. Gemini tetap pada worktree sendiri; addendum dapat dibaca secara read-only dari worktree CI sampai pemilik branch mengintegrasikan konfigurasi baru.
