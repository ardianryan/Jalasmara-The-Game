# QA kamera kiri: sasaran canopy dan penerimaan rumah/gerbang

Status 9 November 2026: **CPU/source siap, belum engine/browser**. Branch `work/06-canopy-route-qa`, worktree `Jalasmara-06-canopy-qa`, base `f7a3b96`. Integrator dan lane rumah memegang engine; lane ini tidak menjalankan Godot, browser, API mutation atau jaringan publik. Startup H2 dan full smoke publik tetap terbuka; perubahan ini tidak mengubah proxy ataupun menyebut mode HTTP1 sebagai default PASS.

## Sasaran diturunkan dari geometri dan alpha

Titik350/1250 adalah simpul jalan, bukan bukti occlusion. Perhitungan CPU memakai persamaan `map_point`55°, basis kamera aktual azimut−45/elevasi35, bend batang `sin(1.2)*14/5/height`, lebar crown, offset `camera_up*width*.08`, body48/forward8, syarat depth>12 dan empat probe body dari `CanopyReadability3D`. Atlas yang dibaca adalah `land-foliage-v1.png` asli, SHA256 `1f07437f9ff5f9cbc063c191904eecf734ffad859b3daf6f0fccf177c8aa4564`; tidak ada gambar moodboard/aset baru.

Model mencakup43pohon manifest dan4pohon border yang sungguh dibangun renderer, total47. Empat border diambil dari bentuk source yang dibatasi, bukan menjalankan GDScript. Bila bentuk source, terrain datar atau sudut kamera tidak lagi didukung, fixture menolak kandidat. SHA renderer ikut dicatat dalam evidence. Mask64² hanya dianggap opaque bila **seluruh** blok8×8 alpha sumber>90; ini lebih konservatif dari sampling nearest, agar perbedaan pembulatan resize tidak membuat bukti palsu.

Pada base ini,350/1250 memprediksi nol occluder, cocok screenshot publik sebelumnya. Kandidat terpendek adalah **142/1213**, crown46 `renderer_forest_border_3`. Rute dari spawn200/1320 memiliki panjang121,709unit dan seluruh segmen lolos `physicalRoute`/floor authoritative. Crown tersebut tetap diprediksi menutup body pada27kombinasi posisi±5unit dan sway±3unit, dengan satu reveal, jauh di bawah47/4. Bound sway3 melampaui amplitude2,425 dari rentang wind source. Kandidat403/1327 yang ditemukan saat model hanya mencakup pohon manifest digantikan setelah empat border turut dihitung; itu bukan hasil browser.

Assertion browser asli `revealed>0`, `revealed<crowns/4`, amount>.99 dan trunk tidak tersentuh dipertahankan. Kini total crown harus cocok dan **index crown prediksi wajib benar-benar aktif**. Rute/target diturunkan lagi dari world API dan view snapshot aktual pada saat run, tidak diteleport atau dipaksa melalui override kamera/cuaca. Posisi hasil CPU belum merupakan penerimaan renderer.

## Mode lokal sempit, belum dijalankan

`PLAN06_ROUTE_MODE=canopy` pada `plan06-layout-browser.mjs` membuat UUID baru pada save awal forest spawn yang sah, kemudian memakai input matriks nyata untuk berjalan ke kandidat→reveal stabil→tap jurnal667×375→gerak terjeda→tutup/resume→berjalan kembali→crown restore→ACK posisi dan reload. Mode ini tidak mengulang prefix desa/tujuh dialog atau mengklaim sudah melewati gerbang hub. Kalender malam memakai fixture sah yang sudah ada, bukan runtime clock override. Batas rute5menit, pin PCK dan byte tetap wajib, origin/DB/Redis tetap localhost, cleanup UUID tetap terarah. Report mempunyai `outcome/completed`; sukses memerlukan seluruh check dan cleanup.

Setelah integrator menggabungkan world kandidat baru (hub layout10/forest layout6 dan post collider), ulang tes CPU pada **source gabungan** terlebih dahulu. Floor baru dapat mengubah rute yang dipilih, sehingga121,709unit adalah hasil base, bukan angka yang dipaksakan pada kandidat. Sesudah hash export baru tersedia dan slot diberikan:

```sh
APP_TEST_ORIGIN=http://localhost:3101 \
PLAN06_ROUTE_MODE=canopy \
PLAN06_EXPECT_PCK=<sha256-export-kandidat> \
PLAN06_EXPECT_PCK_BYTES=<byte-persis> \
node --import tsx scripts/plan06-layout-browser.mjs
```

Jangan jalankan command dengan placeholder atau paket lama yang dianggap baru. Pemeriksaan publik tetap fixed-origin staging dan hanya boleh dijalankan setelah integrator mengaktifkan kandidat serta memberi grant terpisah.

## Penerimaan rumah dan gerbang berikutnya

Lane ini tidak mengubah `land.ts`, `LandWorld3D`, layanan atau posisi rumah. Kandidat rumah/gerbang milik lane lain. Penerimaan browser yang diusulkan menggunakan metadata paket baru dan gerakan nyata:

1. **Rumah:** ambil footprint/elevasi bangunan dari world. Bandingkan kedua sumbu footprint dalam ruang `(x,-y/cos55)` dan mesh actual, bukan sudut screenshot saja. Dek, fascia atap, dinding/pintu, serambi dan tiang harus memakai sumbu yang sama. Untuk tiap rumah, pilih approach di luar tengah sisi fasad, lalu `physicalRoute` membuktikan floor dan clearance post. Berjalan lewat approach/sisi serambi, capture kamera kiri; tidak menembus collider. Griya memakai `world.homestead.door` untuk aksi masuk/keluar aktual, sesudahnya gerak→surface200/ACK→reload; koin/inventori/progres tetap kecuali aksi yang memang diharapkan.
2. **Gerbang:** lane gerbang menyiapkan `land.gateways` dengan center, postCenters/postFootprints, crossing endpoints±36unit fisik sepanjang arah jalan dan transform mesh aktual. Konsumen QA harus memeriksa gap collider/body clearance, lalu berjalan sebelum→tengah aperture→sesudah dan kembali memakai metadata aktual. Sisi signed plane harus benar-benar berganti, posisi lateral tetap di dalam bukaan; screenshot sebelum/tengah/sesudah harus menunjukkan lantai jalan, kedua pangkal dan orientasi lintel sesuai. Menekan E dalam radius portal saja tidak membuktikan melintasi gap.
3. **Antararea:** setelah crossing sah, aksi travel aktual hub→forest→hub tetap200 dan state area benar. Wajib lewat rute physical, tanpa input logical yang mengabaikan `land.view.motion`. Tidak memindah trigger atau menghapus post supaya tes lulus.
4. **Responsif/persistence:** capture844×390 dan667×375, joystick tetap bisa disentuh tanpa menutup pangkal/akses, modal menjeda gerak, save/reload berada di floor layout terbaru. Catat exact PCK/layout dan outcome, API409/error serta cleanup. Ini belum pengukuran perangkat Windows/S23 atau penerimaan semua rumah.

Metadata gerbang masih dikerjakan lane gerbang; house/gate browser route belum diklaim tersedia atau lulus. Integrator memilih paket lokal yang diuji sebelum public rerun.

## Verifikasi dan tool

Aktual: Node26.12.1, Python3.9.6 dan Pillow11.3.0 yang sudah terpasang; Pillow hanya membaca alpha sumber. Tidak ada install, executable upstream baru, engine atau modifikasi raster. Lisensi/aset proyek existing tetap berlaku; kode helper fixture adalah kode QA proyek.

`node --import tsx --test scripts/canopy-route-fixture.test.mjs scripts/land-view-navigation.test.mjs scripts/gameplay-api-failure.test.mjs`: **12/12 PASS**. Empat kasus baru mencakup titik lama unobscured/basis kamera, alpha/rute/27margin kandidat, penolakan sudut/terrain/alpha transparan, dan guard persamaan source/sway. Syntax kedua harness/helper, Prettier dan diff-check lulus. Hasil source ini belum CI baru atau browser baru. Integrator perlu memasukkan command empat tes baru dalam pemeriksaan CPU paket gabungan/CI sesuai ownership runner.
