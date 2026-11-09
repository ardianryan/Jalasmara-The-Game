# Handoff aktif agent

Terakhir diperbarui: 9 November 2026, paket integrasi 06-B berjalan. Baca berkas ini bersama [AGENTS.md](../AGENTS.md), [PRD](PRD.md) dan [Rencana 06](plans/06-finishing-dunia-npc-dan-perluasan-desa.md). Bagian ini ditimpa dengan keadaan terbaru; log singkat di bawah ditambah saat paket selesai. Laporan historis tetap disimpan.

## Rilis versus kandidat

- **Staging yang sudah terbukti:** source `9ba21c6bdcb86de1b1732fe4d646fc5a27099eec`, PCK `a9378a52c9fbb64ec96ae579bcef1ced1ab7920962823025e238a453eb8a716b`. [Laporan rilis 06-A/B1](reviews/06a-delivery.md) memuat image, backup, rollback dan CI. Main sesudahnya memuat perbaikan harness/dokumen; jangan menyamakan source host dengan HEAD lokal.
- **Kandidat aktif:** branch `work/06b-integration`, worktree saudara `Jalasmara-06-integration`. Sudah mengumpulkan website, payload audit, Ujang rear/grip, shelter layout 9 dan helper kamera. Belum diekspor/dirilis sebagai paket gabungan. Gunakan `git log/status` untuk SHA terbaru; source sedang berubah oleh integrator.
- Root mengintegrasikan dan menguji; tiga subagent memakai worktree terpisah untuk shelter, tubuh dan website/QA. Slot engine saat catatan ini dibuat milik subagent karakter; jangan menjalankan Godot/browser sebelum menerima pelepasan.

## Arahan pengguna terbaru

1. Lanjutkan pekerjaan inti yang belum selesai, gunakan subagent sesuai kapasitas; bukan berhenti setelah rencana atau jawaban singkat.
2. Kamera dari kiri menghadap serong kanan, 3/4. Peta/karakter tidak dicerminkan. Helper kandidat memakai azimut −45°, sedangkan default gameplay saat ini tetap azimut 0°/elevasi 35° sampai adapter proyeksi/input menyeluruh selesai.
3. **Koreksi penting:** rumah di atas dermaga belum sejajar dengan sumbu dek. Memiliki dua sisi terlihat tidak membuktikan alignment benar. Footprint rumah lama sudah diskew sementara dek memakai sumbu map; agent shelter sedang memperbaiki Griya, seluruh konstruksi, collider dan akses bersama. Jangan mengembalikan skew lama sebagai alasan “lebih isometrik”.
4. Setelah tiap progres, tulis Markdown walau belum semua selesai: hasil, tool aktual, tes/batas dan langkah berikutnya; sinkronkan petunjuk agent/PRD agar sesi berikutnya tidak mengulang penelitian atau melupakan koreksi.

## Pekerjaan aktif dan penerimaan

| Jalur | Sudah terkumpul | Masih harus diselesaikan |
| --- | --- | --- |
| Shelter/desa | Lima serambi, sepuluh post, tujuh tujuan hujan, fondasi Griya dan local roof cutaway; commit `2115547` sudah masuk kandidat. Fix commute dan API round-trip `c2dd9c9` masuk sebagai `03594be`; subagent mendapat81/81 API | Alignment Griya/dek, migrasi sudut footprint lama, full suite gabungan akhir dan gambar ulang. Jangan menerima hasil8 tes CPU sebagai pengganti full suite. |
| Ujang | `58beafd`, `b358eb5`, `05a38bb`: kontak telapak, rear cap/vest original dan grip joran independen; masuk kandidat | Root flip west menukar hip/prostetik; agent sedang memperbaiki dan menguji turn. Empat arah asli/natural walk final belum selesai; E/W fallback dan anggota tubuh belakang masih terbatas. |
| Kamera | `93ae5ca`: port Noxe orbit/snap berlisensi, helper proyeksi/ray, fixture kiri −45° dan legacy parity | Jalankan ulang tes/capture pada source gabungan dan Griya yang sudah sejajar. Fixture cuaca diperbaiki dari delta0 ke0,5 agar night benar. Gameplay kamera kiri global belum diterapkan. |
| Website | Admin search/error/dirty guard, akun/reset/settings/responsive; `740cdff` mencatat 32 checks/0 JS errors pada production preview kandidat | QA actual game baru, bukan mock website, sesudah export: HUD malam, sentuh, Griya/shelter, hutan/laut, save/reload. |
| Payload/perf | Parser read-only dan inventori647 payload, `4df4d04`; 14 tes harness CPU lulus | PCK64,25 MB lama didominasi tekstur/musik; lazy Admin baru eksperimen. Jangan memangkas dynamic asset atau mengklaim FPS naik. Windows/S23 fisik serta sesi panjang tetap terbuka. |

Kegagalan gabungan awal: `npm test` pada `4fdd6cb` mendapat **78/80**, dengan `integration.test.ts` route Ratih commute sample37 dan Darmi work/home sample6 memotong obstacle. Log `.runtime/06b-api-tests.log`. Fix waypoint/collision `03594be` sudah digabung, dengan81/81 pada worktree shelter; tes final integrator menunggu alignment. Assertion tidak dilonggarkan. Pertahankan catatan kegagalan ini untuk membedakan iterasi awal dan hasil akhir.

## Tool yang benar-benar dipakai dalam paket ini

| Tool/sumber | Penggunaan aktual | Status/lisensi |
| --- | --- | --- |
| Godot4.7.2 Compatibility/GDScript | Mesh serambi/tiang/fondasi, cutaway, rig/IK, headless/native rendering | Runtime aktif; MIT Godot. Capture kandidat gabungan masih menunggu final source. |
| Noxe `d619d856398b44ad084003fac0a9fbfc9c8393e7` | Orbit/snap diadaptasi ke `LandCameraPose.gd`; metode cottage/pier dibaca untuk konstruksi native | Port kamera saja aktif dalam kandidat. MIT/notice dikemas di resources/licenses. Tidak ada renderer/material/demo Three.js kedua. |
| Image generation bawaan + Pillow/generator npc-rig | Artwork rear cap/vest/fist original Ujang dibuat pada paket subagent, lalu dipotong/dipaletkan/dipaketkan reproducibly | Source/prompt pada assets/source-2d/ujang-rear-grip-v1; original art mengikuti LICENSE proyek. Bukan aset demo Noxe/PixelDoll. |
| Playwright/Chromium | Production website32 checks,12 gambar,0 JS errors; persiapan actual-game route QA | Website memakai API fixture. Browser game/HP fisik bukan hasil yang sama. |
| Node/TypeScript test runner | Typecheck, API80 tes pada iterasi awal,14 tes harness performa | Dua API regression masih gagal pada snapshot di atas. |
| Python `scripts/performance/pck-inventory.py` | Parser format PCK4 dengan MD5/hash, inventori647 payload paket rilis lama | Read-only, bukan pruning atau runtime baru. |
| Git/worktree | Isolasi tiga jalur dan cherry-pick ke kandidat | Main/staging belum berubah oleh kandidat ini. |

**Baru referensi, belum dipakai:** PixelDoll/PixelLab, MCP Sprite AI, exporter GLB Noxe. Tool Sprite AI belum callable/auth terverifikasi pada sesi; jangan menyimpan atau mengulang key yang pernah diberikan. Referensi lain dan pin ada di [indeks integrasi](reference-integrations.md) serta [audit Noxe/PixelDoll](world/noxe-pixeldoll-reference.md).

## Langkah integrator berikutnya

1. Terima fix alignment/commute/save dari shelter dan fix turn anatomis dari karakter, tinjau diff dan bukti. Jangan menimpa source kamera dengan source worktree lama.
2. Setelah slot engine bebas, import kandidat, buat `.runtime/world-map.json`, jalankan `npm run check:world`. Runner sekarang memasukkan camera pose, shelter dan Ujang foot-contact; jumlah yang diharapkan40 jika tidak ada tambahan sah. Periksa log/error, bukan hanya jumlah.
3. Jalankan ulang API/typecheck setelah source final. Render pembanding kiri siang/malam/hujan dan periksa Griya sejajar dek, Nala tidak tertutup, tiang bertumpu. Export/build aktual sebelum browser QA.
4. Jalankan actual-game/hub/forest/night/ocean/save/joystick checks pada PCK kandidat yang hash-nya dicatat. Fixture akun sendiri dan cleanup. Website32 check sudah lulus pada source website yang sama; ulang bila website berubah.
5. Catat hasil di laporan paket, perbarui dokumen ini/status/rencana. Rilis hanya setelah penerimaan gabungan, CI dan backup/rollback; setelah rilis cocokkan source/PCK HTTPS lalu smoke akun fixture baru.
6. Paket inti berikutnya: adapter kamera kiri global dan keterbacaan seluruh dunia; matangkan tiga rig sebelum batch NPC; setelah itu perluasan desa C (rumah lurah, direktur/container, Laskar). Pertahankan pekerjaan perangkat dan fitur rumah D sebagai gap terbuka.

## Log ringkas lintas sesi

- **9 November, paket06-A/B1:** hutan/collar laut/jalan dan dasar rutinitas sudah dirilis serta smoke publik; source9ba21c6/PCKa9378a52. Bukti pada laporan awal; bukan seluruh Rencana06 selesai.
- **9 November, integrasi06-B berjalan:** website32/32 dan payload audit diterima; shelter/rig/helper kamera masuk kandidat. Full API mengungkap2 regression route. Pengguna mengoreksi facing kiri serta alignment rumah/dek; fix sedang dikerjakan. Tidak ada rilis baru yang diklaim. Petunjuk agent dan PRD ditambahkan sesuai permintaan agar progres/pending/tool tersimpan.
