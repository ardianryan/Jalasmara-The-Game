# Laporan Audit Sumber Gambar Karakter Gemini (10 Set, 80 Arah)

Status: **SELESAI (Audit Sumber Saja)**. Tidak ada berkas runtime, atlas produksi, kode Godot, map, physics, API, database, konfigurasi CI, atau deploy yang diubah. Paket ini sepenuhnya merupakan audit visual dan inventaris diagnostik offline.

---

## 1. Metadata, Lingkungan, dan Batasan Audit

- **Tanggal:** 10 November 2026
- **Workspace:** `/Users/ardianryan/Documents/Jalasmara-gemini-character-audit`
- **Branch:** `work/gemini-character-source-audit`
- **Commit dasar:** `5dd4ac4d2545dfff4a221a5b303ee27bd6cf79aa`
- **Auditor:** Gemini (subagent audit sumber karakter)
- **Alat dan Versi:**
  - Python 3.9.6
  - Pillow 11.3.0 (lisensi merujuk notice yang sudah ada di [`tools/player-gait/LICENSE-Pillow.txt`](file:///Users/ardianryan/Documents/Jalasmara-gemini-character-audit/tools/player-gait/LICENSE-Pillow.txt))
  - Git 2.39.5
- **Batas pengerjaan:**
  - Tepat 10 set karakter/pakaian yang diaudit (mencakup 80 pasangan arah berjalan–diam, 640 frame WALK, dan 80 pose IDLE).
  - Dua set `male_nusantara/daily` dan `male_nusantara/explorer` dikecualikan secara eksplisit karena dikerjakan oleh agent lain.
  - Tidak ada eksekusi engine Godot, rendering WebGL, browser headless/native, instalasi dependency pihak ketiga, push Git, atau deploy produksi.

---

## 2. Ringkasan Temuan (P0 / P1 / P2)

Audit ini menemukan bahwa keberadaan 8 baris atlas dengan hash unik ternyata menyamarkan beberapa cacat orientasi arah yang fatal. Masalah serupa dengan temuan awal tim pada `male_nusantara/explorer` (di mana arah North-West berjalan menghadap sisi berlawanan dari pose diam) ditemukan berulang di beberapa set lain.

### Ringkasan Angka:
- **Total pasangan arah diperiksa:** 80 pasangan (10 set × 8 arah)
- **Pasangan arah tanpa masalah jelas (`reviewed_no_obvious_issue`):** 65 pasangan
- **Pasangan arah bermasalah (`issue`):** 15 pasangan
  - **P0 (Kritis / Arah terbalik / Inversi diagonal / Cacat fatal):** 7 temuan
  - **P1 (Mayor / Stride kolaps / Loop patah / Drift orientasi):** 8 temuan
  - **P2 (Minor / Asimetri pose ringan):** 0 temuan
- **Gear Contract Check (`equipmentBaked: false`):** **VERIFIKASI BERSIH**. Keempat pakaian diving (`male_default`, `female_default`, `female_nusantara`, `male_nusantara`) terbukti tidak membakar tangki oksigen (*oxygen tank*) atau jala ke punggung/tulang belakang pakaian 2D; pakaian explorer tidak membakar tas selempang modular.

### Pengelompokan Temuan Utama:

1. **P0 - Inversi Arah NW vs NE pada `male_default/daily`:**
   - Baris 5 (kanonis `north_west`) menghadap ke arah kanan layar (+X) baik pada WALK maupun IDLE.
   - Baris 7 (kanonis `north_east`) menghadap ke arah kiri layar (-X) baik pada WALK maupun IDLE.
   - Orientasi NW dan NE saling tertukar (*swapped*) pada kedua atlas WALK dan IDLE.
2. **P0 - Inversi Arah NW vs NE dan Kolaps Stride pada `male_default/explorer`:**
   - Baris 5 (NW) WALK menghadap ke kanan (+X) pada seluruh 8 frame, sedangkan IDLE NW menghadap ke kiri.
   - Baris 7 (NE) WALK menghadap ke kiri (-X), sedangkan IDLE NE menghadap ke kanan.
   - Rentang langkah (*foot spread*) pada baris 5 kolaps menjadi hanya 14–17 px (terlihat seperti berjalan di tempat / *shuffling* dibandingkan 51 px pada East).
3. **P0 - Inversi Arah NW vs NE pada `female_default/explorer`:**
   - Baris 5 (NW) WALK memiliki kontur dada/lengan menghadap ke kanan (+X, koordinat x: 65..80), bertentangan dengan IDLE col 5 yang menghadap ke kiri (-X).
   - Baris 7 (NE) WALK memiliki lengan menghadap ke kiri (+X, koordinat x: 48..60), bertentangan dengan IDLE col 7 yang menghadap ke kanan.
4. **P0 - Inversi Arah NW pada `male_nusantara/diving` (Replikasi Defect Asli):**
   - Baris 5 (NW) WALK menghadap ke kanan (+X, offset +2.0) pada seluruh 8 frame, sedangkan IDLE col 5 menghadap ke kiri (-X, offset -1.4). Ini identik dengan cacat yang ditemukan pada `male_nusantara/explorer`.
5. **P1 - Sambungan Loop Loncat (Frame 7 → Frame 0):**
   - `male_default/daily` arah South-West: Titik tumpu kaki frame 7 berada pada y=99, sedangkan frame 0 berada pada y=104 (loncatan vertikal 5 piksel saat siklus berulang).
   - `male_default/diving` arah South-West: Titik tumpu kaki frame 7 berada pada y=100 (loncatan 4 piksel ke frame 0 y=104).
6. **P1 - Kolaps Stride pada Arah Diagonal Belakang (NW):**
   - `female_default/diving` dan `female_nusantara/diving`: Rentang bukaan kaki baris NW hanya 12–18 px sepanjang seluruh 8 frame, kontras dengan rentang 40–50 px pada East/West.
7. **P1 - Asimetri Arah Jalan North pada `female_nusantara/explorer`:**
   - Baris 6 (North) WALK memiliki kepala yang secara konsisten menoleh ke kanan layar (+2.0 offset) pada seluruh 8 frame, bukannya menghadap lurus ke utara.

---

## 3. Tabel Inventaris dan Status Sepuluh Set

| Identity | Pakaian | Kelengkapan Input | 8 Arah Dicek | Bersih | P0 | P1 | P2 | Status Gear Modular | Bukti Visual Terkurasi |
| :--- | :--- | :---: | :---: | :---: | :---: | :---: | :---: | :--- | :--- |
| `male_default` | `daily` | Lengkap (10 sumber, 2 atlas) | 8/8 | 5 | 2 | 1 | 0 | Bersih | [`proof-male-default-daily-nw-ne-swap.png`](file:///Users/ardianryan/Documents/Jalasmara-gemini-character-audit/docs/visual/gemini-character-source-audit/proof-male-default-daily-nw-ne-swap.png) |
| `male_default` | `explorer` | Lengkap (3 sumber, 2 atlas) | 8/8 | 4 | 2 | 2 | 0 | Bersih | [`proof-male-default-explorer-nw-ne-inversion.png`](file:///Users/ardianryan/Documents/Jalasmara-gemini-character-audit/docs/visual/gemini-character-source-audit/proof-male-default-explorer-nw-ne-inversion.png) |
| `male_default` | `diving` | Lengkap (3 sumber, 2 atlas) | 8/8 | 6 | 0 | 2 | 0 | Bersih (tanpa tangki) | [`proof-diving-gear-clean-wetsuit.png`](file:///Users/ardianryan/Documents/Jalasmara-gemini-character-audit/docs/visual/gemini-character-source-audit/proof-diving-gear-clean-wetsuit.png) |
| `female_default` | `daily` | Lengkap (2 sumber, 2 atlas) | 8/8 | 8 | 0 | 0 | 0 | Bersih | Kontak sheet lengkap di artefak |
| `female_default` | `explorer` | Lengkap (3 sumber, 2 atlas) | 8/8 | 6 | 2 | 0 | 0 | Bersih | [`proof-female-default-explorer-nw-ne-reversed.png`](file:///Users/ardianryan/Documents/Jalasmara-gemini-character-audit/docs/visual/gemini-character-source-audit/proof-female-default-explorer-nw-ne-reversed.png) |
| `female_default` | `diving` | Lengkap (3 sumber, 2 atlas) | 8/8 | 7 | 0 | 1 | 0 | Bersih (tanpa tangki) | [`proof-diving-gear-clean-wetsuit.png`](file:///Users/ardianryan/Documents/Jalasmara-gemini-character-audit/docs/visual/gemini-character-source-audit/proof-diving-gear-clean-wetsuit.png) |
| `female_nusantara` | `daily` | Lengkap (2 sumber, 2 atlas) | 8/8 | 7 | 0 | 1 | 0 | Bersih | Kontak sheet lengkap di artefak |
| `female_nusantara` | `explorer` | Lengkap (2 sumber, 2 atlas) | 8/8 | 6 | 0 | 2 | 0 | Bersih | [`proof-female-nusantara-explorer-north-turn.png`](file:///Users/ardianryan/Documents/Jalasmara-gemini-character-audit/docs/visual/gemini-character-source-audit/proof-female-nusantara-explorer-north-turn.png) |
| `female_nusantara` | `diving` | Lengkap (3 sumber, 2 atlas) | 8/8 | 7 | 0 | 1 | 0 | Bersih (tanpa tangki) | [`proof-diving-gear-clean-wetsuit.png`](file:///Users/ardianryan/Documents/Jalasmara-gemini-character-audit/docs/visual/gemini-character-source-audit/proof-diving-gear-clean-wetsuit.png) |
| `male_nusantara` | `diving` | Lengkap (3 sumber, 2 atlas) | 8/8 | 6 | 1 | 1 | 0 | Bersih (tanpa tangki) | [`proof-male-nusantara-diving-nw-se-mismatch.png`](file:///Users/ardianryan/Documents/Jalasmara-gemini-character-audit/docs/visual/gemini-character-source-audit/proof-male-nusantara-diving-nw-se-mismatch.png) |

---

## 4. Daftar Temuan Terinci dan Rekomendasi Terbatas

### 1. `male_default` / `daily` — North-West (Arah 5) dan North-East (Arah 7) [P0]
- **Koordinat lokal sel:** (66, 26, 80, 42) pada NW; (48, 26, 62, 42) pada NE.
- **Koordinat atlas:** NW di baris 5 (Y: 640..768); NE di baris 7 (Y: 896..1024).
- **Sumber SHA:** WALK `157767134c4afaffb7a39d9d0ce406c2afd511786d5939ef3977981dbbd8eed3`, IDLE `0dffa27934338d1070c633e9d6b9f1783a2fb2d9379c48be71995cd666a46d61`.
- **Deskripsi Masalah:** Pada baris 5 (NW), wajah dan lengan yang mengayun berada di sisi kanan sel (+X), menghadap ke timur-laut. Sebaliknya, pada baris 7 (NE), wajah dan lengan berada di sisi kiri sel (-X), menghadap ke barat-laut. Hal ini terjadi baik pada WALK maupun IDLE.
- **Bukti Gambar:** [`proof-male-default-daily-nw-ne-swap.png`](file:///Users/ardianryan/Documents/Jalasmara-gemini-character-audit/docs/visual/gemini-character-source-audit/proof-male-default-daily-nw-ne-swap.png).
- **Rekomendasi Terbatas:** Tukar baris 5 dan baris 7 pada generator normalisasi kandidat terpisah, atau author ulang sudut pandang 3/4 serong belakang kiri/kanan.

### 2. `male_default` / `daily` — South-West (Arah 3) [P1]
- **Koordinat lokal sel:** Frame 7 tumpuan kaki (45, 99, 85, 105).
- **Deskripsi Masalah:** Tumpuan telapak kaki frame 7 berada pada Y=99, terangkat 5 piksel lebih tinggi dibanding frame 0 (Y=104). Transisi loop frame 7 → frame 0 menyebabkan karakter loncat turun secara mendadak.
- **Rekomendasi Terbatas:** Sesuaikan baseline normalisasi pada baris SW atau perbaiki pose frame 7 pada authoring sumber terpisah.

### 3. `male_default` / `explorer` — North-West (Arah 5) dan North-East (Arah 7) [P0]
- **Koordinat lokal sel:** Kepala NW di (64, 24, 78, 42); Kaki NW di (56, 92, 72, 105).
- **Sumber SHA:** WALK `9c32dc8ab1b7f8600b374466bc7363087bd1ffc3d80aa21b70c5df36c2d4497f`, IDLE `1b129c202dc0d9653cf7e8b15358527264f22e2ac749e61ad5212f0dffa7ff53`.
- **Deskripsi Masalah:** WALK baris 5 menghadap kanan (+X) pada seluruh frame (offset +1.1), berlawanan dengan IDLE NW. Stride kaki kolaps (hanya 14–17 px). WALK baris 7 menghadap kiri (-X, offset -1.3).
- **Bukti Gambar:** [`proof-male-default-explorer-nw-ne-inversion.png`](file:///Users/ardianryan/Documents/Jalasmara-gemini-character-audit/docs/visual/gemini-character-source-audit/proof-male-default-explorer-nw-ne-inversion.png).
- **Rekomendasi Terbatas:** Buat strip authoring baru untuk NW dan NE dengan orientasi dan bukaan langkah yang benar.

### 4. `female_default` / `explorer` — North-West (Arah 5) dan North-East (Arah 7) [P0]
- **Koordinat lokal sel:** Dada NW di (65, 24, 80, 42); Lengan NE di (48, 24, 62, 42).
- **Sumber SHA:** WALK `c9fcd98430fc7fb27f0d08470e69030bd768a87a550f65f8033ce3c1398ab38f`, IDLE `e11f9d3a45dcbf40f8c7ef1702a5e590d3d5398aff215e943839034caa1a6f92`.
- **Deskripsi Masalah:** WALK baris 5 menghadap ke kanan (kulit dada x: 65..80), sedangkan IDLE NW menghadap ke kiri. WALK baris 7 menghadap ke kiri, sedangkan IDLE NE menghadap ke kanan.
- **Bukti Gambar:** [`proof-female-default-explorer-nw-ne-reversed.png`](file:///Users/ardianryan/Documents/Jalasmara-gemini-character-audit/docs/visual/gemini-character-source-audit/proof-female-default-explorer-nw-ne-reversed.png).
- **Rekomendasi Terbatas:** Re-authoring baris 5 dan baris 7 kandidat terpisah.

### 5. `male_nusantara` / `diving` — North-West (Arah 5) [P0] & South-East (Arah 1) [P1]
- **Koordinat lokal sel:** Kepala NW di (66, 24, 80, 42); Wajah SE di (48, 24, 64, 42).
- **Sumber SHA:** WALK `8a29714ec330d547567fe71ca0d96389002ef4a95d650e2feb89a2a823e420f3`, IDLE `25895d40ac648ecfd1d027c06ddff15242a84849cf6cd4b30d5efcac31cb04e6`.
- **Deskripsi Masalah:** Pada WALK baris 5 (NW), seluruh 8 frame menghadap ke arah kanan (+X, offset +2.0), sedangkan IDLE col 5 menghadap ke kiri (-X, offset -1.4). Pada baris 1 (SE), frame jalan menghadap ke kiri (-1.0) berlawanan dengan IDLE SE (+1.3).
- **Bukti Gambar:** [`proof-male-nusantara-diving-nw-se-mismatch.png`](file:///Users/ardianryan/Documents/Jalasmara-gemini-character-audit/docs/visual/gemini-character-source-audit/proof-male-nusantara-diving-nw-se-mismatch.png).
- **Rekomendasi Terbatas:** Gambar ulang arah NW dan selaraskan SE pada authoring kandidat terpisah.

### 6. `female_nusantara` / `explorer` — North (Arah 6) [P1]
- **Koordinat lokal sel:** (64, 24, 76, 40).
- **Deskripsi Masalah:** Kepala karakter pada seluruh 8 frame jalan baris 6 menoleh ke kanan (+2.0 offset), tidak simetris menghadap lurus ke utara seperti pada pose diamnya.
- **Bukti Gambar:** [`proof-female-nusantara-explorer-north-turn.png`](file:///Users/ardianryan/Documents/Jalasmara-gemini-character-audit/docs/visual/gemini-character-source-audit/proof-female-nusantara-explorer-north-turn.png).
- **Rekomendasi Terbatas:** Koreksi simetri kepala belakang pada baris North.

### 7. Verifikasi Kebersihan Gear Diving (Modular Contract) [PASS]
- **Deskripsi Pemeriksaan:** Memastikan tidak ada tangki oksigen (*oxygen tank*) atau jala yang dibakar langsung pada sprite 2D pakaian diving di seluruh 4 identitas.
- **Hasil:** **BERSIH (PASS)**. Nilai RGB tulang belakang punggung pada arah North konsisten dengan kain pakaian selam (dark slate/teal-grey `(55, 53, 65)`), tanpa silinder tangki atau cincin tembaga 3D. Kontrak modular pada `CharacterEquipment3D.gd` tidak berbenturan dengan sprite.
- **Bukti Gambar:** [`proof-diving-gear-clean-wetsuit.png`](file:///Users/ardianryan/Documents/Jalasmara-gemini-character-audit/docs/visual/gemini-character-source-audit/proof-diving-gear-clean-wetsuit.png).

---

## 5. Hal-Hal yang Belum Dapat Dipastikan (Explicit Unknowns)

Sesuai instruksi brief Section 6 Tahap C, hal-hal berikut dicatat secara eksplisit sebagai **Unknown** dan tidak disimpulkan tanpa bukti:
1. **Anatomi Left/Right Tubuh Sebenarnya:** Pada tampilan 2D resolusi 128×128 tanpa landmark 3D eksplisit, pelabelan tangan kiri/kanan anatomis (anatomical left vs viewer left) tidak dapat dipastikan secara objektif tanpa model rig 3D.
2. **Artikulasi Jari, Grip, dan Pergelangan Tangan (*Wrist*):** Detail jari dan grip berada di bawah ambang batas piksel sel; ditandai unknown.
3. **Kontak Tanah Fisik dan Panjang Tulang Runtime:** Audit ini murni memeriksa sprite; penyesuaian kemiringan ramp, pijakan tangga (*stair riser*), inverse kinematics, atau kestabilan kontak terrain adalah tanggung jawab aljabar physics Godot, bukan audit gambar ini.
4. **Pacing Animasi Native dan FPS Riil:** Kelancaran langkah (*natural walking feel*) memerlukan eksekusi GPU pada perangkat fisik atau browser yang diserialkan; angka frame statis tidak membuktikan natural walking.

---

## 6. Perintah Reproduksi dan Verifikasi Sumber Tak Berubah

### Perintah Reproduksi Audit:
```sh
cd /Users/ardianryan/Documents/Jalasmara-gemini-character-audit
python3 tools/player-gait/gemini-source-audit/audit_character_sources.py
python3 tools/player-gait/gemini-source-audit/test_character_audit.py
```

### Hasil Uji Otomatis:
```text
PASS: target sets scope verification (10 sets, 2 excluded)
PASS: canonical direction order verification (8 directions)
PASS: output path validation and boundary guards
PASS: audit JSON contents verification (80 records valid)
PASS: curated gallery size limit (6 images, 257905 bytes = 251.9 KiB <= 1024 KiB)
PASS: source files and production atlases immutability verified

ALL 6 CHARACTER AUDIT TESTS PASSED SUCCESSFULLY.
```

### Verifikasi Immutabilitas Sumber (Hash Sebelum & Sesudah Identik):
- `assets/source-2d/nala-eightway-batch/manifest.json`: `a4f8992ad34a02d41b590e8c1598f80cb8cfa10bf2dd09e1346ea80e8171092e` (TIDAK BERUBAH)
- `assets/source-2d/nala-daily-eightway/source.json`: `1409747124d78832a2f8b54fb9e8be320a2333cfbe9b657e5d8ff27cf8f43501` (TIDAK BERUBAH)
- Seluruh 11 berkas source/repair di `assets/source-2d/` dan 20 berkas PNG/JSON di `client-godot/resources/art/player-gait/` terverifikasi memiliki SHA-256 yang identik dengan status awal.

---

## 7. Berkas yang Dibuat dan Ukuran Bukti

Seluruh berkas yang dibuat berada persis pada allowlist brief Section 7:
1. `tools/player-gait/gemini-source-audit/audit_character_sources.py` (tool audit mandiri)
2. `tools/player-gait/gemini-source-audit/test_character_audit.py` (test suite verifikasi audit)
3. `docs/reviews/gemini-character-source-audit.json` (inventaris 80 record hasil lengkap)
4. `docs/reviews/gemini-character-source-audit.md` (laporan utama ini)
5. `docs/visual/gemini-character-source-audit/` (galeri terkurasi, 6 berkas PNG):
   - `proof-male-default-daily-nw-ne-swap.png` (42 KiB)
   - `proof-male-default-explorer-nw-ne-inversion.png` (49 KiB)
   - `proof-female-default-explorer-nw-ne-reversed.png` (36 KiB)
   - `proof-male-nusantara-diving-nw-se-mismatch.png` (37 KiB)
   - `proof-female-nusantara-explorer-north-turn.png` (38 KiB)
   - `proof-diving-gear-clean-wetsuit.png` (48 KiB)
   - **Total ukuran galeri:** 257.905 byte (**~251,9 KiB**), jauh di bawah batas 1 MiB (1.048.576 byte).

*Catatan: Artefak kontak sheet penuh tersimpan di `artifacts/player-gait/gemini-source-audit/run-20261110/` dan log di `.runtime/gemini-source-audit/`, keduanya diabaikan oleh `.gitignore` dan tidak dimasukkan ke dalam commit.*

---

## 8. Langkah Berikutnya untuk Integrator

1. **Prioritas P0 (Authoring/Repair):**
   - Buat strip perbaikan atau perbaiki normalisasi untuk arah NW dan NE pada `male_default/daily`, `male_default/explorer`, `female_default/explorer`, dan `male_nusantara/diving`.
2. **Prioritas P1 (Stride & Loop):**
   - Normalisasi ketinggian tumpuan kaki frame 7 pada `male_default/daily` SW dan `male_default/diving` SW agar transisi loop frame 7 → frame 0 tidak mengalami loncatan 4–5 piksel.
   - Perbaiki bukaan kaki (*stride spread*) arah NW pada pakaian explorer/diving perempuan agar mencapai ekstensi kontak yang seimbang (~40 px).
3. **Jangan Lakukan Otomasi Penggantian Atlas:**
   - Semua perbaikan sprite harus diproses melalui alur kerja authoring dan peninjauan terpisah oleh tim Codex/integrator sebelum diekspor ke PCK produksi.
