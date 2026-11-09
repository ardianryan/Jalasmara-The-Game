# Pemeriksaan hasil Rencana 04

Tanggal: 9 November 2026. Pemeriksaan dilakukan oleh agen integrasi pada implementasi Godot dan shell React. Bukti lokal berada di `artifacts/` dan `.runtime/`, yang tidak dimasukkan ke paket game. Status CI dan rilis mengikuti revisi sumber serta artefak rilis, bukan jumlah tes pada dokumen ini saja.

Catatan penerimaan visual: pengguna menolak tampilan HUD dasar setelah pemeriksaan fungsional di bawah. Artwork Bahari kemudian dibuat dan dipasang; pengguna juga meminta ukurannya dipadatkan agar tidak menutupi gameplay malam. Laporan dasar ini mempertahankan bukti fungsional historis, bukan persetujuan visual terhadap putaran artwork dan loading yang sedang diintegrasikan. Tinjauan susulan harus memakai capture dan revisi terbaru.

Perubahan mencakup viewport/fullscreen, joystick analog, HUD dan dialog kayu–kuningan, SmaraPedia/tas/atlas, pilihan kualitas, serta animasi darat empat identitas dan tiga pakaian. Laju jalan menjadi 100 piksel/detik dengan stride 64; berenang tetap 160. Alasan perubahan laju ialah rekaman pada 175 memperlihatkan langkah terlalu cepat, sedangkan memperpanjang stride tanpa mengubah gambar membuat kaki meluncur.

## Bukti fungsional

| Pemeriksaan | Hasil lokal dan bukti |
| --- | --- |
| API | 77 tes lulus dalam `.runtime/plan04-api-final.log`; termasuk kalender, rumah, kebun, dan transaksi. |
| Dunia | 30 pemeriksaan lulus dalam `.runtime/plan04-world-final-all.log`; UI terakhir diperiksa ulang setelah pemadatan portrait dan pembesaran nama pembicara. Pelaksana: `npm run check:world`. |
| Artwork | 768 frame berjalan, 96 pose diam, hash sumber/hasil, tubuh tersambung dan batas sel diperiksa oleh `tools/player-gait/test_eightway.py`. Sebelas atlas tambahan dibangun ulang byte-identik dari sumber terlacak. |
| Gerak | Rekaman native `artifacts/godot/player-batch/locomotion-all12-32-100-175.mp4`; 175 adalah beban uji, bukan laju jalan normal. Uji collision menjalankan pengendali asli sampai rumah solid dan memeriksa fase/suara berhenti. |
| Perlengkapan | Render dunia explorer/diving delapan arah di `artifacts/godot/player-outfit-world/`; tabung terlihat di punggung saat menghadap utara dan tertutup badan dari depan. |
| Shell | Tujuh pemeriksaan host pada desktop, landscape dan portrait: fullscreen, fokus, preferensi kualitas dan penyimpanan diblokir. Engine pada tes host berupa fixture. |
| Browser game | 15 pemeriksaan lokal pada engine Web asli di `artifacts/godot/plan04/results.json`: tas/jurnal/atlas/tujuan, rotasi atlas, multitouch, jeda kalender server, penolakan pesan palsu, kualitas renderer dan fullscreen. |
| Sentuh | Tujuh pemeriksaan pada `artifacts/godot/touch-results.json`: joystick analog, dead zone/release, masuk laut, berenang, menjala dan rotasi penyelaman. `touch-dive-portrait.png` memperlihatkan penyelam serta kontrol utuh; O2 berada di atas joystick dan petunjuk rotasi hilang setelah game siap. |
| Putaran harian | Empat pemeriksaan kedai–rumah–tidur lulus tanpa error dalam `.runtime/plan04-night-home.log`; input dialog pertama reveal, kedua advance. |
| Tampilan | Komponen native pada 960×540, 667×375 dan 390×844; modal lama juga diuji pada portrait. Latar capture komponen adalah screenshot proyek, bukan bukti simulasi dunia hidup. |

## Hard Gate

- PASS R-02: teks UI baru memakai kalimat biasa; judul buku/dialog dan label kontrol tidak memakai em dash sebagai pemisah kalimat.
- PASS R-03: batas panel, pembungkusan dan scroll diperiksa pada tiga ukuran; kuis portrait satu kolom, atlas tidak lagi mempunyai minimum lebar tetap.
- PASS R-17/R-18/R-38: angka koin, tas, koleksi dan misi berasal dari state permainan. Warga adalah tokoh cerita, bukan testimoni atau profil pelanggan nyata.
- PASS R-23: pembuatan artwork mengikuti izin pengguna. Sumber asli proyek, hash, lisensi alat dan atribusi dicatat; sprite galeri komersial tidak diimpor.
- PASS R-24/R-26: Menu, fullscreen, kualitas, akun, HUD, buku, tas dan atlas terhubung ke tindakan nyata; kontrol utama diuji melalui browser atau event input engine.
- PASS R-25: pasangan tinta/kertas 10,58:1 dan teks dialog/kayu 12,46:1. Alas gelap menjaga teks aksi/cuaca/peringatan; rincian pengukuran ada pada [tinjauan UI](plan04-ui-review.md).
- PASS R-27/R-28: loading lambat, fullscreen ditolak, penyimpanan preferensi diblokir, tas kosong, koleksi terkunci dan respons API gagal mempunyai penanganan; tidak ada FAQ tambahan.
- PASS R-32: fokus terlihat, Tab/Enter/Escape serta shortcut kuis diuji. Atlas mendukung panah, zoom dan Page Up/Down untuk memilih POI nyata.
- PASS R-33: fitur UI ditulis langsung dalam source. Pemrosesan gambar offline menghasilkan aset dari sumber terlacak; tidak memodifikasi source UI lewat skrip eksternal.
- PASS R-34: tidak ada mode tema baru. Profil kualitas mempertahankan warna, UI dan geometri permainan.
- PASS R-35: typecheck, build Web/API, ekspor Godot, pengujian engine dan click-through browser dijalankan; bukan hanya inspeksi source.
- PASS R-36: monitor performa opt-in berisi pengukuran engine sebenarnya. SwiftShader browser otomatis tidak dilabeli sebagai FPS Windows atau S23.
- PASS R-37: arah pengguna ialah pixel comfy, kamera tiga perempat, palet tropis hangat dan UI taktil. Implementasi mengikuti [arah warna](../art-direction-comfy.md) dan [Rencana 04](../plans/04-hud-fullscreen-performa-dan-gerak.md).

## Purpose Gate

- PASS R-01/R-09/R-10/R-13: cahaya dan grading memperjelas lingkungan; peringatan O2 mempunyai ambang nyata. Tidak ada lapisan kaca atau badge promosi tambahan pada HUD.
- PASS R-04/R-06: ikon peta, buku, tas dan jala menggambarkan fungsi kontrol. Ark Pixel mempertahankan identitas game; Nunito dipakai untuk bacaan panjang dan informasi kecil.
- PASS R-07/R-08: grid tas menyusun inventori nyata; grid pada rekaman gait hanya alat inspeksi. Tidak ada panah dekoratif pada setiap tombol.
- PASS R-12/R-14: bingkai kuningan dan bayangan pendek membedakan panel dari dunia; ukuran panel mengikuti jumlah informasi, bukan pola kartu dashboard.
- PASS R-19/R-22: pembukaan buku, typewriter dan emote memberi umpan balik tindakan. Pengurangan gerak menonaktifkan gerak yang tidak diperlukan. Potret berasal dari pemeran Jalasmara.

## Liveliness

- PASS: ENERGY 2, RHYTHM 2, MOTION 2. Aksen kuningan dipakai pada interaksi dan identitas; lingkungan tetap menjadi bidang visual utama.
- PASS: fokus layar mengikuti konteks, yaitu instrumen saat menyelam, percakapan saat berbicara, dan halaman saat membaca.
- PASS: jarak memisahkan kelompok informasi, joystick dan aksi; ruang atas portrait disisakan untuk Menu browser.
- PASS: motif kayu, kertas dan kuningan muncul konsisten pada HUD, dialog, buku, tas dan atlas.
- PASS: gerak mengikuti input, jarak dan kontak; pose diam netral terpisah dari frame kaki terangkat.
- PASS: keputusan komposisi dan palet berasal dari brief pengguna sebelum implementasi, bukan template halaman umum.

## Craftsmanship dan konsistensi

- PASS C-1/C-3/R-05: setiap kelompok HUD mempunyai tugas dalam permainan; tidak ada bagian pengisi atau layout pemasaran.
- PASS C-2: pengujian input meliputi pemilik joystick, cancel/fokus, modal, tombol tujuan, kuis dan transisi rumah; tidak menambah tindakan ekonomi palsu.
- PASS C-4/R-11/R-15/R-16: panel menggulir saat sempit, fokus mengikuti tindakan, tombol utama minimal 48 piksel fisik dan aksi modal minimal 56; font utama minimal 16 piksel fisik pada ukuran yang diuji.
- PASS C-5: screenshot fixture, rekaman native, pengujian browser dan pengukuran perangkat nyata dibedakan secara eksplisit.
- PASS R-20/R-21/R-29/R-30/R-31: warna teks/fokus ditetapkan pada komponen terkait, kontrol menggunakan motif yang sama, teks panjang membungkus dan angka tas tidak dipotong menjadi elipsis.

## Batas penerimaan

Windows dan Samsung S23 fisik belum diprofilkan. Tidak ada klaim 30/60 FPS, pengukuran thermal throttling, atau penerimaan sesi manusia 15–20 menit. Anotasi overview peta yang kecil bukan pengganti panel informasi besar; dukungan pembaca layar untuk canvas belum dibuktikan. Posisi pivot yang benar tidak membuktikan setiap telapak yang dilukis sempurna pada seluruh frame. Tiga rig NPC tetap cutout; seluruh pemeran desa belum mempunyai atlas ilustrasi delapan arah.

Perubahan ini menyelesaikan implementasi perangkat lunak inti Rencana 04 untuk ditinjau. Validasi perangkat nyata dan perluasan desa/hutan/laut tetap dicatat sebagai pekerjaan terbuka; laporan ini tidak menyatakan seluruh backlog game selesai.
