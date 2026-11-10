# Review dan Authoring: Loop 8-Frame Upper Body Male Nusantara Explorer SOUTH

## Ringkasan Tugas Kartu C
- **Worktree:** `/Users/ardianryan/Documents/Jalasmara-gemini-day01-art`
- **Branch:** `work/gemini-day01-art`
- **Base Commit:** `a40028c`
- **Lingkup:** Review 41 fill tersembunyi `south-explorer-upper.json`, verifikasi dua endpoint, serta penyusunan dan pengujian proposal loop 8-frame kontinu untuk `male_nusantara` explorer arah SOUTH (`south-explorer-upper-loop.py`).
- **Status:** **PROPOSAL AUTHORED OFFLINE (Kandidat Uji, Bukan Runtime Baru)**

---

## 1. Review 41 Fill Tersembunyi & Dua Endpoint Asli

1. **Review 41 Fill Tersembunyi (`authoredHiddenGarment`):**
   - 41 texel tersembunyi berasal dari baris donor asli pada baris yang sama (`same-row, same-garment`) untuk rompi berpeniti/saku (`vest`), kemeja dalam (`shirt`), dan ikat pinggang (`belt`).
   - Tidak ada piksel warna baru di luar palet asli pakaian explorer; seluruhnya diambil dari donor baris yang sah.
   - Rekomposisi rest asli terbukti identik secara biner terhadap sumber asli (`rest.tobytes() == source.tobytes()`, SHA-256 `a429c378400bd5ac60a45124ac48672b4cb1360beb379cc83297b52ea48ae3b9`).
   - Dua piksel batas kontur terisolasi (`[47, 69]` batas telapak bawah kanan dan `[83, 56]` batas luar lengan kiri) secara eksplisit ditetapkan kepemilikannya ke bagian lengan untuk mencegah kebocoran visual saat lengan bergerak.

2. **Dua Endpoint dan Jangkar Sendi:**
   - **Sendi Jangkar Desain (AUTHORED):**
     - Bahu Kiri: `[78, 49]`, Siku Kiri: `[79, 57]`, Pergelangan Kiri: `[75, 61]`
     - Bahu Kanan: `[53, 49]`, Siku Kanan: `[51, 57]`, Pergelangan Kanan: `[49, 64]`
   - **Endpoint 1 (`original-rest`):** Lengan kiri `(upper=0°, fore=0°)`, Lengan kanan `(upper=0°, fore=0°)`, `behindTorso: []`.
   - **Endpoint 2 (`authored-opposing-endpoint`):** Lengan kiri `(upper=0°, fore=-42°)`, Lengan kanan `(upper=0°, fore=-62°)`, `behindTorso: ['left']`.

---

## 2. Formulasi Loop Kontinu 8-Frame

Loop 8-frame dirancang dengan oposisi simetris harmonis antara tungkai atas kiri dan kanan:
- **Konvensi Arah:** Pada pandangan SOUTH (menghadap kamera), anatomical LEFT berada di sisi kanan pengamat (viewer-right), dan anatomical RIGHT berada di sisi kiri pengamat (viewer-left).
- **Kedalaman (Occlusion):** Lengan kiri berayun ke belakang torso (`behindTorso: ['left']`), sedangkan lengan kanan berayun di depan torso.
- **Envelope Gerak:**
  - Lengan Kiri: `upperSinDeg = -2°`, `foreMeanDeg = -21°`, `foreCosDeg = 21°` (rentang ayunan siku: $0° \to -42°$).
  - Lengan Kanan: `upperSinDeg = 2°`, `foreMeanDeg = -31°`, `foreCosDeg = -31°` (rentang ayunan siku: $-62° \to 0°$).
- **Matriks Ayunan 8 Frame:**
  - Frame 0: Kiri $(0.0°, 0.0°)$, Kanan $(0.0°, -62.0°)$ — Kiri di rest/ekstensi, Kanan ayunan depan maksimum.
  - Frame 1: Kiri $(-1.4°, -6.2°)$, Kanan $(1.4°, -52.9°)$
  - Frame 2: Kiri $(-2.0°, -21.0°)$, Kanan $(2.0°, -31.0°)$ — Transisi titik tengah.
  - Frame 3: Kiri $(-1.4°, -35.9°)$, Kanan $(1.4°, -9.1°)$
  - Frame 4: Kiri $(0.0°, -42.0°)$, Kanan $(0.0°, 0.0°)$ — Kiri ayunan depan maksimum, Kanan di rest/ekstensi.
  - Frame 5: Kiri $(1.4°, -35.9°)$, Kanan $(-1.4°, -9.1°)$
  - Frame 6: Kiri $(2.0°, -21.0°)$, Kanan $(-2.0°, -31.0°)$ — Transisi titik tengah balik.
  - Frame 7: Kiri $(1.4°, -6.2°)$, Kanan $(-1.4°, -52.9°)$ — Membungkus mulus kembali ke Frame 0.

---

## 3. Hasil Verifikasi dan Tes Otomatis

File tes: `tools/player-gait/gemini-day01/test_south_explorer_upper_loop.py` (5/5 PASS, 1.516s):
1. `test_schema_and_spec_validation`: Validasi skema, SHA-256 spec explorer atas (`757f811d8f0dd71d965861b2f32c642c6d205f95b920e6de4231b6e1ce77f8a5`), penolakan jumlah frame tidak sama dengan 8, dan penolakan sudut di luar amplop $\pm 3°$.
2. `test_pose_angles_and_opposing_bounds`: Memverifikasi oposisi sempurna antara frame 0 dan frame 4, serta batas sudut siku yang tidak melebihi jangkauan anatomis.
3. `test_connected_components_across_all_frames`: Memverifikasi bahwa pada **seluruh 8 frame**, lengan kiri dan kanan **masing-masing membentuk tepat 1 komponen piksel utuh yang terhubung** (tanpa pulau piksel 1-texel yang terlepas atau robek akibat rotasi nearest-neighbor).
   - Lengan kiri: 1 komponen ($147 \le \text{texel} \le 153$).
   - Lengan kanan: 1 komponen ($140 \le \text{texel} \le 150$).
4. `test_gear_contract_invariants`: Memverifikasi kontrak gear: `newNodes == 0`, `newSatchelPixels == 0`, `atlasVestMeshEnabled == false`, `tankNetEnabled == false`. Tas selempang (satchel) tetap merupakan attachment terpisah dan tidak digabungkan ke atlas tubuh.
5. `test_export_artifacts`: Memverifikasi seluruh artefak review, kontak sheet, detail sheet, dan preview animasi APNG berhasil diekspor tanpa eror.

---

## 4. Galeri Bukti Visual

Pilihan artefak visual telah dikurasi dan disimpan ke `docs/visual/`:
- `docs/visual/south-explorer-upper-eight-strip.png` (18.043 byte / ~17,6 KiB): Strip 8 frame kontinu pada skala 3x.
- `docs/visual/south-explorer-upper-loop-preview.png` (17.391 byte / ~17,0 KiB): Animasi APNG 8 frame pada 100ms per frame.

Total tambahan visual tracked: ~34,6 KiB (jauh di bawah batas harian 8 MiB).

---

## 5. Batasan dan Status Runtime
- **Tidak ada modifikasi atlas produksi:** File `male-nusantara-explorer-walk-8way-v1.png` tidak dimodifikasi.
- **Kandidat Offline:** Model ini adalah model kinematik rotasi 2D potongan kaku (rigid cutouts) untuk review visual, belum dikaitkan ke kontak kaki/stride cadence di runtime game.
- **Upper Runtime Baru Diterima:** 0 (Tetap mengikuti aturan ketat: tidak ada upper baru yang diintegrasikan ke runtime tanpa pengujian native sequence dan acceptance terpisah).
