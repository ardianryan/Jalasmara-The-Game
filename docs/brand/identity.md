# Jalasmara · Jala Muara

**Nama:** Jalasmara. **Judul pendamping:** Menjaring Ingatan.

Jalasmara mengajak pemain menjelajah, mengamati, dan memulihkan hubungan antara pengetahuan, manusia, serta lingkungan. Identitasnya hangat, ingin tahu, membumi, dan memiliki rasa petualangan pesisir Nusantara.

## Logo

Arah Jala Muara dipilih oleh pemilik proyek setelah dua putaran konsep. Lengkung jala menerima kembali ingatan; garis sulur merupakan gambar baru yang tidak mengaku sebagai motif tradisional tertentu.

Gunakan `assets/brand/horizontal.svg` pada bidang terang, `horizontal-white.svg` pada bidang gelap, `stacked.svg` untuk bidang vertikal, dan `symbol.svg` untuk avatar. Versi kecil tersedia pada `symbol-small.svg`, favicon, dan ikon aplikasi. Master SVG wordmark menggunakan outline huruf, sehingga tidak bergantung pada font yang terpasang.

Ruang bebas minimal adalah seperenam tinggi simbol. Simbol normal minimal 24 piksel; gunakan versi kecil pada 16–23 piksel. Jangan memiringkan, merenggangkan, memberi bayangan, atau memadukannya dengan lambang keagamaan/adat. Logo boleh satu warna. Simbol harus tetap terbaca sebelum warna ditambahkan.

## Warna

| Peran | Nama | HEX |
|---|---|---|
| Latar gelap | Palung | `#082E35` |
| Teks / simbol | Tinta Bandar | `#173F43` |
| Aksi utama | Laut | `#0B555B` |
| Biota / pemulihan | Lamun | `#8DB9A2` |
| Sorotan / bahan alami | Pasir | `#EDD3A3` |
| Latar kerja | Kertas | `#F4F6F2` |
| Kesalahan | Peringatan | `#963C30` |

Pasir dan Lamun menjadi aksen, bukan warna teks kecil pada putih. Kontrol dan informasi tetap memakai kontras yang memadai. Warna racun adalah isyarat keadaan di dalam game dan bukan warna utama merek.

## Tipografi

Lora Medium digunakan pada nama dan judul cerita: bentuk serif yang lembut menyerupai ritme tulisan cetak pada papan kedai. Nunito Sans digunakan untuk formulir dan panel pengelola karena bentuknya terbuka dan mudah dibaca. Keduanya disajikan secara lokal melalui paket Fontsource; lisensi SIL OFL disertakan pada `docs/assets/LICENSE-lora.txt` dan `docs/assets/LICENSE-nunito-sans.txt`. Jangan mengganti huruf Latin dengan aksara semu untuk memberi kesan daerah.

## Suara

Tulisan antarmuka ringkas dan langsung: “Berangkat menyelam”, “Tinjau perubahan”, “Kembali ke dermaga”. Narasi memakai detail tempat dan tindakan, bukan janji pemasaran. Mbah Wira tegas dan hemat kata, Beno antusias terhadap rakitan, dan Nala santai dengan humor situasional. Materi pembelajaran tidak mengejek jawaban yang salah.

## Berkas kit

Master simbol dan lockup, versi hitam/putih, ikon 16–512 piksel, favicon ICO/SVG, cover repositori, token warna JSON, serta pedoman ini berada di `assets/brand`. Konsep terdahulu disimpan sebagai riwayat proses dan bukan pilihan untuk penggunaan produksi.

## Catatan produksi

Simbol menggunakan stroke SVG dengan lebar tetap dalam koordinat viewBox. Jangan menerapkan `vector-effect: non-scaling-stroke`; ekspor raster mengubah skalanya secara proporsional. Untuk produksi potong/vinil, ubah stroke menjadi outline di aplikasi vektor sebelum dikirim ke vendor. Kerumitan outline wordmark berasal dari bentuk huruf Lora, bukan detail tambahan pada simbol.

Board presentasi mandiri tersedia pada `assets/brand/presentation.html`; panduan visual satu halaman tersedia pada `assets/brand/guide.html`. Keduanya dapat dibuka langsung di browser.
