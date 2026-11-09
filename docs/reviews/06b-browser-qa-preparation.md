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

## Continuation actual-game: alur selesai, satu konflik sinkronisasi ditemukan

Mode continuation dijalankan pada integrasi `75e2dc2`, runtime `e1bdf95`, PCK **`7f2ac59f0e39bed9ad5d6e47f4836f76a097b89cc2dadf388514cfbd5d02eaf9` / 64.289.088 B**, API lokal production 3101. Fixture baru `28725b49-5e35-4088-a2ae-614ad838a4bb` mulai di endpoint bridge bawah `[1620,1080]` lalu berjalan memakai input nyata. **Tiga pemeriksaan fungsional selesai** dalam **151.206 ms**: posisi awal sesuai manifest final, perjalanan portal hutan→hub dengan progres/uang tetap, serta masuk laut→joystick portrait `touchCancel`→tas/pause→ekstraksi→hub→save/reload. Ini kelompok fixture kedua, terpisah dari 17 pemeriksaan prefix yang sudah lulus.

Penerimaan bersih **tetap gagal**: sesudah `POST /api/dive/extract` 200, satu `POST /api/adventure/surface-position` mendapat **409** dan browser mencatat satu resource error. Assertion `errors == []` menghentikan run setelah reload akhir, walaupun posisi hub `[1485,1290]`, cerita day 2/night, koin 200, dan inventori kosong semuanya benar. Kegagalan ini tidak dihapus atau diabaikan.

Diagnosis source yang dikirim ke integrator: `Main.gd::_extract` mengosongkan `GameState.dive` dan menghapus `network_busy` sebelum `await GameState.refresh()` selesai; timer `_sync_surface` dapat berjalan pada celah ini sebelum player version/posisi darat diperbarui. API menolak versi atau posisi awal lama dengan 409. Log saat ini menyimpan path/status, belum body/code respons atau request version, jadi penyebab persis **masih inferensi source**, bukan bukti respons `SESSION_CHANGED` yang sudah direkam. Integrator perlu memperbaiki/menilai race dan menguji ulang bagian ekstraksi, tanpa melonggarkan assertion API.

Bukti: `Jalasmara-06-integration/artifacts/browser/plan06-layout-28725b49-5e35-4088-a2ae-614ad838a4bb/results.json`, lima capture fase ditambah failure, dan `/tmp/jalasmara-06b-layout-continuation.log`. Capture tas portrait dan hub sesudah kembali diperiksa. Browser ditutup; cleanup scoped player/email/role/name, receipts, shifts, Redis posisi/rumah/kalender/dive dan sesi pemilik lulus `ownTemporaryPlayerRemoved: true`.

## Transaksi malam dan Griya: lulus pada paket yang sama

Sesudah continuation selesai dan browsernya ditutup, `VERIFY_COMPACT_NIGHT=1 APP_TEST_ORIGIN=http://localhost:3101 node --import tsx scripts/night-home-browser.mjs` dijalankan pada integrasi/PCK yang sama. **Exit 0: 7 checks, 8 transaksi POST, 0 error JavaScript/console, 0 respons API gagal.**

Yang terbukti: bahan kangkung+fragmen dikonsumsi dengan bonus 5, seluruh pesanan day 1 dilayani, penutupan kedai menyimpan pending advance tanpa langsung mengubah hari cerita, dialog dan HUD/bag responsif dengan safe area 667×375 dan 390×844, tas melepas input gerak serta pause, rute pintu Griya dapat dicapai, tidur mengubah kalender menjadi day 2 pukul 06.00 serta cerita menjadi day 2/dive, lalu keluar/reload mempertahankan hasil. Koin akhir 525 dan stok kangkung habis sesuai operasi; tidak ada hadiah dari navigasi. Fixture ini memakai appearance `male_default` milik harness lama, sehingga hasil tidak menggantikan penilaian natural walking rig Nala terbaru.

Bukti lokal: `Jalasmara-06-integration/artifacts/godot/night-home/results.json`, sepuluh PNG fase layanan/dialog/HUD/tas/tidur/reload, dan `/tmp/jalasmara-06b-night-home.log`. Gambar gameplay malam 667, pesan tidur dan reload pagi diperiksa. UI gameplay tengah tetap tersedia; modal tas/dialog memang menutupi sebagian besar viewport, dan review ringkas dialog yang dimiliki jalur UI masih perlu ditindaklanjuti. Ini bukan persetujuan visual semua modal/rumah/NPC.

UUID fixture malam `71549acf-05b1-4206-8a0e-a38e8095f5b1` sudah dibersihkan. Verifikasi read-only tambahan sesudah exit membuktikan **players 0, receipts 0, shifts 0, empat kunci Redis bernama 0**. Harness juga menghapus key auth dari cookie sesi lokalnya; pemeriksaan tambahan tidak memindai sesi akun lain. Browser ditutup dan slot engine/browser dilepas ke integrator.

Tool aktual untuk kedua run: Node 26.12.1, Playwright Chromium/SwiftShader, CDP touch, keyboard sintetis, Fastify/MongoDB/Redis lokal, Godot Web melalui PCK terpin, filesystem/Git dan image viewer. Tidak memakai Godot native, generator gambar, Sprite AI, API berbayar atau aset upstream tambahan pada paket QA ini. Tidak ada sumber runtime/website produksi/API yang diubah oleh lane ini.

**Sisa berikutnya:** integrator menangani konflik sesudah ekstraksi dan export/checkpoint terkait; QA mengulang subset laut pada PCK baru yang terpin bila runtime berubah. Prefix 17 dan transaksi malam 7 tetap bukti sah untuk paket lama yang dicatat di atas, bukan otomatis hasil export baru. Billboard nonrig, dialog terlalu besar, camera kiri gameplay global, comfy warna malam, serta perangkat Windows/S23 fisik tetap belum ditutup. Belum ada klaim kandidat ini sudah dirilis ke staging.

## Persiapan subset laut untuk menguji koreksi konflik

Mode `PLAN06_ROUTE_MODE=ocean` ditambahkan sesudah konflik di atas agar pengulangan tidak mengulang perjalanan hutan yang sudah terbukti. Ia memakai UUID baru dan save awal di `world.surfaceSpawn` hub yang sah, lalu tetap berjalan ke tangga, masuk, menguji joystick portrait/cancel/tas, keluar lewat ekstraksi dan reload melalui UI. Posisi tidak diubah setelah gameplay mulai. Pin PCK unduhan tetap wajib. Respons API gagal sekarang menyimpan code/error dan request version/base position, tanpa cookie/password, agar diagnosis berikutnya tidak hanya mengandalkan status409. Probe menunggu 2,5 detik setelah save hub sebelum reload supaya timer posisi sesudah ekstraksi ikut teramati, serta menambah capture laut tanpa modal.

Sintaks, format dan geometri awal diperiksa secara CPU; subset ini **belum dijalankan** pada saat pembaruan. Menunggu integrator menyediakan PCK koreksi dan grant browser. Command sama dengan continuation, ganti `PLAN06_ROUTE_MODE=ocean` serta SHA/byte kandidat baru yang benar.

Mode tambahan `PLAN06_ROUTE_MODE=dialogue` memakai UUID terpisah dengan cerita day 1/dive dan kalender server malam day 2. Pemisahan ini membuka dua kalimat authored Mbah Wira yang nyata, tanpa menulis teks lewat debug: paragraf Mbah Wira lalu jawaban pendek Nala. Pemain berjalan dari spawn ke kedai, menekan interaksi, menguji panel landscape 667×375 (paragraf ≤42%, pendek ≤34%), portrait, pause, reveal tanpa mengubah tinggi, lalu melanjutkan sampai gameplay kembali. Hari cerita/koin/inventori harus tetap. Ini persiapan CPU untuk PCK baru, belum bukti browser. Tidak mengubah source produksi atau mengarang dialog fixture.

Penguatan subset laut: setelah ekstraksi, pemain harus berjalan melalui rute dek sah sejauh sekitar 60 unit, menunggu posisi disimpan, dan membuktikan POST posisi 200 membawa versi yang sama dengan `extract.player.version`. Respons posisi dan API state harus mengakui versi tersebut sebelum reload. Ini menguji request berikutnya yang dahulu konflik409; diam di dock saja tidak cukup. Perubahan hanya harness dan belum dinilai sebagai hasil run sebelum log/capture tersedia.

## PCK koreksi: laut bersih dan dialog aktual lulus

Paket stabil berikutnya dipatok SHA-256 **`26b83efe7c3e0658a98f4c0a2603df179e30d1295bb8b4629aaa2d836b1cc4b2` / 64.290.960 B**, dilayani API/dist lokal 3101. Runtime memuat koreksi ekstraksi `a1add52` dan dialog ringkas `017b0b4`. Ocean awal dan dialog diluncurkan dari source integrasi `2262bae`; run ACK memakai harness `b9701d0`. Commit kamera kiri yang digabung ke source saat pengujian tidak diekspor/dilayani ke browser pada ketiga run ini. Hasil di bawah **bukan** penerimaan kamera kiri atau HUD portrait koreksi berikutnya.

- Ocean awal UUID `f695ff9d-ab78-4f4b-aa38-1519d35e1aee`: exit 0, **2 checks**, 46.505 ms setelah attach, 0 error JavaScript/console dan 0 API gagal/409. Tas/pause, joystick portrait/cancel, ekstraksi dan hub reload lulus. Pemeriksaan tambahan menemukan semua 7 request posisi terjadi sebelum ekstraksi karena pemain diam setelah pulang. Bukti ini saja belum cukup membuktikan request posisi memakai versi baru.
- Ocean yang diperkuat UUID `c4779e96-26a9-4717-90fd-da9ee79da58b`: exit 0, **3 checks**, 61.658 ms, 11 request posisi, **0 error dan 0 API gagal/409**. Setelah ekstraksi versi 1, dua POST posisi 200 membawa `requestVersion: 1` dan mendapat `surface.playerVersion: 1`. Pemain benar-benar berjalan dari `[1485,1290]` ke `[1438.53,1290]`; save dan reload mempertahankan posisi baru, cerita day 2/night, koin 200 dan inventori kosong. Ini membuktikan jalur request berikutnya yang sebelumnya konflik, tanpa mock atau pengabaian status409.
- Dialog UUID `5822cc1a-1554-4702-876e-7bc7ea11468c`: exit 0, **4 checks** termasuk spawn, 33.271 ms, 0 error dan 0 API gagal/409. Percakapan authored Mbah Wira/Nala dibuka lewat interaksi nyata pada 667×375. Logical viewport 960×540; paragraf 144 karakter setinggi 214 (39,63%), jawaban pendek 54 karakter setinggi 180 (33,33%). Portrait dan pause aktif, reveal tidak mengubah tinggi, kemudian dialog ditutup dan dunia berjalan tanpa perubahan hari cerita/koin/inventori. Paragraf menampilkan dua baris utuh dengan scrollbar untuk sisa; screenshot bukan klaim seluruh 144 karakter tampil sekaligus. Pengujian ini tidak melakukan scroll paragraf sampai akhir.

Semua UUID dibersihkan dengan assertion player/receipts/shifts/kunci Redis dan sesi pemilik; `ownTemporaryPlayerRemoved: true` pada setiap hasil. Semua browser ditutup, slot dilepas. Tool tetap Chromium/SwiftShader/CDP emulasi, API dan database lokal, bukan Windows/S23 fisik atau benchmark FPS.

Bukti di worktree integrasi:

- `artifacts/browser/plan06-layout-c4779e96-26a9-4717-90fd-da9ee79da58b/results.json`, `post-extraction-dock-move-saved-with-new-version.png`, `final-hub-save-reload-after-empty-dive.png`; log `/tmp/jalasmara-06b-ocean-version-ack.log`.
- `artifacts/browser/plan06-layout-5822cc1a-1554-4702-876e-7bc7ea11468c/results.json`, `actual-dialogue-paragraph-667x375.png`, `actual-dialogue-short-667x375.png`; log `/tmp/jalasmara-06b-dialogue-fixed.log`. Kedua gambar dialog diperiksa.
- `artifacts/browser/plan06-layout-f695ff9d-ab78-4f4b-aa38-1519d35e1aee/ocean-night-portrait-joystick-cancelled.png`; log `/tmp/jalasmara-06b-ocean-fixed.log`. Gambar laut tanpa modal diperiksa dan menemukan **teks O2/max/depth/beban bertumpuk pada panel portrait390**. Ini gap produk yang nyata dan sudah dikirim kepada integrator serta pemilik HUD, bukan ditutup oleh hasil fungsional laut.

Sisa: jalur karakter/HUD menangani overlap portrait; integrator menyelesaikan kamera kiri, fullworld/native/export dan pin baru; QA mengadaptasi helper input ke consumer `snapshot.land.view.motion` sebelum menguji browser kiri. Helper WASD lama memakai dx/dy dunia dan hanya sah untuk paket azimut0 yang diuji di atas. Perbaikan kontrol produksi tidak boleh dibatalkan untuk menyesuaikan harness. Rilis publik belum diklaim.

## Persiapan browser kamera kiri dan koreksi warning CI

Sesudah pengujian paket stabil di atas, source kamera kiri global dan consumer `scripts/land-view-navigation.mjs` digabung. Harness kini membaca `snapshot.land.view.motion` pada daratan aktif untuk memilih tombol serta durasi pulse/release; matriks datang dari renderer aktual setiap langkah, bukan azimut yang direkonstruksi atau kontrol produk yang diubah. Interior dan penyelaman mempertahankan gerak dx/dy lama. Statistik `navigation` membedakan pulse matriks/legacy. Mode kiri menolak contract hilang, sehingga tidak diam-diam memakai kontrol lama pada paket salah.

Mode `PLAN06_ROUTE_MODE=left` dibatasi **lima menit** sesudah attach. UUID baru mulai di spawn hub sah, lalu menguji tampilan azimut−45/elevasi35, keyboard screen-right, berjalan ke gerbang melalui rute, masuk forest melalui aksi nyata, joystick screen-right/release pada clearing, menyeberangi bridge upper, serta save/reload forest. Gerak diuji dengan proyeksi delta aktual memakai matriks renderer. Cerita day 2, koin 200, inventori kosong dan jam server 36 menit harus tetap. Mode ini tidak mengulang tur tujuh shelter atau menguji laut; laut/HUD portrait memerlukan subset ocean terpisah pada PCK baru.

Pemeriksaan CPU aktual: consumer test **4/4 PASS**, sintaks Node, Prettier dan diff-check PASS; geometri rute 15 waypoint hub, 4 pendekatan clearing, 5 pendekatan bridge, deck/ruang input touch sah terhadap manifest. Ini belum bukti browser/renderer/input kiri. Menunggu fullworld/native/export/pin baru dan slot integrator. Command sama, ganti `PLAN06_ROUTE_MODE=left` dan pin SHA/byte yang benar.

Warning SARIF `js/useless-assignment-to-local` pada `verifyCompactDialogue` turut diperbaiki: wait awal dilakukan tanpa menyimpan nilai yang langsung ditimpa; `current` hanya dideklarasikan di dalam loop saat dipakai. Tidak ada suppression atau perubahan perilaku dialog. Empat job pipeline yang hijau sebelumnya tidak berarti SARIF nol; hasil scan baru tetap menunggu CI integrator.

## Pengujian awal paket kiri/HUD gabungan

PCK baru **`5f2aaa46778d8735e7316b34d2865ad8ad40877d537d81b9a2dc1d31e8d69038` / 64.304.668 B** disajikan API/dist 3101 sesudah fullworld/native integrator. Mode left dari harness `870b1b2` lulus: **4 checks, 84 sync posisi, 0 error, 0 API gagal/409**, 144.556 ms setelah attach. Fixture `c517d448-32ed-4677-9db8-fbe0ef2b1855` memakai 204 pulse matriks dan 0 pulse legacy. Delta proyeksi keyboard `[47.0244,0.00016]`, joystick `[47.1770,0.00052]`, keduanya screen-right pada azimut−45. Gerbang, bridge upper, save/reload forest `[1600.13,645.99]`, progres/koin/inventori dan kalender36menit lulus. Cleanup/browser tutup lulus. Gambar hub667, forest touch dan bridge kiri diperiksa; natural walking penuh/perangkat fisik tetap bukan cakupan still image.

Bukti: `Jalasmara-06-integration/artifacts/browser/plan06-layout-c517d448-32ed-4677-9db8-fbe0ef2b1855/results.json` dan `/tmp/jalasmara-06b-left-gameplay.log`.

Ocean UUID `35b9b710-f362-4308-af3c-a7dc08451b6c` pada paket sama lalu **gagal pada pemeriksaan ledger harness**, sesudah ekstraksi dan langkah dek berhasil. API state sudah mengakui versi1/posisi baru, tetapi callback async Playwright belum memasukkan respons ke array dalam jeda250ms. Hasil yang ditulis sesudah capture failure memuat dua ACK200 versi1, termasuk posisi `[1426.07,1299.46]`, dengan 0 error dan 0 API gagal/409. Cleanup tetap lulus. Jeda tetap diganti bounded wait maksimal10detik untuk ACK aktual; syarat status200/versi/posisi tidak diubah. Rerun subset laut masih menunggu pada saat pembaruan ini. Bukti failure dan log `/tmp/jalasmara-06b-left-hud-ocean.log` dipertahankan, tidak dihapus sebagai hasil lulus.

## Penerimaan laut/HUD pada PCK kiri yang sama: rerun lulus

Sesudah koreksi ledger `26b53ae`, hanya subset ocean diulang pada **PCK `5f2aaa46778d8735e7316b34d2865ad8ad40877d537d81b9a2dc1d31e8d69038` / 64.304.668 B**, API/dist localhost3101 yang sama. Mode left sebelumnya tidak diulang karena perubahan hanya menunggu callback ACK. Fixture baru `cd315799-f2a1-40fa-921b-4f02dd1b0695` **exit 0: 3 checks, 11 sinkronisasi posisi, 0 error JavaScript/console, 0 API gagal/409**, 57.952 ms setelah attach. Navigasi hub memakai 29 pulse matriks renderer. Dua POST posisi sesudah ekstraksi membawa request version1 dan mendapat surface playerVersion1, termasuk `[1430.9004,1289.7755]`. Save/reload mengembalikan posisi tersebut; hari cerita 2/night, koin 200, inventori kosong tetap.

Capture aktual portrait390 tanpa modal diperiksa: nilai O2 dan maksimum berada pada satu baris, gauge pada baris sendiri, Kedalaman `2 m` serta Tas `0.0/12.0 kg` berada pada dua kolom bawah. Teks berada di dalam bingkai, sedangkan joystick serta tombol aksi tetap terpisah. Bukti browser ini menilai tampilan fixture saat O2 penuh/tas kosong; skenario nilai ekstrem/loss dan ukuran font/persilangan kontrol diukur oleh tes native HUD pemilik komponen, bukan diklaim dari PNG saja. Gambar hub667 sesudah reload juga diperiksa dan menunjukkan dek kiri 3/4 aktual.

Bukti lokal final: `Jalasmara-06-integration/artifacts/browser/plan06-layout-cd315799-f2a1-40fa-921b-4f02dd1b0695/results.json`, `ocean-night-portrait-joystick-cancelled.png`, `post-extraction-dock-move-saved-with-new-version.png`, dan `final-hub-save-reload-after-empty-dive.png`; log `/tmp/jalasmara-06b-left-hud-ocean-rerun.log`. Hasil gagal ledger UUID35b9 tetap disimpan sebagai riwayat, tidak ditulis ulang menjadi lulus.

Cleanup assertion lulus untuk seluruh data/kunci UUID sendiri dan sesi pemilik: `ownTemporaryPlayerRemoved: true`. Browser ditutup dan slot engine/browser dilepas ke integrator sesudah peninjauan PNG. Pekerjaan lane ini tetap harness/dokumentasi; tidak mengubah runtime/API/ekonomi atau data akun lain.

Paket ini mempunyai **dua kelompok fixture final**: left4 (UUIDc517) dan ocean3 (UUIDcd315). Jangan menjumlahkannya dengan prefix17/malam7/dialog4 pada PCK lebih lama menjadi satu perjalanan tanpa jeda atau satu penerimaan seluruh rencana. Dialog aktual667 sudah lulus pada26b; source presenter tidak berubah pada5f, sementara tampilan portrait HUD sudah diperiksa langsung pada5f. Runtime kaki/alat/shelter/camera masih perlu dinilai bersama bukti native dan review integrator. Perangkat Windows/S23 fisik, sesi panjang dan pemolesan visual lanjutan tetap terbuka. CI/SARIF baru, backup, deployment dan smoke staging dimiliki integrator; hasil lokal ini belum berarti rilis publik.
