# Nala: diagnosis dan batas calon resumption

9 November 2026. Audit CPU-only sesudah checkpoint native `5d52aba`; tidak ada runtime, raster atau perubahan posisi pemain baru pada dokumen ini. Stop/turn polish telah diterima sebagai perbaikan parsial. Main/rilis `f319da9` tidak disentuh oleh worktree karakter.

## Repro restart yang masih nyata

`artifacts/godot/nala-gait-transitions/results.json` dan frame native daily normal menunjukkan:

| Native frame | Pose actual | `_travel` | Raw phase |
| --- | --- | ---: | ---: |
|0023|neutral|24|0.37500|
|0024|walk3, knee tinggi|26|0.40625|
|0025|walk3|28|0.43750|
|0026|walk3|30|0.46875|
|0027|walk4, contact berikutnya|32|0.50000|

File `artifacts/godot/nala-gait-transitions/restart-pop-contact-sheet.png` menyandingkan kelima render sebenarnya dan telah dibaca dengan `view_image`. Root menerima2unit perpindahan, tetapi gambar langsung dari neutral menjadi lutut tinggi, sebab phase sengaja dipertahankan dari jarak sebelumnya. Memperbaiki stop tidak otomatis memperbaiki restart.

Sebagai **proxy gambar**, bottom opaque row atlas daily idle berada pada y103,x60…75; walk3 tetap y103 tetapi x54…62. MeanX berubah67.5→58.0. Angka ini menjelaskan perubahan silhouette bawah yang besar; ini bukan anotasi telapak kiri/kanan atau bukti sole world-lock. Explorer memiliki perubahan serupa, serta bottom walk3 mencapaiy104 sementara idle y103. Menggunakan centroid alpha sebagai socket anatomis akan memberikan bukti palsu.

## Invariant calon landing-aware resumption

1. `_travel` hanya bertambah dari perpindahan collider yang diterima. Tidak boleh direset, diberi phase jump atau menggerakkan root agar pose awal tampak cocok. Input kamera kiri dan server path tetap sama.
2. Contact/foley tetap persis pada half-stride distance32; antrean restart tidak boleh memanggil event langkah karena timer atau pergantian gambar. Contact mentah dan pose yang ditampilkan harus dilaporkan terpisah apabila ada transisi.
3. Pilih pose launch dari foot/support yang telah dianotasi untuk **direction+outfit** sebenarnya, bukan dari nama contact/down hasil generator atau centroid alpha. Frame1/5 merupakan kandidat lowering yang sudah terlihat; belum otomatis merupakan startup yang benar untuk setiap arah.
4. `posePhase`, frame dan `artworkDirection` menjelaskan gambar yang tampil. Gear memakai ketiganya, termasuk ketika body view masih menempuh giliran bertahap. Tidak boleh memberi tank facing baru lebih awal daripada badan.
5. Catch-up harus ditambatkan pada contact aktual berikutnya dan jarak yang masih tersedia. Untuk repro24→32, ada8unit menuju contact: calon1→2→3→4 dapat dibagikan pada jarak tersebut, tanpa mempercepat `_travel`. Ini **rancangan**, belum bukti bahwa foot identity setiap frame cocok.
6. Jika sisa jarak menuju contact terlalu pendek untuk menampilkan startup dengan utuh, jangan memaksa seluruh rangkaian dalam satu render. Pilihan yang perlu ditinjau: tahan neutral/low pose sampai contact berikutnya, lalu masuk pada contact authored yang sesuai. Itu tradeoff pose/slide kecil yang harus diukur, bukan disembunyikan sebagai natural walk.
7. Nol perpindahan karena collision/pause tidak boleh melanjutkan startup berjalan di tempat. Clock, host dan owner pause membekukan urutan. Jika pemain melepas input ketika startup berlangsung, kembali ke lowering yang aman tanpa false footstep.
8. Satu perubahan arah authored per render frame tetap berlaku pada30Hz,100ms spike dan beberapa physics sample. Jangan menginterpolasi/mirror raster atau menukar identitas kaki untuk mengejar kamera.

## Bukti yang diperlukan sebelum patch resumption

- Anotasi toe/heel/support tiap pose pilot daily/explorer dan pandangan yang dipakai, dengan pixel pada artwork yang sudah dilihat. Bedakan posisi telapak terproyeksi dari body pivot64,104. Jangan menyebut semua arah siap jika baru east yang diperiksa.
- Repro actual Player dari diam dengan akselerasi850, bukan hanya input konstan100 seperti fixture komponen. Sampel stop di delapan phase, restart lurus/reverse90/reverse180, collision tepat sesudah restart, pause/resume serta reduced motion. Setidaknya ukur arah depan/belakang dan kamera kiri pada lantai legal.
- Jumlah event langkah harus identik dengan baseline untuk accepted path yang sama; rawphase/travel tidak diubah. Gambar yang baru diberi label contact harus cocok dengan kontak yang benar-benar terlihat, bukan hanya JSON assertion.
- Native rangkaian berurutan pada ukuran main, ditambah2× lembar inspeksi telapak/gear, lalu browser aktual. Pose komponen di dokumen ini tidak mengukur triangle lantai3D atau FPS Windows/S23.

Tidak ada implementation resumption atau artwork baru yang ditambahkan. Jika gambar lama tidak dapat mempertahankan foot identity, hasil audit harus menyebut perlunya startup/contact asli tambahan; itu lebih tepat daripada menjanjikan footplant melalui phase offset yang tidak pernah diukur. Task berikutnya tetap diputuskan integrator setelah meninjau stop/turn dan trace visual ini.

Tool aktual: pembacaan JSON, Python3/Pillow untuk kontak sheet dari PNG native yang sudah tersedia, dan `view_image`. Tidak menjalankan Godot/browser setelah slot dilepas, tidak menggunakan API key atau image generation, dan tidak menambah lisensi/dependensi.
