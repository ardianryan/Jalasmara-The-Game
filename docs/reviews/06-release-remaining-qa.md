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

## Persiapan QA berikutnya, CPU saja

Mode home-only selanjutnya benar-benar berjalan45unit ke sisi pintu sesudah exit, memakai `physicalRoute` dan input matriks. Ia wajib menerima POST surface200 dengan request/response versi yang dikembalikan aksi exit, posisi<15unit dari titik aktual, lalu reload pada titik tersebut. Berdiri diam dan GET state saja tidak dihitung sebagai bukti ACK pergerakan. Batas15detik memberi ruang respons ledger terlambat tanpa mengabaikan respons gagal. Tambahan ini belum dijalankan; integrator sedang memegang slot engine untuk paket berikutnya.

Lower/shelters dan staging sekarang memakai pencatat kegagalan bersama `gameplay-api-failure.mjs`. Respons API gagal segera mencetak path/method/status/timestamp, serta hanya untuk endpoint gameplay: code, request version/base/revision, posisi dan lintasan numerik maksimal64titik sesuai batas API, versi response bila tersedia. Auth/login/akun/admin tidak pernah dibaca body-nya. Night tetap menyimpan trace urutan lengkap dan kini menyimpan lintasan numerik yang sama. Tiga tes sanitizer membuktikan bukti versi/lintasan terjaga, field credential tidak tersalin, endpoint auth dikecualikan, dan path malformed dibatasi. Tes consumer5 + sanitizer3 **8/8 PASS lokal**; syntax ketiga harness/helper dan diff-check lulus. Job CI lama hanya menjalankan consumer; hasil sanitizer lokal ini tidak disebut sebagai hasil CI baru. Belum ada browser baru, fixture publik atau perubahan produksi.

## Kandidat592: lower selesai, shelter wait diperbaiki

Kandidat baru source runtime `fc0d563`, PCK **`592dc75ba391302aff22fce0f1c3c31d2d894ed46df52e6eb1f90c4917545b2b` /64.307.052 B**, API3101 dari main. Root menyatakan tidak ada patch Main berdasarkan dugaan409; QA memeriksa paket baru dengan pin/byte tersebut.

Lower UUID `c1f1279f-ff03-4f60-8677-d940384485a9`: **2 checks PASS,0 console/0 API gagal/0 HTTP409,cleanup lulus**, 27pulse matriks/0legacy,12sinkronisasi surface,25.807ms. Input nyata melintasi `[1310,1080]→[1618.5153,1076.5199]`, mesh jembatan oriented/rail/thickness benar menurut diagnostics dan posisi yang sama kembali setelah reload; progres/koin/inventori/kalender36menit tetap. Screenshot crossing ditinjau. Bukti `artifacts/browser/plan06-layout-c1f1279f-ff03-4f60-8677-d940384485a9`, log `/tmp/jalasmara-06-release-lower.log`.

Shelter UUID `bee2be92-7c41-41ec-a40c-0cad05d436ab` gagal pada wait160detik, bukan API:6warga sudah `shelter/atStation`, Mang Ujang tetap `walking_shelter`,movingfalse,blockedSeconds0,destination1424/1260. Cuaca server sah rain0,55/nighttrue/jam20:18;0console/0APIgagal,cleanup lulus,164.109ms. Pemain masih di spawn1120/1230, hanya92unit dari posisi rest Ujang1210/1250. Source `_activity_update` memang berhenti bila pemain nearby; menunggu diam di sana menghalangi tujuan tes. Runtime tidak diubah.

Percobaan quietpoint1000/1200, UUID `bffa9e22-2c33-4758-a022-e106db402979`, ditolak `physicalRoute` karena target bukan lantai;0pulse/0APIgagal/cleanup lulus. Kedua kegagalan/results/capture dipertahankan. Pilihan berikutnya diuji CPU sebelum browser:800/1000 sah `isLandWalkable`, route dari spawn sah, jarak minimum dari work/rest/shelter/posisi awal ketujuh warga182,483unit. Preflight tersebut kini menjadi assertion sebelum fixture/browser dan diperiksa ulang memakai world API aktual. Pemain tetap berjalan memakai input nyata; tidak ada teleport, penghapusan collider atau perubahan perilaku NPC. Pengulangan belum dinyatakan selesai pada saat bagian ini ditulis.

## Shelter parsial: Lurah tertutup prioritas papan izin

UUID `291db231-c58a-41a0-ad4c-0be759386cec` benar-benar berjalan ke quietpoint `[800.2717,995.6655]`. Ketujuh warga kemudian sudah `shelter/atStationtrue/movingfalse` pada jam19:15. Dialog Bu Darmi `[1364.7936,277.8700]` dan Yu Sari `[1303.1558,302.7666]` berhasil dibuka serta ditutup dengan resume/pause benar. Namun run berhenti pada Ki Lurah: pemain `[943.7274,310.5105]` mempunyai `nearby="balai"`, sementara destination Lurah940/310 dan statusnya sudah shelter. `Main._find_nearby` memilih objek terdekat; papan izin juga berada940/310 dan bersaing dengan posisi aktual NPC yang berhenti dalam2unit dari station. Ini masalah jangkauan/prioritas interaksi, bukan collision atau respons API.

Hasilnya **4 checks parsial,0 console/0 API gagal/cleanup lulus**,352.433ms. Koordinat aktual NPC Lurah tidak tersedia pada diagnostics; destination/atStation tidak disebut sebagai posisi numerik pasti NPC. Runtime fix tetap ownership root. Bukti `artifacts/browser/plan06-layout-291db231-c58a-41a0-ad4c-0be759386cec/results.json`, capture Darmi/Sari sebelum/saat dialog dan failure, log `/tmp/jalasmara-06-release-shelters-clearance.log`. Saras/Ratih/Tedi/Ujang belum diuji percakapannya pada paket592. Kegagalan ini tidak diubah menjadi PASS hanya karena API bersih.

Harness memiliki `PLAN06_SHELTER_PREDECESSOR=<UUID>` untuk melanjutkan hanya dialog yang belum lulus pada fixture baru. Ia membaca report lokal UUID yang sudah cleanup, memeriksa origin/hash/byte/mode/arrival7 serta quietpoint yang benar-benar pernah dicapai, lalu memulai save fixture baru pada titik tersebut. Hanya initial fixture yang disiapkan; setelah game berjalan seluruh pergerakan tetap input nyata. Report memuat predecessor/koordinat/nama yang sudah selesai dan pengujian tetap menunggu7warga secara alami. Tidak mengulang prefix Darmi/Sari atau mengubah runtime untuk memaksa test. Continuation ini baru disiapkan CPU dan belum dijalankan; pin predecessor wajib sama dengan kandidat saat ini.

## Rumah592: pergerakan setelah keluar mendapat ACK dan reload

UUID `c043d235-b2cf-4715-842f-bbb13d824e4d`, mode home-only: **4 checks/3aksi PASS,0 console/0 API gagal/0 HTTP409,cleanup lulus**,54.159ms,24pulse matriks/23interior. Enter/sleep/exit memakai UI permainan dan exit memberi versi7/base `1794222874255`. POST pertama sesudah gerak mengirim versi7/base tersebut dan mendapat200/versi7/base baru `1794222883911`; seluruh10 POST sesudah exit mendapat200 dengan rantai base berurutan dan versi7. Capture sesudah gerak `[204.1939,617.6207]`, posisi ACK terakhir/reload `[215.7598,610.9868]`; keduanya dalam toleransi15unit tes, bukan bit-exact. Progres hari2/dive, kalenderpagi dan pantry/pending tetap benar sesudah reload.

Bukti `artifacts/browser/night-home-c043d235-b2cf-4715-842f-bbb13d824e4d/results.json` berisi lintasan numerik dan trace, log `/tmp/jalasmara-06-release-home-move-ack.log`. Browser ditutup, semua fixture hanya miliknya dibersihkan dan slot dilepas kepada integrator setelah hasil ini. Bukti baru menguji persistence secara langsung, tetapi code/waktu409 historis tetap tidak diketahui. Public deployment/smoke belum dilakukan oleh lane ini.
