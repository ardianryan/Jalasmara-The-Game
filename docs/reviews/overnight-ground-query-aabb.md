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

## Hasil actual AABB, root4795d28

Root menggabungkan kandidat dan memberikan slot eksklusif focused→benchmark≤30detik. Godot4.7.2 pada cache integrasi yang sama: **correctness PASS, exit0,324ground+20scalar cases/20.783checks**,64 membership differences Geometry2D lama tetap. Seluruh pasangan cached/uncached scalar identik; strict boundary/raw AABB cases lulus. Log `.runtime/ground-query-canonical-aabb.log` bersih dari error/warning.

Script benchmark yang sama selesai exit0, wall877.065µs, lima pasangan AB/BA per area. Raw query counts dan checksum setiap mode/area/ronde dibandingkan terhadap run sebelum dan **sama persis**; tidak membandingkan batch parsial atau expected truth yang diganti.

| Area | Packed lama median µs/query pada run after | Kanonis+AABB median µs/query | Scalar sebelum → after |
| --- | --- | --- | --- |
| Hub | 15,129279 | 32,230631 | 208,066667→32,230631;6,46× lebih cepat |
| Forest | 5,023529 | 16,120588 | 81,044118→16,120588;5,03× lebih cepat |

Predicate kanonis masih2,13×/3,21× biaya baseline native lama. Jangan menyebutnya sama cepat atau memakai waktu benchmark untuk menjanjikan FPS. Artefak `artifacts/godot/ground-query-benchmark-aabb-4795d28/results.json`, log `.runtime/ground-query-benchmark-aabb.log`; sumber before dan after terpisah sehingga pengaruh sistem lain tetap batas bukti, walau baseline native antar-run dekat.

Tidak menjalankan fullsuite/export/browser. Semua proses Godot selesai dan slot dilepas eksplisit kepada root; website consumer fixture antre berikutnya. Runtime integrator masih memerlukan suite/paket aktual sendiri sebelum rilis.
