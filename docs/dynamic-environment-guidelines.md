# Panduan Teknis & Desain: Lingkungan Dinamis Jalasmara
*(Dynamic Weather, Dynamic Time, Dynamic Water, & Water Effects untuk Aset AI)*

**Dokumen Arsitektur & Panduan Desain Teknis**  
*Target Engine:* Godot 4.x (Web / WASM Single-Threaded)  
*Konteks Aset:* 100% Grafis & Piksel Dibuat oleh AI  
*Prinsip Utama:* **Aset AI sebagai kanvas visual statis, Godot Engine sebagai motor dinamika prosedural.**

> **Status:** dokumen ini adalah arah desain, bukan daftar fitur yang semuanya sudah aktif. Lihat [status implementasi lingkungan](world/environment.md) untuk perilaku build saat ini. Dampak cuaca pada ekonomi, siklus bebas 24 jam, audio, dan simulasi air masih merupakan sasaran lanjutan.

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

## 3. Dynamic Time (Siklus Waktu & Pencahayaan 24 Jam)

Siklus waktu menghidupkan ritme permainan antara eksplorasi luar ruangan dan manajemen kedai malam hari.

### 3.1 Palet Warna Pesisir Nusantara (`CanvasModulate`)
Alih-alih melukis ulang aset AI untuk tiap fase waktu, interpolasikan warna ambient global menggunakan palet maritim:

```
[05:00] Fajar Pesisir     ──>  #fde68a (Kuning keemasan lembut, kabut tipis)
[12:00] Siang Terik       ──>  #ffffff (Putih bersih, saturasi warna tinggi)
[17:30] Senja / Maghrib   ──>  #d97706 (Jingga tembaga tua berbayang panjang)
[18:45] Lembayung Malam   ──>  #4c1d95 (Ungu kemerahan mistis)
[21:00] Malam Laut Dalam  ──>  #0c2229 (Toska-navy pekat, BUKAN hitam legam)
```

### 3.2 Pencahayaan Titik 2D (`PointLight2D`) Ramah Web
* Pada malam hari, hidupkan sumber cahaya lokal untuk mempertegas kontur aset statis AI:
  * **Lentera Minyak Galangan Bubat:** Cahaya kuning hangat berkedip lembut (*flickering noise*).
  * **Tungku Rebusan Kedai Waras:** Cahaya oranye kemerahan berayun di lantai kayu.
  * **Senter Selam Nala:** Kerucut cahaya 2D yang mengikuti arah hadap karakter di bawah air gelap.
  * **Bioluminesensi Palung:** Titik-titik cahaya toska/ungu pada ubur-ubur klorofil dan dinding terumbu karang purba.

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
