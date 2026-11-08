# Dunia hidup dan peta geografis

Bandar Hujung memakai bidang 2400 × 1600 yang diselaraskan dengan gambar desa, bukan deretan bangunan pada satu jalan. Dermaga, pelataran bawah, pelataran kedai/galangan, dan punggung bukit dihubungkan lewat jalur serta tangga. `WORLD.hub` menyimpan ukuran, jalur, penghalang, tingkat pelataran, tangga, dan potongan foreground. Titik menyelam berada pada tangga yang tampak di gambar. Posisi permukaan dari tata letak lama dipindahkan ke dermaga tanpa mengubah inventori, saldo, atau progres akun.

`GeoMap` menampilkan gambar wilayah dan bentuk batu pada koordinat permainan. Posisi pemain, bangunan, titik belajar, tangga dan pintu tertutup menggunakan transformasi koordinat yang sama. Peta dapat digeser, diperbesar, dan dipilih lokasinya. Daratan serta penampang kedalaman laut adalah dua tampilan berbeda: arah vertikal pada penampang menunjukkan kedalaman, bukan utara. Minimap memakai data yang sama. Peta tidak menyediakan teleport atau membuka kawasan rencana.

## Laut dan darat

Batu laut memakai polygon tidak beraturan dan tekstur batu asli proyek. Kontur pada `WORLD.terrainContours` dipakai bersama oleh mesh, collision klien, dan pemeriksaan posisi server dengan jarak aman tubuh penyelam. Bounding box lama dipertahankan untuk penempatan konservatif biota. Coral garden dan lamun ditempatkan pada permukaan batu, dengan karang piringan pada dinding. Latar jurang mempunyai kontras lebih rendah; dekorasi depan lebih tajam. Parallax hanya menggerakkan dekorasi terpisah, bukan tanah atau collider.

Hutan mempertahankan jalur yang divalidasi server, menambah properti raster, kupu-kupu, daun jatuh, serta fauna prosedural. Rumah, tajuk, dan props menggunakan urutan kaki dan potongan foreground. Jalur ke wilayah masa depan tetap ditutup longsor, gerbang atau jembatan putus.

## Biota dan alat produksi

Kerangka tubuh dan frame fauna berasal dari [Procedural Pixel Creatures](https://github.com/idlerunner00/procedural-pixel-creatures), dibangkitkan offline melalui Core .NET yang dipin. Game browser hanya memuat PNG dan JSON, tanpa runtime C#. Sepuluh spesies menghasilkan 722 frame; arah dan pivot dibaca dari metadata. Gerakan kelompok memakai pemisahan, arah bersama, dan penghindaran medan/pemain. Target tangkapan dibatasi 30 piksel dari anchor server; gerak ini tidak diklaim sebagai simulasi biota otoritatif server.

Polyfork menyediakan model sumber pakis dan bambu yang dirender ortografis menjadi sprite. Strata menjadi referensi pemisahan permukaan, sisi, tepian, dan tangga; plugin Unity tersebut tidak dipasang di Godot. img2threejs merupakan kemungkinan alur rekonstruksi properti dari gambar, bukan konversi otomatis seluruh peta. Detail sumber dan kredit ada di [pipeline aset](../assets/asset-pipeline.md).

## Cahaya dan audio

Senter memakai `PointLight2D` dengan bayangan dari polygon batu. Lentera dan cahaya hutan mengikuti cuaca serta segmen waktu cerita. Pendekatan cahaya terhalang dinding merujuk [pembahasan SpriteCook](https://www.spritecook.ai/blog/2d-shadowcasting-torchlight-fog-of-war), menggunakan occluder native Godot; belum ada grid fog of war atau AI musuh berbasis line of sight.

SFX dan BGM yang diberikan pengguna dihubungkan ke konteks dunia. Pemutaran menunggu interaksi pengguna, perpindahan track memakai crossfade, audio lingkungan mempunyai bus filter tersendiri, serta heartbeat berhenti saat membaca atau keluar dari penyelaman. Tombol Suara dan V mengatur mute yang tersimpan. Audio tidak menentukan timer kuis, oksigen, atau hadiah.

Pilot laut kini memakai terrain 3D dan Sprite3D melalui renderer hybrid Godot. Kontrol tetap pada bidang dua sumbu. Kota serta hutan masih memakai renderer 2D dengan overlap, atmosfer, dan parallax. Rincian cakupan ada pada [pilot hybrid](hybrid-terrain.md); tidak ada perpindahan ke Three.js.
