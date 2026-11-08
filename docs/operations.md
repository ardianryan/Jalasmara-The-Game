# Operasi Jalasmara

## Topologi staging

Aplikasi berada di VPS alias SSH `dev-jalasmara`, direktori `/opt/jalasmara`. Upstream game adalah **HTTP `10.1.0.8:3000`**, dengan URL publik **`https://staging-jalasmara.ardianryan.com`**. Pengguna mengatur reverse proxy dan sertifikat melalui aaPanel pada server terpisah `moodle-server` (`10.1.0.18`). Jangan memasang proxy tambahan atau mengubah server tersebut lewat deployment aplikasi.

Proxy harus mempertahankan `Host`, meneruskan `X-Forwarded-Proto: https`, dan menambahkan alamat klien pada `X-Forwarded-For`. Tetapkan `APP_ORIGIN=https://staging-jalasmara.ardianryan.com` dan `TRUST_PROXY=10.1.0.18` pada `.env` produksi. Jangan gunakan `trustProxy=true` tanpa batas alamat. Pastikan proxy tidak meng-cache `/api/` dan menyediakan MIME `application/wasm` untuk WebAssembly.

`APP_BIND=10.1.0.8` serta `APP_PORT=3000` memublikasikan upstream pada jaringan privat. `scripts/proxy-firewall.sh` membatasi port Docker ke alamat proxy dan host aplikasi; jangan mengandalkan UFW INPUT saja untuk port Docker. Unit `deploy/jalasmara-firewall.service` tersedia untuk persistensi. Verifikasi aturan aktual sebelum mengaktifkannya. Tidak ada port database yang diterbitkan pada compose produksi.

## Build dan pembaruan

Build membutuhkan ekspor Godot sebelum Docker. Export engine dan template harus sama-sama 4.7.2.

```sh
npm ci
npm run build:game
docker compose build app
docker compose up -d
docker compose exec -T app node apps/api/dist/apps/api/src/cli.js seed
curl --fail http://10.1.0.8:3000/api/health
```

Jalankan dari checkout yang akan dirilis. `APP_VERSION` dapat diisi commit singkat agar image rilis sebelumnya tetap tersedia. Jangan menghapus volume saat pembaruan. `docker compose down -v` menghapus database.

Untuk membuat owner, jalankan dari terminal pengguna, tanpa `-T`:

```sh
ssh -t dev-jalasmara 'cd /opt/jalasmara && docker compose exec app node apps/api/dist/apps/api/src/cli.js owner'
```

Isi nama **Ardian**, email yang dipilih pemilik, dan password minimal 12 karakter. Email belum ditetapkan dalam kode. Password tidak di-echo oleh perintah. Pemulihan menggunakan perintah `recover-owner` melalui terminal yang sama dan mencabut sesi lama.

Setelah login, owner membuat undangan dari panel. Tautan undangan berlaku 72 jam dan reset satu jam. Salin dan bagikan secara privat. Tidak ada SMTP pada demo.

## Verifikasi dan rollback

```sh
docker compose ps
docker compose logs --tail=100 app
curl --fail https://staging-jalasmara.ardianryan.com/api/health
```

Periksa login lokal, Godot `/game/index.html`, undangan, perubahan admin, dan perjalanan menyelam–kedai melalui URL publik. Pemeriksaan lokal tidak membuktikan konfigurasi HTTPS proxy. Catat browser dan apakah pengujian memakai perangkat nyata atau emulasi.

Rollback: gunakan checkout dan `APP_VERSION` rilis sebelumnya, lalu `docker compose up -d --no-build app`. Pertahankan volume database. Jika perubahan membutuhkan migrasi tidak kompatibel, pulihkan backup ke lingkungan terpisah sebelum memutuskan restore produksi. Seed tidak boleh mengganti konten yang sudah diubah pengelola tanpa pemeriksaan.

## Backup dan pemulihan

```sh
sudo bash scripts/backup.sh
sudo bash scripts/verify-restore.sh /var/backups/jalasmara/jalasmara-TIMESTAMP.archive.gz
```

Backup menyimpan MongoDB dan checksum dengan izin terbatas. Simpan salinan terenkripsi di luar VPS dan tentukan retensi sesuai kebutuhan. Tes restore memakai database `jalasmara_restore_check`, membandingkan jumlah dokumen, lalu menghapus database pemeriksaan. Hentikan perubahan data selama perbandingan agar hasil tidak berubah di tengah tes; perbandingan jumlah bukan verifikasi byte demi byte.

Untuk restore produksi, jadwalkan penghentian aplikasi, cek checksum, simpan backup keadaan terakhir, lalu jalankan `mongorestore` dengan namespace yang dipilih. Jangan menjalankan `--drop` pada database hidup tanpa keputusan pemulihan eksplisit. Redis berisi sesi sementara; kehilangan Redis membuat pemain login ulang dan menghapus penyelaman sementara. Simpan `.env` terpisah dari backup data dan repository.

## OIDC opsional

Akun lokal tetap tersedia tanpa ZITADEL. Isi `OIDC_ISSUER`, `OIDC_CLIENT_ID`, `OIDC_CLIENT_SECRET`, dan `OIDC_LABEL` pada aplikasi setelah provider siap. Redirect URI aplikasi adalah:

```text
https://staging-jalasmara.ardianryan.com/api/auth/oidc/callback
```

Daftarkan aplikasi web dengan authorization code, PKCE, serta scope `openid profile email`. Pemain menautkan provider setelah login lokal dan autentikasi ulang. Provider yang belum ditautkan tidak dapat membuat akun. Penggabungan berdasarkan email tidak dilakukan.

Overlay `compose.oidc.yml` menyediakan ZITADEL API v4.16.0, Login v2, dan PostgreSQL 17.10 sebagai layanan opsional. Gunakan `deploy/oidc.env.example` sebagai daftar parameter; secret diisi lokal. Overlay belum mengaktifkan provider Google/Microsoft, karena kredensial dan domain identitas belum diberikan.

```sh
docker compose --env-file .env --env-file .env.oidc -f compose.yml -f compose.oidc.yml config --quiet
docker compose --env-file .env --env-file .env.oidc -f compose.yml -f compose.oidc.yml up -d
```

Proxy eksternal milik pengguna perlu domain identitas tersendiri: `/ui/v2/login/*` menuju HTTP port **3002**, sisanya menuju API h2c port **8080**. Root `/` dapat diarahkan ke `/ui/v2/login/`. Jangan memproxy Login v2 ke API; keduanya proses terpisah. aaPanel harus mendukung h2c upstream untuk layanan API/gRPC yang memerlukannya. Konfigurasi overlay tidak mengubah aaPanel. Batasi kedua port hanya ke proxy privat. API publik menggunakan HTTPS melalui proxy, sementara koneksi container internal tidak memakai TLS.

Bootstrap menulis PAT login-client ke volume privat `zitadel-bootstrap`; volume ini juga perlu backup aman. Gunakan masterkey 32 karakter, password bootstrap kuat, dan tanggal kedaluwarsa PAT yang dikelola. Simpan backup PostgreSQL dengan `pg_dump` serta uji restore tersendiri sebelum mengaktifkan OIDC produksi. Jangan mengaktifkan overlay sampai domain dan proxy identitas siap.

Rujukan: [Compose resmi ZITADEL](https://zitadel.com/docs/self-hosting/deploy/compose), [konfigurasi Login v2](https://zitadel.com/docs/self-hosting/manage/login-client), dan [compose resmi versi 4.16.0](https://github.com/zitadel/zitadel/blob/v4.16.0/deploy/compose/docker-compose.yml).

## CI dan akses repository

Semua eksekusi build, pengujian, audit dependensi, dan CodeQL berada di `.gitlab-ci.yml`. GitHub Actions dinonaktifkan. GitLab menyimpan JUnit dan SARIF sebagai artefak; job report menyalin sumber ke `main` GitHub dan laporan ke branch `ci-reports` dengan deploy key write khusus repository.

Variabel `GITHUB_DEPLOY_KEY_B64` harus masked dan protected. Jangan memasukkan token pribadi `gh`/`glab` ke CI. Branch utama GitLab harus protected agar variabel tersedia. Pipeline merge request tidak menerima deploy key protected. Deploy key tidak memiliki hak GitHub Code Scanning; SARIF dikirim sebagai berkas laporan, bukan anotasi native GitHub.

Cache dapat dibuang tanpa kehilangan data. Build output Godot, `.runtime`, screenshot lokal, `.env`, dan moodboard tidak boleh masuk Git. CI tidak otomatis mengubah VPS. Rilis ke staging dilakukan terpisah setelah hasil pemeriksaan ditinjau.
