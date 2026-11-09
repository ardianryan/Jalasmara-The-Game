# Integrasi kamera kiri, alat warga dan UI

9 November 2026. Laporan parsial kandidat `work/06b-integration`; belum dirilis ke staging. Referensi baru Fish Gen sudah disimpan, tetapi tidak dijalankan atau masuk runtime.

## Source dan paket yang diperiksa

- Kamera kiri dan inverse input: branch view `4088a19`, digabung sebagai `61ff2d9`. Azimut −45°, elevasi35°, tanpa mirror map atau aktor. Griya dan dermaga mempertahankan sumbu dunia yang sama.
- Footfix `d3bbc19`/`e9797e6`: konsumsi perpindahan yang telah melewati batas stance→swing biasa. Panjang tungkai, batas pelvis, startup dan handover belokan tidak dilonggarkan.
- HUD potret `33a6136`/`235a42c`: slot terukur untuk angka/bar O2, maksimum, kehilangan, kedalaman dan tas. Landscape tetap memakai artwork dan layout sebelumnya.
- Harness `870b1b2`: membaca matriks gerak renderer aktual untuk tombol relatif layar; laut/interior mempertahankan kontrak masing-masing. Assignment yang diperingatkan CodeQL diperbaiki tanpa suppression.
- Ekspor gabungan: PCK `5f2aaa46778d8735e7316b34d2865ad8ad40877d537d81b9a2dc1d31e8d69038`, **64.304.668 byte**. Export Godot serta build web/API lulus. API lokal3101 direstart dari build baru; proses3100 lama tidak disentuh.

## Bukti lokal integrator

| Pemeriksaan | Hasil dan batas |
| --- | --- |
| Typecheck dan API | 82/82 PASS pada shared/source kamera kiri; termasuk migrasi posisi lama dan perjalanan sah. Database/UUID tes terpisah. |
| Dunia sesudah merge kiri | 45/45 PASS; seluruh log bebas SCRIPT ERROR/ERROR/Assertion. Sepuluh spesies/722 bingkai tetap sah. Increment HUD sesudahnya diperiksa focused, bukan mengklaim seluruh45 diulang. |
| Ujang | 1.242 sampel termasuk168 belokan; pelvis maksimum6,988868<8, drift telapak0,000349122, sambungan lutut0,000272985;26 grip maksimum0,0153571. Ini batas numerik kontak, bukan bukti semua artwork/gait sudah final. |
| Native renderer final | Sembilan frame hub/Griya/Forest/worker. Semua player1, azimut−45; galat kaki maksimum0,000122071px. Fixture Forest terakhir benar-benar dirender ulang dan kepala worker tidak lagi terpotong oleh zoom3. |
| HUD potret dan analog | HUD headless/native serta analog regression PASS;390×844 actual-fixture dan kehilangan−20 O2, label≥16px, field disjoint/in-frame, bar serta joystick/action terpisah. Gambar komponen ditinjau, bukan disebut game/browser aktual. |
| Paket | Export/build web/API selesai, log bebas error. Browser PCK baru: left4 dan ocean3 PASS,0error/API failure/409; dua UUID terpisah dibersihkan. |

Log lokal: `.runtime/06b-left-typecheck-integrated.log`, `06b-left-api-integrated.log`, `06b-left-world-integrated.log`, `06b-left-native-integrated.log`, `06b-portrait-hud-integrated.log`, `06b-left-export-integrated.log`, `06b-left-web-integrated.log` dan `06b-left-build-api-integrated.log`. Gambar: `artifacts/godot/06b-left-runtime-final/` serta `artifacts/godot/hud-portrait/ocean390-stats.png`.

Root meninjau Griya/dek, Forest bridge dengan Nala terlihat, Sari seutuhnya, dan layout angka HUD. Gambar statis ini membuktikan posisi/keterbacaan; tidak menggantikan uji gerak atau pengujian Windows/S23 fisik.

## Browser dan CI dibedakan menurut paket

PCK sebelumnya `26b83e…`,64.290.960 byte lulus browser ocean ACK3 checks: setelah ekstraksi versi1, dua POST posisi200 mengakui gerak dermaga, lalu reload mempertahankan posisi baru. Tidak ada409/error; fixture dibersihkan. Dialog aktual667×375 lulus4 checks: paragraf39,63% tinggi layar dan pendek33,33%, reveal tidak mengubah tinggi, dunia resume tanpa hadiah/progres cerita. Paragraf memakai scroll untuk sisa bacaan. [Bukti lengkap](06b-browser-qa-preparation.md).

Paket26b83e masih memakai kamera lama dan menyingkap overlap HUD portrait; jangan memakainya sebagai bukti source kamera kiri/HUD baru. Pin5f2aaa kini selesai diuji pada dua UUID terpisah:

- `c517d448-32ed-4677-9db8-fbe0ef2b1855`: modeleft4 checks PASS dalam144.556ms;204 pulsa dari matriks aktual,84 sync, keyboard dan joystick bergerak ke kanan layar, gerbang hub→Forest, bridge_upper serta save/reload. Kedua delta proyeksi ke kanan mempunyai komponen Y≈0; tidak mengubah kontrol produk agar mengikuti harness lama.
- `cd315799-f2a1-40fa-921b-4f02dd1b0695`: ocean3 checks PASS dalam57.952ms;11 sync, masuk laut, cancel joystick, pause tas, ekstraksi, dua ACK posisi200/version1, gerak dek dan reload tersimpan. HUD portrait390 ditinjau di game aktual: angka/bar/depth/bag terpisah, joystick/aksi tetap bebas.

Kedua hasil JSON mencatat errors/failures kosong, pin/byte sesuai, `ownTemporaryPlayerRemoved=true`. Browser ditutup dan slot dilepas. Root membaca hasil keduanya dan meninjau gambar actual HUD390/hub667. Rute laut sebelumnya `35b9b710…` gagal pada ledger harness yang belum selesai membaca respons meskipun API200/ACK sudah benar; boundedwait ACK≤10detik menggantikan jeda250ms, syarat status/versi/posisi tetap, kemudian ocean saja diulang. Riwayat gagal tidak dihapus. Rute bridge_lower dan tujuh dialog hujan lama tidak diulang pada pin baru; bukti historisnya tetap memakai paket7f, dengan tes controller/shelter gabungan terpisah.

CI source `2262bae` berhasil empat job tetapi masih mempunyai **satu warning maintainability** pada assignment harness. Isi artifact:82 API/42 world PASS,201 aturan CodeQL, tiga audit nol kerentanan. [Pemeriksaan artifact](06b-ci-artifacts-3044205000.md). Source870b1b2 memperbaiki assignment; CI source gabungan masih perlu dibaca, bukan dianggap kosong karena job lama hijau.

Pemeriksaan final [pipeline3044287626/source870b1b2](06b-ci-artifacts-3044287626.md) kini selesai: empat job sukses, isi artifact **82 testcase bersih,45/45 world dengan seluruh log PASS,201 aturan CodeQL/0 results, tiga audit/0 kerentanan**. Peringatan assignment lama benar-benar tidak ada pada SARIF baru. PCK CI `e3db84d8…` berukuran64.304.668 byte cocok antara job Godot/build; browser lokal memakai PCK5f2aaa yang dipin terpisah, bukan mengklaim dua paket itu identik byte. Setelahnya hanya harness ACKwait, registrasi empat tes consumer pada CI, dan dokumentasi berubah; runtime yang diuji tetap sama. Empat tes consumer juga dijalankan lokal dan lulus.

## Tool, lisensi dan pekerjaan berikutnya

Godot4.7.2 Compatibility, Node/TypeScript, Playwright/Chromium, Git/worktree dan alat pemeriksaan gambar dipakai. Rumus kamera Noxe tetap mengikuti pin/notice MIT yang sudah dikemas; tidak ada renderer Three.js kedua. Artwork asli dan library sebelumnya dipertahankan. Tidak ada generator gambar/API baru pada increment ini.

[Fish Gen](../world/fish-gen-reference.md) disimpan pada source pin `0faa79003ca50a7d422b618cb59179d9834094f1`, dengan MIT software dan izin hasil README dicatat. Clone ada di workspace utama `.runtime/reference-audit/fish-gen`. Belum install/import/compile/generate atau adapter runtime. Pilot satu spesies PNG/JSON/turn dilakukan sesudah pekerjaan inti; sepuluh spesies aktif tetap dipakai.

Berikutnya: gabungkan kandidat ke main, lalu rilis dengan backup dan rollback sesuai operasi. Artwork arah tubuh lengkap, anotasi grip Darmi/Sari, finishing malam comfy, NPC billboard, rumah lurah/direkturRV/Laskar, farming/keramba lanjutan serta perangkat fisik tetap terbuka. Tidak menyatakan seluruh Rencana06 selesai.
