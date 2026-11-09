# Rilis overnight: smoke publik diterima

Kandidat aktif di `https://staging-jalasmara.ardianryan.com` lulus uji browser default pada 10 November 2026, sekitar01.11WIB. Tidak memakai flag HTTP/1, proxy diagnostik, akun pengguna, atau penggantian aset oleh harness.

| Identitas | Nilai |
|---|---|
| Source image/API/website | `798a47b00a8f471069033a0d6419cd201e7aa008` |
| Image aktif | `d044202760953c6cb295df49073f9e44a788f1b672c7618a4d313f8467eb9964` |
| Source ekspor Godot | `593dc7912b4b691363633f198a898196cd18fc5b` |
| PCK yang disajikan | `1315f34672b0fc5694a5f73684ca68bfbc6b5be1f6f4560b9628cc14ac2ef5e0` |
| Ukuran | 64.491.320 byte, 62 bagian |
| CI | [3046335495](https://gitlab.com/ardianryan/jalasmara-the-game/-/pipelines/3046335495), empat job berhasil |
| Rollback | `jalasmara:rollback-overnight-b5b459e`, image d60aab21 |

## Hasil aktual

Lima pemeriksaan lulus: health dan hash seluruh PCK publik; login formulir dengan cookie Secure/HttpOnly/SameSite; berjalan dari dermaga melalui portal ke hutan dan membuka tajuk lokal yang tepat; jurnal dengan sentuhan yang menghentikan gerak/kalender lalu melanjutkannya; save dan reload posisi hutan tanpa perubahan koin atau hari cerita. Satu aktor pemain tetap, kalender36menit aktif, 200koin dan cerita hari1 tidak berubah.

Harness memakai624pulsa keyboard berdasarkan matriks kamera aktual. Durasi rute378.430ms, di bawah batas8menit yang sudah ditetapkan. Tidak ada error browser atau kegagalan API. Akun sementara `a582cbda-55ee-4ca1-bf13-f7e19f94429d` dibersihkan: pemain, receipts, shifts dan Redis keys semuanya nol. Browser ditutup. Seluruh frame memperlihatkan akun uji tanpa email/kredensial.

Pada navigasi pertama, semua62bagian PCK berprotokol HTTP/2 selesai dalam rentang1.868ms dari permintaan bagian pertama sampai bagian terakhir selesai. Sampel pertama yang mengamati game siap berada14.069ms setelah dokumen game HTTP200 mulai diminta; ini batas waktu observasi, bukan pengukuran presisi titik siap. WASM ikut selesai. Reload kedua juga mencapai game siap dan mengembalikan posisi. Kedua navigasi dibedakan dalam trace; jangan menghitung124bagian gabungan sebagai satu unduhan.

Uji ini menggunakan Chromium/WebGL dengan SwiftShader dan sentuhan melalui CDP. Bukti tersebut menutup blocker startup/rute default publik pada kandidat ini, **bukan** FPS GPU Samsung S23/Windows. Baseline publik5f5 sebelumnya timeout120detik tetap tercatat; perbandingan ini bukan benchmark rasio kecepatan lintas perangkat.

## Bukti dan reproduksi

- `artifacts/browser/staging-plan06-a582cbda-55ee-4ca1-bf13-f7e19f94429d/results.json`, 385.558byte, SHA256 `4b4a6c1f5ad7f669497e018bc8ba61ca5cef483f396cc32b0745cd45dafbad04`.
- Empat PNG asli: dermaga siap, tajuk hutan667×375, jurnal menjeda gerak, posisi setelah reload. Dua gambar dikurasi tanpa modifikasi ke [galeri](../visual/README.md).
- Log `.runtime/overnight-public-smoke.log` menyimpan trace setiap transfer, header/protokol dan tahap startup.

```sh
RUN_STAGING_SMOKE=plan06-public \
PLAN06_EXPECT_PCK=1315f34672b0fc5694a5f73684ca68bfbc6b5be1f6f4560b9628cc14ac2ef5e0 \
PLAN06_EXPECT_PCK_BYTES=64491320 STAGING_STARTUP_TRACE=1 \
node --import tsx scripts/staging-plan06-smoke.mjs
```

Jalankan serial dengan Godot/browser lain. Harness membuat dan menghapus UUID miliknya sendiri; tidak menggunakan akun yang sudah ada. Tidak perlu mengulang smoke setelah perubahan dokumentasi/QA saja.

## Batas dan tindak lanjut

[CI](overnight-ci-candidate.md) membuktikan61pemeriksaan dunia/120API/tiga audit dependensi nol; [SARIF](overnight-final-ci-sarif-798a47b.md) masih memiliki satu warning dan dua notes. [Packaging](overnight-container-build.md) mencatat kegagalan Docker dan script operator, backup yang direstore, serta aktivasi sebenarnya. Data, `.env`, container Mongo/Redis, bind dan sharedproxy dipertahankan; tidak reseed.

Kandidat sudah mencakup HUD ringkas, rumah lurah/RV, rutinitas/Laskar, jahe, keramba dan FishGen dekoratif. Namun pilot kaki modular Nala tetapOFF; kontak tangga dan ritme gerak belum diterima. Browser akuisisi tangkapan sampai berkembang biak, recorder otomatis dan perangkat fisik masih berikutnya. Seluruh delapan jalur tidak dinyatakan selesai karena smoke rilis lulus.
