# Pilot lingkungan hybrid 2.5D

Pilot mengganti tampilan laut dengan geometri 3D yang dirender melalui Godot Compatibility. Daratan Bandar Hujung dan hutan kini memakai renderer komponen `LandWorld3D` terpisah dengan elevasi pandang 35°, footprint bersama layout 5 dan billboard karakter. Rincian terbaru ada pada [daratan modular](land-layering.md). Kontrol penyelam tetap pada bidang dua sumbu, seperti permainan petualangan laut tampak samping; tidak ada gerakan bebas ke arah kamera.

`HybridOcean.gd` membuat SubViewport 480 × 270, kamera ortografis miring 12 derajat, pencahayaan lingkungan, lampu arah, dan senter SpotLight3D. Hasil diperbesar dengan nearest filtering. HUD dan teks tetap pada resolusi antarmuka. Parallax hanya menggeser dekorasi jauh, sedangkan batu dan bidang gerak tetap mengikuti koordinat dunia.

`TerrainGeometry.gd` membangun volume batu dengan permukaan, tepian, sisi, dan bagian belakang. Geometri memakai tekstur piksel asli proyek dan material yang menerima cahaya. Bentuk proyeksinya mengikuti penghalang server. Gua uji berada pada celah antara terumbu atas dan lantai Segaran; gambar lubang tidak menggantikan jalur yang benar-benar dapat dilalui.

`OceanActors.gd` menempatkan Sprite3D karakter, biota, dan objek interaktif pada posisi game yang sama. Bingkai karakter, identitas tampilan, arah renang, gerak fauna, dan status tangkapan dibaca dari sistem yang sudah berjalan. Sprite menjalani depth test sehingga batu di depannya dapat menutup bagian tubuh yang tumpang tindih. Fisika gerak, jarak interaksi, oksigen, hadiah, dan progres tetap memakai kontrak server sebelumnya.

F6 menyediakan perbandingan renderer hanya pada build debug native. Ekspor web release tetap memakai renderer 3D; jalur perbandingan 2D lama menimbulkan peringatan buffer WebGL dan tidak dibuka untuk pemain. Saat keluar dari air, tampilan beralih ke renderer komponen darat; koordinat gerak tetap dua sumbu. Atlas geografis tetap menampilkan koordinat permainan yang sama.

Model Small Reef Rock Polyfork disediakan sebagai GLB runtime, dengan kredit CC BY 4.0 dalam `resources/models/ATTRIBUTION.txt`. Mesh terrain dibuat di Godot; Strata tetap merupakan referensi metode penataan medan, bukan plugin Unity yang dipasang. Tidak ada konversi otomatis seluruh gambar melalui img2threejs.

Pemeriksaan browser dijalankan dengan `VERIFY_HYBRID=1 APP_TEST_ORIGIN=http://localhost:3100 node scripts/godot-browser.mjs` dan fixture privat. Pemeriksaan mencakup mesh 3D aktif, sprite, kamera ortografis, F6 yang tidak mengganti renderer release, lampu ke dua arah, serta perjalanan melewati celah gua yang divalidasi server. Screenshot disimpan di `artifacts/godot/hybrid/` dan tidak memasukkan referensi moodboard.

Pilot laut ini terpisah dari rebuild modular daratan yang sekarang menyediakan pelataran dan prop 3D bertingkat. Rebuild darat masih menjalani finishing lokal dan belum dinyatakan lulus deployment final. Kualitas visual dan performa perangkat fisik perlu dinilai terpisah; keberadaan mesh atau kelulusan tes tidak membuktikan kualitas seni maupun FPS pada HP.

Efek partikel menggunakan modul 2D dan gelembung karakter yang sudah berjalan. Partikel mesh CPUParticles3D dikeluarkan dari pilot setelah pengujian WebGL menampilkan bentuk partikel yang membesar dan peringatan buffer. Mesh terrain, aktor Sprite3D, senter, dan bayangan tetap memakai renderer 3D. Pengujian browser tidak menggantikan verifikasi kompatibilitas dan performa pada GPU/perangkat fisik.

Firefox berhasil merender scene hybrid tanpa error shader dan tanpa bidang transparan yang salah. Namun cold startup melewati batas pengujian 90 detik; kelanjutan tangkapan, gua, dan peta pada renderer baru belum terverifikasi di Firefox. Jalur pilot sebelum penambahan medium air terbaru sudah lulus pada Chromium lokal dan HTTPS staging. Pengujian gabungan medium terbaru yang dicatat di bawah dijalankan pada server lokal.

Perbaikan lanjutan menempatkan senter di depan helm pada kedua arah, mengganti tekstur batu yang berulang dengan campuran crop bertumpang-tindih, dan menempatkan tiga variasi koral transparan pada kontur ledge bersama. Dermaga memakai volume papan, fascia, penutup ujung, dan tangga terbuka pada titik ekstraksi yang sama; tidak ada collider tambahan di jalur berenang.

Setelah partikel mesh dihapus, pemeriksaan screenshot patch tersebut tidak lagi memperlihatkan bidang partikel yang membesar di sekitar karakter. Peringatan pembaruan buffer juga pernah teramati pada SwiftShader; hasil pengujian lokal belum membuktikan performa atau kompatibilitas GPU perangkat fisik.

## Pelapisan medan dan medium air

`TerrainLayerProfile.gd` kini menyediakan tiga profil orisinal: batu kapur berpori, sedimen karst, dan basal retak. Setiap profil memisahkan warna permukaan, sisi, tepian, kedalaman ekstrusi, serta tiga atau empat tingkat teras. `TerrainGeometry.gd` membentuk pita tepi dan relief muka dari profil tersebut sambil mempertahankan proyeksi `terrainContours` yang dipakai server. Metadata sumber, revisi referensi, dan batas pemakaiannya ada di `tools/terrain-layers/source.json`.

Strata menjadi acuan cara memisahkan peran permukaan, sisi, tepian, dan elevasi. Ini implementasi Godot orisinal, bukan pemasangan Unity atau salinan kode, shader, maupun aset Strata. Catatan pemeriksaan sumber belum menyatakan lisensi upstream; tidak ada berkas upstream yang dimasukkan sebagai ketergantungan runtime. Pelapisan baru ini berlaku pada laut pilot. Kota dan hutan memakai renderer komponen terpisah; bukti laut dalam bagian ini tidak menjadi bukti penerimaan renderer darat.

`LivingWater.gd` menambahkan medium air native 2D di atas hasil renderer 3D: partikel berparallax dalam koordinat dunia, jejak renang, kilau kontur, dan cahaya dangkal yang dipotong kontur batu. Intensitas berkas dan pencahayaan mengikuti waktu, kedalaman, serta awan; arus dekoratif memakai kondisi cuaca bersama. Tidak ada partikel mesh 3D atau simulasi fluida. Rincian anggaran efek, pengurangan gerak, dan batas occlusion ada pada [dokumentasi lingkungan](environment.md).

Pengujian gabungan lokal mencatat 29 dari 29 fauna berpindah dalam selang 2,4 detik, empat kawanan, 33 partikel medium, dan enam ray tepi cahaya yang terpotong kontur. Dua tangkapan layar di `artifacts/godot/living/` memperlihatkan perubahan posisi fauna dan pose renang dengan HUD tetap terbaca. Efek medium sengaja lebih halus daripada aktor dan objek interaktif; keberadaan penghitung bukan pengganti peninjauan gambar. Uji ini belum memverifikasi semua kedalaman, komposisi aset, atau performa perangkat fisik.
