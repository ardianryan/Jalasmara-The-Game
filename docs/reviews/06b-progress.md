# Progres 06-B: paket inti lokal dan pekerjaan terbuka

9 November 2026. Laporan parsial untuk pengguna dan agent berikutnya. Runtime kandidat terakhir `e1bdf95` pada `work/06b-integration`; perubahan sesudahnya berupa dokumentasi/harness. **Staging belum diganti:** source rilis tetap `9ba21c6`, PCK `a9378a52`. Laporan ini tidak menyatakan seluruh Rencana06 selesai.

## Perubahan yang selesai dalam kandidat

- **Rumah dan dek:** Griya memakai sumbu yang sama dengan dek, menggantikan footprint skew yang salah. Lebar164 dengan aisle38 menjaga akses belakang. Fasad/atap/serambi/tiang/collider mengikuti plan bersama, bukan model yang diputar terpisah. Lima awning dan sepuluh post melayani tujuan hujan, dengan local roof cutaway serta tumpuan/fondasi Griya. [Review konstruksi](06b1a-shelter-architecture.md).
- **Rute dan save:** commute Ratih/Sari/Darmi mengitari post. API memulihkan14 save lama pada post/sudut yang berubah dan mempertahankan lima posisi dek yang masih sah. Tidak ada reset akun atau hadiah dari animasi.
- **Ujang:** telapak tetap world-locked saat stance; langkah transisi6unit mengalihkan dukungan ketika berbelok90/180°. Seluruh root tidak lagi dimirror sehingga kaki kayu kanan tetap. Kepala belakang/barat, rompi belakang dan fist original disiapkan; grip diukur terhadap joran independen. [Review langkah/arah](06b2-ujang-transition-step.md), [review rear/grip](06b2-ujang-rear-grip.md).
- **Kamera:** helper orbit/snap berlisensi Noxe, legacy parity dan pembanding kiri−45 dengan mesh sebenarnya. Kamera gameplay global belum dipindahkan; inverse input/facing/canopy/penanda masih paket adapter terpisah. [Review kamera](06b-camera-pilot.md).
- **Website:** search admin, stale request guard, kondisi loading/empty/error/retry, perlindungan draft, akun/reset/settings serta layout layar kecil. [Review32 checks](06d-website-account-admin.md).
- **Dokumentasi:** [AGENTS.md](../../AGENTS.md), [PRD](../PRD.md), [handoff aktif](../agent-handoff.md), README/status/rencana serta daftar referensi diperbarui. Handoff wajib diperbarui tiap paket/progres bermakna walau baru sebagian.

## Bukti integrator

| Pemeriksaan | Hasil dan batas |
| --- | --- |
| Typecheck/API |82/82 lulus pada source shared final b765587; increment tubuh tidak mengubah TS/API.14 migrasi+5 posisi valid diuji round-trip memakai database/akun fixture sendiri. |
| Dunia Godot |40/40 lulus pada runtime e1bdf95, termasuk shelter, kamera dan kontak Ujang; log penuh bebas SCRIPT ERROR/ERROR/Assertion.10spesies/722frame tetap sah. |
| Kontak tubuh |1.242sampel default mencakup1.074 commute/tangga/stop dan168belok,26grip; batas pelvis tetap8.176PNG native berurutan ditinjau melalui contact sheet. Belum semua arah tubuh digambar ulang. |
| Kamera/geometri |480sampel Camera3D;18frame low/balanced siang/malam/hujan sesudah alignment. Galat telapak layar maksimum0,0000610352px. Integrator meninjau arah dinding/atap/dek dan lampu malam. |
| Build/paket |Export Godot, API dan web lulus. PCK `7f2ac59f0e39bed9ad5d6e47f4836f76a097b89cc2dadf388514cfbd5d02eaf9`,64.289.088B;656payload MD5 sah. Notice MIT Noxe di direktori PCK dibandingkan byte-per-byte dengan source dan cocok. |
| Website |32checks production,12PNG dan0JS errors; API website fixture. Hasil ini tidak menggantikan browser game/API nyata. |
| Harness performa |14tes CPU lulus; bukan benchmark GPU/perangkat. Tidak ada klaim FPS Windows/S23 atau speedup. |
| Browser game nyata |Run kedua meluluskan17 pemeriksaan pada PCK yang sama: migrasi, Griya masuk/save/reload/keluar, tujuh warga tiba di shelter hujan dan seluruh percakapan, gerbang hutan, reveal/restore tajuk, jurnal/kalender pause, joystick, reload hutan dan kedua jembatan. Berhenti pada batas harness421detik ketika berjalan pulang, bukan collision/API;0JS error/0API gagal, cleanup fixture nol. Laut/pulang/reload akhir tetap menunggu alur lanjutan. Run pertama gagal pada predicate attach interior yang sudah diperbaiki. [Laporan QA](06b-browser-qa-preparation.md). |

Kegagalan selama iterasi disimpan:78/80API pertama karena dua rute memotong tiang, serta36sampel sharp turn yang tak terjangkau. Keduanya diperbaiki pada source dan tes terkait tetap aktif. Fixture kamera delta0 yang belum menerapkan cahaya malam juga diperbaiki menjadi0,5detik. Angka lulus di tabel berasal dari run akhir, bukan menyembunyikan log gagal.

Artefak lokal di worktree integrasi: `.runtime/06b-api-final-aligned.log`, `.runtime/06b-world-final.log`, `.runtime/06b-export-final.log`, `.runtime/06b-left-camera-final.log`, `artifacts/godot/06b-quarter-pilot/`, serta `artifacts/browser/`. Source gambar/prompt Ujang tersedia dalam Git; screenshot pengujian diabaikan agar tidak menjadi aset distribusi.

## CI kandidat, bukan rilis staging

[Pipeline3044026490](https://gitlab.com/ardianryan/jalasmara-the-game/-/pipelines/3044026490) untuk `e0d75b3` lulus empat job branch: verify, godot_web, build dan codeql. Job laporan GitHub khusus default branch tidak dijalankan pada branch ini. Artefak diperiksa langsung:82testcase API tanpa failure/skip;40/40world;201aturan CodeQL dengan0temuan; tiga audit dependensi mencatat0kerentanan. Hasil ini tidak berarti paket sudah aktif di HTTPS.

Pipeline sebelumnya3044000129 mempunyai job CodeQL sukses tetapi satu warning alur jumlah byte HTTP menuju metadata file laporan harness. Field laporan diubah menjadi ukuran pin yang sudah dibandingkan dengan jumlah unduhan dan hash; limit/hash tetap diperiksa, tanpa suppression. SARIF pipeline3044026490 diperiksa kembali dan kosong. Jangan menyebut pipeline pertama bebas warning hanya karena job-nya hijau.

## Tool terbaru yang dipakai

**Noxe Pixel Engine** pin `d619d856398b44ad084003fac0a9fbfc9c8393e7` menjadi sumber port kecil rumus kamera/snap ke Godot, dengan MIT©DanielJankulovski disertakan. Kit cottage/pier menjadi referensi metode untuk bangunan native orisinal; runtime Three.js/material/demo tidak disalin. Noxe bukan editor bangunan dan exporter GLB belum ada pada pin yang diperiksa.

**Image generation bawaan**, Pillow dan generator `tools/npc-rig` dipakai untuk bagian rear/west/grip original Ujang yang belum ada di library. Source, prompt dan proses packing ada di `assets/source-2d/ujang-rear-grip-v1/`; atlas50part total tetap mengikuti lisensi karya asli proyek. Tidak ada API key Sprite AI atau output PixelDoll yang dipakai.

**Godot4.7.2 Compatibility** menjalankan pengujian headless/native dan export Web; **Playwright/Chromium** menguji UI dan game; **Node/TypeScript** menguji kontrak/API; **parser PCK Python read-only** memeriksa hash/direktori/MD5 paket. **Git worktree** memisahkan lane lalu cherry-pick ke integrasi. CI GitLab kandidat berjalan terpisah; status final CI/HTTPS harus dicatat setelah benar-benar selesai.

**Belum dipakai:** PixelDoll/PixelLab masih riset authoring berlapis, MCP Sprite AI belum callable/auth terverifikasi, exporter GLB Noxe belum tersedia. Library/Polyfork existing dipertahankan. Daftar integrasi dan lisensi pada [indeks referensi](../reference-integrations.md) dan [notice](../../THIRD_PARTY_LICENSES.md); nama WorldKit tidak menggantikan atribusi upstream.

## Berikutnya, menurut prioritas

1. Selesaikan bagian browser yang tersisa dan transaksi kedai/tidur.17pemeriksaan prefix yang sudah lulus tetap disimpan; kelompok lanjutan memakai UUID baru dan posisi awal sah, lalu input aktual. Bila bukti memakai dua fixture, laporkan sebagai dua kelompok, bukan satu perjalanan tanpa putus.
2. Adapter kamera kiri gameplay: inverse layar→map, follow elevasi, visual facing terpisah dari phase gait, canopy-right aktual, billboard/alat dan penanda. Checkpoint `6c534ac` pada `work/06b-view-projection` baru source/CPU640kasus; Camera3D test belum dijalankan. Jangan aktifkan diagonal global dari checkpoint ini saja. Ulang coverage336sampel bila kamera berubah.
3. Kotak percakapan pada667×375 masih memakai sekitar63%tinggi layar untuk satu baris; root meninjau screenshot Ujang dan menugaskan audit compact layout. Sesuaikan tinggi terhadap isi sambil mempertahankan teks16px/aksi minimal48px, portrait dan fokus keyboard. Bingkai Bahari serta tombol yang berfungsi belum membuktikan ukuran HUD sudah nyaman.
4. Matangkan pilot Darmi/Sari: target siraman Darmi ditemukan berada19,75unit di luar soil bed; checkpoint `0517cef` pada `work/06b-tool-contact-next` memuat fix dan test actual mesh480sampel, belum dijalankan Godot. Grip keduanya belum mempunyai anotasi pixel independen dan tidak boleh dilaporkan sebagai error0 yang terukur. Ujang masih memerlukan arah torso/rear limbs lengkap dan penilaian manusia atas keluwesan.
5. Warga yang belum memakai rig masih terlihat sebagai billboard potret, termasuk latar abu-abu pada malam. Catat sebagai gap B3, bukan kualitas karakter final. Orientasi rumah lain ditinjau per lot/facing; fix Griya tidak otomatis menyelaraskan seluruh bangunan.
6. Sesudah inti stabil: rumah pribadi lurah, direktur dengan kontainer/RV sendiri, Laskar Kognisi/rute/dialog. Farming/keramba/interior lanjutan mengikuti kontrak server D. Windows/S23 fisik, sesi panjang dan uji bermain manusia tetap terbuka.

Gate dokumentasi parsial: Hard Gate PASS, hasil/pending dan rilis dipisahkan tanpa klaim perangkat; Purpose Gate PASS, tiap perubahan menjawab akses/arah/kontak/coverage yang nyata; Liveliness PASS, arah comfy pesisir pengguna dipertahankan; Craftsmanship PASS untuk laporan, source/bukti/tool/lisensi serta47tautan entry diperiksa. **Gate browser game/rilis belum ditutup**; statusnya harus diperbarui setelah rerun, bukan dianggap lulus oleh gate dokumentasi.
