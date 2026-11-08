# Panduan Desain Antarmuka & HUD Jalasmara

> Acuan desain dari referensi. Tidak semua fitur di dokumen ini sudah aktif. Lihat [status pengembangan](development-status.md) dan [dunia hidup](world/living-world.md) untuk implementasi serta batasnya.
> Pembaruan implementasi: instrumen O2 bersegmen dengan angka besar, kedalaman/tas, kelompok aksi/jala dan strip utilitas sudah tersedia. Tata letak sentuh memisahkan instrumen dari D-pad. Indikator udara tipis dan tahan/lepas jala diuji pada renderer native; status pemeriksaan browser ada di dokumen pengembangan.

*(Pelajaran & Rekomendasi Tata Letak Berdasarkan Dave the Diver)*

**Dokumen Desain Antarmuka Pengguna (UI/HUD Architecture)**  
*Target Engine:* Godot 4.x (Web / WASM Single-Threaded) & Mobile Touch Compatible  
*Status Berkas:* Panduan Desain Resmi Jalasmara  
*Referensi Visual Privat:* `moodboard/dave-the-diver/images/hud-01` s.d. `hud-05` (diabaikan Git)

---

## 1. Evaluasi Komparatif & Masalah HUD Jalasmara Saat Ini

Tinjauan visual terhadap prototipe Jalasmara saat ini menunjukkan sindrom *"Web Dashboard Overlap"*:
1. **Toolbar Web Mendominasi Layar Atas (~20% Viewport):** Navigasi situs web, tombol modul, dan meteran statis membentang horizontal di atas layar seperti bilah aplikasi kantor. Hal ini memotong pandangan dunia piksel dan merusak imersi permainan.
2. **Kuis dan Evaluasi Berupa Formulir Teks Datar:** Pertanyaan sains perairan dan interaksi sosial ditampilkan dalam boks pilihan ganda kaku yang menyerupai lembar ujian daring sekolah.
3. **Ketiadaan Hubungan Diegetik (In-World Connection):** Indikator status (kesuburan tanah, pesanan kedai, kualitas air) tidak menempel pada objek di dunia, melainkan tersembunyi di balik menu atau label teks terpisah.

Sebaliknya, *Dave the Diver* menerapkan filosofi **"Edge Anchors & Diegetic Feedback"**:
* Area tengah layar 100% bebas rintangan visual untuk pergerakan karakter dan aksi permainan.
* Informasi diletakkan di 4 sudut layar (*Corner Anchors*) dengan bentuk geometris yang kompak.
* Status dinamis objek (tanah sawah, pesanan tamu, masakan koki) mengapung langsung di atas objek terkait di dunia (*In-World UI*).

---

## 2. Bedah 5 Referensi HUD Dave the Diver

Kelima tangkapan layar yang diunggah mendemonstrasikan bagaimana sistem antarmuka mendukung berbagai siklus gameplay:

### 2.1 Referensi 1: Tata Letak Pertanian & Sawah Otto (`hud-01-farm-field.jpg`)
* **Pojok Kanan Atas (Dial Waktu & Cuaca Melingkar):**
  * Bentuk bulat menyerupai kompas/roda gigi maritim dengan jarum dan irisan segmen warna (*Morning* disorot kuning, *Afternoon* biru muda).
  * Menampilkan hari dan tanggal kalender (`Thu 11. 17`) berdampingan dengan ikon cuaca cerah (Matahari).
  * Dilengkapi tombol pintas cepat `[Y] Time Skip` untuk pemain yang ingin memajukan waktu tanpa repot membuka menu opsi.
* **Pojok Kiri Atas (Saldo Finansial):**
  * Spanduk hitam miring dengan ikon koin emas tebal `$ 5,610`. Bersih, berjarak dari tepi, dan kontras tinggi.
* **Elemen Diegetik di Atas Dunia (*In-World Floating Gauges*):**
  * Di atas petak sawah padi: Papan meteran kayu mengapung bertuliskan `Nutrient` dengan bilah warna cokelat-emas menunjukkan kesuburan air/lumpur.
  * Di atas bedengan sayur: Papan meteran serupa dengan bilah hijau-cokelat menunjukkan kelembapan tanah.
  * *Pelajaran:* Pemain tidak perlu membuka buku inventaris atau mengklik tanah satu per satu untuk mengetahui petak mana yang perlu disiram atau diberi pupuk kompos.
* **Bawah Layar (Hotbar & Akses Perangkat):**
  * Kiri Bawah: Ikon ponsel pintar dengan lencana notifikasi merah `[N]`, tombol pintas `[≡ Phone]`.
  * Tengah Bawah: Kotak hotbar slot alat dengan indikator alat aktif (*Watering Can* disertai pengukur sisa air biru) dan navigasi bumper pengontrol `[LB]` / `[RB]`.
  * Tepi Kiri: Tanda kayu penunjuk arah `[< EXIT]` untuk kembali ke perahu atau desa.

---

### 2.2 Referensi 2: Pelayanan Malam Restoran Bancho Sushi (`hud-02-restaurant-evening.jpg`)
* **Rak Tiket Pesanan Gantung Kayu (Tengah Atas):**
  * Papan kayu berderet di bawah langit-langit kedai berisi kartu pesanan makanan dengan angka porsi (`34/40`, `7/10`).
  * Pemain dan koki dapat melihat kapasitas sajian yang tersisa dalam sekali lirikan mata tanpa menutupi meja bar.
* **Stasiun Memasak & Bilah Antrean Saji (Kanan Atas):**
  * Empat bilah progres horizontal berwarna-warni (toska, biru, merah muda, ungu) yang bergerak mengisi saat masakan disiapkan oleh koki dan asisten.
* **Bubble Dialog Kontekstual di Atas Kepala Pelanggan (*In-World Emotes*):**
  * Pelanggan yang sedang menunggu memunculkan balon pikiran berisi ikon masakan yang mereka pesan.
  * Pelanggan yang telah makan memunculkan balon reaksi hati merah muda (*"Lovely stuff!"*), pujian (*"Wow... this is good"*), atau emoji kepuasan tersenyum.
  * *Pelajaran:* Mengubah interaksi makan menjadi komunikasi visual non-verbal yang hidup, bukan daftar tabel teks.
* **Dock Navigasi Manajemen Bawah Layar:**
  * Bilah hitam elegan di dasar layar dengan pintasan angka keyboard:
    `[1] Menu` | `[2] Research` | `[3] Staff` | `[4] Ingredients` | `[5] Interior`
  * Pojok Kanan Bawah: Kartu status cabang `[6] Check Branch` menampilkan avatar manajer, perolehan emas cabang (`183`), dan tingkat kepuasan pelanggan (`0`).

---

### 2.3 Referensi 3: Modal Pengaturan Menu Harian / Today's Menu (`hud-03-menu-management.jpg`)
* **Struktur Tiga Kolom Seimbang (Non-blocking Modal):**
  * *Latar Belakang:* Interior restoran tetap terlihat di belakang modal dalam kondisi sedikit redup (*dimming overlay* 60%), menjaga kontinuitas ruang.
  * *Kolom Kiri (Slot Menu Aktif):* Daftar slot menu yang akan disajikan malam ini, dengan peringatan aturan main: *"Remaining menu will be discarded as the restaurant close"*. Tombol `+ Add Menu` yang intuitif.
  * *Kolom Tengah (Katalog Resep):* Kisi-kisi kartu resep dengan fitur sortir harga `[Z] Price v`, indikator level resep (`Lv.1`, `Lv.2`), panah hijau peningkatan, lencana `NEW`, dan stok bahan yang tersedia (`10`, `2`, `12`).
  * *Kolom Kanan (Detail Masakan):* Kartu pratinjau hidangan terpilih (*Giant Trevally Sushi*), statistik utama (Harga emas `$ 30`, Tingkat Rasa/Taste `25`, Porsi `1`), deskripsi rasa kuliner, dan rincian kebutuhan bahan baku (`Giant Trevally Meat 10/1`) disertai informasi kedalaman penangkapan (`50-130m`).
* **Navigasi Tombol Bawah:**
  * Tombol konfirmasi tegas: `[C] Close`, `[OK]` (aksen merah muda), dan `[Ctrl] Enhance` (aksen kuning cerah berpanah ganda).

---

### 2.4 Referensi 4: Modal Riset Resep Baru / Recipe Research (`hud-04-recipe-research.jpg`)
* **Integrasi Karakter & Suasana Dapur:**
  * Di sisi kanan atas modal, terlihat animasi koki Bancho bersedekap di samping panci mendidih dan ikan tangkapan besar di meja dapur. Karakter koki menjadi bagian dari antarmuka, memperkuat narasi kuliner.
* **Struktur Dua Panel Riset:**
  * Panel Kiri: Resep-resep baru yang siap dipelajari berlabel `NEW`.
  * Panel Kanan: Kartu hidangan terpilih (*Boiled Yellowback Fusilier*), estimasi harga jual (`$ 50`), skor rasa (`75`), porsi (`5`), dan deskripsi cita rasa tradisional.
* **Mata Uang Khusus Riset (*Artisan's Flame*):**
  * Persyaratan riset tidak hanya menggunakan koin emas biasa, melainkan *"Artisan's Flame"* (ikon kobaran api merah-oranye, `17 / 3`).
  * *Pelajaran untuk Jalasmara:* Membedakan mata uang ekonomi (Koin/Rupiah) dengan poin ketekunan tradisi (misal: *Kepekaan Jamu* atau *Restu Bahari* untuk membuka ramuan obat baru Mak Waras).

---

### 2.5 Referensi 5: Layanan Malam Cuaca Badai / Stormy Night (`hud-05-restaurant-storm-night.jpg`)
* **Integrasi Atmosfer Cuaca Ekstrem ke dalam UI:**
  * Garis-garis hujan deras dan kilatan petir tampak jelas menembus kaca belakang restoran, sementara lentera oranye gantung di dalam ruangan berayun lembut.
* **Pelacak Misi Kompak (Pojok Kiri Atas):**
  * Kotak quest transparan gelap dengan hierarki tipografi rapi:
    * `[!] Explore the Glacial Area` (Misi Utama)
    * `[<>] Inspirational Chirashi Sushi` (Tugas Khusus Karakter)
    * `[<>] Stormy Night 2` (Misi Cuaca: Menemukan pusaran air badai)
  * Menampilkan kotak centang tugas tanpa memotong ruang gerak pramusaji.
* **Umpan Balik Sosial Real-time (Cooksta App Toast):**
  * Muncul gelembung notifikasi media sosial di kiri atas: *"I think I'll be coming here often"* dengan jumlah suka dan komentar, serta pengingat syarat kenaikan peringkat Cooksta.
* **Minigame Cepat & Kontrol Sentuh/Aksi:**
  * Bubble pesanan bir memicu minigame menuangkan minuman dengan takaran busa pas.
  * Di pojok kanan bawah, terdapat tombol aksi besar ramah layar sentuh/gamepad untuk aksi saji cepat (`Hand Pointer`) dan lari cepat (`Dash`).

---

## 3. Rencana Penerapan HUD untuk Game Jalasmara (Godot 4)

Berdasarkan analisis di atas, berikut transformasi menyeluruh yang direkomendasikan untuk arsitektur UI/HUD Jalasmara:

```
TATA LETAK HUD USULAN JALASMARA (480x270 Viewport / Scaled 16:9):

┌────────────────────────────────────────────────────────────────────────┐
│ [Rp 12.500]       [Tugas: Cek Pipa Limbah]           [Sabtu 14. 08 ☼]  │
│ [Reputasi: ★★★☆☆]                                      ( Dial Jam )    │
│                                                                        │
│                                                                        │
│                                                                        │
│                      Dunia Permainan 100% Bersih                       │
│                   (Nala, Dermaga, Karang, Ikan)                        │
│                                                                        │
│                                                                        │
│ [< Keluar]                                                             │
│                                                                        │
│ [📖 Buku Jurnal]       [ 1. Jala | 2. Serok | 3. Sensor ]     [⚡ Dash]  │
│ [📱 Ponsel Beno]               ( Hotbar Bawah )               [🎯 Aksi] │
└────────────────────────────────────────────────────────────────────────┘
```

### 3.1 Peniadaan Toolbar Web Atas & Penggantian dengan Anchor Pojok
1. **Pojok Kanan Atas: Dial Surya & Pasang-Surut Jalasmara**
   * Lingkaran roda kayu tradisional yang menunjukkan waktu 24 jam (Fajar, Siang, Senja, Malam) dan status pasang-surut air laut pesisir.
   * Ikon cuaca dinamis (Matahari, Berawan, Hujan Rintik, Badai Muson).
2. **Pojok Kiri Atas: Kas Nelayan & Reputasi Pesisir**
   * Spanduk kayu ukir ringkas menampilkan kas koin hasil penjualan ikan/jamu dan reputasi Nala di kalangan warga Bandar Hujung.
3. **Pojok Kiri Bawah: Akses Jurnal & Komunikasi Beno**
   * Menggantikan tombol menu web dengan ikon diegetik: *Buku Jurnal Nala* (inventaris, peta laut, catatan ekologi) dan *Radio Saku Beno* (pesan tugas).
4. **Bawah Tengah: Hotbar Alat Lapangan**
   * Menampilkan slot alat aktif: Jala Lempar Tradisional, Jaring Serok Lamun, atau Sensor Kekeruhan Air, dengan indikator daya tahan/kapasitas.

### 3.2 Transformasi Kedai Waras: Dari Soal Teks ke Layanan Interaktif
1. **Papan Gantungan Resep Jamu Bambu:**
   * Di atas meja racik Mak Waras, gantung bilah bambu pesanan ramuan nelayan (misal: *Wedang Jahe Lamun*, *Sari Temu Lawak*, *Ekstrak Pegagan Karang*).
2. **Balon Pikiran Tamu (*Customer Thought Bubbles*):**
   * Nelayan yang lelah kedinginan memunculkan ikon ramuan jahe hangat di atas kepalanya.
   * Saat Nala menyajikan ramuan yang tepat, muncul ekspresi senyum lega dan pujian singkat khas pesisir Nusantara (*"Seger tenan!", "Badan langsung enteng"*).
3. **Modal Riset Ramuan Tradisional Mak Waras:**
   * Tirulah tata letak modal Bancho Sushi: Mak Waras mengaduk kuali tanah liat di sisi kanan layar, sementara di sisi kiri Nala memilih kombinasi ekstrak daun lamun dan rempah darat untuk dipelajari.

### 3.3 Transformasi Kebun Rakit & Petak Pembibitan Lamun
* Terapkan papan meteran hara melayang (*floating gauges*) di atas petak rakit pembibitan:
  * **Kadar Garam Air (Salinitas):** Bilah warna biru-putih.
  * **Kesuburan Pupuk Organik:** Bilah warna hijau-cokelat.
* Pemain dapat melihat kondisi seluruh bibit lamun hanya dengan berjalan melintas, tanpa membuka satu pun jendela menu pop-up.

---

## 4. Spesifikasi Teknis Node Godot 4 untuk UI/HUD

Agar performa di peramban (Web/WASM) tetap lancar dan tidak terpengaruh shader pencahayaan dunia:

1. **Struktur Tree Scene UI:**
   ```
   UI_Layer (CanvasLayer, Layer = 100)
   ├── CornerTopLeft (Control, Anchor: Top-Left)
   │   ├── MoneyLabel (HBoxContainer)
   │   └── QuestTracker (VBoxContainer)
   ├── CornerTopRight (Control, Anchor: Top-Right)
   │   ├── ClockDial (TextureProgressBar / Custom Control)
   │   └── WeatherIcon (TextureRect)
   ├── InWorldUI_Layer (Node2D, Y-Sort Disabled)
   │   └── FloatingBars (Papan hara sawah & bubble tamu, update via unproject_position)
   └── BottomHotbar (Control, Anchor: Bottom-Center)
       └── ToolSlots (HBoxContainer)
   ```
2. **Isolasi Pencahayaan (Light Mask):**
   * Pastikan `UI_Layer` memiliki properti `CanvasItem > Visibility > Light Mask = 2`.
   * Sumber cahaya dunia (`PointLight2D` senter Nala, lentera minyak, dan `CanvasModulate` malam) hanya menyinari `Item Cull Mask = 1`.
   * Hal ini mencegah teks HUD menjadi gelap saat malam hari atau overbright saat kilat petir menyambar.
3. **Responsivitas Rasio Layar (*Responsive Anchors*):**
   * Gunakan Preset Anchor Godot (`Top Left`, `Top Right`, `Bottom Center`) dengan margin dinamis agar UI otomatis menyesuaikan tata letak pada layar HP (rasio 20:9), tablet (4:3), maupun desktop (16:9) tanpa terpotong.

