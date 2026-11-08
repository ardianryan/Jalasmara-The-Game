# Rencana 02 — Misi Bu Darmi dan pemolesan gameplay

Tanggal: 9 November 2026. Status: rencana baru, belum diimplementasikan.

## 1. Keputusan dan sasaran

Pengguna sudah meninjau hasil pekerjaan air, audio, dan koridor dari Gemini. Anggap pekerjaan tersebut sebagai dasar yang diterima. Dokumen ini terpisah dari `gemini-water-and-cozy-world-handoff.md`; jangan membuka kembali pekerjaan air sebagai proyek utama. Jalankan regresi air/audio hanya jika perubahan gameplay menyentuh integrasinya.

Sasaran berikutnya: satu misi Bu Darmi yang utuh dan menarik selama sekitar **10–15 menit bermain aktif**, di dalam alur Fase 1 yang sudah ada. Durasi ini sasaran desain yang perlu diukur melalui permainan manusia, bukan alasan memasang timer, memperlambat karakter, atau mewajibkan pengumpulan berulang.

Pemain menerima masalah yang jelas, menyelidiki lingkungan, memperoleh pengetahuan melalui tindakan, mencari fragmen saat menyelam, menerapkan hasilnya di kedai, dan melihat perubahan kebun. Dunia yang sudah bergerak harus mendukung kegiatan tersebut.

## 2. Baseline dan hal yang dipertahankan

- Implementasi Gemini: commit `7e765ce`; dokumentasi penyelesaiannya: `ff1e37b`. Periksa HEAD aktual sebelum mengedit.
- Engine tetap Godot 4.7.2 Compatibility/Web single-threaded. Jangan mengganti engine.
- Renderer darat 3D dengan karakter billboard, kamera ortografis elevasi 35°, render 480 × 270 dan nearest filtering tetap dipertahankan.
- Manifest lantai/obstacle bersama, validasi server, dua jembatan, arus/buih/audio baru, serta transisi hub–hutan dipertahankan.
- Siklus kosmetik 24 jam tetap berlangsung 36 menit nyata. Jam visual tidak boleh membuat pemain kehilangan misi atau tidak dapat menemui NPC penting.
- Empat pilihan penampilan memiliki kemampuan yang sama. Semua harus bekerja dalam interaksi dan animasi baru.
- Cerita tetap Bandar Hujung, Kedai Waras, Bu Darmi, Mbah Wira, Beno dan PT Cakrawala Sintetis. Boss akhir Fase 1 tetap **Gajah Mina yang dipulihkan**, bukan dibunuh.
- Fase 2 dan jalur rencana tetap terkunci. Tidak menambahkan area besar, XP, pohon skill, multiplayer atau fitur admin baru pada milestone ini.

## 3. Temuan kode yang menjadi dasar rencana

Jangan membangun sistem paralel untuk fungsi yang sudah tersedia:

| Bagian | Implementasi saat rencana dibuat | Pekerjaan berikutnya |
| --- | --- | --- |
| Cerita Bu Darmi | `Main.gd::_npc_interact`, muncul pada siklus/hari cerita 2 | Hubungkan dialog dengan tindakan dan hasil misi |
| Progres | `Progress` memiliki `day`, `stage`, `missions`; `adventure` memiliki discoveries/puzzles/keyItems | Tentukan state misi minimum dan derivasi dari fakta server |
| Observasi hutan darat | `forest_canopy`, `forest_roots`, `forest_stream`, cache opsional | Pakai untuk pengamatan kontekstual, hindari koleksi wajib tanpa makna |
| Observasi bawah laut | `nitrogen`, `photosynthesis`, `osmosis` di `WORLD.landmarks` | Tetap menjadi penemuan bawah laut pada siklus 2 |
| Kedai hari 2 | `/api/kedai/start` sudah mensyaratkan ketiga penemuan bawah laut tersebut | Pertahankan kontrak, beri petunjuk sebelum pemain pulang tanpa persiapan |
| Penyajian | `/api/kedai/serve`, konsumsi fragmen dan hadiah sudah di server | Poles interaksi dan audit kesesuaian konsep |
| Presentasi kedai | Modal dengan daftar tombol fragmen di `Main.gd::_kedai_customer` | Ubah menjadi interaksi meja/racikan yang terasa bagian dari game |
| Penutup siklus | `/api/kedai/close-shift`, refresh profil dan perpindahan cerita tersedia | Hubungkan pemulihan kebun dengan fakta penyajian yang sah |

**Bedakan dua lokasi bernama Wringin:** Hutan Pesisir Wringin adalah daratan; Hutan Lamun Wringin adalah zona bawah laut. Koral Nitrogen, Lentera Fotosintesis dan Kerang Osmosis saat ini berada di bawah laut. Jangan memindahkannya ke hutan darat hanya karena teks HUD lama menyebut “Wringin”. Gunakan label lengkap pada jurnal dan petunjuk.

Ada ketidaksesuaian yang perlu diaudit: resep hari 2 `akar` membahas kekurangan oksigen/aerasi akar tetapi memakai `fragmentId: "klorofil"`. Jangan memperkuat kesan bahwa klorofil adalah jawaban untuk semua masalah tanaman. Benahi pemetaan konsep melalui konten versi jika diperlukan; jangan mengganti ID lama secara diam-diam atau merusak inventori/save yang sudah ada.

## 4. Alur misi yang dituju

Misi berjudul **“Kebun Apung yang Sekarat”**, tetap berada pada siklus cerita 2. Pemain lama yang sudah melewati siklus ini tidak dipaksa mengulang.

### A. Datang ke kebun — sekitar 1–2 menit

- Bu Darmi berdiri/beraktivitas pada titik lantai yang sah dekat kebun, tidak berada di atas tanaman atau air.
- Percakapan menjelaskan masalah konkret: kebun layu dan beberapa akar terus terendam; tawaran Kapsul Tani korporasi mahal.
- Tujuan singkat: “Periksa kebun Bu Darmi.” Pemain dapat bergerak dan mengamati sebelum membuka jurnal.
- Sediakan dua atau tiga objek observasi: daun, akar/media tanam, dan saluran air. Masing-masing mempunyai visual serta respons singkat yang berbeda.
- Jangan mendiagnosis penyebab hanya dari warna daun. Dialog mengajak memeriksa cahaya, nutrien, air dan aerasi.

### B. Penyelidikan daratan — sekitar 2–3 menit

- Pengamatan hutan darat memperlihatkan contoh yang relevan: perbedaan cahaya di bawah tajuk, kondisi akar, dan aliran air.
- Pakai landmark yang sudah ada. Pemain dapat memilih urutan; jangan memaksa berjalan bolak-balik hanya untuk tiga kotak checklist.
- Setidaknya satu pengamatan melibatkan aksi sederhana yang menunjukkan sebab–akibat: membuka penutup kecil agar aliran demonstrasi lewat, atau membandingkan dua contoh media tanam.
- Jika memakai alat peraga, beri konsekuensi visual langsung pada alat tersebut; jangan seolah-olah memindahkan nutrien atau membalik kondisi ekosistem nyata secara instan.
- Pengamatan darat membantu memahami masalah. Ketiga penemuan bawah laut yang sudah menjadi syarat kedai tetap berasal dari penyelaman.

### C. Persiapan dan penyelaman — sekitar 4–5 menit

- Jurnal memberi petunjuk lokasi secara geografis: dermaga penyelaman → zona lamun → titik observasi yang belum ditemukan.
- Sebelum menyelam, pemain bisa melihat kecukupan oksigen/kapasitas dan kebutuhan fragmen. Jangan mewajibkan upgrade baru yang belum mampu dibeli pada siklus 2.
- Menemukan biota dan menjala tetap merupakan kegiatan utama. Kuis tidak mengambil alih setiap tangkapan biasa.
- Observasi `nitrogen`, `photosynthesis`, `osmosis` memberikan penjelasan pendek yang terhubung dengan masalah kebun.
- Jika kekurangan oksigen, tas penuh, atau gagal menyelam, berikan rute pemulihan yang jelas. Penemuan permanen yang sudah sah tidak hilang hanya karena tangkapan sementara berkurang.
- Jangan menjamin semua bahan muncul secara acak tanpa batas. Pastikan sumber fragmen yang diperlukan tersedia dan dapat dicapai pada level alat yang wajar.

### D. Meracik dan menjelaskan — sekitar 2–3 menit

- Kedai menampilkan Bu Darmi dan meja racikan dalam konteks scene, dengan panel ringkas jika diperlukan untuk memilih bahan.
- Pemain mencocokkan informasi yang dikumpulkan dengan masalah, lalu memilih fragmen/racikan yang sesuai.
- Tetap gunakan endpoint penyajian yang sudah ada. Klien tidak boleh menetapkan hadiah, jumlah konsumsi, atau penyelesaian misi.
- Pilihan keliru memberi penjelasan yang membantu mencoba lagi. Jangan memotong koin/stok baru atau menghukum pemain dua kali tanpa aturan server yang jelas.
- Tampilkan aksi meracik dan menyerahkan seduhan, diikuti penjelasan praktis: memperbaiki aerasi, mengatur cahaya/air, dan menilai kebutuhan unsur hara sesuai temuan.
- Seduhan memulihkan pemahaman warga; seduhan bukan cairan ajaib yang langsung menyembuhkan seluruh tanaman.

### E. Hasil yang dapat dikunjungi kembali — sekitar 1–2 menit

- Setelah penyajian yang sah, kebun memasuki tahap **perawatan dimulai**: aliran diperbaiki, Bu Darmi melakukan perawatan, dan dialog berubah.
- Pertumbuhan/pemulihan lebih lanjut ditampilkan pada kemajuan hari cerita berikutnya. Jangan menggantungkan progres pada menunggu jam kosmetik selama puluhan menit.
- Bentuk perubahan harus jelas tetapi wajar: posisi saluran, media lebih terawat, tanaman baru/tunas pada waktu yang tepat, dan warga mengingat kembali cara merawat.
- Keadaan kebun diturunkan dari progres akun yang tersimpan di server, sehingga tetap terlihat setelah refresh atau login perangkat lain.
- Penutup memberi kaitan singkat menuju pencemaran air pada siklus berikutnya, tanpa langsung memulai boss atau membuka Fase 2.

## 5. Progres dan integrasi server

Sebelum mengedit, tulis tabel transisi dan tentukan fakta yang sudah tersedia. Utamakan derivasi daripada menyimpan banyak boolean yang dapat saling bertentangan.

| State konseptual | Bukti otoritatif | Perilaku |
| --- | --- | --- |
| Belum tersedia | Hari cerita belum 2 | Percakapan biasa, tidak memulai reward misi |
| Masalah diterima | Interaksi sah dengan Bu Darmi pada siklus 2 | Membuka tujuan pemeriksaan |
| Kebun diperiksa | Observasi kebun yang divalidasi server | Memperjelas petunjuk penyelidikan |
| Pengetahuan terkumpul | Discoveries yang sudah tersimpan | Menampilkan apa yang sudah/belum diketahui |
| Siap meracik | Penemuan wajib lengkap, stok sah dan stage sesuai | Kedai mengizinkan penyajian menurut kontrak |
| Perawatan dimulai | Penyajian resep Bu Darmi berhasil di server | Dialog dan visual kebun berubah |
| Pulih bertahap | Perawatan sah + kemajuan hari cerita | Visual lanjutan dan penutup misi |

- Nama state di atas adalah rancangan, bukan field/API yang sudah tersedia. Pilih representasi minimum setelah audit kode.
- Jika dibutuhkan interaksi NPC/kebun baru, validasi ID, area, jarak dari posisi server, hari cerita, status akun dan versi. Jangan mempercayai koordinat atau `completed: true` dari klien.
- Catat penyelesaian dan reward bersama dalam transaksi, dengan idempotency sesuai pola yang sudah ada. Mengulang request tidak menggandakan koin, item atau konsumsi.
- Pertahankan snapshot konten sesi lama. Perubahan resep/fragmen melalui draft → validasi → publish; jangan overwrite langsung konten published.
- Jangan seed ulang database staging untuk memasukkan misi. Gunakan migrasi konten yang ditinjau dan kompatibel.
- Migrasi save mempertahankan akun, progres, item dan statistik. Untuk pemain yang sudah melewati siklus 2, gunakan bukti historis yang tersedia; bila bukti tidak lengkap, tetapkan fallback kompatibel yang tidak memberi reward kedua.
- Admin yang mereset/mengubah progres tetap membatalkan state game lama. Respons terlambat dari sebelum pembatalan tidak boleh menimpa keadaan baru.
- Jangan membuat story-clock tambahan. `progress.day/stage` tetap mengatur alur; jam kosmetik hanya memengaruhi suasana dan kegiatan NPC.

## 6. Respons karakter, alat dan interaksi

Tujuan: setiap aksi memiliki awal, respons, hasil dan kesempatan melanjutkan permainan.

1. Gunakan satu resolver target interaksi terdekat. Prompt hanya muncul untuk objek yang terjangkau, berada di area yang tepat, dan tidak terhalang penghalang yang relevan.
2. Prioritas target deterministik. NPC/objek misi yang sedang dihadapi tidak boleh kalah oleh tanaman dekoratif di belakangnya.
3. Pertahankan keyboard dan kontrol sentuh yang sudah ada. Tombol Aksi berubah label menurut target; jangan menambah banyak tombol baru untuk setiap observasi.
4. Berjalan berhenti ketika badan tertahan; animasi kaki, debu dan suara tidak terus menggambarkan kemajuan ketika karakter diam di collider.
5. Tangga tetap membaca konektor dan elevasi sebenarnya; jangan menambahkan animasi vertikal yang membuat kaki lepas dari lantai.
6. Alat jala mengikuti arah hadap dan mode darat/air. Efek suara/percikan muncul pada saat aksi, bukan setiap frame tombol ditahan.
7. Bedakan input lokal yang langsung mendapat respons dengan hasil jaringan. Tampilkan status menunggu secara ringkas dan cegah submit ganda, tanpa menampilkan hadiah seolah-olah sudah diterima.
8. Tangani koneksi lambat, error server dan pembatalan admin. Pemain dapat mencoba lagi tanpa modal buntu atau inventori yang tampak terpotong dua kali.
9. Mode pengurangan gerak mengurangi camera shake/bob/partikel tambahan. Jangan menggoyangkan kamera pada setiap observasi atau langkah.
10. Uji seluruh empat penampilan: pivot kaki, arah, posisi alat, layering tajuk serta keterbacaan saat bergerak.

## 7. NPC dan dunia yang merespons

Mulai dari tiga NPC yang terlibat: Bu Darmi, Mbah Wira dan Beno. Tidak perlu sistem simulasi penduduk penuh.

- Bu Darmi: memeriksa tanaman sebelum misi, melakukan perawatan setelah penyajian sah, dialog berbeda setelah pemulihan.
- Mbah Wira: menyiapkan alat racik dan memberi petunjuk yang relevan dengan langkah yang belum selesai.
- Beno: bekerja pada bangku bengkel; petunjuk alat diberikan bila pemain kekurangan kapasitas/oksigen, tanpa memaksa pembelian.
- Beri animasi idle/kerja singkat dan perpindahan antaranchor yang semuanya walkable. Jangan melakukan lerp lurus menembus rumah, kebun, jembatan atau air.
- Jika NPC diperlukan untuk misi, selalu ada cara menemuinya atau memanggil interaksinya pada lokasi yang dapat dijangkau. Jadwal siang–malam tidak boleh mengunci misi.
- NPC tidak boleh menghalangi satu-satunya jalan secara permanen. Pilih blocking/nonblocking yang konsisten dengan tampilannya.
- Aktivitas dan dialog mengikuti state misi; jam kosmetik hanya memilih variasi kegiatan yang aman.

## 8. Visual, HUD dan pembelajaran

### Koridor yang dipoles

Batasi pemolesan pada kebun Bu Darmi, jalur ke hutan, dermaga penyelaman, titik observasi relevan dan meja kedai. Jangan membangun ulang seluruh map lagi.

- Pertahankan skala manusia terhadap pintu, tangga, meja, pagar, pohon dan lebar jalan.
- Pakai geometri/layer yang benar: tajuk/atap dapat menutupi pemain, batang/dinding memiliki footprint, dan prop tidak membawa persegi latar tanah.
- Detail dermaga serta kebun membentuk kelompok yang masuk akal, bukan taburan dekorasi acak.
- Cahaya rumah/tungku hangat dan lokal; warna malam tetap terbaca. Pertahankan parallax/perspektif atmosfer dan sistem lingkungan yang baru diterima.
- Reuse aset yang sudah ada. Jika memakai aset library, periksa lisensi dan catat asal. Moodboard berhak cipta tetap privat dan tidak ikut build/repository.

### HUD dan jurnal

- Satu tujuan pendek saat ini, misalnya “Periksa akar di kebun Bu Darmi.” Rincian opsional berada di jurnal.
- Jurnal memisahkan **temuan**, **dugaan**, dan **langkah berikutnya**. Jangan menyebut dugaan sebagai fakta sebelum ada bukti.
- Atlas geografis menunjukkan lokasi sebenarnya dan status akses; jangan menggantinya dengan mindmap atau teleport bebas.
- Tidak ada panah besar terus-menerus atau modal pembelajaran setiap beberapa langkah. Petunjuk tambahan dapat dibuka saat dibutuhkan.
- Panel racikan memakai ukuran teks dan kolom yang stabil. Nama fragmen tidak terbungkus satu huruf per baris seperti bug tas terdahulu.
- Modal dapat ditutup dengan kontrol yang jelas; input gerak tidak bocor ketika memilih bahan. Penghentian bahaya/oksigen saat membaca tetap mengikuti kontrak server.

### Ketepatan materi

- Daun kuning memiliki beberapa kemungkinan penyebab; jangan menyederhanakannya menjadi “pasti kekurangan nitrogen”.
- Akar memerlukan oksigen untuk respirasi; hubungan air, aerasi dan media tidak dijelaskan sebagai sekadar “tambahkan klorofil”.
- Fotosintesis memerlukan energi cahaya serta bahan yang sesuai; cahaya bukan nutrien yang dapat dituangkan sebagai pupuk.
- Osmosis tidak dijelaskan sebagai air yang selalu bergerak menuju tempat “paling kering” tanpa konteks membran/potensial air.
- Tindakan pada tumbuhan/ekosistem merupakan simulasi edukasi, bukan resep dosis bahan kimia dunia nyata.
- Sertakan rujukan pada catatan pengetahuan dan periksa materi saat menulis. Cari sumber primer/pendidikan yang berwenang untuk perubahan ilmiah; dokumen rencana ini tidak menggantikan verifikasi sumber.

## 9. Urutan implementasi dan keluaran

### Tahap 1 — Audit alur dan kontrak misi

Keluaran: tabel transisi final, daftar fakta server yang dipakai, audit pemetaan resep, daftar migrasi konten/save dan storyboard singkat. Pastikan alur hari 1 → hari 2 → hari 3 tetap dapat diselesaikan.

### Tahap 2 — Satu alur fungsional dari awal sampai hasil

Bangun interaksi kebun, progres misi, petunjuk, hubungan penemuan yang sudah ada, penyajian dan perubahan kebun. Gunakan aset yang tersedia dahulu. Hasil harus bisa dimainkan sebelum menambah dekorasi.

### Tahap 3 — Respons karakter dan presentasi kedai

Poles resolver target, prompt, input keyboard/sentuh, animasi/foley dan status jaringan. Buat racikan terasa dilakukan di scene sambil mempertahankan transaksi server.

### Tahap 4 — NPC, visual koridor dan keseimbangan

Tambahkan kegiatan NPC, detail tempat yang relevan dan perubahan kebun. Ukur waktu bermain aktif, kecukupan bahan, perjalanan serta pemahaman tujuan. Pangkas bagian repetitif yang tidak menghasilkan keputusan/penemuan.

### Tahap 5 — Regresi, penerimaan dan staging

Jalankan pemeriksaan di bawah, review video, commit/push, pipeline, deployment dan cleanup. Laporkan yang belum teruji tanpa menandainya selesai.

## 10. Pembagian agen paralel

Jika tersedia, gunakan integrator dan tiga agen dengan kepemilikan file yang disepakati:

| Peran | Tanggung jawab |
| --- | --- |
| Integrator | Storyboard, kontrak state, review akhir, integrasi, commit dan deploy |
| Agen misi/server | State, validasi interaksi, transaksi, migrasi save/konten, tes API |
| Agen gameplay | Input, resolver target, animasi, prompt, NPC dan presentasi kedai |
| Agen verifikasi/visual | Regresi, jalur, screenshot/video, pengukuran durasi/performa, review visual |

`Main.gd` dipakai banyak sistem; tentukan satu pemilik atau ekstrak modul kecil sebelum agen mengedit bersamaan. Jangan membiarkan beberapa agen mengubah AudioManager, manifest atau file shared yang sama tanpa koordinasi. Integrator tunggal menangani deployment.

## 11. Pengujian dan penerimaan

### Tes server yang bermakna

- Misi tidak dapat dimulai pada tahap cerita yang salah atau dari lokasi yang terlalu jauh.
- Event observasi, konsumsi fragmen, penyajian dan reward hanya berlaku sekali sesuai aturan.
- Pilihan salah tidak memberi reward/kemajuan; respons menjelaskan masalah tanpa merusak inventori.
- Retry dengan idempotency yang sama tidak menggandakan perubahan. Konflik versi tidak menimpa progres baru.
- Akun lama dan akun yang sudah melewati siklus 2 tetap dapat melanjutkan. Admin reset/bypass tidak menerima hasil sesi lama.
- Kedai hari 2 masih menolak pembukaan tanpa ketiga penemuan bawah laut yang sah.
- Refresh dan login perangkat lain mempertahankan state misi serta keadaan kebun.
- Clock visual, efek NPC dan animasi tidak dapat memberikan hadiah atau membuka zona.

### Uji permainan sebenarnya

1. Mulai dari akun uji pada akhir siklus 1; masuk siklus 2 dengan alur yang sah.
2. Terima masalah, periksa kebun dan jelajahi hutan darat dengan urutan pengamatan berbeda.
3. Menyelam, temukan pengetahuan dan tangkap fragmen yang diperlukan pada kemampuan yang wajar.
4. Coba pulang dengan satu penemuan/stok yang kurang; petunjuk pemulihan harus jelas dan tidak softlock.
5. Sajikan pilihan salah, lalu benar; cek hasil dan inventori server.
6. Kunjungi kebun, refresh dan lanjutkan hari cerita; lihat perubahan yang sesuai.
7. Coba koneksi lambat, request ulang, reload saat membaca dan pembatalan admin pada akun khusus pengujian.
8. Uji empat penampilan dan kontrol sentuh lanskap; karakter tidak mengambang atau menembus objek.

Lakukan satu sesi manusia tanpa petunjuk pengembang. Catat kapan pemain bingung, bagian yang diulang, bahan yang sulit ditemukan dan lama bermain aktif. Jika durasi melewati 15 menit karena kebingungan atau jalan kosong, perbaiki desain; jangan hanya mengubah angka target.

### Bukti visual/performa

- Video alur lengkap atau rangkaian cuplikan yang menampilkan interaksi, penyelidikan, racikan dan hasil kebun.
- Tangkapan sebelum/perawatan dimulai/pemulihan pada posisi kamera pembanding yang sama.
- Bukti layering, tangga dan batas air pada jalur misi aktual.
- BGM, air, napas dan langkah tetap benar setelah modal, reload dan perpindahan area.
- Catat ukuran build, startup dan frame time sebelum/sesudah. Jangan menambah banyak viewport/partikel/lampu per NPC.
- Tes kode dan snapshot tidak cukup untuk menyatakan misi menyenangkan atau materi mudah dipahami.
- Bedakan emulasi sentuh dari perangkat Android/iOS fisik; jangan mengklaim perangkat yang belum diuji.

Perintah dasar: `npm run typecheck`, `npm test`, `npm run check:world`, `npm run build`. Tambahkan tes misi yang relevan tanpa menulis tes yang hanya meniru implementasi. Setelah pemeriksaan lulus, ulangi hanya bila ada perubahan atau kekhawatiran baru yang relevan.

## 12. Repository, deployment dan pekerjaan paralel

- Gunakan repository yang sudah ada pada remote `gitlab` dan `github`. CI/build/CodeQL tetap di GitLab; GitHub Actions tetap nonaktif, laporan GitHub tetap diperbarui oleh alur yang tersedia.
- Periksa `git status` dan diff sebelum mulai. Saat dokumen ini dibuat pekerjaan lisensi (`LICENSE`, `THIRD_PARTY_LICENSES.md`, package manifests, credits, provenance) serta perubahan lokal dokumen handoff lama masih berada di working tree. Jangan menimpa atau ikut stage tanpa peninjauan.
- Stage eksplisit perubahan milestone ini. Jangan `git add .`, reset/clean massal, seed ulang database produksi atau mereset akun owner.
- Build kandidat dari sumber yang sesuai commit. Jika working tree campuran, pakai snapshot terisolasi dan overlay yang ditinjau.
- Deploy hanya aplikasi pada `ssh dev-jalasmara`, `/opt/jalasmara`, upstream `10.1.0.8:3000`. Domain staging tetap `staging-jalasmara.ardianryan.com`.
- Jangan mengubah `moodle-server`/aaPanel/reverse proxy/sertifikat.
- Sebelum deploy simpan image rollback dan backup. Jalankan build app, lalu update app tanpa menghapus volume Mongo/Redis.
- Verifikasi health, checksum paket, pipeline SHA final dan permainan melalui HTTPS. Gunakan akun uji terpisah, jangan password owner.
- Setelah tes, hapus hanya data/sesi pemain uji, buat backup dan uji restore ke database pemeriksaan terpisah dengan script yang tersedia.

## 13. Definisi selesai

- [ ] Misi Bu Darmi dapat diselesaikan melalui eksplorasi, pengamatan, penyelaman dan penerapan di kedai.
- [ ] Pemain mengetahui tujuan berikutnya tanpa membaca instruksi pengembang.
- [ ] Materi dan pemetaan fragmen/resep konsisten secara ilmiah.
- [ ] Hasil kebun terlihat, tersimpan, dan sesuai kemajuan hari cerita.
- [ ] Tidak ada reward/konsumsi ganda, softlock bahan, atau rusaknya save lama.
- [ ] Animasi, langkah, alat, prompt dan kontrol sentuh bekerja pada empat penampilan.
- [ ] NPC melakukan aktivitas yang relevan tanpa menembus medan atau mengunci misi karena jam.
- [ ] Sesi manusia mengukur sasaran 10–15 menit bermain aktif dan mencatat kebingungan.
- [ ] Air/audio/pencahayaan yang telah diterima tidak mengalami regresi.
- [ ] Tes/build/CI lulus untuk SHA final; staging terverifikasi, akun uji dibersihkan dan backup diuji restore.
- [ ] Keterbatasan serta perangkat yang belum diuji dilaporkan jujur.

## Instruksi untuk Gemini/agen pelaksana

Kerjakan dokumen ini sebagai milestone baru. Tinjauan pengguna terhadap pekerjaan air sudah selesai; mulai dari audit alur misi dan kontrak server pada Tahap 1. Jangan mengulang proyek air atau memperluas seluruh peta. Lanjutkan sampai satu misi Bu Darmi dapat dimainkan dari masalah hingga hasil kebun, kemudian buktikan melalui pengujian dan staging sesuai batas di atas.
