# Peer CPU: prospective foot rotation d014f4e

Source karakter `d014f4ef6be3327248a81a328250cacc254f30aa`, `NalaLowerBody3D.gd:261–287` dan `NalaFootPlane.gd:40–51,73–86`; read-only, tanpa Godot/browser. Perubahan hanya mengizinkan candidate Q yang memang aman walaupun menahan Qlama pada raw pose yang sudah bergerak tidak aman. Tidak ada perubahan raster, dimensi, geometri tanah, ankle target atau tolerance.

## Bound, ankle dan no-safe behavior

`radius_about_ankle` mengambil maksimum norm ke empat sudut texture rectangle original, termasuk transparent extents, dalam basis right dan Z/vertical. Semua opaque pixels ada di dalam rectangle, sehingga R konservatif. Advance memilih angle≤allowance/R; perpindahan sebuah corner terhadap ankle dibatasi `2r sin(θ/2)≤rθ≤Rθ≤allowance`. Quaternion slerp/backtrack membagi angle menuju current menjadi dua, jadi tidak memperbesar budget. Ini batas gerak rotasi, **bukan bukti collision-free swept volume**.

Prospective corner memakai ankle `rawSole+C+A(Qcurrent)`, lalu calon sole `ankle−A(Qnext)`. Saat terpilih, compensation berubah `Cnext=C+A(Qcurrent)−A(Qnext)`, sehingga ankle hasil render `rawSole+Cnext+A(Qnext)` sama dengan ankle yang diuji. Pure rotation tidak memindahkan ankle. Raw translation dan decay C yang sudah terjadi tetap wajib lulus guard independent antarsample; bound ini tidak menjamin semuanya sendiri.

Re-run CPU author tool terhadap captured059 ankle dengan manifest world existing, output `/tmp/jalasmara-peer-orientation-d014.json`:60 original opaque corners; R8.55904572615, step angle0.128758604231, Rθ1.10205078125 tepat allowance1.10205078125; maximum chord bound1.10128966169. Holding min-gap−0.55956915456; bounded proposed angle0.285956644307 memberi min-gap+0.04402730003. Artinya menahan Qlama bukan strategi aman pada raw pose ini; menguji Qnext di ankle yang sama memang diperlukan. Model memakai authored ramp plus captured paint edge, bukan seluruh surface/world.

Clearance diperiksa untuk semua original opaque pixel corners, memakai inverse groundXY dan ground support saat ini; bukan hanya dua heel/toe markers. Jika Qnext gagal, maksimal10 backtrack tetap menjalankan fullmask check. Jika semuanya gagal, source memilih current dan telemetry `selectedClear=false` bila current juga tidak aman. Ini **bukan** jaminan selalu menemukan solusi: interval aman bisa nonmonotonic atau tidak terjangkau dalam budget, dan bounded binary search bukan exhaustive search. Fallback tidak menaikkan kaki/terrain atau mengaku clear; actual independent mesh/fullmask fixture harus menolak unsafe pose tersebut. Grounded contact tetap menolak angle unfinished; fixed-length/opaque/ankle/body guards tidak diubah. Tidak ditemukan blocker baru pada perubahan endpoint-selection ini.

## Cadence: estimasi bukan hasil actual

Character mengonfirmasi angka5.64 dan8.32 berasal dari `100worldXY/treadDepth`: central/west17.7312→5.639776contacts/s, ridge12.0186→8.320437contacts/s **jika** actor maju satu tread per landing pada100worldXY/s. Ini bukan hitungan contacts/time dari actual run. Flat physical contract memakai distance32, sehingga100/32=3.125contacts/s dalam steady window ideal; startup, turn, stop, terrain pacing dan actual solver duration berbeda.

`Player.gd:73`/`Forest.gd:425` masih memakai `SurfaceTraversal.paceScale`, stairs-up0.80/down0.88; controller cap100 adalah maksimum, bukan kecepatan actual universal. `_terrain_duration` juga dapat membesarkan D melebihi tread depth. Karena itu jangan melaporkan contact cadence5.64/8.32 sebagai pengukuran atau menyebut geometrinya natural setelah satu route.

Next movement contract yang layak diuji terpisah:

- Nyatakan batas physical-root worldXY speed serta logical/server cap, kemudian ukur **accepted actual** distance/time setelah accel pada tiap connector/direction.
- Tetapkan urutan satu-tread contacts sebagai constraint geometris, lalu selesaikan lintasan kaki, fixed-leg reach, durasi dan body transfer bersama; D32 global tidak otomatis kompatibel dengan tread12–18 atau curve bound yang ada.
- Jika ingin memakai3.125 sebagai baseline artistik awal, geometric source estimates memberi root speeds55.41/37.558125 untuk central/ridge pada satu tread/contact. Ini **contoh desain bersyarat**, bukan patch speed: memperlambat clock saja tidak mengubah spatial root-to-foot ratio atau membuktikan reach/budget. Solver dan actual accepted phase harus diukur kembali; boleh lebih lambat jika constraint membutuhkan.
- Satu accepted locomotion/contact phase harus menjadi dasar kaki, legacy audio dan authored arm opposition; start/turn/settlement punya fase transisi eksplisit. Jangan memaksa lengan mengikuti contact source yang belum diterima.

Tidak mengimplementasikan kontrak baru, tidak menurunkan guard, dan tidak memperluas avatar/aset lain.

## Actual failure tetap terbuka

Bukti author `artifacts/godot/nala-terrain-dock-up-safe-advance-d014f4e/rejected.json` sudah dibaca: check43 menolak airborne right heel/toe pixel `[10.5,4]` terhadap actual terrain tertinggi48.072006. Jadi CPU endpoint proof di atas tidak menyelesaikan lintasan aktual berikutnya. Tidak ada full16/native/current-flat/cadence/arm acceptance dari review ini; pilot tetap OFF. Parent/author mengelola engine dan perbaikan berikutnya.
