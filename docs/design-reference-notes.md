# Catatan referensi permainan Jalasmara

## Sumber dan batas pengamatan

Referensi utama: [galeri Dave the Diver: In the Jungle di RPGFan](https://www.rpgfan.com/gallery/dave-the-diver-in-the-jungle-screenshots/), dilengkapi [screenshot komunitas Steam](https://steamcommunity.com/app/1868140/screenshots/). Koleksi lokal berisi 10 gambar Steam dan 6 gambar RPGFan setelah deduplikasi URL sebelum pembatasan jumlah. Seluruh contact sheet dan gambar bawah laut RPGFan telah diperiksa secara visual. Berkas referensi dan contact sheet hanya berada dalam `moodboard/`, yang diabaikan Git; tidak didistribusikan bersama game.

Dua video yang diberikan pengguna adalah [Dave the Diver](https://www.youtube.com/watch?v=0lPOcU2PY4Q) dan [In the Jungle](https://www.youtube.com/watch?v=D8n_a1qO9S8). Browser Chromium berhasil memverifikasi metadata kedua video: video utama *In the Jungle* berjudul “Gua Bermain 100% di Dave the Diver: In the Jungle DLC” (NodyPlay, durasi 2:00:04), dan video pendamping berjudul “Gua Bermain 100% Dave The Diver” (NodyPlay, durasi 1:13:48). Tangkapan layar awal gameplay berhasil diambil pada `moodboard/dave-the-diver/player-test.png`, namun lompatan seek terprogram (`seekTo`) memicu pembatasan pemutar YouTube (“Terjadi error. Muat ulang atau coba lagi nanti”). Seluruh analisis representatif, perbandingan komposisi frame lokal resolusi tinggi, kriteria playtest, dan batas verifikasi disusun lengkap pada `moodboard/dave-the-diver/video-analysis-report.md`. Berkas referensi dan rekaman frame tetap berada dalam `moodboard/` yang diabaikan Git dan dikecualikan dari build publik.

## Yang terlihat pada gambar

- **Hub dapat dijelajahi sebagai tempat.** Tokoh dan NPC berdiri di jalan tanah, pelataran, rumah, dan dermaga dalam satu komposisi dunia. Jalan mempunyai percabangan dan batas vegetasi; bangunan berfungsi sebagai tujuan yang dapat didatangi.
- **Tokoh kecil dibanding lingkungan.** Gambar bawah laut menempatkan penyelam sekitar 6–9% tinggi layar. Reruntuhan batu jauh lebih besar daripada tokoh; celah di antaranya membentuk ruang renang. Ukuran ini merupakan estimasi satu gambar, bukan ukuran engine sumber.
- **Ruang dibentuk beberapa lapisan.** Vegetasi besar menutupi tepi depan; jalur bermain memiliki kontras jelas; bukit, bangunan, dan reruntuhan jauh lebih redup. Air memisahkan siluet dengan kabut biru-hijau.
- **Pencahayaan memberi tujuan.** Permukaan dan kolom air terbuka lebih cerah, sedangkan batu atau dedaunan membentuk bidang gelap. Jalur renang tetap terbaca di ruang negatif di tengah.
- **Dialog tetap berhubungan dengan tempat.** Potret dan kotak dialog menimpa latar dunia; scene tidak berubah menjadi halaman daftar NPC.
- **HUD mengikuti aktivitas.** Satu screenshot kedai menampilkan sumber daya dan alat pengelolaan di tepi layar serta panel interaksi kontekstual. Beberapa gambar promosi tidak memiliki HUD, sehingga gambar itu tidak membuktikan bahwa permainan normal bebas HUD.
- **Presentasi memakai kedalaman visual.** Perspektif atap dan bangunan, bayangan, susunan batu, dan kabut memberi volume. Referensi ini tidak cukup untuk memastikan pipeline 2D/3D aslinya. Jalasmara dapat mencapai tujuannya melalui lapisan 2D orisinal.

## Penerapan pada Godot Jalasmara

**Prioritas pertama adalah gerak dan penemuan.** Scene pertama yang dapat dimainkan harus membolehkan Nala berjalan dari dermaga ke Beno dan Kedai Waras, turun ke air, berenang melewati batas kamera, menemukan objek, lalu pulang. Daftar soal tidak menjadi layar utama permainan.

- Hub Bandar Hujung memakai tampilan atas miring: `CharacterBody2D`, pergerakan delapan arah, collision bangunan/air, pengurutan Y untuk NPC dan properti, serta `Area2D` untuk interaksi jarak dekat. NPC mempunyai sprite, lokasi, nama, dan dialog di dunia.
- Penyelaman memakai tampilan samping: gerak bebas dua sumbu dengan akselerasi/deselerasi, arah pandang, animasi renang/diam, gelembung, dan collision batu. Kamera mengikuti Nala dengan batas peta. Mulai dengan skala tokoh sekitar 7% tinggi viewport lalu nilai melalui playtest; jangan memperbesar tokoh sampai menghilangkan rasa menjelajah.
- Peta bawah laut melampaui satu layar. Buat jalur utama, setidaknya satu jalan samping, satu lorong penghubung, dan tempat kembali yang dapat dikenali. Bentuknya dari collision/tilemap, bukan kumpulan tombol zona.
- Segaran memakai cahaya permukaan dan pecahan taman tenggelam; Wringin memakai rimbunan dengan celah aman; Jalatunda memakai lorong batu kapur dan jejak pipa; Tamansari mempunyai ruang arena lebar serta landmark gerbang. Perubahan cahaya, siluet, dan vegetasi menandai zona tanpa menutup pandangan.
- Jala adalah aksi dalam dunia: bidik atau hadapkan Nala, jangkauan terbatas, animasi/projectile, lalu respons objek. Interaksi di luar jangkauan harus gagal secara jelas.
- Sebelum kuis, tunjukkan fenomena: daun lamun menyerap cahaya, ikan mendekati sumber oksigen, air di dekat pipa berubah warna, atau endapan terkumpul pada penyaring. Pengetahuan dibaca sebagai petunjuk tindakan dalam ruang. Kuis singkat menjadi satu jenis resolusi penangkapan, bukan pengganti eksplorasi.
- Bedakan observasi bebas, pengambilan bahan, puzzle lingkungan, dan tangkapan kuis. Contoh puzzle: memindahkan penghalang agar cahaya mencapai tanaman, memilih aliran filter pada pipa, atau menimbang takaran alat Beno. Hasil server tetap menentukan hadiah dan progres.
- HUD penyelaman cukup oksigen, kedalaman, isi tas, dan alat; tujuan singkat dapat dibuka. Prompt muncul hanya dekat objek. Ensiklopedia menampung penjelasan panjang setelah objek dipelajari.
- Pertarungan Gajah Mina tetap bertempat di arena renang: telegraph semburan, ruang menghindar, pipa yang dapat dinetralkan, dan jendela menarik inti. Tujuannya memulihkan penjaga yang tercemar. Soal tidak menggantikan fase bergerak.

## Identitas Nusantara dan aset orisinal

Terapkan arah Jala Muara melalui rumah panggung pesisir, bambu, anyaman, konstruksi dermaga, perahu kerja, kain tenun sehari-hari, kedai jamu, dan bengkel rakitan. Gunakan motif baru yang terinspirasi teknik material; jangan menyalin simbol sakral atau menyatakan aksara rekaan sebagai aksara autentik. Rujuk `docs/brand/cultural-direction.md`.

Pelajaran komposisi, hierarki, skala, dan alur interaksi dapat diterapkan. Sprite, karakter, musik, logo, teks, layout level spesifik, atau hasil potongan screenshot sumber tidak boleh menjadi aset Jalasmara. Setiap aset baru tetap masuk daftar provenance.

## Pemeriksaan hasil

1. Pemain dapat mencapai dua lokasi hub dengan berjalan dan berbicara dengan NPC tanpa memilih daftar lokasi.
2. Nala dapat berenang setidaknya dua layar ke samping dan ke kedalaman, menyentuh batas collision, menemukan jalan samping, dan kembali ke dermaga.
3. Satu penemuan mengajarkan konsep melalui keadaan lingkungan sebelum meminta jawaban; pengamatan bebas tidak selalu memicu modal kuis.
4. Kamera mempertahankan orientasi pemain, HUD tidak menutupi celah navigasi, dan interaksi membutuhkan kedekatan fisik.
5. Aset referensi tidak masuk Git, folder build, atau output publik. Peninjauan video tetap dicatat sebagai belum berhasil sampai ada bukti timestamp yang dapat diperiksa.

## Tiga prioritas dari build Godot saat ditinjau

Perbandingan menggunakan `artifacts/godot/bandar-hujung.png` dan `artifacts/godot/swimming.png`; ini adalah screenshot pengembangan proyek, bukan media sumber.

1. Ringkas toolbar: navigasi aplikasi dan toolbar mengambil sekitar seperlima tinggi layar. Pindahkan oksigen/kedalaman ke sudut kiri dan tombol peta/jurnal/tas ke sudut kanan agar dunia menjadi fokus.
2. Perkaya dermaga dengan fungsi tempat: fasad berulang pada satu garis membutuhkan teras, atap berbeda, perahu kerja, keranjang, jala, dan foreground tiang/kanopi. Setiap tujuan NPC perlu landmark yang terbaca sebelum label.
3. Isi ruang renang dengan bentuk yang dapat dinavigasi: tambahkan karang collision di kiri/bawah untuk menciptakan celah utama dan rongga samping; reruntuhan redup berada di belakang. Sprite Nala saat berenang sudah memiliki skala yang sesuai; prioritaskan ruang dan kedalaman sebelum memperbesar tokoh.
