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
