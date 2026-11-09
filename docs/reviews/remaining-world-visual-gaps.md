# Celah visual dunia yang masih tersisa

Audit baca-saja pada cabang `work/laut-dinamis`, runtime `232385d` di atas baseline `3d648e8`. Tidak ada impor, ekspor, proses Godot, perubahan terrain/collision, save, rute, HUD atau ekonomi dalam audit ini. Ini daftar masalah lokal yang terlihat, bukan pernyataan seluruh peta atau seni laut telah selesai.

## Bukti yang diperiksa

- Worktree laut: `artifacts/godot/ocean-current/passage-159.png`, `reef-159.png`, `deep-159.png`, beserta `results.json` dari render native sebelumnya.
- Worktree utama: `artifacts/godot/forest/02-entry.png` dan `03-canopy.png` (9November11:31); `land/03-garden-components.png` dan `05-forest-downstream-bridge.png` (09:13–09:15).
- Pengecekan tambahan keluaran terbaru utama: `plan04/objective-landscape.png` dan `night-home/02-night-clear-gameplay-667x375.png` (12:09–12:10). HUD terbaru tidak dinilai ulang karena sedang ditangani lane lain. Bukti hutan yang lebih lama perlu dicocokkan kembali jika geometri/camera berubah setelah tangkapan tersebut.

Koordinat piksel berikut memakai gambar1440×810 laut asli, bukan gambar yang diperkecil di chat.

## 1. Kerikil abu-abu laut memang dekorasi yang terpisah dari permukaan — pemasangan diperbaiki

**Terlihat:** pada `passage-159.png`, benda kecil abu-abu sekitar x490–560/y698–763 tampak mengambang atau ditempel di depan muka karang. Siluet abu-abu tanpa tekstur juga berbeda dari batu berlumut di sekelilingnya.

**Sumber pasti:** [TerrainGeometry.gd](../../client-godot/scripts/hybrid/TerrainGeometry.gd), `_build_model_rocks()` pada baris148–164. Instance pertama `resources/models/reef-rock.glb` ditaruh pada koordinat logis **(620,1130)**, depth **+115**, skala95, rotasi(0.12,0.5,0.18). Dua dekorasi lain menggunakan pola pemasangan yang sama pada(1530,1140) dan(3210,990). Ini bukan landmark, puzzle, tangkapan, pemberat pancing atau hadiah dari `OceanActors._mirror_props()`; tidak mempunyai interaksi permainan.

Posisi logis(620,1130) berada di dalam terrain4 `[0,1050,1750,300]`, sehingga pemain tidak mendapat lantai baru di sana. Namun posisi pada proyeksi2D itu **tidak menjamin kontak3D**. Batas vertex model GLB sekitar x±0.25/y0..0.39055/z±0.22971 memberi radius maksimum kurang dari50satuan setelah skala95. Dengan depth pusat+115, seluruh model tetap di depan depth+65. Muka karang dangkal paling maju hanya `FRONT_DEPTH26 + peak20 =46`. Jadi masih ada celah setidaknya sekitar19satuan pada sumbu depth, terlepas dari rotasi; mesh model tidak menembus muka karang yang seharusnya menopangnya.

**Perbaikan terbatas yang disarankan:** pertahankan GLB, pindahkan hanya pemasangan dekorasinya agar bagian belakang batu benar-benar menembus mesh karang yang ada, dan gunakan material bertekstur/palet batu yang sama. Hitung depth pemasangan dari permukaan lokal dan bounds model, bukan konstanta115. Tempatkan sebagai tonjolan pada muka batu atau di bibir atas terrain yang sama; jangan membuat batu solid baru di lorong air. Tidak perlu mengubah collider atau lokasi interaksi/save. Jika satu instance tidak bisa diberi kontak yang terbaca, hilangkan instance dekoratif itu saja sementara; jangan menghapus volume karang3D utama atau semua penggunaan model perpustakaan.

**Bukti penerimaan sesudah perbaikan:** close-up sudut kamera yang sama memperlihatkan persilangan kontak/cekungan lokal, tanpa celah depth; bandingkan kedua arah lampu. Model tetap tidak menambah collision.

## 2. Platform atas mempunyai penyangga, tetapi sambungannya tidak terbaca

**Terlihat:** di `passage-159.png`, ledge besar sekitar x400–910/y90–310 masih dapat terbaca sebagai bongkahan menggantung. Ini berbeda dari masalah kerikil di atas.

**Sumber:** terrain13 `[540,700,340,140]`, dibentuk oleh `_build_reef()` dari kontur bersama. [OceanGeology.gd](../../client-godot/scripts/hybrid/OceanGeology.gd) memang membuat penyangga belakang dari sekitar **(649.68,809.2)** ke **(649.68,1115.0)** pada terrain4. Rekaman `results.json` mengonfirmasi `terrain13 → anchoredTo4`, rearDepth−240. Penyangga berada dalam volume belakang batu sumber/tujuan; bukan kegagalan total membangun penopang.

Masalah visualnya adalah pertemuan penyangga dengan underside tenggelam dalam material/warna dinding gua gelap. [TerrainGeometry.gd](../../client-godot/scripts/hybrid/TerrainGeometry.gd) juga menggambar `CaveRearRockWall` sebagai empat sisi besar pada depth sekitar−580..−670. Beberapa bidang tumpang tindih dan nilai gelapnya menyatu, sehingga mata lebih mudah membaca ujung platform daripada kontinuitas batu di belakangnya.

**Perbaikan terbatas:** perjelas kontak underside–penyangga di geometri belakang yang sudah ada: lebarkan collar/akar pada titik pertemuan yang sama, buat perbedaan relief/nilai kecil dari dinding gua, dan pertahankan parallax penyangga nol. Semua perubahan tetap di belakang bidang renang; jangan menutup celah air yang saat ini valid atau memberi collider baru. Dibutuhkan perbandingan kamera/lampu yang sama untuk membuktikan keterbacaan, bukan sekadar jumlah node penyangga.

## 3. Beberapa tepi gua masih terbaca sebagai batas bidang geometri

`passage-159.png` memperlihatkan tepi kiri dinding gua panjang yang hampir lurus, dan `deep-159.png` memperlihatkan potongan underside kiri yang berakhir keras. Sumber paling jelas untuk dinding gua adalah quad `CaveRearRockWall` dengan empat corner sekitar(410,600),(1160,650),(1090,1180),(430,1210); sebagian garis lurus lain mengikuti kontur volume terrain yang sah.

Tidak ditemukan bukti bahwa latar PNG transparan berubah menjadi kartu persegi opak pada tiga gambar ini. `OceanBackdrop` memakai discard alpha0.2; sedangkan dinding gua di atas adalah mesh opak yang memang dibuat demikian. Shader `reef_variation` sudah memadukan crop bertumpuk; audit ini juga tidak membuktikan adanya seam tile persegi yang harus diperbaiki ulang.

**Perbaikan lokal:** jika bidang gua itu dipoles berikutnya, pecah hanya silhouette quad belakang menjadi tepian berlekuk yang tetap menyatu dengan volume sekeliling, tanpa menambah kolom batu di jalur renang. Pertahankan volume3D/collision utama dan material blending yang sudah bekerja. Jangan menyamarkan tepi keras dengan overlay gelap fullscreen.

## 4. Pintu masuk hutan terlalu tertutup tajuk foreground

Pada `forest/02-entry.png`, tajuk memang menutup karakter dan sebagian gerbang: depth/occlusion bekerja, tetapi pemain baru sulit melihat Nala ketika baru masuk. `03-canopy.png` menunjukkan karakter kembali terbaca setelah berada di jalur terbuka; masalahnya lokal pada framing entrance, bukan hilangnya y-sort di seluruh hutan.

[LandWorld3D.gd](../../client-godot/scripts/land/LandWorld3D.gd), `_atlas_canopy()`, membuat Sprite3D alpha-cut dengan depth nyata. Penempatan berkelompok menghasilkan overlap besar; tajuk tidak memiliki pengecualian keterbacaan kepala pemain dalam jalur tersebut.

**Perbaikan terbatas:** evaluasi fade singkat hanya pada tajuk yang tepat menutupi kepala Nala, atau penyesuaian framing kamera entrance yang kecil. Batang tetap solid di posisi manifest; jangan menghapus collision, memindahkan spawn/save, atau mematikan seluruh penutupan daun. Periksa ulang pada build terbaru sebelum menganggap temuan tangkapan11:31 ini masih aktif.

## 5. Beberapa transisi lantai dekoratif masih berpotongan tajam

Pada keluaran terbaru desa `night-home/02-night-clear-gameplay-667x375.png`, sebagian patch rumput di atas pelataran tanah berakhir dengan garis polygon yang jelas. Tepi rumput–tanah pada hutan juga lebih bersih/seragam dibanding tekstur tajuk yang kaya. Ini masalah penyatuan bahan/tepian kecil, bukan alasan mengulang seluruh terrain atau mempersempit lantai menjadi koridor lagi.

**Perbaikan terbatas:** gunakan variasi tepian dekoratif rendah pada patch yang sudah ada—rumpun rumput kecil atau mask tepi material yang terbatas—tanpa menambah penghalang tinggi di lantai valid. Prioritaskan sisi pintu/gerbang dan ujung jembatan yang terlihat dalam tangkapan, bukan menyebar detail di seluruh peta.

## Bagian yang tidak ditandai sebagai kegagalan baru

- Jembatan downstream sudah mempunyai ketebalan, tiang dan pagar, dan pada bukti yang ditinjau tidak terlihat lagi dua celah air hijau besar di antara plank. Tidak perlu mengerjakan ulang perbaikan tersebut.
- Petak kebun yang kosong/baru bertunas pada bukti awal adalah keadaan pertumbuhan; itu bukan bukti sprite panen hilang. Audit ini tidak meminta tanaman dewasa muncul sebelum waktunya.
- Parallax tiga lapisan, dinding belakang dan batu utama3D memang ada. Perbaikan arus pada `232385d` memperbaiki efek kecil, bukan menyelesaikan masalah kontak batu dekoratif atau seluruh komposisi dunia.
- Aset UI baru dan perubahan loading sedang diverifikasi lane lain. Tidak ada temuan HUD lama yang dimasukkan kembali sebagai pekerjaan laut.

Urutan lokal setelah rilis HUD/loading: kontak tiga batu dekoratif → keterbacaan sambungan platform13 → pemeriksaan entrance hutan pada build terbaru. Ini tiga pemeriksaan konkret dengan koordinat tetap; bukan roadmap perluasan fitur atau klaim kesiapan seni seluruh game.


## Tindak lanjut terbatas sesudah audit

Masalah kontak pada tiga batu dekoratif di bagian1 sudah diperbaiki pada lane laut. `OceanRockMount.gd` membaca vertex GLB setelah skala/rotasi, menguji muka mesh karang yang ada dengan ray segmen3D, dan menanam vertex belakang ke dalam permukaan dengan overlap yang diturunkan dari55% rentang depth model (dibatasi2..32satuan). Depth pusat yang dihasilkan26.74/32.16/38.40 menggantikan115. Seluruh footprint vertex harus berada dalam terrain sah; dekorasi tanpa dukungan dilewati. Titik asal proyeksi x/y ketiga model, collider, volume karang utama, save dan rute tidak berubah.

Material model memakai crop128px dari atlas batu proyek yang sudah ada dengan proyeksi triplanar karena GLB ini tidak mempunyai UV. Model tetap GLB volumetrik; tidak diganti gambar2D. Palet/tekstur dekorasi masih dapat dinilai artistik pada build gabungan, tetapi celah kontak geometri yang terukur di bagian1 telah ditutup.

`ocean-rock-mount.gd` lulus untuk ketiga model: vertex aktual menembus segitiga reef sebesar overlap yang dihitung, asal proyeksi tetap, depth span model>20, material bertekstur, penempatan di air bebas ditolak, tidak ada collider baru atau mutasi data dunia. Native Compatibility reef/passage/deep juga lulus tanpa error shader. Bukti lokal sebelum/sesudah: `artifacts/godot/ocean-rock-mount/passage-before-after.png`; gambar penuh sesudah berada di `artifacts/godot/ocean-current/`. Sambungan platform13, tepi gua dan keterbacaan entrance tetap merupakan temuan audit tersendiri; tidak dinyatakan selesai oleh perbaikan dekorasi ini.
