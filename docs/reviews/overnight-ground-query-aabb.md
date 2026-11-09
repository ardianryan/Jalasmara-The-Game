# Cached scalar bounds, setelah pengukuran

Status source kandidat, belum diuji Godot setelah perubahan bounds. Tidak mengganti predicate, map, collision, layout, atau controller.

## Baseline aktual

Godot4.7.2 headless/root `7a668b5`, `scripts/benchmark-ground-query.gd`, output `artifacts/godot/ground-query-benchmark-first-7a668b5/results.json`, log `.runtime/ground-query-benchmark-first.log`. Semua pasangan selesai, exit0/wall3.209.652µs, tanpa error/warning. Lima pasangan AB/BA/10repetisi dengan324 titik yang sama:

| Area | Packed lama median µs/query | Scalar kanonis median µs/query | Rasio |
| --- | --- | --- | --- |
| Hub | 14,700901 | 208,066667 | 14,15× |
| Forest | 5,005882 | 81,044118 | 16,19× |

Ini bukti biaya query CPU meningkat, bukan angka FPS atau bukti sebab tunggal waktu suite lebih lama. Fungsi baseline menyalin urutan priority/connector lama dan mengambil cache yang sama; keduanya menulis checksum. Correctness324+12/991checks dibuktikan fixture terpisah, tidak ditentukan kecepatan baseline.

## Perubahan minimum terukur berikutnya

`LandGeometry.polygon_bounds` menghitung min/max raw scalar polygon sekali saat cache area dibangun, lalu memperluas keempat sisi **1e-7** secara konservatif. Bukan Rect2/PackedVector2 sehingga koordinat manifest tidak dibulatkan float32. Query `cached_point_in_polygon` menolak titik di luar bounds; titik yang lolos tetap diperiksa rumus scalar `point_in_polygon` dengan boundary strict distance<1e-7 yang sama. Tidak ada Array/Dictionary baru dibuat per query.

Priority terbesar/last-surface, tinggi48perlevel serta connector tetap. Packed polygon diagnosis juga tetap. Empty polygon menghasilkan bounds kosong yang menolak membership.

Corpus generator independen ditambah8 kasus sekitar AABB±epsilon dan raw coordinate1.000000095, sehingga total20 kasus polygon. **324 ground cases dan metadata dibandingkan deep equality terhadap corpus sebelum perubahan dan tetap identik**. Fixture memeriksa cached-vs-scalar membership pada seluruh pasangan posisi/surface, serta ground_height produksi dan frozen truth. Tidak mengganti expected yang gagal agar sesuai optimasi.

CPU yang telah dilakukan: generator324+20, deep equality324+metadata, `node --check`, `git diff --check`. Godot/parity dan benchmark after masih menunggu grant. Root perlu menjalankan fixture correctness terlebih dahulu, baru benchmark script yang sama pada output unik, lalu membandingkan raw pair counts/checksum/median. Tidak ada threshold timing CI baru dan tidak ada optimasi lanjutan sebelum hasil tersebut.
