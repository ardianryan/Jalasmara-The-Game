# Penutupan QA untuk rilis runtime f319da9

9 November 2026. Branch `work/06-release-qa`, worktree `Jalasmara-06-release-qa`, baseline main `f319da9`. Ownership hanya tiga script QA dan laporan ini. Runtime/API/website/aset tidak berubah. Integrator menangani build/deployment dan handoff bersama.

## Persiapan yang selesai

- `night-home-browser.mjs` dan `staging-plan06-smoke.mjs` membaca `land.view.motion` aktual memakai consumer keyboard pulse yang sudah ada. Perjalanan memakai `physicalRoute` dan geometri manifest saat itu; interior rumah tetap memakai input dx/dy. Kontrol produk tidak diubah agar cocok harness.
- Kedua script wajib menerima `PLAN06_EXPECT_PCK` dan `PLAN06_EXPECT_PCK_BYTES`, mengunduh serta memeriksa SHA/byte sebelum fixture dibuat. Pin lama staging dihapus, tetapi origin HTTPS staging dan flag konfirmasi eksplisit tetap dipatok. Tidak ada SSH/fixture publik yang dijalankan pada tahap persiapan.
- Night memakai artifact UUID terpisah, budget delapan menit, progress fase serta cleanup dengan assertion nol pada player, receipt, shift, cache/sesi miliknya. Kredensial tidak dicetak atau disimpan dalam laporan.
- Mode `shelters` pada `plan06-layout-browser.mjs` menguji tujuh warga tiba secara alami pada shelter hujan malam, akses tiap percakapan dan resume, capture sebelum/saat dialog serta progres/reward tidak berubah. Mode `lower` memakai save awal forest sah pada pendekatan bridge lower, menyeberang melalui input nyata dan memeriksa save/reload. Kedua mode memakai UUID berbeda; tidak mengulang prefix rumah, migrasi atau jembatan atas yang sudah terbukti.

Pemeriksaan CPU aktual: syntax Node tiga script, Prettier, diff-check dan consumer test **4/4 PASS**. Guard pin wajib juga diuji dengan import terkendali: night menolak sebelum network/fixture, staging menolak sebelum network/SSH/fixture. Tidak ada browser/Godot/database mutation pada tahap tersebut.

## Paket lokal dan command

API production lokal `http://localhost:3101`, Mongo replica-set 27018, Redis6380. Runtime/PCK target **`5f2aaa46778d8735e7316b34d2865ad8ad40877d537d81b9a2dc1d31e8d69038` / 64.304.668 B**. Ketiga run berikut harus bergiliran dalam slot browser yang diberikan integrator.

```sh
VERIFY_COMPACT_NIGHT=1 APP_TEST_ORIGIN=http://localhost:3101 \
PLAN06_EXPECT_PCK=5f2aaa46778d8735e7316b34d2865ad8ad40877d537d81b9a2dc1d31e8d69038 \
PLAN06_EXPECT_PCK_BYTES=64304668 \
node --import tsx scripts/night-home-browser.mjs

PLAN06_ROUTE_MODE=shelters APP_TEST_ORIGIN=http://localhost:3101 \
PLAN06_EXPECT_PCK=5f2aaa46778d8735e7316b34d2865ad8ad40877d537d81b9a2dc1d31e8d69038 \
PLAN06_EXPECT_PCK_BYTES=64304668 \
node --import tsx scripts/plan06-layout-browser.mjs

PLAN06_ROUTE_MODE=lower APP_TEST_ORIGIN=http://localhost:3101 \
PLAN06_EXPECT_PCK=5f2aaa46778d8735e7316b34d2865ad8ad40877d537d81b9a2dc1d31e8d69038 \
PLAN06_EXPECT_PCK_BYTES=64304668 \
node --import tsx scripts/plan06-layout-browser.mjs
```

Status saat persiapan dicatat: **pengujian lokal baru belum dijalankan**. Setelah lokal selesai, public smoke memakai script staging yang diperbarui hanya setelah integrator benar-benar memasang rilis dan memberikan grant. Pin harus berasal dari paket yang hendak dirilis, bukan diasumsikan dari isi halaman.

## Batas

Playwright Chromium/SwiftShader dan CDP sentuh merupakan emulasi, bukan Windows/S23 fisik atau pengukuran FPS perangkat. Membuka percakapan tidak sendiri membuktikan seluruh tubuh/alat di bawah atap benar secara visual; capture sebelum dialog dan bukti native tetap ditinjau. Semua hasil gagal, cleanup serta pin/source berikutnya ditambahkan sebagai riwayat. Tidak menambah tool gambar, dependensi engine, atau atribusi upstream baru dalam paket QA ini.

## Night pertama: rute harness gagal sebelum transaksi

Run lokal pertama pada PCK5f membuat UUID `33c89b96-4262-4fae-bef2-d30afdeaf311`. Ia attach dan bergerak dengan 67 pulse matriks, lalu berhenti di `[1037.33,1031.84]` pada post serambi Tedi saat menuju waypoint `[600,950]`. Belum ada transaksi/check selesai; error JavaScript dan API gagal sama-sama nol. Cleanup assertion lulus. Bukti `artifacts/browser/night-home-33c89b96-4262-4fae-bef2-d30afdeaf311/failure.png` diperiksa; log `/tmp/jalasmara-06-release-night.log` dan results dipertahankan.

Pemeriksaan geometri actual-vs-authored: segmen ideal `[1120,1000]→[600,950]` sah, tetapi segmen dari posisi aktual yang berhenti terlalu dini tidak sah. Arrival15unit dapat memotong sudut dekat support saat melanjutkan segmen panjang; post runtime memang menahan pemain. Toleransi arrival pada daratan aktual diperketat menjadi5unit di ketiga harness, sedangkan interior/selam mempertahankan15. Produk/collider tidak diubah. Night juga menyimpan diagnostics tiap capture agar kegagalan berikutnya dapat diperiksa. Pengulangan belum dianggap lulus sampai dijalankan.

## Koreksi kedua pada pengendali QA

Rerun night dengan arrival5 masih berhenti sebelum transaksi, UUID `822226a2-1a6b-496d-babf-da54c00d8f4d`, pada `[1039.25,1014.61]`; 0 error/0 API gagal dan cleanup lulus. Diagnosis sebelumnya belum lengkap. Diagnostics matriks membuktikan consumer memilih input digital `[a,s]` untuk target jauh `[-439,-65]`, dengan arah logis `[-0.988,+0.154]`. Pilihan heading terdekat dapat menyimpang ke samping sepanjang segmen panjang sebelum bearing target cukup berubah untuk memilih tombol lain. Batas drift tiap pulse tidak membatasi drift kumulatif koridor.

Ketiga harness sekarang membagi segmen menjadi target absolut berjarak maksimal24unit sebelum mengirim pulse. Target tetap berada pada segmen manifest yang sah; tidak ada teleport/penulisan posisi, pelebaran collider atau perubahan kontrol produk. Arrival5 tetap dipakai pada daratan. Gambar dan diagnostics kedua failure disimpan, bukan disebut bug game tanpa bukti. Rerun baru masih diperlukan.

Subdivision dipindahkan ke `corridorTargets` pada consumer `land-view-navigation.mjs` agar ketiga harness memakai fungsi yang sama. Regression CPU memakai segmen Tedi aktual `[1120,1000]→[600,950]`, matriks renderer kiri dari failure, keputusan delapan tombol, jarak pulse nominal dan clearance post12unit. Jalur greedy lama menyimpang34,756unit dan menyentuh area post; target absolut24unit membatasi deviasi3,381unit serta menghindari post, dengan endpoint<5unit. Consumer test kini **5/5 PASS**, termasuk kasus penolakan spacing invalid dan batas langkah. Tes masuk job verify yang memang menjalankan `scripts/land-view-navigation.test.mjs`; hasil CI baru tetap milik integrator. Simulasi ini menguji kendali QA nominal, bukan mengganti Godot physics/browser atau mengukur FPS.

## Night lengkap: fungsi selesai, satu409 memblokir penerimaan bersih

Run corridor UUID `4907b0a6-2634-47fd-8dac-22d63211d269` mencapai **7 pemeriksaan fungsional/8 transaksi**: tiga layanan dan bonus, close pending hari1, dialog/HUD667/390 serta tas/pause, masuk Griya, tidur→hari2, keluar dan reload. Koin525/version7 tersimpan. Namun assertion akhir **gagal**, karena satu `POST /api/adventure/surface-position`409 dan satu console resource error. Ini tidak disebut clean PASS. Cleanup lulus/browser ditutup; slot dilepas untuk pemeriksaan Nala/alpha integrator, tanpa memulai dua mode sisa.

Bukti: `artifacts/browser/night-home-4907b0a6-2634-47fd-8dac-22d63211d269/results.json`, capture layanan/tidur/reload/failure, log `/tmp/jalasmara-06-release-night-corridor.log`. Trace lama hanya menyimpan path/status respons gagal, sehingga code/versi request/waktu tepat409 **tidak dapat direkonstruksi** setelah cleanup. Urutan operasi yang diketahui: kedai start→serve×3→close-shift→home enter→sleep→exit. Ini belum membuktikan409 terjadi pada salah satu transisi tertentu. Integrator memiliki source fix/runtime tests; QA tidak mengabaikan409 atau menambal produksi.

Harness ditambah trace minimal terurut untuk request/response gameplay yang diizinkan: timestamp, phase, method/path, action, request version/fromPositionAt/revision/posisi/jumlahtitik, status/code/error string, versi player/surface, home revision/inside dan waktu selesai/abort. Login/cookie/header/password/world/catalog tidak dicatat. Trace membedakan ACK terlambat dan request yang dibatalkan saat reload.

Mode `NIGHT_HOME_ONLY=1` juga disiapkan: UUID baru dimulai pada pintu Griya dari manifest dengan state valid sesudah shift ditutup (pending story day1, versi4, hasil/stok sesuai fixture). Ia hanya menguji enter→sleep→exit→reload dan tidak mengklaim menutup shift melalui gameplay pada fixture ini. Kalender/camera/posisi tidak diubah setelah game dimulai. SHA/byte tetap diperiksa sebelum fixture/cache dibuat. Mode penuh dengan trace masih tersedia bila konflik berasal dari fase kedai. Belum ada rerun baru; menunggu grant setelah native lanes. Public release belum diaktifkan oleh hasil QA ini.

## Trace rumah terpisah

Fixture `4eb1312e-6967-4948-8d25-c6cc9f2e181e`, PCK5f yang sama: **2 checks/3 aksi, 0 console error/0 API gagal, cleanup lulus**. Trace enter200 memberi versi5, sleep200 versi6, exit200 versi7; request surface sebelum enter memakai versi4 dan mendapat200. Bukti `artifacts/browser/night-home-4eb1312e-6967-4948-8d25-c6cc9f2e181e/results.json`, log `/tmp/jalasmara-06-release-home-trace.log`. Hasil bersih satu fixture rumah tidak membatalkan409 alur penuh sebelumnya.

Pengulangan penuh kemudian menunggu renderer darat `land.active` beserta `view.motion`, lalu3,5detik tanpa gerak sesudah keluar rumah sebelum reload. Snapshot area/inside saja dapat tersedia sebelum scene daratan menyelesaikan inisialisasi; jeda ini memberi waktu dua interval penyimpanan dan tidak menyembunyikan konflik yang terjadi. Trace tetap mencatat seluruh request gagal/abort. Rerun penuh masih berjalan; belum ada hasil penerimaan baru.

## Pengulangan penuh dengan trace: bersih,409 lama belum terjelaskan

UUID `dc834487-6fdc-4351-b490-c6644e79719e` selesai dengan **7 checks/8 transaksi, 0 console error/0 API gagal/0 HTTP409**, 319 pulse matriks dan20 pulse interior, waktu rute314.834ms. PCK5f tidak berubah. Cleanup assertion lulus dan browser ditutup, lalu slot dikembalikan ke integrator tanpa menjalankan mode lower/shelters. Bukti: `artifacts/browser/night-home-dc834487-6fdc-4351-b490-c6644e79719e/results.json`, sepuluh capture fase/HUD/tas/tidur/reload, log `/tmp/jalasmara-06-release-night-exact-trace.log`.

Trace236baris menyimpan urutan aktual: start200; serve200→versi1,2,3; close200→versi4/pending1; enter200→versi5/revision3; sleep200→versi6/revision5; exit200→versi7/revision6/surface base `1794221552080`; heartbeat200; GET state sesudah exit200→versi7/base sama; GET sesudah reload200→versi7/base sama. Request exit dikirim `1794221551997` dan respons diterima `1794221552967`; GET state berikutnya dikirim `1794221553725`, respons `1794221555400`; GET sesudah reload dikirim `1794221565774`, respons `1794221565850`. Tidak ada POST surface-position sesudah enter/exit pada fixture yang berdiri diam ini; semua POST sebelum enter mendapat200.

Pengulangan bersih tersebut **tidak merekonstruksi code/request-version/waktu409 lama**, sehingga penyebab konflik belum terbukti dan status historis gagal tetap berlaku. Root memegang investigasi runtime. Untuk uji berikutnya, handler sekarang mencetak metadata gagal yang sudah dibatasi allowlist segera saat respons diterima, tanpa menunggu cleanup. Perubahan log ini ditulis saat run penuh sedang berjalan sehingga belum menjadi bukti live-output pada run tersebut. Tidak ada patch produk atau public deployment dari lane ini.
