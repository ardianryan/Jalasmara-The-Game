# Status pengembangan

Versi ini adalah prototipe petualangan Godot Fase 1 yang dapat dimainkan melalui browser. Kualitas animasi, peta, dialog, dan kedai masih perlu pemolesan berdasarkan moodboard yang dikerjakan terpisah. Durasi 30–45 menit adalah sasaran desain dan belum divalidasi dengan sesi bermain manusia dari awal sampai tamat.

## Yang sudah berjalan

Nala berjalan pada peta darat tiga perempat di Bandar Hujung dan hutan pesisir, memilih salah satu dari empat tampilan yang tersimpan di akun, berbicara dengan NPC, berenang dalam dunia 6144 × 3584 dengan tabrakan dan jalur bercabang, menjala biota biasa tanpa kuis, mengamati pengetahuan, memulihkan instalasi, dan membawa fragmen ke Kedai Waras. Tiga siklus membuka kedalaman berikutnya; peningkatan tabung dan jala mempersiapkan pemulihan Gajah Mina. Atlas menampilkan seluruh daerah dan wilayah rencana yang terkunci secara fisik dan melalui server. Jurnal menyimpan penemuan. Karakter dan NPC memakai skala yang diselaraskan dengan peta; HUD ringkas memakai palet kayu, krem, dan indigo. Cuaca, jam visual, angin kanopi, pembiasan air, caustic, percikan, gelembung, dan jejak basah berasal dari engine; dampak cuaca pada hadiah atau ekonomi belum diaktifkan.

Akun lokal, undangan, reset oleh owner, kontrol pemain, editor konten versi, audit transaksi, dan penolakan hasil sesi lama tersedia. OIDC tambahan diuji terhadap issuer lokal tiruan; layanan ZITADEL eksternal belum diaktifkan.

Bandar Hujung memakai peta pesisir 2400 × 1600 dengan empat pelataran, tangga, delapan cabang jalur, serta mask darat layout versi 3. Spawn berada di dermaga (1120, 1230), tangga menyelam di (1485, 1330), dan pintu hutan di (2295, 125). Rumah, tembok, dan tepi air menjadi penghalang; koridor yang dapat dilalui dibaca klien dan server dari metadata yang sama. Peta hutan memisahkan gambar dasar, bentuk padat, dan tajuk yang menutupi pemain melalui Y-sort. Lapisan dekorasi jauh/dekat memakai parallax dan warna atmosfer; gambar dasar serta collision tetap diam.

Sepuluh spesies fauna dihasilkan offline melalui Core Procedural Pixel Creatures pada seed tetap: 722 bingkai animasi dengan metadata arah dan pivot. Godot membaca PNG serta JSON melalui CreatureAnimator; runtime C# tidak disertakan ke web. Gerombolan ikan menghindari penyelam dan penghalang, sementara ular dan kura-kura pesisir menghuni hutan. Dua render pakis/bambu dari model Polyfork dipakai sebagai dekorasi kecil. Ark Pixel 12px proportional Latin menjadi font tema game, HUD, dan peta, dengan antialias dan subpixel dinonaktifkan. Kredit MIT, CC BY 4.0, dan OFL disertakan bersama sumber aset.

## Bukti pemeriksaan

- 38 pengujian backend lulus, termasuk autentikasi, izin, versi konten, hadiah idempoten, eksplorasi, tiga siklus, boss, serta batas dan migrasi layout hub.
- Sepuluh spritesheet procedural lulus pemeriksaan batas dan perubahan piksel; dua proses generasi terpisah menghasilkan PNG/JSON identik. Import Godot dan smoke test scene hutan lulus setelah pemasangan Ark Pixel; pengujian font memastikan cakupan huruf Latin, angka, tanda baca, diakritik, dan panah.
- Setelah perombakan, alur berjalan–menyelam–menjala–penemuan–peta lulus di Firefox; tujuh pemeriksaan peta geografis dan enam pemeriksaan audio lulus di Chromium. Empat tangkapan siang/malam hub dan hutan menunjukkan dunia meredup sementara HUD tetap terbaca, tanpa error browser, shader, atau API. Pengujian audio memeriksa status pemutar, gesture, mute dan reload; kualitas suara melalui speaker tetap memerlukan pendengaran manusia.
- Game diuji di Chromium dan Firefox desktop: berjalan, menyelam, berenang, menjala tanpa kuis, mengamati, dan membuka peta. Tidak ada error browser pada alur tersebut.
- Delapan pemeriksaan hutan lulus di Chromium: pilihan karakter awal, perjalanan melalui gerbang, gerak dua sumbu, penemuan dan hadiah server, jurnal, ganti tampilan, atlas, serta pemulihan posisi setelah refresh.
- Alur yang sama lulus pada HTTPS staging. Cookie produksi memakai prefiks `__Host-`, `Secure`, `HttpOnly`, dan `SameSite=Lax`.
- Emulasi Chromium lanskap menguji input sentuh D-pad, Aksi, dan Jala. Ini bukan pengujian perangkat Android/iOS fisik.
- Admin diuji pada Chromium, Firefox, dan WebKit, termasuk perubahan koin, audit, salinan/edit/publikasi konten, serta lebar 1440, 768, dan 390 piksel tanpa overflow dokumen.
- Build Godot Web, web, API, pemeriksaan dependensi, dan CodeQL dijalankan oleh GitLab CI. Status aktual dan laporan berada pada tautan pipeline repository; GitHub Actions nonaktif.

Bukti browser lokal disimpan di `artifacts/` yang diabaikan Git. Gambar di `docs/screenshots/` adalah tangkapan prototipe Jalasmara sendiri, bukan referensi Dave the Diver; sebagian mendahului perombakan peta terbaru.

Senter kerucut mengikuti arah gerak penyelam. Lentera dermaga serta hutan mengikuti cahaya sekitar dan awan; dua lampu hutan menghasilkan bayangan sederhana. Rincian implementasi dan batas efek dijelaskan dalam [waktu, cuaca, dan efek lingkungan](world/environment.md).

## Yang memerlukan tindak lanjut

Owner pertama harus dibuat lewat perintah interaktif pada [panduan operasi](operations.md); tidak ada password bawaan. Pengujian perangkat HP fisik, uji bermain manusia untuk durasi/keseimbangan, peninjauan budaya oleh manusia, dan pemolesan aset belum dilakukan. Fase 2 hanya pengantar, bukan zona permainan lengkap. SMTP, multiplayer, leaderboard kelas, dan analitik lanjutan belum termasuk.

![Prototipe dermaga Bandar Hujung](screenshots/bandar-hujung.png)

![Prototipe eksplorasi Dangkalan Segaran](screenshots/segaran.png)

![Eksplorasi hutan pesisir tiga perempat](screenshots/hutan-muara.png)
