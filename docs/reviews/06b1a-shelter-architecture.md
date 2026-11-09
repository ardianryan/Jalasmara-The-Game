# Pilot serambi dan tumpuan rumah panggung 06-B1a

Implementasi native Godot pada cabang `work/06b-shelter`, berangkat dari source `1f097cc`. Ini paket konstruksi dan tujuan hujan; perubahan kamera integrator tetap terpisah. Belum merupakan pernyataan rilis staging atau penerimaan seluruh paket 06-B.

## Bentuk yang dibangun

Griya Sasmita memakai dek dan akses jembatan existing pada elevasi 2. Empat tiang bawah, balok keliling, tiga joist dan bracing membentuk ruang bawah dek. Tiang berakhir pada empat footing batu yang menyentuh bed terendam pada world-Z -110; tidak berakhir di udara. Bed ini merupakan fondasi visual bawah air, tidak menjadi lantai berjalan atau jalur baru. Ketebalan dek, tangga antarteras dan jembatan tetap mengikuti geometri lama.

Lima serambi menempel pada fasad Griya, Balai Lurah, rumah Ratih, Sari dan Tedi. Setiap atap mempunyai panel miring, ketebalan lima unit, soffit, fascia, rafter, balok dan dua tiang bertopang. Roof plan dan posisi tiang dihitung dari dua basis footprint rumah yang sama, bukan kotak bounding rumah. Vertikal atap memakai penambahan world-Z di atas `map_point(plan,elevation)` agar pergeseran proyeksi terhadap tinggi tidak menggeser coverage hujan.

Semua material memakai kayu, bambu, rumbia, batu dan pasir existing. Ini adaptasi metode geometri modular dari [kit Noxe revisi d619d856](https://github.com/danieljan-design/noxe-pixel-engine/blob/d619d856398b44ad084003fac0a9fbfc9c8393e7/scenes/kit.js), khususnya pembacaan `cottage()` dan `pier()`. Tidak ada kode/aset Noxe yang disalin atau diport dalam paket ini; helper ditulis sendiri dalam GDScript. Renderer Three.js, dependensi baru, generasi berbayar dan shader fullscreen tambahan tidak dipasang. Karena tidak ada kode upstream yang didistribusikan, tidak ditambahkan entri lisensi integrasi aktif palsu. Ketentuan MIT tetap berlaku jika kode upstream dipakai pada pekerjaan berikutnya, sesuai [audit sumber](../world/noxe-pixeldoll-reference.md).

## Tujuan hujan dan rute

| Warga | Tujuan hujan | Coverage fisik |
| --- | --- | --- |
| Ki Lurah | 940,310 | Serambi Balai |
| Ratih | 465,320 | Serambi rumah Ratih |
| Ujang | 1430,1260 | Shade bilik existing |
| Tedi | 1005,975 | Serambi rumah Tedi |
| Sari | 1305,300 | Serambi rumah Sari |
| Saras | 1020,310 | Serambi Balai |
| Darmi | 1375,300 | Serambi rumah Sari |

Work dan jam kegiatan tetap. Rest Sari/Darmi ikut titik serambi baru, berjarak 70 unit agar keduanya tidak menumpuk dan awning tidak dipanjangkan untuk mengejar titik lama. Rest Ujang tetap 1210,1250. Tujuan Ujang berada cukup jauh dari ujung utara shade agar kepala billboard juga tertutup hujan vertikal.

Sepuluh post menjadi obstacle resmi. Layout hub naik 8 ke 9, sehingga posisi tersimpan yang kini bertabrakan melewati jalur migrasi existing. Jalur serambi Griya, Balai ke Ratih, serta akses Sari/Darmi mengitari tiang. Cabang 1305,300 ke 1375,300 mengikat tujuan Darmi ke graf utama; tanpa cabang ini node sementara dapat memilih tiga node stub commute lama yang terputus. Pemeriksaan runtime menemukan kasus itu dan perubahan rute memperbaikinya, bukan melonggarkan assertion.

## Keterbacaan Nala

Pratinjau pertama ditolak karena atap Griya memotong kepala Nala. Panel atap dan soffit sekarang mempunyai bukaan piksel setempat ketika kaki Nala berada di bawah roof plan. Basis kanan/atas diperoleh dari `Camera3D.global_basis`, sehingga mask mengikuti kamera sebenarnya. Masuk 140 ms, pulih 240 ms. Fascia, tiang, struktur, plan hujan dan collider tetap ada. Setiap rumah mempunyai dua material panel sendiri; static batching hanya menggabungkan material dengan identitas yang sama, sehingga bukaan satu rumah tidak menghilangkan atap rumah lain. Shader melewati perhitungan mask ketika reveal nol.

## Bukti

- Typecheck lulus. Delapan tes CPU terdiri dari lima regresi land existing dan tiga tes shelter baru. Ketujuh anchor mempunyai clearance badan 13 di bawah satu roof plan; jalur menuju spawn, rumah, bilik, jembatan dan portal terhubung oleh ruas lantai sah. Sebanyak 45 sampel posisi lama di sepuluh tiang/clearance yang dahulu walkable dipulihkan ke lantai yang tersambung, bukan sekadar satu titik walkable.
- Semantic native memeriksa lima quad atap yang benar-benar dibangun, sepuluh post, empat footing dan bed; 336 sampel world-space telapak, torso dan kepala ketujuh warga tertutup atap. Uji material membuktikan hanya Griya terbuka saat Nala di bawahnya, basis berubah bersama rotasi Camera3D dan semua panel pulih setelah keluar. Collision tidak berubah ketika panel membuka.
- Pengujian dunia final lulus 38/38, termasuk seluruh regresi peta, HUD, kuis, kalender dan homestead. Kegiatan tujuh warga lulus 2.726 langkah aktual; regresi rutinitas normal/reduced lulus 21.894 langkah kerja, bicara, pulang, hujan, kembali, pause dan pemulihan hambatan tanpa teleport atau mutasi progres.
- Sebanyak 42 gambar native akhir mencakup low/balanced, siang/malam/hujan dan tujuh titik. Kepala Nala Griya sekarang terlihat melalui bukaan lokal; serambi Sari lebih kecil. Data renderer mencatat 53 batch mesh terhadap 42 pada acuan, di bawah guard existing 60. Ini jumlah batch pada fixture, bukan benchmark FPS/GPU atau perangkat S23.
- Regresi API tambahan lulus 81/81 `npm test`. Perbaikan raw commute Ratih/Sari/Darmi mengikuti waypoint kanonis yang mengitari post; commute Ujang tetap work ke rest, dengan shelter sebagai cabang terpisah di hub. Assertion lama tidak dilonggarkan. Satu database Mongo UUID eksklusif dan satu akun fixture menguji sembilan pusat post yang dahulu walkable: migrasi 8 ke 9, persistence Redis, reload, penolakan timestamp lama, penolakan berjalan ke post dan gerak legal sesudahnya. Koin, inventori, kalender, homestead serta cerita sama dengan snapshot sebelum pengujian. Database fixture dan key Redis akun/sesi/rate limit dibersihkan sendiri.
- Pembanding kiri memakai salinan sementara helper/fixture kamera integrator, dengan azimut -45 dan elevasi 30/35,264 derajat. Sebanyak 18 gambar dan pivot telapak lulus, galat layar telapak 0. Tidak ada mirror peta/karakter. Pemanggilan update cuaca 0,5 detik memastikan gambar malam benar-benar mendapat ambient malam/lentera; label gambar final menyebut `left-minus45`. Tiang, balok dan kolong terbaca dari kiri. Ini pemeriksaan statis mesh nyata, bukan penerimaan input/proyeksi gameplay global. Berkas pinjaman tidak masuk commit shelter.

Bukti lokal berada di `artifacts/godot/06b-shelter` dan `.runtime/shelter-*-final.log` pada worktree, tidak dimasukkan ke Git sebagai aset game. Capture menempatkan Nala terpisah dari warga untuk menilai kepala, torso dan tiang; tidak menimpa kedua karakter pada satu posisi.

## Batas paket

### Koreksi sumbu Griya terhadap dek

Pengguna menemukan ketidaksejajaran pada pratinjau kiri. Penyebabnya bukan arah kamera: generator footprint rumah lama menambahkan shear `0,16 * width` dan `0,27 * height`, sedangkan dek memakai rectangle sumbu peta. `_house()` menormalisasi dua vektor tersebut tanpa menjadikannya ortogonal. Pada Griya lama, vektor lebar sekitar `(168, -68.256, 0)` dan belakang `(32, 184.544, 0)` mempunyai dot ternormalisasi -0,212585; sisi rumah dan sisi dek memang berlainan sumbu.

Griya sekarang mempunyai footprint eksplisit rectangle `(78,420,164,145)`, dengan pusat tetap `x = 160, y = 492.5`. Basis native terukur menjadi lebar `(1,0,0)` dan belakang `(0,1,0)`, sama dengan dua vektor dek; dot antarsumbu 0. Roof plan, fasad, post dan collider mengikuti data itu, tanpa rotasi model tambahan atau mirror. Width 164 memberi aisle 38 unit pada kedua sisi dek. Memakai rectangle lebar 200 semula hanya menyisakan 20 unit per sisi, kurang dari diameter clearance badan 26, dan akan memutus akses ke lantai belakang rumah. Regresi sekarang melintasi loop kedua aisle serta strip belakang.

Versi 9 tetap kandidat paket yang belum dirilis publik; sumber rilis lama memakai versi 8. Fixture migrasi memakai footprint oblique Griya rilis 8 yang sebenarnya, bukan menganggap bentuk baru sudah ada pada save lama. Full `npm test` terbaru lulus 82/82: 49 sampel post/clearance yang dahulu sah (satu sampel sebelah selatan Ratih sudah berada di luar clearance lantai lama), empat sudut Griya yang dahulu bebas, 14 migrasi API (sepuluh pusat post dan empat sudut), serta lima save lama yang masih sah dan tetap pada koordinatnya. Seluruh posisi migrasi berada pada lantai yang tersambung dan bisa bergerak legal melalui API; koin, inventori, kalender, rumah serta cerita tidak berubah.

Native terbaru lulus 38/38 dan 336 sampel coverage tubuh, ditambah assertion sumbu rumah/dek/roof plan dalam world space. Gambar acuan kiri disimpan di `06b-shelter-left-before-alignment`; 18 pembanding setelah koreksi di `06b-shelter-left-after-alignment`, termasuk siang/malam/hujan serta low/balanced. Hasil malam memakai pencahayaan malam nyata. Sebanyak 42 capture kamera lama di `06b-shelter-after-alignment` juga diperbarui. Ini pembandingan geometri dengan kamera yang sama, bukan klaim kontrol kamera global sudah siap.

Rumah lain masih mempertahankan footprint oblique existing. Audit source menunjukkan kamera -45 dapat memperlihatkan fasad dan sisi kiri kedelapan rumah tanpa memutar footprint sembarang, tetapi koreksi keselarasan sumbu pada paket ini hanya berlaku untuk pilot Griya. Default yang baru untuk seluruh bangunan memerlukan penetapan facing serta migrasi masing-masing, bukan menghapus shear global tanpa peninjauan akses.

### Inti yang masih terbuka menurut Rencana 06

Kamera kiri global masih memerlukan integrasi proyeksi, billboard, arah visual, input dan HUD. Paket B2/B3 masih memerlukan penerimaan empat arah dan kontak alat Ujang, lalu Darmi/Sari serta warga berikutnya. Paket C belum selesai: rumah pribadi lurah, direktur dengan identitas terpisah dari Inspektur Raka dan kantor kontainer, serta dua kelompok Laskar dengan jadwal/interaksi nyata. Paket D seperti keramba, perluasan tanaman dan interior warga tetap mempunyai kontrak server sendiri.

Paket laut 06-A sudah mempunyai collar penyangga dan relief tepi gua pada rilis sebelumnya. Tidak ada pekerjaan laut baru yang diselesaikan di cabang shelter. Saat proyeksi kamera berubah global, inti laut memerlukan pemeriksaan ulang kontur collision, kaki/renang, occlusion karang, kedalaman/parallax, arus/buih dan framing HUD pada build gabungan. Perluasan dekorasi laut bukan prioritas sebelum konsistensi itu terbukti. Pengukuran fisik Windows/S23 tetap terbuka.

Default kamera dan proyeksi tidak berubah di cabang ini. Empat facing bangunan penuh, kontrol kamera menyudut serta HUD/browser gabungan diuji integrator setelah penggabungan. Round-trip API lokal cabang ini sudah lulus; transaksi akun staging belum diuji ulang dengan source gabungan. Efek hujan canvas existing belum menjadi simulasi partikel dengan collision tiap tetes terhadap atap. Windows/S23 fisik belum diukur.

Sistem interior playable, rumah pribadi lurah yang baru, kontainer direktur, keluarga warga baru, farming dan artwork tubuh empat arah tidak termasuk paket konstruksi ini.

Hard Gate PASS: tidak ada UI/kontrol/tautan baru yang mati, sumber dan status implementasi dibedakan, seluruh 38 pemeriksaan dunia serta gambar native dijalankan; tidak ada klaim performa perangkat yang dibuat-buat. Purpose Gate PASS: tiap tiang/fondasi mempunyai kontak, awning melayani tujuan hujan, bukaan lokal menjaga keterbacaan Nala dan fascia mempertahankan siluet. Liveliness PASS: ENERGY 2, RHYTHM 2, MOTION 1 mengikuti brief pesisir comfy; rumah panggung di atas air, anyaman/rumbia dan cahaya lentera memberi identitas, gerak tambahan hanya transisi bukaan lokal. Craftsmanship PASS: delapan tes CPU, typecheck, 38 pemeriksaan dunia, 42 frame kondisi dan 18 pembanding kiri lulus; gambar ditinjau dan kekurangan proyeksi/gameplay global tetap dinyatakan terbuka. Ini gate paket geometri, bukan klaim gate UI/mobile baru.
