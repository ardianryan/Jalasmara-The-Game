# Sisa pekerjaan desa dan NPC

Audit statis sumber, 9 November 2026. Pemeriksaan ini tidak menjalankan Godot, browser, API, atau migrasi data. Ini daftar pekerjaan lanjutan setelah rilis HUD/loading yang sedang diverifikasi, bukan klaim bahwa seluruh Rencana 03 sudah diterima secara visual.

## Daftar pemeran yang benar-benar terhubung

Manifest sekarang berisi **enam warga tambahan dan empat tokoh distrik**, sehingga ada sepuluh NPC bernama. Nala adalah karakter pemain, bukan NPC kesebelas. Referensi “11 NPC” belum mempunyai padanan satu-ke-satu pada manifest aktif; jangan menambah duplikat atau menganggap hitungan sebelas sudah terpenuhi.

| Nama yang dipertahankan | Identitas sumber | Fungsi/status saat ini |
| --- | --- | --- |
| Ki Lurah Wirabhumi | `npc_ki_lurah_wirabhumi` | Pengamatan pasang; jadwal 08.00–17.30; istirahat/berteduh di depan balai. |
| Mbok Ratih | `npc_mbok_ratih` | Berdagang 07.00–18.00; pasar bibit nyata tetap memakai titik layanan. |
| Mang Ujang | `npc_mang_ujang` | Memancing 06.00–17.30; pilot rig tubuh dan alat. |
| Kang Tedi | `npc_kang_tedi` | Pemeriksaan air/pompa 07.30–17.30; alat kerja terpisah, belum rig pilot. |
| Yu Sari | `npc_yu_sari` | Menenun 08.00–17.00; pilot rig tubuh dan alat. |
| Saras | `npc_saras` | Penelitian 09.00–17.00; tersedia mulai siklus cerita 2, bukan hari kalender 2 otomatis. |
| Mbah Wira | Nama tokoh pada `dist_kedai` | Layanan racikan/cerita; gerak idle, belum profil perjalanan kerja/istirahat seperti enam warga. |
| Beno | Nama tokoh pada `dist_bengkel` | Peningkatan perlengkapan; gerak idle bengkel, belum klip kerja tubuh lengkap. |
| Bu Darmi | Nama tokoh pada `dist_kebun`; profil terpisah `VILLAGE_DISTRICT_ACTIVITIES` | Berkebun 07.00–17.30; pilot menyiram; berdiri di luar footprint petak. |
| Inspektur Raka | Nama tokoh pada `dist_pos_korporat` | Pengawas PT dalam cerita; gerak idle di depan kantor kontainer. Bukan tokoh direktur baru. |

Sumber nama, ID warga, jam, dialog, dan rute: [village.ts](../../packages/shared/src/village.ts#L1). Empat ID `dist_*` di atas adalah **ID lokasi**, bukan ID NPC baru; pengikatan tokohnya memakai nama pada [world.ts](../../packages/shared/src/world.ts#L120). Jangan membuat entri warga kedua untuk Bu Darmi hanya karena profil aktivitasnya disimpan terpisah.

Bagas, Kinasih, Gito, Cempaka, dan Danu tercatat sebagai **perluasan Laskar Kognisi**, bukan lima NPC aktif atau aset siap dipakai. Nama mereka sudah dicadangkan secara naratif pada [village-ecosystem.md](../world/village-ecosystem.md), sedangkan Rencana 03 menunda perluasan itu. Tidak ditemukan ID runtime/jadwal untuk mereka pada manifest warga saat audit ini.

## Bangunan dan tempat kerja

- Hub mempunyai delapan footprint bangunan: kedai, bengkel, pos PT, Griya Sasmita, balai lurah, rumah Ratih, rumah Sari, dan rumah Tedi. Dua petak kebun pemain dan kebun Darmi adalah obstacle kebun terpisah, bukan rumah tambahan. Lihat [land.ts:458–490](../../packages/shared/src/land.ts#L458).
- Pos PT **sudah menjadi kontainer tersendiri**, bukan rumah limas yang hanya diberi warna lain. Renderer membangun chassis, dinding/rib kontainer, atap datar, jendela layanan, pintu, ventilasi, antena, dan lampu akses: [LandWorld3D.gd:657](../../client-godot/scripts/land/LandWorld3D.gd#L657). Ini kantor statis bergaya kontainer; bukan kendaraan RV yang bisa dikendarai. Raka tetap Inspektur. Tokoh direktur terpisah belum ada.
- Balai lurah mempunyai plinth batu, lantai naik, bangku rapat, atap bawah/atas, dan papan pengumuman: [LandWorld3D.gd:583](../../client-godot/scripts/land/LandWorld3D.gd#L583). **Belum ada rumah pribadi lurah terpisah**. Posisi istirahat di depan balai tidak membuktikan adanya interior rumah lurah.
- Rumah pelana Ratih/Tedi, rumah limas Sari, kedai, bengkel, balai bertingkat, dan kontainer memakai cabang bentuk atap berbeda: [LandWorld3D.gd:496](../../client-godot/scripts/land/LandWorld3D.gd#L496). Jadi variasi arsitektur sudah ada; mutu siluet pada kamera permainan tetap perlu dinilai melalui bukti visual yang sesuai revisi sumber.
- Interior yang dapat dimainkan ialah Griya Sasmita. Bangunan warga lain belum merupakan interior yang dapat dimasuki. Pasar bibit dan papan izin/misi balai mempunyai titik interaksi nyata; ini tidak berarti semua rumah mempunyai layanan atau adegan dalam ruangan. Lihat [Main.gd](../../client-godot/scripts/Main.gd#L537) dan [Rencana 03, tahap C/E](../plans/03-desa-hidup-dan-siklus-harian.md).

## Aktivitas: tubuh, alat, dan perjalanan

**Sudah terhubung:** enam warga dan Bu Darmi memakai tempat kerja, jam buka, tujuan istirahat/berteduh, serta jalur perjalanan. `HubActor` memilih berteduh ketika intensitas hujan melewati ambang; jalur diperiksa terhadap walkability dan dapat melaporkan `blocked_*` jika gagal. Pemain yang mendekat menghentikan perjalanan agar interaksi dapat dijangkau. Lihat [HubActor.gd:35–92](../../client-godot/scripts/HubActor.gd#L35).

**Tiga pilot tubuh nyata:** hanya Mang Ujang, Bu Darmi, dan Yu Sari terdapat pada daftar `NpcBodyRig3D.IDS`. Rig merakit bagian sprite, sendi, serta titik tangan; renderer menyembunyikan billboard tubuh lama ketika rig berhasil dipasang. Ini lebih dari menggoyangkan alat di depan portrait, tetapi **belum empat arah ilustrasi baru yang lengkap untuk seluruh warga**. Sumber: [NpcBodyRig3D.gd:3](../../client-godot/scripts/NpcBodyRig3D.gd#L3), [LandActors3D.gd:191](../../client-godot/scripts/land/LandActors3D.gd#L191), [panduan rig](../../tools/npc-rig/README.md).

**Alat kerja sudah terpisah:** joran/tali/pelampung, rangka tenun, penyiram/tetesan, alat pompa/sampel, barang dagangan, dan catatan penelitian ditangani [VillageActivity3D.gd](../../client-godot/scripts/VillageActivity3D.gd#L87). Tedi, Ratih, dan Saras memiliki visual kegiatan, tetapi ini belum membuktikan klip tubuh berlapis lengkap untuk mereka. Lurah dan dua pekerja inti, Wira/Beno, juga belum mempunyai rangkaian tubuh kerja setara ketiga pilot.

**Klip/peristiwa:** state diam, jalan, interaksi, mulai/berulang/selesai kerja, dan istirahat diatur [NpcAnimationState.gd](../../client-godot/scripts/NpcAnimationState.gd#L1); langkah mengikuti jarak, alat memanfaatkan titik tangan dan fase aksi. Untuk menerima mutu animasi, tetap perlukan rekaman arah/fase serta kontak alat pada kamera permainan; keberadaan state dan penghitung mesh saja tidak cukup.

**Batas simulasi:** memancing Ujang tidak memberikan ikan, menyiram Darmi tidak melakukan transaksi panen pemain, dan berdagang Ratih tidak mensimulasikan seluruh ekonomi warga. Jadwal/posisi warga merupakan presentasi lokal, bukan posisi NPC permanen yang disimpan per akun. Pada reduced motion, implementasi sekarang juga menghentikan perjalanan NPC (`HubActor._activity_update`), bukan hanya efek tambahan. Perilaku ini perlu ditinjau terhadap kebijakan aksesibilitas tahap B; layanan penting tetap harus dapat dipakai tanpa menunggu warga bergerak.

## Waktu, cuaca, dan progres yang benar-benar berlaku

Hari kalender berlangsung **36 menit aktif** dan tersimpan di server, terpisah dari hari/siklus cerita: [calendar.ts](../../packages/shared/src/calendar.ts#L1). `CalendarSync` mengirim heartbeat dengan status pause/fokus; layanan kalender memakai lease penulis dan menolak kemajuan waktu dari tab lain atau jeda tak sah. Jam visual menerima kalender tersebut; bukan jam kosmetik bebas yang boleh memberikan hadiah. Sumber: [CalendarSync.gd](../../client-godot/autoloads/CalendarSync.gd), [homestead.ts](../../apps/api/src/homestead.ts#L123), [EnvironmentState.gd](../../client-godot/autoloads/EnvironmentState.gd#L21).

Hujan harian ditentukan server dan ikut perawatan/pertumbuhan kebun pemain; transisi visual hujan dipakai NPC untuk memilih tempat berteduh. Pertumbuhan tiga hari kangkung, pasar bibit, peti/pantry, izin setelah misi akar, serta kedai–pulang–tidur adalah kontrak pemain yang sudah ada. Jangan mencatatnya lagi sebagai fitur baru yang belum dibuat. Lihat [daily.ts](../../apps/api/src/daily.ts#L54). Sebagian daftar “perluasan belum aktif” pada `village-ecosystem.md` masih mencampur tahap lama rumah/kebun yang kemudian diimplementasikan; sumber runtime dan catatan pelaksanaan Rencana 03 lebih tepat untuk status sekarang.

## Pekerjaan berikutnya yang dibatasi

| Prioritas | Pekerjaan | Batas penerimaan |
| --- | --- | --- |
| 1 | Cocokkan referensi sebelas nama dengan sepuluh NPC aktif serta lima nama Laskar yang ditunda. | Satu tabel identitas/peran yang disepakati; tidak membuat direktur baru atau menduplikasi Raka/Darmi hanya demi mencapai hitungan. |
| 1 | Lengkapi dan nilai empat arah tiga pilot sebelum batch warga lain. | Rekaman kerja→jalan→dialog→pulang siang/malam: tangan menempel alat, telapak tidak bergeser, arah/asimetri benar; bukan hanya gambar diam. |
| 1 | Verifikasi perjalanan tujuh profil pada geometri terbaru, pergantian jam, hujan, modal, dan reduced motion. | Semua titik kerja/pulang/berteduh dapat dicapai; tidak ada `blocked_*` menetap, berjalan di atap/air, atau layanan cerita yang menjadi tidak terjangkau. Audit ini belum menjalankan ulang rute tersebut. |
| 2 | Perluas tubuh kerja secara bertahap: Ratih/Tedi/Saras, lalu Lurah dan Wira/Beno. | Setiap tokoh punya aksi sesuai peran dan kontak alat yang dapat diperiksa; tidak mengklaim semua warga selesai dari keberhasilan tiga pilot. |
| 2 | Perjelas “rumah lurah megah” versus balai yang sudah ada. | Pertahankan balai bertingkat saat ini; rumah pribadi/interior tambahan hanya bila scope disepakati dan lantai, footprint, pintu, rute serta layanan ikut dibuat. |
| 3 | Rapikan status dokumentasi desa lama setelah rilis berjalan stabil. | Tandai rumah/kebun/pasar/kalender yang sudah aktif; tetap tunda Laskar, keramba, tanaman tambahan, dan interior seluruh rumah sesuai Rencana 03. |

Tidak ada perubahan gameplay, data pemain, jadwal, bangunan, atau aset dalam audit ini. Tidak ada pengujian native/browser baru yang diklaim lulus di sini.
