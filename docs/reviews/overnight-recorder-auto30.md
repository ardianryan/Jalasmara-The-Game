# Perekam performa: kedaluwarsa otomatis 30 detik

Status: penerimaan browser lokal **lulus 4/4** pada 10 November 2026 WIB. Ini melengkapi bukti manual-stop sebelumnya; tidak mengukur perangkat Windows atau Samsung S23 fisik.

Pemeriksaan memakai source host/API `798a47b` pada `http://localhost:3111`, skrip gabungan `781cd30` + format `cca08d0`, dan PCK SHA-256 `1315f34672b0fc5694a5f73684ca68bfbc6b5be1f6f4560b9628cc14ac2ef5e0` (64.491.320 byte, diverifikasi sebelum fixture). Tidak ada perubahan produksi dalam paket laporan ini.

## Perilaku yang benar-benar diuji

- Pemain fixture masuk ke game aktual tanpa mengaktifkan snapshot QA/account penuh, memilih durasi 30 detik, lalu memulai rekaman lewat Menu.
- Input gerak aktual, Menu dibuka selama sekitar 2,2 detik untuk menguji pause, lalu Escape mengembalikan permainan. Tidak ada klik Hentikan rekaman.
- Badge otomatis menjadi siap saat gameplay tetap terlihat. Menu yang dibuka sesudahnya tidak lagi menyediakan aksi Hentikan; tombol unduh menghasilkan JSON browser sebenarnya.
- JSON mencatat `durationMs=30000`, `elapsedMs=30103.200000047684`, `reason=duration-completed`, 28 sampel (26 sampel engine), dan 60 callback ketika menu mem-pause pengukuran. Identitas fixture, kata sandi, URL halaman, token, inventori dan state akun tidak ada dalam laporan unduhan.

Timer memakai durasi dinding host; pause Menu mengecualikan pengukuran, bukan memperpanjang timer. Jalur lima menit belum diuji. GPU yang dilaporkan adalah Chromium ANGLE/SwiftShader, sehingga angka FPS dalam artefak bukan hasil S23/Windows.

## Bukti dan pembersihan

UUID fixture: `8ebb747b-817c-4c8c-8bae-ca2ddad578c8`. Hasil `completed=true`, `outcome=passed`, `ownTemporaryPlayerRemoved=true`; browser, API, dan shutdown masing-masing 0 error. Browser ditutup dan slot dilepas sebelum pekerjaan CPU berikutnya.

Artefak asli berada di worktree `Jalasmara-overnight-integration/artifacts/browser/performance-recorder-8ebb747b-817c-4c8c-8bae-ca2ddad578c8/`: `results.json`, `downloaded-performance.json`, `recording-actual-game.png`, `menu-pauses-recording.png`, `auto30-ready-during-actual-gameplay.png`, dan `download-ready.png`. Log: `.runtime/overnight-recorder-auto30.log`. PNG siap otomatis sudah dilihat: permainan tetap terbuka, HUD dan Menu tidak menutupi karakter.

```sh
APP_TEST_ORIGIN=http://localhost:3111 \
PLAN06_EXPECT_PCK=1315f34672b0fc5694a5f73684ca68bfbc6b5be1f6f4560b9628cc14ac2ef5e0 \
PLAN06_EXPECT_PCK_BYTES=64491320 \
PERFORMANCE_RECORDER_MODE=auto30 \
node --import tsx scripts/performance/recorder-browser.mjs
```

Tool aktual: Node/tsx, Playwright Chromium, game Web Godot yang sudah diekspor, serta peninjauan PNG lokal. Tidak ada build/export baru, perubahan proxy, data owner, atau klaim pengujian perangkat fisik.
