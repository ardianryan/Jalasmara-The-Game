# Rencana 06: finishing dunia, aktivitas NPC, dan perluasan desa

**Checkpoint 10 November:** kandidat overnight kini terintegrasi lokal, full61 dunia dan build lulus pada source593dc79/PCK1315f346. Rumah lurah/RV,13rutinitas, enam rig original, jahe/keramba, HUD ringkas dan Fish Gen bukan lagi sekadar referensi; batas native/browser/rilis masing-masing tetap pada [status aktif](../development-status.md). Kaki modular Nala masihOFF, browser transaksi/fault dan startup publik baru menunggu penerimaan; Windows/S23 tersedia nanti dengan bantuan pengguna. Bagian bertanggal9November di bawah adalah baseline/historis, bukan pin rilis aktif.

Pembaruan kandidat 9 November: lihat [handoff aktif](../agent-handoff.md) untuk hasil gabungan dan kegagalan yang sedang diperbaiki. Pengguna menetapkan kamera kiri menghadap serong kanan serta rumah dermaga sejajar sumbu dek; footprint skew lama bukan bukti orientasi yang benar. Port Noxe kini terbatas pada helper kamera berlisensi dalam kandidat; PixelDoll masih referensi. Kandidat shelter/rig/website belum otomatis menjadi rilis staging. [PRD](../PRD.md) dan [petunjuk agent](../../AGENTS.md) menyimpan kebutuhan/pelaporan lintas sesi.

Tanggal: 9 November 2026. Status: **06-A dan perbaikan dasar 06-B1 sudah dirilis ke staging pada source `9ba21c6`, dengan CI akhir dan smoke HTTPS lulus**. Profiling 06-P sudah mencakup baseline, kandidat, dan kontrol berpasangan; Windows/S23 fisik serta sesi panjang masih terbuka. Pilot mekanik kaki Ujang 06-B2 ada pada cabang terpisah, belum diterima sebagai animasi lengkap atau dimasukkan ke paket publik. Pengguna meminta subagent mulai bekerja sambil audit Noxe/PixelDoll berlangsung. Dokumen ini terpisah dari Rencana 03, Rencana 04, dan pembagian jalur pada Rencana 05. Bukti gabungan tersedia pada [laporan pengiriman awal](../reviews/06a-delivery.md).

Baseline: `efdacba0e402f5acc3df174e2c27582381628f53`, sudah terpasang di staging. Pipeline GitLab `3043497430` lulus; pemeriksaan staging mencakup 16 alur tanpa error browser. Keberhasilan baseline bukan bukti bahwa pekerjaan dalam rencana ini sudah selesai.

## 1. Urutan dan hasil yang dituju

| Urutan | Paket | Hasil yang dapat dimainkan |
| --- | --- | --- |
| Persiapan | 06-0 | Titik pembandingan, kondisi dunia, dan ukuran layar yang sama untuk seluruh jalur. |
| Pertama | 06-A: hutan dan laut | Nala terbaca saat masuk hutan; jalan menyatu dengan tanah; platform dan dinding laut terlihat sebagai volume yang bertumpu. |
| Kedua | 06-B: aktivitas warga | Warga bekerja, berhenti untuk berbicara, melanjutkan kegiatan, berteduh, dan pulang dengan gerak tubuh serta alat yang sesuai. |
| Ketiga | 06-C: perluasan desa | Rumah dan pemeran tambahan mempunyai tempat, rute, serta fungsi yang terhubung ke permainan. |
| Paralel | 06-P: performa dan perangkat | Profil Windows/S23 yang terukur, tanpa kehilangan kamera tiga perempat, warna, kedalaman, dan keterbacaan HUD. |
| Lanjutan terpisah | 06-D: fitur rumah dan UI website | Keramba/tanaman/interior serta halaman website dikembangkan setelah paket inti stabil, dengan kontrak dan penerimaan sendiri. |

Setiap paket menghasilkan commit dan bukti tersendiri. Paket B dapat dipersiapkan saat A ditinjau, tetapi perluasan penempatan warga mengikuti geometri yang sudah lolos. Waktu kalender tetap **36 menit aktif per hari game** dan terpisah dari kemajuan cerita.

## 2. Dasar yang dipertahankan

- Godot tetap runtime permainan; React menangani website dan host game.
- Kamera tiga perempat, terrain bertingkat, mesh 3D, parallax, dan perspektif atmosfer tetap menjadi dasar visual.
- HUD Bahari, loading dengan progres byte asli, fullscreen, joystick analog, serta ukuran sentuh/bacaan yang sudah diperiksa dipertahankan. Penambahan informasi tidak boleh membuat HUD kembali menutup permainan, terutama malam.
- Rumah Nala, dua petak kebun, kangkung, pasar bibit, pantry, kalender server, serta alur kedai–pulang–tidur sudah tersedia. Semua itu menjadi regresi, bukan pekerjaan baru.
- Kontainer PT sudah ada untuk Inspektur Raka. Balai lurah juga sudah ada dan mempunyai atap bertingkat. Rumah pribadi lurah dan direktur terpisah belum tersedia.
- Sepuluh NPC bernama sudah terhubung. Tujuh profil aktivitas mencakup enam warga serta Bu Darmi; tiga pilot rig tubuh ialah Ujang, Darmi, dan Sari. Lima anak Laskar Kognisi belum aktif.
- Tiga batu dekoratif laut sudah ditanam pada mesh karang berdasarkan vertex model. Fondasi jembatan, sisi tangga, arus mengikuti kontur, serta buih/air yang sudah bekerja tidak dibangun ulang tanpa temuan baru.

Sumber status: [audit dunia](../reviews/remaining-world-visual-gaps.md), [audit desa/NPC](../reviews/remaining-village-npc-gaps.md), [hasil HUD/loading](../reviews/parallel-hud-loading-delivery.md), dan [arah warna](../art-direction-comfy.md).

## 3. Paket 06-0: pembandingan sebelum perubahan

1. Ambil ulang gambar dan rekaman dari build baseline: pintu masuk hutan, kedua jembatan, pertemuan jalan/rumput desa, platform laut 13, mulut gua, serta kedai malam.
2. Simpan posisi kamera/pemain, jam, cuaca, pakaian, ukuran viewport, profil kualitas, dan revisi source. Perbandingan sebelum/sesudah memakai kondisi yang sama.
3. Periksa temuan tajuk hutan pada build terbaru. Jika tidak lagi muncul, tandai temuan selesai atau tidak terulang; jangan mengubah kamera/daun hanya untuk memenuhi daftar pekerjaan lama.
4. Catat ID lokasi dan layanan yang harus tetap dapat dicapai, termasuk spawn, portal hutan, kedai, rumah Nala, pasar, balai, dan bilik pakaian dermaga.
5. Siapkan akun uji terpisah. Simulasi waktu untuk pengujian tidak menjadi fitur yang dapat digunakan pemain untuk mempercepat kalender atau memperoleh hadiah.

**Selesai jika:** setiap masalah aktif mempunyai titik reproduksi dan bukti visual. Screenshot lama saja tidak cukup untuk menyatakan masalah masih terjadi.

## 4. Paket 06-A: keterbacaan hutan dan laut

### A1. Nala terlihat saat memasuki hutan

Lokasi utama: `LandWorld3D.gd`, penempatan tajuk, dan presentasi aktor daratan. Periksa `ForestOcclusion.gd` serta perilaku renderer aktif sebelum menambah sistem kedua.

- Cari tajuk yang benar-benar berada di antara kamera dan kepala/badan Nala. Gunakan bounds atau metadata yang disimpan; hindari pembacaan gambar dari GPU pada setiap frame.
- Bandingkan penyesuaian framing pintu masuk yang kecil dengan transparansi/dither lokal pada tajuk penghalang. Pilih perubahan paling ringan yang memperjelas pemain pada kamera sebenarnya.
- Jika memakai dither/fade, aktifkan hanya pada tajuk terkait, dengan transisi masuk/keluar yang stabil. Uji alpha-cut agar daun tidak hilang sekaligus atau berkedip ketika arah pemain berubah.
- Pertahankan batang, collision, spawn, elevasi, dan koordinat save. Tajuk lain tetap memberi kedalaman foreground.

**Bukti penerimaan:** rekaman masuk/keluar hutan dan berjalan di bawah tajuk, seluruh arah Nala, siang/malam/hujan, serta profil Ringan/Seimbang. Pemain tetap dapat dikenali dan tajuk pulih setelah dilewati; tidak ada kedipan atau input/interaksi yang terhalang.

### A2. Jalan dan tanah menyatu

- Prioritaskan tepi gerbang, ujung jembatan, pintu rumah, dan patch rumput di pelataran desa yang terlihat dalam audit.
- Tambahkan variasi tepian terbatas melalui mask material atau rumpun rendah dari library yang sudah ada. Pertahankan tekstur piksel tajam dan warna tanah hangat/hijau tropis.
- Tempatkan dekorasi sesuai elevasi terrain. Gunakan batching untuk detail berulang; jangan menambah lampu atau penghalang tinggi hanya untuk menyamarkan pertemuan bahan.
- Poles sambungan plank, tepian jalan, dan pijakan yang masih tampak terpotong berdasarkan gambar baru. Fondasi jembatan yang sudah lolos tetap dipertahankan.

**Bukti penerimaan:** perbandingan dekat dan pada ukuran bermain. Tidak ada rumput melayang, tekstur berkedip, kaki tenggelam, penghalang baru di rute sah, atau lonjakan draw call yang tidak dijelaskan.

### A3. Penyangga platform laut terbaca

Titik awal ialah terrain 13, koordinat `[540,700,340,140]`, serta sambungannya ke terrain 4. Penyangga belakang sudah ada; masalah aktif ialah keterbacaan pertemuannya dengan underside dan dinding gua.

- Perjelas akar/collar pada pertemuan mesh yang sama dan pisahkan nilai warna/reliefnya secukupnya dari dinding belakang.
- Pertahankan penyangga sebagai bagian batu yang tertambat, dengan parallax nol terhadap batu utama. Efek partikel tetap boleh mempunyai parallax sendiri.
- Semua tambahan berada di belakang bidang berenang. Celah yang sah, collider, posisi target, dan save tetap sama.
- Bandingkan dengan senter menyala/mati dan cahaya dari kedua arah. Hindari menambah kabut gelap fullscreen yang menyembunyikan sambungan.

**Bukti penerimaan:** gambar dan gerak kamera memperlihatkan hubungan platform–penyangga–massa batu. Hitungan node atau tes bahwa penyangga ada tidak menggantikan penilaian visual.

### A4. Tepi gua lebih alami

- Pecah siluet bidang belakang `CaveRearRockWall` yang masih terlalu lurus menjadi tepian batu berlekuk dengan volume yang menyatu.
- Batasi perubahan pada tepi yang terlihat. Jangan menambah kolom batu pada lorong berenang atau mengulang perbaikan material yang sudah bekerja.
- Pertahankan pemisahan foreground, bidang renang, dan latar atmosfer. Periksa pertemuan mesh pada kamera bergerak, bukan satu gambar saja.

**Paket A diterima jika:** platform terbaca bertumpu, pintu masuk hutan tidak menyembunyikan pemain, tepi jalan/guanya membaik, dan regresi collision, portal, tiga tumpuan batu, air, HUD, serta kualitas tetap lulus.

## 5. Paket 06-B: aktivitas dan animasi NPC

### B1. Rutinitas yang dapat diandalkan

Verifikasi tujuh profil yang sudah ada sebelum menambah pemeran. Gunakan `village.ts`, `HubActor.gd`, `NpcAnimationState.gd`, `VillageActivity3D.gd`, dan `LandActors3D.gd` sebagai sumber implementasi.

- Periksa tempat kerja, tempat istirahat, tempat berteduh, dan rute pada geometri terbaru.
- Jalankan pergantian pagi, jam kerja, sore, dan malam; uji cerah serta hujan. Simulasi cepat menguji transisi, sedangkan sesi nyata menilai ritme 36 menit.
- Pemain yang mendekat dapat menghentikan warga dengan wajar untuk berbicara. Sesudah dialog, warga melanjutkan aksi/rute tanpa menggandakan aktor atau melompat posisi.
- NPC yang tertahan berhenti mengayunkan langkah dan mencoba pemulihan rute yang dibatasi. Jangan mengabaikan collider atau memindahkannya melalui air/atap.
- Perbaiki pemisahan reduced motion: rutinitas dan akses layanan tetap tersedia; pengaturan tersebut mengurangi gerak tambahan yang tidak diperlukan. Jangan membekukan seluruh kegiatan desa sebagai pengganti pengurangan efek.
- Jeda modal, host Menu, kehilangan fokus, dan pergantian sesi mengikuti kalender yang sudah sah. Jadwal lokal tidak memberikan hasil ekonomi atau kemajuan cerita sendiri.

**Bukti penerimaan:** tabel tujuan dan rekaman kerja–bicara–lanjut–pulang–berteduh. Tidak ada `blocked_*` menetap, warga ganda, layanan cerita yang tidak dapat dijangkau, atau hadiah otomatis dari animasi kosmetik.

### B1a. Rumah panggung dan tempat berteduh dengan pendekatan Noxe

Arahan tambahan pengguna: pengerjaan tempat berteduh mencakup rumah panggung yang terbaca sebagai volume dari pandangan tiga perempat. Metode konstruksi Noxe dimajukan dari persiapan C ke satu pilot B1a; bangunan/pemeran baru pada C tetap mempunyai penerimaan sendiri. Lihat [rincian pilot](06b1a-rumah-panggung-dan-kamera.md).

- Bangun modul native Godot untuk tiang, balok, bracing, kolong, lantai tebal, serambi, akses dan atap. Gunakan platform/elevasi yang sudah tersedia; bila lantai atau footprint berubah, manifest, collision, konektor dan migrasi save ikut diperiksa.
- Tujuh tujuan hujan harus berada di bawah bidang atap fisik, di atas lantai sah, dengan rute serta clearance badan. Titik metadata saja tidak cukup.
- Bandingkan kamera permainan dengan satu preset menyudut pada pilot. Kamera sekarang ortografis pada elevasi 35°, tetapi `map_point` dan proyeksi darat mempertahankan susunan peta lama. Pandangan isometrik dunia memerlukan konsistensi proyeksi aktor, input, interaksi dan penanda; tidak cukup mengganti angka rotasi kamera.
- Pisahkan rotasi bangunan dari kamera. Pintu, tangga, footprint, titik berteduh dan lampu mengikuti transform bangunan yang sama. Pilihan akhir mengikuti keterbacaan sisi/depan/atap/kolong pada ukuran bermain.
- Noxe menjadi sumber metode atau port kecil berlisensi ke Godot. Jika kode upstream dipakai, simpan pin, teks MIT dan atribusi berkas yang diadaptasi. Penerimaan performa tetap memakai renderer game, dengan Windows/S23 fisik dicatat tersendiri.

**Bukti penerimaan:** rumah panggung berpenyangga dan kolong nyata, tujuh warga mencapai area beratap saat hujan, Nala/percakapan tetap terbaca, dan jalur tangga/portal/save lama tetap sah. Pembanding kamera harus berupa render mesh sebenarnya, bukan gambar referensi yang ditempel sebagai latar.

### B2. Matangkan tiga pilot tubuh

| NPC | Rangkaian yang dinilai | Kontak yang harus jelas |
| --- | --- | --- |
| Mang Ujang | Menyiapkan joran, melempar, menunggu, menarik, merapikan, berjalan. | Tangan–joran, tali–pelampung–air; kaki penyangga khasnya dipertahankan. |
| Bu Darmi | Mengambil penyiram, mengarahkan, menyiram, menurunkan, berjalan. | Pegangan alat, tetesan pada petak, telapak di lantai yang sah. |
| Yu Sari | Memegang rangka, menenun, memeriksa, merapikan, berjalan. | Tangan–rangka–benang; alat tidak menembus badan. |

- Selesaikan empat arah dahulu. Evaluasi delapan arah hanya jika transisi kamera/perjalanan menunjukkan kebutuhan yang jelas.
- Periksa diam, jalan, interaksi, mulai kerja, loop kerja, selesai, dan istirahat. Lutut/telapak, perpindahan berat, dan sambungan potongan tubuh harus dinilai pada ukuran tampil.
- Alat tetap terpisah dari tubuh. Metadata pivot kaki, tangan, urutan depan/belakang, dan peristiwa suara disimpan per arah/klip.
- Fase langkah membaca perpindahan nyata. Animasi berhenti saat badan tertahan; suara tidak dipicu berulang oleh satu peristiwa.
- Gunakan aset proyek/library terlebih dahulu. Generasi raster dilakukan jika aset yang sesuai belum tersedia, dengan sumber, prompt, hak pemakaian, dan atribusi tercatat. Koneksi Sprite AI yang belum terverifikasi tidak menghalangi perbaikan melalui alat yang sudah tersedia.

**Bukti penerimaan:** rekaman empat arah di tempat kerja dan rute sebenarnya, siang/malam, dengan alat. Kelulusan validasi atlas saja tidak berarti gerakan sudah natural.

### B3. Perluas ke warga lain secara bertahap

Urutan produksi: Ratih/Tedi/Saras, lalu Lurah/Wira/Beno; Raka mengikuti fungsi pengawasan yang sudah ada.

- Ratih menata atau menimbang dagangan, Tedi memeriksa air/pompa, dan Saras membaca/menulis catatan.
- Lurah membaca tanda pasang atau berbicara; Wira bekerja di meja racik; Beno memakai bangku bengkel. Hubungkan aksi ke tempat kerja, bukan menggoyangkan prop di depan tubuh statis.
- Setiap kelompok mewarisi kontrak arah, kontak alat, dialog, jadwal, pause, dan biaya render yang sudah lolos pada pilot.
- Pertahankan nama, ID, syarat kemunculan Saras, serta layanan yang sudah tersimpan. Jangan mengganti ID tokoh dengan ID distrik atau membuat warga kedua untuk Darmi.

**Paket B diterima jika:** tiga pilot lolos penilaian gerak, kelompok berikutnya mempunyai aktivitas tubuh yang dapat dibuktikan, dan rutinitas tetap berjalan pada perubahan jam/cuaca serta interaksi pemain.

## 6. Paket 06-C: perluasan desa yang terhubung

### C1. Rumah dan tata ruang

- Pertahankan delapan footprint yang sudah ada dan variasi atapnya. Buat rumah pribadi lurah sebagai bangunan terpisah dari balai, dengan ukuran/siluet lebih megah tetapi tetap memakai bahan dan arsitektur pesisir desa.
- Fungsi awal rumah lurah ialah tujuan pulang dan titik percakapan rumah yang dapat dicapai; balai tetap menjadi layanan publik. Interior tidak disebut tersedia sebelum lantai, pintu, interaksi, dan transisi penyimpanannya benar-benar dibuat.
- Lengkapi hubungan rumah–tempat kerja warga yang masih belum jelas. Utamakan akses yang berguna dan kebutuhan rute sebelum menambah rumah pajangan.
- Pintu, tangga, elevasi, jalan, collider, serta rute berasal dari manifest yang sama. Jangan memakai renderer saja sebagai sumber lantai tambahan.
- Jika footprint berubah, naikkan versi layout dan siapkan migrasi posisi lama: pertahankan posisi yang masih sah; posisi yang tertutup bangunan dipulihkan ke lantai sah terdekat yang tetap terhubung ke rute/portal. Uji save lama, bukan hanya pemain baru.

### C2. Kantor PT dan direktur

- Kantor PT tetap memakai kontainer/chassis/atap datar yang berbeda dari rumah warga. Raka tetap **Inspektur Raka**, sesuai cerita yang sudah berjalan.
- Penambahan direktur memakai ID NPC tersendiri dan fungsi cerita/interaksi yang jelas. Periksa dokumen cerita/wiki sebelum menetapkan nama pribadi; bila belum ada, gunakan jabatan **Direktur PT Cakrawala Sintetis** pada rancangan awal, tanpa mengganti identitas Raka.
- Tetapkan hubungan kunjungan/kerjanya dengan kantor kontainer dan rute kedatangan sebelum membuat aset. Bedakan tempat berdiri dari Raka; jangan membuat keduanya menumpuk atau mempunyai trigger layanan yang saling mengambil alih.
- Direktur mempunyai kontainer rumah/RV statis tersendiri sesuai permintaan pengguna; kantor Raka yang sudah ada tetap dipertahankan untuk inspektur. RV yang dapat dikendarai tidak termasuk paket ini.

### C3. Laskar Kognisi

- Integrasikan lima anak dalam dua kelompok: Bagas/Kinasih/Danu, kemudian Gito/Cempaka. Setiap anak mempunyai satu identitas, ukuran tubuh anak, tempat berkegiatan, jadwal, interaksi, dan dialog yang sesuai canon.
- Perkenalkan kegiatan yang dapat dilihat dan interaksi yang berfungsi terlebih dahulu. Bantuan otomatis kebun, keramba, prediksi pelanggan, atau bonus kedai memerlukan kontrak server pada paket lanjutan; jangan menampilkan manfaat tersebut sebagai fitur aktif sebelum tersambung.
- Sesuaikan markas/perahu dan aksesnya dengan terrain serta rute sah. Tidak ada rumah/markas yang hanya dapat dicapai dengan berjalan di air atau melompati collider.
- Hitungan pemeran mengikuti daftar yang benar-benar terhubung. Jangan mengejar angka sebelas dengan menggandakan warga yang sudah ada.

**Paket C diterima jika:** bangunan/pemeran baru mempunyai fungsi nyata, pintu/rute dapat dilalui, jadwal dan dialog sesuai peran, save lama pulih dengan benar, serta layanan dan kemajuan cerita lama tetap berjalan.

## 7. Jalur 06-P: performa dan pengujian perangkat

Jalur ini dimulai bersama Paket A dan mengikuti setiap rilis. Pekerjaan yang membutuhkan Windows/S23 fisik ditandai menunggu perangkat jika perangkat tidak tersedia. Persiapan, diagnosis lokal, dan regresi tetap dapat dilakukan tanpa mengklaim hasil perangkat asli.

| Lingkungan | Skenario |
| --- | --- |
| Windows nyata | Chrome/Edge dan Firefox; 1080p, skala sistem 100%/150%, window/fullscreen; catat GPU dan hardware acceleration. |
| Samsung S23 nyata | Chrome dan Samsung Internet; portrait/landscape, bilah browser, fullscreen, safe area, dua jari, Wi-Fi normal dan koneksi terganggu. |
| Sesi panjang | 15–20 menit: desa ramai, tajuk hutan, jembatan, rumah/kebun, hujan/malam, penyelaman/senter/fauna, buku dan kedai. |
| Regresi otomatis | 667×375, 844×390, 390×844, desktop dan layar lebar; gunakan dimensi efektif perangkat ketika sudah diukur. |

Catat median FPS, waktu frame p95, jeda panjang, process/physics time, draw call, objek aktif, perubahan memori, antrean jalur, waktu respons API, serta waktu startup dingin/hangat. Pisahkan byte aset terdekode dari transfer jaringan terkompresi. Respons API bukan RTT jaringan murni; renderer otomatis bukan GPU perangkat fisik.

Sasaran awal profil Ringan ialah 30 FPS stabil pada S23, dengan waktu frame p95 tidak lebih dari 50 ms pada rute yang disepakati. Ini target penerimaan, belum hasil pengukuran atau janji. Target desktop ditetapkan setelah perangkat/GPU baseline tercatat; 60 FPS menjadi sasaran pada perangkat yang memadai.

Urutan optimasi mengikuti hasil ukur: update HUD/marker yang tidak berubah, aktor/dekorasi di luar kamera, alokasi per frame, batching, material, partikel, lalu bayangan/lampu. Jangan menurunkan seluruh kualitas sekaligus karena penyebab perbaikan menjadi tidak jelas. Pertahankan batas resolusi dunia yang ada dan render UI terpisah.

**Selesai jika:** ada tabel sebelum/sesudah pada perangkat sebenarnya, satu profil kualitas yang dapat dipakai dengan nyaman, tidak ada pertumbuhan resource terus-menerus selama sesi panjang, dan fungsi/perspektif/warna/HUD tetap lolos. Tanpa perangkat fisik, status paket hanya selesai sebagian.

## 8. Pembagian subagent dan kepemilikan file

Kapasitas saat penyusunan ialah empat agent aktif termasuk integrator, sehingga maksimal tiga pekerja berjalan bersamaan. Branch/worktree baru dimulai dari baseline rilis terbaru; jangan melanjutkan branch lama `3d648e8` tanpa memasukkan hasil integrasi terakhir.

| Gelombang | Pekerja 1 | Pekerja 2 | Pekerja 3 | Integrator |
| --- | --- | --- | --- | --- |
| 06-A | Hutan/jalan dan occlusion | Platform/dinding laut | Profiling dan regresi | Bukti baseline, review, gabung, dan rilis. |
| 06-B | Jadwal/rute NPC | Rig/animasi pilot dan batch | Aset/validasi atau profiling | Kontrak alat/tubuh, review rekaman, dan integrasi. |
| 06-C | Penempatan bangunan/terrain | Pemeran/interaksi baru | Regresi save/perangkat | Manifest, migrasi, cerita, dan rilis. |

Kepemilikan awal: hutan pada helper occlusion, `LandWorld3D.gd`, dan `LandMaterials.gd`; laut pada `OceanGeology.gd` serta `TerrainGeometry.gd`; NPC pada `HubActor.gd`, `NpcAnimationState.gd`, `NpcBodyRig3D.gd`, `VillageActivity3D.gd`, serta bagian aktor `LandActors3D.gd` yang dikoordinasikan. `LandWorld3D.gd` dipakai kembali oleh jalur bangunan setelah pekerjaan hutan dibekukan.

File bersama `world.ts`, `land.ts`, `village.ts`, konfigurasi proyek, kamera, serta endpoint API mempunyai satu penulis pada satu waktu. Integrator menetapkan penulisnya sebelum perubahan; pembagian ini tidak memerlukan pertanyaan izin baru kepada pengguna untuk pilihan implementasi rutin.

Setiap subagent menyerahkan commit terbatas, daftar perubahan, bukti sebelum/sesudah, hasil tes, serta batas yang masih terbuka. Subagent yang selesai mengambil pekerjaan independen berikutnya dalam paket aktif. Jika menunggu perangkat, ia dapat menyiapkan rekaman, fixture, atau audit CPU/aset; hasil perangkat tidak boleh dibuat-buat. Benchmark GPU tidak berjalan bersamaan dengan render lain. Import/export yang memakai cache sama dijadwalkan bergantian. Integrator melakukan penggabungan dan deployment.

## 9. Pengujian, peninjauan, dan rilis

- Perubahan visual sederhana dinilai melalui gambar/video terkontrol dan uji rute; tidak perlu tes yang hanya menghitung ulang detail implementasi.
- Perubahan occlusion, tumpuan mesh, rute, pause, arah/anchor, migrasi, atau transaksi memperoleh regresi pada kontrak pentingnya.
- Pertahankan baseline 77 tes API, 34 pemeriksaan dunia, pengujian bridge/loading, serta alur browser yang relevan. Jumlah tes boleh bertambah sesuai kontrak baru; jumlah saja bukan bukti mutu visual.
- Periksa HUD siang/malam pada setiap paket: sasaran HUD minimal 48 piksel fisik, aksi modal minimal 56 piksel, bacaan utama minimal 16 piksel; area karakter, pelanggan, dan interaksi tidak tertutup dekorasi baru.
- Jalankan putaran desa–hutan–laut–kedai–rumah–tidur pada kandidat gabungan. Periksa kalender 36 menit, pause, reconnect, stok, serta progres cerita.
- Tinjau gambar terhadap moodboard comfy pada kondisi yang sama. Pelihara pijakan, tinggi terrain, arah cahaya, parallax, dan pemisahan bayangan berwarna; hindari sekadar menaikkan saturasi seluruh layar.
- CI memeriksa source yang sama dengan kandidat rilis. Backup dan image rollback dipertahankan; deployment aplikasi menjaga data akun. Sesudah pemasangan, cocokkan hash paket publik dan jalankan smoke melalui alamat staging.

Rilis bertahap: **06-A keterbacaan dunia**, **06-B rutinitas/animasi warga**, kemudian **06-C perluasan desa**. Setiap rilis menyebut status perangkat fisik secara terpisah. Tidak ada label “semua finishing selesai” jika hanya CI yang lulus.

## 10. Paket 06-D dan pekerjaan sesudah inti stabil

| Lanjutan | Persiapan yang diperlukan | Batas paket |
| --- | --- | --- |
| Tanaman kedua/perluasan petak | Definisi bibit, hari tumbuh, perawatan, hasil, biaya, dan penggunaan nyata. | Satu tanaman lengkap sebelum batch tanaman lain; transaksi/retry tetap sah. |
| Keramba | Aturan spesies/pasangan, kapasitas, penyelesaian hari, hasil, serta idempotency server. | Satu alur tangkap–masukkan–rawat–berkembang–gunakan hasil; belum termasuk seluruh biota. |
| Hidroponik pH/PPM/komposter | Kontrak bahan/air/nutrisi dan UI yang menerangkan keputusan pemain. | Direncanakan sebagai fitur sendiri; tidak dicampur dengan finishing gambar atau kalender kosmetik. |
| Interior warga | Identitas interior, lantai, pintu, pencahayaan, interaksi, posisi dan migrasi save. | Satu interior pilot; boolean `inside` rumah Nala tidak dipakai ulang untuk semua rumah. |
| UI landing/akun/admin | Audit alur login, pengaturan, reset, formulir panjang, role, error dan mobile. | Jalur website tersendiri setelah slot prioritas dunia tersedia; tema konsisten dan teks tetap terbaca. |
| WorldKit dan alat sprite | Kebutuhan produksi yang terbukti, lisensi/atribusi dan jalur ekspor yang teruji. | Gunakan integrasi yang sudah tersedia lebih dahulu; perluasan editor mengikuti [backlog authoring](../nextgen-world-authoring.md). |

Paket D dicatat agar sisa permintaan tidak hilang. Implementasinya tidak menjadi syarat menyelesaikan paket A dan B; setiap perluasan memerlukan rincian kontrak serta bukti penerimaan tersendiri sebelum kode fiturnya dibuat.

## 11. Daftar penerimaan

Tambahan referensi pengguna, 9 November 2026: [audit Noxe dan PixelDoll](../world/noxe-pixeldoll-reference.md). Metode bangunan Noxe dimajukan ke pilot B1a dan helper orbit/snap diport secara terbatas ke Godot dengan MIT; ini belum mengganti kamera gameplay global. Interior playable tetap paket D. PixelDoll masih kandidat authoring layer pakaian/alat pada paket B melalui adapter billboard Godot; delapan arah Nala harus mandiri dan fase langkah tetap mengikuti perpindahan nyata. Pilot kecil dan bukti visual/performa mendahului batch; urutan A–B–C serta jalur perangkat tidak berubah.

- [x] Bukti baseline terbaru dan temuan aktif sudah dicocokkan.
- [x] Kepala/badan Nala terbaca pada pintu masuk dan jalur bertajuk tanpa menghilangkan kedalaman foreground.
- [x] Tepi jalan/rumput, sambungan platform, dan tepi gua membaik pada kamera sebenarnya.
- [ ] Tujuh rutinitas warga tidak terjebak, menggandakan aktor, atau mengunci layanan.
- [ ] Tiga pilot dan batch warga berikutnya memenuhi kontak tubuh/alat serta arah yang ditetapkan.
- [ ] Rumah lurah, direktur dan Laskar yang dirilis mempunyai identitas, lokasi, rute, serta fungsi nyata.
- [ ] Save lama, kalender, pertumbuhan, kedai dan kemajuan cerita tetap benar setelah perluasan layout.
- [ ] Pengujian Windows/S23 mencatat perangkat, kondisi, durasi dan metrik yang sebenarnya, atau ditandai belum tersedia.
- [x] HUD paket awal tetap ringkas, UI dapat dibaca/dioperasikan, CI hijau dan kandidat staging diperiksa melalui alamat publik.

Tanda selesai di atas terbatas pada paket awal 06-A/B1 dan regresinya. Dasar rutinitas B1 sudah diperiksa, tetapi tujuh tujuan hujan belum berada di bawah atap fisik sehingga penerimaan aktivitas lengkap tetap terbuka. Tidak ada perluasan layout pada rilis ini. Catatan pelaksanaan menyebut paket, revisi source, bukti, hasil, serta kekurangan yang masih tersisa.
