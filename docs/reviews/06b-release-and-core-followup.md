# Penutupan rilis 06-B dan perbaikan inti berikutnya

9 November 2026. Pengguna meminta melanjutkan urutan rilis, finishing visual/karakter dan performa. Integrator menangani rilis; tiga worktree terpisah menangani QA, alpha NPC dan transisi langkah Nala. **Status awal laporan: image siap, belum diaktifkan ke staging.**

## Paket rilis yang dibekukan

- Source runtime: `f319da94b0358ee7de47a4ec7670f098ee065f23`. Commit QA/dokumentasi sesudahnya tidak mengubah runtime paket ini.
- PCK yang diuji lokal dan dimasukkan image: `5f2aaa46778d8735e7316b34d2865ad8ad40877d537d81b9a2dc1d31e8d69038`,64.304.668 byte.
- Image siap: `jalasmara:06b-f319da9`, ID `sha256:a9e577c8062b4895c429f9ae035389db6e7f19e6fdc49ef27deab84b33077968`. Dibangun pada VPS dari direktori terpisah `/opt/jalasmara-releases/06b-f319da9`; aplikasi lama tetap berjalan selama build.
- Arsip source+export: SHA256 `ba01a6f869aa4fd0d5ffed67952876c7729eee81216ee0f3f95ffee23a359f22`. Git archive memakai source tetap; export ditambahkan dari worktree integrasi, bukan dibangun ulang ketika agen lain mengubah source.
- Validasi image tanpa jaringan: SHA/byte PCK tepat, layout9, anchor Ujang `[1424,1260]` dan Darmi `[1365,280]` cocok dengan source yang diuji.

## CI main dan pemulihan

[Pipeline3044340306](https://gitlab.com/ardianryan/jalasmara-the-game/-/pipelines/3044340306), sourcef319da9, sukses **lima job**, termasuk laporan GitHub. Artifact yang diunduh langsung membuktikan82 testcase tanpa failure/error/skipped,45/45 world,201 aturan CodeQL/0 results dan tiga audit dependency/0 kerentanan. Ringkasan lokal `.runtime/06b-main-ci/summary.json` mempertahankan angka serta source. Ini melengkapi bukti branch sebelumnya, bukan menganggap job hijau sebagai SARIF kosong.

Backup sebelum aktivasi: `/var/backups/jalasmara/jalasmara-20261109T102817Z.archive.gz`, SHA256 `38b4bf9d0201176e73ed900ae18048ae40ef0298520c938a3cf0c22cbb2ef668`. Restore ke database terpisah berhasil **42 dokumen,0 gagal**; jumlah per koleksi cocok dan database pemeriksaan dihapus. Tidak memulihkan atau menghapus database hidup.

Rollback sudah disiapkan: `jalasmara:pre-06b-f319da9` tetap image lama `sha256:5c5a503d3d228042f457d8ddbe9785a20a7a5b49b035d5ea34f4346d01bf937a`. Hash `.env` dan ID container Mongo/Redis disimpan pada berkas privat VPS untuk dibandingkan sesudah aktivasi. Jangan menyalin `.env` ke arsip/source/laporan. Bind `10.1.0.8:3000` dan proxy pengguna dipertahankan.

## QA penutup dan status pekerjaan paralel

QA menggunakan pin wajib, consumer `land.view.motion` dan jalur yang memeriksa collision. Target tambahan ialah giliran malam/rumah, tujuh shelter/dialog saat hujan serta bridge_lower. [Laporan QA](06-release-remaining-qa.md) menyimpan command, UUID, kegagalan selama iterasi dan cleanup. Pengujian berjalan bergantian dalam satu slot engine/browser; belum ada public smoke atau aktivasi yang diklaim dalam checkpoint ini.

Dua percobaan awal malam berhenti di dekat post Tedi tanpa transaksi atau error API. Ini mengungkap masalah harness: arah keyboard terdekat membuat deviasi menumpuk pada segmen panjang, meskipun tiap pulse kecil. Arrival diperketat dan sasaran absolut pendek mengikuti koridor; regression memakai segmen/matriks/post sebenarnya, bukan menghapus collider agar tes lulus. Hasil akhir baru ditambahkan setelah run selesai.

Agent karakter menyiapkan kandidat transisi stop/turn dari artwork8arah yang sudah ada. Source `375a7bb` belum diparse/native pada checkpoint; tidak ikut image rilis. Agent visual menyelidiki persegi abu-abu yang tampak dekat NPC; source/import atlas mempertahankan alpha, sehingga penyebabnya belum boleh disebut pasti. Tidak ada chroma-key pakaian atau salinan texture tambahan sebelum pembanding native membuktikan mekanisme.

## Performa: pengukuran yang tersedia

Parser PCK read-only memverifikasi **658 payload MD5** pada pin5f2aaa. Tekstur impor43.947.888 byte dan empat musik16.187.080 byte masih mendominasi paket. Tidak ada resource yang dihapus, fallback diputus atau kualitas musik diturunkan. Inventori baru ada pada `.runtime/06b-release-payload.json`; ukuran resource tersimpan bukan memori GPU atau waktu frame.

Windows/S23 fisik belum terhubung untuk pengukuran. Perbandingan SwiftShader lama tidak dipakai sebagai klaim FPS perangkat. Langkah performa berikutnya harus memakai source/paket/profil yang dipin, membedakan startup dari rendering, serta mempertahankan kontrol, volume3D dan keterbacaan. Fish Gen tetap tool tersimpan untuk pilot sesudah inti, belum generator/runtime aktif.

Tool aktual: Git/worktree, Godot export yang sudah diverifikasi, Playwright/Chromium, Node/TypeScript, GitLab API/CLI, Docker build di VPS, SSH/SCP, mongodump/mongorestore dan parser PCK Python. Tidak ada plugin, API generator, library runtime atau aset upstream baru pada checkpoint rilis ini.

## Checkpoint lanjutan: konflik malam menahan aktivasi

Run UUID `4907b0a6-2634-47fd-8dac-22d63211d269` pada PCK5f menyelesaikan pelayanan tiga pelanggan, bonus kebun, penutupan kedai, masuk rumah, tidur, keluar dan reload. Tujuh pemeriksaan perilaku selesai, tetapi satu POST `/api/adventure/surface-position` mendapat409 dan satu console resource error. Ini **bukan penerimaan bersih**. Fixture miliknya sudah dibersihkan; imagef319 yang disiapkan di atas belum diaktifkan. Trace baru harus menentukan kode konflik dan urutan respons sebelum memilih perbaikan produk.

Harness sekarang mengikuti sasaran absolut pendek sepanjang koridor. Lima tes consumer lulus, termasuk pendekatan post Tedi dengan matriks kamera kiri aktual: deviasi maksimum turun dari34,756unit pada pendekatan panjang menjadi3,381unit tanpa menyentuh post. Tidak ada perubahan collider agar tes lewat. `night-home-browser.mjs` menambahkan trace request/response versi/posisi dan mode fixture rumah saja; trace tidak menyimpan password/cookie/token.

Transisi Nala `375a7bb`/`b79a3a7`/`5d52aba` sudah digabung ke main sebagai `4f5da1a`/`65653a3`/`2019357`. Focused144sampel,12set×8arah,collisionfoley,60kasus input kiri dan4×3outfit lulus di worktree karakter; enam log akhir bebas script/error/assertion. Native496PNG dan contact sheet ditinjau integrator. Perbaikan menurunkan kaki sebelum idle pada MC harian/explorer dan melewati pandangan antara saat berbalik; belum merupakan perbaikan seluruh painted sole/restart. Fullworld gabungan, export baru dan browser setelah integrasi masih menunggu. Tidak ada atlas baru atau API generator dipakai. [Bukti dan batas](06e-nala-gait-transitions.md).

Diagnostik alpha NPC `f8e2766` digabung sebagai `1563b9f`, tanpa perubahan runtime. Sebanyak7.762 sampel transparan tetap tidak mengubah latar pada jalur atlas native saat ini. Saras pada posisi kerja di LandWorld malam juga tidak memperlihatkan quad abu-abu. Masalah browser historis belum terbukti selesai; tidak ada chroma-key atau duplikasi texture yang dibenarkan hasil ini. [Diagnostik](06b-npc-portrait-alpha.md) menyimpan perbandingan dan jalur render yang belum diuji.

Slot engine diberikan bergantian: karakter selesai dan release, alpha selesai dan release, lalu agen QA memegang browser untuk trace rumah/malam. Integrator menangani state/transition dan rilis; CPU plan alignment rumah lain terpisah. Rumah selain Griya masih mempunyai shear geometri yang terukur dan perlu penyelarasan footprint/atap/pintu/collider/rute bersama, sesudah blocker save beres. Staging tetap paket lama9ba21c6/PCKa937; image siap di atas harus diganti jika perbaikan runtime baru diperlukan.

## Build gabungan berikutnya: source11c7576, belum aktivasi

Trace rumah saja UUID4eb1312e lulus2checks/3aksi. Rangkaian lengkap UUIDdc834487 kemudian lulus7checks/8transaksi,0console/0HTTP409,cleanuptrue pada PCK5f yang sama. Trace236request mencatat servev1→v2→v3,closev4,enterv5,sleepv6,exitv7 serta refreshv7 dengan basis posisi yang sama. Setelah keluar, tester menunggu renderer aktif dan3,5detik sebelum reload. Konflik pada4907b0a6 tetap merupakan temuan historis yang **belum diketahui kode/penyebabnya**; rerun bersih bukan perbaikan Main yang dibuat-buat. Mode rumah baru menambahkan gerak aktual dan ACK sesudah keluar. [Laporan QA](06-release-remaining-qa.md) menyimpan perbedaan ini.

Nala mendapat batas tambahan satu sudut pandang per frame render, termasuk beberapa physics tick pada frame lambat. Integrator menguji192sampel stop/turn/stress,12set×8arah dan urutan native terbaru; tidak ada perubahan jarak/foley fisik atau atlas. Fullworld awal workspace utama berhenti pada resource Ujang yang belum diimpor di cache lokal. Dua tahap import/export memperbaiki cache; **full45/45**,82/82API,typecheck,buildweb/API dan export kemudian lulus. Log gagal awal dipertahankan pada `.runtime/06b-core-final-world.log`; hasil akhir `.runtime/06b-core-final-world-imported/`, `06b-core-final-world-imported.log`, `06b-core-final-api.log`, `06b-core-final-typecheck.log`, `06b-core-final-export.log` dan `06b-nala-integrated-native.log`. Scan seluruh log akhir bebas SCRIPT ERROR/ERROR/assertion. Delapan tes consumer/failure-trace lulus dan terdaftar di CI. Tidak ada patch Main/API yang diklaim memperbaiki konflik yang tidak terulang.

Paket baru memakai source `11c75762b4616f82efa324941fe7e101170d64cd`, PCK `592dc75ba391302aff22fce0f1c3c31d2d894ed46df52e6eb1f90c4917545b2b`,64.307.052byte. API preview3101 dibangun/restart dari main dan fetch HTTP membuktikan hash/byte tersebut. Server integrasi3101 lama dihentikan hanya sesudah identitas PID/cwd diperiksa; proses3100 tidak disentuh. Arsip immutable source+export SHA `5a4b548a1549850d4a0bafbff3c347ef18d087d284094ccbcb69762e34ef1be7` dikirim ke direktori rilis terpisah VPS. Image11c sedang dibangun; bukan mengganti imagef319 diam-diam atau menyebutnya sudah aktif.

[Pipeline3044607461](https://gitlab.com/ardianryan/jalasmara-the-game/-/pipelines/3044607461) dipicu pushmain11c7576 dan masih berjalan pada checkpoint ini. QA memegang slot browser untuk lower/shelter/gerak sesudah keluar rumah pada pin592. Integrator melakukan Docker/CI/backup lewat CPU/VPS; agen karakter menyiapkan kandidat restart terpisah dan agen arsitektur menyiapkan layout10 terpisah. Keduanya belum masuk paket11c. Gray quad browser historis dan performa Windows/S23 tetap belum dinyatakan selesai.

Image11c selesai dibangun: `sha256:4d2f8990029519877095ca3301a78246cd4a7f352d5906d910b5977843eab081`. Verifikasi tanpa jaringan membaca PCK592/64.307.052byte tepat dan layout9. Backup baru `/var/backups/jalasmara/jalasmara-20261109T110056Z.archive.gz`, SHA `d9755b3fc09ba789f7ab17970c16ad669984eb7d8c8e28b810c39f5da89d684a`, berhasil direstore terpisah42dokumen/0gagal; semua jumlah koleksi cocok dan database pemeriksaan dihapus. Rollback `jalasmara:pre-06b-11c7576` memegang image lama5c5; checksum `.env` dan ID Mongo/Redis disimpan privat. Belum aktivasi.

Native gabungan menghasilkan592PNG; integrator meninjau56pose pilihan dalam contact sheet actual, termasuk30Hz/100ms, lowering dan giliran. Helper Pillow reproducible `tools/player-gait/review_runtime_sequence.py` menyimpan manifest hasil/source/frame SHA; tidak menggambar pose/aset baru. Browser bridge_lower UUIDc1f1279f lulus2checks/27matrixpulse/12ACK tanpa error dan memulihkan titik yang sama setelah reload. Run shelterbee2 tiba di enam shelter; Ujang berhenti memberi perhatian kepada tester yang diam dekat spawn. Cuaca.55/nighttrue dan0blockedSeconds membedakan ini dari collision/path rusak. Fixture bersih; harness berikutnya harus berjalan menjauh dahulu melalui jalur sah, tanpa teleport atau mengubah perilaku NPC agar tes lulus.


## Kandidat final f4fac83 dan pembersihan storage

Source runtime f4fac83 menambahkan aksi bicara Lurah di UI Balai ketika NPC berada dekat papan, dengan guard busy di callback. Interaksi nearest-target tetap; permit board/resident membuka UI sama. Sembilan belas skenario actual Main/HomesteadUI, regresi homestead/dialog, full46world, build/export dan CI82API/46world/201aturan0results/tiga audit0 lulus. [Bukti CI](06b-ci-artifacts-3044738570.md). Tidak ada perbaikan konflik409 historis yang diklaim dari perubahan ini.

PCK43df70a9/64.307.804byte; image `sha256:43bd232ffcb651027b920b9967b0690f2631946e6ed2b582a7e9195416c462f9` dibangun dari arsip immutable source/export SHA `37dd0552b1f1d2698199af3d1281e3f5d616365d89612d7bf0c5963a6fffbfef`. Image diperiksa tanpa jaringan dan PCK cocok. Browser continuation592→43df sedang menguji lima dialog tersisa serta izin/bibit sebenarnya. Belum aktivasi staging pada checkpoint ini.

Pengguna meminta cache/build tidak dipakai dibersihkan pada PC/VPS. Image dan source archive f319/11c yang disebut pada riwayat di atas sudah **superseded dan dihapus**; rollback tetap image aktif5c5. Lokal51path/5.413.732.352allocatedB sudah dibuang; cache Docker VPS dipangkas setelah build selesai. Source kandidat house/restart serta PNG/JSON/log bukti tidak dibuang. Tidak ada dependency/runtime/tool gambar baru.
