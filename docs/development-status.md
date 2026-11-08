# Status pengembangan

Versi ini adalah prototipe petualangan Godot Fase 1 yang dapat dimainkan melalui browser. Kualitas animasi, peta, dialog, dan kedai masih perlu pemolesan berdasarkan moodboard yang dikerjakan terpisah. Durasi 30–45 menit adalah sasaran desain dan belum divalidasi dengan sesi bermain manusia dari awal sampai tamat.

## Yang sudah berjalan

Nala berjalan pada peta darat tiga perempat di Bandar Hujung dan hutan pesisir, memilih salah satu dari empat tampilan yang tersimpan di akun, berbicara dengan NPC, berenang dalam dunia 6144 × 3584 dengan tabrakan dan jalur bercabang, menjala biota biasa tanpa kuis, mengamati pengetahuan, memulihkan instalasi, dan membawa fragmen ke Kedai Waras. Tiga siklus membuka kedalaman berikutnya; peningkatan tabung dan jala mempersiapkan pemulihan Gajah Mina. Atlas menampilkan seluruh daerah dan wilayah rencana yang terkunci secara fisik dan melalui server. Jurnal menyimpan penemuan. Karakter dan NPC memakai skala yang diselaraskan dengan peta; HUD ringkas memakai palet kayu, krem, dan indigo. Cuaca, jam visual, angin kanopi, pembiasan air, caustic, percikan, gelembung, dan jejak basah berasal dari engine; dampak cuaca pada hadiah atau ekonomi belum diaktifkan.

Akun lokal, undangan, reset oleh owner, kontrol pemain, editor konten versi, audit transaksi, dan penolakan hasil sesi lama tersedia. OIDC tambahan diuji terhadap issuer lokal tiruan; layanan ZITADEL eksternal belum diaktifkan.

Peta hutan memisahkan gambar dasar, bentuk padat, dan tajuk yang menutupi pemain melalui Y-sort. Koridor yang dapat dilalui dipetakan pada data dunia; wilayah vegetasi rapat di luar koridor ditolak oleh klien dan server.

## Bukti pemeriksaan

- 35 pengujian backend lulus, termasuk autentikasi, izin, versi konten, hadiah idempoten, eksplorasi, tiga siklus, dan boss.
- Game diuji di Chromium dan Firefox desktop: berjalan, menyelam, berenang, menjala tanpa kuis, mengamati, dan membuka peta. Tidak ada error browser pada alur tersebut.
- Delapan pemeriksaan hutan lulus di Chromium: pilihan karakter awal, perjalanan melalui gerbang, gerak dua sumbu, penemuan dan hadiah server, jurnal, ganti tampilan, atlas, serta pemulihan posisi setelah refresh.
- Alur yang sama lulus pada HTTPS staging. Cookie produksi memakai prefiks `__Host-`, `Secure`, `HttpOnly`, dan `SameSite=Lax`.
- Emulasi Chromium lanskap menguji input sentuh D-pad, Aksi, dan Jala. Ini bukan pengujian perangkat Android/iOS fisik.
- Admin diuji pada Chromium, Firefox, dan WebKit, termasuk perubahan koin, audit, salinan/edit/publikasi konten, serta lebar 1440, 768, dan 390 piksel tanpa overflow dokumen.
- Build Godot Web, web, API, pemeriksaan dependensi, dan CodeQL dijalankan oleh GitLab CI. Status aktual dan laporan berada pada tautan pipeline repository; GitHub Actions nonaktif.

Bukti browser lokal disimpan di `artifacts/` yang diabaikan Git. Gambar di `docs/screenshots/` adalah tangkapan prototipe Jalasmara sendiri, bukan referensi Dave the Diver.

Senter kerucut mengikuti arah gerak penyelam. Lentera dermaga serta hutan mengikuti cahaya sekitar dan awan; dua lampu hutan menghasilkan bayangan sederhana. Rincian implementasi dan batas efek dijelaskan dalam [waktu, cuaca, dan efek lingkungan](world/environment.md).

## Yang memerlukan tindak lanjut

Owner pertama harus dibuat lewat perintah interaktif pada [panduan operasi](operations.md); tidak ada password bawaan. Pengujian perangkat HP fisik, uji bermain manusia untuk durasi/keseimbangan, peninjauan budaya oleh manusia, dan pemolesan aset belum dilakukan. Fase 2 hanya pengantar, bukan zona permainan lengkap. SMTP, multiplayer, leaderboard kelas, dan analitik lanjutan belum termasuk.

![Prototipe dermaga Bandar Hujung](screenshots/bandar-hujung.png)

![Prototipe eksplorasi Dangkalan Segaran](screenshots/segaran.png)

![Eksplorasi hutan pesisir tiga perempat](screenshots/hutan-muara.png)
