# PRD Jalasmara: dunia, kontrol dan presentasi

Pemilik arah produk: pengguna proyek. Dokumen ini merangkum keputusan yang sudah diberikan, bukan penawaran fitur baru. Status implementasi terbaru selalu pada [handoff](agent-handoff.md) dan [laporan paket](reviews/06a-delivery.md); kebutuhan di bawah tidak otomatis berarti fitur sudah selesai.

## Pengalaman utama

Nala datang ke Kota Apung Bandar Hujung, menjelajah desa/hutan/gua daratan, menyelam di Palung Smara, mengumpulkan fragmen pengetahuan dan melayani Kedai Waras. Pembelajaran hadir melalui penemuan dan kuis kontekstual dengan bacaan yang nyaman. Eksplorasi, siklus kedai, penyimpanan progres dan akses warga harus berjalan sebelum perluasan dekorasi/interior.

## Kebutuhan dan penerimaan

| Area | Kebutuhan | Bukti minimum |
| --- | --- | --- |
| Daratan | Mesh/terrain 3D bertingkat; pandangan 3/4 dari kiri menghadap kanan, parallax dan atmosfer; tetap piksel tajam | Kamera bergerak pada hub dan hutan; aktor, input, penanda dan permukaan konsisten. Render kamera fixture saja belum menerapkan kamera gameplay. |
| Bangunan | Griya di dermaga sejajar sumbu dek, kolong terbaca, tiang berfondasi; bangunan tampil menyudut sesuai kamera | Bandingkan sumbu rumah/dek dalam ruang dunia dan gambar; atap, pintu, collision, serambi, akses dan rute cocok. Jangan memakai footprint yang sudah diskew sebagai pengganti orientasi ruang. |
| Desa hidup | Warga bekerja, memancing/merawat kebun/menenun sesuai waktu, berhenti berbicara, melanjutkan, berteduh dan pulang | Seluruh13rutinitas pada cuaca/waktu normal dan reduced motion; jalur sah, kepala/badan di bawah atap, tanpa teleport atau layanan hilang. |
| Perluasan desa | Rumah pribadi lurah, rumah warga yang fungsional, direktur tersendiri di kontainer/RV, lima Laskar Kognisi | NPC/ID/peran terpisah, dialog dan tujuan dapat dicapai, manifest/migrasi/save diuji. Raka tidak diganti menjadi direktur. |
| Hutan | Jalan/jembatan/tangga menyatu dengan terrain; pemain terlihat di balik tajuk | Masuk/keluar kedua jembatan dengan input aktual, restore reveal, tidak menembus pohon atau tepian; siang/malam/hujan. |
| Laut | Batu bertumpu di kiri/kanan dengan celah renang, volume dan kedalaman; arus, riak, buih dan audio gelombang | Gambar bergerak membuktikan tumpuan dan parallax, jalur renang/capture tidak terganggu; cahaya/senter dan kedalaman berbeda. Daftar SFX tidak membuktikan air visual bergerak. |
| Nala/perlengkapan | Pakaian harian, explorer dan diving; bilik dermaga mengubah pakaian; tabung/tas/senjata modular | Idle/walk/turn semua arah, kontak kaki nyata, alat tetap pada tangan benar, item dapat dilepas tanpa duplikat tubuh. Mirror tidak membuktikan arah asli lengkap. |
| HUD/dialog | Badge, ikon dan bingkai piksel bahari, informasi ringkas, portrait/dialog ekspresif, bacaan kuis sans yang tajam | Uji HUD darat/selam/kedai malam tanpa menutup area aksi; keyboard, sentuh dan teks panjang; menu/kuis menjeda bahaya, air/idle tetap hidup. |
| Layar/kontrol | Game memenuhi viewport, tombol fullscreen, safe area, joystick bulat analog | Landscape/portrait desktop/mobile, resize, keluar fullscreen, modal, gerak diagonal dan multitouch tidak macet. |
| Loading/website | Gambar bertema dengan parallax yang dapat dikurangi, persentase unduhan asli, tahap persiapan terpisah, retry/error jelas | Muat pertama/cache/gagal, byte asli, tidak mengarang persentase inisialisasi; akun/admin mempunyai loading/empty/error/dirty protection. |
| Waktu | 24 jam game = 36 menit aktif nyata; server memegang kalender | Transisi cuaca/waktu, pause, lease/reload, tidur dan tanaman diuji; cerita tidak dilompati oleh jam kosmetik. |
| Performa | Windows/mobile tetap nyaman tanpa menghilangkan volume, atmosfer dan identitas piksel | Baseline/kandidat dengan perangkat dan profil sama; batas kualitas dan resource nyata. Target ringan S23: 30 FPS stabil/p95≤50 ms; belum hasil yang boleh diklaim tanpa perangkat. |
| Persistensi | Progres, inventori, ekonomi dan posisi tidak rusak oleh perubahan visual/layout | Migrasi posisi lama ke lantai terhubung, API round-trip, reload dan retry/idempotency; fixture terpisah, tidak reset akun. |
| Penyimpanan pengembangan | Cache/build tidak terpakai dibersihkan pada PC dan VPS; build aktif serta satu rollback dipertahankan | Manifest penghapusan dan ruang bebas aktual, health/hash aplikasi; source, bukti, konfigurasi, backup serta volume data tetap utuh. |

## Prioritas pengembangan

Checkpoint10November04.10WIB: [host e171734/imagea9](reviews/overnight-admin-host-release.md) aktif dengan PCK73d45630 tetap. Lazy Admin lulus9/9 browser compiled dan6/6 smoke publik khusus host; pemain tidak memuat chunk Admin. Bukti smoke dunia6/6 pada host203 tetap terpisah, dengan gamebytes sama. [Jahe empat hari](reviews/overnight-jahe-four-day-gate.md)10/10 actualbrowser dan [bilik pakaian](reviews/overnight-wardrobe-gear-audit.md)4/4 actualbrowser selesai; izin/benih adalah setup dan gear yang tertutup atap bukan penerimaan visual penuh. Siklus induk→panen8/8 terdahulu tetap. Full63world/120API/CodeQL CI sebelumnya lulus, build CI terakhir gagal sebelum memperoleh runner; [bukti](reviews/overnight-ci-build-runner.md). Nala lower-body tetapOFF karena terrain ramp/upper-arm/native sequence belum selesai; prototipe satu arah delapanframe baru authoring/CPU, belum runtime. Pengguna siap membantu Windows/S23 fisik nanti. Status ini tidak mengubah kriteria penerimaan tabel.

Arahan aktif pengguna: kerjakan seluruh [delapan jalur overnight](reviews/overnight-eight-workstreams.md) melalui tiga subagent dan satu integrator, bukan berhenti setelah rencana. Kandidat runtime tetap terpisah dari staging sampai tes gabungan dan browser diterima. Pengguna bersedia membantu Windows/S23 fisik setelah recorder siap; angka target performa di atas belum hasil pengukuran perangkat tersebut.

Keputusan operasional terbaru: migrasi GitLab CE dibatalkan pengguna. GitLab.com tetap menjalankan CI, GitHub menjadi mirror; pekerjaan auth/runner CE dihentikan. Prioritas adalah rilis finishing yang sudah diterima lokal dan penutupan startup publik, lalu sisa gerak/rig sebelum perluasan desa.

Arahan terbaru memajukan [paket rumah/gapura06-B2](plans/06b2-keselarasan-rumah-dan-gapura.md): rumah warga mengikuti sistem modular3D Griya; gapura dan jalan memakai orientasi/bukaan/collider yang konsisten. Kerjakan penerimaan lokalnya secara terisolasi, sambil mempertahankan blocker startup publik yang belum selesai.

Koreksi berikutnya dalam paket yang sama: tepi pulau dan kenaikan terrain berupa batu alami yang menyambung; hutan sudah terlihat dari desa meski perpindahan tetap loading; kaki naik/turun mengikuti pijakan tangga sebenarnya. Warna mengikuti gambar login/loading yang cerah dengan ambience sejuk dan cahaya hangat. Tekstur bintik yang membuat rumah/karakter/terrain tampak burik bukan target finishing; perbaiki sumber noise dan palet, bukan sekadar memperbesar saturasi layar.

1. Tutup penerimaan publik paket aktif06-B: diagnosis startupHTTP2 dan targetcanopyharness setelah kamera kiri. Runtime46world/82API sudah lolos, tetapi hasil HTTP1 diagnostik bukan bukti browser default. Lihat [diagnosis startup](reviews/06p-public-startup-transport.md).
2. Pertahankan kamera kiri yang sudah diterapkan bersama invers input/proyeksi; lanjutkan alignment rumah selain Griya melalui kandidat layout10 dan native penerimaan. Jangan mengubah rotasi kamera sendirian.
3. Matangkan pilot Ujang, Darmi dan Sari sebelum menggandakan rig ke seluruh warga. Pertahankan bukti visual walking/turn, bukan angka socket saja.
4. Lanjut 06-C: rumah lurah, direktur dengan tempat tinggal terpisah dan Laskar Kognisi beserta fungsi/rutenya.
5. Perluasan tanaman, keramba dan interior mengikuti kontrak server 06-D. Pengujian perangkat 06-P tetap terbuka sampai bukti fisik tersedia.

Urutan rinci dan checklist pada [Rencana 06](plans/06-finishing-dunia-npc-dan-perluasan-desa.md), [pilot bangunan/kamera](plans/06b1a-rumah-panggung-dan-kamera.md), serta [backlog authoring](nextgen-world-authoring.md).

## Referensi, tool dan lisensi

Godot tetap runtime; referensi Phaser diterjemahkan ke arsitektur yang ada. Noxe dapat diport secara terbatas ke Godot dengan MIT/pin; PixelDoll dipertimbangkan untuk authoring berlapis, bukan klaim integrasi aktif. Polyfork/library existing didahulukan, raster original dibuat bila perlu. Setiap aset/tool yang dipakai dicatat pada [integrasi referensi](reference-integrations.md), laporan paket dan [lisensi](../THIRD_PARTY_LICENSES.md). WorldKit boleh bernama milik proyek dengan tetap menyertakan atribusi kode upstream.

Tidak termasuk asumsi otomatis: migrasi ke Phaser/Three.js, semua interior langsung playable, exporter GLB Noxe tersedia, semua delapan arah asli selesai, atau perf HP terjamin. Keputusan itu memerlukan implementasi dan bukti tersendiri.

Permintaan [Fish Gen](world/fish-gen-reference.md) sudah dilanjutkan menjadi [pilot overnight](reviews/overnight-fishgen-pilot.md): satu atlas asli dengan renang/putaran dan adapter tiga ikan dekoratif, terpisah dari sepuluh spesies gameplay. Reproduksi, animasi/kontak serta native render lulus; adapter telah masuk ekspor593/PCK1315 pada rilis798. Lisensi MIT, izin hasil dan provenance disertakan. Pilot ini bukan generator terrain/air dan tidak mengubah aturan tangkapan atau ekonomi.
