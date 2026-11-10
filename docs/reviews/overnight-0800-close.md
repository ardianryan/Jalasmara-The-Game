# Serah terima pekerjaan malam, 10 November 2026

Checkpoint 07.53 WIB menjelang batas kerja 08.00 WIB. **Seluruh pekerjaan belum selesai.** Rilis staging tetap ekspor kelima; eksperimen kaki Nala tidak digabung. Laporan ini memegang status terbaru dan mengatasi catatan historis yang masih menyebut pekerjaan sedang berjalan.

## Workspace dan rilis

- Integrasi: `/Users/ardianryan/Documents/Jalasmara-overnight-integration`, branch `work/overnight-integration`. Checkout asli `/Users/ardianryan/Documents/Jalasmara`/main tetap dipertahankan; jangan menerapkan pekerjaan berikutnya di checkout yang salah. Symlink dependency `node_modules` tidak boleh di-stage.
- Staging: Docker/API source `bf55342d82b439119f48aee3a5a7189a33b26357`, Godot export source `72b173c5f04d986e365fa34fd19daea62fb65125`, image `559451efd4c10c841ef0f2aa1f8e0dd09eba5fd76dafcbb2e779c3c095e5c7db`.
- PCK `9a1ca274b88cf65e819f1c117da2ede7992420e2128b454ef6bc3cf7f19cbb1a`, 64.500.848 byte/62 bagian. Tidak ada ekspor baru untuk proposal art atau eksperimen fisik. HTTP `/api/health` staging kembali `{"status":"ok"}` pada pemeriksaan penutup.
- GitHub dan GitLab.com adalah remote; GitLab CE dibatalkan. Push mirror memakai `ci.skip`, bukan bukti CI hijau. Build CI terakhir gagal memperoleh runner (`stuck_pending_no_matching_runners`), bukan kegagalan kompilasi yang sudah dibuktikan.

## Hasil yang sudah diperiksa

1. [Browser shelter](overnight-export5-canonical-shelters.md): satu fixture lokal menyelesaikan 18/18 pemeriksaan, seluruh 13 warga berteduh dan dapat diakses/berdialog/resume, termasuk layanan lurah. 468.786 ms, 1.469 pulsa, 323 operasi teramati, nol error, cleanup berhasil. WebGL Apple M2/Metal terukur; bukan pengujian Samsung S23/Windows. Timeout SwiftShader sebelumnya tetap disimpan.
2. [Lighting lokal](overnight-actor-lighting-frame.md): konteks 11 lampu dibaca sekali per batch; warna/checksum sama. Full 67/67 pemeriksaan dunia lulus, 140.929 ms akumulasi, tiga warning lama dicatat. Perubahan source `36b68af` belum diekspor. Penghematan sekitar 0,103 ms pada batch 24 actor CPU bukan bukti kenaikan FPS.
3. [Art upper](overnight-upper-authoring-progress.md): dari 16 pasangan pakaian/arah, 6 mempunyai proposal loop, 1 hanya endpoint, 9 belum dibuat. Semuanya belum menjadi gerak runtime yang diterima. NORTH daily/explorer memakai sumber dan mask terpisah, root 10 tes rig + 9 tes loop lulus; 28 PNG/APNG hasil regenerasi identik. Semua 19 tautan relatif dalam laporan progres telah diperiksa di checkout root, nol hilang.
4. Galeri dokumentasi berisi 26 PNG/APNG, 4.046.375 byte, dengan sumber/proposal dibedakan. Output penuh dan bukti gagal tetap ignored, bukan dihapus sebagai cache. Tidak ada klaim seluruh 12 outfit sudah mempunyai natural gait baru.
5. Rilis publik ekspor kelima sebelumnya lulus 6/6 smoke HTTP/2 default; hutan/badge lokal 5/5 dan lautan 3/3 lulus. [Rincian pin, bukti, backup dan cleanup](overnight-export5-integration.md) tetap berlaku. Pemeriksaan health penutup bukan pengulangan smoke penuh.

## Hambatan inti Nala

Source terakhir `831cf9b` hanya ada di branch eksperimen `work/overnight-character`; branch itu dipush sampai laporan `ddb409b`. **Jangan cherry-pick seluruh branch**: riwayat memuat voxel body yang ditolak. Root hanya mengambil laporan, bukan runtime FootPlant/Lower/StairSupportCurve.

[Laporan aktual karakter](overnight-nala-upper-exit-831cf9b.md) dan [rekonstruksi peer](overnight-stair-view-envelope-peer.md) menyimpan perintah, source/hash, kegagalan, dan bukti:

- Target keluar tangga kini diukur dari kedalaman tread 3D sebenarnya, bukan jarak logis yang salah. Unit target lulus; ini belum bukti rute selesai.
- Gate sisa lintasan mencegah mask sepatu baru melampaui envelope riser yang dibekukan. Unit `831cf9b` lulus 1,028 s; parse gagal pada fixture pendahulu `21f1ac7` tetap dicatat walaupun process exit 0.
- FIRST7 source sama **gagal setelah enam kasus**, 15,538 s/398 observasi, pada ridge UP: kaki kiri yang sudah menapak membutuhkan drop 8,841755 > batas 8. Rekonstruksi independen cocok hingga 0,0000314 piksel.
- Gate menahan EAST, tetapi body sudah NW, sehingga carried-resume jatuh ke jalur legacy 22,75. Kontak LEFT144 terlambat; langkah RIGHT berikutnya belum selesai ketika stance kiri melampaui jangkauan. Pemulihan arah belum diterima: ada sepatu ditahan 1,3 detik/74,14 unit. Jangan memperlebar eligibility, mengubah facing paksa, memanjangkan tulang, atau melonggarkan guard demi PASS.
- Model third-step dataran juga menemukan 41/62 sudut RIGHT mengenai pohon `hub_margin_tree_10`; klaim tiga langkah legal dicabut. Jangan memindahkan pohon atau mengubah fixture untuk menyembunyikannya.

Pekerjaan berikutnya harus memodelkan **mask asli yang benar-benar ditahan + correction/pivot + jadwal resume/stance dan recovery** pada kegagalan yang direkam. Setelah model menjelaskan kedua kaki dan target `_safe` nyata, bekukan perubahan sempit, review peer, lalu jalankan unit dan FIRST7 serial. Hanya bila lulus, lanjut full 16 terrain source sama, fresh flat32/raw input/facing recovery, validasi urutan kontak, dua native sequence bergerak daily/explorer, upper/gear phase/grip, biaya CPU, integrasi terisolasi dan browser. Saat ini full16, flat/native terbaru dan natural walking tetap belum diterima; audio kontak belum dihubungkan pada pilot.

## Gemini: paket ditahan dan tugas koreksi

Commit `f67de11a9c067ec80cf42ed5fb6cfa9dae4a89e2` tetap di worktree `/Users/ardianryan/Documents/Jalasmara-gemini-character-audit`, branch `work/gemini-character-source-audit`. Scope sepuluh file baru sesuai dan enam tes struktural lulus, tetapi kebenaran audit belum diterima.

**Semua tujuh klaim P0 inversi arah dan klaim mismatch diving SE terbukti salah.** Ekor bandana masuk centroid “kulit”; sumber asli cocok dengan IDLE. Dua hash laporan juga salah meskipun file aslinya tidak berubah, 65 status bersih terisi default, klaim gear melampaui cakupan bukti, dan guard output mengizinkan review lain/symlink/overwrite. Jangan swap/mirror atlas berdasarkan paket ini.

[Instruksi siap diberikan kepada Gemini](../plans/07b-gemini-character-audit-corrections.md) menetapkan worktree, allowlist persis, koreksi klaim, ledger visual, hash/format input, test guard, output run baru, bukti maksimum 1 MiB, commit lokal baru dan syarat berhenti. Koreksi manual file miliknya diperbolehkan; generator tidak boleh menimpa bukti lama. Dokumen review root dibaca lewat path absolut secara read-only karena belum ada dalam commit Gemini. Gemini belum menjalankan koreksi lanjutan dan belum mendapat izin memperbaiki artwork.

## Alat, lisensi, penyimpanan dan batas lain

Paket penutup memakai Git, Python/Pillow, tool authoring proyek, Godot 4.7.2 Compatibility, dan harness browser yang sudah ada. Tidak ada dependency/engine/MCP baru, penggunaan key SpriteAI, atau generator gambar eksternal. Tool NORTH merupakan kode/mask authoring proyek; artwork asli dan [notice Pillow](../../tools/player-gait/LICENSE-Pillow.txt) tetap berlaku. Integrasi Fish Gen sebelumnya hanya dekorasi offline dengan atribusi MIT, bukan pengganti 10 spesies gameplay/722 frame. Noxe tetap helper kamera berlisensi MIT; PixelDoll adalah referensi, bukan runtime baru.

Cleanup sebelumnya menghapus context build duplikat dan image builder milik tugas yang sudah tidak dipakai; active image559 dan rollback898, source unik, log gagal, worktree, data dan backup tetap disimpan. Penghapusan empat builder stage memberi kenaikan free-space VPS terukur 1.053.335.552 byte; jangan menambahkan ukuran image secara teoritis sebagai penghematan baru.

Windows/Samsung S23 fisik belum diuji. Pengguna bersedia menjalankan [prosedur perangkat](../performance/overnight-device-test.md) nanti; jangan mengarang hasil FPS atau menjadikan Metal/SwiftShader sebagai penggantinya. Penilaian visual akhir moodboard, detail seluruh outfit/arah, pemulihan gait dan alat warga masih perlu diteruskan. Seluruh delapan jalur belum selesai.
