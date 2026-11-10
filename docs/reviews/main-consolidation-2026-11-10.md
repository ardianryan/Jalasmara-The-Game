# Konsolidasi `main` dan pembersihan kandidat gait

Keputusan pengguna: Codex mengambil alih integrasi, menggabungkan pekerjaan yang telah diterima, dan membersihkan branch Claude agar pengembangan berikutnya kembali rapi. Paket ini **tidak mengaktifkan gait eksperimental dan tidak mengubah staging**.

## Hasil Git

- `main` lokal awal `d070a7b67b9f42986da2e4650f7c4110713ae73b` bersih dan merupakan ancestor `work/overnight-integration`. Fast-forward `--ff-only` ke `59e916bff3beeeb6e5a5b78bcc6f72bdd034c385` berhasil tanpa konflik. Source itu mengandung paket integrasi dan CI Gitea yang sudah diuji pada `2fb54aacb3abf8a1032b11cf133c7ab0d14dc224`; setelah commit uji tersebut sampai `59e916b`, yang berubah hanya dokumentasi/notice lisensi.
- `main` pada Gitea, GitHub, dan GitLab dipush melalui `npm run push:all -- main` setelah dry-run. Ketiga remote menunjuk SHA `59e916b`. GitHub Actions dan GitLab CI tetap nonaktif; Gitea adalah CI utama. Gitea default tetap `main`.
- Riwayat 266 commit yang masuk fast-forward mempunyai satu identitas author Git, `ardianryan`. Tidak ada commit dari `work/claude-gait-integration` yang digabung ke `main`.
- Branch Claude `3e758d2016607fc164082ebd7f05a32b92d03773` dihapus dari worktree lokal, branch lokal, dan ketiga remote. Sebelum itu, patch binary Git dan 11 fixture `.gd` yang belum tracked disimpan lokal pada `.runtime/rejected-branches/claude-gait-3e758d2.zip` (72.657 byte, SHA-256 `16baf8ad84c3dc728e7725fd342b902aa76c3983e9f794538e71c0a0c647141c`). Arsip terverifikasi ZIP, diabaikan Git, dan **bukan** aset rilis. Cache Godot 62 MiB worktree yang digantikan ikut hilang. Bukti kegagalan terstruktur tetap dalam laporan/artefak lab Gemini; dua output Claude yang kosong tidak dipertahankan.
- Ada proses Godot PID 61099 yatim (PPID 1, berjalan sekitar 6 menit) dengan cwd worktree Claude dan dua file output 0 byte. Setelah pengguna menyatakan semua agen berhenti, proses itu dihentikan dengan TERM dan diverifikasi keluar sebelum worktree dihapus. Proses milik paket lain tidak disentuh.

## Mengapa kode Claude tidak masuk

Branch tersebut menambah enam modul gait yang belum dipakai runtime produksi. Laporannya sendiri mencatat `flat32` gagal, full16 gagal pada satu dari tiga run, dan checker kontak hanya 9/16 kasus lulus dengan 7 kasus incomplete. Fixture gait yang dipakai juga tidak masuk commit branch; checkout bersih tidak dapat mengulang hasilnya. Perbaikan inner-reach menambah lift pinggul dengan batas yang berasal dari batas *drop* kaki, tetapi belum mempunyai bukti gabungan bahwa dua kaki dan kontak tetap sah. Karena itu pilot tetap **OFF**. Ini penolakan kandidat saat ini, bukan kesimpulan bahwa ide gait tidak bisa diperbaiki.

## CI dan staging

- Gitea run 6 pada `2fb54aa` **SUCCESS**: verify, CodeQL, Godot/67 world, build, delivery upload. Run 7 pada SHA `59e916b` **FAIL** karena proses Godot runner `spawnSync ... ETIMEDOUT` saat beberapa pekerjaan lain berjalan; tidak ada bukti perubahan source gameplay sebagai penyebab. [Run 10](https://git.ppti.me/ardianryan/Jalasmara-The-Game/actions/runs/10) pada SHA `59e916b` **completed/success**: verify, CodeQL, Godot, build, dan upload dua artefak selesai. Log packager mematok `context.tar` 118.876.160 byte, SHA-256 `73beba3ab376c7f21214ec61c3ed5b6127a9015062983c64f81df3d384768bd7`, `requiredReusedAssets: []`. Upload delivery selesai; ZIP delivery belum diunduh dan diperiksa secara terpisah. Run 9 Claude juga bertanda success, tetapi tidak membuktikan gait karena fixture belum tracked.
- HTTPS staging `GET /api/health` mengembalikan `{"status":"ok"}` sebelum dan sesudah konsolidasi. `HEAD /game/pck/9a1ca274b88cf65e819f1c117da2ede7992420e2128b454ef6bc3cf7f19cbb1a/0` mengembalikan HTTP/2 200, `Content-Length: 1048576`, `X-Pck-Length: 64500848`, sesuai PCK export5 yang tercatat. Ini pemeriksaan kesehatan/identitas aset, **bukan** smoke perjalanan game atau rilis baru. Source staging tetap source host `bf55342d82b439119f48aee3a5a7189a33b26357` dan export Godot `72b173c5f04d986e365fa34fd19daea62fb65125` sampai ada aktivasi terpisah.
- Aktivasi staging dari `main` kini mempunyai CI sukses pada SHA yang dipin, tetapi masih memerlukan unduhan/verifikasi artefak delivery, backup/rollback sesuai `docs/operations.md`, lalu smoke publik dengan fixture sendiri. Tidak ada aktivasi pada paket konsolidasi ini; pemeriksaan staging di atas masih mengukur rilis export5. Jangan memakai hasil CI run 9 branch Claude sebagai persetujuan gait; fixture-nya tidak ikut runner.

## Langkah berikutnya

1. Untuk gait, mulai kandidat baru dari `main`; reproduksi kegagalan dengan fixture yang **tracked** terlebih dahulu. Tolak klaim full16 bila checker `complete16CasesVerified` bukan true, kemudian lanjut flat32/native bergerak/browser. Jangan menghidupkan pilot dari arsip Claude.
2. Siapkan aktivasi staging dari delivery run 10 hanya sesudah manifest/context diverifikasi dan backup/rollback siap; setelah aktivasi, lakukan smoke publik dengan fixture sendiri. Pengujian Windows/Samsung S23 fisik tetap membutuhkan build berpinned dan bantuan pengguna.
3. HUD malam dan penilaian visual moodboard masih terpisah; jangan menyebut kualitas akhir selesai dari keberhasilan CI.

Tool yang digunakan: Git, helper `scripts/push-remotes.mjs`, `tea` Gitea, Python standar, `curl`, `lsof`, dan `ps`; tidak ada generator gambar, aset baru, perubahan lisensi, atau deploy dalam paket ini. Arsip patch adalah bukti teknis lokal, bukan kontribusi runtime.
