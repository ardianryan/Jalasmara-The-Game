# Handoff aktif agent

Terakhir diperbarui: 9 November 2026, paket integrasi 06-B berjalan. Baca berkas ini bersama [AGENTS.md](../AGENTS.md), [PRD](PRD.md) dan [Rencana 06](plans/06-finishing-dunia-npc-dan-perluasan-desa.md). Bagian ini ditimpa dengan keadaan terbaru; log singkat di bawah ditambah saat paket selesai. Laporan historis tetap disimpan.

## Rilis versus kandidat

- **Staging yang sudah terbukti:** source `9ba21c6bdcb86de1b1732fe4d646fc5a27099eec`, PCK `a9378a52c9fbb64ec96ae579bcef1ced1ab7920962823025e238a453eb8a716b`. [Laporan rilis 06-A/B1](reviews/06a-delivery.md) memuat image, backup, rollback dan CI. Main sesudahnya memuat perbaikan harness/dokumen; jangan menyamakan source host dengan HEAD lokal.
- **Kandidat aktif:** branch `work/06b-integration`, worktree saudara `Jalasmara-06-integration`, runtime terakhir `e1bdf95`. Paket gabungan sudah diekspor dan build API/web lulus; PCK `7f2ac59f0e39bed9ad5d6e47f4836f76a097b89cc2dadf388514cfbd5d02eaf9`,64.289.088B. Belum dirilis ke staging. Gunakan `git log/status` untuk SHA dokumen/QA terbaru.
- Root mengintegrasikan dan menguji; tiga subagent memakai worktree terpisah untuk shelter/proyeksi, tubuh dan website/QA. Slot browser saat pembaruan ini milik subagent website untuk game nyata localhost3101. API kandidat berjalan pada sesi integrator51031; jangan menyentuh proses lama3100 atau menjalankan Godot/browser sebelum pelepasan.

## Arahan pengguna terbaru

1. Lanjutkan pekerjaan inti yang belum selesai, gunakan subagent sesuai kapasitas; bukan berhenti setelah rencana atau jawaban singkat.
2. Kamera dari kiri menghadap serong kanan, 3/4. Peta/karakter tidak dicerminkan. Helper kandidat memakai azimut −45°, sedangkan default gameplay saat ini tetap azimut 0°/elevasi 35° sampai adapter proyeksi/input menyeluruh selesai.
3. **Koreksi penting:** rumah di atas dermaga semula belum sejajar dengan sumbu dek. Memiliki dua sisi terlihat tidak membuktikan alignment benar. Footprint rumah lama sudah diskew sementara dek memakai sumbu map; fix Griya sekarang masuk kandidat dan terbukti native. Jangan mengembalikan skew lama sebagai alasan “lebih isometrik”.
4. Setelah tiap progres, tulis Markdown walau belum semua selesai: hasil, tool aktual, tes/batas dan langkah berikutnya; sinkronkan petunjuk agent/PRD agar sesi berikutnya tidak mengulang penelitian atau melupakan koreksi.

## Pekerjaan aktif dan penerimaan

| Jalur | Sudah terkumpul | Masih harus diselesaikan |
| --- | --- | --- |
| Shelter/desa | `b765587`: Griya rectangle164 sejajar dek, aisle38, roof/post/collider cocok. Final integrator82/82 API;14 posisi lama dipulihkan dan5 save sah tetap.38 tes dunia subagent dan native before/after | QA game/browser gabungan sedang berjalan. Jangan menerima metadata tujuan hujan saja sebagai bukti ketujuh warga tiba di atap. |
| Ujang | `6c2bd70` checkpoint gagal telah digantikan `e1bdf95`: root anatomis positive, kepala barat original, transition step6unit; defaultCI1.242kontak termasuk168belok,26grip,50parts PASS.176PNG berurutan ditinjau | Empat arah tubuh yang seluruhnya digambar ulang belum selesai; rear limbs dan side torso masih cutout. Audit Darmi/Sari berikutnya, tanpa batch NPC baru dahulu. [Review final](reviews/06b2-ujang-transition-step.md). |
| Kamera | `93ae5ca`: port Noxe orbit/snap berlisensi. Integrator480 sampel Camera3D+18frame sesudah alignment PASS; galat telapak maksimum0,0000610352px; night benar dan gambar ditinjau | Gameplay kamera kiri global belum diterapkan. Subagent menyiapkan adapter proyeksi/input terpisah; canopy-right, follow elevasi, facing/phase dan penanda perlu integrasi. [Review](reviews/06b-camera-pilot.md). |
| Website | Admin search/error/dirty guard, akun/reset/settings/responsive; `740cdff` mencatat 32 checks/0 JS errors pada production preview kandidat | QA actual game baru, bukan mock website, sesudah export: HUD malam, sentuh, Griya/shelter, hutan/laut, save/reload. |
| Payload/perf | Parser read-only dan inventori647 payload, `4df4d04`; 14 tes harness CPU lulus | PCK64,25 MB lama didominasi tekstur/musik; lazy Admin baru eksperimen. Jangan memangkas dynamic asset atau mengklaim FPS naik. Windows/S23 fisik serta sesi panjang tetap terbuka. |

Kegagalan gabungan awal: `npm test` pada `4fdd6cb` mendapat **78/80**, dengan route Ratih commute sample37 dan Darmi work/home sample6 memotong obstacle. Fix `03594be` dan alignment `b765587` kini lulus82/82 pada integrator, log `.runtime/06b-api-final-aligned.log`. Source TS tidak berubah pada increment tubuh sesudahnya. Kegagalan sharp turn36sampel pada checkpoint38e88 juga sudah diperbaiki tanpa melonggarkan batas:1.242kontak default PASS. Pertahankan catatan gagal sebagai sejarah iterasi, bukan hasil akhir.

Tes gabungan akhir runtime `e1bdf95`:40/40 pemeriksaan dunia,10spesies/722frame,14tes harness performa, export Godot/build API/web, tanpa SCRIPT ERROR/ERROR/Assertion. Log `.runtime/06b-world-final.log`, `.runtime/06b-export-final.log` dan `.runtime/06b-web-final.log`. Website JS/CSS tetap hash yang sudah lulus32 checks. Ini bukti lokal, bukan CI/HTTPS rilis baru.

## Tool yang benar-benar dipakai dalam paket ini

| Tool/sumber | Penggunaan aktual | Status/lisensi |
| --- | --- | --- |
| Godot4.7.2 Compatibility/GDScript | Mesh serambi/tiang/fondasi, cutaway, rig/IK, headless/native rendering | Runtime aktif; MIT Godot. Capture kandidat gabungan masih menunggu final source. |
| Noxe `d619d856398b44ad084003fac0a9fbfc9c8393e7` | Orbit/snap diadaptasi ke `LandCameraPose.gd`; metode cottage/pier dibaca untuk konstruksi native | Port kamera saja aktif dalam kandidat. MIT/notice dikemas di resources/licenses. Tidak ada renderer/material/demo Three.js kedua. |
| Image generation bawaan + Pillow/generator npc-rig | Artwork rear cap/vest/fist dan kepala west original Ujang, lalu dipotong/dipaletkan/dipaketkan reproducibly;18part Ujang/50total | Source/prompt pada assets/source-2d/ujang-rear-grip-v1; original art mengikuti LICENSE proyek. Bukan aset demo Noxe/PixelDoll. |
| Playwright/Chromium | Production website32 checks,12 gambar,0 JS errors; persiapan actual-game route QA | Website memakai API fixture. Browser game/HP fisik bukan hasil yang sama. |
| Node/TypeScript test runner | Typecheck,82API final,14tes harness performa | Dua regression awal sudah diperbaiki; jangan mengutip78/80 sebagai hasil akhir. |
| Python `scripts/performance/pck-inventory.py` | Parser format PCK4 dengan MD5/hash, inventori647 payload paket rilis lama | Read-only, bukan pruning atau runtime baru. |
| Git/worktree | Isolasi tiga jalur dan cherry-pick ke kandidat | Main/staging belum berubah oleh kandidat ini. |

**Baru referensi, belum dipakai:** PixelDoll/PixelLab, MCP Sprite AI, exporter GLB Noxe. Tool Sprite AI belum callable/auth terverifikasi pada sesi; jangan menyimpan atau mengulang key yang pernah diberikan. Referensi lain dan pin ada di [indeks integrasi](reference-integrations.md) serta [audit Noxe/PixelDoll](world/noxe-pixeldoll-reference.md).

## Langkah integrator berikutnya

1. Selesaikan browser acceptance `scripts/plan06-layout-browser.mjs` pada localhost3101, mematok hash/ukuran PCK di atas. Agent QA memegang slot; root tidak menjalankan engine bersamaan. Harness telah digabung dari10d1edd, CPU10tujuan/97segmen sah. Pergerakan aktual keyboard/joystick, tanpa teleport/debug override/mock game.
2. Tinjau gambar/HUD malam, tujuh warga di shelter, Griya masuk/save/reload/keluar, hutan/dua jembatan, laut/pulang dan cleanup. Bila gagal, bedakan bug harness dengan game; jangan melemahkan collision atau menulis posisi untuk melewati rute.
3. Jalankan night-home untuk transaksi kedai/tidur bila perlu. Website32 checks sudah lulus pada source website yang sama; ulang bila website berubah.
4. Catat hasil di laporan paket, perbarui handoff/status/rencana. Rilis hanya setelah penerimaan gabungan, CI dan backup/rollback; cocokkan source/PCK HTTPS kemudian smoke fixture baru. Staging tetap9ba21c6 sampai langkah ini benar-benar selesai.
5. Lanjut adapter kamera kiri global dan keterbacaan seluruh dunia; matangkan tiga rig sebelum batch NPC; setelah itu perluasan desa C (rumah lurah, direktur/container, Laskar). Pertahankan pekerjaan perangkat dan fitur rumah D sebagai gap terbuka.

## Log ringkas lintas sesi

- **9 November, paket06-A/B1:** hutan/collar laut/jalan dan dasar rutinitas sudah dirilis serta smoke publik; source9ba21c6/PCKa9378a52. Bukti pada laporan awal; bukan seluruh Rencana06 selesai.
- **9 November, integrasi06-B berjalan:** website32/32 dan payload audit diterima; shelter/rig/helper kamera masuk kandidat. Full API mengungkap2 regression route. Pengguna mengoreksi facing kiri serta alignment rumah/dek; fix sedang dikerjakan. Tidak ada rilis baru yang diklaim. Petunjuk agent dan PRD ditambahkan sesuai permintaan agar progres/pending/tool tersimpan.
- **9 November, koreksi core selesai lokal:** Griya/dek sejajar, rute/post/save diperbaiki;82API/40world/14harness PASS. Sharp-turn gagal36sampel kini menjadi168kasus default yang lulus, kepala west original mempertahankan kaki kanan. Paket7f2ac59f diekspor, browser nyata berjalan; staging dan CI baru belum diklaim.47tautan lokal pada dokumen entry diperiksa.
