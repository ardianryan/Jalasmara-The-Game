# Rencana 04: HUD, fullscreen, performa, dan gerak Nala

Tanggal: 9 November 2026. Status: **implementasi inti tersedia dan diuji lokal; penerimaan perangkat nyata belum selesai**. Disusun dari laporan Windows/Samsung S23, tangkapan layar pengguna, audit kode, dan brief HUD sebelumnya. Dokumen ini terpisah dari [Rencana 03](03-desa-hidup-dan-siklus-harian.md); keberhasilan fitur rumah dan kalender tidak berarti performa HP atau seluruh pemolesan animasi selesai. Hasil dan batas bukti tersedia pada [laporan pemeriksaan](../reviews/plan04-delivery.md).

## Revisi artwork HUD

Setelah baseline `3d648e8`, pengguna meminta penggantian tampilan HUD dengan kit pixel art yang lebih nyata: bingkai kayu–kuningan, kertas, lencana, dan ikon bahari asli. Tampilan sebelumnya belum diterima secara visual. Pengerjaan ini merupakan kelanjutan terpisah dari bukti fungsi yang sudah lulus, dengan referensi contoh IndigoLay dari pengguna tanpa menyalin asetnya. Integrasi mencakup HUD, percakapan, SmaraPedia, tas, dan atlas melalui helper tekstur bersama; tidak menambahkan bar HP/MP atau statistik fiktif. Hasil perlu diperiksa kembali pada desktop, lanskap sempit, dan portrait, termasuk kontras tekstur, fokus, teks 16 px fisik, serta target sentuh yang sudah ditetapkan.

## 1. Hasil yang dituju

Permainan memenuhi area layar yang tersedia, mempunyai tombol fullscreen yang berfungsi, dan tetap nyaman ketika keluar fullscreen atau berganti orientasi. HUD serta percakapan memakai bahasa visual kayu–kuningan Jalasmara dengan teks yang mudah dibaca. Kontrol sentuh menjadi joystick analog bulat. Nala berjalan dengan perpindahan berat badan dan kontak kaki yang jelas dalam delapan arah. Dunia tetap mempunyai kamera tiga perempat, terrain, air bergerak, parallax, dan atmosfer; optimasi tidak boleh menghilangkan identitas tersebut.

Runtime tetap **Godot**, sedangkan React menangani halaman dan browser. Contoh Phaser pada brief lama menjadi referensi perilaku, bukan alasan untuk mengganti engine atau membuat HUD kedua yang menumpuk HUD Godot. Siklus hari tetap 36 menit aktif dan aturan server tetap berlaku.

## 2. Temuan audit sebelum implementasi

| Bagian | Temuan audit | Implikasi |
| --- | --- | --- |
| Halaman permainan | `apps/web/src/play.tsx` memberi izin fullscreen pada iframe, tetapi belum menyediakan tombol/API/state fullscreen. Header dan pengurangan tinggi masih ada pada `main.tsx` serta `style.css`. | Perbaiki shell halaman dan viewport engine bersama-sama. |
| Resolusi | Basis UI 960×540, dunia 480×270, banyak koordinat HUD tetap. | Layar lebar/pendek perlu tata letak dan kamera adaptif; memperbesar CSS saja tidak cukup. |
| HUD | `GameHud.gd` mempunyai fondasi indikator oksigen, tetapi banyak posisi tetap dan misi dapat terpotong. | Pertahankan state yang benar, bangun ulang presentasinya. |
| Percakapan | Presenter sederhana di `Main.gd` dan dialog hutan terpisah di `Forest.gd`. | Satukan perilaku dialog, potret, input, dan keterbacaan. |
| Sentuh | Empat tombol arah; melepas satu tombol dapat mengirim vektor nol. Pengolahan input hub dan hutan berbeda. | Gunakan satu kontrak analog dengan kepemilikan pointer. |
| Jalan | `CharacterVisual.gd` memakai dua pose bergerak pada tempo tetap dan flip kiri/kanan. | Memerlukan klip directional dan penggerak fase berdasarkan gerak aktual. |
| Performa | Ada rebuild area ketika petak kebun berubah, serialisasi diagnosis berkala, dan pekerjaan presentasi tersembunyi. | Kandidat optimasi yang perlu dibandingkan lewat profiling. |
| Gerak tersendat | Antrean jalur bisa penuh saat menunggu server. | Pisahkan masalah jaringan dari masalah FPS. |

Belum ada profiling oleh agen pada Windows atau S23 fisik. Screenshot dan laporan pengguna merupakan bukti masalah, tetapi belum menentukan penyebab CPU/GPU/jaringan. Hasil browser emulasi tidak boleh dilaporkan sebagai hasil S23.

## 3. Tahap A — baseline performa dan kontrak layar

### A1. Rekam sebelum mengubah

Buat lintasan pengujian yang dapat diulang: desa ramai → jembatan hutan → rumah → siram/panen → kembali desa → menyelam → buka dialog/buku. Ulangi pada siang cerah serta malam/hujan. Catat unduhan awal, inisialisasi, dan permainan setelah pemuatan secara terpisah.

Ukur frametime p50/p95/p99, hitch di atas 100 ms, waktu script/physics/render, draw call aktual, memori, RTT, panjang antrean jalur, durasi antrean penuh, serta waktu input sampai gerakan terlihat. Angka `debug.meshes` saat ini bukan penghitung draw call lengkap. Simpan profil, konfigurasi perangkat, dan rekaman lintasan yang sama untuk pembandingan sesudah perubahan.

Target awal yang harus divalidasi: desktop 60 FPS; profil hemat ponsel 30 FPS stabil. Anggaran frame masing-masing 16,7 ms dan 33,3 ms, dinilai dengan persentil serta stall, bukan rata-rata FPS saja. Usulan gerbang akhir: p95 tidak melampaui anggaran profil pada lintasan standar setelah warm-up; seluruh hitch besar diberi penyebab. Uji ponsel berlanjut 15–20 menit untuk melihat thermal throttling. Bila target belum tercapai, laporkan hasil dan batasnya secara eksplisit.

### A2. Halaman permainan memenuhi layar

- `/play` memakai shell khusus yang mengisi viewport browser; navigasi situs dipindahkan ke menu ringkas selama bermain. Tetap ada cara kembali ke akun/keluar.
- Tinggi mengikuti perubahan browser mobile melalui unit viewport dinamis dan pembaruan ukuran yang sesuai; hormati safe area/notch dan perubahan bilah browser. Jangan mengandalkan satu pengurangan header tetap.
- Tambahkan tombol DOM **Layar penuh / Keluar layar penuh** yang memanggil API langsung dari gestur pengguna. Dengarkan `fullscreenchange` dan error; ikon mengikuti state browser sebenarnya. Keluar lewat Escape maupun tombol browser harus dipulihkan dengan benar.
- Bila API tidak tersedia atau ditolak browser, mode memenuhi viewport tetap bekerja dengan pesan singkat yang sesuai. Jangan menampilkan state fullscreen palsu. Kunci landscape hanya dicoba bila didukung; portrait tetap memiliki tampilan yang dapat digunakan.
- Pesan iframe memvalidasi origin **dan** `event.source`; ukuran dan status fullscreen dikirim melalui kontrak host yang terbatas. Jangan menaruh token atau data akun dalam pesan ukuran.
- Atur template ekspor/pengaturan Godot yang menjadi sumber; jangan memperbaiki HTML hasil ekspor yang akan tertimpa build.

### A3. Kamera dan piksel

Prototipekan pengaturan aspect/expand yang mempertahankan proporsi objek dan sudut kamera tiga perempat. Dunia menambah area terlihat sesuai aspect ratio, bukan memipihkan gambar 16:9. Tinggi render rendah tetap menjadi acuan; lebar internal dihitung dari aspect dan dibatasi berdasarkan hasil profil. Jangan menaikkan render dunia mengikuti DPR perangkat tanpa batas.

Pisahkan resolusi dunia dari ukuran UI. UI memakai anchor/container dan skala yang menjaga target fisik sentuh serta ukuran teks. Periksa sprite pixelated, pemetaan world-to-screen, minimap, interaksi, dan culling setelah kamera berubah. Default harus memenuhi layar, tanpa bar hitam besar seperti laporan pengguna.

Rujukan implementasi: [resolusi Godot](https://docs.godotengine.org/en/stable/tutorials/rendering/multiple_resolutions.html) dan [Fullscreen API](https://developer.mozilla.org/en-US/docs/Web/API/Element/requestFullscreen). Perilaku browser wajib diuji, bukan diasumsikan dari izin iframe.

## 4. Tahap B — joystick analog dan satu jalur input

Buat adaptor input bersama untuk hub, hutan, interior, dan penyelaman; aturan berenang tetap berbeda dari berjalan. Kontrak internal mengirim vektor dua dimensi bermagnitudo 0–1, sumber input, dan status aktif. Ini usulan kontrak baru, bukan API yang sudah tersedia.

Joystick berupa alas bulat transparan dengan thumb bulat di kiri bawah. Radius dan posisi mengikuti safe area serta ukuran layar. Terapkan dead zone awal sekitar 0,15, kurva halus, batas radius, dan normalisasi diagonal. Besaran analog mengendalikan kecepatan; jangan dinormalisasi menjadi kecepatan penuh pada semua simpangan.

Pointer pertama dalam area joystick menjadi pemilik sampai dilepas. Pointer lain tetap bisa menekan aksi di kanan. Seret keluar batas tetap terbaca melalui capture yang sesuai. `pointercancel`, kehilangan fokus, buka modal, pergantian orientasi/ukuran, dan keluar fullscreen selalu mengosongkan input agar karakter tidak berjalan sendiri. Menutup modal tidak menghidupkan kembali input lama.

Tombol aksi kanan minimal 48×48 piksel fisik, terpisah dari utilitas. Tampilkan hanya aksi yang benar-benar tersedia. WASD/panah keyboard dan gamepad tetap didukung; pilih sumber input aktif tanpa menjumlahkan input sehingga gerak melebihi batas. Uji collision, lereng, tangga, jembatan, dan transisi area dengan simpangan kecil maupun penuh.

## 5. Tahap C — HUD dan percakapan sesuai brief

### C1. Fondasi visual dan tata letak

Gunakan arah merek yang sudah ada: kayu gelap, kuningan, perkamen, cahaya sian, dan bayangan piksel tegas. Judul pendek/angka memakai font pixel yang tersedia; teks dialog, soal, dan penjelasan memakai font tubuh yang mudah dibaca. Target minimum teks panjang 16 piksel fisik di HP dan 18 di desktop, diverifikasi pada canvas nyata setelah scaling.

Buat komponen panel, tombol, indikator, tooltip, dan presenter reusable. Gerak tekan terasa langsung; spring singkat hanya untuk masuk panel yang relevan, dengan reduced-motion. Hindari kartu dashboard, bingkai raksasa kosong, dan modal berlapis yang menutup sebagian besar dunia.

HUD mengikuti container/anchor dan tiga kondisi: desktop, landscape pendek, portrait. Misi menampilkan instruksi penting yang utuh serta tombol perluasan detail; jangan memotong tujuan dengan ellipsis tanpa jalur membaca lengkap. Minimap dan tombol utilitas tidak bertabrakan dengan joystick, dialog, atau notch.

### C2. HUD dunia dan penyelaman

- Kiri atas: kapsul O2 dengan angka, warna aman/peringatan di bawah 35%/bahaya di bawah 15%, perubahan O2 yang terbaca, dan umpan balik bahaya yang menghormati reduced-motion.
- Kedalaman/nama zona serta beban tas memakai data aktual. Peringatan beban mulai 80%; angka tidak hanya dibedakan lewat warna.
- Koin dan akses buku/ransel ringkas. Panel dapat menyesuaikan panjang nama zona tanpa menutupi dunia.
- Reticle, pratinjau jangkauan, indikator interaksi, dan progress aksi kecil mengikuti posisi dunia/kamera yang sebenarnya. Jangan menempatkannya dengan perkiraan koordinat layar tetap.
- Kedai memakai antrean, kesabaran, dan progress yang tersedia dari gameplay. Meter katalis hanya ditambahkan setelah state/mekanik pendukung tersedia; tidak boleh ada indikator dekoratif palsu.

### C3. Satu presenter percakapan

Bangun presenter bersama untuk desa, hutan, rumah, dan NPC yang relevan. Pisahkan dari panel transaksi, pilihan tidur, serta kuis; ketiganya tidak otomatis menjadi dialog bergambar.

Kotak bawah proporsional sekitar seperempat layar pada desktop, menyesuaikan tinggi layar dan panjang teks pada HP. Potret setengah badan menyembul dari bingkai, pita nama serta jabatan tidak menghalangi teks. Awali dengan aset asli yang tersedia; emosi tambahan dicatat sebagai kebutuhan aset, bukan gambar rusak atau karakter pengganti.

Teks muncul bertahap dengan blip yang dibatasi frekuensinya. Klik/Space/Enter pertama menyelesaikan kalimat, berikutnya melanjutkan; jangan melompati dua kalimat dalam satu input. Parse penekanan kata sebelum menghitung karakter terlihat agar `**` tidak muncul selama reveal. Dialog panjang tetap terbaca dan dapat diulang melalui riwayat percakapan bila fitur itu dipilih dalam implementasi. Emote bukan emoji sistem yang berubah antardevice.

Input permainan dilepas saat dialog terbuka. Bahaya/gerak yang relevan berhenti, sedangkan idle dan air tetap bergerak dengan biaya terbatas. Tentukan perilaku kalender bersama server sebelum mengubah pause; jam tidak boleh menyimpang antara UI dan akun.

### C4. Buku, inventori, dan kuis yang belum terpenuhi

Audit masing-masing panel terhadap brief lama, lalu selesaikan dalam tahap ini:

| Panel | Hasil yang harus tersedia | Ketergantungan |
| --- | --- | --- |
| SmaraPedia | Buku taktil, transisi sekitar 380 ms, dua halaman desktop, detail responsif HP, tab biota/konsep/warga/misi, siluet belum ditemukan. | Koleksi/progres nyata; stempel hanya untuk penemuan baru, bukan setiap render. |
| Ransel | Grid koper, detail item, bobot jelas, navigasi sentuh/keyboard. | Buang/lepas tahan 0,8 detik hanya sesudah kontrak server aman tersedia; jangan memasang tombol palsu. |
| Kuis | Teks panjang terbaca, pilihan 2×2 dengan tinggi minimal 56 piksel, input 1–4, status menunggu/gagal/kirim ulang jelas. | Timer dan hasil mengikuti server; cegah submit ganda. Pertahankan penangkapan biasa tanpa kuis jika itu aturan saat ini. |
| Menu/modal | Fokus keyboard, close/back konsisten, pengembalian fokus dan pelepasan input. | Pause bahaya/O2 dan kalender sesuai kontrak; shader bukan alasan membiarkan simulasi bahaya berjalan. |

## 6. Tahap D — animasi berjalan natural dan delapan arah

### D1. Pilot sebelum memperbanyak aset

Mulai dari satu identitas Nala berpakaian harian, satu klip berjalan per arah. Tetapkan ukuran tubuh, skala terhadap rumah, perspektif tiga perempat, palet, pivot telapak kaki, dan posisi tangan terlebih dahulu. Delapan arah berarti artwork arah yang benar; jangan memutar seluruh kartu sprite atau sekadar mirror empat pose untuk semua sudut.

Klip harus memperlihatkan contact → down → passing → up dengan kaki penopang stabil, lutut menekuk, panggul berpindah berat, dan lengan berayun berlawanan. Tidak cukup hanya membuka/menutup kaki. Periksa depan/belakang/samping/diagonal pada kecepatan normal dan lambat, dengan lantai grid untuk mendeteksi foot sliding.

Tambahan laporan pengguna, 9 November 2026: cuplikan karakter menunjukkan tungkai terlalu tipis, tekukan bersudut tajam, dan tumpuan telapak yang tidak jelas. Perbaikan artwork kaki menjadi syarat sebelum memperbanyak atlas: proporsi paha–betis–pergelangan konsisten, sepatu mempunyai volume dan sol, sambungan panggul/lutut tidak tampak terputus, serta kedua kaki tidak membuka berlebihan. Periksa pose diam dan setiap fase secara terpisah pada ukuran asli maupun pembesaran nearest-neighbor. Kaki penopang harus menyentuh bidang tanah dan kaki ayun melewati tubuh secara wajar; mempercepat animasi atau menambah frame saja tidak menyelesaikan masalah anatomi. Cuplikan pengguna menjadi referensi cacat, bukan target gaya.

### D2. Alur Sprite AI yang benar

Audit lanjutan cuplikan kaki mengidentifikasi rig NPC Ujang sebagai sumber pose yang dilaporkan. Lingkup perbaikannya mencakup sambungan potongan paha/betis pada rig NPC dan pembatasan tekukan lutut, dengan identitas kaki penyangga Ujang tetap dipertahankan. Kriteria proporsi dan kontak kaki di atas tetap berlaku pada pilot pemain.

Dua tautan pengguna menjadi referensi kemampuan, bukan aset Nala yang langsung disalin:

- [Referensi delapan arah](https://www.sprite-ai.art/gallery/friendly-travelling-merchant-8-directions-ed10).
- [Referensi berjalan](https://www.sprite-ai.art/gallery/young-biblical-shepherd-character-sprite-walking-forward-7fe4).

Halaman galeri tersebut tidak berhasil dibuka dalam audit ini; gerak per frame belum diverifikasi. Tool Sprite AI juga belum callable pada sesi ini, walaupun konfigurasi lokal pernah dicatat. Implementasi dimulai dari pemeriksaan koneksi, capabilities, saldo, dan hak output; tidak ada job berbayar yang dijalankan saat perencanaan.

Menurut [panduan MCP resmi](https://www.sprite-ai.art/api/mcp/docs), rotasi menghasilkan delapan still, bukan delapan animasi berjalan. Alur yang direncanakan: impor still Nala orisinal → rotasi → potong arah → impor setiap still arah → animasikan berjalan per arah → rapikan offline → ekspor atlas dan metadata pivot/anchor. Input animasi berupa still, bukan sheet delapan arah utuh. Mulai delapan frame per klip; periksa hasil sebelum memperbanyak identitas/pakaian. Biaya dihitung ulang dari capabilities/saldo saat eksekusi, bukan diasumsikan gratis.

[Lisensi galeri](https://www.sprite-ai.art/license) membedakan aset galeri personal/nonkomersial dari lisensi output yang dibuat sendiri pada paket berbayar. Gunakan sumber Nala milik proyek, catat asal output serta ketentuannya, dan tambahkan atribusi/lisensi yang berlaku. Jangan memasukkan API key ke Git, Markdown, log, atau aset build.

Jika layanan belum dapat dipakai, lanjutkan pilot lewat penyunting sprite/rig offline yang tersedia. Setiap kekurangan kualitas dicatat; fallback dua pose lama tidak boleh disebut animasi natural selesai.

### D3. Integrasi locomotion dan perlengkapan

Penggerak animasi membaca perpindahan aktual setelah collision, bukan tombol yang ditekan. Fase langkah mengikuti jarak/kecepatan; saat menabrak dinding, kaki tidak terus berjalan di tempat. Tambahkan hysteresis arah agar diagonal tidak berkedip, transisi idle yang stabil, dan pengaturan kecepatan klip tanpa root motion ganda.

Footstep dipicu pada contact frame dengan permukaan terrain yang benar: tanah, rumput, batu/tangga, dermaga, jembatan, pasir, atau air dangkal. Jangan memicu dari timer terpisah yang tidak sejalan dengan kaki. Tangga mengubah elevasi melalui geometri yang sudah divalidasi; sprite tetap tertambat pada lantai. Renang memiliki penggerak/klip sendiri.

Pakaian harian, explorer, dan diving mempertahankan identitas Nala. Tabung oksigen, tas, senjata/jala tetap terpisah dengan anchor per arah/frame dan urutan depan/belakang yang benar. Perbanyakan empat identitas × tiga pakaian baru dilakukan setelah pilot lolos; jangan menyatukan tabung atau senjata ke gambar tubuh untuk mempercepat produksi.

## 7. Tahap E — optimasi berdasarkan pembandingan

Profiling dimulai pada tahap A; perubahan berikut dijalankan satu kelompok per pembandingan sehingga penyebab perbaikan dapat diketahui.

| Urutan | Kandidat dan lokasi | Tindakan yang diuji |
| --- | --- | --- |
| E1 | `Main.gd:357–376`, snapshot lengkap ke JS tiap 100 ms. | Diagnosis opt-in; rilis normal tidak menyerialisasi seluruh dunia. Harness dapat mengaktifkannya secara eksplisit. |
| E2 | `LandWorld3D.gd:175–178,1043–1049`; `WaterField.gd`. | Update petak lokal; cache shoreline/geometri berdasarkan versi area, bukan status tanaman. |
| E3 | `LandWater3D.gd:166–192`; presentasi 2D yang tersembunyi. | Hentikan pekerjaan visual renderer nonaktif. Pertahankan simulasi fauna yang masih dipakai renderer aktif. Tidak mengklaim dua viewport sedang menggambar bersamaan. |
| E4 | Sampling elevasi dan diagnostik rig per frame. | Cache polygon/bounds dan metadata kaki; snapshot pose hanya saat dibutuhkan. Hindari pembacaan image GPU saat pergantian pose runtime. |
| E5 | Shadow, lampu, batching seluruh area. | Bandingkan jarak/atlas shadow, batas lampu, dan batching per wilayah. Batching besar dapat mengurangi manfaat culling. |
| E6 | Minimap/navigasi/HUD berdasarkan hitungan frame. | Pisahkan geografi statis dan marker; gunakan perubahan data/interval waktu agar FPS rendah tidak memperlambat HUD. |
| E7 | `Player.gd:58`, `LandPath.gd`, sinkronisasi server. | Ukur antrean penuh dan RTT; kaji sampling/batching/ack dengan replay serta validasi jalur. Jangan menghapus collision atau otoritas server. |

Sediakan profil kualitas yang menjaga kamera, terrain/collision, warna comfy, dan gerak air. Profil hemat mengurangi shadow dekoratif, kepadatan partikel/vegetasi dekoratif, jarak detail, atau frekuensi update jauh berdasarkan bukti. Peralihan otomatis memerlukan hysteresis agar tidak berkedip antarprofil. Simpan pilihan manual pemain. UI tidak boleh menjadi buram ketika dunia memakai resolusi hemat.

Ekspor browser tetap Compatibility/WebGL 2.0. Jangan menjadikan pergantian renderer Mobile/Forward+ atau multithreading sebagai solusi otomatis. [Dokumentasi ekspor Web Godot](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html) menjadi batas teknis; perubahan thread/header memerlukan uji tersendiri.

## 8. Audit tambahan yang ikut diselesaikan

- Tombol fullscreen, audio, menu, close, loading, retry, dan kembali ke akun mempunyai state yang jelas; tidak ada klik tertangkap lapisan transparan.
- Tidak ada input tertahan setelah dialog, tab browser, resize, reconnect, atau pergantian area.
- Nama NPC panjang, dialog panjang, tujuan misi, angka O2/bobot besar, dan teks Indonesia tidak keluar bingkai.
- Safe area, kontras, reduced-motion, mute, fokus keyboard, serta ukuran sentuh diperiksa pada hasil render nyata.
- Lifecycle koneksi event tidak berlipat setelah berulang masuk/keluar rumah atau mengganti UI.
- Pakaian/perlengkapan, sorting foreground, kaki di tanah/tangga, dan transisi air tetap benar setelah perubahan animasi/kamera.
- Temuan CodeQL terakhir `js/useless-assignment-to-local` pada `apps/api/test/integration.test.ts:750` merupakan assignment awal yang tertimpa. Rapikan saat menyentuh verifikasi terkait dan laporkan jumlah hasil sebenarnya; CI hijau bukan berarti laporan SARIF kosong.

## 9. Urutan kerja dan batas paket

1. **Paket 1:** baseline, shell fullscreen, kontrak ukuran/aspect, joystick bersama. Bukti: video window/fullscreen/orientasi dan multitouch tanpa gerak tersangkut.
2. **Paket 2:** komponen visual bersama, HUD adaptif, presenter percakapan desa/hutan. Bukti: tangkapan desktop/HP serta video reveal–skip–advance dan aksi dunia.
3. **Paket 3:** SmaraPedia/ransel/kuis/kedai yang belum memenuhi brief, dengan kontrak gameplay yang tersedia. Bukti: data nyata, fokus, pause, retry, dan progres tidak hilang.
4. **Paket 4:** pilot berjalan delapan arah, validasi kontak kaki, lalu perluasan pakaian/identitas dan anchor perlengkapan. Pilot aset dapat berjalan bersamaan dengan Paket 2 setelah skala kamera disepakati.
5. **Paket 5:** penyelesaian optimasi terukur, profil kualitas, matriks regresi dan kandidat staging. Perbaikan hitch yang jelas dari baseline boleh dilakukan lebih awal, tetapi tetap dicatat sebelum/sesudah.

Pemilik pekerjaan bila memakai beberapa agen: shell/input, HUD/dialog, aset/locomotion, dan profiling/integrasi. Tentukan kepemilikan file agar perubahan `Main.gd`, `GameHud.gd`, serta controller tidak saling menimpa. Penanggung jawab integrasi menjaga satu kontrak input, pause, dan viewport.

## 10. Bukti penerimaan dan rilis

| Lingkungan | Pemeriksaan minimum |
| --- | --- |
| Windows nyata | Chrome/Edge dan Firefox; 1080p, skala 100/150%, window/fullscreen; catat GPU serta hardware acceleration. |
| Samsung S23 nyata | Chrome dan Samsung Internet; landscape/portrait, masuk/keluar fullscreen, bilah browser, safe area, multitouch, Wi-Fi/jitter, sesi 15–20 menit. |
| Ukuran regresi | 667×375, 844×390, desktop 16:9 dan ultrawide; tambah ukuran efektif S23 yang terukur. |
| Dunia | Desa ramai, jembatan hutan, tangga/batu, rumah, kebun, hujan/malam, penyelaman/senter/fauna. |
| UI | Percakapan panjang, buku, ransel, kuis, kedai, resize saat modal terbuka, kehilangan fokus, keyboard/touch/gamepad. |
| Progres | Kedai → pulang → tidur, kalender 36 menit, pertumbuhan kebun, outfit/perlengkapan, reconnect dan idempotency transaksi. |

Tambahkan tes hanya pada kontrak penting: analog/dead zone/cancel, pause yang bertumpuk, fullscreen state, batas viewport, pemetaan arah/phase, dan transaksi yang berubah. Jalankan pemeriksaan API/Godot/browser yang relevan serta CI. Pengujian otomatis tidak menggantikan penilaian visual gait atau profil S23.

Simpan screenshot pembanding dengan kamera/lokasi sama, video jalan delapan arah di lantai grid, video UI/joystick, dan laporan performa sebelum/sesudah. Tulis browser, perangkat, profil kualitas, commit, serta batas hasil. Jangan menyebut paket selesai hanya karena build dan tes lulus.

Rilis staging dilakukan per paket yang dapat ditinjau, memakai build dari revisi yang sama dan rollback image sebelumnya. Verifikasi hash aset, alur login, data tersimpan, dan smoke test setelah deploy. Jangan mengubah data akun pengguna demi demo. Penerimaan akhir memerlukan bukti perangkat nyata; bila perangkat belum tersedia, statusnya tetap **belum diverifikasi pada perangkat tersebut**.

## 11. Catatan implementasi berjalan

Paket shell, kontrol, dan UI telah diuji lokal: halaman memenuhi viewport, Menu membuka fullscreen browser nyata, joystick analog mempertahankan pemilik sentuhan ketika jari lain menekan aksi, dan dialog membedakan reveal dari advance. SmaraPedia, tas dan atlas memakai data permainan serta tata letak yang menyesuaikan layar. Pilihan Auto/Ringan/Seimbang tersambung ke renderer; versi Ringan mempertahankan bayangan senter dan contact shadow sambil mengurangi bayangan matahari. UI tetap tajam pada anggaran render dunia 129.600 piksel.

Perubahan petak kebun tidak lagi membangun ulang area, air, atau NPC. Shoreline dicache dengan batas enam entri; air nonaktif serta presentasi 2D tersembunyi berhenti mengerjakan presentasi, tetapi fauna yang dipakai renderer aktif tetap bergerak. Diagnosis lengkap menjadi opt-in; pengukuran meliputi monitor engine, antrean jalur dan waktu respons API, bukan angka FPS perkiraan. Waktu respons API mencakup penantian klien dan tidak boleh disebut pengukuran jaringan murni.

Perbaikan kaki Ujang mencakup volume potongan paha/betis dan tekukan lutut. Empat identitas/tiga pakaian kini mempunyai 768 gambar berjalan dalam delapan arah asli dan 96 pose diam netral. Delapan baris belakang yang awalnya menyerong telah diganti dan diperiksa pada ukuran game. Laju jalan darat menjadi 100 piksel/detik dengan stride 64 yang sesuai rentang gerak telapak; laju lama 175 terlihat seperti lari kecil dan tetap diuji sebagai beban gerak cepat. Kecepatan berenang tidak berubah. Tabung, tas dan jala berupa geometri terpisah yang mengikuti arah tubuh. Aset dibuat dari sumber proyek sendiri dan artwork orisinal baru; tidak ada sprite galeri yang diimpor. Sumber, hash dan batas kualitas dicatat pada [asal aset](../assets/provenance.md).

Checkpoint lokal: 77 tes API dan 30 pemeriksaan Godot lulus; tujuh pemeriksaan host serta 15 pemeriksaan browser game lulus. Browser memeriksa kualitas pada renderer nyata dan jeda kalender server selama menu terbuka, membuka detail tujuan/atlas serta mempertahankan atlas saat rotasi. Bukti UI native mencakup landscape pendek dan portrait; font/target dihitung dalam piksel fisik. Empat pemeriksaan alur kedai–rumah–tidur lulus dengan dua tahap input dialog baru. Semua kombinasi pakaian/identitas kini mempunyai artwork delapan arah, tetapi detail kontak telapak yang dilukis masih dapat dipoles. Ini bukan pengukuran FPS Windows/S23 atau status CI revisi akhir. Status rilis mengikuti [status pengembangan](../development-status.md).
