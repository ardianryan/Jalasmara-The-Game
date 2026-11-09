# Runbook staging berbasis image

`docs/operations.md` diperbarui dari source yang sama dengan integration `0e44618`; tidak menyalin checkout/asset/cache root ke worktree ini. Bagian topologi, OIDC, akun dan backup yang tidak terkait dipertahankan. Perubahan mengganti alur rutin `compose build/up/seed` dan rollback checkout dengan context terverifikasi, build image bertag unik, aktivasi `current` dan recreate app saja.

Runbook membedakan source Docker dari declared export source, memasukkan hash context dan seluruh gameAssets/reuse WASM, backup/uji restore terpisah, validasi image/PCK serta smoke publik, `.env` checksum tanpa menyuntingnya, dan batas retensi image aktif+satu rollback. Kegagalan operator sebelumnya (curl host tidak tersedia dan exec-T mengonsumsi stdin) ditangani dengan health Node container dan redirect stdin. Tidak ada langkah CE, reset data, proxy, atau checkout VPS baru.

Pemeriksaan CPU: seluruh blok shell dokumentasi lolos `bash -n`, dua Python verifier tertanam lolos parse AST, `git diff --check` bersih. Tidak menjalankan perintah deploy, SSH, Docker build, Godot atau browser. Ini dokumentasi prosedur, bukan bukti aktivasi image baru.

CI integration sudah mendaftarkan lima tes packager. Usulan terpisah `.runtime/player-gait-cpu-ci.patch` menambahkan hanya dua perintah unittest CPU ke job verify: 15 tes urutan kontak dan2 tes metrik ramp analitik. Keduanya dijalankan ulang **17/17 PASS**. Patch tidak diterapkan pada `.gitlab-ci.yml` karena root pemilik file; tidak menambahkan engine, artifact aktual atau penerimaan gait palsu ke job CPU.
