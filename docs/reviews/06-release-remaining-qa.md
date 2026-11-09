# Penutupan QA untuk rilis runtime f319da9

9 November 2026. Branch `work/06-release-qa`, worktree `Jalasmara-06-release-qa`, baseline main `f319da9`. Ownership hanya tiga script QA dan laporan ini. Runtime/API/website/aset tidak berubah. Integrator menangani build/deployment dan handoff bersama.

## Persiapan yang selesai

- `night-home-browser.mjs` dan `staging-plan06-smoke.mjs` membaca `land.view.motion` aktual memakai consumer keyboard pulse yang sudah ada. Perjalanan memakai `physicalRoute` dan geometri manifest saat itu; interior rumah tetap memakai input dx/dy. Kontrol produk tidak diubah agar cocok harness.
- Kedua script wajib menerima `PLAN06_EXPECT_PCK` dan `PLAN06_EXPECT_PCK_BYTES`, mengunduh serta memeriksa SHA/byte sebelum fixture dibuat. Pin lama staging dihapus, tetapi origin HTTPS staging dan flag konfirmasi eksplisit tetap dipatok. Tidak ada SSH/fixture publik yang dijalankan pada tahap persiapan.
- Night memakai artifact UUID terpisah, budget delapan menit, progress fase serta cleanup dengan assertion nol pada player, receipt, shift, cache/sesi miliknya. Kredensial tidak dicetak atau disimpan dalam laporan.
- Mode `shelters` pada `plan06-layout-browser.mjs` menguji tujuh warga tiba secara alami pada shelter hujan malam, akses tiap percakapan dan resume, capture sebelum/saat dialog serta progres/reward tidak berubah. Mode `lower` memakai save awal forest sah pada pendekatan bridge lower, menyeberang melalui input nyata dan memeriksa save/reload. Kedua mode memakai UUID berbeda; tidak mengulang prefix rumah, migrasi atau jembatan atas yang sudah terbukti.

Pemeriksaan CPU aktual: syntax Node tiga script, Prettier, diff-check dan consumer test **4/4 PASS**. Guard pin wajib juga diuji dengan import terkendali: night menolak sebelum network/fixture, staging menolak sebelum network/SSH/fixture. Tidak ada browser/Godot/database mutation pada tahap tersebut.

## Paket lokal dan command

API production lokal `http://localhost:3101`, Mongo replica-set 27018, Redis6380. Runtime/PCK target **`5f2aaa46778d8735e7316b34d2865ad8ad40877d537d81b9a2dc1d31e8d69038` / 64.304.668 B**. Ketiga run berikut harus bergiliran dalam slot browser yang diberikan integrator.

```sh
VERIFY_COMPACT_NIGHT=1 APP_TEST_ORIGIN=http://localhost:3101 \
PLAN06_EXPECT_PCK=5f2aaa46778d8735e7316b34d2865ad8ad40877d537d81b9a2dc1d31e8d69038 \
PLAN06_EXPECT_PCK_BYTES=64304668 \
node --import tsx scripts/night-home-browser.mjs

PLAN06_ROUTE_MODE=shelters APP_TEST_ORIGIN=http://localhost:3101 \
PLAN06_EXPECT_PCK=5f2aaa46778d8735e7316b34d2865ad8ad40877d537d81b9a2dc1d31e8d69038 \
PLAN06_EXPECT_PCK_BYTES=64304668 \
node --import tsx scripts/plan06-layout-browser.mjs

PLAN06_ROUTE_MODE=lower APP_TEST_ORIGIN=http://localhost:3101 \
PLAN06_EXPECT_PCK=5f2aaa46778d8735e7316b34d2865ad8ad40877d537d81b9a2dc1d31e8d69038 \
PLAN06_EXPECT_PCK_BYTES=64304668 \
node --import tsx scripts/plan06-layout-browser.mjs
```

Status saat persiapan dicatat: **pengujian lokal baru belum dijalankan**. Setelah lokal selesai, public smoke memakai script staging yang diperbarui hanya setelah integrator benar-benar memasang rilis dan memberikan grant. Pin harus berasal dari paket yang hendak dirilis, bukan diasumsikan dari isi halaman.

## Batas

Playwright Chromium/SwiftShader dan CDP sentuh merupakan emulasi, bukan Windows/S23 fisik atau pengukuran FPS perangkat. Membuka percakapan tidak sendiri membuktikan seluruh tubuh/alat di bawah atap benar secara visual; capture sebelum dialog dan bukti native tetap ditinjau. Semua hasil gagal, cleanup serta pin/source berikutnya ditambahkan sebagai riwayat. Tidak menambah tool gambar, dependensi engine, atau atribusi upstream baru dalam paket QA ini.

## Night pertama: rute harness gagal sebelum transaksi

Run lokal pertama pada PCK5f membuat UUID `33c89b96-4262-4fae-bef2-d30afdeaf311`. Ia attach dan bergerak dengan 67 pulse matriks, lalu berhenti di `[1037.33,1031.84]` pada post serambi Tedi saat menuju waypoint `[600,950]`. Belum ada transaksi/check selesai; error JavaScript dan API gagal sama-sama nol. Cleanup assertion lulus. Bukti `artifacts/browser/night-home-33c89b96-4262-4fae-bef2-d30afdeaf311/failure.png` diperiksa; log `/tmp/jalasmara-06-release-night.log` dan results dipertahankan.

Pemeriksaan geometri actual-vs-authored: segmen ideal `[1120,1000]→[600,950]` sah, tetapi segmen dari posisi aktual yang berhenti terlalu dini tidak sah. Arrival15unit dapat memotong sudut dekat support saat melanjutkan segmen panjang; post runtime memang menahan pemain. Toleransi arrival pada daratan aktual diperketat menjadi5unit di ketiga harness, sedangkan interior/selam mempertahankan15. Produk/collider tidak diubah. Night juga menyimpan diagnostics tiap capture agar kegagalan berikutnya dapat diperiksa. Pengulangan belum dianggap lulus sampai dijalankan.
