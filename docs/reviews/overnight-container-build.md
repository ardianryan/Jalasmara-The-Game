# Packaging kandidat overnight

Build Docker pertama dari bundle480d27d gagal sebelum image runtime dibuat. Vite tidak menemukan `client-godot/resources/art/hud-bahari-v1/button-normal.png`, yang dipakai tombol Menu host. Build lokal lulus karena seluruh checkout tersedia; Dockerfile hanya menyalin apps/packages. Log `.runtime/overnight-image-build.log` menyimpan kegagalan sebenarnya.

Perbaikan packaging menyalin satu PNG original tersebut ke path build yang sama. Tidak menduplikasi artwork sumber, tidak menyalin cache/engine Godot, dan tidak mengubah kode UI, ukuran piksel, bundle dependency atau PCK1315f346. Pembangunan image ulang menjadi verifikasi yang diperlukan, bukan klaim lulus dari patch Dockerfile saja. Image staging d60 dan rollback43bd tetap dipertahankan; belum ada aktivasi kandidat saat laporan awal ini ditulis.

Bundle dasar memakai source480d27d, ekspor593dc79/PCK1315f346/64.491.320byte. Arsip sementara265.236.480byte SHA-256 `021ae26444e887f3e321f168517525e6b44830da3741040f02a0b24d408ba213` sudah diverifikasi. Perubahan source sesudahnya dikirim sebagai patch terikat hash, bukan mengunggah ulang aset game yang sama. Manifest release mencatat base, patch, image dan penghapusan output sementara setelah penerimaan.


## Aktivasi01.04 WIB

Image akhir source798a47b adalah `d044202760953c6cb295df49073f9e44a788f1b672c7618a4d313f8467eb9964`, tagovernight-798a47b/current. Image intermediatebdc/d811 berhasil tetapi sudah digantikan, belum dibersihkan sebelum smoke. FullPCK di image dibaca dan SHA1315/64.491.320byte cocok. Container aktif `7bf52bfa9b32140da04d5db999653f954a40182e5b04e30ae60b87127ec55490` sehat; manifest62bagian/part0HTTP200. `.env` SHA627555330e24f0159d84ca5df860fdebe2c28812cd62edec433635565dd0f68e, Mongo7b13e58/Redis a67512d dan bind10.1.0.8:3000 tidak berubah.

Percobaan aktivasi pertama otomatis rollback karena scriptoperator memakai curl yang tidak tersedia di host, bukan healthfailure aplikasi. Percobaan kedua mengaktifkan image, tetapi exec-T mengonsumsi sisastdin shell sehingga verifikasi susulan dijalankan terpisah dengan command terkutip dan stdin/dev/null. Semua log dipertahankan: `.runtime/overnight-activation.log`, `overnight-activation2.log`, `overnight-activation3-verify.log`. Verifikasi ketiga berhasil, tanpa menginstal paket host atau mengubah proxy. Actualpublicsmoke berjalan sesudahnya; aktivasi ini sendiri belum membuktikan startupgame.

Baseline d60 terikat tagrollback-overnight-b5b459e. Backup `/var/backups/jalasmara/jalasmara-20261109T172408Z.archive.gz`, SHA672afc5a66b96e55ad5550d763753c5ee59b29eccac0b5c15e642b6ba64e06a2, sudah diuji restore42dokumen/0gagal pada databasepemeriksaan terpisah lalu dibersihkan. Tidak ada reseed atau penghentian DB.
