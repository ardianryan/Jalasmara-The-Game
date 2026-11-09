# 06-A1/A2: tajuk hutan dan tepian jalan

9 November 2026. Cabang `work/06a-hutan`, worktree terpisah dari lane website, laut dan NPC. Basis source `2da6854`, runtime rilis `efdacba`. Paket ini mengerjakan pembandingan 06-0 khusus hutan/desa, keterbacaan tajuk 06-A1 dan penyatuan tepian bahan 06-A2. Tidak menyatakan seluruh Rencana 06 selesai.

## Reproduksi yang sah

Baseline memakai `Forest.gd` dengan renderer aktif `LandWorld3D.gd`, bukan fixture bitmap `land-occlusion-render.gd`. Visual Nala diinisialisasi sebagaimana physics Forest normal melakukannya, lalu physics dihentikan agar posisi pengujian tetap. Semua gambar baseline akhir mempunyai `actors.player = 1`. Jam diberikan sesudah `_ready`, sehingga `EnvironmentState.snapshot()` benar-benar menunjukkan 10:00, cuaca cerah dan reduced motion untuk pembandingan.

Percobaan fixture pertama mematikan physics sebelum tekstur Nala diinisialisasi dan `_ready` mereset jam menjadi 08:00. Hasil tersebut dibuang dan tidak dipakai sebagai bukti occlusion. Baseline yang sah diambil ulang dengan kontrol tajuk disembunyikan untuk membuktikan karakter memang dirender.

| Titik | Posisi pemain logis | Kamera |
| --- | --- | --- |
| Masuk hutan | `[200,1320]` | Forest sebenarnya, zoom 1.05, limits tetap. |
| Di bawah tajuk gerbang | `[350,1250]` | Sama; Nala hilang tertutup tajuk pada baseline. |
| Celah Cahaya Tajuk | `[650,1050]` | Kamera mengikuti pemain sebagaimana Forest. |
| Ujung jembatan atas | `[1290,660]` | Kamera Forest, geometri dek/rail tetap. |
| Patch hijau pelataran desa | `[1310,1100]` | Renderer hub, zoom 0.88. |
| Gerbang desa menuju hutan | `[2290,130]` | Renderer hub, zoom 0.88. |

Semua still 1440×810, kamera elevasi 35°, profil Seimbang. Posisi kamera efektif, cuaca, pakaian/visual pemain dan hitungan renderer tersimpan dalam `results.json`. Kamera awal hutan terjepit limit kiri secara normal; tidak diubah supaya pemain terlihat. Baseline dan kandidat memakai harness yang sama. Transisi shader dan pencahayaan dimajukan deterministik sebelum tangkapan agar enam frame native yang singkat tidak tertukar dengan fade yang sudah selesai.

## Perubahan runtime

`CanopyReadability3D.gd` mengelola Sprite3D atlas yang memang dipakai renderer daratan. Ia menyimpan satu mask alfa CPU 64×64 per frame atlas saat pembangunan, lalu memeriksa bounds, sampel alfa kepala/badan dan urutan depth kamera. Tidak ada pembacaan gambar GPU di setiap frame.

Hanya tajuk yang benar-benar berada di depan badan dan mempunyai daun pada sampel tersebut yang mendapat reveal. Lubangnya terbatas di sekitar kepala/torso, memakai dither piksel yang tertambat pada tajuk, fade masuk 140 ms, hold keluar 180 ms dan pemulihan 240 ms. Menghadap arah lain di posisi sama tidak mengubah seleksi tajuk. Batang, collision dan tajuk lain tetap utuh. Shader mempertahankan billboard kamera, normal untuk pencahayaan, alpha discard, tekstur nearest dan bayangan; tidak menggunakan transparansi seluruh objek atau pass transparan fullscreen.

UV Sprite3D yang memakai AtlasTexture sudah menunjuk ke atlas. Shader mengubah UV tersebut kembali ke koordinat lokal untuk lubang, tetapi mengambil warna dari UV atlas asli. Ini dicocokkan dengan [implementasi Sprite3D Godot](https://github.com/godotengine/godot/blob/master/scene/3d/sprite_3d.cpp#L131), lalu diverifikasi pada renderer Compatibility native.

Untuk jalan dan patch rumput dekoratif, `LandMaterials.gd` menambahkan mask piksel stabil hanya pada strip tepi sepanjang 12 satuan dunia. Bagian dalam tetap polygon opak dengan triangulasi biasa. Strip memakai tekstur/palet grass dan dirt proyek yang sudah ada dan dua material bersama. Tidak ada rumpun baru, lampu, collider atau pengubahan terrain. Patch terlalu sempit atau inset terpecah mempertahankan mesh dekoratif semula. Geometri bergerigi lama diganti mask ini, bukan ditumpuk di bawahnya.

`ForestOcclusion.gd` tidak diubah: itu helper foreground bitmap 2D lama dan bukan jalur atlas 3D yang bermasalah. Fallback tajuk non-atlas juga tidak dibuat ulang, karena atlas proyek tersedia pada build ini.

## Anggaran dan regresi

| Pengamatan native | Baseline | Kandidat |
| --- | --- | --- |
| Batch mesh statis hutan | 20 | 21 |
| Batch mesh statis desa | 40 | 42 |
| Patch dengan tepi mask hutan | 0 | 22, maksimum konstruksi 4.190 vertex sebelum indexing. |
| Patch dengan tepi mask desa | 0 | 13, maksimum konstruksi 1.890 vertex sebelum indexing. |
| Setup scene hutan, satu sampel lokal | 206,9 ms | 216,6 ms |
| Setup renderer desa, satu sampel lokal | 142,6 ms | 137,5 ms |

Angka setup merupakan pengamatan CPU lokal tunggal pada harness, bukan benchmark berulang atau hasil S23. Seluruh permukaan tidak ditesselasi: tambahan vertex hanya mengikuti keliling. Hutan mempunyai 47 tajuk atlas dengan satu mask bersama; titik gerbang mengaktifkan tiga reveal lokal. Desa mempunyai 21 tajuk dengan dua mask atlas. Angka ini tersedia melalui `debug_status().performance` dan `.readability` untuk diagnosis gabungan.

Pemeriksaan yang lulus:

- `forest-readability.gd`: foreground depth dan alfa aktual, tajuk tak terkait tetap opak, delapan arah tidak mengubah seleksi, exit hold, pemulihan penuh, posisi tajuk tetap, mask digunakan ulang, tidak ada collider 3D tambahan atau mutasi world/save, serta batas geometri/batch.
- `land-renderer.gd`: proyeksi telapak pada empat elevasi, kamera 35°, arsitektur/batching, kedua jembatan dan transisi menyelam tetap sah.
- `component-land.gd`, `land-path.gd`, `surface-traversal.gd`: lantai, collider, rute, jembatan, pemulihan posisi save dan metadata traversal tetap lulus.
- Render native Compatibility: delapan gambar dasar termasuk kontrol tanpa tajuk, ditambah 48 gambar gerbang untuk delapan arah × siang/malam/hujan × Ringan/Seimbang, tanpa error shader.
- Rekaman 252 frame pada simulasi 30 Hz: berjalan 100 satuan dunia/detik mengikuti rute masuk → gerbang → celah tajuk → jalan terbuka. Setiap langkah diuji terhadap collision yang sebenarnya. Kamera mengikuti dan daun kembali tertutup saat Nala lewat.

Sumber pengujian:

```sh
GODOT_BIN --path client-godot --script ../scripts/tests/forest-readability-render.gd -- --acceptance --output=res://../artifacts/godot/06a-hutan/after
GODOT_BIN --headless --path client-godot --script ../scripts/tests/forest-readability.gd
```

Baseline diambil dari kedua source material/renderer pada revisi basis, menggunakan harness yang sama; source kandidat dipulihkan sebelum kandidat/tes dijalankan. Slot Godot diberikan bergantian dengan laut/profiling, tidak merender atau mengukur GPU bersamaan.

## Bukti dan penilaian visual

Artefak lokal yang tidak dibundel:

- `artifacts/godot/06a-hutan/before/gateway.png`: karakter dirender tetapi tertutup tajuk.
- `artifacts/godot/06a-hutan/before/gateway-without-canopies.png`: kontrol karakter utuh pada posisi yang sama.
- `artifacts/godot/06a-hutan/after/gateway.png`: kepala dan torso terlihat melalui reveal setempat, tajuk/batang di sekeliling tetap menutup ruang.
- `artifacts/godot/06a-hutan/after/gateway-balanced-night-6.png` dan `gateway-low-rain-2.png`: arah belakang malam serta arah depan saat hujan.
- `artifacts/godot/06a-hutan/before/village-grass-edge.png` dan `after/village-grass-edge.png`: batas polygon hijau yang tegas menjadi tepian piksel yang menyatu.
- `artifacts/godot/06a-hutan/after/bridge.png`: dek, rail dan sambungan lantai tetap terlihat.
- `artifacts/godot/06a-hutan/forest-entry-walk.mp4` serta sumber `after/motion/`: gerak masuk/keluar tajuk dengan angin.
- `before/results.json` dan `after/results.json`: kondisi dan diagnostik sebenarnya.

Pemeriksaan manual dilakukan pada entry/gateway, kontrol tajuk, patch rumput, ujung jembatan, gerbang desa, contoh malam/hujan serta frame jalan 30/60/120/200/251. Root juga meninjau gambar gateway setelah fade selesai dan menerima keterbacaan kepala/badan pada kondisi tersebut. Keluaran awal yang belum settle diganti; tidak dipakai sebagai hasil final.

Ruang lingkup UI tidak berubah. Native fixture menghentikan controller Forest untuk mempertahankan posisi, sehingga label HUD fixture bukan bukti penerimaan HUD atau nilai akun langsung. Buku, joystick, host loading, fullscreen, kalender 36 menit, save, collider, portal, spawn dan manifest tidak diedit. Lane ini tidak melakukan ekspor publik, deployment atau pengujian perangkat Windows/S23. Peninjauan gabungan, CI dan rute browser kandidat tetap menjadi tanggung jawab integrator.

## Penggabungan akhir

Runtime `2f7f551` melewati perhitungan reveal saat nilainya nol dan memakai `MAIN_CAM_INV_VIEW_MATRIX` agar orientasi billboard pada shadow pass mengikuti kamera utama seperti Sprite3D semula. Delapan capture native gabungan selesai tanpa error shader/script. [Delapan pemeriksaan browser](06a-forest-browser.md) membuktikan perjalanan melalui gerbang, reveal dan pemulihannya, kedua jembatan, save/reload, serta portal pulang pada ekspor PCK `a9378a52`. [Kontrol performa aktif dan tidak aktif](../performance/06p-comparison.md) tidak menunjukkan perbedaan median yang konsisten terhadap paket lama; tidak dipakai sebagai klaim peningkatan FPS perangkat fisik.
