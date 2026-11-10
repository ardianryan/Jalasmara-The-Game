# Instruksi koreksi audit karakter untuk Gemini

10 November 2026. Status paket `f67de11a9c067ec80cf42ed5fb6cfa9dae4a89e2`: **ditahan, belum digabung**. Dokumen ini menugaskan koreksi audit, bukan perbaikan artwork. Baca [hasil pemeriksaan integrator](../reviews/gemini-character-audit-integration-review.md) dan [brief asli](07-gemini-character-source-audit.md). Batas tugas berikut mengatasi ambiguitas izin memperbaiki berkas baru milik Gemini pada brief pertama.

Salin instruksi di bawah kepada Gemini.

## Tempat kerja dan pemeriksaan awal

Kerjakan hanya di `/Users/ardianryan/Documents/Jalasmara-gemini-character-audit`, branch `work/gemini-character-source-audit`. Periksa `pwd`, branch, `git status --short`, dan HEAD. Riwayat harus masih memuat commit `f67de11a9c067ec80cf42ed5fb6cfa9dae4a89e2`. Jangan reset, checkout paksa, amend, rebase, atau menghapus pekerjaan yang ada. Jika tempat kerja/branch salah atau ada perubahan asing, hentikan perubahan dan laporkan; pembacaan sumber boleh diteruskan.

Baca `AGENTS.md` dan `docs/plans/07-gemini-character-source-audit.md` di worktree sendiri. Dokumen koreksi integrator belum ada dalam commit Anda. Baca secara **read-only** di:

`/Users/ardianryan/Documents/Jalasmara-overnight-integration/docs/reviews/gemini-character-audit-integration-review.md`

Jangan menyalin dokumen root ke path tracked baru dalam branch Anda. Boleh membaca dua gambar pembanding yang ditautkan dokumen koreksi; jangan mengubahnya.

## Izin tulis persis

Hanya berkas milik paket ini:

- Tool/test milik Anda dalam `tools/player-gait/gemini-source-audit/`.
- `docs/reviews/gemini-character-source-audit.md`.
- `docs/reviews/gemini-character-source-audit.json`.
- Bukti baru dengan nama baru di `docs/visual/gemini-character-source-audit/`; total seluruh folder tetap maksimum 1 MiB.
- Output ignored pada `artifacts/player-gait/gemini-source-audit/<run-id-baru>/` dan log sendiri di `.runtime/gemini-source-audit/`.

Koreksi manual tool, test, JSON, dan Markdown yang Anda buat pada `f67de11` diperbolehkan. Pertahankan commit dan PNG bukti lama. Jangan menimpa PNG tracked lama; tambahkan bukti koreksi bernama baru dan jelaskan bahwa interpretasi lama dicabut. Generator harus memakai direktori run yang belum ada, menolak symlink pada setiap komponen path sebelum `resolve`, dan tidak menulis langsung ke laporan/bukti tracked. Jangan membuka izin ke seluruh `docs/reviews` atau seluruh repository.

Jangan menyentuh atlas, sumber gambar, mask produksi, runtime, metadata arah/pivot, physics, terrain, pakaian/gear, engine, API, HUD, website, CI, lockfile, README, AGENTS, PRD, handoff, atau berkas agent lain. Jangan memperluas audit ke `male_nusantara/daily` atau `male_nusantara/explorer`.

## Koreksi wajib

1. Cabut tujuh klaim P0 arah terbalik: male_default daily NW/NE, male_default explorer NW/NE, female_default explorer NW/NE, dan male_nusantara diving NW. Gambar asli menunjukkan NW kiri dan NE kanan sesuai IDLE. Cabut pula klaim mismatch SE male_nusantara diving. Jangan mempertahankan jumlah temuan dengan menciptakan pengganti.
2. Pisahkan piksel asli dari interpretasi. Detektor `R>120 && R>B` ikut menghitung ekor bandana cokelat sebagai kulit; centroid tidak membuktikan arah kepala. Pertahankan sinyal numerik hanya sebagai petunjuk diagnostik. Jangan swap, mirror, redraw, normalisasi ulang, atau mengganti flag agar hasil terlihat benar.
3. Hitung hash dari input yang benar-benar dibaca. Hash batch manifest yang diperiksa integrator adalah `21fa13f548ea4d582ec624d3dd6c3162e237dc455366d1c9a0415aa221d49f79`; daily source JSON `8e65f4e8d22d18060e6b21bf889c558c39631a1c942e66cee65d33e48d9e9c74`. Keduanya identik terhadap base `5dd4ac4`. Kesalahan pelaporan bukan bukti source berubah. Jika hasil Anda berbeda, laporkan path/input/observasinya; jangan memaksa nilai agar cocok.
4. Seluruh 80 record tetap harus ada. Hapus default otomatis `reviewed_no_obvious_issue`. Setiap keputusan visual harus mempunyai ledger arah, frame yang benar-benar dilihat, bukti, koordinat, alasan, dan cakupan aspek. Kasus belum diperiksa menjadi `unknown` dengan alasan. Jumlah hasil dihitung dari ledger nyata; audit parsial disebut belum lengkap.
5. Klaim gear bersih hanya berlaku pada view/frame/aspek yang benar-benar diperiksa. Sampel spine North frame0 tidak membuktikan 640 frame atau seluruh arah bebas tabung/jala/tas. Kontrak `equipmentBaked:false` adalah klaim metadata, bukan hasil visual atau bukti node runtime.
6. Lebar bbox kaki diagonal bukan stride dunia. Jangan menyarankan kaki diperpanjang ke 40–52 piksel hanya karena pembanding East/West. Beda alpha bawah 4–5 piksel adalah observasi gambar, bukan bukti teleport/kontak runtime. Tanpa bukti tambahan, beri status dugaan yang memerlukan pemeriksaan pose/pivot/fase. Tidak ada pengujian runtime dalam tugas ini.
7. Anatomical left/right, wrist, grip, joint dan kontak yang tidak terbukti tetap `unknown`/null. Jangan mengarang landmark atau menyimpulkan anatomi dari jumlah komponen, hash unik, atau threshold warna.

## Pengaman dan verifikasi CPU

Perbaiki tool sebelum menjalankan generator. Tambahkan pengujian yang benar-benar menolak:

- Path review lain, termasuk file review agent lain yang sudah ada.
- Symlink pada parent atau target output, termasuk symlink yang akhirnya menuju folder yang terlihat diizinkan.
- Direktori run yang sudah ada; kegagalan tidak boleh mengubah isinya.
- Input hilang, dimensi atlas salah, mode/format yang tidak didukung, atau inventaris set tidak lengkap.
- Output ke direktori source/runtime dan data manifest yang hilang tetapi dilaporkan cocok.

Simpan hash sebelum/sesudah seluruh sumber yang dibaca. Periksa dimensi, mode, alpha, arah/baris/kolom sesuai brief asli; jangan resize input diam-diam. Catat versi Python/Pillow yang benar-benar berjalan. Jangan mengaku identitas/model AI tertentu tanpa bukti.

Jalankan syntax check, test CPU milik paket, `git diff --check`, audit allowlist, dan hitung total byte bukti. Catat perintah persis, hasil, serta kegagalan yang sempat terjadi. Test yang lulus tidak boleh disebut membuktikan kebenaran visual.

Gunakan tautan/path relatif repository dalam Markdown dan JSON. Artefak ignored boleh disebut dengan run-id/path relatif. Jangan commit `.runtime`, artefak penuh, atlas duplikat, kredensial, atau dependency.

## Serah terima dan batas berhenti

Buat satu commit koreksi lokal baru yang mempertahankan `f67de11` dalam riwayat. Serahkan:

- SHA penuh commit dan base, daftar tepat berkas berubah, working-tree status.
- Perintah dan hasil tes, bukti allowlist dan total byte PNG.
- Inventaris hash input sebelum/sesudah, dimensi/mode/alpha dan hasil perbandingan manifest yang jujur.
- Ringkasan jumlah kasus benar-benar diperiksa, dugaan, `unknown`, dan temuan yang dicabut.
- Tautan relatif bukti serta keterbatasan yang masih tersisa.

Kemudian berhenti untuk review integrator. Jangan push, merge, deploy, atau memulai perbaikan artwork. Jangan menjalankan Godot/import/export/browser/GPU, memasang package/plugin/MCP, mengunduh aset, memakai API/key, mengakses server/SSH/Docker/data pemain, atau membersihkan cache/worktree. Peninjauan root berikutnya yang menentukan apakah audit dapat digabung.
