# Rencana 03: desa hidup, Griya Sasmita, dan siklus harian

Tanggal penyusunan: 9 November 2026. Status: implementasi prototipe dan regresi lokal selesai; rilis staging mengikuti prosedur di bagian 17. Baseline yang diperiksa: `d503059`.

Dokumen ini merupakan rencana baru setelah [Rencana 02](02-misi-bu-darmi-dan-gameplay.md). Rencana 02 tetap menjadi catatan pekerjaan yang telah selesai. Bagian rencana di bawah dipertahankan sebagai kriteria kerja. Kontrak yang berjalan dicatat di [API](../api.md) dan [status pengembangan](../development-status.md); catatan pelaksanaan di akhir membedakan implementasi dan tindak lanjut.

## 1. Hasil yang dituju

Pemain dapat menjalani satu putaran kegiatan yang tersambung:

**Bangun di rumah Nala → merawat kebun dan menemui warga → menjelajah hutan atau menyelam → membawa hasil ke Kedai Waras → pulang → tidur → melihat hari dan kebun berubah.**

Dunia perlu menunjukkan hasil tindakan pemain. Rumah dapat dimasuki, warga benar-benar menggerakkan tubuh saat bekerja, kebun menyimpan pertumbuhannya, dan hasil panen mempunyai penggunaan di kedai. Kualitas dinilai dari bermain langsung, kesesuaian dengan moodboard, dan ketahanan penyimpanan.

Prioritas pengalaman: gerak dan interaksi yang nyaman, rumah yang berguna, kebun sederhana yang lengkap, lalu pemolesan koridor desa–hutan–pesisir. Setiap tahap harus dapat ditinjau tanpa menunggu semua fitur selesai.

## 2. Dasar yang sudah tersedia

| Bagian      | Kondisi baseline                                                               | Pekerjaan berikutnya                                                       |
| ----------- | ------------------------------------------------------------------------------ | -------------------------------------------------------------------------- |
| Runtime     | Godot 4.7.2 Compatibility/Web; React untuk akun dan admin                      | Lanjutkan integrasi di Godot                                               |
| Daratan     | Kamera ortografis 35°, viewport 480 × 270, terrain 3D, karakter billboard      | Pertahankan kedalaman, pijakan, dan keterbacaan piksel                     |
| Peta        | Hub layout 7, hutan layout 5; manifest bersama renderer dan API                | Tambahkan rumah Nala serta portal dengan migrasi yang menjaga save         |
| Warga       | Enam profil tambahan; Saras hadir pada siklus cerita 2; Bu Darmi ikut jadwal   | Tingkatkan animasi tubuh dan hubungan aktivitas dengan tempat kerja        |
| Kegiatan    | Jadwal kerja/pulang/berteduh dan alat 3D terpisah                              | Ganti gambar tubuh statis dengan klip kerja dan jalan yang sesuai          |
| Bangunan    | Rumah Ratih, Sari, Tedi, balai lurah, kedai, bengkel, kantor PT                | Tambahkan fungsi yang dapat digunakan pemain                               |
| Pemain      | Empat identitas, pakaian harian/explorer/diving, alat modular, bilik dermaga   | Pastikan klip baru dan interior mendukung semuanya                         |
| Waktu       | Jam kosmetik 24 jam dalam 36 menit nyata; modal menjeda jam                    | Tambahkan hari dan aturan pertumbuhan yang disimpan server                 |
| Cerita      | `progress.day`, `stage`, `missions`; tiga siklus menuju Gajah Mina             | Pisahkan kemajuan cerita dari kalender kegiatan                            |
| Penyimpanan | Progres, inventori, hadiah dan transaksi berada di server                      | Integrasikan rumah, kalender, kebun, serta pemulihan setelah koneksi putus |
| Visual      | Grading dunia, lampu, parallax laut, atmosfer, arus, buih, fauna               | Poles komposisi dan konsistensi, berdasarkan perbandingan gambar           |
| Alat        | WorldKit, Pixel Snapper, Image-to-Pixel, jalur Polyfork dan alat produksi lain | Gunakan untuk menghasilkan aset dan manifest yang ditinjau                 |

Pemeriksaan baseline tercatat pada [status pengembangan](../development-status.md): 60 tes API, 18 pemeriksaan dunia, build, serta alur browser lokal dan HTTPS. Ini merupakan bukti baseline, bukan bukti bahwa fitur dalam rencana ini sudah selesai.

## 3. Keputusan yang menjadi pegangan

1. Satu hari penuh tetap 36 menit nyata. Pemain dapat mempercepat waktu melalui tindakan tidur atau memulai pelayanan kedai yang divalidasi server.
2. Hari kalender berbeda dari siklus cerita. Menunggu atau tidur tidak otomatis menyelesaikan misi, membuka Saras, menaikkan level alat, atau membuka boss.
3. Griya Sasmita merupakan rumah Nala tersendiri: rumah panggung pesisir, rakit kebun, dan akses dermaga. Rumah warga tidak diganti menjadi rumah Nala.
4. Kantor pihak PT tetap berupa container house pada petak terpisah. Balai lurah mempertahankan arsitektur desa dengan atap bertingkat. Raka tetap mengikuti jabatan yang sudah ada dalam cerita; penambahan tokoh direktur memerlukan penetapan identitas cerita tersendiri.
5. Bangunan, tangga, jembatan, pijakan dan collider memakai data yang sama. Dekorasi tidak boleh mengubah air menjadi lantai atau membuat atap dapat dipijak.
6. Tabung, jala, alat kebun dan alat kerja warga tetap terpisah dari gambar tubuh. Klip menggambarkan aksi; server menentukan konsumsi, hasil dan progres.
7. Nuansa visual mengikuti referensi pengguna: hijau tropis yang hidup, tanah hangat, laut teal, bayangan berwarna, cahaya lokal yang nyaman. [Palet terbaru](../art-direction-comfy.md) didahulukan ketika catatan lama lebih kusam.
8. Permainan dan antarmuka di dalam dunia tetap ditangani Godot. Referensi Phaser/React diterjemahkan menjadi perilaku yang sesuai dengan runtime yang tersedia.
9. Setiap perluasan mempunyai fungsi yang dapat dicoba. Fitur yang belum tersambung ke server tidak ditampilkan sebagai tombol siap pakai.

## 4. Batas rilis ini

### Wajib selesai

- Animasi jalan dan kerja warga, dengan tiga pilot: Mang Ujang, Bu Darmi, dan Yu Sari.
- Rumah Nala yang dapat dimasuki dan ditinggalkan, tempat tidur, meja arsip, serta peti sederhana.
- Hari kalender dan waktu yang pulih setelah login ulang, dengan aturan tidur dan pergantian cerita yang jelas.
- Dua petak kebun dan sedikitnya satu tanaman yang dapat ditanam, dirawat, tumbuh, dipanen, serta digunakan di kedai.
- Transaksi pasar Ratih yang terbatas dan papan informasi/misi balai yang memakai data nyata.
- Satu putaran kegiatan dari rumah sampai kembali tidur, tanpa kehilangan progres atau mengunci cerita.
- Finishing pada rumah, kawasan warga, kebun, akses hutan, kedua jembatan, dermaga dan pesisir yang dilalui putaran tersebut.

### Sesudah putaran dasar diterima

Tanaman kedua, perluasan petak, keramba dan pembiakan ikan, hidroponik dengan pH/PPM, komposter, otomatisasi oleh anak-anak, interior seluruh rumah warga, serta perluasan lengkap Laskar Kognisi. Kerangka rumah dan kebun harus memberi ruang untuk fitur ini tanpa memasukkannya sekaligus ke rilis pertama.

Peta wilayah baru, pergantian engine, editor visual besar, multiplayer, dan perubahan sistem pertarungan tidak menjadi pekerjaan utama rencana ini.

## 5. Tahap A: kontrak hari, penyimpanan, dan transisi cerita

Tahap ini menjadi fondasi untuk rumah dan kebun. Pengerjaan aset animasi dapat berjalan setelah kontraknya ditetapkan.

### Pemisahan waktu

| Konsep           | Pemilik keputusan              | Aturan                                                         |
| ---------------- | ------------------------------ | -------------------------------------------------------------- |
| Siklus cerita    | Server, progres yang sudah ada | Tetap memakai syarat misi dan pelayanan kedai                  |
| Hari kalender    | Server                         | Bertambah pada batas hari yang sah atau tidur yang melewatinya |
| Menit permainan  | Server, diinterpolasi klien    | 24 jam setara 36 menit aktif; jeda membaca berlaku             |
| Pertumbuhan      | Server, per tanaman            | Batas hari diproses sekali; tidak dihitung dari jumlah frame   |
| Animasi air/awan | Renderer                       | Dapat terus bergerak saat waktu kegiatan dijeda                |

Usulan data minimum: `calendarDay`, `minuteOfDay`, `calendarRevision`, `lastSettledDay`, dan bukti penutupan kedai yang menunggu penyelesaian hari. Nama final ditetapkan saat implementasi. `progress.day` lama diperlakukan sebagai siklus cerita dan tidak diganti namanya secara merusak kontrak lama.

- Sumber waktu berasal dari durasi aktif yang diakui server. Klien tidak mengirim jumlah hari, hasil pertumbuhan, atau jam selesai pilihannya sendiri.
- Gunakan pembaruan berkala yang dibatasi dan checkpoint saat transaksi/transisi. Jangan membuat request setiap frame atau menulis MongoDB setiap detik.
- Saat koneksi putus, aplikasi ditutup, atau tab tidak aktif, kalender berhenti pada checkpoint sah. Pertumbuhan offline belum termasuk rilis ini.
- Tetapkan satu sesi penulis waktu per akun. Dua tab tidak boleh melipatgandakan durasi aktif atau pemrosesan hari.
- Jeda dialog/buku/kuis dipadukan dengan kontrak membaca yang sudah ada. Sesi jeda mempunyai pemulihan setelah tab ditutup agar akun tidak terjebak dalam keadaan dijeda.
- Refresh mengambil waktu yang tersimpan. `EnvironmentState.update_story()` perlu disesuaikan agar tidak mengembalikan jam ke pagi atau malam pada setiap pemuatan progres.
- Cuaca yang memengaruhi petak mempunyai pola/seed dan bukti kejadian yang ditentukan server. Klien menampilkan kondisi yang sesuai; hujan shader lokal tidak menjadi bukti bahwa tanaman sudah tersiram.

### Tidur dan tengah malam

Target tidur adalah kemunculan pukul 06.00 berikutnya. Tidur pada pukul 23.00 melewati batas hari; tidur pada pukul 02.00 menuju pukul 06.00 pada hari kalender yang sama. Menutup buku, reload, atau mengulang request tidur tidak memberikan hari tambahan.

Melewati tengah malam secara alami dapat menaikkan hari kalender dan menyelesaikan pertumbuhan yang memenuhi syarat. Peristiwa ini tidak menutup kedai, membatalkan penyelaman, memindahkan pemain, atau menaikkan siklus cerita. Tidur di siang hari memerlukan pilihan singkat yang menjelaskan bahwa kegiatan hari itu akan dilewati.

### Perubahan kontrak penutupan kedai

Saat ini `/api/kedai/close-shift` langsung menaikkan `progress.day` atau mengubah stage ke boss. Rencana baru mengubah urutannya secara terkoordinasi:

1. Penutupan pelayanan yang lengkap mencatat hasil dan hak kemajuan cerita sekali, kemudian menampilkan tujuan pulang.
2. Tidur menyelesaikan pergantian pagi dan menerapkan kemajuan cerita yang sudah sah, dalam satu transaksi.
3. Tidur lebih awal tanpa hak kemajuan hanya mengubah kalender; misi dan siklus cerita tetap.
4. Giliran aktif atau pelanggan cerita wajib yang belum selesai ditangani secara eksplisit. Pemain dapat menutup sementara untuk mencari stok; rumah memberi alasan jika tidur belum dapat menyelesaikan hari cerita.
5. Pelayanan yang sudah lengkap tidak dapat dibuka ulang untuk menerima hadiah lagi selama menunggu tidur.

Jangan menambahkan tombol tidur dahulu lalu meninggalkan kenaikan hari pada dua endpoint. Migrasi harus menangani save lama yang sudah menerima kenaikan hari dari kontrak lama tanpa memberikannya lagi. Respons close-shift, UI kedai, endpoint tidur dan pengujian alur cerita dirilis bersama.

Kedai tersedia melalui syarat cerita. Pemain tidak diwajibkan menunggu jam nyata untuk pelanggan wajib: tindakan memulai persiapan dapat memajukan waktu ke awal pelayanan, dengan hasil yang ditentukan server. Jadwal NPC tidak boleh mengunci misi.

Sesudah stage `done`, kegiatan rumah, kebun, dan layanan yang sesuai tetap dapat digunakan tanpa mengulang akhir cerita atau memunculkan hadiah boss kembali. Audit jalur akses pasca-ending termasuk dalam integrasi ini.

### Kriteria selesai A

- Tidur, rollover alami dan penutupan kedai mempunyai tabel transisi yang konsisten.
- Dua request serentak, retry setelah respons hilang, reload, serta perubahan jam perangkat tidak menggandakan hari atau hasil.
- Save lama dapat melanjutkan tiga siklus, misi Bu Darmi dan boss tanpa mengulang hadiah atau kehilangan inventori.
- Simulasi cepat menguji satu hari penuh tanpa harus menunggu 36 menit nyata; ritme nyata tetap ditinjau melalui playtest.

## 6. Tahap B: animasi tubuh dan alat warga

Mulai dari tiga aksi yang paling mudah dinilai secara visual, kemudian perluas pola yang sudah diterima.

| Pilot      | Urutan aksi yang terlihat                                        | Hal yang harus sesuai                                                    |
| ---------- | ---------------------------------------------------------------- | ------------------------------------------------------------------------ |
| Mang Ujang | Menyiapkan joran, melempar, menunggu, menarik, merapikan         | Tangan memegang joran; tali dan pelampung berada di air                  |
| Bu Darmi   | Mengambil penyiram, mengarahkan, menyiram, menurunkan alat       | Tetesan mengenai tanaman/petak yang dituju; kaki berada di tepi yang sah |
| Yu Sari    | Memegang rangka, menggerakkan tangan dan benang, memeriksa hasil | Rangka tidak menembus badan; benang mengikuti tangan                     |

Warga berikutnya memakai klip yang relevan: Ratih menata/menimbang barang, Tedi memeriksa sampel dan alat, Lurah membaca tanda pasang atau berbicara, Saras membaca dan menulis catatan. Mbah Wira dan Beno mendapat klip kerja di tungku serta bangku bengkel pada tahap integrasi kedai.

### Kontrak produksi animasi

- Pisahkan tubuh, pakaian, tangan, dan perlengkapan sejauh diperlukan. Hapus alat yang sudah tergambar permanen pada gambar tubuh sebelum memasang alat modular baru.
- Mulai dengan empat arah yang sesuai proyeksi kamera. Perluasan menjadi delapan arah dilakukan bila pilot menunjukkan kebutuhan; cermin sprite hanya digunakan jika alat dan detail asimetris tetap benar.
- Klip minimum: diam, berjalan, berinteraksi, mulai kerja, kerja berulang, selesai kerja, serta istirahat. Setiap klip mempunyai durasi dan perpindahan yang jelas.
- Metadata memuat pivot kaki, titik tangan, arah hadap, posisi depan/belakang alat, dan peristiwa suara/efek. Tetapkan resolusi bingkai setelah membandingkan satu pilot pada viewport asli.
- Navigasi menentukan perpindahan badan. Klip tidak membawa root motion yang memindahkan NPC melewati collider.
- Animasi langkah mengikuti jarak bergerak yang benar-benar ditempuh. Warga yang tertahan tidak terus menampilkan berjalan di tempat.
- Percakapan menyelesaikan atau menghentikan aksi secara wajar sebelum menghadap pemain. Alat tidak muncul atau hilang mendadak di tengah aksi.
- Peristiwa langkah, percikan dan alat dipicu sekali pada waktunya, memakai AudioManager/WorldFoley yang sudah tersedia.
- Pengurangan gerak menurunkan bob, goyangan dan efek tambahan. Perilaku navigasi dan akses interaksi tetap konsisten dengan kebijakan aksesibilitas yang disepakati.
- Empat identitas pemain dan tiga pakaian diuji terhadap titik alat yang sama ketika klip pemain ikut diperbarui.

Kriteria selesai B: tiga pilot disetujui dari rekaman bergerak pada kamera game, siang dan malam. Tubuh berubah antarbingkai, tangan bersentuhan dengan alat, kaki tetap berpijak, dan pergantian kerja–jalan–dialog tidak menembus objek. Gambar diam serta penghitung mesh saja tidak cukup membuktikan kualitas animasi.

## 7. Tahap C: Griya Sasmita dan fungsi rumah

### Penempatan dan akses

- Susun blockout rumah Nala di sisi permukiman dekat jalur Kedai Waras dan dermaga. Pilih petak setelah memeriksa lantai, pesisir, landmark, sudut kamera, dan ruang kebun; koordinat tidak ditetapkan dari perkiraan gambar saja.
- Sediakan satu jalur utama yang jelas menuju rumah. Jika memakai jembatan gantung, bangun dek, ketebalan, penyangga, pagar, dan collider yang sejalan dengan permukaan air.
- Rumah memiliki beranda, pintu yang terbaca, fondasi/tiang yang menyentuh terrain, dan ruang perluasan rakit. Tinggi tangga mengikuti beda elevasi sebenarnya.
- Naikkan versi layout ketika lantai, footprint atau portal berubah. Posisi lama yang masih aman dipertahankan; posisi yang terhalang dipindahkan ke titik aman terdekat tanpa mengubah progres.

### Interior pertama

Interior kecil dibangun sebagai scene 3D/2.5D dengan pintu masuk, dipan rotan, meja peta/lontar, peti, dan rak pameran. Kamera mempertahankan sudut tiga perempat; atap atau dinding depan dapat disembunyikan ketika menghalangi pandangan. Collision tidak ikut hilang saat atap memudar.

Masuk rumah menggunakan portal eksplisit yang divalidasi dari posisi server dekat pintu. Transisi singkat memindahkan pemain ke titik interior sah; keluar mengembalikan ke titik luar yang jelas. Berpindah area tidak boleh menjadi teleport umum menuju lokasi pilihan.

| Objek rumah | Fungsi rilis pertama                           | Perilaku yang harus terlihat                                               |
| ----------- | ---------------------------------------------- | -------------------------------------------------------------------------- |
| Dipan rotan | Tidur sesuai kontrak Tahap A                   | Pilihan tidur, hasil pagi, serta alasan bila ada kegiatan yang menghalangi |
| Meja arsip  | Membuka jurnal/pengetahuan yang sudah dimiliki | Teks dapat dibaca; entri terkunci mengikuti progres nyata                  |
| Peti        | Menyimpan dan mengambil barang yang diizinkan  | Jumlah sebelum/sesudah berasal dari transaksi server                       |
| Rak pameran | Menampilkan key item yang benar-benar dimiliki | Slot kosong tidak menampilkan hadiah yang belum diperoleh                  |

### Penyimpanan dan pemulihan

Progres sudah disimpan server. Rumah tidak boleh memberi kesan bahwa semua progres hanya tersimpan setelah pemain menekan tombol simpan. Tampilkan status penyimpanan saat diperlukan, terutama ketika tidur atau memindahkan barang.

- Transfer peti bersifat atomik, mempertahankan ID, kualitas dan jumlah barang. Tas menyelam aktif tidak dapat dipindahkan dari dalam laut.
- Key item cerita dan kemampuan tidak boleh tersimpan pada tempat yang membuat misi kehilangan akses.
- Bibit/hasil kebun dipisahkan secara tipe dari fragmen pengetahuan, lalu diberi tampilan inventori yang sesuai.
- Refresh di dalam rumah memulihkan area dan titik yang aman. Jika versi interior berubah, gunakan migrasi menuju pintu masuk interior atau pintu luar.
- Gagal memuat rumah tidak membuat pemain terjebak pada layar gelap. Sediakan pemulihan ke titik luar yang sudah divalidasi.
- Pemindahan barang, tidur, dan perubahan admin mengikuti versi sesi yang sudah ada. Hasil sesi lama tidak boleh menimpa keadaan baru.

Kriteria selesai C: pemain masuk rumah, membaca arsip, memindahkan barang, tidur, memuat ulang permainan, lalu keluar dengan posisi dan jumlah item yang benar. Putaran tersebut bekerja untuk empat penampilan, keyboard dan sentuh.

## 8. Tahap D: kebun pertama dari bibit sampai kedai

Mulai dengan dua petak di rakit Griya Sasmita dan satu tanaman. Tambahkan tanaman kedua setelah alur pertama lulus. Tahap pertumbuhan minimum: petak kosong, bibit, tunas, tanaman muda, siap panen, dan keadaan perlu dirawat.

### Pembukaan kebun

Hak kebun pribadi dikaitkan dengan fakta penyelesaian misi Bu Darmi dan izin Lurah. Gunakan fakta server yang tersedia, termasuk misi `akar`; jangan menafsirkan `calendarDay >= 2` sebagai siklus cerita kedua. Akun lama yang sudah memenuhi syarat memperoleh akses melalui migrasi/derivasi yang idempoten.

Petak tidak dibuka hanya dari dialog kosmetik. Papan balai memberi syarat yang belum dipenuhi dan menunjukkan lokasi Bu Darmi atau catatan misinya.

### Aturan tanaman yang dituju

1. Pemain memilih petak dan bibit dari inventori yang dimiliki.
2. Server memvalidasi lokasi, petak kosong, hak kebun dan jumlah bibit, lalu mengonsumsi satu bibit.
3. Penyiraman memberi status dirawat untuk hari yang berlaku. Mengulang penyiraman tidak menambah pertumbuhan berkali-kali.
4. Pertumbuhan dihitung pada batas hari yang sah. Setiap petak menyimpan hari terakhir yang telah diproses.
5. Hujan dapat memenuhi kebutuhan air melalui aturan cuaca yang ditentukan server. Variasi shader atau hujan lokal klien tidak langsung memberi hasil pertanian.
6. Pada versi pertama, tanaman yang kurang dirawat tertunda tumbuh dan mendapat penjelasan. Kematian permanen serta penyakit acak ditunda agar kebun pertama mudah dipahami.
7. Tanaman siap panen tetap tersedia sampai dipanen; keluar permainan atau terlambat beberapa menit tidak menghapusnya.
8. Panen memberi hasil sekali dan mengubah petak secara atomik. Tahap awal memakai tanaman sekali panen; tanaman yang tumbuh kembali ditambahkan kemudian bila diperlukan.

Durasi pertumbuhan, hasil per petak, stok bibit dan harga merupakan parameter konfigurasi untuk playtest. Tidak memberi klaim keseimbangan sebelum diuji. Pemain boleh tidur untuk memajukan kalender, tetapi produksi tetap membutuhkan bibit dan perawatan yang sah.

### Hasil fisik dan fragmen pengetahuan

Katalog saat ini memakai ID seperti `klorofil` untuk Benih Hayati, `ekosistem`, `rasio`, dan `netralisasi`. Nama Benih Hayati tidak berarti item tersebut sudah merupakan bibit pertanian. ID `frag_bio_*` pada referensi pengguna bukan kontrak katalog aktif.

Tambahkan definisi bibit dan hasil pertanian yang jelas. Panen menghasilkan bahan kebun, sedangkan kuis/penemuan tetap menghasilkan fragmen pengetahuan. Bahan kebun tidak otomatis menjadi fragmen bintang tiga atau menggantikan syarat pembelajaran.

### Penggunaan hasil di kedai

- Tambahkan satu penggunaan konkret: hasil kebun dititipkan sebagai stok bahan pelengkap untuk satu sajian opsional.
- Mulai dengan satu bahan dan satu sajian yang jelas. Menu menampilkan stok dan pemakaian; server mengonsumsi bahan saat penyajian berhasil.
- Fragmen pengetahuan wajib pada resep cerita tetap diperlukan. Hasil kebun dapat memberi variasi penyajian atau bonus terbatas yang ditetapkan konten, tanpa menyelesaikan misi cerita sendiri.
- Resep lama tetap bekerja ketika akun belum mempunyai kebun atau versi konten belum memuat hasil pertanian.
- Jangan membuat perubahan kimia/biologi yang menyesatkan. Materi ilmiah baru diperiksa terhadap sumber pendidikan yang berwenang saat kontennya ditulis.

Kriteria selesai D: tanam → siram → hari berganti → pertumbuhan → panen → stok kedai → penyajian, seluruhnya tetap benar setelah reload, request ganda, koneksi putus, dan pergantian perangkat. Ada perubahan visual pada setiap tahap dan bahan benar-benar digunakan.

## 9. Tahap E: pasar, balai dan hubungan warga

### Pasar Ratih

Pasar menyediakan stok bibit yang terbatas dan daftar transaksi yang ringkas. Harga, stok dan saldo ditetapkan server. Pembelian ulang akibat retry tidak menggandakan barang atau pengurangan koin. Penjualan hasil kebun baru dibuka setelah perbandingan harga beli, hasil dan penggunaan kedai diperiksa agar tidak ada putaran beli–jual yang langsung mencetak koin.

Pasar mempunyai lokasi layanan yang jelas. Jadwal kerja memberi variasi visual; pemain tetap dapat memperoleh kebutuhan penting melalui antrean/panggilan di titik pasar atau persediaan awal yang cukup. Jangan membuat cerita gagal karena Ratih sedang berjalan pulang.

### Balai lurah

Mulai dari papan pengumuman di beranda balai: izin kebun, status misi warga yang benar-benar tersedia, dan arsip tujuan. Interaksi Lurah membuka izin ketika syarat sah terpenuhi. Interior balai yang luas bukan prasyarat untuk fungsi pertama.

Papan tidak menampilkan deretan misi kosong, penghargaan palsu, atau semua pekerjaan rencana sebagai fitur aktif. Tidak perlu menambahkan quest engine besar untuk satu izin; gunakan fakta progres yang sudah ada dan kontrak minimum yang dapat diperluas.

### Keterhubungan warga

Bu Darmi menjelaskan perawatan kebun, Ratih menyediakan bibit, Lurah memberi izin, Beno menangani alat yang sudah menjadi tanggung jawabnya, dan Mbah Wira memakai hasil di kedai. Kinasih/Danu serta anggota Laskar Kognisi masuk pada perluasan berikutnya setelah putaran ini stabil, bukan sekaligus sebagai NPC tanpa fungsi.

Kriteria selesai E: layanan dapat ditemukan, syaratnya terbaca, transaksi bertahan setelah login ulang, dan kegiatan warga tetap bisa diakses sepanjang kebutuhan cerita tanpa hadiah berulang dari percakapan kosmetik.

## 10. Tahap F: satu putaran harian yang lengkap

| Urutan        | Aksi pemain                            | Respons dunia                                   | Bukti selesai                                       |
| ------------- | -------------------------------------- | ----------------------------------------------- | --------------------------------------------------- |
| Pagi          | Bangun dan keluar rumah                | Waktu, posisi serta kebun sesuai save           | Tidak kembali ke spawn dermaga tanpa alasan         |
| Kegiatan desa | Menyiram, membeli bibit, menemui warga | Klip tubuh/alat dan respons singkat sesuai aksi | UI dan jumlah barang cocok dengan server            |
| Eksplorasi    | Memilih hutan atau dermaga             | Outfit, alat, terrain dan petunjuk menyesuaikan | Jalur serta misi tetap dapat diselesaikan           |
| Penyelaman    | Menjelajah, menjala dan membawa hasil  | Air, atmosfer dan fauna mendukung eksplorasi    | Oksigen, tas, penemuan dan ekstraksi tetap sah      |
| Kedai         | Menitipkan hasil kebun dan melayani    | Bahan dikonsumsi serta hasil tercatat           | Hadiah dan penyajian hanya sekali                   |
| Pulang        | Menutup kedai dan berjalan ke rumah    | Tujuan pulang jelas, jalur malam terbaca        | Giliran tidak terbuka ulang untuk duplikasi hadiah  |
| Tidur         | Mengakhiri hari                        | Pagi, pertumbuhan dan kemajuan cerita yang sah  | Retry/reload tidak memberi hari atau hasil tambahan |

Sasaran playtest: pemain memahami tujuan berikutnya tanpa harus membaca dokumen atau membuka beberapa modal setiap saat. Catat durasi aktif dan titik kebingungan; jangan menyatakan durasi putaran sebelum ada sesi bermain manusia.

Interaksi pendek memakai satu tombol aksi kontekstual. Menu dibuka untuk memilih barang, membaca informasi, atau membuat keputusan yang memang perlu pilihan. Waktu dan bahaya yang dijeda mengikuti kontrak server, sementara animasi lingkungan tetap dapat berjalan.

## 11. Tahap G: finishing visual dan audio

Finishing dimulai sebagai peninjauan kecil pada tiap tahap, lalu menjadi pemeriksaan lintas area setelah putaran berfungsi. Pertahankan arah tropis pesisir Nusantara pada [arah budaya](../brand/cultural-direction.md) dan referensi pengguna.

| Area            | Pekerjaan utama                                                                    | Bukti visual yang diminta                                              |
| --------------- | ---------------------------------------------------------------------------------- | ---------------------------------------------------------------------- |
| Rumah Nala      | Siluet rumah panggung, sambungan rakit, beranda, lampu, benda rumah tangga         | Eksterior, interior, masuk/keluar, lampu malam mengenai lantai         |
| Permukiman      | Variasi atap, skala pintu/manusia, kelompok barang kerja, tempat duduk dan tanaman | Pemandangan desa yang mempunyai fokus serta ruang navigasi             |
| Jalan           | Transisi tanah–rumput–batu, tepi yang tidak seragam, sambungan tangga/teras        | Jalur terbaca pada siang, malam dan hujan; kaki tidak melayang         |
| Hutan           | Tajuk depan/tengah/belakang, atmosfer jarak, celah cahaya, semak berkelompok       | Karakter tertutup secara wajar tetapi tetap dapat dinavigasi           |
| Jembatan        | Sambungan kedua ujung, papan, penyangga, pagar dan beda elevasi                    | Rekaman berjalan di kedua arah serta berhenti pada pagar               |
| Dermaga/pesisir | Tiang tertanam, transisi air–pantai, variasi arus dan buih, benda tambat           | Video bergerak, bukan satu gambar air statis                           |
| Laut            | Batu tersambung ke dasar/dinding, celah renang, parallax dan pemisahan jarak       | Pergerakan kamera memperlihatkan perbedaan lapisan tanpa batu melayang |

- Palet diperiksa pada konteks pencahayaan yang sama sebelum/sesudah. Meningkatkan saturasi seluruh layar bukan pengganti perbaikan material.
- Lentera dan jendela memberi cahaya lokal; malam tetap menunjukkan jalur, tangga, batas air serta wajah. HUD tidak ikut menjadi kusam karena grading dunia.
- Atap dan tajuk memakai occlusion yang mempunyai alasan geografis. Efek memudar tidak boleh membuat collider salah atau menyingkap seluruh peta sekaligus.
- Pergerakan air, daun dan partikel berbeda menurut skala/jarak. Batasi pola berulang yang mudah dikenali.
- Audio memakai SFX permukaan dan ombak yang tersedia. Suara alat mengikuti aksi; ambience diberi transisi dan batas jumlah pemutar.
- Antarmuka memakai kayu, kuningan dan perkamen sesuai identitas; teks panjang memakai font terbaca. Ukuran tombol sentuh dan keyboard mengikuti pemeriksaan yang sudah ada.
- Bloom, blur, vignette dan efek kamera dibuat ringan. Pertahankan tepi piksel, keterbacaan tindakan, dan kenyamanan saat pengurangan gerak aktif.

## 12. Data, layanan, dan modul yang direncanakan

| Lingkup                                                                              | Perubahan yang diperkirakan                                                                      |
| ------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------ |
| `packages/shared/src/index.ts` dan modul baru                                        | Tipe kalender, rumah, bibit/hasil, aturan petak, stok pasar, respons transisi hari               |
| `packages/shared/src/land.ts`, `world.ts`, `village.ts`                              | Rumah Nala, koneksi, portal, titik kerja/istirahat dan tujuan layanan                            |
| `apps/api/src/game.ts`                                                               | Integrasi close-shift, snapshot dan transisi cerita yang sudah tersedia                          |
| Modul API baru, nama usulan `calendar.ts`, `homestead.ts`, `village-interactions.ts` | Aturan hari, tidur, peti, petak dan transaksi layanan; gunakan pola lock/once/transaksi yang ada |
| `client-godot/autoloads/EnvironmentState.gd`                                         | Waktu hasil server dan interpolasi visual, terpisah dari kemajuan cerita                         |
| `HubActor.gd`, `NpcActivityNavigation.gd`, `VillageActivity3D.gd`, `LandActors3D.gd` | Klip tubuh, titik tangan, alat, transisi aktivitas dan navigasi                                  |
| Scene/script rumah dan kebun baru                                                    | Interior, portal, interaksi benda, render tahap tanaman serta umpan balik                        |
| `Main.gd`, `GameHud.gd`, `InventoryView.gd`, `WorldAtlas.gd`                         | Tujuan harian, akses rumah, tampilan stok/barang dan penanda geografis                           |
| `AudioManager.gd`, `WorldFoley.gd`                                                   | Peristiwa suara animasi, langkah, air dan ambience sesuai lokasi                                 |
| `tools/worldkit` dan alat aset                                                       | Ekspor draft, pemeriksaan manifest, atlas animasi, pivot dan palet                               |

Usulan operasi server: ambil snapshot rumah; masuk/keluar interior; tidur; pindahkan barang peti; tanam; rawat; panen; beli bibit; titipkan bahan kedai; klaim izin. Nama endpoint final mengikuti konvensi proyek setelah audit; daftar ini bukan endpoint yang sudah tersedia.

Setiap mutasi memvalidasi akun, versi, area, jarak atau portal sah, status sesi aktif, hak akses dan inventori. Request klien berisi niat dan ID objek, bukan hasil. Perubahan item, koin, petak, kalender dan receipt disimpan dalam transaksi yang relevan. Retry memakai kunci operasi yang sama; request baru yang berlomba tetap tunduk pada versi/keadaan terakhir.

Tambahan data dibuat kompatibel dengan akun lama melalui default yang aman dan versi skema. Jangan mengganti koleksi live dengan seed ulang. Perubahan admin tetap membatalkan hasil sesi lama; perubahan rumah normal menjaga posisi darat yang masih aman melalui helper versi permukaan yang sudah tersedia.

## 13. Penggunaan alat dan sumber aset

| Alat/sumber                        | Penggunaan pada rencana ini                                               | Batas penerimaan                                                                                                                    |
| ---------------------------------- | ------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| WorldKit                           | Draft lantai, portal, footprint, elevasi dan titik aktivitas              | Draft ditinjau; adapter saat ini hanya menargetkan hub/forest, sehingga interior memerlukan perluasan kontrak atau authoring manual |
| Polyfork                           | Batu, vegetasi atau prop 3D yang sesuai skala dan perspektif              | Material dipoles, pijakan diperiksa, kredit CC BY dicatat                                                                           |
| Blender/Kiln                       | Blockout rumah/prop dan ekspor ortografis atau GLB bila jalurnya tersedia | Periksa hasil nyata; jangan menyebut alat terpasang sebagai bukti model sudah dibuat                                                |
| Pixel Snapper                      | Merapikan kisi aset sebelum perakitan atlas                               | Ukuran, alpha dan pivot tidak berubah tanpa pemeriksaan; jangan memproses seluruh atlas buta                                        |
| Image-to-Pixel                     | Preview variasi palet comfy                                               | Bandingkan terhadap bahan sumber dan pencahayaan; keluaran tidak otomatis mengganti aset produksi                                   |
| Aseprite/Pixprite                  | Penyusunan klip dan koreksi tangan, kaki, serta alat                      | Periksa ketersediaan dan round-trip saat eksekusi; hasil runtime tetap PNG/metadata/GLB yang didukung                               |
| Sprite AI/generator gambar         | Pelengkap tubuh/prop yang belum tersedia bila diperlukan                  | Periksa akses dan lisensi; bersihkan gambar tubuh dari alat tertanam sebelum integrasi                                              |
| Pixelbolt dan jalur audio yang ada | Air dari penyiram, debu langkah, uap, percikan dan bunyi aksi             | Efek mengikuti peristiwa; jumlahnya dibatasi                                                                                        |

Reuse aset yang cocok didahulukan. WorldKit merupakan lapisan authoring milik proyek; kode dan aset upstream tetap membawa atribusi serta lisensinya. Referensi komersial di moodboard tetap privat dan tidak masuk build. Pemakaian sumber baru dicatat pada provenance dan `THIRD_PARTY_LICENSES.md`.

## 14. Urutan kerja dan pembagian yang dapat dijalankan

| Tahap                           | Dependensi                                              | Hasil yang dapat ditinjau                                                 |
| ------------------------------- | ------------------------------------------------------- | ------------------------------------------------------------------------- |
| A. Kontrak kalender dan progres | Audit baseline                                          | Tabel transisi, skema, migrasi dan tes layanan inti                       |
| B. Animasi warga                | Kontrak klip dan arah; dapat berjalan bersama fondasi A | Tiga pilot bergerak, lalu perluasan warga                                 |
| C. Rumah Nala                   | A untuk tidur; blockout dapat dimulai lebih awal        | Eksterior/interior, pintu, dipan, meja arsip dan peti                     |
| D. Kebun                        | A dan C                                                 | Dua petak, satu tanaman, panen dan pemakaian bahan di kedai               |
| E. Pasar dan balai              | Kontrak item/izin dari D                                | Bibit dapat dibeli dan hak kebun dapat dipahami/diperoleh                 |
| F. Putaran harian               | A sampai E                                              | Bermain dari bangun sampai kembali tidur dengan progres tersimpan         |
| G. Finishing lintas area        | Koridor F sudah jelas                                   | Perbandingan moodboard, video suasana, pemeriksaan performa dan perangkat |

Urutan yang terlihat pemain: pilot animasi → rumah Nala → kebun lengkap → pasar/balai → putaran harian → finishing. Kontrak A dikerjakan terlebih dahulu agar rumah dan kebun tidak membangun aturan waktu yang berbeda.

Jika memakai beberapa agen saat implementasi, batas kepemilikan harus jelas: layanan/data; animasi/aset; dunia/interior; serta integrasi/verifikasi. Satu pemilik menggabungkan kontrak shared dan integrasi `Main.gd`. Godot import, render dan export dijalankan bergantian pada proyek yang sama. Jangan membuat dua agen mengubah file pusat bersamaan atau menyatakan hasil agen lain lulus tanpa memeriksa buktinya.

Setiap tahap mempunyai checkpoint sumber, daftar perubahan, hasil uji dan bukti visual. Jika pilot belum cocok, perbaiki pilot sebelum membuat batch aset atau memperluas peta.

## 15. Skenario kegagalan yang wajib dipikirkan

| Keadaan                                       | Hasil yang diharapkan                                                                    |
| --------------------------------------------- | ---------------------------------------------------------------------------------------- |
| Respons tidur hilang lalu dikirim ulang       | Hari dan hasil yang sama dikembalikan; tidak ada pergantian hari kedua                   |
| Dua tab menekan panen                         | Hanya satu memperoleh hasil; tab lain memuat keadaan petak terbaru                       |
| Reload setelah menanam                        | Bibit sudah berkurang sekali dan tanaman tetap ada                                       |
| Putus koneksi saat transfer peti              | Tidak ada barang hilang atau tersalin; status dapat dimuat ulang                         |
| Tengah malam saat menyelam                    | Pemain tetap di laut; oksigen dan sesi tidak direset                                     |
| Tengah malam saat pelayanan kedai             | Pelanggan/hasil tidak dihapus; cerita tidak ditutup otomatis                             |
| Sudah lewat tengah malam lalu tidur           | Tidak memproses pertumbuhan hari yang sama dua kali                                      |
| Akun lama sudah melewati misi Bu Darmi        | Izin/kebun dapat diberikan sekali tanpa mengulang cerita                                 |
| Pemain belum menyelesaikan kedai wajib        | Petunjuk pemulihan jelas; tidak melompati syarat cerita                                  |
| NPC sedang pulang atau berteduh               | Interaksi penting tetap dapat diakses di titik yang masuk akal                           |
| Pemain/NPC berada pada footprint baru         | Migrasi memilih pijakan aman; inventori/progres dipertahankan                            |
| Admin mengubah/reset akun saat kegiatan aktif | Mutasi lama ditolak dan klien memuat keadaan sah                                         |
| Alat atau atlas belum dimuat                  | Kesalahan terlihat dan dapat dipulihkan; tidak menampilkan tombol palsu atau layar buntu |
| Mode pengurangan gerak atau layar sempit      | Kontrol, teks, tujuan, serta feedback hasil tetap terbaca                                |

## 16. Verifikasi dan kriteria penerimaan rilis

### Pemeriksaan layanan

Uji transaksi tidur/rollover/close-shift, request serentak, item dan koin, pemakaian bahan kedai, jarak/area, hak kebun, versi konten, migrasi akun serta pembatalan admin. Gunakan database pengujian terpisah. Pastikan alur tiga siklus sampai Gajah Mina tetap selesai.

### Pemeriksaan engine dan aset

Uji proyeksi kaki pada elevasi/tangga, metadata arah/titik tangan, perubahan bingkai nyata, transisi klip, rute kerja/rumah yang tidak menembus objek, portal, collision interior, tahap tanaman, serta layering pakaian/peralatan. Peristiwa audio/efek harus terukur satu kali per aksi yang semestinya.

### Pemeriksaan browser dan visual

- Jalankan putaran rumah–desa–hutan/laut–kedai–rumah, termasuk reload di interior dan sesudah panen.
- Bandingkan tampilan pagi, siang, senja, malam dan hujan pada posisi kamera yang sama.
- Rekam video pilot animasi, perjalanan harian, air pesisir dan dua jembatan. Periksa sprite, alat, pijakan, occlusion serta jarak lapisan secara langsung.
- Uji keyboard dan sentuh pada ukuran lanskap sempit yang sudah dipakai proyek; pertahankan teks soal minimal 16 piksel fisik dan target jawaban minimal 56 piksel pada pemeriksaan yang relevan.
- Lakukan regresi laut/air/audio ketika perubahan menyentuh integrasinya. Hindari mengulang seluruh pengujian mahal hanya karena perubahan dokumentasi.
- Ukur FPS dan waktu frame pada perangkat yang benar-benar diuji. Sasaran desktop 60 FPS dan perangkat lebih terbatas 30 FPS merupakan target, bukan klaim yang sudah terbukti.
- Kurangi efek mahal melalui profil kualitas jika perlu; pertahankan collision, informasi interaksi, bentuk 3D, palet, dan animasi inti.

### Playtest manusia

Pemain diminta mencari rumah, memahami status simpan, menjalankan satu kegiatan warga/kebun, menggunakan hasil di kedai, lalu tidur. Catat kebingungan, waktu tunggu, kebutuhan petunjuk, kenyamanan warna, keterbacaan malam, dan kejelasan hubungan belajar dengan tindakan. Pengujian otomatis tidak menggantikan penilaian kenyamanan atau kualitas gerak.

Rilis dinyatakan selesai bila semua tindakan wajib berfungsi, save pulih benar, tidak ada jalan pintas yang melompati progres, dan bukti visual telah dibandingkan dengan moodboard. Penghitung objek atau tes yang lulus saja tidak cukup.

## 17. Rilis dan pemulihan

1. Simpan perubahan sumber dan bukti pemeriksaan per tahap. Fitur eksperimental dapat memakai flag hingga seluruh kontraknya siap.
2. Siapkan migrasi yang dapat dicoba pada salinan data. Backup akun dibuat sebelum perubahan skema atau transisi hari dipakai di staging.
3. Ekspor Godot dan build API/web dari sumber yang sesuai. Cocokkan paket yang diuji dengan paket yang dipasang.
4. Setelah implementasi dan pemeriksaan memenuhi kriteria rilis, deploy ke staging, jalankan alur dengan akun uji terpisah, kemudian bersihkan hanya data akun uji tersebut.
5. Periksa health, pemulihan login, save lama dan putaran baru. Catat versi skema serta layout bersama rilis.
6. Rollback aplikasi harus mempertimbangkan data baru. Pertahankan field lama dan representasi kompatibel selama masa migrasi; jangan menganggap mengganti image lama otomatis memulihkan skema data.

Pelaksanaan dilakukan setelah pengguna menyetujui rencana ini. Rilis dan hasil verifikasinya dicatat terpisah dari rancangan awal.

## 18. Titik mulai setelah rencana diterima

Pekerjaan pertama: finalisasi tabel hari/cerita dan rancangan lokasi Griya Sasmita, sambil menyiapkan tiga pilot animasi. Hasil peninjauan pertama harus memperlihatkan Mang Ujang memancing dengan tubuh yang bergerak dan rumah Nala pada petak yang sah.

Sesudah pilot diterima, lanjutkan interior dan tidur yang tersimpan server. Kebun dimulai setelah transisi hari terbukti benar. Perluasan tanaman, keramba, NPC anak-anak dan interior rumah lain mengikuti penerimaan putaran dasar.

Referensi kerja: [kegiatan warga](../world/village-activities.md), [ekosistem desa](../world/village-ecosystem.md), [pakaian modular](../assets/modular-character-outfits.md), [arah warna](../art-direction-comfy.md), [finishing dunia](../world/cozy-finishing.md), [integrasi sumber](../reference-integrations.md), serta [backlog authoring](../nextgen-world-authoring.md).

## 19. Catatan pelaksanaan prototipe

Implementasi mempertahankan Godot, kamera daratan 35°, viewport dunia 480 × 270, empat identitas/tiga pakaian pemain, serta kantor kontainer PT yang terpisah. Hub memakai layout 8; hutan tetap layout 5. Griya Sasmita dibangun manual dalam kontrak manifest bersama, tanpa mengganti engine atau menerbitkan draft WorldKit secara otomatis.

| Tahap | Hasil yang tersedia                                                                                                                                                                                |
| ----- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| A     | Kalender server 36 menit aktif, satu penulis, jeda membaca/offline, pelepasan lease tab berlatar, hujan server, dan tidur yang menerapkan marker cerita sekali                                     |
| B     | Tiga pilot cutout berlapis: Ujang, Darmi, Sari; kaki mengikuti jarak dan alat mengikuti tangan. Empat arah belum digambar ulang lengkap; pemeran lain masih memakai portrait serta jadwal yang ada |
| C     | Rumah panggung dan interior cutaway, dipan, arsip penemuan, peti berkapasitas 100 fragmen, rak mengikuti key item yang dimiliki, serta pemulihan posisi interior                                   |
| D     | Dua petak kangkung, tiga hari pertumbuhan yang dirawat, panen tiga per petak, penyiraman/hujan, stok kedai dan bonus lima koin bersama fragmen resep yang benar                                    |
| E     | Papan izin setelah misi `akar`, dua bibit awal sekali, pembelian bibit 20 koin dan stok enam per akun per hari                                                                                     |
| F     | GUI nyata menguji rumah/kebun serta pelayanan kedai–pulang–tidur–pagi cerita berikutnya; tidur bebas tidak melewati syarat cerita                                                                  |
| G     | Rumah dan kain tenun, dua lampu interior, tombol kayu–kuningan, rumpun kangkung berdaun, lorong rakit yang diperlebar; regresi terrain/jembatan/air/parallax tetap lulus                           |

Verifikasi lokal: 77 tes API; 23 pemeriksaan Godot; 12 pemeriksaan browser daratan, delapan hybrid dan enam backdrop; sepuluh pemeriksaan rumah/kebun dan tiga pemeriksaan kedai–tidur. Tidak ada error browser pada alur akhir. Satu respons HTTP 503 sengaja disimulasikan sesudah tidur tersimpan; retry memakai kunci yang sama dan tidak menggandakan hari. Target 16 piksel teks serta 56 piksel tindakan rumah/opsi kebun kedai diperiksa pada lanskap 667 × 375.

Rekaman native tiga pilot mencakup kerja siang dan transisi pulang/dialog malam. Pemeriksaan tubuh terisolasi menunjukkan 1.024–1.596 piksel berubah tanpa alat/latar, dengan telapak tetap stabil. Generator cutout memakai artwork orisinal proyek; sumber dan batas arah belakang dicatat pada [panduan rig](../../tools/npc-rig/README.md) serta [provenance](../assets/provenance.md).

Bukti lokal berada di `artifacts/godot/{homestead,night-home,npc-body-rig,land,hybrid,backdrop}/`. Build dari sumber yang dirilis, hash paket staging, dan CI harus cocok. Hasil CI revisi sumber dapat diperiksa pada repository serta cabang laporan otomatis.

Tindak lanjut yang tetap terbuka: playtest manusia untuk kenyamanan dan ritme, pengukuran perangkat HP fisik, pemolesan arah animasi belakang/samping, perluasan rig ke warga lain, serta detail vegetasi/dermaga mengikuti moodboard. Keramba, tanaman tambahan, NPC anak-anak dan interior rumah warga lain belum termasuk implementasi putaran dasar ini. Jangan menyebut prototipe ini sebagai penyelesaian seluruh backlog visual atau simulasi desa penuh.
