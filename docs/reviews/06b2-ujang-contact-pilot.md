# 06-B2 fase 1 — kandidat mekanik kontak Ujang

Cabang terisolasi `work/06b-body-pilot`, dasar `6c6d0ad`. Ini kandidat untuk menilai mekanik satu pilot, **belum penerimaan mutu animasi B2 dan belum digabungkan ke rilis A+B1**. Tidak mengubah manifest, jadwal, collider, alat gambar, save, HUD, server, ataupun kecepatan gerak. Tidak menghasilkan ilustrasi arah baru, memakai layanan berbayar, atau menambah aset perpustakaan.

## Perubahan yang benar-benar diterapkan

- `UjangFootPlant.gd` menyimpan titik telapak stance dalam koordinat dunia. Kaki swing bergerak ke pijakan berikutnya, hanya pada lantai sah di luar footprint obstacle; sampel sole mempunyai margin 6 unit. Tujuan kaki yang tidak sah dipersempit menuju posisi actor yang sah, tanpa memindahkan actor.
- Tinggi lantai/tread dibaca dari metadata dan rumus tangga renderer yang sudah ada. Kontak tidak memakai ramp interpolasi sebagai pengganti puncak tread yang benar-benar digambar. Tidak membuat lantai atau collider baru.
- Fase berjalan mengikuti jarak fisik pada bidang tanah hasil proyeksi renderer. Driver tetap 26 unit logis/detik. Arah Y pada kamera 35° mempunyai jarak fisik berbeda dari X; ini tidak mengubah kecepatan navigasi atau memperlambat clock animasi secara palsu.
- Hanya Ujang pada `LandWorld3D` yang memakai kaki ber-IK panjang tetap. Bagian sprite paha/betis diorientasikan dalam ruang 3D dengan skala panjang 1. Rig tetap 16 bagian; bukan model karakter baru. Darmi/Sari dan stage lama yang tidak menyediakan peta renderer memakai fallback lama.
- Pelvis visual dapat naik paling banyak 3 px atau turun 8 px untuk mencapai telapak dengan panjang kaki yang sama. Root actor tetap berada pada posisi navigasi; torso/kepala/lengan ikut pergeseran visual tersebut. Lutut membengkok ke depan sesuai bidang arah E/W atau N/S, bukan selalu ke X.
- Stop, penghalang dan interaksi menghentikan fase jarak; kaki swing menyelesaikan penurunan pendek ke tanah. Reduced motion tetap mempertahankan gait yang diperlukan, dengan flourishes kerja/idle seperti B1.
- Socket kaki diambil dari baris alpha opak terbawah tekstur sepatu yang sudah ada. Tidak mengasumsikan seluruh kotak gambar adalah telapak. Joran tetap prop terpisah. Pengukuran grip Ujang sekarang `unknown`: jarak socket ke segmen yang dibangun dari socket yang sama tidak lagi disajikan sebagai bukti genggaman independen.

`pose_snapshot().contacts` menyediakan status grounded, posisi telapak/plant, `worldSole`/`worldPlant` numerik, fase, rasio proyeksi, kompensasi pelvis, dan error panjang. Nilai debug bukan pengganti inspeksi gambar.

## Verifikasi yang dijalankan

Godot 4.7.2 Compatibility pada Apple M2, worktree sendiri. Tidak ada browser atau perangkat fisik yang diuji dalam kandidat ini.

`ujang-foot-contact.gd` **PASS**, headless dan native, **1.074 langkah/frame pemeriksaan**. Test membangun `LandWorld3D` serta kameranya yang sebenarnya, membaca WORLD yang sama, dan memakai `LandCollision.is_walkable()` asli. Driver diagnostik berjalan pada commute dermaga Ujang lalu jalur dock/tangga teras yang sudah sah; perjalanan tangga adalah tes kontak, bukan perubahan rutinitas produksi Ujang. Tidak ada callback lantai yang selalu mengembalikan true.

Hasil:

| Pemeriksaan aktual | Hasil |
| --- | --- |
| Drift sole opak selama stance yang sama | maksimum ≈0,000274 unit dunia |
| Jarak sambungan quad paha/betis pada knee | maksimum ≈0,000273 unit |
| Skala panjang bagian kaki | 1, tanpa stretch |
| Penurunan pelvis maksimum pada trace | ≈7,041 px, di bawah batas 8 px |
| Sole terhadap geometri lantai | Ray pendek berpotongan dengan segitiga floor/tread yang dipancarkan renderer; toleransi 1,2 unit mencakup overlay bahan lantai kecil |
| Batas air dermaga | Driver benar-benar mencapai candidate yang ditolak collision; posisi, fase berjalan dan event langkah berhenti |
| Normal/reduced, belok, stop dan pose bicara | Keduanya melewati trace yang sama; kontak dan panjang tetap diperiksa |
| Grip joran | `unknown`; tidak dihitung lulus kontak piksel |
| Mutasi WORLD/pemain/save | Tidak ada pada snapshot yang dibandingkan |

Tes mengukur kembali alpha sole dari tekstur dan transform `Sprite3D`, menyambungkan ujung quad tulang sebenarnya, serta mengindeks segitiga mesh renderer. Ia tidak hanya mempercayai label `grounded` atau penghitung node. Percobaan harness pertama menemukan surface mesh tanpa index array; penanganan array kosong diperbaiki dalam test sebelum hasil di atas, tanpa melonggarkan toleransi.

Regresi sebelumnya juga lulus pada kandidat sebelum penyempurnaan bidang knee terakhir: `village-routine06.gd` (20.906 langkah tujuh profil), `village-activities.gd` (2.647 langkah), dan `npc-body-animation.gd`. Perubahan terakhir hanya bidang knee Ujang dan penambahan pemeriksaan batas air; test kontak final serta native direkam ulang sesudahnya. Tidak mengklaim suite induk/browser diulang pada commit kandidat ini.

## Bukti lokal dan reproduksi

Bukti diabaikan Git: `artifacts/godot/06b-body-contact/`.

- `contact-pilot.mp4`: 1.074 frame pada playback 10 fps, 107,4 detik simulasi, kamera nyata 3/4.
- `sequence.png`, `sole-strip.png`, `scene-*.png`: tinjauan kontak, berjalan, belok dan tangga.
- `results.json` dan `evidence-sha256.json`: snapshot serta hash bukti. Sumber gambar tetap atlas proyek yang sama, tanpa PNG runtime baru.

```sh
mkdir -p .runtime
node --experimental-strip-types --input-type=module -e 'import{WORLD}from"./packages/shared/src/world.ts";import{writeFileSync}from"node:fs";writeFileSync(".runtime/world-map.json",JSON.stringify(WORLD))'
GODOT_BIN=/path/to/Godot
"$GODOT_BIN" --headless --editor --path client-godot --import
"$GODOT_BIN" --headless --path client-godot --script ../scripts/tests/ujang-foot-contact.gd
UJANG_CAPTURE=1 "$GODOT_BIN" --path client-godot --script ../scripts/tests/ujang-foot-contact.gd
```

Fixture native mempertahankan kamera tetap agar kontak dapat dibandingkan dengan latar dunia. Pada beberapa frame landing atas, kepala terpotong tepi frame; gambar tersebut dipakai untuk kaki/knee, bukan bukti framing karakter lengkap atau penilaian wajah. Ini bukan rekaman dialog UI/layanan pemain atau kalender 36 menit; B1 dan kandidat integrasi induk menguji bagian itu.

## Penilaian dan batas penerimaan

Inspeksi still menunjukkan stance lebih tegak setelah koreksi kecil tinggi pelvis; knee tidak lagi selalu menyamping pada north/south. Foot plant dan sambungan geometri dapat diukur, tetapi tekstur potongan kaki/upper body masih dapat terbaca seperti boneka. Transisi arah dapat menghasilkan silhouette kaki yang kurang alami. Gambar kepala/torso belakang tetap silhouette warna lama dan E/W tetap memakai karya yang dicerminkan. **Tidak ada empat arah ilustrasi baru, tidak ada batch warga lain, dan tidak ada klaim natural walk selesai dari hasil matematika ini.**

Pembaruan posisi visual yang meloncat lebih dari setengah stride fisik mereset kontak dengan aman agar kaki tidak memanjang; kestabilan stance melintasi frame gap besar belum dijamin. Trace yang direkam tidak memerlukan reset tersebut. Sinkronisasi bunyi langkah NPC belum dipindahkan ke event plant; event lama masih berbasis jarak logis, sementara pose kontak memakai jarak fisik. Tidak ada klaim benchmark mobile atau biaya render baru sudah diterima.

Joran masih tidak mempunyai `gripPixel` independen pada karya telapak. Darmi/Sari mempertahankan metrik lama yang belum membuktikan kontak visual, sesuai audit sebelumnya; kandidat ini tidak memperluas scope mereka. Seluruh status ini harus tetap terlihat pada review sebelum memutuskan integrasi. Langkah berikutnya adalah review video mekanik Ujang, lalu karya arah/grip yang benar bila disetujui, bukan otomatis menggabungkan kandidat ini ke rilis publik.
