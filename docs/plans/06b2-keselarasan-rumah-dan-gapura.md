# 06-B2: keselarasan rumah warga dan gapura

Arahan pengguna 9 November 2026: luruskan arah rumah warga dan bangun ulang memakai sistem modular 3D seperti rumah Nala; gapura juga harus cocok dengan arah jalan. Ini memajukan pekerjaan alignment sebelum perluasan bangunan baru. Diagnosis loading publik tetap terbuka dan tidak dianggap selesai oleh paket visual ini.

## Hasil yang dituju

Rumah memiliki bidang siku-siku dalam ruang dunia. Kamera kiri tiga perempat membuat sisi dan atap terlihat menyudut secara alami. Dinding, lantai, pintu, tangga/serambi, atap, lampu dan collider mengikuti satu transform bangunan. Facing pintu mengikuti akses jalan masing-masing; identitas pelana, limas, bengkel, balai dan pos tetap berbeda. Griya Sasmita serta alignment dermaganya yang sudah diterima dipertahankan.

Tujuh bangunan hub yang diperbaiki: Kedai Waras, galangan Beno, pos Cakrawala, Balai Wirabhumi, rumah Ratih, Sari dan Tedi. Kandidat option B layout10 mempertahankan luas fisik, rasio sisi, pusat, tinggi dan elevasi sambil menghilangkan shear lama. Kandidatnya sudah ada; jangan kembali ke option A yang membesarkan luas52,35%. Akses NPC, shelter dan migrasi save wajib mengikuti footprint baru.

Untuk gapura hub–hutan dan pintu masuk hutan, bukaan searah gerak sepanjang jalan, sedangkan palang melintang tegak lurus arah jalan **dalam ruang fisik 3D**. Pusat gapura berada pada garis jalur. Tiang berdiri di kedua tepi, atap/papan/lampu mengikuti basis tiang yang sama. Kamera, portal dan spawn tidak dipindahkan untuk menyamarkan kesalahan orientasi.

## Temuan awal source

- Tujuh footprint rumah lama mempunyai sudut sumbu86,086°–98,661°. Renderer membentuk kerangka lokal dari edge tersebut, sehingga shear terbawa ke dinding dan atap. Griya sudah90°.
- `_gateway_arch` saat ini menerima dua titik hardcoded. Gapura hub berpusatx2287 sementara jalur dan portal x2295. Gapura hutan memakai tiang horizontal pada y1358, sementara jalur masuk berjalan diagonal dari85,1378 menuju200,1320.
- Roof/sign gapura memakai box sejajar sumbuX tanpa transform bersama. Menggeser tiang saja belum memperbaiki seluruh gapura.
- Metadata/collider harus menjadi sumber yang sama. Tiang gapura hutan belum mempunyai pasangan obstacle tersendiri; penambahan collision harus diperiksa sebagai perubahan layout, bukan sekadar dekorasi.

## Pembagian dan urutan

1. Lane rumah memperbarui kandidat option B ke main terkini, mengulang typecheck/API/migrasi dan menyiapkan28frame perbandingan siang/malam. Lane ini tidak mengubah gapura.
2. Lane gapura membuat metadata kerangka berbasis jalur serta komponen native untuk tiang, atap dan papan. Integrator menghubungkannya ke map/collider/layout. Tidak ada engine browser kedua.
3. Lane QA menurunkan sasaran occlusion dari proyeksi kiri aktual serta menyiapkan pendekatan rumah/gapura dengan input fisik; tidak menghapus assertion reveal atau teleport agar lolos.
4. Integrator menggabungkan source, menjalankan pemeriksaan dunia dan native bergantian, meninjau gambar sebelum/sesudah, lalu menguji gerak/pintu/shelter/save pada kandidat yang dipin. Ekspor serta rilis merupakan tahap sesudah penerimaan tersebut.

Semua import/headless/native/browser memakai satu slot bergantian. Source/CPU dapat paralel. Satu penulis per berkas dalam worktree; konflik integrasi manifest ditangani integrator. Cache baru yang sudah tidak diperlukan dibersihkan setelah paket, sementara source dan bukti dipertahankan.

## Penerimaan

- Delapan rumah termasuk Griya mempunyai basis siku-siku; sudut rumah/dek/jalan tampak konsisten pada kamera default−45°/35°.
- Native memperlihatkan fasad, ketebalan sisi, sambungan atap/serambi/tiang serta pintu tanpa clipping. Gambar siang/malam memakai posisi pembanding sama.
- Palang gapura tegak lurus tangen jalan fisik, pusatnya berada di jalan, atap/papan mengikuti basis yang sama. Tiang tidak memakan koridor jalan dan mempunyai collider yang sesuai.
- Jalur hub–hutan dapat dilalui kedua arah; tangga dan portal tetap terhubung. Sisi tiang benar-benar menghalangi, sedangkan bukaan tetap cukup untuk pemain13px clearance.
- Semua tujuan kerja/rumah/berteduh tetap dapat dicapai; dialog dan aktivitas lanjut bekerja. Recovery save lama tetap pada lantai tersambung, tanpa reset spawn atau perubahan inventori/ekonomi.
- Full API/typecheck/world, native dan gameplay aktual dicatat terpisah. Hasil lokal tidak otomatis berarti sudah tampil di staging atau lolos browser publik default.

## Koreksi lanjutan pengguna: terrain, sambungan area dan warna

Pengguna menolak tebing kotak/siku90°, pulau yang tampak terputus, tangga seperti bidang datar, serta tekstur yang tampak burik. Target warna mengikuti gambar login/loading: cerah, lingkungan sejuk, cahaya matahari/lampu hangat. Piksel tajam tetap dipertahankan, sedangkan noise material dikurangi.

- Terrain batu memakai kontur bahu/tanah/batuan yang menyambung, faceted dan bertumpu pada lantai bawah. Tidak menutupi akses tangga atau mengubah collision/save untuk menyamarkan masalah visual. Dek kayu tetap konstruksi lurus.
- Di balik portal desa–hutan harus tampak potongan area tujuan dengan basis jalan dan bidang sambungan yang sama. Preview hanya visual; perpindahan area tetap melalui interaksi dan loading. Tidak menambahkan lokasi yang dapat diinjak tanpa dukungan server.
- Ketinggian kaki harus mengikuti tread tangga yang benar-benar dirender. Ramp tetap kontinu. Naik/turun, diam, pause dan reduced motion diperiksa bersama geometri, tanpa mengklaim artwork/IK dua kaki sudah selesai.
- Material dikurangi bintik kontras tinggi; warna dasar tanah/kayu/hijau diperbaiki sebelum menaikkan saturasi global. Bandingkan native siang/malam pada kamera, waktu dan kualitas sama; jangan menaikkan resolusi dan biaya GPU tanpa pengukuran.

Pembagian lanjutan: shelter mengerjakan helper tepi terrain; character mengerjakan sampling/gerak tangga dan helper geometri; website memegang acceptance browser dan audit sisa pekerjaan. Integrator satu-satunya penulis hook LandWorld3D, palet/shader, sambungan area, manifest dan dokumentasi aktif. Seluruh engine/browser tetap bergantian.

## Sistem dan lisensi

Runtime tetap Godot4.7.2 dengan konstruksi mesh modular native yang juga dipakai Griya. Port aktif Noxe terbatas pada helper kamera; referensi konstruksi bangunannya dipakai sebagai arahan, bukan klaim integrasi seluruh engine. Notice MIT dan pin upstream dipertahankan. Tidak ada aset moodboard yang didistribusikan, library runtime baru, atau generasi gambar dalam tahap alignment ini.

Status awal: kandidat rumah telah diterapkan ke worktree integrasi; gapura dan QA sedang pada tahap source/CPU. Belum ada native baru, ekspor atau rilis paket06-B2. Laporan progres harus diperbarui setelah pemeriksaan aktual.
