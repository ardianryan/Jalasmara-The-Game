# Kandidat predicate lantai kanonis

Status awal: source terisolasi, **belum diparse/dijalankan Godot**. Perbaikan ini berdiri sendiri dari pilot Nala yang tetap OFF; tidak mengganti controller, collision, map, layout, mesh atau kalender.

## Reproduksi aktual sebelum perubahan

Character menjalankan diagnosis Godot `59b9c84`,5,94detik/exit1, artefak `Jalasmara-overnight-character/artifacts/godot/nala-physical-dock-priority-59b9c84/endpoint-diagnostic.json`. Pada `(1135.271484375,1124.9990234375)` connector sudah tidak aktif, tetapi `Geometry2D.is_point_in_polygon` masih memasukkan `dock_gangway_floor` tinggi0/priority30. Ia mengalahkan lower_court tinggi48/priority0 serta dirt tinggi48/priority4. Sedikit lebih jauh di y1124.989990234375 surface dock tidak lagi cocok dan tinggi kembali48.

Akibatnya terdapat48→0→48 serta loncatan XY≈68,55unit tepat setelah ramp atas. Helper limiter benar menolak loncatan; menaikkan tolerance helper akan menyembunyikan kesalahan pemilihan lantai. Data polygon server dan query scalar kanonis tidak memasukkan titik y1124.999023 ke dock.

## Perubahan minimum

- `LandGeometry.gd` memport rumus scalar `landDistanceToSegment` dan `landPointInPolygon` shared: distance clampedsegment, boundary **strict `<1e-7`**, ray parity. Operasi memakai scalar float64, bukan toleransi Geometry2D.
- `_cache_ground_queries` menyimpan raw polygon manifest sebagai `canonicalPolygon` sekali per build area. `polygon` PackedVector2Array lama tetap tersedia untuk diagnosis, tidak dipakai lagi untuk memilih tinggi surface.
- `ground_height` hanya mengganti predicate membership. Priority terbesar, surface terakhir saat priority sama, elevasi48/level dan override connector tidak berubah.
- Tidak mengganti Geometry2D global atau LandCollision. Ini memperbaiki pemilihan floor dalam renderer, bukan memperlebar lantai atau mengubah route/save.

Port adalah kode proyek sendiri dari shared yang sudah ada; tidak menambahkan dependency/aset/lisensi upstream baru.

## Fixture dan penerimaan berikutnya

`scripts/tests/ground-query-canonical.gd` membaca manifest `.runtime/world-map.json` serta corpus beku independen `fixtures/ground-query-canonical.json`:324 posisi aktual hub/forest,12 kasus edge/concave/rawscalar dan3 assertion hardcoded endpoint di atas harus48. Corpus dibuat CPU dari **fungsi server aktual** melalui `scripts/generate-ground-query-canonical.mjs`, bukan dari helper Godot yang diuji. Input posisi dibulatkan Math.fround agar sama dengan Vector2 controller; polygon tetap angka manifest scalar. Semua connector endpoints diuji pada offset−.01/−.001/0/.001/.01 dengan center dan dua posisi lateral. Surface identity/order/version beku membuat perubahan manifest memerlukan review, bukan auto-regenerate saat tes.

Pemeriksaan CPU yang dijalankan: generator berhasil324+12, `node --check`, `git diff --check`. Belum ada kelulusan Godot dari langkah ini.

Usulan registrasi root: tambahkan `scripts/tests/ground-query-canonical.gd` dekat `land-renderer`/`surface-traversal` dalam `scripts/verify-living-world.mjs`. Root memegang runner. Setelah grant: parse/focused scalar corpus, actual character input-only dock+side; ulang ground/tread/renderer/left-controller suites dan fullworld bila kandidat diterima. Jalankan native/browser paket baru sebelum menyebut perbaikan ada di rilis.

## Focused pertama pada integrasi

Root menggabungkan source sebagai `75b866a` dan memberi slot headless≤30detik. Godot4.7.2 menjalankan fixture pada cache integrasi yang sudah ada. Log `.runtime/ground-query-canonical-first.log` **FAIL** pada perbandingan membership di `(1135.271484375,1125)`, frozen indices `[7,11,40,41]` dibaca sebagai float JSON. Parse source berhasil; ini belum kelulusan predicate. Fixture berhenti lebih dini sebelum renderer dibebaskan sehingga log juga memuat leak/resource errors; kegagalan tersebut tidak disembunyikan.

Revisi fixture `08d2c64` menormalkan expected dan actual index menjadi `Array[int]` sebelum perbandingan tepat, menampilkan kedua array bila gagal, serta membebaskan renderer pada exit gagal. Predicate runtime tidak berubah. Normalisasi tipe adalah hipotesis penyebab perbandingan pertama; rerun actual masih diperlukan untuk membuktikannya. Engine dilepas ke root setelah run pertama, tidak mengulang tanpa grant.

## Rerun actual diterima pada scope focused

Root menggabungkan revisi fixture sebagai `cf28881`, kemudian memberikan slot eksklusif ulang≤30detik. Godot4.7.2 headless pada worktree/cache integrasi menghasilkan **PASS, exit0:324 posisi ground aktual +12 kasus scalar independen,991 pemeriksaan**. Terdapat **64 perbedaan membership Geometry2D lama** terhadap predicate scalar/server; jumlah itu dipertahankan sebagai diagnosis, bukan disembunyikan dengan epsilon baru.

Log lengkap `.runtime/ground-query-canonical-typed-rerun.log` hanya berisi versi engine dan baris PASS; tidak ada SCRIPT ERROR, ERROR, warning, atau leak. Titik aktual `(1135.271484375,1124.9990234375)` dan dua tetangganya kini dipastikan ground_height48 melalui method renderer produksi, selain corpus membership/priority/connector. Ini mengonfirmasi runtime predicate, bukan hanya perbaikan tipe fixture.

Tidak menjalankan suite lebih luas/export/browser. Engine selesai dan slot dilepas eksplisit, pgrep Godot kosong. Perubahan belum menjadi bukti gait/connector traversal aktual atau paket staging baru; character/root melanjutkan gate tersebut dan registrasi runner.
