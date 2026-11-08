# Panduan Efek Dramatis Pertarungan & Bahaya Jalasmara

> Acuan desain dari referensi. Tidak semua fitur di dokumen ini sudah aktif. Lihat [status pengembangan](development-status.md) dan [dunia hidup](world/living-world.md) untuk implementasi serta batasnya.
*(Battle Effects, Low Oxygen Dramatics, & Boss Encounters untuk Aset 100% AI)*

**Dokumen Desain Sistem & Panduan Teknis Efek Permainan (Game Feel Architecture)**  
*Target Engine:* Godot 4.x (Web / WASM Single-Threaded)  
*Status Berkas:* Panduan Resmi Jalasmara  
*Referensi Visual Privat:* `moodboard/dave-the-diver/images/battle-01` s.d. `battle-04` & `yt-boss-yawie-01` s.d. `04` (diabaikan Git)

---

## 1. Prinsip Utama "Game Feel" pada Aset Piksel Buatan AI

Ketika 100% aset visual dikerjakan oleh generator AI, tantangan terbesarnya adalah: **AI tidak bisa menghasilkan transisi animasi benturan (*hurt frames*), ekspresi panik frame-by-frame, dan partikel fluida yang konsisten.**

Solusi arsitektur Jalasmara adalah **"Procedural Impact & Screen-Space Drama"**:
Dramatisasi pertarungan TIDAK dibebankan pada ribuan gambar sprite AI, melainkan ditangani 100% oleh engine Godot melalui:
1. **Manipulasi Waktu & Kamera:** *Hit stop* (jeda frame sesaat), *screen shake* berarah, dan zoom dramatis.
2. **Post-Processing Shaders:** Vignette merah berdenyut, distorsi gelombang kejut (*shockwave*), dan kilatan putih (*hit flash*).
3. **Sistem Partikel Native:** Letupan gelembung darurat di air, hamburan serpihan batu, serta debu tanah di darat.
4. **Desain Tata Suara Terpadu:** Modulasi frekuensi (*low-pass filter*), detak jantung berdegup, dan sirene alarm darurat.

---

## 2. Efek Saat Terkena Pukulan & Kerusakan (*Damage & Impact Feedback*)

### 2.1 Benturan di Dalam Air (Segaran, Jalatunda, & Palung Tamansari)
Di bawah air, Oksigen berfungsi ganda sebagai **Darah (HP) sekaligus Waktu Eksplorasi**. Kehilangan oksigen saat terkena serangan harus terasa mengancam kelangsungan hidup Nala:

* **1. Hit Stop / Micro Freeze-Frame (0.06 – 0.08 detik):**
  * Begitu serangan capit monster atau semburan limbah mengenai Nala, bekukan `Engine.time_scale = 0.05` selama 60 milidetik sebelum kembali ke `1.0`.
  * Efek ini memberi "bobot kinetik" seketika, membuat pemain merasakan hantaman keras sebelum karakter terlempar.
* **2. Sprite Hit-Flash Shader (Kilatan Putih):**
  * Seluruh piksel sprite Nala berubah menjadi putih solid selama 2–3 frame:
  ```glsl
  shader_type canvas_item;
  uniform float flash_modifier : hint_range(0.0, 1.0) = 0.0;
  uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
  void fragment() {
      vec4 color = texture(TEXTURE, UV);
      COLOR = mix(color, vec4(flash_color.rgb, color.a), flash_modifier);
  }
  ```
* **3. Knockback Fluida & Hambatan Air:**
  * Vektor dorongan mundur yang kuat, tetapi segera mengalami deselerasi cepat akibat massa jenis air (*fluid drag*).
* **4. Letupan Gelembung Darurat (*Emergency Bubble Burst*):**
  * Emitter `CPUParticles2D` menyemburkan 12–16 partikel gelembung udara besar dari katup regulator helm Nala ke segala arah, menandakan tabung oksigen baru saja mengalami benturan fatal.
* **5. Pengurangan Oksigen Dramatis:**
  * Bilah O2 di HUD pojok kiri bawah seketika berkedip merah dan melompat turun (misal: $-25\text{ bar}$), disertai teks melayang minus merah `-25 O₂`.

### 2.2 Benturan di Darat / Hutan (Bandar Hujung & Hutan Pesisir)
Mengadopsi referensi pertarungan taktis `hud-02-jungle-tactical-combat`:
* **1. Screen Shake Tajam Dua Sumbu:**
  * Guncangan kamera horizontal beramplitudo 8px dengan peredaman cepat (*decay*) dalam 0.2 detik.
* **2. Efek Tanah & Daun Rontok:**
  * Partikel debu tanah cokelat memancar di bawah kaki Nala, disertai rontokan daun tropis kecil dari tajuk pohon di atas layar.
* **3. Squash & Stretch Prosedural:**
  * Karena sprite AI tidak memiliki frame tersungkur, pipihkan skala sprite Nala sesaat (`scale.y = 0.75`, `scale.x = 1.25`) lalu lenturkan kembali ke ukuran normal (`1.0, 1.0`) menggunakan *Tween* berdurasi 0.15 detik.

---

## 3. Efek Kritis Kehabisan Oksigen (*Low Oxygen & Suffocation Crisis*)

Ketika level oksigen Nala turun di bawah $20\%$ (seperti pada referensi `battle-01-low-oxygen-vignette.jpg`), seluruh permainan beralih ke **Mode Bahaya Akut (*Panic State*)**:

```
                       ANATOMI LAYAR OKSIGEN KRITIS (<20%)
┌────────────────────────────────────────────────────────────────────────┐
│  ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒  │
│  ▒                 ▲▲ PERINGATAN BAHAYA ▲▲                            ▒  │
│  ▒                 OKSIGEN MENIPIS SEGERA NAIK!                       ▒  │
│  ▒                                                                    ▒  │
│  ▒                                                Siluet Pemangsa     ▒  │
│  ▒                                                Mengintai di Keruh  ▒  │
│  ▒                                                                    ▒  │
│  ▒                ( Nala megap-megap & gelembung                      ▒  │
│  ▒                  berhamburan cepat ke atas )                       ▒  │
│  ▒                                                                    ▒  │
│  ▒                                                                    ▒  │
│  ▒ [O₂: 12] ◄ Berkedip Merah Terang                                   ▒  │
│  ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒  │
└────────────────────────────────────────────────────────────────────────┘
  ▲ VIGNETTE MERAH BERDENYUT SEIRAMA DETAK JANTUNG DI SELURUH TEPI LAYAR
```

### 3.1 Komponen Visual Bahaya Akut
1. **Pita Peringatan Bahaya Bergaris Kuning-Hitam:**
   * Pita bahaya melayang di bagian tengah atas layar:
     `▲▲ WARNING ▲▲ Running out of air!`
   * Berkedip perlahan dengan garis chevron miring khas rambu keselamatan industri maritim.
2. **Shader Vignette Merah Berdenyut (*Pulsing Red Vignette*):**
   * Tepi layar diselimuti gradien merah tua darah (`#991b1b`) yang mengaburkan penglihatan tepi (*tunnel vision*).
   * Nilai intensitas vignette berdenyut seirama detak jantung:
     $$\text{Vignette Intensity} = 0.4 + 0.3 \times |\sin(\text{Time} \times \pi \times \text{BPM} / 60)|$$
     (BPM detak jantung meningkat dari 80 saat O2 20% menjadi 140 saat O2 kritis 5%).
3. **Meteran Oksigen Berkedip Merah & Membesar:**
   * Lingkaran O2 di HUD pojok kiri bawah berkedip merah menyala, bergetar mikro, dan membesar $15\%$ dari ukuran normal.
4. **Aliran Gelembung Panik & Gerak Melambat:**
   * Aliran gelembung udara dari helm Nala keluar tanpa henti meliuk panik ke permukaan.
   * Kecepatan renang Nala berkurang 20% karena lemas kehabisan tenaga, meningkatkan urgensi mencari kapsul oksigen atau berenang ke dermaga.

### 3.2 Desain Tata Suara Tenggelam (*Suffocation Soundscape*)
1. **Low-Pass Filter Ekstrem (Kanal Musik & Lingkungan):**
   * Frekuensi cut-off audio lingkungan ditarik turun dari $20.000\text{ Hz}$ ke $250\text{ Hz}$.
   * Musik latar belakang menjadi sangat jauh dan teredam seperti terdengar dari balik dinding tebal.
2. **Audio Detak Jantung (*Heartbeat Audio Loop*):**
   * Suara degup jantung berat bersuara rendah (*lub-dub... lub-dub...*) mendominasi telinga pemain, temponya berakselerasi seiring jarum oksigen mendekati angka nol.
3. **Alarm Sirene Regulator:**
   * Suara beep elektronik bernada tinggi berulang setiap 1.5 detik dari instrumen selam Nala.

---

## 4. Efek Pertarungan Bos & Momen Epik (*Boss Encounter Dramatics*)

Berdasarkan referensi kartu perkenalan `battle-04-boss-splash-card-yawie.png` dan video pertarungan bos akhir `dVdtIbTDQS4`:

### 4.1 Freeze-Frame Kartu Pengenalan Bos (*Boss Splash Intro Card*)
Saat entitas raksasa seperti **Gajah Mina** (atau Kelabang Purba Yawie) muncul pertama kali:
1. **Jeda Aksi Sesaat (*Cinematic Freeze*):** Permainan berhenti sejenak selama 2.5 detik.
2. **Komposisi Komik Halftone & Cipratan Cat:**
   * Layar diwarnai gradien warna tema monster (misal: ungu tua dan kuning neon).
   * Tekstur bintik-bintik *screentone halftone* retro dan cipratan tinta (*ink splatter*) membingkai siluet wajah monster.
3. **Spanduk Tipografi Masif:**
   * Spanduk pita kuning-oranye tebal melintang di sepertiga bawah layar menampilkan nama monster dengan font arkade tebal:
     **`GAJAH MINA - PENJAGA PALUNG SEGARAN`**
   * Dilengkapi raungan audio monster berbobot seismik rendah (*sub-bass roar*).

### 4.2 Letterbox Sinematik Otomatis (Rasio 21:9)
* Dua bilah hitam horizontal turun mulus dari atas dan naik dari bawah layar menutupi masing-masing $10\%$ layar.
* Menandakan pemain telah memasuki arena terisolasi; menu biasa dinonaktifkan sementara dan kamera beralih ke fokus dinamis antara Nala dan sang Bos.

### 4.3 Ledakan Gelombang Kejut Kavitasi (*Cavitation Shockwaves*)
* Saat monster membuka rahangnya untuk meraung atau menyemburkan arus (seperti pada referensi `battle-03-underwater-boss-roar.jpg`):
  * **Cincin Distorsi Layar (*Screen Shockwave Distortion*):** Shader refraksi melingkar membesar cepat dari mulut monster, mendistorsi kolom air dan meretakkan formasi karang terdekat.
  * **Hujan Gelembung Kavitasi:** Ratusan partikel gelembung putih pekat meletup di sepanjang jalur semburan.

### 4.4 Telegraph Serangan Area (*Visual Telegraphing*)
* Bos besar tidak boleh menyerang secara instan tanpa aba-aba:
  * **Garis Pusaran Arus Merah:** Sebelum monster menerjang dengan capit atau ekor, tampilkan garis proyeksi arus merah tipis berkedip selama 0.8–1.2 detik.
  * Pemain memiliki jendela waktu reaksi yang adil untuk menggunakan manuver *Dash* menghindar ke balik celah batu karang aman.

---

## 5. Implementasi Modul Skrip Godot 4 (Web-Ready)

### 5.1 Pengendali Guncangan Kamera (*Camera Shake Controller*)
```gdscript
# camera_shake.gd
extends Camera2D

var trauma: float = 0.0
var trauma_power: int = 2
var max_offset: Vector2 = Vector2(16, 12)
var max_roll: float = 0.05

func add_trauma(amount: float) -> void:
    trauma = clamp(trauma + amount, 0.0, 1.0)

func _process(delta: float) -> void:
    if trauma > 0.0:
        trauma = max(trauma - delta * 1.5, 0.0)
        var shake = pow(trauma, trauma_power)
        rotation = max_roll * shake * randf_range(-1.0, 1.0)
        offset.x = max_offset.x * shake * randf_range(-1.0, 1.0)
        offset.y = max_offset.y * shake * randf_range(-1.0, 1.0)
```

### 5.2 Pengendali Efek Hit Stop Tanpa Merusak Web Thread
```gdscript
# hit_stop.gd
extends Node

func freeze_frame(duration: float = 0.06, time_scale: float = 0.05) -> void:
    Engine.time_scale = time_scale
    await get_tree().create_timer(duration * time_scale, true, false, true).timeout
    Engine.time_scale = 1.0
```

---

## 6. Ringkasan Penerapan untuk Jalasmara

| Momen Permainan | Efek Visual Layar | Efek Partikel & Sprite | Efek Audio |
| :--- | :--- | :--- | :--- |
| **Terkena Serangan Air** | Hit stop 0.06s, trauma camera shake | Flash putih 3 frame, letupan 16 gelembung regulator | Suara benturan berat, desis katup udara bocor |
| **Terkena Serangan Darat** | Screen shake horizontal tajam | Flash merah, squash & stretch sprite, debu tanah | Hantaman fisik kayu/tanah, rontokan dedaunan |
| **Oksigen Kritis (<20%)** | Vignette merah berdenyut, pita peringatan kuning | Aliran gelembung cepat panik, gerak melambat 20% | Suara degup jantung keras, low-pass filter 250Hz, alarm beep |
| **Kemunculan Bos** | Freeze 2.5s, kartu splash halftone komik, letterbox | Siluet monster masif berlatar cipratan tinta | Raungan sub-bass bergemuruh, musik orkestra tegang |
| **Raungan & Semburan Bos** | Cincin gelombang kejut refraksi layar | Semburan awan gelembung kavitasi, batu rontok | Ledakan sonik air, gemeretak karang retak |

