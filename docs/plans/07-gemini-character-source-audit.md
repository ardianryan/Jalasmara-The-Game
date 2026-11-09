# Brief Gemini: audit sprite karakter tanpa mengubah game aktif

Tanggal: 10 November 2026. Pemilik integrasi: Codex/root. Paket ini merupakan pekerjaan terpisah untuk Gemini, bukan instruksi mengambil alih pekerjaan agent lain.

## 1. Hasil yang diminta

Temukan masalah **sumber gambar** pada karakter/pakaian yang belum sedang dikerjakan tim Codex. Hasilnya berupa laporan dengan bukti piksel, inventaris JSON, dan contact sheet yang dapat direproduksi. Jangan memperbaiki game atau mengganti sprite produksi dalam paket ini.

Alasan tugas ini penting: tim menemukan `male_nusantara/explorer` WALK arah `north_west` menghadap sisi berbeda dari IDLE arah yang sama. Keberadaan delapan baris atlas dan delapan hash berbeda ternyata tidak cukup untuk membuktikan delapan arah yang benar. Kita perlu memeriksa set lain sebelum membuat rig/animasi baru di atas sumber yang salah.

Selesai berarti seluruh set dalam daftar berikut sudah mempunyai hasil audit dan bukti. Selesai **tidak berarti** seluruh artwork benar, natural walking selesai, atau masalah sudah tampil membaik di staging.

## 2. Worktree dan branch khusus

Gunakan hanya workspace berikut yang disiapkan integrator:

```text
/Users/ardianryan/Documents/Jalasmara-gemini-character-audit
branch: work/gemini-character-source-audit
```

Sebelum bekerja, jalankan:

```sh
pwd
git branch --show-current
git status --short
```

Hentikan perubahan jika cwd/branch berbeda. Jangan `git switch`, reset, checkout paksa, rebase, merge, stash, membersihkan worktree, atau menghapus berkas untuk membuat kondisi terlihat bersih. Jika ada perubahan yang bukan milik Gemini, catat dan biarkan. Jangan memakai workspace main, integration, character, contact-audio, atau ground-consumers untuk menulis apa pun.

Baca `AGENTS.md`, `docs/agent-handoff.md`, `docs/PRD.md`, `docs/art-direction-comfy.md`, serta brief ini. Status runtime tetap mengikuti handoff; data dalam laporan lama tidak otomatis berlaku untuk rilis terbaru.

## 3. Pembagian kepemilikan yang wajib dipertahankan

| Area | Pemilik saat brief dibuat | Aturan untuk Gemini |
| --- | --- | --- |
| Physics, pijakan, tangga, motion/root, contact trace Nala | Agent character + peer shelter | Boleh membaca; jangan mengubah atau menjalankan engine |
| `male_nusantara/daily` dan `male_nusantara/explorer`, termasuk SOUTH/NW upper art | Agent website/art | Boleh membaca sebagai pembanding; jangan mengerjakan ulang, mengganti, atau membuat mask tandingan |
| HUD, dialog, website/loading, API, database, release | Integrator | Jangan diubah |
| Sepuluh set dalam bagian 4 | Gemini untuk audit sumber saja | Buat output baru dalam direktori milik paket ini |

Tidak ada file runtime bersama yang boleh diedit. Temuan yang menyentuh pekerjaan agent lain cukup dicatat dengan koordinat/pin sumber dan diserahkan kepada integrator.

## 4. Daftar set yang HARUS diaudit

| Identity | Pakaian |
| --- | --- |
| `male_default` | `daily`, `explorer`, `diving` |
| `female_default` | `daily`, `explorer`, `diving` |
| `female_nusantara` | `daily`, `explorer`, `diving` |
| `male_nusantara` | `diving` saja |

Total **10 set, 80 pasangan arah WALK/IDLE, 640 frame WALK dan 80 pose IDLE**. Set `male_nusantara/daily` dan `male_nusantara/explorer` sengaja dikecualikan karena sedang dikerjakan agent lain.

Jangan menambah NPC, pakaian, karakter, sistem inventori, atau fitur baru. Jangan memperluas tugas ke bangunan, map, laut, shader, atau integrasi tool.

## 5. Sumber yang dibaca

- `assets/source-2d/nala-eightway-batch/manifest.json`: identitas, pakaian, sumber, output, arah, pivot dan hash terdahulu.
- `assets/source-2d/nala-eightway-batch/*-source.png`, `*-idle24.png`, serta berkas repair yang memang disebut manifest: sumber authoring. Baca; jangan tulis ulang.
- `client-godot/resources/art/player-gait/*-walk-8way-v1.png`: atlas WALK yang dipakai runtime.
- `client-godot/resources/art/player-gait/*-idle-8way-v1.png`: atlas IDLE yang dipakai runtime.
- `tools/player-gait/prepare_outfit.py`, `prepare_idle_outfits.py`, `test_eightway.py`: pahami cara normalisasi dan pemeriksaan yang sudah ada. **Jangan menjalankan generator dengan output ke direktori produksi dan jangan mengubah tool ini.**
- `client-godot/scripts/CharacterVisual.gd`: baca `_load_directional`, pemilihan arah/frame, pakaian dan `get_equipment_state`.
- `client-godot/scripts/CharacterEquipment3D.gd` dan `docs/reviews/overnight-wardrobe-gear-audit.md`: hanya untuk memahami kontrak gear. Pemeriksaan kode bukan bukti node/mesh terlihat.

Untuk set yang diperiksa sekarang, WALK terukur 1024×1024, sel 128×128, delapan baris arah dan delapan kolom frame. IDLE terukur 1024×128, delapan sel arah horizontal. Tetap baca dimensi aktual dan tolak input yang berbeda; jangan meresize diam-diam agar cocok.

Urutan arah kanonis:

```text
0 east
1 south_east
2 south
3 south_west
4 west
5 north_west
6 north
7 north_east
```

Pada WALK, index arah memilih baris. Pada IDLE, index arah memilih kolom. Jangan menukar aturan ini. Ejaan identity pada runtime memakai underscore; stem nama PNG memakai hyphen, sesuai loader yang sebenarnya.

Keterangan manifest seperti `drawnDirections: 8`, `equipmentBaked: false`, atau `review: visually inspected` adalah klaim sumber untuk dibandingkan dengan gambar aktual, **bukan hasil audit otomatis yang boleh disalin sebagai PASS**.

## 6. Urutan pengerjaan

### Tahap A: bekukan inventaris

1. Catat commit workspace dan daftar persis sepuluh set.
2. Hash SHA-256 setiap source/manifest/atlas terkait sebelum audit; catat dimensi, jumlah sel, mode gambar dan rentang alpha.
3. Simpan salinan data hasil pembacaan dalam JSON audit. Jangan menyalin/menimpa source asli.
4. Jika sumber tidak ada, hash berbeda dari manifest, atau format tidak sesuai, catat sebagai temuan. Jangan mencari gambar internet atau menjalankan generator untuk menutup kekurangan.

### Tahap B: buat bukti perbandingan

Untuk setiap set, buat contact sheet yang memperlihatkan:

- Delapan arah WALK frame0 bersebelahan dengan delapan arah IDLE sesuai label yang sebenarnya.
- Seluruh frame0–7 untuk setiap arah yang mencurigakan, termasuk sambungan frame7→0.
- Detail kepala, badan atas, kedua kaki dan aksesori yang relevan. Gunakan nearest-neighbor dan grid/koordinat bila dibutuhkan; beri label bahwa ini pembesaran/crop diagnostik.
- Perbandingan yang berlawanan, misalnya NW versus NE dan E versus W, tanpa memirror salah satunya.

Nomor frame/arah pada label harus berasal dari indeks atlas, bukan ditebak dari rupa gambar. Jangan menukar sel ketika menyusun sheet supaya hasil tampak benar.

### Tahap C: audit visual dan angka

Isi satu record untuk **setiap 80 pasangan arah**, dengan status `reviewed_no_obvious_issue`, `issue`, atau `unknown`. Status tanpa masalah berarti tidak terlihat masalah pada cakupan gambar tersebut; bukan natural walking PASS.

Periksa hal-hal berikut:

1. **Arah:** kepala/hidung/telinga, punggung/dada dan bahu WALK sesuai IDLE serta label kanonis. NW dan NE tidak boleh otomatis dianggap benar hanya karena hash berbeda. Perspektif tubuh lebih penting daripada label file.
2. **Transisi jalan–diam:** identitas, rambut/ikat kepala, kontur bahu, outfit dan sisi aksesori tidak tiba-tiba berganti. Perbedaan pose sendiri bukan kesalahan arah.
3. **Seluruh delapan frame:** cari kepala atau torso yang berbalik di tengah loop, lengan saling bertukar, bagian tubuh terpotong, dan loncatan frame7→0.
4. **Kaki:** cari bentuk gunting, telapak menyilang tidak masuk akal, tungkai melar/menghilang dan kontak visual yang meragukan. Ini audit sprite saja; jangan menyimpulkan kontak dengan terrain atau panjang tulang runtime.
5. **Pakaian:** warna/rompi/sabuk/pocket tetap konsisten, tidak berpindah ke telapak, tidak berganda, tidak meninggalkan fragmen terpisah ketika pose berubah.
6. **Gear:** bedakan detail kain yang memang ada pada baju dari tas/tabung/jala yang seharusnya terpisah. Jika gambar terlihat membakar gear ke tubuh, catat koordinat dan alasan; jangan mengubah flag runtime agar dua gambar terlihat lolos.
7. **Alpha/atlas:** bagian tubuh menyentuh batas sel, terpotong, transparansi ganjil atau pulau piksel terpisah. Angka connected-component dan bounding box hanyalah sinyal; inspect gambar sebelum memberi makna anatomis.
8. **Pengulangan:** hash identik antararah/frame atau beda yang sangat kecil menjadi penanda untuk diperiksa. Hash unik tidak membuktikan arah/anatomi benar. Jangan memasang threshold kemiripan sebagai pengganti keputusan visual.

Untuk setiap `issue`, tulis identity/outfit/arah/frame, koordinat **lokal sel 128×128**, koordinat atlas bila perlu, sumber SHA, screenshot bukti dan penjelasan singkat. Jika menyebut warna, catat RGBA piksel asli. Pisahkan masalah pasti dari dugaan.

Anatomical left/right, wrist, grip dan joint yang tidak terbukti harus `unknown`. Jangan memakai aturan SOUTH viewer-right untuk rear/NW tanpa bukti. Jangan membuat landmark/joint karangan lalu menyebutnya hasil pengukuran sumber.

### Tahap D: rekomendasi tanpa penerapan

Kelompokkan temuan:

- **P0:** arah/identitas terbalik, bagian tubuh hilang/berpindah, gear ganda yang jelas.
- **P1:** loop jalan–diam atau sambungan frame terlihat patah, kaki/lengan meragukan, clipping yang mengganggu.
- **P2:** detail shading/outline/palet yang layak dirapikan.

Untuk setiap temuan, usulkan satu tindakan terbatas: gambar ulang bagian tertentu, authoring satu arah, perbaikan normalisasi pada kandidat terpisah, atau investigasi lebih lanjut. Sertakan alasan mengapa tindakan itu relevan. **Jangan menerapkannya dalam paket audit ini.**

Jika solusi memerlukan gambar baru, mirror, pergantian baris, perubahan rig, update metadata produksi atau regenerasi atlas, tulis sebagai usulan untuk integrator. Jangan lakukan otomatis setelah audit selesai.

## 7. Berkas yang boleh DIBUAT

Hanya path baru berikut:

```text
tools/player-gait/gemini-source-audit/             # tool/test CPU baru bila diperlukan
docs/reviews/gemini-character-source-audit.md      # laporan utama
docs/reviews/gemini-character-source-audit.json    # inventaris dan 80 record hasil
docs/visual/gemini-character-source-audit/         # pilihan bukti kecil; total <= 1 MiB
artifacts/player-gait/gemini-source-audit/<run-id>/ # output lengkap, ignored, jangan commit
.runtime/gemini-source-audit/                     # log lokal milik paket ini, jangan commit
```

Script baru harus membuka atlas/source sebagai input saja, menolak output di direktori runtime/source dan tidak mengikuti symlink output keluar folder miliknya. Gunakan direktori run baru; jangan menimpa artefak review lama.

Jangan mengubah README/AGENTS/PRD/handoff/CI bersama. Tulis rekomendasi pembaruannya di laporan; integrator yang menerapkannya.

## 8. Larangan eksplisit

- Jangan menulis ke `client-godot/`, `assets/source-2d/`, `packages/`, `apps/`, tool/test yang sudah ada, lockfile atau konfigurasi CI/deploy.
- Jangan mengubah `.import`, `.uid`, source atlas, mask, palette, pivot, direction mapping, collision, terrain, outfit/gear state atau runtime flag.
- Jangan membuka/memakai akun owner, `.env`, token/key, save pemain, Mongo/Redis, VPS, SSH, Docker, GitLab runner atau API produksi.
- Jangan menjalankan Godot/import/export/native render/browser/WebGL atau build aplikasi. Slot engine/browser sedang diserialkan integrator. Audit ini cukup Python/Pillow dan inspeksi gambar lokal.
- Jangan memasang package/plugin/MCP, mengunduh sprite/tool, memakai API berbayar atau memakai key dari chat. Tidak perlu SpriteAI/Imagen untuk audit ini.
- Jangan menghapus cache, build, worktree, log atau artefak agent lain. Penghematan storage dikelola integrator.
- Jangan commit `node_modules`, `.runtime`, artefak mentah, sumber PNG produksi duplikat, kredensial atau seluruh atlas.
- Jangan push/merge/deploy. Serahkan commit lokal pada branch khusus; integrator melakukan cherry-pick dan push.

Python/Pillow yang sudah terpasang boleh digunakan. Jika interpreter/dependensi tidak tersedia, catat kebutuhan tersebut tanpa menginstal atau memodifikasi environment bersama. Tidak ada GPU diperlukan.

## 9. Pemeriksaan sebelum menyerahkan

1. Semua sepuluh set dan 80 pasangan arah terdaftar. Tidak ada pasangan yang hilang diam-diam; ketidakpastian tetap tercatat.
2. Semua sumber mempunyai SHA sebelum/sesudah yang sama. Perbedaan dengan manifest dilaporkan, bukan diperbaiki diam-diam.
3. Contact sheet menyertakan arah/frame/file/hash yang benar, tidak ada hasil mirror/recolor/swap tersembunyi.
4. Temuan visual dibaca dari gambar aktual, bukan hanya angka/hash/nama file.
5. Jika membuat script: jalankan pemeriksaan sintaks dan pengujian yang relevan untuk pemilihan sepuluh set, input/format rusak, konsistensi indeks dan pembatasan output. Jangan menulis tes yang hanya mengulangi implementasi.
6. Pastikan seluruh berkas yang berubah berada pada allowlist bagian 7. `git diff --check` lulus. Tidak ada perubahan ke runtime/source asli.
7. Galeri terkurasi <=1MiB, tanpa kredensial/data akun; gambar diagnostik berlabel. Lisensi artwork proyek tetap terpisah dari lisensi kode. Jika memakai Pillow, rujuk notice existing `tools/player-gait/LICENSE-Pillow.txt`.

## 10. Format laporan dan penyerahan

Laporan Markdown harus memuat:

1. Branch/commit dasar, alat dan versi yang benar-benar dipakai, waktu pengerjaan dan batas audit.
2. Ringkasan temuan menurut P0/P1/P2, tanpa klaim performa, natural walking atau runtime acceptance.
3. Tabel sepuluh set: status kelengkapan input, 8 arah diperiksa, jumlah masalah pasti/dugaan/unknown.
4. Daftar temuan terinci dengan koordinat, SHA dan tautan bukti; rekomendasi perbaikan terbatas.
5. Yang belum dapat dipastikan: anatomy/grip/contact terrain/native timing dan hal lain yang memang tidak diuji.
6. Perintah reproduksi, hasil tes aktual, kegagalan yang ditemukan, hash input/output dan pemeriksaan source tidak berubah.
7. Daftar persis semua berkas yang dibuat/diubah, ukuran bukti yang dicommit, dan pekerjaan berikutnya untuk integrator.

Commit hanya file allowlist yang sudah diperiksa. Berikan SHA commit lokal, daftar prioritas temuan dan path laporan. Berhenti pada penyerahan paket audit; jangan otomatis melanjutkan memperbaiki atlas atau mengambil alih tugas lain.

## Prompt singkat untuk memulai Gemini

> Bekerja hanya di `/Users/ardianryan/Documents/Jalasmara-gemini-character-audit`, branch `work/gemini-character-source-audit`. Baca `AGENTS.md` dan `docs/plans/07-gemini-character-source-audit.md`, lalu kerjakan seluruh paket audit dalam brief tersebut. Patuh pada daftar sepuluh set, allowlist output dan larangan perubahan runtime. Jangan mengganti atlas, menjalankan engine/browser, mengakses server/data/key, memasang dependency, push atau deploy. Hasil akhir berupa commit lokal, laporan dengan 80 record arah dan bukti terkurasi. Jangan menganggap nama arah atau hash unik sebagai bukti visual. Jika fakta tidak cukup, catat unknown. Jangan memperluas tugas setelah selesai.
