# Review CPU pembatas segmen gerak Nala

10 November2026, source karakter setelah `983282f` dengan perubahan belum commit pada `NalaPhysicalMotion.gd`, `Player.gd`, `Forest.gd`, dan fixture produksi. Review baca-saja; tidak mengubah source karakter, menjalankan Godot, atau mengubah default pilot yang tetap OFF.

## Yang benar secara kontrak

Callback opsional sesudah `velocity.move_toward` dan sebelum `move_and_slide` dapat membatasi inersia yang tersisa saat keluar dari ramp terkompresi menuju lantai datar. Normalisasi input sebelum percepatan tidak membatasi velocity hasil percepatan pada metrik berikutnya. `velocity.limit_length(100)` lalu mengalikan prefix0–1 mempertahankan batas logis100 dan tidak memperbesar analog. Delta nol/velocity nol kembali nol. Callback kosong mempertahankan jalur controller lama; hook Player dibatasi pada darat sehingga gerak selam tetap.

Untuk lintasan tanah kontinu, bagi segmen pada batas awal/akhir/sisi connector, gunakan arclength kumulatif XY, lalu pilih prefix yang memenuhi `100*delta`. Jangan memakai chord endpoint saja: panjang kurva dapat melebihi chord. Z riser diskret tidak dihitung sebagai jarak horizontal; XY tread memakai bidang linear `StairGeometry3D.contact_point`, sesuai ground aktual.

## Temuan konkret: sisi ramp yang sah mempunyai loncatan XY

`NalaPhysicalMotion.gd:64–72` mengambil ground_point pada cut, menganggap span berikutnya affine, lalu menginterpolasi `remaining/length`. Anggapan ini salah pada sisi `dock_gangway`: `ground_point` memilih connector secara inklusif di batas, sedangkan titik tepat di luar memakai lantai dermaga0.

Probe CPU memakai **manifest WORLD aktual** serta `isLandWalkable` radius12. Kedua titik berikut sah:

| Lokasi | Titik dalam ramp | Titik luar ramp | Tinggi bidang ramp / dermaga | Loncatan XY |
| --- | --- | --- | --- | --- |
| Sisi timur,10% panjang | `(1194.999,1183.5)` | `(1195.001,1183.5)` | 4,8 / 0 | 6,855110 |
| Sisi barat,10% panjang | `(1045.001,1183.5)` | `(1044.999,1183.5)` | 4,8 / 0 | 6,855110 |
| Sisi timur,25% panjang | `(1194.999,1173.75)` | `(1195.001,1173.75)` | 12 / 0 | 17,137776 |
| Sisi barat,25% panjang | `(1045.001,1173.75)` | `(1044.999,1173.75)` | 12 / 0 | 17,137776 |

Loncatan adalah `abs(hRamp-hDock)*tan(55°)`, karena embedding `Y=-logicalY/cos(55°)-height*tan(55°)`. Ini bukan riser Z dan bukan masalah tolerance fixture.

Counterexample matematis untuk solver source saat direview: mulai `(1194.999,1183.5)`, velocity `(100,0)`, delta1/60. Cut sisi berada di x1195; target awal1196.665667. Interpolasi span menghasilkan x1195.393283. Karena titik hasil sudah di luar ramp, ia menanggung **seluruh** loncatan6,855110, bukan fraksi loncatan. Jarak XY aktual6,866440 melebihi anggaran1,666667, setara411,986worldunit/detik. Angka ini hasil perhitungan CPU dari rumus source, belum eksekusi Godot/float32.

Perbaikan yang diusulkan kepada character: bedakan nilai satu sisi pada cut, tangani biaya loncatan utuh, dan jangan menginterpolasi melintasi jump yang tidak mampu ditempuh anggaran. Arah keluar dapat berhenti tepat pada batas inklusif ramp; arah masuk memerlukan limit sebelum switch inklusif bila jump tidak terjangkau. Solusi harus mempertahankan keabsahan titik, tidak menggeser floor/collider atau memperbesar100unit/detik agar lulus. Regresi khusus sisi ±epsilon ini perlu menemani exit centerline dan dua arah entry/exit.

## Pemeriksaan lanjutan yang diperlukan

- `LandWorld3D.ground_point` memakai connector pertama yang cocok, sementara `ground_gradient` menimpa dengan connector terakhir. Tidak membuktikan overlap bermasalah pada peta sekarang; solver harus mengikuti ground_point aktual, bukan menduplikasi aturan gradient yang berbeda.
- Collision/axis fallback sesudah move dapat mengubah segmen yang diterima. Guard harus mengukur arclength posisi aktual sesudah clamp/fallback, bukan hanya kandidat sebelum gerak. Character mengusulkan callback accepted-position opsional sesudah fallback dan sebelum moved_velocity/traversal/path; ia wajib memakai solver yang juga sudah memperbaiki jump sisi di atas.
- Hasil callback berupa prefix kolinear dari previous→accepted, tidak menambah jarak, diverifikasi terhadap predicate walkability existing. Bila prefix dipangkas, velocity mengikuti gerak yang benar-benar diterima; jangan menyimpan momentum seolah jarak penuh sudah dilalui. Mode default kosong tetap jalur lama.
- Cut connector saja tidak otomatis membuktikan semua batas polygon permukaan di luar connector kontinu. Fixture independen harus menilai ground_point aktual pada route/axis fallback dan menolak jump yang luput; jangan mengklaim seluruh dunia dibatasi dari satu lintasan ramp tengah.
- Uji delta1/120,1/60,1/30 serta frame yang melintasi lebih dari satu cut; input nol/deceleration, diagonal, analog kecil, pause, wall slide, dan batas logis100. Sampling independen128 ground point berguna tetapi harus memasukkan offset dekat sisi, bukan hanya centerline. Tidak mengubah tolerance kontak/kecepatan untuk menerima hasil.

Temuan dan counterexample dikirim ke root/character sebelum commit atau native test. Tidak ada penerimaan helper/pilot dari review CPU ini; gait, tangan berlawanan, kontak tangga, dan performa perangkat tetap gate berbeda.
