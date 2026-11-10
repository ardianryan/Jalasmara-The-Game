# Gitea utama, GitHub dan GitLab sebagai backup

Keputusan pengguna, 10 November 2026: repository dan pipeline dipusatkan di Gitea. GitHub serta GitLab tetap menerima riwayat Git, tanpa menjalankan CI. GitLab CE yang pernah dibatalkan bukan layanan yang digunakan sekarang; host `git.ppti.me` saat ini menyediakan Gitea API.

## Repository dan autentikasi

| Remote | Tujuan | Peran |
| --- | --- | --- |
| `gitea` | `https://git.ppti.me/ardianryan/Jalasmara-The-Game` | Repository privat utama, Actions, laporan dan paket delivery |
| `github` | `https://github.com/ardianryan/Jalasmara-The-Game` | Backup Git; Actions dinonaktifkan |
| `gitlab` | `https://gitlab.com/ardianryan/jalasmara-the-game` | Backup Git; CI/CD project dinonaktifkan |

`tea` lokal versi0.16.0 sudah login `gitlocal` sebagai `ardianryan`; token tetap dikelola tool, tidak ditulis ke repository. Gunakan `tea --help`/help subcommand sebelum mengasumsikan flag; `glab` terpasang tidak mempunyai flag `api --jq` pada sesi migrasi ini.

Push HTTPS besar pernah ditolak HTTP413. Git memakai SSH khusus repo, tanpa mengubah reverse proxy. URL SSH server sebenarnya: `ssh://gitea@git.ppti.me:2212/ardianryan/Jalasmara-The-Game.git`. Pada komputer ini alias `jalasmara-gitea` memilih host/port dan key khusus repository; remote lokal memakai `ssh://jalasmara-gitea/ardianryan/Jalasmara-The-Game.git`. Key privat hanya berada di `~/.ssh/jalasmara_gitea`, bukan Git atau artefak CI. Deploy key memiliki write ke repo ini saja, bukan shell server. Jangan menyalin key ke runner, worktree atau dokumen.

Login `tea` dan SSH Git adalah dua mekanisme terpisah. Di komputer baru, daftarkan public key baru atau gunakan credential manager untuk HTTPS; jangan menyalin key privat komputer lama. Alias SSH tidak otomatis tersedia di komputer lain.

## Push satu branch ke ketiga remote

```sh
npm run push:all -- work/nama-branch --dry-run
npm run push:all -- work/nama-branch
```

Tanpa nama branch, helper memakai branch aktif; detached HEAD ditolak. Helper membekukan satu SHA commit sebelum transaksi pertama, kemudian mengirim SHA yang sama ke ketiga branch remote meskipun agent membuat commit baru di tengah proses. Hanya checkpoint tersebut yang dipush. Helper tidak stage/commit WIP, mengirim cache, menghapus branch remote, mirror refs, atau force-push. Urutan: Gitea dahulu, kemudian GitHub dan GitLab. GitLab juga menerima opsi `ci.skip` sebagai perlindungan tambahan bagi konfigurasi lama.

Ini tiga transaksi Git, bukan transaksi atomik. Gitea gagal: backup tidak dilanjutkan. GitHub gagal: GitLab tetap dicoba; hasil gagal tetap membuat exit nonzero. Jangan menganggap ketiga salinan identik sebelum memeriksa hasil/SHA. Retry perintah yang sama aman untuk branch yang sudah terkirim; jangan menambahkan `--force` untuk menyembunyikan divergence.

Remote disimpan di common Git config, sehingga terlihat di seluruh linked worktree. `remote.pushDefault=gitea` membuat push biasa memilih primary saat tidak ada pengaturan branch lain. **Push biasa tidak otomatis mengirim ke tiga tempat**; gunakan helper untuk checkpoint backup. Ini bukan server-side push mirror yang menyimpan token GitHub/GitLab pada Gitea.

Untuk snapshot awal migrasi, integrator boleh menggunakan push normal `--all`/`--tags` ke tiga remote, tanpa `--mirror`, force atau delete. Branch lama yang divergen harus dilaporkan dan dipertahankan, bukan ditimpa. Helper rutin sengaja tetap satu branch agar pekerjaan experimental tidak terpublikasi tanpa sengaja.

## Pipeline Gitea

[Workflow](../.gitea/workflows/ci.yml) berjalan pada push `main`/`work/**`, pull request, dan manual dispatch. Branch harus benar-benar mempunyai file workflow; backup branch lama tidak otomatis memperoleh pipeline baru. Runner terverifikasi online bernama `gitea-runner` dengan label `ubuntu-latest`; tidak ada runner baru yang dipasang.

Satu job menjalankan urutan:

1. Install Git dan dependensi sebelum checkout. Tanpa Git, action checkout mengambil archive tanpa `.git`; run pertama gagal pada pencatatan SHA. Kegagalan tersebut dipertahankan.
2. Checkout source penuh; credential action tidak dipersist ke Git config.
3. MongoDB8 disposable dalam container job, replset `rs0`, port27018 dan alias `mongo`; Redis7.4 service terpisah. Tidak terhubung database pemain.
4. [Verifikasi](../ci/verify.sh): typecheck, tes API, host/loader/controller/performance/tooling/art, audit dependensi. Daftar dipindahkan dari GitLab, bukan dikurangi untuk migrasi.
5. [CodeQL](../ci/codeql.sh) sebelum export yang lebih mahal; error tetap menolak kandidat, tanpa mengubah rule/severity.
6. [Godot4.7.2](../ci/setup-godot.sh): tes sprite/HUD, export Web, pemeriksaan dunia dan audio; kemudian build web/API.
7. Packager memverifikasi source/PCK/part/gzip lalu menghasilkan context Docker dan manifest yang terikat SHA. Tidak memasukkan `.env`, cache, `.git` atau data pemain.
8. Laporan disimpan di Actions Gitea14hari, paket `verified-delivery`3hari agar storage terkontrol. Paket tidak dipush sebagai commit Git.

Tidak ada workflow GitHub baru. `.gitlab-ci.yml` menolak seluruh pipeline; pengaturan project GitLab juga dimatikan agar branch lama tidak menghabiskan kuota. `ci/publish-reports.sh` historis tidak dipanggil: laporan dan SARIF berada di Gitea, bukan dibuat lewat job GitLab→GitHub.

CI merujuk implementation checkout/artifact upstream melalui URL eksplisit GitHub; **eksekusinya tetap runner Gitea**, bukan GitHub Actions. Dokumen resmi: [Gitea Actions](https://docs.gitea.com/usage/actions/faq/), [runner](https://docs.gitea.com/runner/), [artefak](https://docs.gitea.com/usage/actions/artifacts/).

## Delivery dan aktivasi staging

`verified-delivery` adalah hasil continuous delivery: paket source/context/export lengkap yang lolos tahap sebelumnya, dengan manifest byte/SHA. Runner tidak mempunyai SSH key VPS atau `.env` produksi; workflow tidak mengganti aplikasi, melakukan migrasi/reseed, menghapus volume atau mengubah proxy.

Aktivasi staging tetap tahap terpisah mengikuti [operasi rilis](operations.md): periksa source/run/artifact, backup, build image, reuse hanya jika hash cocok, aktivasi app-only, health/hash/smoke dan rollback. Handoff Gemini tetap melarang deploy. Jangan menganggap keberhasilan build berarti sudah dirilis. Jika kelak aktivasi staging dipindahkan ke workflow manual Gitea, buat job terpisah dengan otorisasi deployment, kredensial terbatas, pin artefak, backup dan rollback yang nyata; jangan membuat step deploy palsu atau melewati gate.

## Pemeriksaan operasional

```sh
tea login list
tea whoami
tea actions runs list --login gitlocal --repo ardianryan/Jalasmara-The-Game
tea api repos/ardianryan/Jalasmara-The-Game/actions/runs
```

API run harus mempunyai `conclusion: success`; `status: completed` atau step yang sekadar selesai tidak membuktikan PASS. Baca log, jumlah tes, warning, artefak dan SHA source. Laporan migrasi aktual berada pada [review](reviews/gitea-ci-migration.md).

Workflow `security.yml` menyediakan diagnosis CodeQL manual tanpa mengulang export. Hasilnya tidak menggantikan pipeline penuh. Artifactv3 dapat diunduh melalui UI Actions, tetapi [REST artifact-list v1 mempunyai keterbatasan untuk v3](https://github.com/go-gitea/gitea/issues/36973). Jangan menganggap array kosong berarti upload gagal atau mengaku sudah memverifikasi isi ZIP melalui REST jika belum.
