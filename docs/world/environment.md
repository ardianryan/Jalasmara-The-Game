# Waktu, cuaca, dan efek lingkungan

Implementasi ini menghubungkan waktu visual, cuaca, vegetasi, lampu, dan medium air. Server tetap menentukan hari cerita, oksigen, misi, hadiah, dan pergantian penyelaman–kedai. Perubahan cuaca klien tidak membuka wilayah atau mengubah kemampuan berenang.

## Perilaku yang tersedia

| Unsur | Implementasi |
| --- | --- |
| Waktu dan cuaca | `EnvironmentState` mempertahankan jam dalam satu tab dan menghasilkan siklus lokal 90 detik: cerah, berawan, hujan ringan, lalu cerah. Awan, hujan, angin, dan arus visual berasal dari kondisi yang sama. |
| Siang dan malam | Tahap cerita `night` memilih segmen malam. Warna dunia 2D memakai `CanvasModulate`; laut hybrid memakai cahaya dan kabut 3D. Lampu lokal mengikuti cahaya sekitar dan awan. |
| Hujan di darat | Maksimal 56 garis miring mengikuti angin. Percikan Pixelbolt ditempatkan pada titik jalur hub atau hutan yang terlihat kamera. Titik ini mengikuti data jalan; belum ada deteksi benturan atap atau genangan. Hujan tidak digambar di bawah laut. |
| Vegetasi | Kekuatan shader kanopi mengikuti angin. Pangkal dan collider tetap. Api lentera miring sedikit, sedangkan uap bergeser perlahan dan lebih terlihat saat hujan. |
| Air permukaan | Garis gelombang bergerak pada permukaan. Masuk laut memicu percikan singkat; ini efek visual, bukan perpindahan volume air. |
| Medium bawah air | `LivingWater.gd` menggambar partikel dalam koordinat dunia dengan dua lapisan parallax, jejak pendek di belakang penyelam, dan kilau lokal pada kontur batu. Arus visual mengubah perpindahan partikel. |
| Cahaya air | Maksimal tiga berkas cahaya dangkal meredup menurut kedalaman, siang/malam, dan awan. Kedua sisi tiap berkas dipotong pada perpotongan kontur batu pertama. |
| Pembiasan | Shader layar dengan filter nearest menggeser sampel sedikit. Pola caustic layar yang sudah ada memudar menurut kedalaman; kilau kontur dari `LivingWater` merupakan lapisan tambahan dalam koordinat dunia. |
| Respons pemain | Gelembung `Player.gd` lebih sering ketika bergerak atau oksigen rendah. Jejak air `LivingWater` hanya terbentuk saat bergerak. Tangkap fragmen memicu kilau memori Pixelbolt. Setelah naik, pemain menetes dan meninggalkan tanda basah sementara. |
| Suara gerak | `WorldFoley` membaca perpindahan nyata untuk langkah kayu/rumput, sapuan air, napas penyelam, tetesan gua, dan derit tali. Audio menunggu interaksi pengguna dan mengikuti mute/menu. Musik serta filter bawah air berada pada bus lingkungan. |

## Waktu dan data bersama

`EnvironmentState.update_story(day, stage)` mengatur konteks. Pergantian hari atau segmen siang/malam mengulang jam visual; perpindahan tahap siang seperti `dive` ke `boss` tidak mengulangnya. Tiga detik nyata memajukan satu menit: siang mulai 08:00 dan berhenti 17:50; malam mulai 18:30 dan berhenti 23:50. Tidak ada siklus 24 jam bebas.

`snapshot()` menyediakan `clock`, `weather`, `rain`, `clouds`, `daylight`, `night`, `day`, `phase`, `wind_x`, `wind_y`, `current_x`, `current_y`, `sea_state`, dan `reduced_motion`. Intensitas hujan maksimum 0,6. Arus ini adalah parameter visual; bukan instruksi untuk menggeser pemain atau menghitung oksigen.

Jam dan cuaca tidak disimpan ke server. Refresh memulai segmen visual sesuai progres; perangkat berbeda tidak dijamin memiliki cuaca yang sama. Preferensi pengurangan gerak mengikuti `prefers-reduced-motion` ketika tersedia, dapat diatur melalui `EnvironmentState.set_reduced_motion(bool)`, dan disimpan di `user://environment.cfg`. Belum ada panel kualitas efek khusus. Pengurangan gerak membatasi partikel, jejak, pembiasan, dan goyangan; jam serta progres cerita tetap berjalan.

## Integrasi renderer dan occlusion

`EnvironmentEffects.configure("hub" | "forest" | "sea")` memilih suasana. Pembiasan berada pada CanvasLayer 3, `LivingWater` pada layer 4, cuaca pada layer 5, HUD pada layer 10, dan dialog di atasnya. Efek dunia tidak meredupkan teks HUD.

`HybridOcean.setup(main)` memasang `LivingWater`, yang membaca posisi penyelam dan kamera 2D otoritatif. Efek tetap tersedia saat perbandingan F6 memakai renderer laut 2D. Parallax hanya diterapkan pada partikel dekoratif; batu, target tangkapan, dan collider tidak digeser.

Prinsip cahaya yang terhalang dinding mengacu pada [penjelasan shadowcasting SpriteCook](https://www.spritecook.ai/blog/2d-shadowcasting-torchlight-fog-of-war). Implementasi proyek memakai perpotongan segmen pada `terrainContours`, sesuai bentuk peta yang tidak berupa kisi. Kode artikel tidak disalin. Pemotongan ini berlaku pada berkas cahaya dekoratif; belum menjadi fog of war, deteksi musuh, atau aturan pengetahuan pemain. Senter dan bayangan pada mesh tetap ditangani renderer 3D, sedangkan renderer 2D memakai occluder native.

`water.gdshader` memakai `hint_screen_texture` dan filter nearest. Kekuatan pembiasan normal 0,0015, turun menjadi 0,00025 saat pengurangan gerak aktif. `foliage.gdshader` hanya menggeser vertex di atas pangkal; kekuatan akhirnya dibatasi delapan piksel. Efek ini tidak mengubah tabrakan atau jangkauan interaksi.

## Batas dan verifikasi

Tidak ada partikel mesh `CPUParticles3D` pada laut hybrid. Jalur tersebut dihapus setelah pengujian WebGL memperlihatkan partikel membesar dan peringatan buffer. Efek air sekarang memakai gambar native 2D dan animasi atlas Pixelbolt orisinal proyek.

- `LivingWater`: maksimal 48 partikel, 18 jejak berumur 1,1 detik, tiga berkas cahaya dengan enam ray tepi, dan 20 kandidat kilau kontur. Sampel diperbarui setiap 0,16 detik. Mode pengurangan gerak membatasi partikel menjadi 16 dan menghentikan pembentukan jejak baru.
- Hujan: maksimal 56 garis, atau 20 dalam mode pengurangan gerak. Pencarian titik percikan memeriksa maksimal enam kandidat jalur setiap 0,4 detik; jumlah sprite benturan juga dibatasi.
- Percikan lensa lama: maksimal 24 entri berumur 0,7 detik, dengan jeda pemanggilan 0,12 detik. Tetes lensa tidak digambar dalam mode pengurangan gerak.
- Gelembung karakter: maksimal 24 entri berumur 2,2 detik. Batas ini terpisah dari partikel medium dan fauna; bukan batas total gambar seluruh permainan.

Uji permanen dijalankan dari akar repositori:

```sh
godot --headless --path client-godot --script "$PWD/scripts/tests/living-water.gd"
```

Uji memeriksa kondisi cerah/hujan/malam, hubungan angin dan arus, penghentian ray pada dinding, batas efek, pengurangan gerak, percikan pada jalur yang terlihat, serta oksigen dan koin yang tidak berubah. Render native Compatibility juga diperiksa untuk hujan, vegetasi, dan air.

Pada pengujian browser gabungan lokal, 29 dari 29 fauna berpindah dalam selang 2,4 detik, dengan empat kelompok kawanan. Cuplikan yang sama mencatat 33 partikel air, tiga berkas, enam ray yang terpotong kontur, serta arus visual yang bergerak. Hasil dan dua tangkapan layar ada di `artifacts/godot/living/`, yang diabaikan Git. Ini membuktikan simulasi bergerak dan integrasi efek, bukan performa pada HP fisik atau kualitas seluruh komposisi visual.

## Batas implementasi

Belum tersedia cuaca otoritatif/persisten, prakiraan, musim, pasang-surut, badai/petir, simulasi volume air, benturan hujan per atap, genangan persisten, atau pengeringan menurut material. Suara hujan, angin, dan guntur belum disimulasikan terus-menerus. Bayangan tidak mencakup semua objek dan tidak menentukan deteksi musuh. Pengujian FPS, baterai, Safari iOS, dan perangkat Android fisik tetap diperlukan.

Jika cuaca menjadi mekanik permainan, server harus menerbitkan kondisi serta versi transisinya. Arus yang memengaruhi pemain, oksigen, akses, spawn, dan hadiah harus dihitung dari kondisi server, bukan jam lokal.
