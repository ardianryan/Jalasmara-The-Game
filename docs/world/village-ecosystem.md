# Bandar Hujung: warga, busana, dan perluasan rumah

## Implementasi desa saat ini

Sumber data warga ialah `packages/shared/src/village.ts`, dikirim bersama `WORLD.surface_hub.residents`. Ki Lurah Wirabhumi, Mbok Ratih, Mang Ujang, Kang Tedi, dan Yu Sari hadir sejak siklus pertama. Saras hadir mulai siklus kedua. Mbah Wira, Beno, Bu Darmi, dan Inspektur Raka tetap menjalankan fungsi cerita sebelumnya.

Warga tambahan memiliki sprite tersendiri, respons menghadap pemain, serta percakapan siang dan malam. Tujuh warga termasuk Bu Darmi mengikuti jadwal kerja, perjalanan pulang, dan berteduh ketika hujan. Rute diperiksa terhadap lantai, rintangan, serta tangga yang sama dengan pemain. Mereka berhenti berjalan saat pemain mendekat, tanpa teleportasi ketika jam berubah. Alat kegiatan memakai mesh terpisah; sprite tubuh masih memakai animasi sederhana. Rincian jadwal dan batas simulasi tersedia pada [kegiatan warga](village-activities.md). Percakapan membantu pengamatan lingkungan, persiapan alat, dan navigasi tanpa memberikan hadiah ekonomi dari klien.

Raka tetap menjadi inspektur lapangan dalam cerita Fase 1. Kantornya memakai bangunan kontainer industri di petak terpisah yang sudah tersedia, bukan rumah adat warga. Pada tata letak 7, kantor `pos_cakrawala` tetap berada pada kotak pembatas (1840, 140, 300, 105), dengan badan panel krem, atap logam datar berusuk, jendela layanan, kisi ventilasi, dan antena. Siluet kantor dibedakan dari atap pelana, limas, dan balai warga. Nama jabatan Raka tidak diubah menjadi direktur dan tidak ada direktur baru yang menduplikasi perannya. Render native revisi ini diperiksa pada `artifacts/godot/village7/corporate-office.png`; badan kontainer serta atap datarnya tetap hadir setelah penambahan rumah warga.

Bilik ganti Beno berada di dermaga pada sekitar (1430,1290). Dua tiang memakai footprint bersama server/klien. Melewati bilik menuju tangga memasang pakaian selam, tabung, dan jala; kembali ke desa melepasnya. Pakaian penjelajah digunakan di hutan. Identitas empat karakter tetap tersimpan di akun; pakaian mengikuti konteks medan. Pergantian visual tidak mengubah saldo, kapasitas oksigen, atau tingkat kemampuan.

## Rumah warga dan balai pada tata letak 7

Rumah warga diperkenalkan pada tata letak 7; penambahan Griya Sasmita menaikkan `LAND_MAPS.hub.layoutVersion` menjadi 8. Pelataran hunian di sebelah utara menyatu dengan pelataran atas pada elevasi 2. Lantai, batas pesisir, dan footprint bangunan berasal dari manifest bersama yang dipakai renderer serta pemeriksaan gerak server. Titik cerita, kebun Bu Darmi, jalur dermaga, dan gerbang hutan tetap tersedia.

| Bangunan         | Footprint pembatas (x, y, lebar, tinggi) | Elevasi | Titik pendekatan pintu |
| ---------------- | ---------------------------------------- | ------- | ---------------------- |
| Balai Ki Lurah   | 750, 120, 380, 145                       | 2       | 940, 310               |
| Rumah Mbok Ratih | 350, 150, 230, 125                       | 2       | 465, 320               |
| Rumah Yu Sari    | 1210, 120, 230, 125                      | 2       | 1325, 300              |
| Rumah Kang Tedi  | 920, 850, 170, 90                        | 1       | 1005, 975              |

Ukuran tabel merupakan kotak pembatas; penghalang sebenarnya berupa poligon empat sudut miring yang sama dengan dasar bangunan 3D. Balai memiliki atap bertingkat, tiang kayu, alas batu, bangku rapat, dan papan pengumuman. Rumah Ratih dan Tedi memakai siluet atap pelana berwarna tanah liat, sedangkan rumah Sari memakai atap limas berpenutup jerami. Bentuk tersebut merupakan adaptasi arsitektur fiktif yang bersahaja, bukan rekonstruksi bangunan adat atau penggunaan simbol sakral.

Jalur batu selebar 76 piksel dunia menghubungkan titik pendekatan pintu dengan pelataran lama. Jalur ini merupakan lapisan visual di atas lantai yang sudah sah; jalur tidak menciptakan jalan melintasi air atau melewati footprint rumah. Tepi dua lantai yang bersambung pada elevasi sama tidak lagi diberi dinding tebing semu. Renderer tetap menampilkan tebing pada tepi yang benar-benar berbeda tinggi atau berbatasan dengan pesisir.

Pada perluasan tata letak 7, jumlah bangunan rumah/kedai/kantor menjadi tujuh; Griya Sasmita pada versi 8 menjadi bangunan kedelapan. Bangunan baru belum menyediakan interior yang dapat dimasuki, tempat tidur, penyimpanan barang, transaksi panen, atau hadiah baru. Jadwal dan aktivitas warga dibahas terpisah dari keberadaan bangunannya.

Pemeriksaan lokal mencakup 30 ruas jalur hub dengan jarak aman tubuh 13 piksel serta titik awal/akhir rute warga yang ada. Render native siang dan malam selesai tanpa kesalahan shader; bukti visual tersedia secara lokal di `artifacts/godot/village7/`. Pemeriksaan ini belum menyatakan hasil pengujian peramban atau perangkat fisik untuk revisi tersebut.

## Griya Sasmita pada tata letak 8

Rumah Nala dibangun terpisah di sebelah barat Kedai Waras. Rumah panggung memiliki dek kayu, tiang penopang hingga permukaan air, beranda, dan sambungan jembatan berpagar menuju pelataran lama. Tidak ada rumah warga atau kantor Raka yang digantikan. Lantai dek dan footprint penghalang dipakai bersama oleh renderer serta validasi server.

| Unsur       | Geometri atau titik interaksi                  |
| ----------- | ---------------------------------------------- |
| Rumah Nala  | Kotak pembatas 60, 420, 200, 145; elevasi 2    |
| Pintu luar  | 160, 615                                       |
| Dek beranda | x 40–280, y 385–735; elevasi 2                 |
| Rakit kebun | x 40–280, y 735–875; elevasi 2                 |
| Jembatan    | Sumbu 265, 720 menuju 400, 720; lebar 80       |
| Petak 1     | Footprint 65, 760, 80, 70; interaksi 105, 850  |
| Petak 2     | Footprint 165, 760, 80, 70; interaksi 205, 850 |

Jembatan ditempatkan di sebelah selatan pohon yang sudah ada. Titik pagar dan lantai tidak dipilih hanya dari gambar; ruas jalan diperiksa dengan jarak aman tubuh 13 piksel. Jalan menuju petak kebun memutari sisi kanan bedeng dan berakhir pada papan pijakan di depannya. Air di luar dek tidak menjadi lantai yang dapat dilalui.

`HomesteadScene.gd` merupakan ruang kecil yang benar-benar dapat dijelajahi. Scene membuat Player, kamera tiga perempat, lantai 3D, dan penghalang furnitur dari `WORLD.homestead.interior`. Atap dan dinding depan dipotong untuk pandangan; collision furnitur tetap aktif. Dipan rotan, meja arsip, peti, rak pameran, dan ambang pintu masing-masing memiliki titik pendekatan yang sah. Scene menerbitkan sinyal interaksi dan menerima `set_state(home)`; menu dan panggilan API berada pada pengendali rumah, bukan pada renderer. Ruang memakai anyaman pada selimut dan tikar, dua bantal, sandaran rotan, buku serta gulungan lontar di meja arsip, keranjang pada rak, dan tanaman kecil pada meja. Dua lampu memberi cahaya hangat lokal; cahaya lingkungan khusus interior dinaikkan secukupnya pada malam hari agar serat kayu dan jalan tetap terbaca. Bingkai dinding samping dan dinding depan rendah memperjelas volume tanpa menutupi pintu.

Empat penampilan serta sistem pakaian/perlengkapan tetap menggunakan komponen karakter yang ada. Rak kosong tidak menampilkan artefak. Barang yang dipamerkan hanya berasal dari `player.adventure.keyItems`. Dua petak di luar mengikuti `homestead.plots`: `empty`, `seed`, `sprout`, `young`, atau `ready`; `needsCare` menentukan tampilan perlu dirawat. Renderer tidak menentukan pertumbuhan, mengurangi bibit, atau memberikan hasil panen.

Pengujian geometri/interior lokal memeriksa 287 sampel lintasan, footprint furnitur, lima interaksi yang dapat dicapai, jeda modal, empat identitas dengan tiga pakaian, serta ketiadaan perubahan ekonomi/state server oleh scene. Render native eksterior, interior siang, dan interior malam tersedia di `artifacts/godot/homestead/`. Bukti ini menguji scene dan renderer; penerimaan akhir transaksi peti, tidur, refresh, serta masuk/keluar tetap memerlukan pengujian API dan peramban terpadu.

## Rancangan perluasan yang belum aktif

Perluasan berikutnya mencakup interior rumah yang lebih lengkap, keramba pribadi, fungsi lanjutan balai Ki Lurah, serta Laskar Kognisi: Bagas, Kinasih, Gito, Cempaka, dan Danu. Pertahankan nama dan peran tersebut untuk perluasan berikutnya. Jangan menampilkan tombol panen, tidur, pemberian bibit, ataupun hadiah yang belum mempunyai layanan server.

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
