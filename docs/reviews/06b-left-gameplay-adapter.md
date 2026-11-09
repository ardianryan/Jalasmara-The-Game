# Kandidat gameplay kamera kiri — 9 November 2026

Base `e0d75b3`, branch `work/06b-view-projection`. Default source kandidat hub/Forest memakai azimut-45/elevasi35; build/PCK stabil yang sedang diuji browser tidak diganti dari worktree ini.

## Perubahan

- Pose dipasang sebelum billboard dibangun. Follow memakai posisi dan tinggi lantai kontinu aktor; input keyboard/joystick dibalik dari arah layar ke koordinat logis dengan batas kecepatan server yang sama.
- Nala memakai arah visual terpisah dari jarak gait. Actor, canopy, tangan/alat, ground rain dan wet marks mengikuti basis/proyeksi kamera aktual. Mini-map tetap north-up; laut/interior memakai kontrak lama masing-masing.
- Rain station Ujang bergeser1430,1260→1424,1260; Darmi1375,300→1365,280, tetap63.25px dari Sari. Rute authoritative konsisten; tidak menambah atap atau lantai.
- Bobber dipilih pada sisi actual rod melalui inverse view dan sampel WaterField basah; arah kerja dipulihkan setelah commute tanpa merusak arah idle terakhir. Grip yang belum dianotasi tetap unknown.
- Air jauh mendapat backing dua triangle pada material yang sama; mesh dekat32×24 tetap. Poolwetmarks maksimal24. Tidak ada renderer/physics3D tambahan atau dependency baru.

## Bukti

| Pemeriksaan | Hasil |
| --- | --- |
| Typecheck | PASS |
| Node route matrix/controls | 4/4 PASS |
| API penuh | 82/82 PASS, termasuk14 migrasi save8→9 dan5 posisi dek lama tetap |
| Camera3D helper | 576 proyeksi/ray/foot/host +2304 input/gradient PASS |
| Player/Forest nyata | 60 arah/input/gradient, magnitudo, gaitdistance, pause, elevatedfollow PASS |
| Shelter kiri | 336 tubuh/atap dan native house/deck axis PASS |
| Darmi/Sari tools | 480 kerja,260droplet,8arah layar, arrival→work, pause/reduced/unknowngrip PASS |
| Forest canopy | Sampelrute/floor sah, alpha mask lokal, hold/restore, front/back PASS |
| Fullworld sebelum footfix | 44/45; hanya Ujang swing pertama gagal |
| Ujang sesudah footfixd3bbc19 | 1242 langkah,168turn0/-45,26westgrip PASS; pelvismax6.988868<8 |
| Nativeframe | 9 ditulis, logakhir0error; batas di bawah |

`d3bbc19` mengonsumsi overshoot stance→swing biasa; panjang limb, toleransi dan perilaku startup/turn tidak diubah. Typecheck/API/helper/controller dan perubahan kamera dipisahkan dari hasil gambar. Full45 sesudah seluruh source digabung menunggu root; jangan melabeli run44/45 sebagai45/45.

## Review gambar dan sisa

`artifacts/godot/06b-left-runtime/` memuat Griya siang/malam/low, pantai, worker dan Forest. Griya memperlihatkan fasad/sisi dan atap sejajar dek, Nala terlihat melalui reveal lokal. Workerreview diam memperlihatkan bobber/rod kiri, Darmi ke tanah, Sari/frame; kepala Ujang/Sari sedikit terpotong pada fixturezoom3. Ini tidak membuktikan empat artworkfacing atau kualitas gait.

Dua frameForest memiliki `actors.player=0` akibat fixture belum mengembalikan actorNala sebelum rebuild area sesudah reviewworker. Sourcefixture sekarang memperbaiki urutan itu dan menambah assertplayer1; zoomworker menjadi2.4. Fixture terakhir belum dirender ulang setelah slot dilepas. FrameForest yang ada hanya diterima untuk geometri, bukan keterlihatan Nala; controllerForest nyata lulus pada tes terpisah.

Perlu: rootfull45 gabungan, renderulang fixture terakhir, ekspor kiri dan browserhub/Forest dengan harness membaca `land.view.motion`, keyboard/touch, canopy/equipment, save/reload dan seluruh overlay. Tidak ada benchmark Windows/S23 atau penerimaan browser kamera kiri. Rute Ujang tidak mencakup semua stair. Dunia, kalender36menit, ekonomi dan migrasi layout9 tetap memakai koordinat server semula.

DeliveryGate: HardGatePASS untuk status bukti/batas; PurposePASS, transform untuk arah gerak dan keterbacaan; LivelinessPASS sesuai brief kamera kiri/pixel3D; CraftsmanshipPASS untuk source/helper/controller yang diuji, penerimaan global tetap terbuka.
