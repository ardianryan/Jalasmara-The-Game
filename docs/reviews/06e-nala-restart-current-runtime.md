# Nala: restart east pada runtime daratan terbaru

9 November 2026. Worktree `Jalasmara-06-nala-restart-audit`, branch `work/06b-nala-restart-audit`, basis `a30b35c`. Pengguna membatalkan CE; pekerjaan ini melanjutkan core yang belum selesai. Runtime rilis integrator tetap dibekukan. Kandidat ini belum digabung, diekspor, atau dirilis.

## Perubahan terbatas

Pilot `b93719d`/`5cc90ac` diterapkan ulang sebagai `2c3b89c`/`ea936c9`. Konflik hanya pada README; petunjuk review native existing dipertahankan. Dibandingkan basis, source produksi yang berubah hanya `CharacterVisual.gd`, melalui cabang restart kecil untuk menahan pose rendah2 sampai contact aktual berikutnya. Berlaku hanya `male_nusantara`, daily/explorer, east, sudah selesai settling, rawframe3, gerak hampir mendatar ke kanan layar, dan perpindahan render pertama paling banyak4 view-unit. Gerak normal, gambar, pivot, jarak `_travel`, collider, akselerasi, arah lain, contact/foley, pakaian lain, dan server tidak diubah. Gear membaca pose yang sedang ditampilkan.

Audit menemukan fixture/controller dan model lama memakai elevasi kamera55°, sementara default gameplay kini−45°/35°. Fixture sekarang membaca default renderer aktual, dengan embedding logis55° tetap. Untuk gerak tepat ke kanan layar, scale horizontal35° dan55° sama, yaitu1,226744594496685. Jadi ini perbaikan kesesuaian bukti, bukan klaim bahwa angka repro horizontal lama salah.

Model sumber diperluas dari satu titik stop24 ke12 posisi dalam rawframe3 `[24,32)`, masing-masing tiga heading dalam toleransi1% vertikal. Hash empat atlas dan seluruh heel/toe yang ditandai tetap diperiksa. Fixture runtime menambah24 kasus daily/explorer di seluruh jendela tersebut, termasuk restart31,875 yang langsung melewati actual contact32. Tidak ada gambar atau dependensi baru.

## Pemeriksaan yang dijalankan

Godot lokal `4.7.2.stable.official.ed1daf0bf`, Compatibility. Semua engine/native serial setelah grant integrator; proses selesai dan slot dilepas sebelum review CPU. Log ada di `.runtime/nala-restart-*` worktree ini.

| Pemeriksaan | Hasil sendiri |
| --- | --- |
| `python3 tools/player-gait/test_restart_support.py --output artifacts/godot/nala-restart-source` |3.228 trace heel/toe PASS;804 first-update contact crossings dicatat tidak berubah; kedua pakaian,12 titik stop,3 heading, akselerasi850 pada30/60/120Hz serta variasi langkah. Drift tidak nol.|
| `python3 tools/player-gait/test_eightway.py` |Exit0; atlas existing tidak ditulis ulang.|
| Import ulang |Exit0, scan seluruh log tidak menemukan error.|
| `player-locomotion.gd` headless |192 sampel stop/turn existing,40 sampel restart sebelum contact,24 kasus window, actual Player acceleration/deceleration850,12 set pakaian ×8 arah, gear/pause/fallback PASS.|
| `locomotion-collision-foley.gd` |Actual100px/s controller membentur rumah, fase/SFX berhenti,3 contact-synced footsteps PASS.|
| `land-left-gameplay.gd` |60 actual Player/Forest/connector checks PASS: arah keyboard, magnitude analog, jarak gait fisik, pause, elevated follow, water backing; tanpa mutasi save.|
| Native `NALA_GAIT_CAPTURE=1` |924 PNG +JSON selesai27,33s, assertion yang sama PASS. Tidak ada `SCRIPT ERROR`, `ERROR:`, parse/load failure di seluruh log native maupun tiga focused bersih.|
| `git diff --check` |PASS.|

Kegagalan awal tidak disembunyikan: fresh import pertama mengeluhkan font tema yang belum punya cache impor; import berikutnya bersih. Focused pertama mencetak assertion PASS tetapi log berisi240 InputMap errors ketika actual Player melepas touch. Hasil itu ditolak. Fixture kini mendaftarkan/melepas `left/right/up/down` seperti bootstrap uji gameplay kiri existing; production `Player` tidak diubah. Sesudah perbaikan, ketiga focused diulang dan seluruh log bersih. Log awal tetap disimpan.

## Hasil gambar yang benar-benar dilihat

`artifacts/godot/nala-gait-transitions/` pada worktree ini:

- `results.json`:924 frame; SHA256 `241c1fb119d71df6fa92f29081357d2c7d6f63de84ae8a8cb48a44b4ac5d33d0`.
- `restart-pop-contact-sheet.png`:actual native neutral24→low2 pada26/28/30→raw4 pada32.
- `restart-pilot-contact-sheet.png`:daily/explorer, normal/reduced,30/60Hz; low2 di awal akselerasi lalu kembali ke pose mentah di contact aktual.
- `transition-contact-sheet.png`:56 pose stop/turn existing, dibuat dari PNG runtime.
- `contact-sheet-manifest.json`:hash results dan setiap PNG yang dipakai helper review. Helper hanya memotong hasil render dan memberi caption.
- `restart-before-after-native.png` serta manifest:perbandingan native historical592 pada worktree utama dengan kandidat. Results historical SHA256 `63ebdcc6ca159a0779bc51fdbc1c37b209a1fb6ee3f82e3289874c620c0ad31b`; manifest mencatat hash frame23–27 kedua sumber.

Before actual daily:neutral0 pada24, high3 pada26/28/30, raw4 pada32. After actual daily:neutral0 pada24, low2 pada26/28/30, raw4 pada32. Knee-pop awal berkurang tanpa menggeser jarak atau contact. Pose rendah memang ditahan beberapa sampel; frame4 tetap pose lebar existing. Ini bukan animasi startup baru atau penyelesaian seluruh keluhan kaki membuka/menggunting.

Native ini fixture komponen dengan pivot/root gambar tetap di layar. Actual Player/controller dibuktikan assertion terpisah pada lantai hub legal dengan proyeksi datar. Model sumber menambah perpindahan root terproyeksi pada marker untuk membandingkan drift; gambar fixture tidak boleh dipakai untuk mengklaim telapak terkunci terhadap lantai dunia. Physical left/right tetap `unassigned`; bitmap seluruh badan tidak memberi socket telapak independen. Kontak lintas32 tidak disambungkan seolah kaki support yang sama.

## Penerimaan dan langkah berikutnya

Source dan focused/native tersedia untuk integrator sebagai perbaikan parsial. Sebelum masuk image selanjutnya, integrator perlu meninjau contact sheets, menggabungkan source, lalu menjalankan suite gabungan dan browser aktual. Paket rilis yang sedang dibangun tidak diubah. Belum ada bukti restart world3D di tangga/lereng, browser actual, seluruh arah/identitas/pakaian, Windows atau Samsung S23 fisik. Tidak ada alasan membuat batch raster baru dalam paket kecil ini; perbaikan seluruh siklus dan sole lock masih memerlukan review animator tersendiri.

Command reproduksi setelah izin slot engine:

```sh
GODOT_BIN=/Users/ardianryan/Documents/Jalasmara/.runtime/godot/Godot.app/Contents/MacOS/Godot
"$GODOT_BIN" --headless --path client-godot --script "$PWD/scripts/tests/player-locomotion.gd"
NALA_GAIT_CAPTURE=1 "$GODOT_BIN" --path client-godot --rendering-method gl_compatibility --resolution 960x540 --position 40,60 --always-on-top --script "$PWD/scripts/tests/player-locomotion.gd"
python3 tools/player-gait/review_runtime_sequence.py artifacts/godot/nala-gait-transitions
```

Tool aktual:Git,Python3/Pillow,Godot lokal, pembacaan source/JSON/log, dan `view_image`. Atlas original proyek existing dipakai tanpa regenerasi; tidak ada API key, layanan berbayar, MCP, imagegen, raster moodboard, lisensi, atau dependensi baru. Header MIT port kamera existing tetap dipertahankan. Handoff/PRD dan source daratan integrator tidak disentuh.

## Pemeriksaan dunia gabungan sesudah review integrator

Integrator menerima perbaikan startup yang terbatas untuk kandidat followup, tetap terpisah dari image rilis5f5. Dengan grant engine kedua, `GODOT_BIN=/Users/ardianryan/Documents/Jalasmara/.runtime/godot/Godot.app/Contents/MacOS/Godot npm run check:world` dijalankan pada source kandidat `62a8538134c4c190aa756d4a08f029a65aea9819`.

Hasil sendiri: **50/50 world checks PASS**, dilanjutkan verifikasi **10 spesies/722 frame**. Jumlah waktu50 check80,957 detik. Scan seluruh log tidak menemukan `SCRIPT ERROR`, `ERROR:`, parse error, atau load failure. Ada dua peringatan cleanup yang tetap dicatat:4ObjectDB instances saat `locomotion-collision-foley.gd` keluar dan2ObjectDB instances saat `balai-resident-interaction.gd` keluar. Keduanya bukan assertion failure; paket ini tidak mengklaim bersih dari leak warning atau menekan warning itu.

Bukti pada worktree yang sama:

- `.runtime/nala-restart-full-world.log`, SHA256 `7354d2922a3c449b05e35d5af599925fe1f6113e635d43d9d0f1237386af90cd`.
- `.runtime/world-check/world-checks.json`, SHA256 `d0f50f3ce675dd8659a0d7650789d353d4d865c28b19d8d38846c58a249c1220`;50 status `passed` dan elapsed tiap script.
- `.runtime/nala-restart-full-world-summary.json`, ringkasan hasil/error/warning dan hash sumber bukti.
- `.runtime/world-map.json`,93.747 byte, SHA256 `6b044603aed383f94a799b53e9ac5f9d90df7ef5add592bdd27e5dfe890a757d`.

`git diff a30b35c cc6b514 -- client-godot packages/shared scripts/tests` kosong: basis runtime daratan/controller dunia kandidat sama dengan main yang saat itu diterima integrator, selain perubahan pilot pada branch ini. Tidak ada ekspor, perubahan raster, browser, push main, atau perubahan image. Semua proses Godot selesai dan slot engine dilepas eksplisit. Suite penuh ini memperkuat regresi source; batas visual/anatomi/world3D/browser/perangkat yang dijelaskan di atas tetap berlaku.
