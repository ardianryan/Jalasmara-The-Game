# Panduan Desain Ekologi Bawah Air & Budidaya Apung Jalasmara

> Acuan desain dari referensi. Tidak semua fitur di dokumen ini sudah aktif. Lihat [status pengembangan](development-status.md) dan [dunia hidup](world/living-world.md) untuk implementasi serta batasnya.
*(Underwater Stratification, Encumbrance, Wildlife Encounters, & Floating Fish Farm)*

**Dokumen Desain Level & Ekologi Permainan (Ecology & Level Design Architecture)**  
*Target Engine:* Godot 4.x (Web / WASM Single-Threaded)  
*Status Berkas:* Panduan Resmi Jalasmara  
*Referensi Visual Privat:* `moodboard/dave-the-diver/images/underwater-01` s.d. `underwater-04` (diabaikan Git)

---

## 1. Analisis 4 Pilar Pengayaan Bawah Air dari Dave the Diver

Empat tangkapan layar terbaru memperlihatkan bagaimana *Dave the Diver* membangun dunia bawah air yang kaya, hidup, dan berlapis tanpa membebani performa grafis:

```
                  4 PILAR EKOLOGI & LEVEL BAWAH AIR
┌────────────────────────────────────────────────────────────────────────┐
│ [underwater-01] Interaksi Satwa Damai: Lumba-lumba, god rays, koral    │
│                 warna-warni, pemicu quest penyelamatan lingkungan      │
├────────────────────────────────────────────────────────────────────────┤
│ [underwater-02] Navigasi Langit-Langit Karang: Celah sempit horizontal,│
│                 minigame busur tarikan jala, & mekanika beban tas (kg) │
├────────────────────────────────────────────────────────────────────────┤
│ [underwater-03] Jurang Vertikal Bertingkat: Karang piringan bertangga, │
│                 zonasi kedalaman (meter), & kontras paralaks jurang    │
├────────────────────────────────────────────────────────────────────────┤
│ [underwater-04] Keramba Jaring Apung (Fish Farm): Rakit kayu 3x3 petak,│
│                 drum pelampung, penanda habitat, & pembibitan biota    │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Bedah Detail & Penerapan Konkret pada Jalasmara

### 2.1 Satwa Liar Damai & Penyelamatan Lingkungan (`underwater-01-dolphin-encounter.jpg`)
* **Observasi Visual:**
  * Pertemuan langsung antara penyelam dan lumba-lumba liar di kolom air terbuka berlatar sinar matahari tembus air (*god rays*).
  * Balon dialog `[?]` di atas kepala penyelam menandakan adanya interaksi sosial non-pertempuran.
  * Formasi batu purba bertingkat dihiasi anemon merah, karang lunak ungu, spons cyan, dan partikel mikroplankton bercahaya (*marine snow*).
* **Penerapan pada Jalasmara (Segaran):**
  * Tidak semua biota laut harus ditangkap dengan jala. Hadirkan mamalia laut pesisir seperti **Pesut Mahakam** atau **Lumba-lumba Fraser** dan **Penyu Sisik**.
  * **Quest Penyelamatan Lingkungan:** Balon dialog `[?]` muncul saat Nala mendekati penyu yang terlilit sampah jaring nelayan atau pesut yang terperangkap di dekat pipa limbah. Nala menggunakan alat potong atau jala pembebas untuk menolong mereka, yang kemudian memberi hadiah berupa serpihan arca kuno atau membuka jalan rahasia ke gua karang tersembunyi.

### 2.2 Navigasi Plafon Sempit & Sistem Beban Tas (`underwater-02-harpoon-cavern.jpg`)
* **Observasi Visual:**
  * Langit-langit batu masif membentang horizontal di atas kepala Dave, membatasi pergerakan vertikal dan menciptakan koridor renang mendatar.
  * Terdapat indikator busur melingkar (*tension timing arc*) saat Dave menarik hasil tangkapan.
  * **Mekanika Beban Berat (*Encumbrance*):** Indikator di pojok kiri bawah menunjukkan berat `9.2 / 9.0 kg` (warna merah).
* **Penerapan pada Jalasmara (Jalatunda & Rangka Kapal Selam):**
  * **Plat Karst & Reruntuhan Kayu Kapal:** Ciptakan koridor sempit di mana Nala harus berenang menyusup di bawah bangkai kapal pedagang kuno atau lempeng batu karst Jalatunda.
  * **Mekanika Beban Logam Limbah & Bahan Jamu:** Nala memiliki kapasitas tas jinjing terbatas (misal: $10\text{ kg}$). Jika Nala memaksakan mengambil logam rongsokan berat dari pabrik atau terlalu banyak sampel karang:
    * Kecepatan renang berkurang $25\%$.
    * Tingkat konsumsi Oksigen naik $35\%$ lebih cepat.
    * Pemain dihadapkan pada dilema strategis: membuang muatan tidak penting atau mempertaruhkan nyawa berenang lambat menuju tangga dermaga.

### 2.3 Jurang Karang Vertikal & Stratifikasi Kedalaman (`underwater-03-vertical-canyon-descent.jpg`)
* **Observasi Visual:**
  * Penyelaman menukik ke bawah di antara dua tebing batu curam. Dinding tebing ditumbuhi karang piringan jamur biru (*shelf fungus corals*) yang tersusun bertingkat seperti anak tangga.
  * Tampilan kedalaman real-time: `23.6 m` diukur persis di samping O2 `60`.
  * Lapisan paralaks belakang memperlihatkan jurang biru gelap berkabut (*depth fog*), memberikan sensasi vertigo kedalaman laut (*oceanic abyss*).
* **Penerapan pada Jalasmara (Dari Segaran ke Palung Tamansari):**
  * Hubungkan zona dangkalan Segaran ($0 - 15\text{ m}$) dengan Palung Tamansari ($50 - 120\text{ m}$) melalui **Celah Jurang Karang Bertingkat**.
  * Karang meja dan kipas laut (*Gorgonian sea fan*) berfungsi sebagai penghalang alami (*collision boundaries*) dan tempat beristirahat untuk mengisi oksigen dari gelembung celah batu.
  * Suhu warna air bergeser secara mulus dari biru toska cerah di $10\text{ m}$ menjadi biru nila pekat berkabut di kedalaman $>40\text{ m}$.

### 2.4 Struktur Keramba Jaring Apung Nusantara (`underwater-04-floating-fish-farm.jpg`)
* **Observasi Visual:**
  * Platform rakit kayu terapung berstruktur kisi-kisi 3×3 petak jaring penangkaran di tengah laut biru toska.
  * Setiap petak jaring memiliki papan kayu penanda kedalaman habitat asalnya (`Depth ~50m`, `Depth ~130m`).
  * Detail properti maritim: Pelampung drum plastik biru terikat di bawah geladak, ban mobil bekas diikat di tepi rakit sebagai fender penahan ombak, pelampung keselamatan oranye, perahu motor bersandar di sisi dermaga, dan pondok kerja beratap terpal dengan kincir penyuplai aerasi.
* **Penerapan pada Jalasmara (Kebun Rakit Beno & Pembibitan Lamun Mak Waras):**
  * **Ini adalah cetak biru visual sempurna untuk Kebun Rakit Jalasmara!**
  * Alih-alih berupa menu klik teks di dashboard web, wujudkan **Kebun Rakit Bandar Hujung** sebagai rakit kayu terapung fisik:
    * Petak 1–3: **Penangkaran Lamun Pesisir** (untuk menyaring polutan dan memproduksi oksigen).
    * Petak 4–6: **Keramba Pemulihan Ikan Sakit** (merawat biota yang terkena limbah kimia sebelum dilepasliarkan kembali ke laut).
    * Petak 7–9: **Kultur Mikroalga Emas** (bahan baku ramuan jamu unggulan Kedai Waras).
  * Nala dapat berjalan bebas di atas titian papan kayu rakit, memeriksa kesehatan jaring apung, memberi pakan alami, dan memanen bahan jamu segar setiap pagi.

---

## 3. Matriks Implementasi Properti Lingkungan untuk Generator AI

Gunakan panduan prompt berikut untuk memproduksi elemen ekologi dan fasilitas apung baru:

| Kategori Aset | Deskripsi Visual & Fungsi Gameplay | Prompt AI yang Benar (Clean & Unlit) |
| :--- | :--- | :--- |
| **Satwa Damai** | Lumba-lumba / Pesut hidung pendek ramah, berenang anggun | `"Single coastal irrawaddy dolphin, swimming side view, peaceful, clean pixel art, vibrant blue-gray, transparent background, isolated, no water effects"` |
| **Karang Piringan** | Koral meja bertingkat untuk dinding jurang vertikal | `"Tiered shelf fungus plate corals, growing horizontally from left wall, vibrant turquoise and purple, 2D pixel art asset, isolated, transparent background"` |
| **Keramba Apung** | Petak jaring kayu terapung dengan tali dan drum biru | `"Single wooden floating aquafarm dock module, 2.5D oblique view, wood planks with blue plastic buoy barrel underneath, nylon net submerged, transparent background"` |
| **Papan Habitat** | Penanda kayu petak keramba bertuliskan kedalaman | `"Small rustic wooden signpost on dock plank, hand painted depth marker, clean pixel art, isolated"` |

