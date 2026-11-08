# Panduan Teknis & Desain: Lingkungan Dinamis Jalasmara
*(Dynamic Weather, Dynamic Time, Dynamic Water, & Water Effects untuk Aset AI)*

**Dokumen Arsitektur & Panduan Desain Teknis**  
*Target Engine:* Godot 4.x (Web / WASM Single-Threaded)  
*Konteks Aset:* 100% Grafis & Piksel Dibuat oleh AI  
*Prinsip Utama:* **Aset AI sebagai kanvas visual statis, Godot Engine sebagai motor dinamika prosedural.**

> **Status:** dokumen ini tetap merupakan arah desain, bukan klaim semua fitur aktif. Build lokal kini memakai komponen darat modular 3D, jam kosmetik 24 jam visual per 36 menit nyata, air/cuaca/cahaya dinamis serta SFX eksplorasi yang sudah diintegrasikan. Dampak cuaca otoritatif pada ekonomi dan simulasi air penuh belum diklaim tersedia. Pengguna telah mengizinkan pemakaian aset pustaka yang ada; sumber serta lisensinya tetap dicatat, sehingga uraian “100% aset AI” di dalam panduan adalah konteks awal, bukan batas produksi saat ini. Lihat [status implementasi](world/environment.md); rebuild sedang difinishing dan belum dinyatakan lulus deployment final.

---

## 1. Tantangan Mendasar Game Pixel Art Berbasis Aset AI

Ketika 100% aset visual dikerjakan oleh generator AI, muncul tiga masalah khas yang dapat merusak kualitas game jika tidak diatasi oleh engine:

1. **Jittering Animasi AI:** AI tidak mampu menjaga kesinambungan antar-frame untuk fluida (air, hujan, ombak). Animasi frame-by-frame dari AI akan terlihat goyang dan patah-patah.
   * *Solusi:* Jangan generate animasi cairan dari AI. Gunakan shader gelombang prosedural dan partikel Godot.
2. **Masalah Kerapatan Piksel Campuran (*Pixel Mixel*):** AI sering menghasilkan gambar dengan ukuran piksel berbeda-beda (ada yang beresolusi tajam, ada yang pikselnya besar).
   * *Solusi:* Kunci resolusi rendering internal Godot pada resolusi rendah (misal $480 \times 270$ atau $960 \times 540$) dengan `stretch mode: viewport` dan `aspect: keep`, untuk menjaga raster akhir tetap stabil. Ini tidak otomatis menyamakan ukuran pixel cluster yang sudah tertanam pada aset; aset tetap perlu disamakan skala, palet, dan kepadatan detailnya. Pada browser, uji dahulu ketajaman serta keterbacaan HUD di berbagai rasio layar sebelum mengganti mode stretch.
3. **Palet Warna Tidak Konsisten:** Setiap gambar AI memiliki rentang warna gradien RGB acak tanpa batas palet retro.
   * *Solusi:* Terapkan post-processing Color Palette Limiter Shader (lut-based) agar warna seluruh aset AI tampak seperti dikerjakan oleh satu seniman piksel yang sama.

---

## 2. Dynamic Weather (Cuaca Dinamis)

Cuaca tropis maritim Nusantara memiliki karakteristik muson yang kuat: dari siang cerah terik, angin kencang berdebu, hingga badai muson barat dengan hujan lebat dan kilat.

### 2.1 Arsitektur Sistem Cuaca di Godot
* **Komponen 1: Hujan Tropis (`GPUParticles2D`)**
  * Emisi berbentuk kotak selebar viewport kamera ($1440 \times 10$ piksel).
  * Vektor jatuh: miring $-15^\circ$ mengikuti arah tiupan angin barat.
  * Bentuk partikel: garis 1×6 piksel berwarna `#bae6fd` dengan alpha $0.4$.
  * Partikel benturan lantai (*Roof & Deck Splash*): Saat partikel menyentuh atap rumah panggung atau dek dermaga Beno, muncul letupan 2–3 titik air mikro.
* **Komponen 2: Angin Prosedural (Goyangan Pohon & Lamun AI)**
  * Aset pohon kelapa, bakau, dan anyaman bambu AI dipasangi vertex shader ayunan pucuk:
  ```glsl
  shader_type canvas_item;
  uniform float wind_speed = 2.0;
  uniform float wind_strength = 0.05;
  void vertex() {
      // Bagian bawah (akar/tiang) diam, bagian atas bergoyang
      float height_factor = clamp(1.0 - UV.y, 0.0, 1.0);
      VERTEX.x += sin(TIME * wind_speed + VERTEX.y * 0.5) * wind_strength * height_factor * 50.0;
  }
  ```
* **Komponen 3: Kilatan Petir (*Lightning Flash*)**
  * Perubahan kecerahan seketika menggunakan `CanvasModulate` ke nilai over-bright `Color(2.2, 2.2, 2.5)` selama 0.06 detik, diikuti jeda audio guntur 1–3 detik sesuai jarak kilat.

### 2.2 Dampak Cuaca terhadap Gameplay
| Tipe Cuaca | Dampak di Darat (Bandar Hujung) | Dampak di Laut (Segaran / Jalatunda) | Dampak di Kedai Waras |
| :--- | :--- | :--- | :--- |
| **Cerah Tropis** | Nelayan beraktivitas normal, perahu bersandar rapi. | Sinar matahari tembus ke dasar dangkalan, terumbu lamun berfotosintesis aktif, ubur-ubur bersinar. | Pengunjung meminta olahan es segar & minuman kelapa penurun panas. |
| **Hujan Rintik** | Warga berteduh di bawah teras panggung, dermaga basah berkilap. | Permukaan air beriak halus, suara kedap hujan menenangkan. | Minuman jamu hangat mulai diminati. |
| **Badai Barat Laut** | Angin kencang mengayunkan pohon kelapa, perahu bergoyang liar di dermaga. | Arus palung menjadi deras, jarak pandang air berkurang pekat, sampah industri hanyut mendekat, biota laut dalam naik ke permukaan. | Pengunjung memadati kedai mencari kehangatan; omzet pesanan jamu rebusan (jahe, temu lawak) meningkat pesat. |

---

## 3. Dynamic Lighting & Time System (Sistem Pencahayaan Dinamis & Waktu Terpadu)

Siklus waktu dan pencahayaan dinamis adalah pengikat visual paling krusial ketika seluruh aset game dibuat 100% oleh AI. Tanpa sistem pencahayaan mesin (engine lighting), aset AI yang dihasilkan dari prompt berbeda akan terasa terpisah, berantakan, dan datar (*flat collage*). Pencahayaan dinamis 2D di Godot menyatukan palet warna, memberikan rasa kedalaman, serta menghidupkan atmosfer maritim Nusantara.

### 3.1 Hierarki Pencahayaan Global (Ambient `CanvasModulate` & Siklus 24 Jam)
Alih-alih melukis ulang aset AI untuk tiap fase waktu, interpolasikan warna ambient global menggunakan `CanvasModulate` dengan kurva palet pesisir Nusantara:

```
[05:00] Fajar Pesisir     ──>  #fde68a (Kuning keemasan lembut, kabut tipis)
[12:00] Siang Terik       ──>  #ffffff (Putih bersih, saturasi warna tinggi)
[17:15] Senja Keemasan    ──>  #fb923c (Jingga madu hangat)
[17:45] Maghrib / Senja   ──>  #b45309 (Tembaga tua kemerahan, bayangan memanjang)
[18:45] Lembayung Malam   ──>  #4338ca (Ungu nila magis, batas darat & laut kabur)
[21:00] Malam Laut Dalam  ──>  #082f49 (Navy-toska pekat berkedalaman, BUKAN hitam mati #000000)
```

* **Formula Modulasi Cuaca Terhadap Waktu:**
  Warna ambient akhir merupakan hasil kali matriks antara siklus waktu dan status cuaca:
  $$\text{Final Ambient} = \text{TimeColor}(t) \times \text{WeatherModulate}(w)$$
  * *Saat Cerah Siang:* `WeatherModulate = Color(1.0, 1.0, 1.0)`.
  * *Saat Mendung Tebal:* `WeatherModulate = Color(0.65, 0.70, 0.75)` (suasana meredup dingin keabuan).
  * *Saat Badai Muson:* `WeatherModulate = Color(0.40, 0.45, 0.55)` (gelap dramatis di siang bolong, memicu lampu-lampu rumah menyala lebih awal).

### 3.2 Interaksi Pencahayaan Cuaca: Kilat Petir & Overbright
* **Kilatan Petir Prosedural (*Lightning Strike*):**
  * Tidak menggunakan sprite animasi AI. Gunakan `CanvasModulate` yang disetel sekejap ke mode overbright:
    $$\text{Flash Color} = \text{Color}(2.4, 2.4, 2.7) \quad (\text{durasi } 0.05 - 0.08\text{ detik})$$
  * Diikuti pemudaran cepat (*lerp decay*) kembali ke ambient badai dalam 0.35 detik.
  * *Delay Guntur Dinamis:* Pemicu audio guntur (`AudioStreamPlayer2D`) dihitung berdasarkan jarak fiktif pusat petir:
    $$t_{\text{guntur}} = \text{randf\_range}(0.8, 2.5)\text{ detik}$$
  * *Efek Siluet Sesaat:* Saat kilat menyala, pohon kelapa dan rumah panggung AI yang biasanya gelap seketika menjadi siluet tajam dengan kontras ekstrem, menciptakan ketegangan atmosferik instan.

### 3.3 Pencahayaan Artifisial Darat (Bandar Hujung & Kedai Waras)
Pada senja hingga malam hari (atau saat badai gelap), aktifkan titik-titik cahaya buatan (`PointLight2D`):

1. **Cahaya Jendela Rumah Panggung Pesisir:**
   * Di balik jendela anyaman bambu dan dinding kayu rumah panggung, pasang `PointLight2D` berona kuning hangat (`#fef08a`) dengan tekstur gradien radial halus.
   * *State Logic:* Lampu jendela mati otomatis di siang hari terik dan mulai menyala perlahan (*fade-in*) ketika ambient cahaya turun di bawah threshold tertentu (pukul 17:30 atau saat badai lebat).
2. **Lentera Minyak & Obor Dermaga Galangan Bubat:**
   * Warna: Oranye kemerahan hangat (`#fb923c` ke `#ea580c`).
   * *Flicker Prosedural (Gemetar Nyala Api):* Gunakan noise berfrekuensi rendah pada properti `energy` dan `texture_scale`:
     ```gdscript
     # Skrip ringan flicker tanpa membebani browser
     var noise_val = sin(Time.get_ticks_msec() * 0.008) * 0.12 + cos(Time.get_ticks_msec() * 0.015) * 0.08
     light.energy = 1.0 + noise_val
     light.texture_scale = 1.0 + (noise_val * 0.05)
     ```
   * Menghasilkan ilusi nyala sumbu minyak yang ditiup angin laut tanpa memerlukan sprite sheet animasi frame berulang dari AI.
3. **Tungku & Dapur Rebusan Kedai Waras:**
   * Pendaran bara api merah membara (`#f87171` - `#ef4444`) berdenyut pelan di lantai dapur, memantulkan kehangatan ramuan jamu Mak Waras bagi pengunjung yang berteduh dari hujan.

### 3.4 Pencahayaan Eksplorasi Bawah Air (Senter Selam & Visibilitas Palung)
Di bawah permukaan air, pencahayaan menjadi mekanika navigasi inti:

1. **Senter Helm Selam Nala (*Diver Flashlight Cone*):**
   * Tipe Node: `PointLight2D` dengan tekstur kerucut sorot (*spot cone texture*, sudut bukaan $45^\circ$, jangkauan 240–300 piksel).
   * *Rotasi Terarah:* Rotasi senter di-lerp mulus mengikuti arah hadap renang atau posisi bidikan jala Nala.
   * *Spektrum Sorot:* Putih kebiruan terang di bagian tengah (`#e0f2fe`), dengan cincin falloff kekuningan tipis di pinggirnya, mensimulasikan refraksi lensa kaca helm selam kuno.
2. **Penetrasi Cahaya & Atenuasi Kekeruhan Air (*Water Turbidity Attenuation*):**
   * Di perairan jernih Segaran: Senter menembus jauh hingga 300px dengan pendaran caustics matahari tipis.
   * Di dekat pipa limbah PT Cakrawala Sintetis (air keruh berminyak): Naikkan nilai `attenuation` cahaya secara drastis sehingga jangkauan senter menyusut menjadi hanya 80–100px. Hal ini menciptakan rasa klaustrofobik dan bahaya alami tanpa perlu memodifikasi aset sprite ikan/limbah AI.
3. **Berkas Sinar Matahari Bawah Air (*God Rays / Crepuscular Rays*):**
   * Shader pita cahaya 2D diagonal di perairan dangkal (0–20 meter).
   * Pada siang hari cerah: Berkas sinar tampak tajam dan bergerak ritmis mengikuti gelombang permukaan.
   * Saat matahari terbenam atau awan badai lewat: Berkas sinar meredup dan lenyap perlahan, meninggalkan pemain dalam kegelapan kolom air.

### 3.5 Bioluminesensi Alami & Pendaran Polusi
* **Biota Laut Bercahaya (Ubur-ubur Klorofil & Terumbu Karang Purba):**
  * `PointLight2D` berskala kecil (32–64px) berwarna toska neon (`#22d3ee`) atau ungu berpendar (`#c084fc`).
  * Denyut pernapasan: Skala cahaya membesar-mengecil seirama gerakan renang ubur-ubur.
* **Pendaran Kontaminan Beracun:**
  * Rembesan senyawa kimia industri di Palung Tamansari menggunakan pendaran hijau asam berpendar (`#4ade80` / `#a3e635`) yang kontras dengan biru laut, memberi tahu pemain secara visual bahwa area tersebut beracun untuk diselami tanpa perlengkapan memadai.

### 3.6 Kaidah Kritis Menghasilkan Aset AI Khusus Pencahayaan (Prompting & Pipeline)
Agar sistem pencahayaan dinamis Godot bekerja sempurna dengan aset 100% buatan AI, taati protokol produksi berikut:

1. **Prinsip "Unlit / Flat Spritesheet":**
   * *Larangan Keras:* JANGAN PERNAH meminta AI menggambar efek lampu yang sudah memancarkan halo cahaya menyala (*baked glow*), atau menggambar bayangan hitam pekat ke tanah (*baked directional shadow*).
   * *Alasan:* Jika aset AI sudah memiliki gambar bayangan matahari siang terik yang digambar mati di sprite, saat malam tiba bayangan tersebut tetap terlihat aneh dan lampu malam tidak dapat menyinarinya dengan wajar.
   * *Prompt AI yang Benar:* `"Stilt house front view, diffuse lighting, flat overcast lighting, clean edges, isolated transparent background, no cast shadow, unlit lantern"`.
2. **Isolasi Layer Cahaya (*Light Cull Masks*):**
   * Seluruh node UI, font dialog, ikon HUD, dan potret karakter harus dipasang pada `CanvasItem > Visibility > Light Mask = 2`.
   * Seluruh sumber cahaya (`PointLight2D`, `DirectionalLight2D`) disetel hanya memengaruhi `Item Cull Mask = 1`.
   * *Hasil:* Saat dunia permainan mengalami mati lampu total, malam pekat, atau kilatan petir berkedip liar, teks HUD dan menu tetap terbaca 100% jernih tanpa terdistorsi kecerahan lampu.
3. **Normal Map 2D Prosedural untuk Kedalaman Ekstra:**
   * Karena AI biasanya hanya menghasilkan tekstur warna datar (Albedo/Diffuse), buat normal map 2D sederhana menggunakan shader runtime deteksi tepi Sobel (Height-to-Normal). Dengan normal map ini, saat senter Nala menyapu batu karang atau dinding kayu panggung AI, permukaan tampak memiliki tekstur timbul 3D yang realistis.

### 3.7 Optimalisasi Godot Web/WASM (Single-Threaded Performance)
Rendering WebGL di peramban memiliki batas draw call dan fragment shader yang ketat:

* **Batas Maksimal Lampu Aktif:** Jangan gunakan lebih dari 6–8 `PointLight2D` aktif di dalam satu layar secara bersamaan.
* **Culling Otomatis:** Pasang `VisibleOnScreenNotifier2D` pada setiap lentera rumah/dermaga. Matikan node cahaya (`light.enabled = false`) segera setelah posisinya keluar dari viewport kamera.
* **Pembatasan Shadow Occluder 2D:**
  * Mengaktifkan bayangan (`shadows_enabled = true`) pada puluhan objek di web akan melipatgandakan draw call dan memicu penurunan frame rate (*lag spike*).
  * *Solusi:* Hanya aktifkan bayangan dinamis pada 1–2 elemen struktur masif (misalnya lambung perahu utama atau pilar tebing besar). Objek kecil seperti tiang bambu, pagar, atau rumput laut CUKUP menerima penerangan tanpa menghitung bayangan oklusi.
* **Ukuran Tekstur Gradien Cahaya:** Gunakan tekstur gradien radial kecil ($64 \times 64$ atau $128 \times 128$ piksel) dengan kompresi teroptimasi, bukan tekstur resolusi tinggi $1024 \times 1024$. Godot akan memfilternya dengan mulus tanpa membebani memori browser.

---

## 4. Dynamic Water (Air Dinamis: Permukaan & Kedalaman)

### 4.1 Permukaan Air Bergelombang (*Procedural Water Surface*)
Garis batas permukaan air dibuat dari mesh dinamis dengan gabungan dua gelombang sinus:
$$y(x, t) = A_1 \sin(k_1 x + \omega_1 t) + A_2 \sin(k_2 x - \omega_2 t)$$
* Menghasilkan gerakan air yang tidak berulang secara monoton.
* Ketika Nala melangkah di permukaan, tambahkan gaya perpindahan lokal yang merambat sebagai riak gelombang ke samping.

### 4.2 Distorsi Pembiasan Kolom Air (*Screen Refraction*)
Gunakan shader post-processing dengan sampler Godot 4 `uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;`, berpadu dengan noise atau gelombang prosedural yang bergeser lambat. `SCREEN_TEXTURE` merupakan nama bawaan versi lama, bukan API shader Godot 4:
* Seluruh batu karang, tiang kayu, dan ikan AI di bawah air akan tampak meliuk lentur secara fisik.
* Efek ini menghilangkan kesan "gambar tempelan mati" pada sprite AI.

### 4.3 Transisi Pencemaran Air (PT Cakrawala Sintetis)
* Di zona perairan bersih Segaran: Rona air biru toska muda dengan berkas cahaya caustics cerah.
* Saat Nala mendekati pipa limbah pabrik: Ubah warna rona (*tint color*) shader secara mulus menjadi cokelat keruh berlapisan pelangi minyak tipis (*oil sheen effect*), dan kurangi visibilitas jarak pandang kamera secara dramatis.

---

## 5. Drop Water & Water Effects (Tetesan, Percikan, dan Transisi Basah)

### 5.1 Efek Percikan Terjun & Muncul Permukaan (*Splash & Ripple*)
* **Saat Melompat Masuk Air:**
  1. Letupan 16 partikel piksel busa putih memancar ke atas kiri dan kanan (`CPUParticles2D`).
  2. Cincin elips mengembang di permukaan air (*expanding ripple decal*) yang memudar dalam 0.6 detik.
  3. Audio: Suara benturan air berbobot berat (*heavy body plunge*).
* **Saat Muncul ke Udara:**
  1. Letupan gelembung dan semburan air mikro.
  2. Layar kamera mendapatkan efek tetesan air mengalir turun (*lens droplets*) selama 1.5 detik.

### 5.2 Karakter Basah Menetes di Darat (*Wet State*)
* Saat Nala naik ke dermaga kayu setelah menyelam:
  * Partikel tetesan air kecil jatuh dari siku dan ujung sirip selam Nala selama 3–4 detik.
  * Di atas papan kayu dermaga, tinggalkan bercak pijakan kaki basah gelap sementara (*temporary wet footprint*) yang perlahan menguap dan menghilang dalam 4 detik.

### 5.3 Feedback Gelembung Oksigen
* **Posisi Diam:** Gelembung keluar berkala setiap 2.5 detik melayang zig-zag ke permukaan.
* **Berenang Cepat (*Dash*):** Jejak semburan gelembung memanjang di belakang kaki katak Nala, mempertegas sensasi dorongan kinetik.
* **Oksigen Kritis (<20%):** Aliran gelembung cepat dan acak disertai audio denyut jantung berdegup kencang.

---

## 6. Desain Tata Suara Terpadu (*Dynamic Audio Architecture*)

1. **Efek Kedap Bawah Air (*Low-Pass Filter*)**:
   * Pasang `AudioEffectLowpassFilter` pada bus lingkungan tersendiri, bukan Master; UI dan dialog harus tetap jelas.
   * Saat menyelam: *Tween* frekuensi cut-off dari $20.000\text{ Hz}$ turun ke $550\text{ Hz}$ dalam waktu 0.25 detik.
   * Seluruh kebisingan angin dan obrolan darat seketika teredam menjadi suara dengung air laut yang dalam dan sunyi.
2. **Audio Hujan Spesifik Tempat**:
   * Suara hujan di luar ruangan: Deru angin dan titik air menyentuh tanah.
   * Suara saat berteduh di bawah atap kedai: Ketukan gemeretak air hujan di atas anyaman rumbia bambu.

---

## 7. Aturan Prompting AI Khusus Sistem Dinamis

Gunakan format prompt berikut saat memproduksi aset visual baru melalui generator AI:

```
┌─────────────────────────────────┬─────────────────────────────────────────────────────────────┐
│ Kategori Aset                   │ Aturan Prompting AI yang Benar                              │
├─────────────────────────────────┼─────────────────────────────────────────────────────────────┤
│ 1. Vegetasi & Pohon             │ "Single isolated tropical nypa palm on pure black or        │
│                                 │ transparent background, vertical trunk, clean 2D pixel art, │
│                                 │ crisp edges, no ground shadow, no grass at base"            │
│                                 │ ➔ Pucuk pohon mudah digoyang shader tanpa distorsi tanah.   │
├─────────────────────────────────┼─────────────────────────────────────────────────────────────┤
│ 2. Air Permukaan                │ JANGAN pernah minta AI menggambar air bersatu dengan tanah. │
│                                 │ Minta: "Wooden coastal stilt dock platform, empty bottom,   │
│                                 │ transparent background" ➔ Air diisi oleh shader Godot.      │
├─────────────────────────────────┼─────────────────────────────────────────────────────────────┤
│ 3. Objek Bercahaya              │ Minta AI menggambar lentera dalam keadaan MATI atau KACA    │
│                                 │ KUNING RATA tanpa menggambar lingkaran pendaran cahaya.     │
│                                 │ ➔ Pendaran glow dinamis dibuat oleh PointLight2D Godot.     │
├─────────────────────────────────┼─────────────────────────────────────────────────────────────┤
│ 4. Jejak Kaki Basah             │ "Single 4x4 pixel dark water puddle spot, top down,         │
│                                 │ transparent background" ➔ Untuk partikel jejak langkah Nala.│
└─────────────────────────────────┴─────────────────────────────────────────────────────────────┘
```

---

*Dokumen ini dirancang sebagai acuan arsitektur game Jalasmara untuk menjaga keseimbangan antara efisiensi aset berbasis AI dan kedalaman atmosfer permainan di platform web.*



## 8. Perspektif, layering, dan biaya pencahayaan

Darat memakai pandangan tiga perempat dengan gerak dua sumbu. Ukuran karakter harus dinilai terhadap pintu, tangga, bangku, dan pepohonan dalam screenshot permainan sebenarnya. Titik kaki menentukan Y-sort; collider hanya mewakili bagian yang menapak, bukan seluruh gambar tubuh. Pisahkan dasar, benda padat, tajuk depan, dan atmosfer jauh. Jangan menggeser layer yang memiliki collider demi parallax; gunakan parallax hanya pada latar atau vegetasi dekoratif terpisah.

Kedalaman yang dimaksud adalah perspektif, tumpang-tindih, bayangan kontak, dan berkurangnya kontras lapisan jauh. Blur layar penuh tidak diperlukan untuk membuat pixel art terasa berdimensi dan dapat mengaburkan jalur atau UI. Hindari blur pada pemain, interaksi, dan HUD.

Pencahayaan lokal harus berada pada lampu yang terlihat di dunia. Interpolasikan energi lentera menurut cahaya sekitar dan awan, dengan variasi kecil, bukan kedip ekstrem. Senter mengikuti arah gerak terakhir, dengan peralihan sudut halus. Bayangan aktif hanya untuk beberapa sumber penting; tumbuhan kecil tidak memerlukan occluder sendiri. Collision tidak berubah karena cahaya atau shader.

Untuk Web Compatibility single-thread, partikel native yang digambar dalam satu node adalah pilihan sah selain GPUParticles2D. Pilih berdasarkan profiling pada HP nyata. Tetapkan jumlah partikel, lampu berbayangan, dan sampler layar yang terbatas; jangan menyebut efek “ringan” tanpa mengukur perangkat sasaran. Sediakan preferensi pengurangan gerak sebelum menambahkan kilat atau distorsi kuat.
