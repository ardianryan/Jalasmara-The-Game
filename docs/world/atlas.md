# Atlas dunia Jalasmara

Bandar Hujung terletak di muara fiksi yang menghadap Palung Smara. Daratan berhutan berada di sisi timur kota, sementara zona bawah laut mengikuti lereng teluk menuju dasar palung. Nama dan susunan geografis merupakan rekaan; rujukan bunyi toponimi Nusantara bukan pemetaan situs sejarah nyata.

Atlas utama berupa peta geografis: daratan Bandar Hujung dan Wringin berada pada satu garis pantai, dengan jalur berjalan, footprint bangunan, sungai, dan kontur bukit. Marker pemain dan tujuan memakai transformasi koordinat game. Jalur menuju kawasan rencana tetap ditandai tertutup. Penampang palung adalah tampilan terpisah karena sumbu vertikalnya menunjukkan kedalaman, bukan utara.

## Permukaan: kota, muara, dan hulu

| Wilayah | Fungsi dan hubungan lingkungan | Akses demo |
| --- | --- | --- |
| Bandar Hujung | Permukiman rakit di muara yang menjadi pintu penyelaman. Kedai Waras melayani warga, Galangan Rongsok Bubat merawat alat, dan Rakit Tani Tanggulangen memasok pangan. | Terbuka sejak awal |
| Hutan Pesisir Wringin | Daratan di timur kota. Tajuk, akar, serasah, dan aliran kecil memperlihatkan hubungan cahaya, tanah, air, serta teluk. | Melalui gerbang di ujung timur dermaga |
| Hulu Wringin | Lereng dan kebun tua di atas hutan pesisir. Limpasan dari wilayah ini menuju sungai, lalu ke perairan Bandar Hujung. | Pengembangan berikutnya |

Pos Pengawas Cakrawala mengawasi jalur perdagangan dan akses warga. Fasilitas industri korporasi menghubungkan konflik di darat dengan pipa yang ditemukan pada kedalaman Jalatunda. Kedai dan bengkel berfungsi sebagai tujuan pulang dari eksplorasi, sedangkan kebun apung memberi alasan nyata untuk mempelajari siklus hara dan pencemaran.

Hutan menggunakan pandangan miring dari atas dengan gerak dua arah pada bidang tanah. Wilayah hutan terpisah dari kota darat Bandar Hujung yang juga memakai pandangan miring dari atas, serta dari laut yang memakai tampilan samping. Perjalanan antarkeduanya dilakukan melalui gerbang, sehingga koordinat hutan tidak dibaca sebagai sambungan horizontal peta laut.

Tiga penghalang fisik menandai batas wilayah hutan:

- **Jembatan Akar Patah**, di timur laut: papan hanyut sehingga jalur tepian hulu tidak dapat dilalui.
- **Longsoran Hulu**, di utara: batu dan akar menutup lereng yang belum stabil.
- **Gerbang Kebun Lama**, di tenggara: gerbang tertutup menuju kebun tua di luar cakupan demo.

Penghalang memiliki bentuk, alasan naratif, dan pembatas posisi pada server. Tombol atlas tidak membuka perjalanan ke wilayah masa depan. Menaikkan hari atau kemampuan melalui panel admin juga tidak mengubah wilayah `coming_soon` menjadi dapat dimainkan.

## Laut: lereng teluk menuju jaringan memori

| Wilayah | Kedalaman | Ekologi atau fungsi cerita | Akses demo |
| --- | --- | --- | --- |
| Dangkalan Segaran | 0–25 m | Bekas taman air yang tenggelam, masih menerima banyak cahaya; tempat belajar berenang, menjala, dan mengamati sel. | Hari 1 |
| Hutan Lamun Wringin | 25–60 m | Tumbuhan laut dan alga dalam lingkungan fiksi memberi petunjuk cahaya, osmosis, dan perputaran hara. | Setelah malam pertama, hari 2 |
| Rongga Kapur Jalatunda | 60–95 m | Lorong batu gamping, penyaring lama, serta rembesan pipa korporasi. | Hari 3 |
| Pelataran Kuno Tamansari | 95–110 m | Gerbang dangkalan dan Gajah Mina yang terjerat limbah. | Hari 3 pada atlas; pertarungan tetap memerlukan misi dan peningkatan alat |
| Reruntuhan Mekanik Smara | Sekitar 150 m | Struktur penyimpanan ingatan kuno yang terlihat sebagai tujuan lanjutan. | Fase 2, belum dapat dimainkan |
| Gerbang Palung Dalam | Sekitar 300 m | Pintu jaringan memori dan penjaga mekanik di kedalaman. | Fase 2, belum dapat dimainkan |

Lamun merupakan tumbuhan berbunga laut, sedangkan kelp adalah alga. Lingkungan Wringin memakai stilisasi tumbuhan bawah air untuk dunia fiksi, bukan pernyataan bahwa semua biota tersebut memiliki habitat identik di perairan Indonesia. Teks penemuan perlu menjaga perbedaan konsep ini saat aset dan konten diperluas.

## Data dan status atlas

Peta geografis memakai `WORLD.hub`, jalur hutan, dan titik gerbang bersama. Offset hutan menyatukan gerbang masuk dengan koordinat kota; pan, zoom, marker, dan minimap memakai transformasi yang sama. `MapGeography.gd` menambahkan garis pantai dan relief kartografis, yang tidak mengubah collider atau membuka wilayah baru. Gambar peta desa dan hutan tidak ditempelkan sebagai dua persegi.

`WORLD.atlas` tetap menyimpan katalog wilayah cerita, deskripsi, koneksi, dan status pengembangan. Posisi ilustratif pada katalog tersebut tidak menggantikan koordinat pemain pada peta geografis.

API menghitung status `story` menjadi `open` setelah hari pemain mencapai `requiresDay`. Status `coming_soon` tetap terkunci. Status atlas tidak menggantikan validasi perjalanan, jarak interaksi, syarat boss, atau batas penyelaman pada server.

Penemuan hutan memberi catatan permanen tentang fotosintesis, serasah dan akar, serta daerah aliran sungai. Temuan ini memperluas alasan pemain menjelajah tanpa menjadikan setiap interaksi sebagai kuis.

Jalur berjalan hutan ditetapkan sebagai gabungan koridor dengan jarak maksimum 130 unit dari garis jalur (`walkablePaths`, `walkableHalfWidth`). Tiga titik pembelajaran dan peti berada pada koridor tersebut. Collider batang, batu, bangunan, dan batas jalur bekerja bersama lapisan tajuk; pemain tidak dapat menembus vegetasi padat dengan mengirim posisi dari klien.
