# 06-B1 — perjalanan dan jeda rutinitas warga

Lane `work/06b-rutinitas`, baseline `1825976`. Scope tujuh profil yang sudah aktif: enam warga tambahan dan Bu Darmi. Tidak menambah pemeran, rumah, jam, hadiah, rig baru atau aset. `village.ts`, manifest lantai/obstacle, kalender server dan ekonomi tidak berubah.

## Masalah yang ditangani

Sebelumnya `HubActor._activity_update()` menghentikan perjalanan pada reduced motion. `NpcAnimationState` juga memaksa semua frame menjadi0; tiga pilot tubuh mempunyai guard terpisah yang menghentikan langkah meski posisi berpindah. Akibatnya pengaturan pengurangan gerak juga dapat menunda akses ke warga, atau menghasilkan tubuh diam yang meluncur.

Perjalanan terjadwal dan roaming yang sudah ada kini tetap tersedia pada reduced motion. Gait menggunakan perpindahan aktual; gerak idle, lean, kepala, dan loop/peristiwa kerja tambahan tetap dikurangi. Perubahan pada `NpcBodyRig3D` hanya tiga guard kaki/tangan berjalan, sesuai pengecualian ownership untuk B1; tidak merombak bentuk tubuh, alat atau aset B2.

`clock_paused` menghentikan perjalanan dan evaluasi ulang tujuan. Modal percakapan tetap dapat menyelesaikan gerak membereskan pekerjaan lalu beralih ke interaksi; setelah modal ditutup NPC melanjutkan pekerjaan atau rute yang sesuai. Mendekati warga yang sedang berjalan menghentikannya di tempat, tanpa menghapus jalur; posisi interaksi tetap mengikuti NPC.

Ketika segmen tidak lolos walkability, posisi dan jarak gait berhenti. Graph rute disusun ulang dari jalur/commute resmi dengan walkability saat itu, bukan menggunakan kembali edge yang terhalang. Pencarian gagal memakai backoff0,5/1/2/8detik; sesudahnya maksimal satu percobaan tiap8detik. Penghalang sementara yang hilang dapat dipulihkan. Untuk tujuan yang tetap mustahil NPC menunggu secara eksplisit, bukan teleport, menembus obstacle, atau menciptakan jalan alternatif palsu. Tidak ada klaim NPC bisa menembus penghalang permanen.

## Tujuan yang tetap digunakan

Semua koordinat berikut berasal dari manifest yang sama, bukan tujuan baru.

| Profil | Kerja | Pulang/berteduh | Jam kerja |
| --- | --- | --- | --- |
| Ki Lurah Wirabhumi | 580,950 | 940,310 | 08.00–17.30 |
| Mbok Ratih | 620,1030 | 465,320 | 07.00–18.00 |
| Mang Ujang | 900,1360 | 1210,1250 | 06.00–17.30 |
| Kang Tedi | 1150,980 | 1005,975 | 07.30–17.30 |
| Yu Sari | 760,650 | 1325,300 | 08.00–17.00 |
| Saras | 1480,680 | 1020,310 | 09.00–17.00 |
| Bu Darmi | 1720,520 | 1395,310 | 07.00–17.30 |

Saras tetap mengikuti pembukaan siklus cerita2 di aplikasi; tes profilnya tidak mengubah pembukaan itu. Mbah Wira, Beno dan Raka tidak diberi profil perjalanan baru dalam B1 ini. Layanan transaksi yang sudah ada tidak dipindah atau diubah.

## Verifikasi dan reproduksi

Hasil Godot4.7.2 Compatibility, AppleM2:

- `village-routine06.gd` **PASS**: tujuh profil normal/reduced, **20.906langkah** collision-checked, batas jam mulai/tutup, kerja→bicara→lanjut→pulang→hujan→kembali, pause saat perjalanan, obstacle sementara dan pemulihan dengan backoff, tanpa mutasi WORLD/pemain. Tiga rig diuji dari transform kaki/tangan aktual: berubah saat ada perpindahan, berhenti ketika blocked/talking, work flourishes tetap diam pada reduced.
- `village-activities.gd` **PASS**, 2.647langkah perjalanan pada kontrak lama. Ekspektasi reduced motion diperbarui menjadi perjalanan tetap berjalan, bukan posisi dibekukan.
- `npc-body-animation.gd` **PASS**: klip/peristiwa satu kali, tidy lock, arah dan gait berbasis jarak, pause serta state rest reduced tetap0.
- Native normal dan reduced **PASS**, masing-masing590frame/59detik simulasi. Diperiksa still kerja, dialog, berjalan, rest dan shelter: posisi bergerak di dermaga nyata; alat kerja disimpan saat berjalan; perjalanan reduced tetap sampai tujuan. Keduanya exit0 tanpa error shader/script.

Bukti lokal: `artifacts/godot/06b-routines/normal.mp4`, `reduced.mp4`, dua `*-sequence.png`, still `scene-*.png` dan `results.json` setiap mode. `evidence-sha256.json` memuat hash video/montage/report. Rekaman ini memakai renderer dan jadwal asli tanpa memaksa klip/posisi, tetapi tidak membuktikan mutu B2 seluruh warga atau layanan browser.

```sh
mkdir -p .runtime
node --experimental-strip-types --input-type=module -e 'import{WORLD}from"./packages/shared/src/world.ts";import{writeFileSync}from"node:fs";writeFileSync(".runtime/world-map.json",JSON.stringify(WORLD))'
GODOT_BIN=/path/to/Godot
"$GODOT_BIN" --headless --editor --path client-godot --import
"$GODOT_BIN" --headless --path client-godot --script ../scripts/tests/village-routine06.gd
"$GODOT_BIN" --headless --path client-godot --script ../scripts/tests/village-activities.gd
"$GODOT_BIN" --headless --path client-godot --script ../scripts/tests/npc-body-animation.gd
NPC_06_REDUCED=0 "$GODOT_BIN" --path client-godot --script ../scripts/tests/village-routine06-render.gd
NPC_06_REDUCED=1 "$GODOT_BIN" --path client-godot --script ../scripts/tests/village-routine06-render.gd
```

Tes memakai WORLD dan `LandCollision.is_walkable()` nyata. Penghalang tambahan hanya mempersempit titik tujuan Ujang sesudah rute direncanakan, untuk memeriksa kegagalan segmen/pencarian lalu penghapusan penghalang; tidak ada callback yang selalu mengembalikan true. Test tidak memberi hadiah atau menulis save. Pengujian accelerated/local-minute ini tidak menggantikan penilaian ritme kalender36menit atau browser focus/lease server.

Native fixture mengambil adegan3D desa aktual. Posisi Ujang hanya berasal dari pemanggilan rutinitas normal; phase/clip tidak dipaksa. Gambar dan frame lokal berada di `artifacts/godot/06b-routines/{normal,reduced}` yang diabaikan Git. Delta simulasi0,1detik/frame dengan playback10fps mencatat59detik simulasi, meskipun perekaman dapat selesai lebih cepat. Ini bukti transisi rutin pendek, bukan sesi36menit/perangkat fisik.

## Batas

Pekerjaan ini tidak menyelesaikan mutu ilustrasi/arah tubuh seluruh warga, perluasan rig B2, interior rumah, atau ekonomi warga. Pathfinding tetap mengikuti graph rute authored yang ada. Native menunjukkan Ujang mencapai anchor bernama `shelter` `(1210,1250)`, tetapi anchor tersebut masih berada di bagian dermaga terbuka, tidak tepat di bawah kanopi booth. Jadi respons hujan/rute lulus tidak membuktikan tempat berteduh arsitektural semua warga sudah memadai. Lokasi shelter/kanopi tidak dipindah diam-diam dalam B1 karena manifest dan bangunan di luar ownership; perlu penyesuaian metadata/arsitektur terpisah. Penghalang yang memutus seluruh graph atau tujuan tetap menahan NPC dengan retry terbatas; pemeriksaan ini tidak menyembunyikan status blocked atau mereset NPC ke titik layanan. Pemeriksaan UI/layanan melalui browser serta kalender otoritatif dilakukan pada kandidat integrasi induk, bukan diklaim dari tes semantik ini.
