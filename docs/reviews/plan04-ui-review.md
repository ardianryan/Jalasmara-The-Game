# Tinjauan UI Plan 04

Tanggal: 9 November 2026. Ruang lingkup: HUD Godot, percakapan, SmaraPedia, tas, atlas, dan menu browser. Ini laporan bukti UI; keputusan rilis, performa perangkat, serta penerimaan keseluruhan tetap dilaporkan terpisah oleh pengelola integrasi.

## Revisi artwork setelah penilaian pengguna

Pengguna menolak tampilan HUD pada baseline `3d648e8`, walaupun pemeriksaan fungsi dan ukuran di bawah sudah lulus. Bukti tersebut tetap berlaku untuk perilaku yang diuji; **bukan persetujuan mutu visual**. Referensi baru menekankan kit HUD pixel art yang mempunyai bingkai, lencana, slot, dan ikon nyata, seperti karakter material pada contoh IndigoLay yang diberikan pengguna. Referensi itu menjadi arah bentuk dan keterbacaan, bukan aset yang disalin.

Pengerjaan berikutnya memakai artwork asli `hud-bahari-v1`: kayu gelap, kuningan, kertas, serta ikon bahari. `HudSkin.gd` menyediakan bingkai tekstur sembilan bagian untuk HUD dan menu Godot; buku, tas, percakapan, dan atlas memakai sumber yang sama. Ukuran teks, area sentuh, sumber data, pause, dan akses keyboard harus tetap terjaga. Penerimaan visual baru menunggu pemeriksaan render desktop/lanskap/portrait dari aset yang sudah diimpor. Rasio warna datar pada laporan lama belum membuktikan kontras di seluruh tekstur baru.

### Pemeriksaan awal kit Bahari

Integrasi awal tersedia pada `artifacts/godot/hud-bahari/menus/`: 15 capture komponen native pada 960×540, 667×375, dan 390×844. Bingkai sembilan bagian, tombol empat state, ikon berwarna, slot inventori, portrait, bar oksigen, cincin joystick, dan rim minimap memakai PNG asli. Minimap tetap GeoMap yang sama, dipotong melingkar; dekorasinya tidak mengganti koordinat dunia. Uji HUD oksigen, buku/tas, serta analog/percakapan lulus pada tahap ini. Capture pertama menemukan pola kertas berulang, teks terang pada panel percakapan krem, dan label tab portrait yang terjepit; ketiganya sudah diperbaiki. Capture ulang setelah penyesuaian kontras hover dan padding percakapan selesai; tiga uji komponen yang sama tetap lulus tanpa kesalahan engine. Ini bukti komponen, bukan pengujian seluruh alur permainan lewat browser. Belum ada bukti baru dari perangkat fisik atau penerimaan visual pengguna.

### Pemadatan HUD setelah umpan balik ukuran

Pengguna menilai HUD baru masih terlalu besar, terutama malam hari. Pada tindak lanjut, tujuan tidak ditampilkan sebagai banner tetap; tombol gulungan membuka teks tujuan lengkap. Identitas darat memakai dua baris area dan resource. Pada fixture fisik 667×375, tinggi panel itu turun dari 108,4 menjadi 66,7 px (sekitar 38,5%). Alas jam/cuaca menyesuaikan teks, dari 251,5 menjadi 136,2 px pada contoh “20:35 Berawan”. Hit area utilitas tetap minimal 48 px meskipun artwork diberi inset dan bingkai luar tambahan disembunyikan. Joystick menjadi sekitar 100 px dan minimap 78 px. Teks utama tetap minimal 16 px fisik.

Bukti sebelum/sesudah tersedia di `artifacts/godot/hud-bahari/compact/`: kontrol Godot asli di atas capture dunia malam milik Jalasmara, bukan simulasi layanan kedai melalui API. Capture `after-667x375-night-modal.png` membuktikan identitas, resource, cuaca, utilitas, minimap, dan kontrol dunia tersembunyi ketika modal terbuka. Pengujian geometri mempertahankan ambang/peringatan oksigen dan menambah batas tinggi panel, area tengah pemain yang bebas pada darat, misi lengkap melalui tombol, modal siang/malam, serta resource bingkai yang tidak dibuat ulang setiap polling. Pengujian GUI malam menyeluruh tetap menjadi verifikasi integrasi berikutnya.

## Bukti dan batas pemeriksaan

- Capture komponen native tersedia di `artifacts/godot/plan04-ui/`: ukuran fisik 960×540, 667×375, dan 390×844. Capture menggunakan kontrol Godot nyata di atas tangkapan dunia milik Jalasmara sebagai latar fixture. Ini bukan rekaman sesi dunia yang sedang berjalan dan bukan pengukuran FPS.
- Capture atlas mencakup daratan dan penampang laut pada ketiga ukuran. Posisi, zoom, pan, transformasi koordinat, dan alasan jalur terkunci diuji terpisah.
- `scripts/play-host-browser.mjs` menguji host React dengan autentikasi dan iframe fixture: fullscreen DOM nyata, penolakan/ketiadaan API, validasi origin serta sumber pesan, fokus menu, perubahan orientasi, pilihan kualitas, penyimpanan preferensi, dan penyimpanan browser yang diblokir. Fixture ini tidak membuktikan hasil renderer Godot atau kualitas perangkat fisik.
- Capture awal pukul 10.18 telah digantikan oleh capture setelah perbaikan fisik HUD/modal. Set terbaru menampilkan SmaraPedia dan alas gelap label aksi/peringatan. Pemeriksaan integrasi berikutnya memindahkan O2 portrait ke atas joystick agar penyelam dekat permukaan tidak tertutup; bukti adegan laut aktif berada di `artifacts/godot/touch-dive-portrait.png`.
- Validasi lokal setelah perbaikan: **enam pengujian headless UI lulus tanpa error** (`hud-oxygen`, `quiz-layout`, `homestead-ui`, `legacy-forest-ui`, `analog-dialogue`, dan `world-atlas-layout`), serta 15 capture komponen dan 6 capture modal lama. Root menguji ulang ukuran HUD, kapasitas tas tanpa elipsis, nama pembicara dan tujuh pemeriksaan sentuh sesudah pemindahan O2 portrait. Angka seluruh proyek dan status deployment tidak dinyatakan oleh laporan ini.

## Temuan yang ditindaklanjuti

| Temuan awal | Bukti | Perbaikan source yang diminta |
| --- | --- | --- |
| Utilitas dan tombol `+` tujuan terlalu kecil pada portrait. | `GameHud.gd` sebelumnya memakai utilitas 72 dan tombol tujuan 48 unit logis. Pada 390 px dengan viewport logis 667, targetnya sekitar 42 px dan 28 px fisik. | Ukuran mengikuti rasio viewport terhadap jendela; kontrol terlihat minimal 48 px fisik. Tombol tujuan tetap membuka modal, bukan memperluas banner di dunia. |
| Resource, cuaca, peringatan, dan label aksi turun di bawah 16 px. | Ukuran 18/13/24 logis sebelumnya menjadi sekitar 10,5/7,6/14 px pada portrait. | Metrik teks fisik bersama dan penyederhanaan informasi saat penyelaman lanskap pendek. Detail tujuan tetap tersedia lewat tombolnya. |
| Label aksi dan peringatan bergantung pada warna dunia di belakangnya. | Pada pemeriksaan capture sebelum alas ditambahkan, sampel tanah `(500,276)` adalah `#b28f60`: teks krem `#f1e1bc` hanya 2,32:1; emas `#e6bd76` hanya 1,70:1. Nilai ini catatan pengukuran historis; file capture tersebut telah diperbarui, sehingga koordinat yang sama sekarang berisi alas UI. | Alas gelap untuk aksi, cuaca, dan peringatan. Warna teks tidak perlu berubah mengikuti terrain. Sampel tersebut membuktikan masalah capture lama, bukan kontras source setelah alas ditambahkan. |
| Menu DOM menimpa identitas HUD portrait. | Menu berada di tengah atas, 88×48 px fisik; identitas sebelumnya mulai dekat tepi atas. | Ruang atas 60 px fisik pada portrait. Lanskap mempertahankan celah tengah antara identitas dan utilitas; pengujian memeriksa perpotongan bounds. |
| Modal lama masih memakai ukuran dan font tetap. | Quiz dua kolom dengan minimum 285 per jawaban; dialog pilihan karakter hutan 600×285 dan tombol 36; panel rumah body 24 tanpa penyesuaian portrait. | `UiMetrics.gd` menyediakan font minimal 16 px fisik dan target aksi 56 px. Quiz portrait satu kolom; dialog lama hutan dan panel rumah menggulir isi tanpa menambah ukuran panel melewati layar. |
| Percakapan lanskap sempat menaruh tombol Lanjut di bawah viewport. | Capture native awal menunjukkan portrait dan tombol terpotong; pengukuran memperlihatkan panel tumbuh setelah perhitungan minimum konten. | Scroll minimum nol, anggaran tinggi, dan penghitungan ulang setelah layout konten. Capture sesudah perbaikan memperlihatkan portrait, teks, dan Lanjut utuh. |
| Detail buku sempit sempat hanya memperlihatkan tombol kembali dan ikon. | Capture 667×375 awal; teks catatan berada di bawah lipatan. | Tombol Daftar dipindah ke header; ikon besar hanya pada dua halaman desktop. Detail teks langsung terlihat pada tampilan ringkas. |
| Warna teks tombol saat fokus/hover diwarisi sebagai krem di atas kertas. | Tombol Tutup dan tab konsep kehilangan kontras. | Warna normal/hover/pressed/focus ditetapkan eksplisit pada buku, tas, atlas, dan dialog terkait. |

## Kontras warna

Dihitung dengan `antislop-human/contrast-check.py`, bukan penilaian mata. Rasio ini berlaku untuk pasangan warna datar; lapisan transparan di dunia tetap perlu diperiksa pada hasil render.

| Pasangan | Rasio | Penilaian |
| --- | ---: | --- |
| Teks tinta `#302d2a` / kertas `#f1e1bc` | 10,58:1 | Lulus teks normal 4,5:1. |
| Teks percakapan `#f4ebd9` / kayu `#362419` | 12,46:1 | Lulus teks normal. |
| Sorotan konsep `#8ee0ce` / kayu `#362419` | 9,63:1 | Lulus teks normal. |
| Kuningan `#c89240` / kayu `#362419` | 5,37:1 | Lulus batas komponen 3:1. |
| Border `#8a633d` / kertas `#f1e1bc` | 4,13:1 | Lulus batas komponen; tidak dipakai sebagai warna teks normal kecil. |
| Fokus `#80501f` / kertas `#f1e1bc` | 5,26:1 | Lulus batas fokus 3:1. |
| Krem `#f1e1bc` / batas komposit alas gelap `#423127` | 9,55:1 | Lulus teks normal pada perhitungan komposit 94% alas di atas putih; tetap periksa render akhir. |
| Emas `#e6bd76` / batas komposit alas gelap `#423127` | 7,00:1 | Lulus teks normal pada batas komposit yang sama. |

## Verifikasi ukuran dan input

- `hud-oxygen.gd`: 667×375,844×390,390×844; kontrol terlihat minimal 48 px fisik, teks resource/cuaca/aksi/peringatan minimal 16 px beserta tinggi baris, label suara utuh, alas label aktif, ruang DOM Menu tidak bersinggungan dengan identitas/utilitas, serta peringatan tidak menimpa joystick. Ambang 35%/15%, feedback kerusakan, perubahan kapasitas, dan reduced motion tetap diuji.
- `quiz-layout.gd`: UI Main asli, dua kolom lanskap/satu kolom portrait, pilihan pendek maupun panjang minimal 56 px fisik, body minimal 16 px, Nunito, shortcut 1–4, Tab/Enter, scroll mengikuti fokus, dan pemain/HUD berhenti selama modal. Tidak ada panggilan mutasi API.
- `homestead-ui.gd`: tiga ukuran yang sama, teks 16 px, aksi 56 px, fokus halaman baru, Tab/Enter, scroll ke tindakan terbawah, penjagaan permintaan sibuk, pemulihan operasi tertunda, dan tombol kembali pada detail tujuan.
- `legacy-forest-ui.gd`: empat penampilan dan tombol kembali pada tiga ukuran; target 56 px, teks 16 px, warna hover, scroll fokus, serta penutupan tanpa permintaan API.
- `world-atlas-layout.gd`: bounds container, target 48 px/teks 16 px, informasi alasan terkunci yang membungkus, transformasi world–screen, pan/zoom setelah layout, posisi yang tidak salah muncul di bagian lain, keyboard POI/pan/zoom, sinyal tutup, dan tidak mengubah data dunia.
- Capture `*-quiz.png`, `*-home-chest.png`, dan `*-forest-appearance.png` menunjukkan modal aktual pada 667×375 dan 390×844. Latar fixture tidak menyatakan mutu akhir peta desa/hutan.

## Catatan yang tetap berlaku

- Teks percakapan dan informasi utama memakai Nunito; Ark Pixel tetap untuk judul serta identitas yang sesuai. Ukuran logis 24 saja tidak membuktikan 16 px fisik: pada 390 px/667 logis diperlukan sedikitnya 28 logis.
- SmaraPedia memakai pengamatan, inventori, dan misi tersimpan. Konsep yang sudah digunakan dalam racikan tetap dikenal lewat misi selesai. Warga yang tersedia menurut siklus cerita tidak boleh disebut sebagai bukti bahwa pemain sudah berbicara dengan semuanya. Ini belum merupakan katalog taksonomi seluruh spesies atau riwayat kualitas terbaik sepanjang akun.
- Portrait percakapan memakai crop aset karakter yang tersedia; belum seluruhnya berupa ilustrasi kepala ekspresif terpisah. Ekspresi dan perubahan nama baru memerlukan capture setelah source tersebut berubah.
- Anotasi kecil yang digambar langsung oleh GeoMap masih memakai font 10 logis. Panel informasi lokasi menyediakan bacaan lebih besar, tetapi label overview bukan teks 16 px fisik. Root menambahkan fokus peta, pan dengan panah, zoom `+`/`-`, pemilihan POI nyata dengan PageUp/PageDown, serta Home untuk reset. Pengujian atlas terbaru lulus setelah perubahan tersebut; jangan menganggap anotasi overview kecil sebagai pengganti panel informasi lokasi.
- Screenshot statis tidak membuktikan pointer capture multitouch, kenyamanan joystick, pembatalan sentuhan, atau pergantian orientasi pada HP nyata. Pengujian S23/Safari iOS fisik tetap terpisah.
- Fokus DOM menu sudah diuji. Dukungan pembaca layar untuk isi canvas Godot belum dibuktikan; jangan menyamakan label DOM host dengan aksesibilitas seluruh permainan.
- Tidak ada klaim bahwa kualitas Ringan mencapai 30 FPS atau bahwa Seimbang mencapai 60 FPS dari tinjauan UI ini. Pilihan kualitas dan paket pesannya diuji; pengukuran frametime, thermal throttling, serta interaksi renderer tetap memerlukan lintasan dan perangkat yang sesuai.
