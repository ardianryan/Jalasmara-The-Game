# Tangkapan hidup → induk → dua hari diberi pakan → panen

Actual browser lokal, 10 November2026: **8 pemeriksaan PASS**, exit0, `completed=true`, cleanup lengkap. Ini menutup batas akuisisi/pembiakan yang sengaja belum dibuktikan oleh smoke kebun terdahulu.

## Provenance dan reproduksi

- Integrasi saat preflight `cca08d0`; saat selesai HEAD `f9e9d69` berisi pembaruan laporan. Tidak mengubah runtime selama pengujian.
- Preview `http://localhost:3111`, API/image source `798a47b`, runtime export `593dc79`.
- PCK SHA256 `1315f34672b0fc5694a5f73684ca68bfbc6b5be1f6f4560b9628cc14ac2ef5e0`, **64.491.320 byte**. Seluruh hash/byte diperiksa sebelum fixture dibuat.
- Harness merged `scripts/live-parent-cycle-browser.mjs`, navigasi laut dan cleanup auth dari `1c38dd6`, `7af5aab`, `68ab853`. Tidak memakai akun/data owner.
- Fixture UUID `2fe51904-6362-40d0-80f7-303f799df9d3`; viewport844×390; Chromium Playwright/ANGLE SwiftShader. Batas18menit aktif ditentukan sebelum run. Run selesai sekitar15menit; heartbeat terakhir870detik, tanpa memperpanjang batas atau mengulang dengan stok pengganti.

```sh
APP_TEST_ORIGIN=http://localhost:3111 \
PLAN06_EXPECT_PCK=1315f34672b0fc5694a5f73684ca68bfbc6b5be1f6f4560b9628cc14ac2ef5e0 \
PLAN06_EXPECT_PCK_BYTES=64491320 \
node --import tsx scripts/live-parent-cycle-browser.mjs
```

Setup dinyatakan: cerita hari2, izin kebun, tutorial/misi akses, kalender hari2 kering08:00,250koin, semua upgrade level3, dan posisi awal tangga desa `(1485,1330)`. **Inventory, tangkapan hidup, induk, anak dan seluruh hasil kebun awal kosong.** Setelah setup, tidak ada teleport, perubahan database/tanggal, injeksi loot, atau penggantian aksi game dengan endpoint langsung. GET state hanya membaca ledger; tulis gameplay berasal dari input UI/kontrol game.

## Delapan pemeriksaan aktual

1. Tangkap `ekosistem` melalui gerakan keyboard dan Space jala: server Bintang3, live session1, oksigen208,496. Homestead liveCatch masih0 sebelum ekstraksi.
2. Tangkap `netralisasi` melalui jala: server Bintang3, live session2, oksigen207,345. Homestead liveCatch tetap0.
3. Berenang ke perahu, ekstraksi UI tanpa pingsan: liveCatch homestead menjadi2; inventory terpisah menyimpan masing-masing satu fragmen Bintang3.
4. Berjalan melalui jalur/tangga desa ke keramba, stok UI: liveCatch2→0, induk0→2, progres0/anak0.
5. Pakan hari2 seharga2koin, berjalan ke Griya, masuk/jalan ke dipan/tidur UI: kalender2→3, progres0→1, anak0, induk2. Hari cerita tetap2/stage tidak berubah.
6. Keluar/jalan kembali ke keramba, pakan hari3 seharga2koin, tidur UI berikutnya: kalender3→4, progres1→0, anak0→1, induk2; cerita tetap.
7. Keluar dan kembali secara fisik, panen UI: anak1→0, hasil `ikan_seruni`0→1; induk2 tetap. Total koin250→246 dan dua fragmen ilmu tetap utuh.
8. Reload browser, baca state kanonis: ledger induk/hasil/koin/inventory/version/revision sama sebelum dan sesudah reload.

| Keadaan | Version/revision | Kalender | Koin | Live/induk/progres/anak | Hasil ikan |
| --- | --- | --- | --- | --- | --- |
| Awal | 0/0 | 2 | 250 | 0/0/0/0 | 0 |
| Ekstraksi | 1/2 | 2 | 250 | 2/0/0/0 | 0 |
| Stok induk | 2/3 | 2 | 250 | 0/2/0/0 | 0 |
| Tidur pertama | 5/7 | 3 | 248 | 0/2/1/0 | 0 |
| Tidur kedua | 9/12 | 4 | 246 | 0/2/0/1 | 0 |
| Panen/reload | 11/14 | 4 | 246 | 0/2/0/0 | 1 |

Terdapat808 respons API, seluruhnya200; nol page/console error dan nol unexpected API failure. Dua koleksi server Bintang3 memiliki selang ACK net→REQUEST collect **1202,740ms** dan **917,695ms**. Ini timestamp monotonic klien untuk diagnosis, bukan pembacaan langsung waktu charge server. Tidak memperbesar jendela Bintang3 atau memasang fallback bila gagal.

## Bukti dan cleanup

Direktori lengkap di worktree integrasi:

`artifacts/browser/live-parent-2fe51904-6362-40d0-80f7-303f799df9d3/`

- `results.json`:310.385byte; SHA256 `c409152c31fa2aed204b9732ce7ad2695bc8991024191b672564aee1bd18b681`.
- `01-actual-live-parent.png`:351.584byte; SHA256 `b28cf64832558f870977f074d49fe8f5f49e45d105ba2e9798ed39960da28cac`.
- `02-actual-live-parent.png`:363.471byte; SHA256 `53e2de1bcdc709b0a5661c78502c8bb6b384088c3379bc9f3619a1ab402178eb`.
- `03-extracted-live-parents.png`:212.173byte; SHA256 `0523a6f22a616cffb2ef5bfe8f036f6a8b4865dc46dccb921095d2f07c4a9a46`.
- `04-actual-fed-settlement.png`:120.972byte; SHA256 `92e61151d9a8ce86ab617a33852e110874338c8ea71f607345d89f146f80febc`.
- `05-actual-fed-settlement.png`:123.047byte; SHA256 `6a93e58b35e447b7380436d22b0f983ead8a72693a5eda5c348b3c13d12b6c70`.
- `06-genuine-offspring-persisted.png`:238.219byte; SHA256 `7f45da1b9cfba3a3e3552a82f1549c21abc524030ae045771ca07b97c60bcd89`.

Dibuka untuk penilaian:01 menampilkan notifikasi tangkapan3bintang dan HUD208/220;03 Nala kembali di dermaga;04 hari3/06:00 dengan cerita siklus2;06 setelah reload menunjukkan246koin/hari4 dekat keramba. State panen/induk dinilai dari respons server dan ledger, bukan ditebak dari jumlah ikan pada screenshot.

`fixtureAttempted=true`, insert acknowledged, `browserClosed=true`, pemain/receipts/shifts milik UUID tidak tersisa. Redis seluruh key fixture dibersihkan; scan auth hanya menghapus JSON dengan userId UUID yang sama dan memastikan `ownAuthKeysRemaining=0`. Tidak ada proses harness/Chromium milik run tersisa saat slot browser dilepas eksplisit ke root. Tidak menyimpan kredensial/cookie/session key dalam laporan.

## Batas bukti

Ini satu jalur browser lokal dengan setup akses/gear/kalender eksplisit. Tidak membuktikan perolehan izin/upgrades dari akun baru, kapasitas penuh keramba, hari tanpa pakan, pingsan, semua spesies, pelaksanaan malam kedai memakai ikan yang sama, atau pertumbuhan Jahe empat hari. Uji API/shortsmoke sebelumnya mempunyai scope sendiri; hasilnya tidak dicampur sebagai langkah browser yang tidak dijalankan di sini. Tidak ada klaim FPS Windows/S23, cadence Nala alami, atau seluruh delapan arah artwork selesai.

Tidak ada perubahan runtime/aset/dependensi pada run ini, tidak ada import/export Godot. Interior warga06-D masih proposal terpisah; rumah Griya yang dilalui di sini bukan penerimaan interior warga baru.
