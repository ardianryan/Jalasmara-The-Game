# 06-A3/A4 — sambungan platform dan relief gua

Lane `work/06a-laut`, berangkat dari source `2da6854` (runtime dasar `efdacba`). Perubahan terbatas pada geometri belakang laut. Tidak mengubah terrain/kontur otoritatif, posisi interaksi, collider, save, oksigen, ekonomi, arus, foam, HUD atau kamera. Tidak menambah dependensi maupun aset gambar: atlas batu proyek dan tiga model GLB perpustakaan yang sudah ada tetap digunakan.

## Baseline baru dan perubahan

Baseline enam shot dibuat pada worktree ini **sebelum** perubahan runtime. Platform13 `[540,700,340,140]` sudah mempunyai akar ke terrain4; masalahnya bukan hilangnya penopang. Bahu yang sempit serta nilai material dekat dinding gua membuat akar mudah terlewat. `CaveRearRockWall` sebelumnya empat segitiga dengan perimeter empat sisi yang panjang.

- Hanya akar `terrain13 → terrain4` mendapat profil collar: bahu melebar di bawah ledge, badan menyempit, kaki melebar ke batu bawah. Seluruh vertex bahu/kaki masih berada dalam kontur sumber/tujuan yang sama. Reliefnya berada sekitar depth−222..−126, tetap di belakang bidang renang. Warna batu sedikit lebih hangat/terang daripada dinding jauh; bukan lapisan glow atau fog.
- Dinding gua memakai outline30vertex berlekuk dan tiga pita relief nyata pada depth sekitar−728..−537. Ring yang bertemu menggunakan fungsi depth identik. Tepian bersama benar-benar tersambung; tekstur tetap memakai world UV/material batu yang sama.
- Akar lain tetap memakai profil lama. Seluruh akar mempertahankan parallax0. Ketiga GLB dekoratif tetap pada pemasangan terhitung sebelumnya, depth26.74/32.16/38.40; tidak diratakan menjadi sprite atau dipindah ke air bebas.

## Bukti dan reproduksi

Bukti lokal yang diabaikan Git: `artifacts/godot/06a-ocean/{baseline,after}/` dan `*-comparison.png`. Hash seluruh12PNG asli tersimpan pada `evidence-sha256.json`. `results.json` masing-masing varian menyimpan posisi, arah, status lampu, cuaca dan debug geometri; tidak menyimpan kredensial.

Kondisi sama: Godot4.7.2 Compatibility native AppleM2, viewport1440×810, profil balanced, hari cerita2 pukul10.00/cuaca cerah, identitas male_default dengan pakaian diving, oksigen77/koin700 tetap. Enam shot: passage `(750,900)` dengan lampu kanan, kiri dan mati; pemain sama dengan kamera `(660,900)` dan `(840,900)`; reef kontrol `(1550,620)`. Efek shader/biota dapat berbeda pada waktu tangkap; fixture ini mengontrol geometri/kamera/cuaca, bukan menjanjikan PNG identik piksel demi piksel.

```sh
mkdir -p .runtime
node --experimental-strip-types --input-type=module -e 'import{WORLD}from"./packages/shared/src/world.ts";import{writeFileSync}from"node:fs";writeFileSync(".runtime/world-map.json",JSON.stringify(WORLD))'
GODOT_BIN=/path/to/Godot
"$GODOT_BIN" --headless --editor --path client-godot --import
"$GODOT_BIN" --headless --path client-godot --script ../scripts/tests/ocean-platform06.gd
OCEAN_06_VARIANT=after "$GODOT_BIN" --path client-godot --script ../scripts/tests/ocean-platform06-render.gd
```

Untuk baseline gunakan runtime `2da6854` dengan fixture render yang sama dan `OCEAN_06_VARIANT=baseline`; source sebelum/sesudah tidak dicampur dalam satu adegan. Native fixture melakukan warm-up sebelum membaca lampu.

Lulus:

- `ocean-platform06.gd`: bahu/kaki vertex aktual dalam kontur; collar/flare nyata; seluruh geometry baru rear-only; perimeter gua mempunyai recess; relief depth>130; semua edge internal dipakai tepat dua segitiga, hanya30edge perimeter terbuka; nilai material terpisah; parallax0; tiga mount tetap; tidak ada collider/mutasi WORLD.
- `ocean-geology.gd`: sepuluh penyangga tetap bertumpu pada batu/lantai yang dituju, camera-lock dan rear-only.
- `ocean-rock-mount.gd`: kontak vertex GLB dengan segitiga reef tetap valid untuk ketiganya; dekorasi tanpa dukungan ditolak.
- `terrain-layers.gd`:15kontur/521pita teras/5184vertex terproyeksi, volume dan aset3D tetap ada.
- Enam native shot akhir selesai exit0 tanpa error shader/script. Impor cache kosong pertama sempat mencoba membaca font sebelum reimport selesai; native/headless berikutnya tidak mengulang error tersebut.

## Penilaian visual dan batas

Inspeksi gambar kanan/kiri/mati serta kamera bergeser menunjukkan bahu dan kaki penyangga lebih mudah diikuti. Perimeter gua sudah berlekuk; tidak lagi empat garis quad panjang. Koneksi tidak terlepas saat kamera bergerak. Ini perbaikan lokal keterbacaan dan silhouette, bukan penyelesaian seni seluruh laut.

Dinding masih merupakan massa belakang bertekstur besar dengan batas silhouette yang dapat terlihat pada air terang. Batuan atas tetap berbentuk ledge lebar sesuai kontur sah. Tidak ada klaim dinding menjadi gua berlorong penuh, perubahan visibilitas lampu global, benchmark FPS baru, atau validasi browser/mobile dari lane ini. Profil low/balanced, browser dan build gabungan tetap perlu diperiksa pada kandidat integrasi induk. Gambar/video lama bukan pengganti bukti tersebut.
