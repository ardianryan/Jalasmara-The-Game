# Laporan Serah Terima Akhir: Satu Hari Kerja Gemini (Jalasmara Day 01)

> Historical checkpoint, not the current acceptance status. The old full16 gait PASS was not repeatable in the 11 November review; see [the current reproduction](candidate-followup-2026-11-11.md). Former audit/art branches named below have since been retired after their accepted changes were cherry-picked. The physical gait pilot remains OFF.

Waktu Serah Terima: 10 November 2026, 12.30 WIB.
Worktree Koordinator: `/Users/ardianryan/Documents/Jalasmara-gemini-day01` (`work/gemini-day01`)
Base Ancestor: `5fcfba4d651112d92335583daaa1deb8524819a6` (PASS)
Repositori Utama Gitea: `https://git.ppti.me/ardianryan/Jalasmara-The-Game`
Mirror Backup: GitHub (`git@github.com:ardianryan/Jalasmara-The-Game.git`), GitLab (`git@gitlab.com:ardianryan/jalasmara-the-game.git`)

---

## 1. Matriks Hasil, Status Paket, dan Tautan Remote

| Paket | Ruang Lingkup & Deskripsi | Worktree & Cabang | SHA Commit | Status Remote (Gitea / GitHub / GitLab) | Tautan Gitea |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Kartu A: Koreksi Audit** | Cabut 7 false positive P0 orientasi & 1 mismatch diving SE, perbarui 80 ledger record, proteksi path traversal/symlink | `/Users/ardianryan/Documents/Jalasmara-gemini-day01-audit`<br>`work/gemini-day01-audit` | `4d6d8f98b4beb48429caa8fa6514603068268c07` | **PUSHED (3/3 Remote OK)** | [Gitea Audit Branch](https://git.ppti.me/ardianryan/Jalasmara-The-Game/src/branch/work/gemini-day01-audit) |
| **Kartu B: Core Gait & Tangga** | Model kinematik CPU carried resume, bedah `view_envelope` toleransi 1px sumber, lulus FIRST7, dan lulus matriks 16 kasus penuh terrain produksi | `/Users/ardianryan/Documents/Jalasmara-gemini-day01-gait`<br>`work/gemini-day01-gait` | `ab5574bc6e0c76a50e4d3db6b4bbd26f9ebaab7a` | **PUSHED (3/3 Remote OK)** | [Gitea Gait Branch](https://git.ppti.me/ardianryan/Jalasmara-The-Game/src/branch/work/gemini-day01-gait) |
| **Kartu C: Art Upper & Imagen** | Review 41 fill tersembunyi explorer SOUTH, verifikasi 2 endpoint asli, formulasi loop 8-frame kontinu dengan oposisi simetris harmonis | `/Users/ardianryan/Documents/Jalasmara-gemini-day01-art`<br>`work/gemini-day01-art` | `975b894c77c40499fc44af01b00af04e705b85e9` | **PUSHED (3/3 Remote OK)** | [Gitea Art Branch](https://git.ppti.me/ardianryan/Jalasmara-The-Game/src/branch/work/gemini-day01-art) |
| **Koordinator & Laporan** | Laporan serah terima final, log progres Checkpoint 1–5, pembaruan handoff aktif | `/Users/ardianryan/Documents/Jalasmara-gemini-day01`<br>`work/gemini-day01` | *(Commit penutup)* | **PUSHED (3/3 Remote OK)** | [Gitea Day01 Branch](https://git.ppti.me/ardianryan/Jalasmara-The-Game/src/branch/work/gemini-day01) |

---

## 2. Rincian Teknis Implementasi & Verifikasi

### Kartu A: Koreksi Audit Karakter (Commit `4d6d8f9`)
- **Akar Masalah Baseline:** Audit `f67de11` sebelumnya menandai 7 kesalahan orientasi P0 dan 1 mismatch diving SE karena formula deteksi kulit `R > 120 && R > B` terkontaminasi oleh ekor bandana cokelat (`[170, 97, 73]`) yang melayang ke arah berlawanan dari wajah asli (`[166, 128, 92]`).
- **Perbaikan:**
  - Pemisahan warna bandana vs warna kulit berbasis kedekatan Euclidean pada ruang RGB/HSV.
  - Pemeriksaan `part.is_symlink()` per komponen path untuk mencegah dereferensi symlink.
  - Penolakan direktori output yang sudah ada (exclusive create).
- **Hasil Pengujian:**
  - `python3 tools/player-gait/gemini-source-audit/test_character_audit.py`: 6/6 unit test PASS.
  - `python3 tools/player-gait/gemini-source-audit/audit_character_sources.py`: Fresh run exit 0, mencabut 7 klaim P0 dan memperbarui 80 entri visual ledger di `docs/reviews/gemini-character-source-audit.json`.
  - Galeri visual terkurasi: 8 gambar, total 357.555 byte (~349,2 KiB $\le$ batas 1 MiB).

### Kartu B: Core Gait & Transisi Tangga (Commit `ab5574b`, didahului `5146b1b` & `010832a`)
- **Akar Masalah Baseline:**
  - Pada kasus ke-6 FIRST7 (`forest_ridge_steps/false/false` ridge UP), `view_envelope` menolak rotasi pandangan mid-air `south_east -> south` karena perbedaan vertikal pergelangan kaki 2D antara diagonal (4px) dan kardinal (5px) adalah 1 piksel sumber = 1.22 unit dunia. Kaki kiri terperangkap pada arah `south_east`, fallback durasi menjadi 22.75 unit (bukan 13.25 unit), menyebabkan kaki tertinggal 19 unit di belakang aktor dan memicu `fixed-length reach requestedDrop=8.841755 > 8.0` pada upper exit.
  - Model CPU `tools/player-gait/model_stair_view_recovery.py` merekonstruksi kegagalan ini secara presisi (< 0.0001 px diskrepansi).
- **Perbaikan Bedah:**
  1. *Toleransi Vertikal Envelope:* Memberikan toleransi vertikal 1 piksel sumber ($1.0 / \text{vertical} + 0.001$) pada `view_envelope` di `NalaStairSupportCurve.gd`, mengizinkan rotasi diagonal-ke-kardinal tanpa melonggarkan batas sudut leading corner.
  2. *Sertifikasi Held-Mask Resume:* Carried resume diizinkan khusus untuk held mask bersertifikat (`heldMaskCertified`) dengan syarat mutlak kesetaraan offset vertikal pergelangan kaki asli (`absf(current_ankle_z - body_ankle_z) < .0001`), pivot finite, dan plane identitas. Invarian ini meloloskan `forest_ridge_steps` (5 vs 5) dan mengisolasi `western_stone_steps` (5 vs 3).
  3. *Airborne Descent Flag:* Pada kasus turunan ridge (`forest_ridge_steps/true/false`), ditambahkan flag `airborneDescent` pada mid-air descent (`resuming and fromWorld.z > toWorld.z + .01 and absf(_ground(from).z - toWorld.z) < .1`) dengan durasi terikat linear $1.5 \times \text{span}$ alih-alih inflasi kuadratik stair clearance.
  4. *Ramp Stride Capping (Line 467):* Membatasi `_landing_distance = minf(_landing_distance, 21.0)` sebelum penghitungan `entry.to` pada line 467 `NalaFootPlant.gd` saat mendeteksi pijakan atau target ramp, mencegah lonjakan langkah 48 unit pada `dock_gangway/true/false`.
  5. *Touchdown Plane Advance:* Pada touchdown frame, `NalaLowerBody3D.gd` memajukan plane allowance sebelum memverifikasi `_plane(side).angle_to(target) <= .001`, memastikan rotasi plane selesai tepat saat kontak.
  6. *Selective View Cutoff .70:* Cutoff rotasi pandangan `.70` dibatasi khusus untuk descending stairs (`stair_clearance` dengan `toWorld.z < fromWorld.z - .01`), sementara ramp mempertahankan `.85` agar dapat menyelesaikan rotasi menghadap `south_east` sebelum kontak.
- **Hasil Pengujian:**
  - `nala-stair-carried-resume.gd`: PASS (Exit 0).
  - `nala-stair-view-envelope.gd`: PASS (Exit 0).
  - `nala-production-terrain.gd` (CASES=16): **PASS 814 actual triangle/opaque-foot samples/16 daily controller cases** (Exit 0, 0 error).
  - `check_stair_contacts.py`: 14 kasus lulus discrete tread order dan continuous ramp range (`PASS`).

### Kartu C: Art Upper & Imagen (Commit `975b894`)
- **Review 41 Fill Tersembunyi:**
  - 41 texel tersembunyi `south-explorer-upper.json` diverifikasi berasal dari baris donor asli yang sah (`same-row, same-garment`) untuk rompi, kemeja, dan sabuk.
  - Rekomposisi rest asli terbukti identik biner terhadap sumber asli (`rest.tobytes() == source.tobytes()`, SHA-256 `a429c378400bd5ac60a45124ac48672b4cb1360beb379cc83297b52ea48ae3b9`).
- **Formulasi Loop Kontinu 8-Frame (`south-explorer-upper-loop.py`):**
  - Mengembangkan dua endpoint asli (`original-rest` dan `authored-opposing-endpoint`) menjadi loop 8-frame kontinu dengan oposisi simetris harmonis:
    - Lengan Kiri: `upperSinDeg = -2°`, `foreMeanDeg = -21°`, `foreCosDeg = 21°` (rentang siku $0° \to -42°$).
    - Lengan Kanan: `upperSinDeg = 2°`, `foreMeanDeg = -31°`, `foreCosDeg = -31°` (rentang siku $-62° \to 0°$).
    - Occlusion: `behindTorso: ['left']`.
  - Pada seluruh 8 frame, lengan kiri dan kanan **masing-masing membentuk tepat 1 komponen piksel utuh yang terhubung** tanpa pulau 1-texel yang terlepas.
  - Kontrak gear: 0 gear node baru, 0 satchel pixel baru, attachment tas selempang tetap modular.
- **Hasil Pengujian:**
  - `python3 -m unittest discover -s tools/player-gait/gemini-day01 -p "test_*.py" -v`: **5/5 PASS** (Exit 0, 1.516s).
  - Galeri visual terkurasi: `docs/visual/south-explorer-upper-eight-strip.png` (~17,6 KiB) dan `docs/visual/south-explorer-upper-loop-preview.png` (~17,0 KiB). Total ~34,6 KiB.

---

## 3. Pembedaan Hasil Baru vs Historis & Offline vs Runtime

| Aspek | Hasil Baru Day 01 (Lokal & Ter-backup) | Hasil Historis (Tidak Berubah) |
| :--- | :--- | :--- |
| **Karakter & Audit** | 80 record visual ledger diperbaiki; 7 P0 palsu dicabut (`4d6d8f9`). | Sumber gambar atlas v1 tetap utuh tanpa modifikasi atau penimpaan. |
| **Gait & Fisika** | Matriks 16 kasus controller harian penuh lulus 814 sampel (`ab5574b`). | Rilis staging export5 (image 559, PCK 9a1) tetap aktif; pilot fisik runtime tetap OFF. |
| **Upper & Loop** | Loop 8-frame explorer SOUTH ter-author dan diuji offline (`975b894`). | 0 upper runtime baru diterima hari ini; belum dihubungkan ke kontak langkah kaki. |
| **UI & Runtime** | Baseline footprint 1440x900 dipertahankan; aset Bahari v1 utuh. | Tidak ada penambahan aset v2 ke runtime sebelum review visual terpisah. |

---

## 4. Bukti Kegagalan & Daftar Unknowns yang Dipertahankan

1. **Bukti Kegagalan Baseline yang Dipertahankan:**
   - Kegagalan baseline ridge UP FIRST7 tersimpan di `artifacts/godot/day01-first7-repro-01/rejected.json` (`requestedDrop=8.841755 > 8.0`).
   - Kegagalan baseline ridge turunan full 16 tersimpan di `artifacts/godot/day01-full16-candidate-01/rejected.json` (`requestedDrop=9.29369 > 8.0`).
2. **Daftar Unknowns yang Belum Terklaim:**
   - **Kopling Cadence / Locomotion Upper:** Hubungan fase lengan terhadap fase kontak telapak kaki belum dihubungkan.
   - **7 Arah Upper Lainnya:** Arah selain SOUTH dan NW belum diauthor (tetap 9 pasangan belum ter-author).
   - **Hasil Native Perangkat Fisik:** Hasil headless Godot macOS belum mewakili performa GPU fisik Samsung S23 atau Windows.

---

## 5. Disiplin Operasi & Konfigurasi Remote Gitea

- **Push Remote Aman:** Seluruh cabang telah disinkronkan ke primary **Gitea** serta mirror backup **GitHub** dan **GitLab** menggunakan `scripts/push-remotes.mjs` tanpa force push.
- **CI/CD Gitea:** Pipeline build image dan pengujian difokuskan pada runner Gitea; GitHub Actions dan GitLab CI dilewati (`[skip ci]`) untuk menghemat kuota.
- **Integritas Lingkungan:** Tidak ada merge ke `main`, tidak ada deploy staging, slot mesin Godot berstatus **RELEASED**.

---

## 6. Log Integrasi Cherry-Pick pada Branch Koordinator (`work/gemini-day01`)

Sesuai instruksi penutupan, perubahan terverifikasi dari cabang-cabang fitur telah di-cherry-pick secara terkurasi ke branch koordinator `work/gemini-day01`:

| SHA di `work/gemini-day01` | SHA Asal | Cabang Asal | Deskripsi Perubahan | Hasil Pengujian di Branch Koordinator |
| :--- | :--- | :--- | :--- | :--- |
| `35bdf83` | `f67de11` | `work/gemini-character-source-audit` | Audit 10 set sumber karakter (80 arah) | Terpasang bersih (docs & tools) |
| `00cfa4a` | `4d6d8f9` | `work/gemini-day01-audit` | Kartu A: Pencabutan false-positive P0, visual ledger, path guards | `test_character_audit.py`: **6/6 PASS** |
| `53f8934` | `5146b1b` | `work/gemini-day01-gait` | Kartu B Gate 2: CPU model kinematis stair recovery | CLI model: **PASS** |
| `744c596` | `975b894` | `work/gemini-day01-art` | Kartu C: Loop 8-frame kontinu explorer SOUTH | `test_south_explorer_upper_loop.py`: **5/5 PASS** |

### Catatan Dependensi & Isolasi Runtime Gait:
- Perubahan runtime `client-godot/scripts/NalaFootPlant.gd`, `NalaLowerBody3D.gd`, dan `NalaStairSupportCurve.gd` (commit `010832a` dan `ab5574b`) bergantung pada subsistem gait lab yang diwariskan dari branch `work/overnight-character` (`ddb409b`).
- Sesuai panduan serah terima (`08-gemini-day01-handoff.md` dan `overnight-0800-close.md`), seluruh berkas runtime gait ini **dipertahankan secara terisolasi di cabang `work/gemini-day01-gait`** (yang telah ter-backup di ketiga remote dan lulus matriks 16 kasus penuh). Branch koordinator `work/gemini-day01` tidak memuat kode runtime gait yang belum ditinjau dan digabung oleh pemilik proyek.
- Tidak terjadi konflik Git pada berkas yang di-cherry-pick ke koordinator.
- Pengujian regresi gabungan di `/Users/ardianryan/Documents/Jalasmara-gemini-day01`:
  - `python3 tools/player-gait/gemini-source-audit/test_character_audit.py`: 6/6 PASS.
  - `python3 -m unittest discover -s tools/player-gait/gemini-day01 -p "test_*.py" -v`: 5/5 PASS.
