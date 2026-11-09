# 06-B2 — persiapan pilot tubuh Ujang dan audit tempat berteduh

Audit baca-saja pada worktree `work/06b-rutinitas`, source `8134016` (B1 diintegrasikan induk sebagai `a5e6b46`). Tidak menjalankan Godot, browser, impor, ekspor, PixelDoll atau generator aset dalam audit ini. Tidak mengubah runtime, manifest, bangunan atau save. Hasil B1 sebelumnya dipakai sebagai bukti terbatas, bukan hasil baru B2.

## 1. Tiga pilot yang benar-benar tersedia

Sumber [NpcBodyRig3D.gd:3](../../client-godot/scripts/NpcBodyRig3D.gd#L3) hanya mencakup Mang Ujang, Bu Darmi, dan Yu Sari. Setiap rig mempunyai16 bagian, pivot kaki `(0,0)` dan joint yang disampling dari karya karakter proyek sendiri. Atlas `npc-rigs/{ujang,darmi,sari}.png` diperiksa langsung dalam audit ini.

[Generator:15–35](../../tools/npc-rig/generate.py#L15) memakai crop Ujang/Sari dari `village-residents-v1.png`, Darmi dari `npc-atlas.png`. [Generator:83–119](../../tools/npc-rig/generate.py#L83) memotong bagian, menambal kain dari sampel potret yang sama, lalu mengekstrak lengan/kaki. Ini mempertahankan wajah dan motif pakaian, tetapi bukan sumber pose anatomi lengkap dari segala arah. Tangan kecil berasal dari crop yang sudah berpose memegang benda; membersihkan torso tidak otomatis membersihkan setiap fragmen benda pada tangan/lengan.

### Arah yang ada versus arah yang belum digambar

| Tampilan runtime | Implementasi nyata | Status untuk penerimaan B2 |
| --- | --- | --- |
| South | Potongan potret tiga perempat depan | Sumber identitas ada; belum front view baru atau sheet empat arah. |
| East | Potret depan yang lebarnya dikalikan0,93 | Bukan ilustrasi samping autentik. |
| West | East dengan `scale.x` negatif | Flip, bukan karya arah baru; detail asimetris/topi/tangan ikut tercermin. |
| North | Kepala/torso belakang dari alpha silhouette depan yang diberi warna sampel | Belakang sederhana, bukan gambar rear baru. Lengan/kaki masih bagian yang sama. |

Bukti source: [NpcBodyRig3D:88–118](../../client-godot/scripts/NpcBodyRig3D.gd#L88), [generator:120–132](../../tools/npc-rig/generate.py#L120). Kepala belakang masih mengikuti silhouette potret depan sehingga arah hidung/topi tidak otomatis menjadi bentuk belakang yang tepat. Jangan menyebut ini empat arah ilustrasi selesai hanya karena enum arah berisi empat nilai.

## 2. Audit kontak, lutut dan alat per fase

### Kaki dan lutut — ketiga pilot

[Runtime:101–113](../../client-godot/scripts/NpcBodyRig3D.gd#L101) membuat hip, ankle, knee dan foot terpisah. Posisi ankle adalah `-sole-lift`; pusat kaki ditambah setengahsole, sehingga bawah kaki stance secara lokal berada pada0. Ini mendukung pivot tanah dan swing lift; **belum mengunci telapak stance pada satu titik dunia**.

Gerak horizontal ankle memakai `sin(phase)*3,5` untuk semua arah. Selama separuh cycle stance, NPC berpindah sekitar12,5 unit karena cycle berjalan25 unit, sedangkan offset kaki kembali ke posisi awal setelah ayunan sinus. Jadi fase mengikuti jarak tidak cukup untuk membuktikan kaki menapak tanpa slip. North/south juga masih memakai ayunan X yang sama, tanpa foreshortening langkah sesuai arah.

Knee saat ini `hip.lerp(ankle,0,52) + (1+lift*0,35,0)`; `_bone()` meregangkan potongan tekstur ke panjang segmen. Ini telah mengurangi bentuk lutut patah pada revisi sebelumnya, tetapi bukan constraint panjang paha/betis atau plant-lock. Pada Sari, torso memuat bagian rok panjang yang menutupi sebagian kaki; penilaian joint tidak boleh sekadar memaksa semua paha terlihat melalui kain. Volume sumber Ujang sekitar11 px paha/7 px betis pada tinggi tubuh100 px; pertahankan bobot visual itu, jangan menyempitkan anggota gerak untuk mengejar lebih banyak frame.

### Tangan dan alat

[Runtime:121–155](../../client-godot/scripts/NpcBodyRig3D.gd#L121) mempunyai IK dua segmen lengan dan mengirim world hand sockets. Alat terpisah memakai sockets pada [VillageActivity3D:79–86](../../client-godot/scripts/VillageActivity3D.gd#L79). Ini fondasi yang dapat dipakai kembali, tetapi socket dihitung di ujung rantai tulang; posisi sprite telapak digeser1,5 px. Socket belum didefinisikan dari piksel grip pada gambar telapak.

| Pilot | Prepare/start | Work loop | End/tidy dan arah |
| --- | --- | --- | --- |
| Ujang | Interpolasi tangan menuju titik grip selama0,8 detik; belum antisipasi badan/bahu terpisah | Siklus9 detik prepare→cast→wait→pull→tidy; rod mengikuti dua sockets, line/float mengikuti fase | Tangan turun selama0,65 detik sebelum jalan/dialog. Target air tetap `actor+(-80,70)` untuk semua arah; east/west flip tidak membuat target atau aksi baru. North memakai depth tangan belakang tetapi belum ada silhouette siku/rod yang digambar khusus. |
| Darmi | Tangan menuju dua posisi kerja; belum bukti gerak mengangkat beban kaleng melalui seluruh siklus | Lift/aim/pour/lower5,2 detik; kaleng/spout bertumpu pada socket kanan | Spout memakai offset world X+15, sasaran tetes memakai `feet+(95,0,30)`; tidak diputar bersama arah tubuh. Nilai gripError selalu0, bukan pengukuran kontak gambar pegangan. |
| Sari | Dua tangan mendekati kerangka | Weave/inspect; kerangka dibangun langsung di antara sockets | Kerangka ikut tangan dan belum mempunyai anchor kerja independen, tension kain atau silang tangan khusus tiap arah. Nilai gripError selalu0; itu tidak membuktikan jari menempel shuttle/benang secara visual. |

Sumber fase [NpcAnimationState:74–85](../../client-godot/scripts/NpcAnimationState.gd#L74), geometri alat [VillageActivity3D:91–130](../../client-godot/scripts/VillageActivity3D.gd#L91). Error joran adalah jarak socket ke segmen yang memang dibangun dari socket yang sama: berguna memeriksa kontinuitas matematika, tetapi bukan penilaian genggaman pada piksel telapak atau visual occlusion dari empat arah.

B1 menjaga reduced-motion travel tetap berjalan dan hanya mengurangi flourishes. Itu tidak memperbaiki ilustrasi arah, plant-lock atau interaksi alat di atas.

## 3. Bukti yang ada dan apa yang belum dibuktikan

- `artifacts/godot/06b-routines/{normal,reduced}.mp4` dan montage:59 detik simulasi pervarian, Ujang pada renderer desa nyata, kerja→bicara→lanjut→pulang→kembali→hujan→tujuan shelter. Ini bukti rutinitas dan perubahan lokasi/gait, bukan pemeriksaan empat arah lengkap atau semua kontak telapak saat stance.
- [village-routine06.gd:147–181](../../scripts/tests/village-routine06.gd#L147) menguji transform kaki/tangan ketiga pilot pada reduced motion, stop saat blocked/talking, dan work flourishes yang diam. Transform berubah tidak sama dengan anatomi/ilustrasi sudah diterima.
- [npc-body-render.gd:46–71](../../scripts/tests/npc-body-render.gd#L46) membandingkan dua pose work south, lalu satu walk east dan satu north. Alpha-bottom work≤2 px serta body pixels berubah berguna, tetapi belum mencakup west, seluruh prepare/end, footprint stance dunia, atau perbandingan side/rear art asli.
- Rekaman pilot lama di `artifacts/godot/npc-body-rig/` dicatat pada README alat; audit ini tidak membuat render baru atau menganggap rekaman lama cocok dengan revisi source terakhir tanpa pencocokan hash.

## 4. Pilot Ujang yang disarankan berikutnya

Urutkan satu pilot sampai dapat dinilai, bukan memproses seluruh warga sekaligus berdasarkan jumlah state.

### Langkah pertama: kontak pada sumber yang sudah ada

Pertahankan potret/warna asli, atlas cutout proyek, joran bambu dan tali/bobber3D orisinal. Tidak memerlukan paket karakter berbayar atau PixelDoll. Model/tile lingkungan yang sudah berlisensi tidak menyediakan tubuh Ujang empat arah dan tidak boleh diklaim seolah menyediakan hal itu.

- Tambahkan titik sole serta grip dalam metadata gambar, bukan menganggap tengah crop selalu telapak. Simpan nama tangan anatomis kiri/kanan terpisah dari urutan tampilan; flip tidak boleh diam-diam menukar identitas tangan.
- Pisahkan stance dan swing berbasis jarak. Saat stance, simpan titik sole dunia dan kompensasikan gerak badan melalui pose lokal; saat swing gunakan lintasan terangkat yang berakhir pada titik plant berikutnya. Tidak menggeser root actor, tidak membekukan cadence sambil badan terus berjalan.
- Pertahankan panjang segmen dalam rentang yang sesuai bind pose dan volume tekstur. Solusi lutut hanya mengubah pose; tidak menambah gap alpha atau menipiskan betis. Periksa arah normal26 unit/detik, lambat, stop, belok serta hambatan nyata.
- Pertahankan target lempar pada air sah di stasiun Ujang; jangan memutar offset menuju darat hanya untuk membuat empat enum arah tampak berbeda. Work heading ditentukan sisi air, sedangkan empat arah berjalan/dialog dinilai terpisah. Pemeriksaan pose work dari arah tambahan di stage tidak boleh diklaim sebagai empat stasiun pancing legal baru.

### Langkah kedua: empat arah karya asli

Buat sumber staging milik proyek untuk south/east/north/west yang mempertahankan wajah, penutup kepala, rompi, sepatu dan warna Ujang. Source3/4 saat ini dapat menjadi panduan/warna dan bagian front yang sesuai; side/rear/asimetri yang tidak ada harus digambar atau dihasilkan sebagai karya baru lalu diperiksa. Jangan mengisi arah kosong dengan flip dan memberi label selesai. Generator cutout Pillow yang sudah ada dapat menata/menormalisasi sumber dan mempertahankan alpha; ia tidak menciptakan informasi pandangan belakang dari crop depan.

Usulan kontrak sebelum runtime berikutnya:

| Bidang | Kontrak |
| --- | --- |
| `directions` | `south,east,north,west`; perarah mempunyai sumber/hash, bagian dan joint sendiri; fallback dicatat eksplisit. |
| Pose root | Feet `(0,0)`, tinggi tubuh sekitar100 px; actor/navigation tetap otoritatif. |
| Klip | `idle,walk,interact,start_work,work_loop,end_work,rest` mempertahankan nama yang sudah dipakai. Walk mengikuti jarak25 unit/cycle sebagai baseline yang harus divalidasi kontak, bukan target estetika yang kebal perubahan. |
| `contacts` | Perkaki: `grounded`, `soleLocal`, `plantWorld`, `kneeLocal`; stance tidak bergeser melebihi toleransi visual yang disepakati pada rekaman native. |
| `hands` | World sockets kiri/kanan tetap kompatibel dengan alat; metadata `gripPixel` menentukan titik telapak sebenarnya. |
| Alat | Rod/body terpisah; grip kiri/kanan, tip, line end, bobber dan target air dapat dibaca tes. Tidak membakar joran ke setiap frame tubuh. |
| Frame/phase | Delapan keyphase walk untuk review contact/down/passing/up, durasi start0,8 detik/end0,65 detik serta work phase9 detik tetap baseline; pisahkan event satu kali dari pose. |
| Reduced/pause | Essential travel/gait tetap berjalan; idle/work flourishes dikurangi. Blocked/talking tidak memajukan jarak, langkah atau root. |

Bukti penerimaan pilot: native grid empat arah semua fase; close-up telapak/knee/palm; overlay diagnostik joints/grips yang dapat dimatikan; fullscene actual commute/work/dialog siang dan malam; tangan terhadap rod di depan/belakang tubuh; rekaman normal/reduced serta benturan jalur. Ukur sole-world drift selama stance dan jarak grip dari piksel/socket alat yang independen, bukan hanya alpha-bottom atau nilai error yang didefinisikan0. Baru sesudah Ujang diterima lanjut Darmi, lalu Sari. PixelDoll tetap kandidat pipeline masa depan, bukan blocker B1 ataupun alasan mengklaim arah baru tersedia.

## 5. Audit ketujuh shelter terhadap atap nyata

Anchor `shelter` sama dengan `rest` untuk ketujuh profil: [village.ts:6–53](../../packages/shared/src/village.ts#L6). Kelulusan rute B1 membuktikan dapat dicapai pada lantai, bukan terlindung dari hujan.

Metode statis: bentuk atap dihitung dari source renderer, bukan bbox rumah. `_house()` membentuk basis miring dari tiga titik footprint dan `map_point()` ([LandWorld3D:476–494](../../client-godot/scripts/land/LandWorld3D.gd#L476)). Roof limas memakai half-extent0,55width/0,57depth; pelana/balai0,54/0,55 ([baris525–530](../../client-godot/scripts/land/LandWorld3D.gd#L525), [569–603](../../client-godot/scripts/land/LandWorld3D.gd#L569)). Plan roof diturunkan pada bidang tanah elevasi yang sama, sesuai sinar hujan vertikal world-Z; gambar atap yang menumpang kepala pada proyeksi kamera bukan bukti coverage. Booth shade mempunyai plan x1392..1468/y1200..1380 ([1393–1403](../../client-godot/scripts/land/LandWorld3D.gd#L1393)). Hasil berikut perkiraan jarak logical-world ke tepi roof terdekat, bukan hasil raycast GPU baru.

| NPC | Shelter sekarang | Atap terdekat | Jarak ke tepi | Penilaian source |
| --- | --- | --- | --- | --- |
| Lurah | 940,310 | Atap bawah balai | ≈54,8 px | Di luar roof; depan balai bukan otomatis porch tertutup. |
| Ratih | 465,320 | Rumah Ratih | ≈53,0 px | Di luar roof. |
| Ujang | 1210,1250 | Shade bilik Beno | 182 px | Dermaga terbuka; native B1 juga memperlihatkannya. |
| Tedi | 1005,975 | Rumah Tedi | ≈40,7 px | Di luar roof. |
| Sari | 1325,300 | Rumah Sari | ≈60,9 px | Di luar roof. |
| Saras | 1020,310 | Atap bawah balai | ≈45,0 px | Di luar roof; berbagi depan balai, bukan interior kedai. |
| Darmi | 1395,310 | Rumah Sari | ≈58,7 px | Di luar roof; dekat tetangga belum berarti terlindung. |

Semua anchor berada di luar plan atap terdekat; karena titik pusat saja tidak tertutup, seluruh footprint tubuh juga belum tertutup. Pemeriksaan ini tidak memodelkan hujan miring, kebocoran atap atau ray3D baru. Rumah balai yang terlihat terbuka tetap mempunyai footprint collision penuh pada manifest; memindahkan NPC ke tengah bangunan akan membuatnya masuk obstacle meskipun gambar interior tampak dapat ditempati.

### Pilihan perbaikan minimal untuk direview

**A. Gunakan titik tertutup yang benar-benar dapat dicapai.** Ujang mempunyai kandidat di bawah shade existing, misalnya sekitar `(1430,1235)`; titik ini berada dalam plan kain dan jauh dari kedua post, tetapi masih perlu tes `LandCollision`, coverage seluruh badan, jalur/graph dan akses bilik pemain sebelum dipilih. Pertahankan work/rest jika tidak perlu diubah; pindahkan hanya shelter dan tambahkan branch commute resmi bila disetujui. Jangan menjadikan semua warga menumpuk di bilik76 px tersebut. Untuk rumah lain, eave yang tipis di luar footprint tidak otomatis menyisakan clearance tubuh13 px sekaligus coverage badan; jangan menuliskan koordinat covered palsu tanpa pencarian+validasi.

**B. Tambahkan awning kecil yang benar-benar menempel pada fasad.** Ini lebih masuk akal untuk Lurah/Saras di depan balai, Ratih/Tedi di depan rumah sendiri, serta Sari/Darmi di rumah Sari. Gunakan roof/beam bambu/rumbia yang sudah ada, anchoring pada bangunan, tinggi jelas melewati kepala dan runoff ke luar ruang berdiri. Dua kelompok bersama memerlukan luasan/titik berbeda agar tidak menumpuk. Bukan rectangle gelap di udara atau pilar baru tanpa collision.

- Bila cantilever/beam berangkat dari footprint bangunan lama dan tidak menambah tiang di lantai berjalan, perubahan bisa tetap visual: tidak perlu mengubah collider atau layoutVersion hanya demi kain atap. Tetap uji view occlusion, headroom, shadow dan coverage.
- Bila membutuhkan tiang/rail baru di luar footprint lama, data obstacle, body clearance, seluruh rute, spawn/save lama, layout version dan validasi API harus ikut diputuskan. Jangan memperlebar seluruh rumah untuk menyembunyikan masalah; itu dapat menutup jalan utara/akses layanan.
- Memindahkan shelter mengubah metadata rute NPC kosmetik, bukan posisi save pemain secara langsung. Namun tujuan harus diuji dari kedua arah, semua jam/cuaca serta kondisi migrasi layout; jangan mengubah work/spawn/rest atau template rumah diam-diam.
- Ujang: pindah ke shade existing adalah opsi termurah secara model, tetapi penggunaan bilik/privasi dan akses mengganti pakaian pemain perlu dinilai. Alternatif awning dermaga baru memerlukan dukungan/pile yang benar dan footprint bila tiangnya dapat dijangkau; bukan janji visual tanpa penyangga.

Rekomendasi: tangani audit shelter ini sebagai metadata/arsitektur kecil yang terpisah dari perubahan tubuh Ujang. Memasukkan keduanya sekaligus akan menyulitkan pembandingan kontak animasi dan regresi rute. Dokumen ini mengajukan pilihan; **tidak menerapkan atau menyetujui sendiri salah satu perpindahan anchor/penambahan bangunan**.
