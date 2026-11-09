# Audit CPU batas ketinggian di luar connector

10 November2026. Permintaan root: cari counterexample nyata di polygon permukaan/priority di luar connector, karena limiter karakter baru memotong persegi connector. Baca source dan jalankan perhitungan Node/tsx saja; tidak menjalankan Godot/browser atau mengubah runtime.

Manifest berasal dari `WORLD` aktual worktree `Jalasmara-overnight-integration`, HEAD `2702bca`, sesudah paket ekspor `593dc79` dengan runtime/PCK1315 tetap. SHA256 source `land.ts`: `0f2b0d1855ff92a9e0bd5c32ac0821cda1bfe0bc248169b52957f398e25b8fef`. Evaluasi memakai fungsi server `landPointInPolygon`, `isLandWalkable`, dan `isLandSegmentWalkable` dari source bersama aktual. Reproduksi tinggi mengikuti `_surface_queries`/`ground_height`: seluruh surface termasuk walkablefalse, `elevation*48`, priority terbesar, surface terakhir menang bila priority sama. Nilai dasar0. Connector dikeluarkan dengan predicate progress0–1 dan jarak lateral≤width/2 yang sama dengan `connector_ground`.

Pada setiap sisi polygon, sampel midpoint interval berjarak maksimal4unit logis, bandingkan titik normal±0,001 di dua sisi. Cari tinggi berbeda, pastikan kedua titik di luar semua connector, lalu persyaratkan **kedua titik serta segmen penghubung walkable pada radius12**. Jalur yang gagal salah satu guard tidak disebut counterexample yang dapat ditempuh. Tidak menghapus collider atau mengabaikan margin tubuh untuk menghasilkan temuan.

| Area | Surface / connector | Probe sisi | Perubahan tinggi | Perubahan di luar connector | Pasangan perubahan yang sah |
| --- | --- | --- | --- | --- | --- |
| Hub | 78 / 4 | 10.854 | 3.241 | 2.785 | **0** |
| Forest | 24 / 0 | 5.908 | 0 | 0 | **0** |

Scan awal terpisah pada11fraksi setiap sisi (.05,.1,.2,.25,.35,.5,.65,.75,.8,.9,.95) juga tidak menemukan pasangan sah. Scan rapat di atas memperluas cakupan, bukan bukti analitik untuk setiap titik. Tidak ada koordinat counterexample nonconnector yang dapat dilaporkan secara jujur dari pemeriksaan ini. Priority/tebing/tepi air yang memang mempunyai lompatan ketinggian belum menghasilkan dua endpoint sah pada margin tubuh tersebut.

Temuan sisi dock_gangway terdahulu tetap berlaku tetapi **merupakan batas connector**, sehingga tidak dihitung sebagai temuan baru di sini. Revisi limiter satu sisi ditinjau di [laporan peer](overnight-physical-segment-limiter-peer.md); bukti controller/Godot tetap pekerjaan character/root.

Batas: sampling4unit dapat melewatkan interval sah yang lebih sempit atau perpotongan sudut yang tidak tersampel; tidak membuktikan semua embedding kontinu secara global, collision slide Godot, semantik float32, atau kecepatan actual controller. Tidak perlu mengarang sambungan salah pada forest ketika seluruh surface-nya berketinggian sama. Global enable masih membutuhkan guard jarak aktual dan suite traversal, bukan kesimpulan dari scan ini.
