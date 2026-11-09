# 06-A/B1: smoke melalui HTTPS staging

9 November 2026. Smoke berjalan melalui `https://staging-jalasmara.ardianryan.com` setelah integrator mengonfirmasi rilis aplikasi `9ba21c6bdcb86de1b1732fe4d646fc5a27099eec`. Pengujian ini mengunduh PCK publik dan memeriksa sendiri hash-nya sebelum membuat fixture:

```text
SHA-256: a9378a52c9fbb64ec96ae579bcef1ced1ab7920962823025e238a453eb8a716b
PCK terdekode: 64.249.828 byte
```

Jumlah byte tersebut hanya PCK, bukan keseluruhan unduhan awal mesin, JavaScript, dan aset permainan. Hash cocok dengan paket runtime guard `2f7f55129c4bafacbf49449d703f3e7913917de3` yang telah diuji secara lokal.

## Hasil aktual

`scripts/staging-plan06-smoke.mjs` selesai dengan exit 0, **lima pemeriksaan lulus, tanpa error browser dan tanpa respons API gagal**:

| Pemeriksaan | Bukti |
| --- | --- |
| Health dan paket publik | `/api/health` mengembalikan HTTP berhasil dengan `status: ok`; SHA-256 dihitung dari seluruh body PCK HTTPS, tanpa override atau penggantian aset. |
| Login dan startup | Login melalui formulir publik memakai pemain UUID baru. Cookie `__Host-jalasmara` memiliki `Secure`, `HttpOnly`, serta `SameSite=Lax`; Godot sebenarnya mencapai ready dan overlay loading hilang. Pemain dirender pada spawn desa `[1120,1230]`. |
| Gerbang dan tajuk | Input gerak fisik mengikuti jalan desa ke gerbang, kemudian interaksi menerima perpindahan API ke hutan. Pemain berjalan menuju `[350,1250]` dan berhenti aktual pada `[345.59,1256.70]`. Tiga dari 47 tajuk mempunyai reveal selesai (`amount = 1`), satu mask bersama, batang tetap utuh, dan kamera tetap 35°. |
| Jurnal sentuh | Pada viewport 667×375, ikon jurnal disentuh melalui koordinat canvas sebenarnya. Modal terbuka, `clockPaused` aktif, dan input gerak tidak menggeser pemain. Escape menutup jurnal dan melepas jeda. |
| Posisi server dan reload | Posisi hutan dibaca kembali melalui API, lalu halaman dimuat ulang. Pemain kembali pada koordinat yang sama dengan satu aktor 3D dan reveal lokal aktif. Saldo tetap 200, hari cerita tetap 1, dan durasi kalender tetap 36 menit. |

Gambar gerbang sebelum dan sesudah reload diperiksa manual: kepala dan torso Nala terlihat melalui celah lokal sementara batang dan daun di sekelilingnya tetap utuh. Jurnal dan tombol tutup terbaca pada layar pendek. Cuaca aktual cerah, dari sekitar 10:00 di desa sampai 10:35 di hutan.

## Isolasi dan pembersihan

Lane baru terpisah dari seluruh harness lokal. Ia mengunci origin staging persis, hash paket rilis persis, dan izin eksekusi eksplisit:

```sh
RUN_STAGING_SMOKE=plan06-public node scripts/staging-plan06-smoke.mjs
```

Pemain dibuat melalui SSH `dev-jalasmara`, menggunakan proses Node di container aplikasi `/opt/jalasmara`. Defaults berasal dari shared hasil kompilasi aplikasi dan kata sandi di-hash menggunakan argon2. UUID dan kata sandi acak dikirim melalui stdin, tidak melalui argumen proses, log, repository, atau berkas kredensial. Tidak ada akun pengelola atau fixture pengguna yang dipakai; seed konten tidak dijalankan.

Blok `finally` menutup Chromium sebelum pembersihan SSH. Penghapusan memvalidasi UUID, email khusus run, nama, dan role pemain, kemudian menghapus hanya pemain tersebut, receipt berawalan UUID-nya, shift miliknya, cache surface/home/calendar/dive, serta sesi auth dengan `userId` yang cocok. Hasil pemeriksaan akhir remote:

```json
{ "players": 0, "receipts": 0, "shifts": 0, "keys": 0 }
```

`keys` mencakup kunci sesi yang diperoleh dari cookie dan pencarian sesi milik UUID tersebut. Harness tidak mengubah guard local-only lama atau kode produksi. Browser/GPU dipakai secara bergantian sesudah slot native/profiling dilepas dan dikembalikan setelah Chromium ditutup.

## Bukti dan batas

Artefak lokal yang tidak dibundel berada di `artifacts/browser/staging-plan06-7dc4c289-256c-4371-b7fb-0fca635f79aa/`: `results.json`, `01-public-ready-hub.png`, `02-public-physical-canopy-667x375.png`, `03-public-journal-pauses-movement.png`, serta `04-public-forest-resumes-after-reload.png`.

Pemeriksaan CPU sebelum eksekusi mencakup sintaks host dan helper remote, quoting SSH yang mempertahankan kode statis, serta penolakan eksekusi tanpa flag eksplisit sebelum network/account/browser. Pada run aktual tidak ada teleport debug, intersepsi respons, PCK override, atau perubahan data pemain lain.

Ini smoke publik pada Chromium dengan emulasi sentuh 844×390/667×375 dan SwiftShader di host pengembangan. Ia bukan benchmark atau penerimaan perangkat Windows/Samsung S23. Rute kedua jembatan, pemulihan tajuk saat keluar, dan jeda kalender server telah dicakup [penerimaan browser lokal](06a-forest-browser.md); alur kedai–rumah–tidur–reload serta HUD malam dua orientasi dicakup [regresi malam lokal](06a-night-regression.md), bukan dijalankan ulang melalui staging dalam smoke terbatas ini. Seluruh Rencana 06 belum dinyatakan selesai oleh laporan ini.
