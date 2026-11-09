# Waktu, cuaca, dan efek lingkungan

Implementasi ini menghubungkan waktu visual, cuaca, vegetasi, lampu, dan medium air. Server menentukan kalender tersimpan, cuaca harian untuk kebun, hari cerita, oksigen, misi, hadiah, dan pergantian penyelaman–kedai. Perubahan cuaca klien tidak membuka wilayah atau mengubah kemampuan berenang.

## Perilaku yang tersedia

| Unsur            | Implementasi                                                                                                                                                                                                                                                                             |
| ---------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Waktu dan cuaca  | `EnvironmentState.apply_calendar` menerima kalender/cuaca server dan menginterpolasi jam di antara heartbeat. Awan, hujan, angin dan arus visual mengikuti snapshot yang sama. Siklus lokal 360 detik hanya menjadi fallback native tanpa snapshot otoritatif.                           |
| Siang dan malam  | Kalender server menentukan siang/malam; tahap cerita tidak mereset jam akun. Fallback tanpa kalender tetap dapat memilih segmen malam untuk pengujian native. Darat modular dan laut hybrid memakai cahaya 3D; UI terpisah tetap terbaca. Lampu lokal mengikuti cahaya sekitar dan awan. |
| Hujan di darat   | Maksimal 56 garis miring mengikuti angin. Percikan Pixelbolt ditempatkan pada titik jalur hub atau hutan yang terlihat kamera. Titik ini mengikuti data jalan; belum ada deteksi benturan atap atau genangan. Hujan tidak digambar di bawah laut.                                        |
| Vegetasi         | Kekuatan shader kanopi mengikuti angin. Pangkal dan collider tetap. Api lentera miring sedikit, sedangkan uap bergeser perlahan dan lebih terlihat saat hujan.                                                                                                                           |
| Air permukaan    | Garis gelombang bergerak pada permukaan. Masuk laut memicu percikan singkat; ini efek visual, bukan perpindahan volume air.                                                                                                                                                              |
| Medium bawah air | `LivingWater.gd` menggambar partikel dalam koordinat dunia dengan dua lapisan parallax, jejak pendek di belakang penyelam, dan kilau lokal pada kontur batu. Arus visual mengubah perpindahan partikel.                                                                                  |
| Cahaya air       | Maksimal tiga berkas cahaya dangkal meredup menurut kedalaman, siang/malam, dan awan. Kedua sisi tiap berkas dipotong pada perpotongan kontur batu pertama.                                                                                                                              |
| Pembiasan        | Shader layar dengan filter nearest menggeser sampel sedikit. Pola caustic layar yang sudah ada memudar menurut kedalaman; kilau kontur dari `LivingWater` merupakan lapisan tambahan dalam koordinat dunia.                                                                              |
| Respons pemain   | Gelembung `Player.gd` lebih sering ketika bergerak atau oksigen rendah. Jejak air `LivingWater` hanya terbentuk saat bergerak. Tangkap fragmen memicu kilau memori Pixelbolt. Setelah naik, pemain menetes dan meninggalkan tanda basah sementara.                                       |
| Suara gerak      | `WorldFoley` membaca perpindahan nyata untuk langkah kayu/rumput, sapuan air, napas penyelam, tetesan gua, dan derit tali. Audio menunggu interaksi pengguna dan mengikuti mute/fokus. Musik serta filter bawah air berada pada bus lingkungan.                                          |

## Waktu dan data bersama

Kalender akun tersimpan di MongoDB dan dipulihkan saat refresh atau berganti perangkat. `calendarDay` berbeda dari `progress.day`: hari kalender dapat berganti tanpa membuka siklus cerita. Satu hari aktif setara 36 menit nyata. `CalendarSync` mengirim heartbeat sekitar lima detik dengan ID tab, status fokus dan jeda; Redis memberi satu penulis lease 20 detik. Tab lain menerima snapshot baca-saja. Interval lebih dari 15 detik tidak ditambahkan, sehingga offline atau tab yang lama terputus tidak mengejar waktu secara massal.

Server memaksa jeda ketika penyelaman sedang membaca atau menjawab tantangan. Klien melaporkan jeda modal serta kehilangan fokus. Perubahan hari, pertumbuhan petak dan penyimpanan kalender dilakukan melalui transaksi; retry tidak menggandakan pertumbuhan. Hujan harian ditentukan server dan dapat memenuhi kebutuhan air tanaman. Shader atau preferensi efek hujan tidak menentukan hasil kebun.

`EnvironmentState.apply_calendar` menerima `minuteOfDay`, `calendarDay`, `calendarRevision`, status `writer`, dan cuaca. Interpolasi lokal berhenti ketika snapshot sudah terlalu lama atau tab bukan penulis. `update_story(day, stage)` hanya mempertahankan konteks dan fallback pengujian ketika kalender otoritatif belum tersedia; fungsi ini tidak mengubah kalender akun.

`snapshot()` menyediakan jam, cuaca, intensitas hujan, cahaya, angin, arus, fase hari, preferensi pengurangan gerak, serta status kalender seperti `authoritative`, `calendarDay`, `clockConnected` dan `clockWriter`. Arus adalah parameter visual, bukan instruksi untuk menggeser badan pemain atau menghitung oksigen.

Preferensi pengurangan gerak mengikuti `prefers-reduced-motion` ketika tersedia, dapat diatur melalui `EnvironmentState.set_reduced_motion(bool)`, dan disimpan di `user://environment.cfg`. Belum ada panel kualitas efek khusus. Pengurangan gerak membatasi partikel, jejak, pembiasan dan goyangan; pengaturan itu tidak mengubah kalender atau cuaca server.

## Integrasi renderer dan occlusion

`EnvironmentEffects.configure("hub" | "forest" | "sea")` memilih suasana. Pembiasan berada pada CanvasLayer 3, `LivingWater` pada layer 4, cuaca pada layer 5, HUD pada layer 10, dan dialog di atasnya. Efek dunia tidak meredupkan teks HUD.

`HybridOcean.setup(main)` memasang `LivingWater`, yang membaca posisi penyelam dan kamera 2D otoritatif. Perbandingan F6 dibatasi pada build debug native; web release tetap memakai renderer 3D. Parallax diterapkan pada partikel dan bidang latar dekoratif `OceanBackdrop`; terrain batu yang dapat bertabrakan, target tangkapan, dan collider tidak digeser.

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

Kalender tersimpan dan hujan harian otoritatif sudah tersedia untuk kebun. Belum tersedia prakiraan, musim, pasang-surut, badai/petir, simulasi volume air, benturan hujan per atap, genangan persisten, atau pengeringan menurut material. Suara hujan, angin, dan guntur belum disimulasikan terus-menerus. Bayangan tidak mencakup semua objek dan tidak menentukan deteksi musuh. Pengujian FPS, baterai, Safari iOS, dan perangkat Android fisik tetap diperlukan.

Jika cuaca menjadi mekanik permainan, server harus menerbitkan kondisi serta versi transisinya. Arus yang memengaruhi pemain, oksigen, akses, spawn, dan hadiah harus dihitung dari kondisi server, bukan jam lokal.

## Pekerjaan baru: perspektif atmosfer pada latar laut

**Status: implementasi native, uji semantik, dan enam pemeriksaan browser Chromium lokal lulus.** Latar laut sebelumnya masih terasa datar meskipun partikel dan mesh terrain sudah bergerak/bervolume. Pembaruan ini menambahkan komposisi jarak melalui tebing, reruntuhan, vegetasi, dan karang pada tiga bidang dengan respons kamera serta warna berbeda.

Tiga kelompok kedalaman—Segaran, Wringin, dan Jalatunda/Tamansari—masing-masing memerlukan bidang jauh, tengah, dan dekat. Siluet jauh menggunakan biru air dengan kontras dan kejenuhan paling rendah; bidang tengah memberi bentuk lembah, sulur atau rusuk gua; tepian dekat memakai detail serta nilai warna yang lebih tegas. Pemain dan objek interaksi tetap lebih mudah dikenali daripada dekorasi. Gambar harus orisinal, memakai aset transparan yang tidak menimbulkan kartu persegi, dan menyisakan ruang kosong pada jalur berenang. Tidak ada detail latar yang menjadi petunjuk palsu bahwa area solid atau zona lanjutan dapat dimasuki.

Kontrak penerimaan yang harus dipenuhi:

- Respons terhadap perpindahan kamera berbeda antarbidang dan dapat diukur dari transformasi, termasuk saat arah gerak berbalik. Collider dan landmark otoritatif tidak ikut bergeser.
- Pemisahan warna/kontras antarjarak tetap terbaca pada siang, berawan, malam, dan pergantian zona; perpindahan memakai transisi halus tanpa kilatan.
- Dekorasi jauh tidak menutupi pemain/HUD. Jumlah instance serta pembaruan dibatasi, dengan culling yang tidak menghasilkan bidang kosong pada tepi viewport.
- Mode pengurangan gerak mengurangi gerakan dekorasi mandiri; penanda kedalaman statis tetap tersedia. Pengaturan ini tidak mengubah arus, oksigen, hadiah, atau progres server.
- Uji headless memeriksa parallax dan pemisahan atmosfer dari state terukur, serta kesamaan data collision sebelum/sesudah konfigurasi. Uji browser kemudian membandingkan beberapa posisi kamera dan memastikan tidak ada error shader atau alpha-card.

Komposisi tiap zona dan batas budaya dirinci pada [referensi dan integrasi](../reference-integrations.md#pekerjaan-baru-komposisi-latar-bawah-air). Bukti native diperiksa pada posisi masuk laut dan kedalaman lanjut. Chromium lokal juga lulus enam pemeriksaan backdrop bersama alur permainan, fauna, cahaya, dan gua. Kamera bergerak sekitar −790 piksel secara horizontal dan +276 piksel secara vertikal; ketiga bidang mempunyai pergeseran berbeda yang cocok dengan faktor parallax masing-masing, dan ketiganya berubah tint saat turun. Hasil serta pasangan tangkapan ada di `artifacts/godot/backdrop/`; bukan pengukuran FPS perangkat fisik.

Implementasi `OceanBackdrop.gd` memakai atlas orisinal enam sel, 48 bidang dekorasi dan satu bidang warna air kontinu. Bidang jauh/tengah/dekat berada pada z −1550/−950/−420 dengan faktor respons kamera X/Y 0,18/0,12; 0,42/0,28; dan 0,70/0,55. Kontras berturut-turut 0,35/0,64/0,88. Pergeseran vertikal dibatasi 220 piksel; vegetasi tidak ditampilkan di kedalaman lebih dari 60 meter. Mode pengurangan gerak menghentikan goyangan mandiri, sementara petunjuk kedalaman dari perpindahan kamera dipertahankan.

Shader membuang alpha di bawah 0,2. Latar transparan atlas mengandung alpha sangat rendah, bukan selalu nol mutlak; uji membaca nilai alpha sebenarnya dan keberadaan siluet tampak pada keenam sel. Shader yang sama dipakai seluruh bidang; parameter tiap bidang berbeda. Batas 48 bidang adalah batas implementasi, bukan klaim FPS atau kelayakan pada HP fisik.

`scripts/tests/ocean-backdrop.gd` lulus tanpa error: 24 sampel tepi transparan, urutan tiga jarak/kontras, perpindahan mesh nyata pada sumbu X dan Y, batas 49 mesh, mode pengurangan gerak, serta data collision, koin, inventori, progres dan oksigen yang tidak berubah. Uji ini tetap menjadi bagian dari `npm run check:world`; urutan dan jumlah keseluruhan mengikuti runner revisi yang diuji.

## Verifikasi Plan 03

Pengujian backend terbaru mencatat 76 tes lulus, termasuk kalender, kepemilikan penulis, tidur dan pertumbuhan kebun. Griya Sasmita diuji melalui render native siang/malam: dua lampu hangat mengenai lantai, sedangkan ambient khusus interior menjaga jalan serta furnitur tetap terbaca. Efek malam tidak meredupkan HUD. Hasil final regresi browser, deployment dan CI revisi Plan 03 masih dalam verifikasi; catatan browser lingkungan sebelumnya tetap merupakan bukti revisi terdahulu.

Tab yang tidak terlihat melepas lease kalender miliknya agar tab aktif dapat mengambil alih. Tab berlatar tidak dapat mengambil atau memperpanjang lease; dialog pada tab aktif tetap mempertahankan jeda. Interval offline tidak dikejar saat tersambung kembali.
