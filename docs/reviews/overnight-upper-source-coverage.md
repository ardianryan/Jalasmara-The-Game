# Tubuh atas Nala: cakupan sumber asli

Audit CPU/visual source karakter `59f0356`, tanpa engine, generator gambar, raster baru atau perubahan pixel. Data terstruktur baru: [upper-source-coverage.json](../../tools/player-gait/upper-source-coverage.json). Berkas anotasi/generator karakter tetap milik lane character dan tidak diubah.

Dibuka langsung: contact sheet64sel tubuh atas daily, delapan crop WEST asli, idle front/WEST berkoordinat, front frame0/4 berkoordinat, serta atlas explorer asli1024×1024. Hash semua sumber dan artefak ada dalam JSON. Pillow hanya membaca RGBA/crop di memori untuk pemeriksaan dan hash; tidak menulis PNG. Aset tetap sumber original proyek dengan provenance existing; tidak menambahkan aset upstream/lisensi baru.

## Temuan yang terlihat

**WEST/view4 tidak mempunyai backswing near-arm yang lengkap pada delapan frame walk yang ditinjau.** Posisi lengan berubah sedikit tetapi tetap di depan tubuh. Menggeser phase kolom tidak menciptakan pose belakang yang tidak tergambar. Idle WEST menawarkan lengan menggantung, tetapi menutup bagian torso yang berbeda; ia bukan bukti adanya plate baju bersih di bawah lengan walk.

**SOUTH/view2 paling layak menjadi awal pilot modular terbatas.** Frame0/4 mempunyai kedua telapak yang teridentifikasi dari pixel sumber daily/explorer pada anotasi existing. Itu mendukung arah forward-arm yang berlawanan pada dua pose, bukan membuktikan seluruh kurva/runtime opposition. Forearm yang melintas masih menutupi baju; menghapusnya tidak boleh dianggap otomatis membuka torso bersih.

Lima patch interior baju daily yang konservatif dicatat dengan rect asli, jumlah opaque dan SHA rawRGBA: core SOUTH frame0/4 masing-masing60pixel, posterior WEST frame0/3/7 masing-masing60/42/45pixel. Semuanya opaque dan secara visual bagian kain, **bukan** mask torso penuh atau izin mengisi daerah tersembunyi. Per-frame shading/registrasi berbeda; jangan menyalin patch antar-frame hanya karena kotaknya berdekatan.

Tiga landmark palm WEST daily diperiksa RGBA asli. Ada counterexample reuse outfit yang konkret: WESTframe7 pixel `(50,57)` daily adalah kulit opaque `[218,163,115,255]`, explorer transparent `[0,0,0,0]`. Explorer mempunyai vest/strap berbeda; mask dan palm daily tidak boleh diterapkan diam-diam pada explorer. Front marks kedua outfit tetap sah pada scope anotasi existing.

EAST/SE/NE menunjukkan perubahan pose lengan yang bisa diteliti untuk mask asli, tetapi belum dianotasi anatomical side/joint. SW/WEST tidak mempunyai reverse extreme yang dapat saya terima dari lembar ini. NW dan NORTH mempunyai overlap/depth yang belum terbukti; central rear shirt terlihat tetapi tidak menjelaskan swing out-of-plane. JSON mempertahankan unknown per view, tanpa menyebut seluruh delapan view modular sudah siap.

## Rute remediasi yang dibenarkan sumber

1. Mulai SOUTH satu outfit: anotasi mask pixel-run shoulder/upper arm/forearm/hand dari frame sumber yang terlihat dan anchor joint sebenarnya. Pisahkan props dari lengan. Pertahankan pixels head/shirt yang sah.
2. Buktikan rest recomposition1:1: tidak ada dua sleeve/tangan, tidak ada alpha hole yang diisi tebakan, dan setiap pixel keluaran menunjuk texel sumber. Daerah baju yang belum pernah terlihat tetap unknown/blocker lokal.
3. Untuk WEST, buat coverage union same-view hanya setelah registrasi posisi/shading antar-frame dibuktikan. Patch kecil audit ini tidak cukup untuk menyatakan full shirt plate tersedia. Bila daerah yang diperlukan tetap tertutup pada semua frame/idle, catat kebutuhan authoring tersendiri; jangan melabeli phase shift sebagai penyelesaian artwork.
4. Baru hubungkan gerak lengan independen ke kontak kaki yang benar, tinjau native sequence pada zoom gameplay dan semua contact/stop/turn yang dicakup. SOURCE coverage, mask reconstruction, geometri dan cadence adalah gate berbeda.

Tidak ada perubahan rig/runtime, tidak ada mask final atau gambar baru. Seluruh view modular-upper masih belum diterima. Validasi data CPU memeriksa hash sumber, hash267pixel patch daily, alpha255, palm RGBA dan counterexample explorer; itu membuktikan asal pixel yang disebut, bukan kualitas animasi.
