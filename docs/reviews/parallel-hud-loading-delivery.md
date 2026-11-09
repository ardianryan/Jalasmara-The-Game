# Integrasi HUD Bahari dan loading website

9 November 2026. Pemeriksaan integrasi dilakukan pada source Godot dan React, gambar native, serta game Web yang benar-benar berjalan. Hasil jalur daratan dan laut dijelaskan tersendiri; laporan ini tidak menyatakan semua pekerjaan visual dunia atau seluruh NPC sudah selesai.

## Hasil yang diperiksa

- HUD menggunakan artwork asli Bahari: ikon raster berwarna, panel kayu/kertas, bingkai potret, bar oksigen, minimap bundar berisi peta asli, dan joystick. Angka dan bacaan tetap teks engine; tidak ada HP, level, mata uang atau perlengkapan palsu.
- Pada fixture malam 667×375, panel identitas berkurang dari 108,4 menjadi 66,7 piksel; jam dari 251,5 menjadi 136,2 piksel lebar; joystick 122 menjadi 100 piksel; minimap 89 menjadi 78 piksel. Detail misi tetap dapat dibuka melalui tombol. Pengujian memastikan pusat layar untuk karakter terbuka, sasaran sentuh minimal 48 piksel fisik dan bacaan utama minimal 16 piksel fisik.
- Saat modal dibuka, HUD gameplay dan joystick disembunyikan. Hasil racikan pendek menyesuaikan tinggi isi dan memakai bingkai perkamen; soal serta bacaan panjang tetap mempunyai ruang dan scroll. Callback transaksi racikan tidak dipindahkan ke presentasi.
- Loading memakai panorama Bandar Hujung dan foreground transparan terpisah, total WebP 567.756 byte. Parallax ringan berhenti pada layar sentuh dan preferensi kurangi gerakan. Source PNG, prompt persis, hash dan asal pembuatan disimpan di `assets/source-2d/loading-bandar-hujung-v1/`; pembuatan memakai built-in image_gen.
- Persentase dan MB berasal dari callback byte engine yang sudah ada. Total belum diketahui tetap indeterminate. Selesai mengunduh berbeda dari dunia siap; tidak ada angka berdasarkan timer atau estimasi waktu buatan. Gagal, macet, muat ulang, dan tautan halaman utama mempunyai tindakan nyata.
- Startup tanpa sesi atau gagal mengambil state sekarang mengirim status gagal kepada website, sehingga dialog error engine tidak tersembunyi di balik layar persiapan tanpa akhir. Asal, jendela pengirim dan versi pesan loading diperiksa.

## Bukti

| Pemeriksaan | Hasil |
| --- | --- |
| Typecheck dan API | Typecheck lulus; 77 tes API lulus, tanpa kegagalan atau skip. |
| Dunia | 34 pemeriksaan engine lulus pada export akhir, termasuk HUD, kuis, hasil kedai, fondasi jembatan, arus laut dan tiga model batu yang bersentuhan dengan mesh karang. |
| Artwork | Rebuild atlas Bahari deterministik, 48 sprite raster dan empat alias; alpha tengah bingkai, empat keadaan tombol dan hash sumber lulus. |
| Bridge loading | Empat tes lulus; perubahan pola shell upstream membuat export gagal secara eksplisit. |
| Browser loading fixture | 24 pemeriksaan lulus pada desktop, landscape, portrait dan reduced motion. Tujuh pemeriksaan host lama juga lulus. Gambar 25/100 MB pada fixture bukan ukuran release. |
| Loading engine asli | Lima pemeriksaan lulus: satu GET WASM dan satu GET PCK, status persiapan, sinyal dunia siap, overlay hilang dan startup auth gagal. Putaran terakhir membaca total aset terdekode 103.753.450 byte; angka tersebut bukan ukuran transfer terkompresi melalui jaringan. Auth gagal terlihat pada host dalam 347 ms setelah respons gagal dalam pengujian lokal. Tidak ada error startup normal. |
| Gameplay malam | Tujuh pemeriksaan browser lulus dengan delapan operasi server: racikan dan pelengkap kebun, tutup kedai, HUD malam 667×375/390×844, tas, rumah, tidur satu kali dan persistensi setelah reload. Insets aman pada pemeriksaan ini diemulasikan melalui host yang sebenarnya. |
| Browser game | 15 pemeriksaan lulus pada bundle website terakhir: kontrol, modal, rotasi, multitouch, jeda waktu server/visual, penolakan pesan palsu, tiga profil kualitas dan fullscreen. |
| Kontrol sentuh | Tujuh pemeriksaan lulus pada game sebenarnya: joystick, kepemilikan pointer, berenang, jala dan rotasi penyelaman. Tidak ada error browser. |

Gambar yang ditinjau langsung oleh agen integrasi: HUD malam sebelum/sesudah, hasil racikan sebelum/sesudah, desa/hutan dan lorong laut native, loading desktop/portrait/error landscape, serta HUD malam dan gagal startup pada browser asli. Crop batu laut sebelum/sesudah juga diperiksa: model tetap tiga dimensi dan kini ditanam pada permukaan karang berdasarkan vertex model dan segitiga mesh pendukung. Posisi proyeksi, collision dan data dunia tidak berubah; dekorasi tanpa tumpuan ditolak. Pemeriksaan fungsional 29 alur game di atas mendahului perbaikan dekorasi ini; export akhir diperiksa ulang oleh 34 tes engine dan smoke loading game asli. Capture komponen dengan latar screenshot proyek dibedakan dari pengujian dunia hidup. Fixture pemain sementara dihapus setelah pengujian; akun pemilik tidak digunakan.

## Gerbang desain yang ditinjau integrator

- **Hard Gate PASS:** artwork mengikuti izin eksplisit dan arah pengguna; tidak memakai piksel kit komersial. Angka UI berasal dari state atau byte sebenarnya. Pengujian tiga ukuran memeriksa batas layar, 48/56 piksel untuk tindakan, 16 piksel untuk bacaan dan fokus/shortcut. Keadaan kosong, unduhan tak diketahui, error, macet, retry dan siap tersedia. Bukti fungsi di atas tidak dipakai untuk mengklaim FPS perangkat fisik.
- **Purpose Gate PASS:** kayu, kuningan, kertas dan ikon objek bahari menyatukan antarmuka dengan Jalasmara. Bingkai besar dipadatkan agar lingkungan dan karakter tetap terlihat. Lapisan gelap di balik bacaan menjaga kontras; teks loading primer 11,48:1, sekunder 9,37:1 dan tombol pemulihan 7,67:1. Potret berasal dari pemeran milik proyek. Parallax hanya memberi kedalaman pada adegan loading dan mengikuti preferensi gerakan.
- **Liveliness PASS:** ENERGY 2, RHYTHM 2, MOTION 1 untuk loading; tujuan visual sudah diberikan pengguna sebelum pembuatan. Dermaga tropis dan ruang air menjadi fokus gambar, progres menjadi fokus informasi. Gameplay mempertahankan area tengah terbuka; ornamen ditempatkan pada tepi. Efek oksigen hanya mengikuti ambang risiko sebenarnya.
- **Craftsmanship PASS:** source, build, export, tes engine dan click-through browser diperiksa. Tombol misi tetap mengirim teks lengkap meskipun ringkasannya dilipat. UI tidak menambah renderer/canvas tambahan untuk loading dan tidak mengunduh paket game dua kali. Style tombol utility dibuat sekali, bukan dialokasikan pada setiap polling HUD. Source gambar, prompt dan pipeline dapat ditelusuri.

## Batas bukti

Pengujian browser dijalankan secara lokal dengan emulasi viewport/touch dan renderer otomatis. Windows dan Samsung S23 fisik belum diuji ulang, sehingga tidak ada janji 30/60 FPS atau hasil thermal. Angka waktu startup lokal bukan perkiraan waktu unduhan pemain melalui internet. Penerimaan staging mengikuti commit dan hash artefak rilis yang benar-benar dipasang. Backlog NPC, bangunan, readability terrain dan dukungan batu laut tetap dicatat berdasarkan audit source serta gambar, bukan dianggap selesai oleh pengujian HUD.
