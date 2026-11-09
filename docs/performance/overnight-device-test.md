# Pengujian Windows dan Samsung S23

Status 10 November 2026: pengguna bersedia menjalankan pengujian pada perangkat asli setelah kandidat siap. Dokumen ini adalah panduan pelaksanaan, bukan hasil pengujian. Build publik yang lama belum mewakili kandidat overnight; integrator harus mengisi pin rilis terlebih dahulu.

## Identitas kandidat

| Data | Nilai sebelum pengujian |
|---|---|
| URL kandidat | Belum ditetapkan untuk pengujian perangkat |
| Commit sumber runtime | Diisi integrator setelah rilis kandidat |
| SHA-256 PCK dan ukuran | Diisi integrator dari manifest yang disajikan |
| Tanggal dan jam aktivasi | Diisi integrator |
| Hasil startup browser publik | Masih menunggu kandidat baru |

Integrator memverifikasi pin dan startup publik sebelum meminta pengguna menguji. Hasil recorder lokal pada PCK `1d3c94a5…` memakai SwiftShader dan tidak menjadi pengukuran Windows atau S23.

## Sesi singkat, sekitar lima menit per perangkat

Gunakan akun pemain sendiri dan Chrome yang biasa dipakai. Catat versi browser, model perangkat/GPU bila diketahui, orientasi layar, jaringan Wi-Fi atau seluler, serta apakah mode hemat daya aktif. Jangan mengubah progres atau membersihkan data akun demi pengujian.

1. Buka URL kandidat. Ukur waktu sampai permainan dapat dikendalikan dan catat jika persentase unduhan berhenti lama. Muat ulang sekali untuk membandingkan akses pertama dengan aset yang sudah tersimpan. Jangan menghapus seluruh cache browser.
2. Buka **Menu → Layar penuh**. Pada S23, gunakan landscape dan periksa tombol Menu, joystick, serta tombol aksi tetap dapat disentuh. Keluar dari layar penuh lalu masuk kembali; periksa kanvas memenuhi ruang yang tersedia tanpa memotong tombol.
3. Biarkan **Kualitas dunia: Auto (perangkat)**. Buka **Menu → Uji performa perangkat**, pilih **30 detik**, lalu **Mulai rekam performa**. Menu menutup dan permainan dapat dilanjutkan.
4. Selama rekaman, berjalan di desa dan bagian yang paling terasa berat. Di S23, ubah arah joystick perlahan dan tekan aksi dengan jari kedua. Di Windows, gunakan kontrol keyboard yang biasa dipakai. Catat lokasi dan gerakan yang terasa tersendat.
5. Setelah rekaman selesai, buka Menu dan pilih **Unduh laporan JSON**. Nama berkas dimulai dengan `jalasmara-performa-`. Simpan hasilnya; aplikasi tidak mengunggah laporan secara otomatis.
6. Ulangi rekaman 30 detik di area dan rute yang sama dengan **Ringan**. Jika tersedia dalam progres pemain, ambil rekaman tambahan di hutan atau laut. Tidak perlu membuka area terkunci. Gunakan durasi lima menit hanya untuk menilai panas atau penurunan kelancaran yang muncul belakangan.
7. Buka percakapan dan jurnal. Periksa teks terbaca, tombol lanjut terjangkau, dan dunia tidak menerima gerakan pemain ketika panel terbuka. Jika sudah berada pada fase malam, periksa pelanggan dan resep kedai dapat dibaca serta digulir tanpa menutupi konteks pelanggan.

Saat membuka Menu, rekaman menandai jeda dan mengecualikannya dari distribusi frame aktif. Membuka tab lain juga bukan bagian pengukuran gameplay. Gunakan rute dan kondisi yang serupa ketika membandingkan Auto dengan Ringan.

## Catatan yang dikembalikan

| Perangkat | Profil | Area/rute | Loading pertama/ulang | Kontrol dan HUD | Kelancaran/panas | Nama laporan |
|---|---|---|---|---|---|---|
| Windows | Auto |  |  |  |  |  |
| Windows | Ringan |  |  |  |  |  |
| Samsung S23 | Auto |  |  |  |  |  |
| Samsung S23 | Ringan |  |  |  |  |  |

Jika ada masalah, cukup catat langkah pemicu dan hasil yang terlihat. Jangan menyertakan kata sandi, token, cookie, atau data akun. Laporan recorder membatasi isinya pada metadata browser/perangkat dan metrik performa; pengguna tetap memilih sendiri berkas yang akan dibagikan.

## Cara membaca hasil

Integrator mengikat setiap laporan pada pin kandidat, perangkat, profil, dan rute yang diuji. Interval RAF menunjukkan penjadwalan browser, bukan waktu GPU. Heap JavaScript bukan total memori WASM, VRAM, atau proses. Nilai renderer yang disembunyikan browser tetap dicatat sebagai tidak tersedia. Kesimpulan optimasi harus mengikuti hasil perangkat dan pengulangan yang sebanding; panduan ini tidak menjanjikan FPS tertentu.
