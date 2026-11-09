# Pilot 06-B1a: rumah panggung, tempat berteduh, dan kamera tiga perempat

Arahan pengguna, 9 November 2026: gunakan pendekatan Noxe saat memperbaiki tempat berteduh agar rumah panggung terbaca sebagai bangunan 3D dengan pandangan tiga perempat. Pengguna juga meminta sisa pekerjaan dijalankan paralel. Empat slot sesi terdiri dari integrator dan tiga subagent; pengujian engine/browser dijadwalkan bergantian.

Status awal: rancangan dan implementasi pada worktree terpisah. Source rilis awal tetap `9ba21c6`, PCK `a9378a52`; dokumen ini tidak menyatakan kamera atau bangunan baru sudah dipasang di staging.

## Temuan source yang menentukan pekerjaan

`LandWorld3D.gd` sudah memakai `Camera3D.PROJECTION_ORTHOGONAL` dengan elevasi pandang 35°. Namun `map_point` meregangkan sumbu kedalaman dan memberi kompensasi posisi terhadap tinggi; `ground_projection` mengembalikannya ke susunan peta dua sumbu lama. Kamera bergerak pada bidang Y/Z tanpa azimut diagonal. Rumah memperoleh orientasi dari footprint miring. Ini 3D nyata, tetapi bukan proyeksi isometrik global seperti pandangan menyudut Noxe.

Noxe pin `d619d856398b44ad084003fac0a9fbfc9c8393e7` memisahkan azimut/elevasi kamera; preset awal 45°/30°. Kit `cottage()` dan `pier()` membangun volume, atap, papan serta tiang dalam ruang lokal. Rumah panggung Nusantara memerlukan modul sendiri yang memakai prinsip tersebut; pondok demo tidak otomatis menjadi rumah panggung atau lantai gameplay Jalasmara. Sumber dan lisensi terperinci ada pada [audit Noxe](../world/noxe-pixeldoll-reference.md).

## Jalur bangunan dan tempat berteduh

1. Pilih satu rumah pada dek yang sudah mempunyai ruang bawah terbuka. Griya Sasmita menjadi kandidat karena terhubung ke dek/jembatan existing; rumah di atas tanah teras tidak diberi kolong panjang yang tertimbun terrain.
2. Bangun lantai tebal, balok bawah, tiang yang mempunyai tumpuan, bracing, serambi, atap dengan ketebalan, serta akses yang mengikuti platform sebenarnya. Material kayu, bambu, anyaman dan palet pesisir tetap memakai library proyek.
3. Tambahkan atau perjelas serambi/awning bertopang pada titik yang melayani tujuh tujuan hujan. Simpan hubungan atap, post, lantai dan titik kegiatan dalam koordinat bangunan yang sama. Siluet tiang dan bayangan kontak membantu membaca kolong; grading fullscreen tidak menjadi pengganti volume.
4. Periksa coverage atap setelah transform miring, clearance badan, seluruh ruas rute serta elevasi. Atap tidak boleh hanya menutupi titik secara visual dari satu kamera sementara karakter sebenarnya berada di luar bidangnya.
5. Post tambahan yang menjadi penghalang harus masuk manifest. Bila versi layout naik, uji posisi save lama yang bertabrakan dengan post, pemulihan posisi sah, serta keterhubungan ke graf/portal. Titik walkable hasil pencarian radial belum membuktikan konektivitas.

## Jalur kamera

Pembanding native pertama memakai bangunan/mesh sebenarnya pada kamera rilis dan kamera menyudut. Pisahkan perubahan geometri dari perubahan proyeksi agar penyebab hasil dapat dinilai.

- Pandangan tiga perempat menyudut: bandingkan azimut sekitar 45° dan elevasi 30°/35° terhadap acuan comfy. Isometrik geometris murni mempunyai elevasi sekitar 35,264° pada azimut 45°; keputusan seni tidak harus memaksakan persamaan panjang ketiga sumbu.
- Perubahan kamera seluruh dunia harus memakai transform yang sama bagi lantai, bangunan, aktor, titik kaki, input joystick/keyboard, reticle/interaksi dan penanda. Uji invers proyeksi serta arah visual karakter. Jangan mengompensasi tanah kembali ke tampilan lama lalu menyebut hasilnya isometrik global.
- Pertahankan koordinat gameplay server sebagai sumber kebenaran. Perubahan sudut pandang bukan izin berjalan melalui kolong/atap, memindahkan portal, atau mengganti koordinat save secara kosmetik.
- `facing` bangunan tetap transform lokal. Empat facing diperiksa bersama pintu/tangga/coverage atap. Mengubah facing satu rumah tidak memutar input seluruh peta.
- Bila atap/dinding menghalangi Nala, gunakan cutaway/fade setempat yang mempertahankan informasi tiang dan tepi lantai. Perubahan collision tetap terpisah dari keterlihatan mesh.

Pilot kamera belum mengubah default rilis sebelum proyeksi, kontrol dan rute gabungan terbukti benar. Hasil uji harus menyebut kamera yang benar-benar dipakai dan kekurangan yang belum ditangani.

## Kepemilikan dan pengujian

| Jalur | Kepemilikan |
| --- | --- |
| Rumah panggung/shelter | Modul bangunan, konstruksi `LandWorld3D`, metadata manifest/rute, coverage atap dan migrasi. |
| Ujang | Rig dan artwork arah/grip sendiri; source dan provenance aset, tanpa mengubah renderer bangunan atau jadwal. |
| Website | Halaman/formulir/CSS non-game, request/loading/error serta responsive; tidak mengubah HUD atau source kamera. |
| Integrator | Pembanding proyeksi/kamera, peninjauan visual, penggabungan, regresi serta rilis. |

Pembuktian mencakup render siang/malam/hujan, Nala di depan/serambi/belakang, tujuh perjalanan berteduh/pulang/bicara, post sebagai penghalang, tangga/jembatan, save lama, HUD landscape/portrait, serta biaya mesh/material/draw call. Performa Windows/S23 fisik tidak digantikan hasil renderer otomatis.

Satu renderer Godot dipertahankan. Kode Noxe yang benar-benar diport harus memperoleh notice MIT, pin dan daftar berkas; adaptasi metode tanpa menyalin kode ditandai demikian. Engine Noxe, exporter GLB baru, interior playable semua rumah, dan RV bergerak bukan prasyarat pilot ini.

Pemeriksaan dokumen: Hard Gate PASS, source dan status rancangan dibedakan; Purpose Gate PASS, tiap modul mempunyai fungsi tumpuan/akses/coverage; Liveliness PASS, arah comfy dan ruang panggung berasal dari brief pengguna; Craftsmanship PASS, jalur source serta hubungan proyeksi diperiksa. Gate visual dan gameplay menunggu hasil implementasi sebenarnya.
