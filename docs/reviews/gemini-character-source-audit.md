# Laporan Koreksi Audit Sumber Karakter Gemini (10 Set, 80 Arah)

Status: **SELESAI (Koreksi Audit Saja)**. Berdasarkan peninjauan integrator pada [gemini-character-audit-integration-review.md](gemini-character-audit-integration-review.md) dan instruksi pada [07b-gemini-character-audit-corrections.md](../plans/07b-gemini-character-audit-corrections.md), laporan audit sebelumnya (`f67de11`) dikoreksi secara menyeluruh. Tidak ada atlas produksi, runtime, physics, engine, atau kode bersama yang dimodifikasi.

---

## 1. Metadata, Lingkungan, dan Batasan Audit

- **Tanggal Koreksi:** 10 November 2026
- **Workspace:** `/Users/ardianryan/Documents/Jalasmara-gemini-day01-audit`
- **Branch:** `work/gemini-day01-audit`
- **Commit Dasar:** `f67de11a9c067ec80cf42ed5fb6cfa9dae4a89e2`
- **Auditor:** Gemini (subagent koreksi audit)
- **Alat dan Versi:**
  - Python 3.9.6
  - Pillow 11.3.0 (lisensi merujuk notice yang sudah ada di [tools/player-gait/LICENSE-Pillow.txt](../../tools/player-gait/LICENSE-Pillow.txt))
  - Git 2.39.5
- **Batas Pengerjaan:**
  - 10 set karakter/pakaian yang diaudit (mencakup 80 pasangan arah berjalan–diam, 640 frame WALK, dan 80 pose IDLE).
  - Dua set `male_nusantara/daily` dan `male_nusantara/explorer` dikecualikan secara eksplisit.
  - Audit offline murni; tidak ada swap baris atlas, mirroring, perbaikan gambar produksi, atau eksekusi engine.

---

## 2. Pencabutan Klaim P0 (False Positive) dan Penjelasan Teknis

### A. Pencabutan 7 Klaim P0 Inversi Arah & 1 Mismatch SE:
Seluruh 7 klaim P0 arah terbalik pada laporan sebelumnya **DICABUT PENUH**:
1. `male_default/daily` NW & NE (keduanya menghadap arah kanonis yang benar, cocok dengan IDLE).
2. `male_default/explorer` NW & NE (keduanya menghadap arah kanonis yang benar, cocok dengan IDLE).
3. `female_default/explorer` NW & NE (keduanya menghadap arah kanonis yang benar, cocok dengan IDLE).
4. `male_nusantara/diving` NW (menghadap kiri, cocok dengan IDLE NW).
5. `male_nusantara/diving` SE (menghadap 3/4 kanan, cocok dengan IDLE SE).

### B. Penyebab Positif Palsu (Tercemarnya Centroid Kulit oleh Bandana):
Detektor warna numerik pada script awal menggunakan filter sederhana `R > 120 and R > B` untuk mengelompokkan piksel "kulit". Pada pakaian penjelajah dan harian, karakter mengenakan ikat kepala/bandana cokelat dengan ekor kain yang berkibar di sisi belakang kepala.
- Pada `female_default/explorer` NW frame 0:
  - Piksel di `(75, 37)` memiliki nilai `[170, 97, 73, 255]`. Nilai ini adalah **ekor bandana cokelat**, bukan kulit!
  - Wajah asli karakter berada di sisi sebaliknya pada `(55, 37) = [166, 128, 92, 255]`.
- Karena `170 > 120` dan `170 > 73`, algoritma keliru menganggap ekor bandana sebagai kulit. Hal ini menggeser titik berat (*centroid*) ke sisi kanan dan menyimpulkan secara keliru bahwa karakter menghadap ke kanan.
- Peninjauan visual resolusi asli membuktikan bahwa wajah tetap berada di sisi kiri (NW menghadap kiri) dan ekor bandana berkibar ke kanan, sepenuhnya konsisten dengan pose IDLE.
- Bukti pembesaran piksel tersimpan pada [docs/visual/gemini-character-source-audit/proof-correction-bandana-face-separation.png](../visual/gemini-character-source-audit/proof-correction-bandana-face-separation.png) dan contact sheet pencabutan pada [docs/visual/gemini-character-source-audit/proof-correction-revocation-nw-ne.png](../visual/gemini-character-source-audit/proof-correction-revocation-nw-ne.png).

---

## 3. Koreksi Hash Masukan dan Inventaris Nyata

Hash masukan yang benar-benar dibaca dari disk pada base `5dd4ac4`:
- `assets/source-2d/nala-eightway-batch/manifest.json`: `21fa13f548ea4d582ec624d3dd6c3162e237dc455366d1c9a0415aa221d49f79` (COCOK).
- `assets/source-2d/nala-daily-eightway/source.json`: `8e65f4e8d22d18060e6b21bf889c558c39631a1c942e66cee65d33e48d9e9c74` (COCOK).
- Seluruh 11 berkas source/repair di `assets/source-2d/` dan 20 berkas atlas PNG di `client-godot/resources/art/player-gait/` terbukti tidak bermutasi (*immutable*).

---

## 4. Tabel Status Koreksi Sepuluh Set (80 Pasangan Arah)

| Identity | Pakaian | Kelengkapan Input | 8 Arah Dicek | P0 Diterima | P0 Dicabut | P1 Dugaan | Status Bersih | Catatan Visual |
| :--- | :--- | :---: | :---: | :---: | :---: | :---: | :---: | :--- |
| `male_default` | `daily` | Lengkap | 8/8 | **0** | 2 | 1 | 7 | NW/NE arah benar. SW frame 7 tumpuan y=99 vs 104 (dugaan variasi baseline). |
| `male_default` | `explorer` | Lengkap | 8/8 | **0** | 2 | 0 | 8 | NW/NE arah benar. Bbox sempit NW (14–17px) adalah proyeksi 2D, bukan stride dunia. |
| `male_default` | `diving` | Lengkap | 8/8 | **0** | 0 | 1 | 7 | SW frame 7 tumpuan y=100 vs 104 (dugaan variasi baseline). |
| `female_default` | `daily` | Lengkap | 8/8 | **0** | 0 | 0 | 8 | Bersih. Seluruh arah konsisten dengan IDLE. |
| `female_default` | `explorer` | Lengkap | 8/8 | **0** | 2 | 0 | 8 | NW/NE arah benar; ekor bandana terpisah dari kulit wajah. |
| `female_default` | `diving` | Lengkap | 8/8 | **0** | 0 | 0 | 8 | Bersih. Tangki modular tidak dibakar ke punggung (sampel North f0). |
| `female_nusantara` | `daily` | Lengkap | 8/8 | **0** | 0 | 0 | 8 | Bersih. Seluruh arah konsisten dengan IDLE. |
| `female_nusantara` | `explorer` | Lengkap | 8/8 | **0** | 0 | 0 | 8 | Bersih. Arah gerak konsisten dengan IDLE. |
| `female_nusantara` | `diving` | Lengkap | 8/8 | **0** | 0 | 0 | 8 | Bersih. Tangki modular tidak dibakar ke punggung (sampel North f0). |
| `male_nusantara` | `diving` | Lengkap | 8/8 | **0** | 1 | 0 | 8 | NW & SE arah benar; klaim inversi dicabut. |

---

## 5. Ledger Visual Eksplisit dan Klarifikasi Keterbatasan

1. **Bukan Stride Fisik:** Lebar bounding box kaki diagonal (12–18 px pada sudut 3/4 serong belakang) merupakan proyeksi ortografis 2D dari sudut pandang kamera, bukan panjang langkah di ruang dunia (*world stride length*). Jangan memperpanjang kaki secara paksa ke 40–52 piksel.
2. **Bukan Bukti Teleportasi Runtime:** Perbedaan ketinggian alpha bawah (misalnya tumpuan telapak kaki frame 7 berada pada y=99 vs y=104 pada South-West `male_default/daily`) adalah observasi data gambar mentah (*image baseline observation*). Hal ini memerlukan peninjauan fase tumpuan dan pivot pada rig, bukan bukti adanya teleportasi atau kontak tanah yang salah pada runtime.
3. **Cakupan Pemeriksaan Gear:** Pengujian kebersihan gear modular (`equipmentBaked: false`) dilakukan secara visual pada sampel tulang punggung arah North frame 0 pakaian selam (tidak ditemukan tangki oksigen atau jala). Seluruh 640 frame pada sudut pandang lain tidak diklaim secara berlebihan dan ditandai *unknown* untuk kepastian penuh.
4. **Unknown yang Dipertahankan:** Anatomi tangan kiri/kanan riil, artikulasi jari/grip, serta adaptasi kemiringan terrain runtime tetap ditandai `unknown` karena berada di luar batas resolusi sprite 2D atau merupakan domain engine 3D.

---

## 6. Perintah Reproduksi dan Uji Otomatis

### Perintah Reproduksi Koreksi:
```sh
cd /Users/ardianryan/Documents/Jalasmara-gemini-day01-audit
python3 tools/player-gait/gemini-source-audit/audit_character_sources.py
python3 tools/player-gait/gemini-source-audit/test_character_audit.py
```

### Hasil Uji CPU Mandiri (6/6 PASS):
```text
PASS: target sets scope verification (10 sets, 2 excluded)
PASS: canonical direction order verification (8 directions)
PASS: output path validation and boundary guards
PASS: audit JSON contents verification and P0 revocations (80 records valid)
PASS: curated gallery size limit (8 images, 357555 bytes = 349.2 KiB <= 1024 KiB)
PASS: source files and production atlases immutability verified with expected hashes

ALL 6 CORRECTED CHARACTER AUDIT TESTS PASSED SUCCESSFULLY.
```

---

## 7. Inventaris Berkas Paket Koreksi

Berkas yang dimodifikasi / ditambahkan berada persis dalam allowlist:
1. `tools/player-gait/gemini-source-audit/audit_character_sources.py` (diperbarui dengan pembatas path ketat, symlink check, fresh run, dan visual ledger)
2. `tools/player-gait/gemini-source-audit/test_character_audit.py` (diperbarui dengan pengujian penolakan review lain, symlink, dan verifikasi pencabutan P0)
3. `docs/reviews/gemini-character-source-audit.json` (inventaris 80 record terkoreksi)
4. `docs/reviews/gemini-character-source-audit.md` (laporan koreksi ini)
5. `docs/visual/gemini-character-source-audit/` (seluruh berkas PNG lama dipertahankan; 2 bukti koreksi baru ditambahkan):
   - `proof-correction-bandana-face-separation.png`
   - `proof-correction-revocation-nw-ne.png`
   - Total ukuran seluruh direktori visual: **357.555 byte (~349,2 KiB)**, jauh di bawah batas 1 MiB.
