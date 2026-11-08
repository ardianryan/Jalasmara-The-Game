# Panduan Desain Peta Darat, Hutan Bakau, & Candi Air Tawar Jalasmara

> Acuan desain dari referensi. Tidak semua fitur di dokumen ini sudah aktif. Lihat [status pengembangan](development-status.md) dan [dunia hidup](world/living-world.md) untuk implementasi serta batasnya.
*(Jungle Hub, Open-Air Banquet, Freshwater Ruins, & Night Mangrove Swamp)*

**Dokumen Desain Peta & Level Daratan (Land Map & World Ecology Architecture)**  
*Target Engine:* Godot 4.x (Web / WASM Single-Threaded)  
*Status Berkas:* Panduan Resmi Jalasmara  
*Referensi Visual Privat:* `moodboard/dave-the-diver/images/jungle-01` s.d. `jungle-05` (diabaikan Git)

---

## 1. Analisis 5 Pilar Pengayaan Peta Darat & Hutan

Kelima tangkapan layar terbaru dari ekspansi hutan *Dave the Diver: In the Jungle* memperlihatkan bagaimana ruang daratan dibangun menjadi dunia hidup yang terhubung secara organis dengan alam:

```
              5 PILAR ARSITEKTUR PETA DARAT & HUTAN JALASMARA
┌────────────────────────────────────────────────────────────────────────┐
│ [jungle-01] HUB PERKEMAHAN & DESA: Tenda kanvas Beno, meja radio/peta, │
│             sungai air tawar jernih bertebing lumut, rumah panggung    │
├────────────────────────────────────────────────────────────────────────┤
│ [jungle-02] KEDAI MALAM TERBUKA: Paviliun bambu, string lights hangat, │
│             papan menu sate gantung, meja piknik komunal berumput      │
├────────────────────────────────────────────────────────────────────────┤
│ [jungle-03] CANDI AIR TAWAR TERENDAM: Pilar batu megalitikum di 44m,   │
│             bola roh mengapung, fauna lele/baung raksasa berpatil      │
├────────────────────────────────────────────────────────────────────────┤
│ [jungle-04] PERAYAAN HASIL TANGKAPAN: Bangkai predator di pelataran,   │
│             tetua adat & warga berkumpul mengapresiasi reputasi Nala   │
├────────────────────────────────────────────────────────────────────────┤
│ [jungle-05] RAWA BAKAU MALAM HARI: Titian jembatan batu melintasi rawa,│
│             akar tunjang raksasa, spora biru neon, sergapan monster rawa│
└────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Bedah Detail & Penerapan Konkret pada Jalasmara

### 2.1 Hub Perkemahan Peneliti & Pelataran Desa (`jungle-01-village-research-campsite.jpg`)
* **Observasi Tata Letak (2.5D Oblique Top-Down):**
  * Tenda ekspedisi kanvas hijau tua dan putih berangka kayu berdiri di tanah lapang berpasir dan berumput. Meja perkakas dilengkapi instrumen radio komunikasi, teleskop bintang, dan papan pengumuman kayu berisi peta zonasi yang disematkan pin.
  * Tepat di bagian kanan bawah, terdapat aliran sungai air tawar jernih bertebing tanah terasering dengan tanaman teratai air putih (*water lilies*) dan rumpun lumut basah.
  * Rumah-rumah panggung tradisional beratap rumbia/alang-alang berdiri kokoh dengan tangga kayu, berhias tanaman puring (*Croton*) merah-ungu dan rumpun pohon pisang.
* **Penerapan pada Bandar Hujung Jalasmara:**
  * **Rombak Garis Datar Menjadi Pelataran Semi-Tampak Atas:** Jangan membuat Bandar Hujung hanya berupa garis dermaga lurus 1D. Jadikan sebagai pelataran desa pesisir di mana Nala dapat berjalan bebas 8-arah (`CharacterBody2D`).
  * **Bengkel Rakitan Beno:** Wujudkan tempat kerja Beno berupa tenda kanvas ekspedisi maritim dengan meja peralatan perkakas selam dan radio saku pemantau kapal patroli limbah.
  * **Aliran Sungai Muara ke Laut:** Aliran sungai air tawar membelah daratan desa menuju muara Segaran, menjadi pembatas alami sebelum Nala melangkah ke jembatan titian kayu.

---

### 2.2 Kedai Waras Terbuka & Suasana Malam (`jungle-02-night-village-banquet.jpg`)
* **Observasi Tata Letak Warung Malam:**
  * Paviliun bambu beratap rumbia terbuka ke pelataran, dihiasi untaian lampu bohlam pijar kuning hangat (*string lights / fairy lights*) yang digantung di antara tiang kayu.
  * Di atas meja bar terdapat papan menu bambu berderet dengan porsi santapan (`2/2`, `3/5`, `3/6`).
  * Warga desa duduk di meja piknik kayu komunal beralaskan tanah berumput. Balon pikiran menampilkan sate bakar dan olahan pisang, disertai senyuman dan teks apresiasi: *"It was really delicious... thank you..."*.
  * Terdapat anglo batu bara api (*stone fire braziers*) yang menyala merah hangat di samping meja saji.
* **Penerapan pada Kedai Waras (Mak Waras):**
  * **Kedai Jamu & Bakaran Pesisir Terbuka:** Mengubah interior tertutup menjadi warung bambu terbuka yang menghadap langsung ke arah laut malam.
  * Untaian lampu bohlam kuning menggantung di bawah atap rumbia, memberikan pencahayaan ambient hangat (`#fef08a`) yang kontras dengan langit malam pesisir biru gelap (`#082f49`).
  * Meja-meja kayu sederhana diletakkan di pelataran tanah di bawah pohon kelapa, tempat para nelayan berkumpul minum rebusan jahe hangat dan mencicipi olahan lamun Mak Waras setelah seharian melaut.

---

### 2.3 Reruntuhan Candi Terendam & Ikan Air Tawar Purba (`jungle-03-freshwater-ruins-giant-catfish.jpg`)
* **Observasi Ekologi Air Tawar:**
  * Penyelaman di kedalaman $44.2\text{ m}$ bukan di laut lepas, melainkan di dalam gua air tawar reruntuhan megalitikum!
  * Formasi balok batu candi terendam berpahat relief kuno membentuk lorong navigasi megah.
  * Dave berhadapan dengan **Lele Raksasa (*Giant Freshwater Catfish*)** dengan sungut panjang dan mulut menganga lebar.
  * Terdapat bola cahaya putih misterius (*spirit orb*) mengapung di kolom air dan tanaman rumput air tawar hijau lebat.
* **Penerapan pada Ceruk Karst Jalatunda & Sendang Kuno:**
  * Hadirkan variasi ekologi: Nala tidak hanya menyelam di laut asin Segaran, tetapi juga dapat menyelam di **Sendang Tirta Jalatunda** (danau gua air tawar di bawah tebing karst pedalaman).
  * Karakter visual air tawar: Air lebih hijau lumut (*mossy emerald tint*), tanpa terumbu karang laut, melainkan dihiasi pilar batu candi Majapahit terendam dan tanaman ganggang air tawar.
  * **Fauna Endemik Air Tawar Nusantara:** Ganti hiu laut dengan **Ikan Baung Raksasa (*Hemibagrus*)**, **Ikan Patin Purba**, atau **Sidat Rawa Raksasa** yang menjaga gerbang lorong batu kuno.

---

### 2.4 Perayaan Hasil Tangkapan & Apresiasi Sosial Komunitas (`jungle-04-village-trophy-cutscene.jpg`)
* **Observasi Interaksi Sosial:**
  * Predator raksasa yang berhasil ditaklukkan (hiu predator terluka) diletakkan di tengah pelataran rumput desa.
  * Warga desa berkumpul mengerumuni: kepala suku bermahkota bulu tradisional, tetua adat dengan tongkat jalan, pemburu dengan tombak, dan anak-anak yang bersorak gembira.
  * Terdapat rumah panggung kayu dengan lentera minyak menyala di teras depan dan semak bunga tropis mekar di sekitarnya.
* **Penerapan pada Narasi & Progres Jalasmara:**
  * **Dampak Keberhasilan Nala Terlihat di Dunia:** Saat Nala berhasil menetralisir katup pipa racun atau menyelamatkan satwa langka yang terjerat dari palung:
    * Muncul adegan sinematik singkat di pelataran Bandar Hujung.
    * Warga pesisir, Beno, dan Mak Waras menyambut Nala dengan upacara syukur bahari sederhana.
    * Tingkat *Reputasi Nelayan* Nala naik, dan warga memberikan peralatan baru (misal: jala sutra anyaman tetua atau lampu senter selam berdaya tahan ganda).

---

### 2.5 Rawa Bakau Malam Hari & Sergapan Monster Rawa (`jungle-05-night-mangrove-swamp-ambush.jpg`)
* **Observasi Rawa Bakau Mencekam:**
  * Jembatan titian batu dan balok kayu melintasi perairan rawa hitam pekat di tengah hutan bakau malam hari.
  * Akar tunjang pohon bakau raksasa (*Rhizophora stilt roots*) menjulang kokoh ke dalam air rawa.
  * **Bioluminesensi Spora Rawa:** Partikel cahaya biru neon melayang di udara di antara dedaunan bakau yang gelap.
  * **Sergapan Mendadak:** Monster ikan katak rawa bertanduk (*Angler Toadfish*) menyembul tiba-tiba dari pusaran air rawa, membuka mulutnya tepat di samping jembatan saat rombongan Dave melintas.
* **Penerapan pada Zona Hutan Bakau Wringin (Malam Hari):**
  * Hutan Bakau Wringin di malam hari adalah zona bahaya darat-air yang intens.
  * Nala menyusuri titian jembatan kayu di atas rawa pasang-surut yang dipenuhi akar bakau berlumut.
  * **Pencahayaan Dramatis:** Gunakan `PointLight2D` senter saku Nala yang menyapu air hitam pekat, diiringi partikel spora biru neon melayang pelan.
  * Riak air mendadak muncul di samping jembatan kayu, memperingatkan pemain bahwa ada pemangsa rawa (seperti **Buaya Muara** atau **Ikan Kodok Purba**) yang siap menerjang jika Nala tidak waspada.

---

## 3. Spesifikasi Prompting Generator AI untuk Aset Peta & Hutan

Gunakan format prompt berikut untuk menghasilkan aset lingkungan daratan dan hutan yang siap diimpor ke Godot tanpa masalah bayangan mati:

| Elemen Peta | Deskripsi Aset | Prompt AI yang Benar (Clean & Unlit) |
| :--- | :--- | :--- |
| **Tenda Peneliti** | Tenda kanvas ekspedisi hijau/putih dengan meja radio | `"Expedition canvas field research tent, 2.5D oblique view, radio equipment and field desk outside, weathered olive green canvas, clean 2D pixel art, transparent background, isolated, no cast shadow"` |
| **Paviliun Warung** | Warung bambu terbuka dengan atap rumbia & bohlam gantung | `"Open air tropical bamboo stall kitchen, thatched palm roof, string light garland hanging from eaves, rustic wooden picnic counter, 2.5D oblique view, pixel art, isolated"` |
| **Akar Tunjang Bakau** | Rumpun akar bakau purba untuk rawa berlumpur | `"Gnarled mangrove tree stilt roots cluster, mossy bark, aerial roots descending into swamp, clean silhouette, 2D pixel art asset, isolated, transparent background"` |
| **Pilar Candi Terendam** | Balok batu megalitikum berpahat lumut untuk air tawar | `"Submerged ancient megalithic stone pillar with carved tribal spiral relief, freshwater aquatic moss clinging to cracks, 2D side view, clean pixel edges, transparent background"` |
| **Ikan Lele Raksasa** | Ikan air tawar purba bermulut lebar dengan sungut | `"Giant prehistoric freshwater catfish swimming side view, wide whiskers, gaping mouth, dark gray scales with white belly, clean pixel art, isolated transparent background"` |

