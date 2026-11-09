# Peer CPU: hull, settle dan fixed ramp target

Review read-only source character `6170c1e`, lalu hunk turn re-budget yang terlihat belum committed saat review. Query sync yang diizinkan root tidak mengubah WORLD layout11/hash. Tidak mengubah file character/shared dan tidak menjalankan engine. Ini penerusan temuan peer d8bf012, bukan penerimaan runtime baru.

Perbaikan source yang terkonfirmasi:

- `opaque_vertices` mengambil seluruh sudut piksel alpha≥.5 original, bukan hanya dua titik heel/toe. `valid_contact` memeriksa groundXY inverse, legal support, penetration dan bottom contact; inverse gagal ditandai invalid. Cache memuat outfit/view/side, camera-right/vertical dan target logical, sehingga tidak menyamakan geometri source berbeda.
- `_safe` sekarang mempertimbangkan ramp, mencari target didukung, dan melaporkan landing invalid bila gagal. Kurva ramp memakai target yang dibekukan sebelum penambahan durasi, dengan `_terrain_duration`4.9 terhadap lintasan aktual. Ini menjawab ramp D20 sebelumnya yang sama sekali tidak masuk budget stairs.
- Stop memilih `settlingTarget`, mengganti `entry.to` agar target plane sesuai landing settle, membagi waktu raw/pivot dari satu24δ, dan menunda kontak sampai correction/plane siap. Resume reanchor dari raw world pose aktual; tidak memindahkan root server.

Menjalankan model CPU source saat ini ke `.runtime/rigid-foot-peer-6170c1e.json`:32original feet PASS. Hull leftNW dengan114opaque vertices menolak center1189.9 (minimum gap−1.5744), menerima1180 pada ramp dan1194 pada flat; lebih ketat daripada dua edge-center yang memberi−1.36837 pada peer sebelumnya. Model fixed-orientation settlement selesai12ticks, budget0.4/tick, sisa raw/pivot0. Itu model statik/fixed-Q, bukan pengujian Godot aktual.

## Temuan yang dikirim ke character/root

**Curve plan stale setelah ordinary turn.** Pada commit6170, cabang turn mengubah from/fromWorld, mereset phase dan D ke `_turn_distance`, tetapi meninggalkan fixedRampTarget/fixedTreadTarget serta plan/target lama. Karena kurva baru bukan kurva yang dibudgetkan,4.9 tidak lagi terjamin; bisa memakaiD20 lagi. Cabang resume sudah memanggil `_begin`, tetapi ordinary turn belum. Character kemudian menambahkan hunk source yang menghitung ulang `_terrain_duration(new fromWorld, existing fixed target, turn minimum, new path span)` dan memperbarui plan. Hunk itu menjawab gap geometri secara source; belum parsed/run dalam review ini. Metadata `fixedPathWorldXY` pada treadPlan juga perlu mengikuti span baru bila dipakai sebagai bukti.

**Shared settlement clock mempunyai batas fixed-orientation.** Pembagian raw+pivot memberi jumlah24δ untuk translasi ankle. Namun rotasi airborne saat berhenti masih memperoleh allowanceδ×24 tambahan. Kompensasi mempertahankan ankle sesaat, sehingga ini bukan bukti pelanggaran ankle baru; tetapi gerak opaque corners mencakup translasi+rotasi dan tidak dibatasi oleh satu total24δ dari model fixed-Q. Jangan memperluas hasil12ticks menjadi bukti active-Q/full-hull continuity. Uji corner motion/clearance aktual atau nyatakan batas tersebut; tidak perlu menaikkan guard.

Tidak menemukan blocker source tambahan yang terkonfirmasi dalam cache/inverse/target settlement. Default nonphysical tetap memakai jalur lama. Pending tetap: parser, actual ramp/flat/stair matrix dan stopped/resume/turn dengan opaque hull, strict ankle/bone/contact-order, serta native sequence. Tidak ada natural walking atau perangkat fisik yang diterima dari model CPU ini.
