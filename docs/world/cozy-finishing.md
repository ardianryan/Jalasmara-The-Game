# Finishing pixel yang nyaman

Arah visual mengikuti contoh pengguna: material matte, warna bumi yang sedikit redup, cahaya lokal hangat, serta bayangan berwarna yang mempertahankan detail saat malam. Nuansa rumah dan hutan berasal dari permukiman pesisir Nusantara: rumah panggung, rumbia, bambu, kayu lapuk, tanaman tropis dan kebun warga. Bentuk rumah Eropa, pohon musim gugur, atau susunan level dari contoh tidak disalin.

Palet acuan: hijau sage `#657361`, kayu `#887055`, atap kusam `#344a4b`, lentera `#efc478`, dan ambient biru abu `#52656b`. Angka ini merupakan arah artistik; hasil pencahayaan tetap diperiksa melalui render siang, senja, malam, dan hujan.

- Terang lampu rumah membentuk area di tanah dan mengenai objek di sekitarnya. Warna jendela tidak menggantikan sumber cahaya ruang.
- Malam menurunkan kontras lingkungan tanpa mengubah seluruh layar menjadi hitam. Jalur, tepian, tangga, dan karakter tetap terbaca.
- Angin menggerakkan tajuk dengan pangkal tetap tertanam; bayangan kontak mengikat benda pada lantai.
- Air mempunyai gelombang, busa tepian, riak hujan, serta interaksi cahaya. Air tanpa dek atau jembatan bukan lantai berjalan.
- Detail kecil dikelompokkan di dekat rumah, kebun, tepian dan tempat kerja; jalur tetap lega. Kepadatan tidak dihasilkan dari pengulangan satu objek secara seragam.
- Komponen visual, pijakan dan footprint penghalang memakai manifest yang sama. Finishing tidak dapat dipakai untuk menutupi kesalahan navigasi.

Contoh pengguna dan moodboard komersial tetap menjadi referensi privat yang diabaikan Git. Material pustaka yang dipakai harus mempunyai provenance tersendiri; material orisinal pelengkap tercatat pada [atlas modular](../assets/modular-land-art.md).

## Kamera daratan

Daratan memakai kamera ortografis miring 35° dari bidang tanah, bukan kamera tegak dari atas. Bangunan memiliki atap, muka, dan sisi; lantai, tebing, serta tangga berupa geometri 3D. Karakter tetap sprite piksel yang berpijak pada posisi tanah yang sama dengan pemeriksaan tabrakan. Proyeksi diuji pada empat tingkat elevasi agar perubahan sudut kamera tidak menggeser kaki dari lantai. Adegan bawah laut tetap memakai tampak samping untuk berenang.

## Ritme waktu yang dipilih

Pengguna memilih satu hari penuh selama 36 menit nyata: satu jam game adalah 90 detik, dan setengah siklus berlangsung 18 menit. Kalender akun berlanjut melewati tengah malam dan diselesaikan server dari waktu aktif, berhenti saat dialog/kuis atau koneksi terputus, sementara animasi cuaca tetap berjalan. Tidur menempatkan kalender pada pukul 06.00 berikutnya; membuka kedai dapat memajukan waktu ke awal pelayanan. Kalender mengatur pertumbuhan kebun, sedangkan kenaikan siklus cerita memerlukan hasil kedai yang sah dan tidur. Pengujian mempercepat simulasi hingga satu siklus penuh tanpa menunggu 36 menit nyata.

## Griya Sasmita pada rilis Plan 03

Rumah panggung Nala menggunakan komponen 3D yang sama dengan permukiman, jembatan berpagar, dua petak rakit, dan interior cutaway. Kain tenun hijau kebiruan, bantal, rak buku/lontar, pot herba, dan keranjang ditempatkan pada footprint perabot yang sudah terhalang. Dua lampu menghangatkan lantai; ambient malam interior dinaikkan tanpa mencerahkan desa atau HUD. Panel rumah menggunakan perkamen, tombol kayu dengan tepi kuningan, Nunito untuk teks panjang, serta fokus keyboard yang kontras.

Render siang/malam dan rekaman tiga pilot NPC berada di artefak lokal; penilaian kenyamanan akhir dan performa HP fisik tetap membutuhkan playtest manusia.
