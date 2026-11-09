# Bandar Hujung: warga, busana, dan perluasan rumah

## Implementasi desa saat ini

Sumber data warga ialah `packages/shared/src/village.ts`, dikirim bersama `WORLD.surface_hub.residents`. Ki Lurah Wirabhumi, Mbok Ratih, Mang Ujang, Kang Tedi, dan Yu Sari hadir sejak siklus pertama. Saras hadir mulai siklus kedua. Mbah Wira, Beno, Bu Darmi, dan Inspektur Raka tetap menjalankan fungsi cerita sebelumnya.

Warga tambahan memiliki sprite tersendiri, rute pendek di tempat bekerja, jeda aktivitas, respons menghadap pemain, serta percakapan siang dan malam. Rute diperiksa terhadap lantai dan rintangan yang sama dengan pemain. Mereka berhenti ketika diajak mendekat. Ini belum merupakan simulasi jadwal lintas distrik; mereka tidak diteleportasi ketika jam berubah. Informasi percakapan membantu pengamatan lingkungan, persiapan alat, dan navigasi tanpa memberikan hadiah ekonomi dari klien.

Raka tetap menjadi inspektur lapangan dalam cerita Fase 1. Kantornya memakai bangunan kontainer industri di petak terpisah yang sudah tersedia, bukan rumah adat warga. Pada tata letak 7, kantor `pos_cakrawala` tetap berada pada kotak pembatas (1840, 140, 300, 105), dengan badan panel krem, atap logam datar berusuk, jendela layanan, kisi ventilasi, dan antena. Siluet kantor dibedakan dari atap pelana, limas, dan balai warga. Nama jabatan Raka tidak diubah menjadi direktur dan tidak ada direktur baru yang menduplikasi perannya. Render native revisi ini diperiksa pada `artifacts/godot/village7/corporate-office.png`; badan kontainer serta atap datarnya tetap hadir setelah penambahan rumah warga.

Bilik ganti Beno berada di dermaga pada sekitar (1430,1290). Dua tiang memakai footprint bersama server/klien. Melewati bilik menuju tangga memasang pakaian selam, tabung, dan jala; kembali ke desa melepasnya. Pakaian penjelajah digunakan di hutan. Identitas empat karakter tetap tersimpan di akun; pakaian mengikuti konteks medan. Pergantian visual tidak mengubah saldo, kapasitas oksigen, atau tingkat kemampuan.

## Rumah warga dan balai pada tata letak 7

Manifest `LAND_MAPS.hub` kini memakai `layoutVersion: 7`. Pelataran hunian di sebelah utara menyatu dengan pelataran atas pada elevasi 2. Lantai, batas pesisir, dan footprint bangunan berasal dari manifest bersama yang dipakai renderer serta pemeriksaan gerak server. Titik cerita, kebun Bu Darmi, jalur dermaga, dan gerbang hutan tetap tersedia.

| Bangunan         | Footprint pembatas (x, y, lebar, tinggi) | Elevasi | Titik pendekatan pintu |
| ---------------- | ---------------------------------------- | ------- | ---------------------- |
| Balai Ki Lurah   | 750, 120, 380, 145                       | 2       | 940, 310               |
| Rumah Mbok Ratih | 350, 150, 230, 125                       | 2       | 465, 320               |
| Rumah Yu Sari    | 1210, 120, 230, 125                      | 2       | 1325, 300              |
| Rumah Kang Tedi  | 920, 850, 170, 90                        | 1       | 1005, 975              |

Ukuran tabel merupakan kotak pembatas; penghalang sebenarnya berupa poligon empat sudut miring yang sama dengan dasar bangunan 3D. Balai memiliki atap bertingkat, tiang kayu, alas batu, bangku rapat, dan papan pengumuman. Rumah Ratih dan Tedi memakai siluet atap pelana berwarna tanah liat, sedangkan rumah Sari memakai atap limas berpenutup jerami. Bentuk tersebut merupakan adaptasi arsitektur fiktif yang bersahaja, bukan rekonstruksi bangunan adat atau penggunaan simbol sakral.

Jalur batu selebar 76 piksel dunia menghubungkan titik pendekatan pintu dengan pelataran lama. Jalur ini merupakan lapisan visual di atas lantai yang sudah sah; jalur tidak menciptakan jalan melintasi air atau melewati footprint rumah. Tepi dua lantai yang bersambung pada elevasi sama tidak lagi diberi dinding tebing semu. Renderer tetap menampilkan tebing pada tepi yang benar-benar berbeda tinggi atau berbatasan dengan pesisir.

Jumlah bangunan rumah/kedai/kantor pada hub menjadi tujuh. Bangunan baru belum menyediakan interior yang dapat dimasuki, tempat tidur, penyimpanan barang, transaksi panen, atau hadiah baru. Jadwal dan aktivitas warga dibahas terpisah dari keberadaan bangunannya.

Pemeriksaan lokal mencakup 30 ruas jalur hub dengan jarak aman tubuh 13 piksel serta titik awal/akhir rute warga yang ada. Render native siang dan malam selesai tanpa kesalahan shader; bukti visual tersedia secara lokal di `artifacts/godot/village7/`. Pemeriksaan ini belum menyatakan hasil pengujian peramban atau perangkat fisik untuk revisi tersebut.

## Rancangan perluasan yang belum aktif

Referensi pengguna menetapkan Griya Sasmita sebagai rumah panggung Nala, kebun dan keramba pribadi, fungsi lanjutan balai Ki Lurah, serta Laskar Kognisi: Bagas, Kinasih, Gito, Cempaka, dan Danu. Pertahankan nama dan peran tersebut untuk perluasan berikutnya. Jangan menampilkan tombol panen, tidur, pemberian bibit, ataupun hadiah yang belum mempunyai layanan server.

Urutan implementasi lanjutan:

1. Tentukan petak rumah dan jembatan pada peta geografis, lantai bertingkat, footprint bangunan, jalur NPC, dan migrasi posisi save. Jalur menuju wilayah belum selesai tetap dibatasi fisik dengan papan pembangunan.
2. Hubungkan meja arsip ke jurnal/SmaraPedia dan rak pameran ke key item yang benar-benar dimiliki. Tidur tidak boleh melewati syarat penyelesaian kedai atau membuka boss tanpa misi wajib.
3. Tambahkan transaksi server untuk izin rakit setelah misi Bu Darmi, inventori bibit, penanaman, panen, dan pemeliharaan. Gunakan ID fragmen katalog nyata; ID dalam referensi pengguna belum tentu sama dengan seed proyek.
4. Pisahkan hari pertumbuhan otoritatif dari jam visual 36 menit. Satu batas panen hanya diproses satu kali; refresh, tidur berulang, dan pergantian perangkat tidak menggandakan hasil.
5. Implementasikan quest warga dan bantuan anak-anak dengan prasyarat, hadiah sekali pakai, audit, serta dialog yang sesuai status. Aktivasi fitur Fase 2 tetap terkunci sampai fiturnya selesai.

## Penyesuaian materi dan keseimbangan

- Koral adalah hewan, sehingga tidak dijadikan tanaman hidroponik. Tanaman darat, ganggang, dan penangkaran karang perlu modul lingkungan berbeda.
- Rentang pH dan kebutuhan nutrisi ditentukan per spesies; pH 7 bukan kondisi terbaik untuk seluruh tanaman. Hindari satu bonus yang menetralkan semua kebun menjadi pH 7 tanpa mempertimbangkan tanaman.
- Filter mengurangi jenis kontaminan tertentu; air jernih tidak otomatis layak diminum. Efek penyaringan dan desinfeksi perlu dibedakan dalam pembelajaran.
- Klaim peluang telur 25%, aturan dua induk, bonus harga 15%, dan unlock jala level 4 adalah rancangan baru. Jangan mengaktifkannya sebelum sesuai batas level serta ekonomi demo yang sudah ada.
- Ingatan warga dan bantuan anak-anak disampaikan dengan hormat. Aktivitas dapur anak diawasi Mbah Wira; eksperimen bahan berbahaya tidak menjadi contoh kegiatan mandiri.

Referensi ini diterapkan pada Godot Compatibility dengan dunia 3D dan sprite piksel; React tetap menjadi shell akun/admin. Tidak ada migrasi kembali ke Phaser.
