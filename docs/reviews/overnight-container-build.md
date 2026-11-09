# Packaging kandidat overnight

Build Docker pertama dari bundle480d27d gagal sebelum image runtime dibuat. Vite tidak menemukan `client-godot/resources/art/hud-bahari-v1/button-normal.png`, yang dipakai tombol Menu host. Build lokal lulus karena seluruh checkout tersedia; Dockerfile hanya menyalin apps/packages. Log `.runtime/overnight-image-build.log` menyimpan kegagalan sebenarnya.

Perbaikan packaging menyalin satu PNG original tersebut ke path build yang sama. Tidak menduplikasi artwork sumber, tidak menyalin cache/engine Godot, dan tidak mengubah kode UI, ukuran piksel, bundle dependency atau PCK1315f346. Pembangunan image ulang menjadi verifikasi yang diperlukan, bukan klaim lulus dari patch Dockerfile saja. Image staging d60 dan rollback43bd tetap dipertahankan; belum ada aktivasi kandidat saat laporan awal ini ditulis.

Bundle dasar memakai source480d27d, ekspor593dc79/PCK1315f346/64.491.320byte. Arsip sementara265.236.480byte SHA-256 `021ae26444e887f3e321f168517525e6b44830da3741040f02a0b24d408ba213` sudah diverifikasi. Perubahan source sesudahnya dikirim sebagai patch terikat hash, bukan mengunggah ulang aset game yang sama. Manifest release mencatat base, patch, image dan penghapusan output sementara setelah penerimaan.
