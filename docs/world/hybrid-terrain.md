# Pilot lingkungan hybrid 2.5D

Pilot mengganti tampilan laut dengan geometri 3D yang dirender melalui Godot Compatibility. Daratan Bandar Hujung dan hutan masih memakai renderer 2D sebelumnya. Kontrol penyelam tetap pada bidang dua sumbu, seperti permainan petualangan laut tampak samping; tidak ada gerakan bebas ke arah kamera.

`HybridOcean.gd` membuat SubViewport 480 × 270, kamera ortografis miring 12 derajat, pencahayaan lingkungan, lampu arah, dan senter SpotLight3D. Hasil diperbesar dengan nearest filtering. HUD dan teks tetap pada resolusi antarmuka. Parallax hanya menggeser dekorasi jauh, sedangkan batu dan bidang gerak tetap mengikuti koordinat dunia.

`TerrainGeometry.gd` membangun volume batu dengan permukaan, tepian, sisi, dan bagian belakang. Geometri memakai tekstur piksel asli proyek dan material yang menerima cahaya. Bentuk proyeksinya mengikuti penghalang server. Gua uji berada pada celah antara terumbu atas dan lantai Segaran; gambar lubang tidak menggantikan jalur yang benar-benar dapat dilalui.

`OceanActors.gd` menempatkan Sprite3D karakter, biota, dan objek interaktif pada posisi game yang sama. Bingkai karakter, identitas tampilan, arah renang, gerak fauna, dan status tangkapan dibaca dari sistem yang sudah berjalan. Sprite menjalani depth test sehingga batu di depannya dapat menutup bagian tubuh yang tumpang tindih. Fisika gerak, jarak interaksi, oksigen, hadiah, dan progres tetap memakai kontrak server sebelumnya.

F6 menyediakan perbandingan renderer saat menyelam. Ini alat pemeriksaan visual, bukan teleport, pembuka wilayah, atau perubahan kemampuan pemain. Permukaan dan hutan tetap memakai mode 2D saat keluar dari air. Atlas geografis tetap menampilkan koordinat permainan yang sama.

Model Small Reef Rock Polyfork disediakan sebagai GLB runtime, dengan kredit CC BY 4.0 dalam `resources/models/ATTRIBUTION.txt`. Mesh terrain dibuat di Godot; Strata tetap merupakan referensi metode penataan medan, bukan plugin Unity yang dipasang. Tidak ada konversi otomatis seluruh gambar melalui img2threejs.

Pemeriksaan browser dijalankan dengan `VERIFY_HYBRID=1 APP_TEST_ORIGIN=http://localhost:3100 node scripts/godot-browser.mjs` dan fixture privat. Pemeriksaan mencakup mesh 3D aktif, sprite, kamera ortografis, pergantian F6, serta perjalanan melewati celah gua yang divalidasi server. Screenshot disimpan di `artifacts/godot/hybrid/` dan tidak memasukkan referensi moodboard.

Pilot ini belum mengubah kota atau hutan menjadi medan 3D bertingkat. Kualitas visual dan performa perangkat fisik perlu dinilai terpisah; keberadaan mesh atau kelulusan tes tidak membuktikan kualitas seni maupun FPS pada HP.

Efek partikel menggunakan modul 2D dan gelembung karakter yang sudah berjalan. Partikel mesh CPUParticles3D dikeluarkan dari pilot setelah pengujian WebGL menampilkan bentuk partikel yang membesar dan peringatan buffer. Mesh terrain, aktor Sprite3D, senter, dan bayangan tetap memakai renderer 3D. Pengujian browser tidak menggantikan verifikasi kompatibilitas dan performa pada GPU/perangkat fisik.

Firefox berhasil merender scene hybrid tanpa error shader dan tanpa bidang transparan yang salah. Namun cold startup melewati batas pengujian 90 detik; kelanjutan tangkapan, gua, dan peta pada renderer baru belum terverifikasi di Firefox. Jalur lengkap pilot sudah lulus pada Chromium lokal dan HTTPS staging.

Perbaikan lanjutan menempatkan senter di depan helm pada kedua arah, mengganti tekstur batu yang berulang dengan campuran crop bertumpang-tindih, dan menempatkan tiga variasi koral transparan pada kontur ledge bersama. Dermaga memakai volume papan, fascia, penutup ujung, dan tangga terbuka pada titik ekstraksi yang sama; tidak ada collider tambahan di jalur berenang.

Setelah partikel mesh dihapus, pemeriksaan screenshot browser tidak lagi memperlihatkan bidang besar di sekitar karakter. Peringatan pembaruan buffer masih teramati pada SwiftShader; hasil ini belum membuktikan performa atau kompatibilitas GPU perangkat fisik.
