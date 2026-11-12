# Addendum Gemini: primary Gitea dan backup tiga remote

> Historical day01 addendum. The delegation is closed and the active CI home is
> [GitHub Actions](../operations-github.md). Do not apply its Gitea-only push/CI
> instructions to current work.

Keputusan pengguna setelah handoff day01: Gitea menjadi pusat repo/CI/CD; GitHub dan GitLab tetap menerima backup Git. Addendum ini mengatasi larangan push menyeluruh pada dokumen day01 **hanya untuk checkpoint branch milik Gemini**. Larangan merge/main/deploy, ownership file, batas audit dan gate pengujian tetap berlaku.

1. Tetap bekerja di worktree day01 sendiri. Jangan mengedit worktree CI integrator atau memindahkan runtime game agar memperoleh pipeline.
2. Sebelum push, periksa `pwd`, branch, HEAD, status, daftar file commit, secret/artifact scope, dan tes paket. Hanya namespace `work/gemini-day01*` milik tugas yang boleh dipush oleh Gemini. Jangan push main atau branch agent lain.
3. Jika helper tersedia pada branch sendiri, gunakan `npm run push:all -- <branch>`. Jika belum, helper integrator dapat dibaca/dijalankan tanpa menyuntingnya:

```sh
# Jalankan dengan CWD worktree Gemini, bukan worktree CI.
node /Users/ardianryan/Documents/Jalasmara-gitea-ci/scripts/push-remotes.mjs \
  work/gemini-day01 --dry-run
node /Users/ardianryan/Documents/Jalasmara-gitea-ci/scripts/push-remotes.mjs \
  work/gemini-day01
```

4. Git config remote bersama sudah mengenal `gitea`, `github`, `gitlab`. Primary Gitea memakai SSH alias khusus repo. Jangan membaca/menyalin private key atau token. Jika auth gagal, catat remote/exit tanpa secret dan lanjut pekerjaan lokal.
5. Jangan membuat `.github/workflows`, menghidupkan CI GitLab, atau mengubah runner/proxy/secret. Workflow dan laporan CI hanya di Gitea. Branch lama tanpa `.gitea/workflows/ci.yml` belum otomatis diuji; jangan menyebut backup push sebagai CI PASS.
6. Integrasi konfigurasi CI baru ke branch Gemini dilakukan oleh pemilik branch setelah memeriksa commit dan WIP, bukan dengan force reset atau merge seluruh riwayat lain. Worker audit tetap hanya menulis allowlist audit; coordinator yang melakukan integrasi konfigurasi.
7. Push backup bukan penerimaan art/physics atau izin deploy. Prototype gagal tetap OFF. Simpan SHA dan hasil tiga remote pada progress log; divergence tidak boleh diatasi dengan force push.

Lihat [operasi Gitea](../operations-gitea.md) dan [hasil migrasi](../reviews/gitea-ci-migration.md). Repo utama: `https://git.ppti.me/ardianryan/Jalasmara-The-Game`.
