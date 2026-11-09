# Finishing dunia 06-B2 dan galeri pengembangan

9 November 2026. Pengguna membatalkan migrasi GitLab CE dan meminta pekerjaan inti dilanjutkan, lalu meminta bukti visual bisa dilihat di GitHub. Dokumen ini membedakan runtime rilis, bukti lokal, dan kandidat animasi berikutnya.

## Paket yang sudah dibangun

- Source image: `b5b459ea448bc8799bebb771e56df20ce5e8f039`; commit CI berikutnya `cc6b5148014c82b2616339eeee37df0fbe4d15b3` hanya mendaftarkan tiga regresi body-fault ke runner.
- Image VPS: `sha256:d60aab21ec405f85cd3c35b7c1cecd70b331142e280953364aa00de7f3e3e81b`, tag `jalasmara:06b2-b5b459e`.
- PCK: `5f5baf243a3bf941cf34fab6c143bb9cf2bc8d65997ded6ed4e048b929353f96`,64.333.184byte.
- WASM: `fc74679e3b97f76878947fcd4fbe1268cbfa6188182a2e33bbc3f5dc9bfa57d0`; loader dipatch: `a72d94cabd4b5cedcf66bebd84c97b6e8c3173c6b269f2fdfa887fd47597ad05`.
- Arsip source/export: SHA`9c293ab6fa90ca3282926223b8b9d474eca495eac41c5b900df19a42b44f5e15`,216.328.610byte. Build terpisah `/opt/jalasmara-releases/06b2-b5b459e`, bukan build di direktori aplikasi hidup. Pemeriksaan image offline membuktikan hash/ukuran PCK yang benar sebelum aktivasi.

Paket berisi rumah sejajar dek, gapura dengan bukaan/collider mengikuti jalan, tebing berfaset bertumpu, preview desa–hutan yang menyambung, support tread tangga sebenarnya, pelataran rumput/jalan dan warna cerah dengan normal shadow yang diperbaiki. Loader menampilkan error/retry ketika body PCK/WASM ditolak. Tidak ada raster atau dependency runtime baru, fullengine Noxe, migrasi Phaser/Three, atau klaim semua pose kaki sudah natural.

## Bukti yang diterima

Typecheck/100API/50world/722fauna-frame, native28rumah/18terrain/6gate/99frame tangga, localgateway7/canopy4/bodyfault6 browser lulus. Root mengulang25loader dan19navigation/harness pada source gabungan serta tiga audit dependensi nol. [Laporan dunia](06b2-world-finishing-progress.md), [gerbang/kanopi](06b-local-world-browser-acceptance-5f5.md), [body-fault](06p-loader-body-fault-browser.md) menyimpan bukti dan riwayat kegagalan. Ini tidak menggantikan hasil CI/default HTTPS/perangkat fisik.

Backup sebelum aktivasi `jalasmara-20261109T134822Z.archive.gz`, SHA`76095fe83cda6624d525e2cc944f33668c95d6a00cce48d3cb2e401c55527a23`. Restore ke database terpisah selesai42dokumen/0gagal, hitungan tiap koleksi cocok dan database pemeriksaan dihapus. Data owner tidak direset, tidak ada reseed.

## Pembatalan CE dan penyimpanan

CI tetap GitLab.com dan GitHub mirror. Tidak ada token/runner/server CE dipasang; remote lokalCE dihapus. Perbaikan Pillow dan riwayat lengkap mirror dipertahankan, body-fault ditambahkan ke CI. Pipeline awal b5b3045322936 dihentikan karena diganti sourceCIcc6, bukan diberi status lulus.

Satu cache Godot lama `Jalasmara-06-house-integration/client-godot/.godot` dihapus setelah pemeriksaan ignored/tidak tracked/tanpa handle:64.995.328allocatedbyte; free lokal10.441.719.808→10.506.891.264byte. Source, bukti, seluruh jalur Nala aktif, dependency, konfigurasi dan data tetap. Manifest lokal `.runtime/releases/06b2-final/cleanup-local.json`.

## Kelanjutan

Nala restart kandidat62a8538 mengurangi lonjakan lutut saat mulai ulang ke kanan layar. Focused/native dan model lulus; before/after ditinjau root. Kandidat terpisah dari image dunia ini, belum merupakan telapak terkunci, sinkron per-leg tangga, semua arah atau bukti browser/perangkat. [Branch kandidat](https://github.com/ardianryan/Jalasmara-The-Game/tree/work/06b-nala-restart-audit) memegang source/review. Prioritas berikutnya adalah penerimaan gabungan dan world3D/browser kandidat, lalu rig warga/rumah lurah/direkturRV dan Laskar sesuai PRD. Windows/S23 fisik dan transportHTTP2 publik tetap harus dinyatakan menurut hasil aktual.

## Aktivasi dan hasil publik aktual

Kelima job [CI3045337293](06b2-ci-artifacts-3045337293.md) lulus. API100/world50/tiga audit nol; CodeQL201aturan/1warning+2notes tetap dicatat. Image diaktifkan hanya serviceapp dengan `--no-deps --no-build`, health200, internalPCK5f5 benar. FullcurlHTTPS publik memverifikasi64.333.184byte/SHA5f5; `.env`, Mongo/RedisID/volume dan bind tetap. Rollback43bd disimpan dengan tag `rollback-06b-f4fac83`. Tidak ada reseed atau perubahan proxy.

Default Chromium/WebGL publik UUID`152bacc6-39a7-4068-99bc-6d430c31f538` gagal batas startup120detik; hanya health/hash1check,0pulses. WASM31.052.533decoded/7.312.790encoded dan PCK1.119.800decoded/1.105.628encoded masih HTTP200H2pending pada45.198.149.181. Tidak ada bodyreject atau console/APIerror; ini tetap gagal, bukan PASS gameplay. Semua data fixture/receipt/shift/session dibersihkan dan browser ditutup. Artefak `Jalasmara-06-buildings-gates/artifacts/browser/staging-plan06-152bacc6-39a7-4068-99bc-6d430c31f538/`. Masalah sudah ada pada43df; loadererrorpatch tidak memperbaiki slowtransfer yang tidak rejected. PythonHTTP1 manual juga sempat lambat dan dihentikan; curlH2 berhasil. Penyebab belum dibuktikan.

[Galeri visual](../visual/README.md) sudah dipush GitHub/GitLab, tautan README publikHTTP200. LimaPNG1.255.344byte; semuanya salinan exact bukti original dengan provenance/hash, termasuk kandidat Nala berlabel BELUMDIRILIS. Galeri bukan kit aset umum; splitLICENSE tetap. Source/kandidatNala juga tersedia di branchGitHub, tidak mengubah image dunia aktif.

## Pembersihan sesudah rilis

VPS menghapus buildsource262.967.296allocatedbyte dan transferarchive216.334.336byte, serta danglingDockerimages (laporan Docker256,3MB). FreeVPS42.550.169.600→43.758.903.296byte; angka free teramati tidak dijumlahkan dengan ukuran layer yang bisa berbagi. Image5c5 yang lebih tua dipensiunkan sesudah43bd dipastikan menjadi rollback: free43.758.596.096→44.041.203.712byte. Image aktifd60 dan rollback43bd tetap, tidak ada volume yang dipangkas.

Lokal dua arsip source/export superseded9cc/final b5b dihapus setelah image/publichash benar,432.644.096allocatedbyte; free9.139.351.552→9.572.589.568byte pada checkpoint terpisah. File PCKunduhan64.333.184byte sementara juga dihapus setelah hash dicatat. Cachelama64.995.328byte tercatat di atas. Log/manifest/screenshot dan seluruh source tetap disimpan.

Checkpoint diagnosis terakhir: [purefetch browser](06p-public-asset-only-transport.md) selesai tanpaengine/akun: PCK lambat20detik, WASMgzip cepat387,4ms. [Origin/header comparison](06b2-public-asset-transfer-audit.md) membuktikan origin privat cepat dan beberapa varian curl bisa lambat. Eksperimen header paralel belum membuktikan sebab; berikutnya serial/cache/connection comparison. Semua proses uji sudah ditutup, health sesudah cleanup200. Galeri/mainREADME/WorldKitreference dan catatan CI/rilis sudah dipush kedua mirror. Runtime tetap sourceb5b/PCK5f5; tidak ada modifikasi proxy atau klaim fullpublicPASS.
