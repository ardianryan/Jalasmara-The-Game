# Operasi Jalasmara

**Pembaruan 10 November 2026:** [Gitea](operations-gitea.md) menjadi pusat repository, CI dan paket delivery. GitHub/GitLab tetap backup dengan CI dinonaktifkan. Tahap aktivasi VPS di bawah tetap terpisah dari build dan tidak otomatis dijalankan oleh workflow baru.

## Topologi staging

Aplikasi berada di VPS alias SSH `dev-jalasmara`, direktori `/opt/jalasmara`. Upstream game adalah **HTTP `10.1.0.8:3000`**, dengan URL publik **`https://staging-jalasmara.ardianryan.com`**. Pengguna mengatur reverse proxy dan sertifikat melalui aaPanel pada server terpisah `moodle-server` (`10.1.0.18`). Jangan memasang proxy tambahan atau mengubah server tersebut lewat deployment aplikasi.

Proxy harus mempertahankan `Host`, meneruskan `X-Forwarded-Proto: https`, dan menambahkan alamat klien pada `X-Forwarded-For`. Tetapkan `APP_ORIGIN=https://staging-jalasmara.ardianryan.com` dan `TRUST_PROXY=10.1.0.18` pada `.env` produksi. Jangan gunakan `trustProxy=true` tanpa batas alamat. Pastikan proxy tidak meng-cache `/api/` dan menyediakan MIME `application/wasm` untuk WebAssembly.

`APP_BIND=10.1.0.8` serta `APP_PORT=3000` memublikasikan upstream pada jaringan privat. `scripts/proxy-firewall.sh` membatasi port Docker ke alamat proxy dan host aplikasi; jangan mengandalkan UFW INPUT saja untuk port Docker. Unit `deploy/jalasmara-firewall.service` tersedia untuk persistensi. Verifikasi aturan aktual sebelum mengaktifkannya. Tidak ada port database yang diterbitkan pada compose produksi.

## Build dan pembaruan berbasis image

Staging menjalankan image Docker; **tidak memerlukan checkout Git, `git pull`, atau build dari direktori aplikasi VPS**. `/opt/jalasmara` mempertahankan compose, `.env`, script operasi, volume, dan backup. Context build sementara berada di direktori rilis terpisah. CI memeriksa kandidat, tetapi tidak mengaktifkannya di VPS. Tidak ada langkah CE pada alur ini.

Bekukan source yang akan diekspor. Engine dan template Godot harus sama-sama 4.7.2; jalankan pemeriksaan kandidat yang relevan sebelum packaging. Catat commit penuh sebelum export, karena commit source Docker bisa berbeda sesudah perbaikan host/API tanpa mengubah PCK:

```sh
npm ci
TASK_EXPORT_SOURCE="$(git rev-parse HEAD)"
npm run build:game
TASK_RELEASE_DIR="$PWD/.runtime/release-$(date -u +%Y%m%dT%H%M%SZ)"
python3 scripts/package-web-release.py \
  --output "$TASK_RELEASE_DIR" \
  --export-source "$TASK_EXPORT_SOURCE" \
  --reuse-wasm
```

Output baru berisi `context.tar` dan `manifest.json`. Script menolak output yang sudah ada, source tracked yang berubah dalam scope Docker, member archive symlink/hardlink/path tidak sah atau `.env*`, dan nama export tak dikenal. Input source berasal dari `git archive HEAD`, sehingga untracked/cache lokal tidak disertakan. Generated export harus tidak tracked, selain `.gitkeep` kosong. Script memverifikasi ukuran/SHA-256 PCK, seluruh part1MiB dan salinan gzip sebelum packaging. Jangan menjalankan export lain ketika context sedang dibuat.

Manifest membedakan:

- `source`: commit HEAD input Docker/API/website yang benar-benar diarsipkan.
- `declaredExportSource`: commit penuh yang dideklarasikan saat export Godot dimulai; bukan bukti otomatis bahwa PCK berasal dari commit tersebut. Simpan juga log export dan hash PCK.
- `context`: ukuran dan SHA-256 archive; `gameAssets`: ukuran/hash setiap aset; `toolSha256`: hash packager yang dijalankan.
- `requiredReusedAssets`: aset yang sengaja tidak ada dalam tar. Dengan export saat ini, `--reuse-wasm` menghilangkan `index.wasm` dan `index.wasm.gz`; keduanya tetap tercantum beserta hash/ukurannya. Hilangkan opsi ini bila belum tersedia salinan yang cocok.

Untuk rilis **host/API saja** dengan seluruh export Godot tetap byte-identik, gunakan `--reuse-game-assets` sebagai pengganti `--reuse-wasm`. Kedua opsi eksklusif. Packager tetap memvalidasi semua aset lokal/PCK/part/gzip dahulu; archive tidak membawa payload game, tetapi `requiredReusedAssets` wajib mencantumkan seluruh aset beserta byte/hash. Ambil salinan hanya dari image/build yang identitasnya dipin, lalu cocokkan **setiap** aset dengan manifest baru sebelum Docker build. Jangan menganggap PCK sama berarti loader/WASM/gzip juga sama. Jika satu aset berbeda atau tidak tersedia, hentikan dan buat paket yang membawanya; jangan menghapus item dari manifest agar lolos.

Simpan hash manifest/context dan kedua commit dalam catatan rilis, lalu transfer kedua output ke direktori sementara baru di VPS. Cocokkan byte/hash context dengan manifest **dan catatan lokal yang sudah dipin** sebelum ekstraksi. Gunakan archive dari packager yang telah diverifikasi, bukan archive lain. Ekstrak ke direktori context kosong; jangan menimpa `/opt/jalasmara`, compose atau `.env`.

Tetapkan `TASK_BUNDLE_DIR` ke path absolut direktori transfer dan `TASK_CONTEXT_DIR` ke path absolut direktori context baru yang belum ada. Verifikasi context sebelum ekstraksi; tetap cocokkan hash manifest dengan catatan lokal:

```sh
python3 - "$TASK_BUNDLE_DIR" <<'PYCONTEXT'
import hashlib, json, pathlib, sys
bundle = pathlib.Path(sys.argv[1])
record = json.loads((bundle / "manifest.json").read_text())["context"]
assert record["name"] == "context.tar"
path = bundle / "context.tar"
assert path.is_file() and not path.is_symlink()
digest = hashlib.sha256()
with path.open("rb") as stream:
    for block in iter(lambda: stream.read(1024 * 1024), b""):
        digest.update(block)
assert path.stat().st_size == record["bytes"]
assert digest.hexdigest() == record["sha256"]
print("Context bytes and SHA-256 match")
PYCONTEXT
mkdir "$TASK_CONTEXT_DIR"
tar -xf "$TASK_BUNDLE_DIR/context.tar" -C "$TASK_CONTEXT_DIR"
```

Bila reuse diminta, salin aset dari container aktif tanpa menghentikannya. Contoh berikut dijalankan dari `/opt/jalasmara`; `TASK_CONTEXT_DIR` menunjuk hasil ekstraksi baru, dan `TASK_BUNDLE_DIR` menunjuk direktori manifest/context transfer:

```sh
TASK_ACTIVE_CONTAINER="$(APP_VERSION=current docker compose ps -q app)"
docker cp "$TASK_ACTIVE_CONTAINER:/app/apps/web/dist/game/index.wasm" \
  "$TASK_CONTEXT_DIR/apps/web/public/game/index.wasm"
docker cp "$TASK_ACTIVE_CONTAINER:/app/apps/web/dist/game/index.wasm.gz" \
  "$TASK_CONTEXT_DIR/apps/web/public/game/index.wasm.gz"
```

Salinan dari image lama tidak otomatis benar. Verifikasi **semua** aset dalam context sesudah reuse dan sebelum build; ini juga mendeteksi perubahan aset antara hashing dan penulisan tar. Jangan meneruskan build bila satu byte/hash berbeda:

```sh
python3 - "$TASK_CONTEXT_DIR" "$TASK_BUNDLE_DIR/manifest.json" <<'PYVERIFY'
import hashlib, json, pathlib, sys
root, manifest_path = map(pathlib.Path, sys.argv[1:])
manifest = json.loads(manifest_path.read_text())
for record in manifest["gameAssets"]:
    name = record["name"]
    assert pathlib.Path(name).name == name, "Invalid asset name"
    path = root / "apps/web/public/game" / name
    assert path.is_file() and not path.is_symlink(), name
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    assert path.stat().st_size == record["bytes"], name + " size"
    assert digest.hexdigest() == record["sha256"], name + " sha256"
print("All gameAssets match the release manifest")
PYVERIFY
```

Bangun dari context tersebut dengan tag rilis baru yang belum dipakai, misalnya `jalasmara:release-<waktuUTC>-<source12>`. Catat image ID hasil `docker image inspect`, tag, kedua source commit, hash context dan PCK. Sebelum aktivasi, baca `index.pck` dan manifest di `/app/apps/web/dist/game` dari image hasil build dan cocokkan hash/ukuran dengan paket; keberhasilan `docker build` saja belum membuktikan aset yang benar. Build dapat dilakukan di VPS dari context sementara atau image terverifikasi dapat dipindahkan; tidak ada kebutuhan Git checkout di VPS.

```sh
docker build -t "jalasmara:$TASK_RELEASE_TAG" "$TASK_CONTEXT_DIR"
docker image inspect --format '{{.Id}}' "jalasmara:$TASK_RELEASE_TAG"
```

Exporter mengimpor font dua tahap agar export bersih tidak bergantung pada cache editor. Salinan gzip WASM/JavaScript dipilih Fastify melalui `Accept-Encoding`, dengan `Vary: Accept-Encoding`; original tetap tersedia. PCK tidak dikompresi ulang bila penghematannya di bawah5%. Proxy meneruskan negosiasi encoding standar; alur rilis tidak mengubah aaPanel.

Aktivasi rutin tidak menjalankan seed, reset owner, atau inisialisasi ulang volume. CLI owner berikut hanya untuk pembuatan/pemulihan akun yang memang diperlukan, bukan setiap pembaruan.

Untuk membuat owner, jalankan dari terminal pengguna, tanpa `-T`:

```sh
ssh -t dev-jalasmara 'cd /opt/jalasmara && docker compose exec app node apps/api/dist/apps/api/src/cli.js owner'
```

Isi nama **Ardian**, email yang dipilih pemilik, dan password minimal 12 karakter. Email belum ditetapkan dalam kode. Password tidak di-echo oleh perintah. Pemulihan menggunakan perintah `recover-owner` melalui terminal yang sama dan mencabut sesi lama.

Setelah login, owner membuat undangan dari panel. Tautan undangan berlaku 72 jam dan reset satu jam. Salin dan bagikan secara privat. Tidak ada SMTP pada demo.

## Aktivasi, verifikasi dan rollback

Sebelum mengganti image, catat container/image aktif, `.env` checksum, bind upstream, identitas container Mongo/Redis dan ruang bebas. Buat backup serta uji restore terpisah seperti bagian berikut. Pertahankan image aktif lama dengan tag rollback unik dan image ID yang tercatat. `APP_VERSION=current` di contoh hanya variabel proses; jangan menyunting `.env` untuk mengganti rilis.

```sh
cd /opt/jalasmara
TASK_ACTIVE_CONTAINER="$(APP_VERSION=current docker compose ps -q app)"
TASK_PRIOR_IMAGE="$(docker inspect --format '{{.Image}}' "$TASK_ACTIVE_CONTAINER")"
docker image tag "$TASK_PRIOR_IMAGE" "jalasmara:$TASK_ROLLBACK_TAG"
sha256sum .env
docker image tag "jalasmara:$TASK_RELEASE_TAG" jalasmara:current
APP_VERSION=current docker compose up -d --no-build --no-deps app </dev/null
APP_VERSION=current docker compose ps
APP_VERSION=current docker compose logs --tail=100 app
```

`TASK_RELEASE_TAG` dan `TASK_ROLLBACK_TAG` harus ditetapkan ke tag unik dalam catatan rilis; jangan menimpa tag rollback yang masih diperlukan. Hanya service app direcreate, tanpa build baru atau recreate database. Jangan memakai `docker compose down -v`.

Periksa status health container dan API. Host VPS tidak selalu mempunyai `curl`; pemeriksaan internal dapat memakai Node yang sudah ada di container. Redirect stdin agar `docker compose exec -T` tidak mengonsumsi sisa script operator yang dikirim melalui stdin:

```sh
APP_VERSION=current docker compose exec -T app node -e \
  'fetch("http://127.0.0.1:3000/api/health").then(async r=>{console.log(await r.text());if(!r.ok)process.exit(1)}).catch(e=>{console.error(e);process.exit(1)})' </dev/null
sha256sum .env
```

Pastikan image/container aktual, hash PCK penuh, manifest part, bind `10.1.0.8:3000`, checksum `.env` serta container Mongo/Redis cocok dengan catatan yang diharapkan. Dari mesin operator, periksa `https://staging-jalasmara.ardianryan.com/api/health`, kemudian jalankan smoke publik dengan hash/ukuran PCK yang dipin: startup default, login fixture, perjalanan darat/hutan, jurnal/pause, save dan reload. Gunakan UUID fixture sendiri dan pastikan akun/receipt/shift/auth cleanup nol. Pemeriksaan internal belum membuktikan HTTPS, delivery H2, startup atau perjalanan game publik. Catat emulasi versus perangkat nyata; jangan menyebut SwiftShader sebagai FPS Samsung/Windows.

Jika health/hash atau smoke gagal, kembalikan tag `current` ke image lama yang sudah dicatat, lalu recreate **app saja** dan ulangi verifikasi. Tidak perlu checkout source atau mengubah `.env`:

```sh
docker image tag "$TASK_PRIOR_IMAGE" jalasmara:current
APP_VERSION=current docker compose up -d --no-build --no-deps app </dev/null
```

Untuk rollback pada sesi operator baru, ambil image ID/tag rollback dari catatan rilis, jangan mengandalkan variabel shell sesi sebelumnya. Rollback image tidak memutar balik data. Jika migrasi tidak kompatibel, uji backup di lingkungan terpisah sebelum keputusan restore produksi; jangan otomatis mengganti database saat health gagal. Simpan log aktivasi gagal dan hasil rollback.

## Backup dan pemulihan

```sh
sudo bash scripts/backup.sh
sudo bash scripts/verify-restore.sh /var/backups/jalasmara/jalasmara-TIMESTAMP.archive.gz
```

Backup menyimpan MongoDB dan checksum dengan izin terbatas. Simpan salinan terenkripsi di luar VPS dan tentukan retensi sesuai kebutuhan. Tes restore memakai database `jalasmara_restore_check`, membandingkan jumlah dokumen, lalu menghapus database pemeriksaan. Hentikan perubahan data selama perbandingan agar hasil tidak berubah di tengah tes; perbandingan jumlah bukan verifikasi byte demi byte.

Untuk restore produksi, jadwalkan penghentian aplikasi, cek checksum, simpan backup keadaan terakhir, lalu jalankan `mongorestore` dengan namespace yang dipilih. Jangan menjalankan `--drop` pada database hidup tanpa keputusan pemulihan eksplisit. Redis berisi sesi sementara; kehilangan Redis membuat pemain login ulang dan menghapus penyelaman sementara. Simpan `.env` terpisah dari backup data dan repository.

Godot menonaktifkan dekompresi ulang `HTTPRequest` pada ekspor Web karena browser sudah mendekompresi respons dari proxy. Konfigurasi ini menghindari kegagalan parsing respons gzip tanpa mengubah proxy. Lihat [properti accept_gzip pada dokumentasi Godot](https://docs.godotengine.org/en/stable/classes/class_httprequest.html#class-httprequest-property-accept-gzip).

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

Job `verify` juga menjalankan lima uji CPU packager (`python3 scripts/test_package_web_release.py -v`); ini memeriksa archive/manifest/gzip/overwrite, bukan penerimaan image atau deployment.

Cache dapat dibuang tanpa kehilangan data. Build output Godot, `.runtime`, screenshot lokal, `.env`, dan moodboard tidak boleh masuk Git. CI tidak otomatis mengubah VPS. Rilis ke staging dilakukan terpisah setelah hasil pemeriksaan ditinjau.

## Retensi hasil build

Sesudah image baru lulus smoke dan satu rollback terverifikasi sudah dipin, hapus arsip transfer/context hasil ekstraksi dan direktori build sementara yang tidak lagi diperlukan. Pertahankan manifest, hash dan log penerimaannya; jangan menghapus satu-satunya bukti rilis. Simpan image aktif dan satu rollback yang terverifikasi; beberapa tag pada image yang sama tidak menggandakan ukuran layer. Cache compiler/editor worktree yang sedang tidak dipakai boleh dibuang sesudah pemilik melepas prosesnya. Pertahankan source, hasil review, log pengujian, dependency bersama, binary serta template export yang masih diperlukan.

Pada VPS, cocokkan tag `current` dengan image container aktif dan tag rollback dengan image ID yang tercatat. Hapus tag/image superseded hanya setelah dipastikan bukan keduanya dan tidak dirujuk container atau build aktif; jangan memakai `docker image prune -a` sebagai pengganti pemilihan tersebut. Periksa `docker ps`, image ID, dan build yang sedang berjalan sebelum `docker builder prune -a -f` serta `docker image prune -f`. Kedua perintah ini dijalankan setelah build selesai. Jangan memakai prune volume atau menghapus database, `.env`, backup, atau direktori aplikasi aktif untuk menghemat cache. Catat ruang bebas sebelum/sesudah dan verifikasi health aplikasi serta hash PCK. Ukuran images dan build cache dapat menunjuk layer bersama: jangan menjumlahkannya sebagai byte yang berhasil dibebaskan.
