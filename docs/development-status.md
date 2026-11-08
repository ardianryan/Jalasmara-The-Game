# Status pengembangan

Versi ini adalah prototipe petualangan Godot Fase 1 yang dapat dimainkan melalui browser. Kualitas animasi, peta, dialog, dan kedai masih perlu pemolesan berdasarkan moodboard yang dikerjakan terpisah. Durasi 30–45 menit adalah sasaran desain dan belum divalidasi dengan sesi bermain manusia dari awal sampai tamat.

## Yang sudah berjalan

Nala berjalan pada peta darat tiga perempat di Bandar Hujung dan hutan pesisir, memilih salah satu dari empat tampilan yang tersimpan di akun, berbicara dengan NPC, berenang dalam dunia 6144 × 3584 dengan tabrakan dan jalur bercabang, menjala biota biasa tanpa kuis, mengamati pengetahuan, memulihkan instalasi, dan membawa fragmen ke Kedai Waras. Tiga siklus membuka kedalaman berikutnya; peningkatan tabung dan jala mempersiapkan pemulihan Gajah Mina. Atlas darat memakai satu garis pantai kontinu, jalur dan footprint bangunan dari koordinat game, sungai, serta kontur bukit; bukan tempelan dua gambar peta persegi. Atlas menampilkan seluruh daerah dan wilayah rencana yang terkunci secara fisik dan melalui server. Jurnal menyimpan penemuan. Karakter dan NPC memakai skala yang diselaraskan dengan peta; HUD memakai palet kayu, krem, tembaga, dan hijau lamun. Cuaca, jam visual, angin kanopi, pembiasan air, caustic, percikan, gelembung, dan jejak basah berasal dari engine; dampak cuaca pada hadiah atau ekonomi belum diaktifkan.

Akun lokal, undangan, reset oleh owner, kontrol pemain, editor konten versi, audit transaksi, dan penolakan hasil sesi lama tersedia. OIDC tambahan diuji terhadap issuer lokal tiruan; layanan ZITADEL eksternal belum diaktifkan.

Bandar Hujung memakai peta pesisir 2400 × 1600 dengan empat pelataran, tangga, delapan cabang jalur, serta mask darat layout versi 3. Spawn berada di dermaga (1120, 1230), tangga menyelam di (1485, 1330), dan pintu hutan di (2295, 125). Rumah, tembok, dan tepi air menjadi penghalang; koridor yang dapat dilalui dibaca klien dan server dari metadata yang sama. Peta hutan memisahkan gambar dasar, bentuk padat, dan tajuk yang menutupi pemain melalui Y-sort. Lapisan dekorasi jauh/dekat memakai parallax dan warna atmosfer; gambar dasar serta collision tetap diam.

Sepuluh spesies fauna dihasilkan offline melalui Core Procedural Pixel Creatures pada seed tetap: 722 bingkai animasi dengan metadata arah dan pivot. Godot membaca PNG serta JSON melalui CreatureAnimator; runtime C# tidak disertakan ke web. Gerombolan ikan memakai empat school dengan cohesion/separation, lima perilaku, serta klip idle/locomotion generator; prey menghindari penyelam/predator, predator mengejar secara visual, dan semuanya menghindari kontur batu. Ular dan kura-kura pesisir menghuni hutan. Dua render pakis/bambu dari model Polyfork dipakai sebagai dekorasi kecil. Ark Pixel 12px proportional Latin menjadi font tema game, HUD, dan peta, dengan antialias dan subpixel dinonaktifkan. Kredit MIT, CC BY 4.0, dan OFL disertakan bersama sumber aset.

Pilot laut kini memakai geometri 3D dengan kamera ortografis miring, Sprite3D untuk penyelam dan biota, serta senter yang menghasilkan bayangan pada batu. Kontur bergerigi yang sama dipakai oleh mesh, collider klien, peta, dan validasi posisi server. Kota dan hutan tetap menggunakan renderer 2D. Rincian cakupan ada pada [pilot hybrid](world/hybrid-terrain.md).

HUD memakai satu instrumen oksigen bersegmen dengan angka besar, kedalaman dan tas. Pada desktop instrumen berada di bawah kiri; pada mode sentuh di atas kiri agar tidak bertabrakan dengan D-pad. Tombol jala dan aksi disatukan, dengan indikator tahan/lepas. Peringatan udara tipis muncul pada 20% atau kurang. Baris tas memisahkan ikon, nama, kualitas, dan jumlah dengan lebar teks yang mengikuti panel. Peta, jurnal, tas, tampilan, dan suara berada dalam satu strip.

## Bukti pemeriksaan

- Pembaruan dunia hidup lulus enam pemeriksaan Godot headless: geometri peta, animasi, fauna, air/occlusion, foley, dan relief terrain. Simulasi fauna mencakup 43.500 sampel selama 60 detik dan 7.200 posisi target; terrain memeriksa 15 kontur, 521 teras, dan 4.650 vertex proyeksi. Verifikasi generator mencakup 10 spesies/722 bingkai.
- Pada Chromium, 29 dari 29 makhluk berpindah posisi dalam dua pengamatan berjarak 2,4 detik; empat kawanan dan perilaku idle/feed/swim/flee/hunt aktif. Pemeriksaan browser juga memastikan arus berubah, berkas cahaya terpotong kontur, serta langkah dan audio bawah air aktif. Bukti ini tidak mengukur kualitas suara melalui speaker atau FPS perangkat fisik.
- 40 pengujian backend lulus, termasuk autentikasi, izin, versi konten, hadiah idempoten, eksplorasi, tiga siklus, boss, batas dan migrasi layout hub, serta pengiriman berkas terkompresi melalui HTTP.
- Pilot hybrid diuji melalui browser: mesh dan sprite 3D aktif, kamera ortografis, perbandingan F6, serta berenang melalui celah gua dengan posisi yang diterima server. Pemeriksaan GPU native juga memeriksa sembilan titik proyeksi pada tiga tingkat zoom. Alur lengkap pilot lulus di Chromium lokal dan HTTPS; Firefox baru terverifikasi merender scene, dengan cold startup melewati 90 detik dan alur lanjut belum lulus. Ini belum merupakan pengukuran FPS perangkat fisik.
- Sepuluh spritesheet procedural lulus pemeriksaan batas dan perubahan piksel; dua proses generasi terpisah menghasilkan PNG/JSON identik. Import Godot dan smoke test scene hutan lulus setelah pemasangan Ark Pixel; pengujian font memastikan cakupan huruf Latin, angka, tanda baca, diakritik, dan panah.
- Setelah perombakan, alur berjalan–menyelam–menjala–penemuan–peta lulus di Firefox; tujuh pemeriksaan peta geografis dan enam pemeriksaan audio lulus di Chromium. Empat tangkapan siang/malam hub dan hutan menunjukkan dunia meredup sementara HUD tetap terbaca, tanpa error browser, shader, atau API. Pengujian audio memeriksa status pemutar, gesture, mute dan reload; kualitas suara melalui speaker tetap memerlukan pendengaran manusia.
- Game diuji di Chromium dan Firefox desktop: berjalan, menyelam, berenang, menjala tanpa kuis, mengamati, dan membuka peta. Tidak ada error browser pada alur tersebut.
- Delapan pemeriksaan hutan lulus di Chromium: pilihan karakter awal, perjalanan melalui gerbang, gerak dua sumbu, penemuan dan hadiah server, jurnal, ganti tampilan, atlas, serta pemulihan posisi setelah refresh.
- Alur yang sama lulus pada HTTPS staging. Cookie produksi memakai prefiks `__Host-`, `Secure`, `HttpOnly`, dan `SameSite=Lax`.
- Emulasi Chromium lanskap menguji input sentuh D-pad, Aksi, dan Jala pada HUD baru, termasuk posisi tombol jala yang berubah sesuai konteks. Angka oksigen rendah, peringatan, dan suara detak juga diperiksa. Ini bukan pengujian perangkat Android/iOS fisik.
- Admin diuji pada Chromium, Firefox, dan WebKit, termasuk perubahan koin, audit, salinan/edit/publikasi konten, serta lebar 1440, 768, dan 390 piksel tanpa overflow dokumen.
- Build Godot Web, web, API, pemeriksaan dependensi, dan CodeQL dijalankan oleh GitLab CI. Status aktual dan laporan berada pada tautan pipeline repository; GitHub Actions nonaktif.

Bukti browser lokal disimpan di `artifacts/` yang diabaikan Git. Gambar di `docs/screenshots/` adalah tangkapan prototipe Jalasmara setelah perombakan peta, bukan referensi Dave the Diver.

Senter kerucut mengikuti arah gerak penyelam. Lentera dermaga serta hutan mengikuti cahaya sekitar dan awan; dua lampu hutan menghasilkan bayangan sederhana. Rincian implementasi dan batas efek dijelaskan dalam [waktu, cuaca, dan efek lingkungan](world/environment.md).

## Yang memerlukan tindak lanjut

Pada instalasi baru, owner pertama dibuat lewat perintah interaktif pada [panduan operasi](operations.md); tidak ada password bawaan. Akun owner staging yang sudah dibuat dipertahankan saat deployment. Pengujian perangkat HP fisik, uji bermain manusia untuk durasi/keseimbangan, peninjauan budaya oleh manusia, dan pemolesan aset belum dilakukan. Fase 2 hanya pengantar, bukan zona permainan lengkap. SMTP, multiplayer, leaderboard kelas, dan analitik lanjutan belum termasuk.

![Prototipe dermaga Bandar Hujung](screenshots/bandar-hujung.png)

![Prototipe eksplorasi Dangkalan Segaran](screenshots/segaran.png)

![Pilot gua Segaran dengan batu 3D dan HUD baru](screenshots/gua-segaran.png)

![Eksplorasi hutan pesisir tiga perempat](screenshots/hutan-muara.png)

![Atlas geografis pesisir dan Wringin yang menyambung](screenshots/atlas-geografis.png)

![Tas terisi dengan nama dan jumlah yang terbaca](screenshots/tas-nala.png)

Integrasi sumber lengkap dicatat pada [referensi dan integrasi](reference-integrations.md). Pembaruan dunia hidup menambah lapisan teras 3D, backing tablet dari jalur img2threejs offline, berkas cahaya yang terhalang kontur, motes/parallax, wake renang, percikan Pixelbolt kontekstual, serta foley langkah/breathing. `npm run check:world` memeriksa perilaku dan geometri melalui Godot, tidak hanya keberadaan aset.
