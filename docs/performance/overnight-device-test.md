# Pengujian Windows dan Samsung S23

Status 12 November 2026: pengguna sudah mencoba Windows dan Samsung S23; gerakan cukup lancar dengan sedikit lag. Setelah koreksi bus Web aktif di staging, pengguna memastikan musik dan SFX tombol menu terdengar serta musik lancar selama 1–2 menit di kedua perangkat. Pengujian sesi panjang dan seluruh zona belum dilakukan.

## Identitas kandidat

| Data | Nilai sebelum pengujian |
|---|---|
| URL kandidat | https://staging-jalasmara.ardianryan.com |
| Commit sumber runtime | `acd70c342b4f8768386af7fc70e6f0e50531f9bf` |
| SHA-256 PCK dan ukuran | `38c5aaa95cef751f6cedee7b439df1e1b936c12def36a8afd43d02d187462a3a`, 69.775.548 byte |
| Image staging | `sha256:044b9ea36587bfcd768ab886f1480f4a9443c6c27e5dbdc2bf767cb62cb7f214` |
| Tanggal aktivasi | 12 November 2026 |
| Hasil startup browser publik | Rute fisik penuh 6/6 lulus, termasuk login/READY, desa→hutan, jurnal, jam dan save/reload; [laporan koreksi bus](../reviews/web-audio-silent-bus-2026-11-12.md). Pengguna mengonfirmasi musik dan SFX tombol terdengar serta musik lancar 1–2 menit di Windows/S23. |

Integrator telah memverifikasi pin dan startup publik. Recorder menyertakan identitas PCK dari loader di awal/akhir rekaman; hasil lama tanpa identitas tetap ditandai tidak tersedia. Hasil recorder lokal memakai SwiftShader dan tidak menjadi pengukuran Windows atau S23.

## Sesi singkat, sekitar lima menit per perangkat

Gunakan akun pemain sendiri dan Chrome yang biasa dipakai. Catat versi browser, model perangkat/GPU bila diketahui, orientasi layar, jaringan Wi-Fi atau seluler, serta apakah mode hemat daya aktif. Jangan mengubah progres atau membersihkan data akun demi pengujian.

1. Buka URL kandidat. Ukur waktu sampai permainan dapat dikendalikan dan catat jika persentase unduhan berhenti lama. Muat ulang sekali untuk membandingkan akses pertama dengan aset yang sudah tersimpan. Jangan menghapus seluruh cache browser.
2. Buka **Menu → Layar penuh**. Pada S23, gunakan landscape dan periksa tombol Menu, joystick, serta tombol aksi tetap dapat disentuh. Keluar dari layar penuh lalu masuk kembali; periksa kanvas memenuhi ruang yang tersedia tanpa memotong tombol.
3. Biarkan **Kualitas dunia: Auto (perangkat)**. Buka **Menu → Uji performa perangkat**, pilih **30 detik**, lalu **Mulai rekam performa**. Menu menutup dan permainan dapat dilanjutkan.
4. Selama rekaman, berjalan di desa dan bagian yang paling terasa berat. Di S23, ubah arah joystick perlahan dan tekan aksi dengan jari kedua. Di Windows, gunakan kontrol keyboard yang biasa dipakai. Catat lokasi dan gerakan yang terasa tersendat.
5. Setelah rekaman selesai, buka Menu dan pilih **Unduh laporan JSON**. Nama berkas dimulai dengan `jalasmara-performa-`. Simpan hasilnya; aplikasi tidak mengunggah laporan secara otomatis.
6. Ulangi rekaman 30 detik di area dan rute yang sama dengan **Ringan**. Jika tersedia dalam progres pemain, ambil rekaman tambahan di hutan atau laut. Tidak perlu membuka area terkunci. Gunakan durasi lima menit hanya untuk menilai panas atau penurunan kelancaran yang muncul belakangan.
7. Buka percakapan dan jurnal. Periksa teks terbaca, tombol lanjut terjangkau, dan dunia tidak menerima gerakan pemain ketika panel terbuka. Jika sudah berada pada fase malam, periksa pelanggan dan resep kedai dapat dibaca serta digulir tanpa menutupi konteks pelanggan.
8. Dengarkan musik sejak layar judul, lalu desa siang. Jika progres memungkinkan, dengarkan pula hutan, senja, kedai malam, dan gua/laut. Coba mute lalu unmute, pindah tab sebentar, dan muat ulang sekali. Catat di area mana musik tidak mulai, terputus atau terdengar pecah; sebutkan apakah SFX tombol juga terpengaruh. Pengujian bunyi ini terpisah dari metrik frame recorder.

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


## Pemeriksaan laporan oleh pengembang

Setelah berkas dikembalikan, gunakan [pembaca offline](device-report-summary.md) untuk memeriksa identitas PCK, metadata perangkat, sampel aktif/jeda dan profil efektif. Pembaca tidak mengunggah atau mengubah laporan. Dua laporan hanya dibandingkan jika metadata pengukuran cocok dan pin PCK sama; Auto yang memilih Ringan tidak dianggap profil efektif berbeda dari Ringan manual. Rekaman lama tanpa pin tetap tidak diketahui. Contoh regresi yang disimpan berasal dari SwiftShader, bukan pengganti pengujian perangkat pengguna.
