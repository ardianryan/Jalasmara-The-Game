# Persiapan QA browser game: kandidat 06-B dan layout 9

Tanggal: 9 November 2026. **Status: persiapan CPU selesai, browser game belum dijalankan.** Branch `work/06b-browser-route`, worktree `Jalasmara-06-game-browser`, dimulai dari `e27d613`. Tidak mengubah runtime, website produksi, API, layout, ekonomi, atau akun pengelola. Integrator masih menyelesaikan alignment Griya dan turn Ujang sebelum export akhir.

## Cakupan yang sudah tersedia dan celah kandidat

| Harness                                                   | Bukti sebelumnya                                                                                                                    | Celah pada kandidat gabungan                                                                                                                                         |
| --------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `plan06-forest-browser.mjs`                               | Gerbang fisik, bukaan tajuk, pemulihan, dua jembatan, input analog, pause jurnal, posisi forest setelah reload pada PCK `a9378a52`. | Belum dijalankan pada layout 9, tujuh shelter, Griya sejajar dek, dan rig kandidat akhir.                                                                            |
| `night-home-browser.mjs`, dengan `VERIFY_COMPACT_NIGHT=1` | Pelayanan kedai, stok, penutupan, rumah, tidur dan reload; HUD malam 667/390 serta safe area.                                       | Perlu putaran ulang pada API/PCK gabungan setelah export. Ini tetap pemeriksaan transaksi malam utama.                                                               |
| `homestead-browser.mjs`                                   | Transaksi rumah/kebun dan retry, termasuk respons hilang sesudah commit.                                                            | Tidak perlu diulang untuk setiap perubahan gambar; perubahan footprint/pintu/route memerlukan pemeriksaan akses dan posisi tersimpan yang baru.                      |
| `staging-plan06-smoke.mjs`                                | Akun publik UUID sendiri, HTTPS/cookie, PCK pin, gerbang/tajuk/jurnal/save pada rilis lama.                                         | Masih mematok PCK `a9378a52` dan 64.249.828 B. Jangan menjalankannya sebagai bukti kandidat baru tanpa memperbarui metadata sesudah rilis yang benar-benar dipasang. |
| `website06-browser.mjs`                                   | 32 checks production website pada source website yang sama, API fixture, bukan game.                                                | Tidak menggantikan pengujian HUD Godot, gerak, collision, rumah, save, atau laut.                                                                                    |

## Harness tambahan yang disiapkan

`scripts/plan06-layout-browser.mjs` menjalankan game ekspor dan API nyata di origin lokal. PCK SHA-256 dan ukuran byte wajib diisi; keduanya dicocokkan dengan respons unduhan aktual **sebelum fixture dibuat**. API harus memakai source yang mempunyai layout 9. Default origin ialah `http://localhost:3101`, terpisah dari proses lokal lama 3100. Host nonlokal dan `BROWSER_FIXTURE` ditolak.

Fixture memakai UUID/email/password acak sendiri, role player, story day 2 supaya Saras hadir, dan kalender day 2 pukul 18.30. UUID dipilih memakai fungsi `calendarRain` yang sama dengan server agar hujan merupakan cuaca otoritatif akun tersebut. Tidak mengubah cuaca lewat JavaScript, jam client, snapshot, atau mock response. Lokasi lama layout 8 disiapkan hanya pada cache UUID fixture sendiri, di salah satu tiang baru berdasarkan manifest source final. Proses ini baru dijalankan setelah pin kandidat cocok.

Rangkaian yang disiapkan:

1. Login form nyata, game siap, API/world layout 9, migrasi lokasi layout 8 keluar dari tiang ke lantai sah, lima atap/sepuluh tiang/empat fondasi tersedia pada diagnostics renderer nyata.
2. Berjalan ke pintu Griya dari `world.homestead.door`, menilai serambi malam, masuk melalui UI, berjalan di interior, menunggu posisi tersimpan, reload di dalam, dan keluar melalui UI. Footprint, pintu, post dan rute dibaca dari manifest saat pengujian; perubahan alignment Griya tidak dipatok sebagai koordinat bangunan lama.
3. Menunggu ketujuh warga tiba di tujuan shelter pada hujan server, lalu mendatangi tiap tujuan dan membuka percakapan. Snapshot harus menunjukkan station/shelter, bukan hanya warga sedang menuju rumah. Percakapan menjeda dan dapat dilanjutkan tanpa membekukan input.
4. Menjalankan rangkaian hutan yang sudah ada: gerbang, tajuk setempat dan restore, pause jurnal dengan heartbeat server, gerak joystick, dua jembatan, save/reload, serta pulang lewat portal.
5. Berjalan ke tangga selam, masuk melalui aksi nyata, menguji joystick portrait yang dibatalkan dengan `touchCancel`, membuka tas saat menyelam, pulang lewat tangga/ekstraksi, dan reload posisi hub. Ekstraksi biasa memang mengubah tahap menjadi `night`; hari cerita tetap 2, koin 200 dan inventori kosong sesuai fixture tanpa tangkapan.

Tidak ada teleport, pemanggilan aksi game melalui debug API, penulisan snapshot, request mutasi langsung untuk menggantikan tombol, atau pembuatan hadiah. Pengaturan fixture awal dan pembersihan data berbeda dari tindakan gameplay: sesudah mulai, gerak/interaksi dikirim melalui keyboard dan sentuh sebenarnya.

`scripts/plan06-physical-route.mjs` mempertahankan rute tangga/jembatan yang sudah dipakai jika seluruh segmennya masih sah. Jika tiang baru memotong segmen lama, ia menghitung detour dari titik rute/commute dan sudut post, lalu memeriksa setiap segmen terhadap `isLandSegmentWalkable` manifest aktual. Perencana ini hanya memilih titik yang akan dituju input; ia tidak mengubah posisi pemain. Perbedaan jalur manifest dengan collision/render sebenarnya tetap dapat ditemukan saat browser dijalankan.

HUD diuji pada viewport emulasi 667×375, 844×390, 390×844, dan lebar desktop 1440×900 dalam context sentuh. Safe area 24/16/12/18 CSS px diterapkan pada probe host yang sebenarnya. Bukti ini akan menguji layout responsif dan input sintetis Chromium, bukan perangkat Samsung S23, Windows, atau sentuhan jari fisik.

## Verifikasi yang benar-benar sudah dilakukan

- `node --check` lulus pada kedua script baru; Prettier dan `git diff --check` lulus.
- Pemeriksaan CPU manifest baseline layout 9: **10 tujuan, 112 segmen sah**, mencakup Griya, tujuh station shelter, gerbang hutan dan tangga selam. Ini membuktikan hasil perencana terhadap manifest baseline; tidak menggantikan collision/input game sebenarnya dan harus diulang setelah perubahan alignment terakhir digabung.
- Pengulangan terhadap manifest integrasi **`b765587`**, sesudah alignment Griya, awalnya menemukan kegagalan helper `hubRoute`: graf metadata lama melempar “Destination is disconnected” sebelum detour geometri sempat dihitung. Penanganan assertion graf itu diperbaiki pada helper pengujian, tanpa melonggarkan pemeriksaan segmen atau mengubah game. Pengulangan berikutnya lulus **10 tujuan, 97 segmen sah** pada manifest final tersebut. Hasil awal yang gagal merupakan kegagalan perencana harness, bukan bukti bahwa pemain game terhalang.
- Tidak membuka browser/Godot, tidak memanggil API kandidat, tidak membuat fixture dan tidak mengubah MongoDB/Redis pada tahap persiapan ini. Proses 3100 tidak disentuh.
- Tool aktual: Node/TypeScript loader `tsx`, fungsi geometri shared proyek, filesystem/Git. Playwright/Chromium, MongoDB, Redis dan Argon2 baru merupakan dependensi harness yang akan digunakan saat eksekusi mendapat slot. Tidak meneliti atau memakai tool gambar/engine upstream baru.

## Command berikutnya dan dependensi

Jalankan dari source integrasi akhir yang sudah menerima perubahan Griya/Ujang dan kedua script ini, bukan dari worktree baseline yang belum diperbarui. Diperlukan build API/web production yang menyajikan PCK final pada **3101**, Mongo replica-set lokal pada 27018 dengan satu konten published, Redis lokal pada 6380, dependensi npm dan Chromium Playwright yang sudah tersedia. Tidak reseed atau mereset akun.

```sh
APP_TEST_ORIGIN=http://localhost:3101 \
PLAN06_EXPECT_PCK=<sha256-export-final> \
PLAN06_EXPECT_PCK_BYTES=<byte-export-final> \
node --import tsx scripts/plan06-layout-browser.mjs
```

Rute dibatasi sepuluh menit setelah kesiapan awal. Pergantian hari kalender yang sah boleh terjadi sesudah pemeriksaan shelter; hari kalender dan progres cerita tetap dibedakan. Kesiapan engine/reload mempunyai timeout 240 detik masing-masing. Melebihi anggaran dicatat sebagai kegagalan harness/lingkungan yang perlu diperiksa, bukan otomatis kesalahan game. Tiap waypoint juga mempunyai batas retry/stuck; tidak ada fallback teleport.

Sesudah slot dilepas, jalankan rangkaian transaksi malam terpisah pada kandidat yang sama:

```sh
VERIFY_COMPACT_NIGHT=1 APP_TEST_ORIGIN=http://localhost:3101 \
node --import tsx scripts/night-home-browser.mjs
```

Harness menulis PNG, observations, operasi, pin PCK, hasil dan snapshot terakhir ke folder UUID `artifacts/browser/plan06-layout-*`. Ia menutup browser lalu menghapus hanya player/email/role/name fixture, receipts miliknya, shifts miliknya, dan kunci Redis yang berasal dari UUID atau cookie sesi yang diverifikasi pemiliknya. Keberhasilan cleanup diperiksa dan dicatat. Artifact tidak dimasukkan ke Git; password/cookie tidak dicetak.

## Sisa dan pemilik

- **Integrator:** menerima source akhir, export, pin hash/byte dan menjalankan API terpisah di 3101; mempertahankan slot engine satu pemilik. Perbarui handoff aktif dengan review persiapan ini.
- **Agent QA:** sesudah mendapat slot, jalankan harness nyata, periksa semua kegagalan dan capture, serta laporkan cleanup. Jangan mengklaim hasil script yang baru disiapkan sebagai hasil penerimaan.
- **Agent QA/integrator:** ulang transaksi malam dan tur Griya setelah perubahan alignment final. Pixel/bentuk/comfy, ketertutupan tubuh di bawah atap, pijakan dan arah/prostetik tetap dinilai melalui gambar/gerak aktual.
- **Setelah rilis:** smoke staging baru memakai pin source/PCK yang benar; hasil lama dipertahankan sebagai sejarah. Windows/S23 fisik, sesi panjang dan kamera kiri gameplay global tetap belum ditutup oleh harness ini.

## Eksekusi awal kandidat: hasil parsial dan koreksi harness

Actual-game browser pertama dijalankan pada kandidat runtime `e1bdf95` melalui API production lokal `http://localhost:3101`, dengan PCK SHA-256 `7f2ac59f0e39bed9ad5d6e47f4836f76a097b89cc2dadf388514cfbd5d02eaf9`, **64.289.088 B**. Tool aktual: Playwright Chromium dengan SwiftShader, viewport sentuh emulasi, API/Fastify, MongoDB dan Redis lokal nyata. Ini bukan perangkat fisik atau pengukuran FPS.

Rangkaian berhasil mengunduh dan mencocokkan PCK, login, memigrasikan lokasi lama keluar post ke layout 9, berjalan ke Griya, masuk melalui UI, berjalan di interior dan menyimpan posisi. Rangkaian kemudian **gagal pada harness attach sesudah reload**: predicate dari script hutan menunggu `snapshot.hud`, sedangkan snapshot `HomesteadUI.gd` memang mengekspor `area/home`, `renderer` dan `homestead`, tanpa key HUD. Ia menunggu timeout 240 detik yang sudah dibatasi. Snapshot terakhir membuktikan game hidup di interior, renderer aktif dan posisi `[284.42,326.34]` tersimpan. Tidak ada kesalahan JavaScript/console atau respons API gagal yang tercatat.

Bukti lokal: `Jalasmara-06-integration/artifacts/browser/plan06-layout-6174b6a2-be3c-47ab-a8ed-cb8e82e8a201/` memuat `home-porch-night-667x375.png`, `failure.png`, dan `results.json`. Kedua gambar diperiksa. Capture porch memperlihatkan Nala dapat dikenali di lantai Griya dan HUD malam berfungsi. Billboard abu-abu warga nonrig pada malam hari masih tampak dan tetap menjadi gap visual B3; gambar ini bukan persetujuan bahwa semua warga sudah selesai.

Cleanup run gagal tetap lulus: player/email/role/name fixture, receipts dan shifts UUID tersebut serta kunci cache/sesi yang diverifikasi sudah nol melalui assertion. Laporan menyatakan `ownTemporaryPlayerRemoved: true`. Browser ditutup. Tidak memakai SIGKILL, tidak menyentuh proses 3100 atau data akun lain.

Commit `b208942` memperbaiki predicate attach agar menerima renderer home yang aktif dan menambahkan progress fase/capture/states warga. Pemeriksaan sintaks lulus. Perbaikan ini hanya pada harness; tidak mengubah script atau paket game. **Tujuh shelter, hutan, laut dan penerimaan reload lengkap masih menunggu rerun yang berhasil.**

## Rerun kedua: 17 pemeriksaan lulus, batas harness tercapai

Pada source harness `9faa532`, PCK dan API yang sama, fixture `eb16cba0-1e9d-487b-84b2-c51d8bbadfed` menyelesaikan **17 pemeriksaan**: migrasi layout, Griya masuk/simpan/reload/keluar, tujuh warga tiba di shelter dan percakapan masing-masing, gerbang hutan, tajuk, heartbeat pause jurnal, joystick, proyeksi desktop, save/reload hutan, serta kedua jembatan. Tidak ada error JavaScript/console atau respons API gagal. Pukul 421.023 ms, harness berhenti karena batas tujuh menit saat perjalanan pulang dari jembatan bawah, pada `[1579.01,1073.75]`. Ini kegagalan anggaran harness, bukan collision atau transaksi game yang gagal. Cleanup UUID dan browser lulus.

Bukti: `Jalasmara-06-integration/artifacts/browser/plan06-layout-eb16cba0-1e9d-487b-84b2-c51d8bbadfed/results.json` dan capture tiap fase. Log lokal `/tmp/jalasmara-06b-layout-browser-rerun.log`. Capture percakapan membuktikan akses/interaksi; modal menutupi sebagian dunia sehingga ketertutupan tubuh oleh atap tetap perlu bukti renderer/native terpisah. Dialog malam pada layar pendek juga masih besar; pemeriksaan perbaikannya dimiliki jalur karakter/UI, bukan diubah pada QA ini.

Arahan integrator sesudah hasil ini: pertahankan 17 hasil parsial dan lanjutkan bagian yang belum teruji dengan **fixture UUID baru**. Mode `PLAN06_ROUTE_MODE=continuation` menyiapkan save awal di endpoint `bridge_lower` dari manifest saat itu, lokasi yang sudah dilewati pada kelompok pertama. Setelah game mulai, seluruh perjalanan hutan→portal→hub→selam→ekstraksi→reload tetap melalui input nyata. Tidak ada perubahan posisi/kalender/cuaca saat sesi berjalan. Mode ini dilaporkan sebagai kelompok fixture kedua, bukan satu perjalanan tanpa jeda. Rangkaian penuh tetap tersedia dengan batas sepuluh menit bila dibutuhkan.

```sh
PLAN06_ROUTE_MODE=continuation APP_TEST_ORIGIN=http://localhost:3101 \
PLAN06_EXPECT_PCK=7f2ac59f0e39bed9ad5d6e47f4836f76a097b89cc2dadf388514cfbd5d02eaf9 \
PLAN06_EXPECT_PCK_BYTES=64289088 \
node --import tsx scripts/plan06-layout-browser.mjs
```

Mode continuation dan transaksi malam masih **belum dijalankan** pada saat pembaruan ini. Perubahan hanya harness/dokumentasi; paket runtime tidak berubah.
