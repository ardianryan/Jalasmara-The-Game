# Audit source rig pada kandidat kamera kiri

9 November 2026. Review read-only terhadap worktree `Jalasmara-06-view`, branch `work/06b-view-projection`, HEAD `4df8f3c` beserta perubahan runtime yang belum di-commit saat pemeriksaan. Runtime kandidat tersebut tetap milik agent shelter/view; audit ini tidak mengubah source-nya. Ini bukti CPU/source, bukan hasil Godot, native atau browser baru. Tidak ada perubahan staging.

## Temuan yang dikirim untuk perbaikan

### Joran west dan pelampung berada di sisi layar yang berlawanan

`VillageActivity3D.update_actor()` masih menaruh target air pada logical `actor.position + Vector2(-80,70)`, sedangkan `NpcBodyRig3D` menaruh joran west dalam frame tubuh mengikuti kamera sebenarnya. Pada azimut −45°, elevasi 35°, basis right kamera adalah `(0.70710678,-0.70710678,0)`. Dengan map tilt 55°, delta world ke pelampung adalah `(-80,-122.04078,-11)`, sehingga proyeksi X-nya **+29.72767**. Ujung joran west mempunyai X lokal `13 + 47*cos(-3π/4) = −20.23402` sebelum lean kecil. Pelampung di kanan, ujung joran di kiri; garis pancing melintas kembali ke sisi tubuh.

Repro: Mang Ujang bekerja di `(900,1360)`, kamera gameplay −45°, fase `wait`, normal atau reduced motion. Periksa ujung cylinder joran dan mesh pelampung sebenarnya; grip palm tetap harus diukur terhadap cylinder independen. Fixture grip lama meminta kamera cardinal 0° dan tidak memeriksa sisi layar pelampung.

Agent shelter telah menerima temuan dan menyiapkan target air dari inverse view plane pada sisi ujung joran, dengan pemeriksaan WaterField. Audit ini belum menyebut perbaikannya lulus. Gate berikutnya: target berada di air, tanda X relatif aktor konsisten dengan arah joran, fase prepare/cast/wait/pull/tidy tetap benar, dan galat grip tidak berubah.

### Darmi mempertahankan arah jalan diagonal ketika mulai bekerja

Rute pulang kerja Darmi berakhir pada `(1350,635) → (1720,520)`. Arah logical `(370,-115)` diproyeksikan menjadi screen `(119.85716,-231.38180)` pada kamera baru, sehingga `_camera_facing()` memilih **north**. `NpcAnimationState` memperbarui `direction` hanya saat ada velocity; memasuki `start_work` tidak menetapkan orientasi stasiun. Logical direction pada segmen itu tetap east, sehingga `_camera_facing()` juga mempertahankan `_view_velocity` diagonal sesudah Darmi berhenti. Akibatnya rear head dan arm depth belakang (`−.12`) terus dipakai saat menyiram.

Target tanah actual untuk Darmi adalah X1836.75, Z128; kaki X1720, Z96, dan Y target diklem pada Y kaki. Proyeksi target relatif kaki adalah screen **(82.55472,-73.56431)**, arah east. Jadi orientasi arrival north tidak sesuai orientasi kerja ke bed east. Ini bukan alasan menghilangkan arah diagonal saat idle biasa: berhenti berjalan tetap perlu mempertahankan facing alami.

Repro berikutnya harus menjalankan shelter → commute → work, bukan spawn langsung di work. Focused fixture 480 sampel menempatkan Darmi di work dengan initial direction east sehingga tidak mencakup transisi ini. Usulan kepada agent shelter: orientasi eksplisit pada transisi tiba di stasiun kerja, dengan vector kerja yang dipakai rig; hindari memaksa semua idle ke cardinal. Belum ada engine repro baru atau patch pada audit ini.

## Bagian yang diperiksa tanpa temuan regresi terbukti

- Transform tangan memakai `to_global()` rig kemudian `to_local()` activity; mirror Darmi/Sari ikut transform tersebut. Joran Ujang dan grip artwork tetap dihitung terpisah. Positive root/prostetik Ujang tidak direfleksikan oleh facing baru.
- Target siraman 0517 tetap dalam world-space rect tanah yang sama dengan raised-bed mesh; rotasi kamera tidak memindahkan soil target. Penggantian offset handle/spout menjadi actual camera-right sesuai frame layar. Pengukuran grip Darmi/Sari tetap `unknown`, bukan klaim nol dari socket sendiri.
- `ground_gradient()` memakai half-width connector yang sama dengan `ground_height()`. Facing memperhitungkan gradient, dan `input_motion()` menginvers matriks proyeksi dengan gradient. Tidak ditemukan cacat aljabar baru pada jalur itu.
- Root rig mengikuti actual camera basis; local up dan depth menjadi camera-up/camera-outward secara konsisten. Tidak ada perubahan shader rim dalam rig ini: pilot tetap sprite unshaded dengan tint. Tidak mengklaim directional rim-light selesai.

## Batas bukti dan langkah berikutnya

Ujang default 1.242-sample fixture mencakup commute, dock connector, stop/reduced, dan 168 sharp turns. Pada kandidat view, `dock_gangway` bertipe **ramp**, bukan tangga bertingkat. Route fixture tidak mengunjungi central/western empat tread atau ridge tiga tread. Jangan menyebut semua stairs bertingkat kamera kiri sudah terbukti dari jumlah sampel itu. Tambahkan traversal aktual bila perubahan berikutnya bergantung pada kontak di tread tersebut; audit ini tidak mengklaim kegagalan yang belum direproduksi.

Prioritas: selesaikan dua temuan alat/orientasi di atas, jalankan focused work-arrival dan endpoint-air serta regresi 480/1.242 dengan log penuh bebas `SCRIPT ERROR`/`ERROR`, kemudian native pada ukuran main. Darmi/Sari masih fallback cutout dengan langkah heuristik; empat arah tubuh original seluruh pilot dan natural walk mereka belum selesai. Tidak menambah NPC atau artwork baru sebelum jalur inti diterima.

Tool aktual: Git, ripgrep, pembacaan GDScript/TypeScript, Python3 standard-library untuk dot-product proyeksi. Tidak ada API berbayar, image generation, aset atau dependensi baru. Lisensi source/assets tetap seperti paket sebelumnya; audit ini tidak mengadopsi library lain.
