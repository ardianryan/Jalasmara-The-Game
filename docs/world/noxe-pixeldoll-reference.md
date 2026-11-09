# Referensi Noxe dan PixelDoll untuk Jalasmara

Diperiksa pada 9 November 2026 atas permintaan pengguna. Status: penelitian sumber dan pratinjau bawaan, belum integrasi runtime atau produksi aset baru. Godot tetap menjadi runtime; prioritas penyelesaian dunia pada [Rencana 06](../plans/06-finishing-dunia-npc-dan-perluasan-desa.md) tetap berlaku.

| Proyek | Revisi yang diperiksa | Keputusan untuk Jalasmara |
| --- | --- | --- |
| [Noxe Pixel Engine](https://github.com/danieljan-design/noxe-pixel-engine/tree/d619d856398b44ad084003fac0a9fbfc9c8393e7) | `d619d856398b44ad084003fac0a9fbfc9c8393e7` | Cocok untuk metode konstruksi ruang/bangunan 3D, kamera tiga perempat, dan finishing piksel. Implementasinya memerlukan adaptasi Godot. |
| [PixelDoll](https://github.com/Shilo/PixelDoll/tree/1136e4db1a055a850f0a684e5fb581a2d13aa3bc) | `1136e4db1a055a850f0a684e5fb581a2d13aa3bc` | Cocok untuk authoring karakter 2D dengan pakaian dan alat berlapis. Ekspor Godot tersedia; pemasangan pada billboard 3D Jalasmara memerlukan adapter. |

## Noxe: bentuk 3D dahulu, finishing piksel kemudian

Noxe memakai Three.js untuk geometri prosedural. Adegan Studio memperlihatkan lantai tebal, dua dinding, jendela, meja, rak, dan lampu pada ruang potong terbuka. Cove memperlihatkan pondok, dermaga, air, serta relief daratan. Gambar tersebut membantu menjelaskan arah pengguna: permukaan atas dan sisi terlihat bersamaan, objek memiliki volume, dan cahaya mengikat ruang. Keduanya ialah gambar bawaan upstream yang ditinjau, bukan hasil Jalasmara atau bukti performa perangkat kita.

Temuan yang dapat diperiksa:

- [Kamera dan render](https://github.com/danieljan-design/noxe-pixel-engine/blob/d619d856398b44ad084003fac0a9fbfc9c8393e7/engine/pixel-engine.js): kamera ortografis, azimuth/elevasi terpisah, serta penempatan kamera pada grid piksel. Default 45°/30° bukan kewajiban mengganti elevasi daratan Jalasmara yang sekitar 35°.
- [Studio](https://github.com/danieljan-design/noxe-pixel-engine/blob/d619d856398b44ad084003fac0a9fbfc9c8393e7/scenes/studio.js): ruang dibangun melalui `create()` dan geometri dalam kode. Cutaway dirancang untuk rentang pandangan tertentu; dua dinding terbuka tidak otomatis menjadi sistem occlusion untuk semua sudut.
- [Kit geometri](https://github.com/danieljan-design/noxe-pixel-engine/blob/d619d856398b44ad084003fac0a9fbfc9c8393e7/scenes/kit.js): terrain bertingkat, lubang pada sisi terrain, pondok/dermaga/prop, dan penggabungan mesh per material. Pondok mempunyai orientasi pintu lokal tertentu; rotasi objek perlu diterjemahkan bersama footprint dan titik interaksi.
- [Material](https://github.com/danieljan-design/noxe-pixel-engine/blob/d619d856398b44ad084003fac0a9fbfc9c8393e7/engine/materials.js) dan [shader](https://github.com/danieljan-design/noxe-pixel-engine/blob/d619d856398b44ad084003fac0a9fbfc9c8393e7/engine/shaders.js): pencahayaan bertingkat, outline kedalaman, sorotan tepi, fog, grade, kuantisasi warna, dan dither. Shader/material Three.js tidak langsung menjadi shader Godot Compatibility.
- [Kontrol aplikasi](https://github.com/danieljan-design/noxe-pixel-engine/blob/d619d856398b44ad084003fac0a9fbfc9c8393e7/app.js): pemilihan adegan, kamera, waktu, cuaca, tampilan, dan ekspor. Ini belum editor bangunan drag-and-drop dengan penempatan pintu, collision, rute, undo, serta penyimpanan layout game.
- [Ekspor](https://github.com/danieljan-design/noxe-pixel-engine/blob/d619d856398b44ad084003fac0a9fbfc9c8393e7/engine/exporter.js): PNG dan MP4 tersedia; tidak ditemukan jalur GLB/glTF/OBJ pada revisi ini. Angka 60 FPS merujuk pada ekspor video offline, bukan hasil benchmark gameplay Windows/S23.

### Penerapan yang direncanakan

Gunakan konstruksi mesh modular native Godot untuk dinding, lantai, kusen, atap dan furnitur, dengan bentuk pesisir Nusantara. Pertahankan aset library/GLB yang sudah sesuai. Port bagian kecil berlisensi hanya jika membantu hasil; jangan memasukkan renderer Three.js kedua ke halaman permainan.

`facing` bangunan ialah rotasi lokal terhadap dunia. Kamera tetap tiga perempat. Pintu, tangga, footprint, lampu, serta titik kunjungan NPC ikut transformasi yang sama. Utamakan empat facing kardinal; sudut tambahan hanya dibuat jika jalur dan komposisi memerlukannya. Memutar bangunan tidak berarti memutar kamera atau mengubah arah jalan pemain.

Untuk interior, sediakan bagian atap/dinding yang dapat disembunyikan berdasarkan arah pandang. Pertahankan kusen, ketebalan lantai, bayangan, dan kontak furnitur agar ruangan tetap terbaca sebagai 3D. Potongan visual tidak menonaktifkan collider atau membuka jalur server baru.

Finishing memakai resolusi dunia rendah dan upscale nearest yang sudah ada, pencahayaan hangat, bayangan berwarna, serta kabut menurut jarak. Dither, outline, bloom, dan refleksi dipilih satu per satu melalui perbandingan visual/performa. Jangan menyalin seluruh rangkaian pass: Noxe dapat menggambar mesh dalam pass bayangan, refleksi, dan utama. Dither rapat pada pratinjau juga bukan kewajiban untuk mood comfy Jalasmara.

Arahan pengguna berikutnya memajukan satu pilot ke 06-B1a: rumah panggung pada dek existing dan serambi/tempat berteduh fisik. Tiang, kolong, balok, atap serta aksesnya dinilai bersama pembanding kamera menyudut. [Rencana pilot B1a](../plans/06b1a-rumah-panggung-dan-kamera.md) menjelaskan perubahan yang diperlukan pada proyeksi bila seluruh dunia memakai kamera isometrik. Pilot tersebut belum berarti Noxe sudah menjadi runtime game.

Pilot lanjutan pada paket 06-C: satu bangunan kontainer direktur dengan satu rancangan ruang potong terbuka. Eksterior/penempatan yang diperlukan paket C dapat selesai dahulu; interior playable tetap mengikuti paket 06-D. Bukti pilot meliputi empat facing, siang/malam, kamera permainan, pintu/tangga yang terhubung, dan penilaian HUD. Tidak ada janji interior siap hanya karena pratinjau ruang berhasil dirender.

Ekspor GLB dari generator Three.js dapat diteliti kemudian sebagai alat authoring offline. Perlu menambahkan exporter sendiri, menangani geometri yang didukung dan material pengganti, lalu menguji round-trip. Material prosedural, cuaca, lampu dan post-processing tidak boleh diasumsikan ikut tersimpan dalam GLB.

## PixelDoll: satu tubuh, pakaian dan alat terpisah

PixelDoll adalah aplikasi authoring 2D berbasis Svelte/Vite/TypeScript. Generasi baru memanggil PixelLab melalui akun pengguna. Ini layanan yang berbeda dari Sprite AI yang pernah diberikan. Demo/peninjauan data tidak memerlukan generasi berbayar; sesi penelitian ini tidak menggunakan key, memasang dependensi, atau memanggil API generasi.

[Toolchain authoring](https://github.com/Shilo/PixelDoll/blob/1136e4db1a055a850f0a684e5fb581a2d13aa3bc/app/package.json) memakai Node 24 dan npm 11. Jika dipasang kemudian, gunakan lingkungan terisolasi; konsumsi PNG/JSON tidak memerlukan pergantian Node runtime Jalasmara.

Kontrak yang relevan:

- [Manifest](https://github.com/Shilo/PixelDoll/blob/1136e4db1a055a850f0a684e5fb581a2d13aa3bc/docs/manifest-spec.md): item/slot, arah bernama, daftar frame beserta durasi, pivot per layer, anchor tangan/kaki, pasangan depan/belakang, serta pengecualian urutan layer per arah/animasi/frame. Item besar boleh mempunyai sel berbeda selama pivot merujuk titik tubuh yang sama.
- [Ekspor Godot](https://github.com/Shilo/PixelDoll/blob/1136e4db1a055a850f0a684e5fb581a2d13aa3bc/app/src/lib/export/godot.ts): `Node2D` dengan `AnimatedSprite2D` per layer, `SpriteFrames`, fungsi `equip`, dan sinkronisasi frame dari tubuh. Ini bukan rig tulang 3D atau node `Sprite3D` siap pasang pada peta kita.
- [Preset arah](https://github.com/Shilo/PixelDoll/blob/1136e4db1a055a850f0a684e5fb581a2d13aa3bc/app/src/studio/characterConfig.ts): default Top-down 8 mencerminkan tiga arah barat. Unique 8 menyediakan arah mandiri. Pilih Unique 8 untuk Nala dan periksa setiap arah; mirror dapat memindahkan alat ke tangan lain.
- [Batas mutu](https://github.com/Shilo/PixelDoll/blob/1136e4db1a055a850f0a684e5fb581a2d13aa3bc/docs/known-issues.md): grip, bentuk alat, telapak dan animasi hasil generasi masih memerlukan pemeriksaan visual. Keberadaan keypoint atau tes lolos tidak menjamin kaki berjalan natural. README juga membatasi klaim pengujian independen delapan arah; itu bukan bukti batch Nala sudah berhasil.
- [Ekspor umum](https://github.com/Shilo/PixelDoll/blob/1136e4db1a055a850f0a684e5fb581a2d13aa3bc/app/src/lib/export/export.ts): manifest, PNG terpisah dan catatan sumber memungkinkan adapter offline. PNG hasil gabungan dapat menjadi pilihan optimasi, tetapi berkas kerja tiap item tetap disimpan.

### Adapter yang direncanakan

Pertahankan renderer dan pengendali gerak Jalasmara. Adapter membaca PNG+manifest, memetakan nama arah secara eksplisit ke `E, SE, S, SW, W, NW, N, NE`, menyamakan skala/pivot kaki, dan menyusun lapisan pada bidang billboard yang mengikuti kamera. Urutan gambar pakaian/alat berbeda dari posisi kedalaman karakter terhadap bangunan.

Semua lapisan mengikuti satu fase tubuh. Saat berjalan, fase tetap membaca perpindahan nyata sehingga kaki/alat berhenti saat tertahan collider; animasi kerja memakai waktu klipnya sendiri. Jangan membiarkan setiap layer menjalankan clock bebas atau mengganti fase langkah berbasis jarak dengan autoplay ekspor.

Simpan pakaian harian, explorer dan diving sebagai pilihan terpisah dari slot tabung, tas, alat tangan dan aksesori. Mesh tabung/jala/tas yang sudah bekerja tetap dapat digunakan; satu item hanya mempunyai satu representasi aktif agar tidak muncul dobel. Tank di punggung dan genggaman alat diperiksa pada utara/selatan serta diagonal. Metadata anchor dari PixelDoll perlu dikonversi ke koordinat bidang tubuh sebelum dipakai oleh attachment mesh.

Atlas Nala yang ada mempunyai ukuran/pivot dan pakaian yang sudah menyatu dalam gambar tubuh. Menamai atlas itu sebagai layer pakaian tidak memisahkan pikselnya. Pilot harus membuktikan pemisahan dengan sumber yang memang berlapis atau penyuntingan yang ditinjau, sambil mempertahankan identitas Nala. Jangan mengganti semua karakter dengan demo upstream.

Pilot pada paket 06-B dimulai dari satu identitas, idle/walk, satu pakaian berlapis, satu tas dan satu alat terpisah. Tinjau 64 frame berjalan pada delapan arah mandiri, lalu perluas ke tiga pilihan pakaian. Pemeriksaan kontrak awal dapat memakai aset lokal tanpa key/API. Perluasan animasi kerja NPC mengikuti pilot empat arah yang sudah ditetapkan Rencana 06. Berenang dan seluruh batch identitas menunggu kualitas pilot dan anggaran render.

Catat jumlah layer/aktor, draw call, waktu frame dan memori. Evaluasi layer langsung dibanding cache gabungan yang hanya diperbarui saat frame/arah/perlengkapan berubah. Cache harus dibatasi; jangan membuat tekstur baru setiap frame untuk seluruh warga. Pakaian dan attachment tetap modular dalam data meskipun hasil render tertentu digabung untuk performa.

## Lisensi, atribusi, dan batas integrasi

[Lisensi Noxe](https://github.com/danieljan-design/noxe-pixel-engine/blob/d619d856398b44ad084003fac0a9fbfc9c8393e7/LICENSE) ialah MIT, hak cipta 2026 Daniel Jankulovski. [Lisensi PixelDoll](https://github.com/Shilo/PixelDoll/blob/1136e4db1a055a850f0a684e5fb581a2d13aa3bc/LICENSE) ialah MIT, hak cipta 2026 Shilo. Jika kode atau bagian substansialnya dipakai, sertakan pemberitahuan hak cipta dan teks izin yang sesuai, pin revisi, serta daftar berkas yang diadaptasi.

MIT perangkat lunak tidak dipakai sebagai kesimpulan otomatis tentang semua keluaran layanan generasi. PixelDoll menyebut demo sebagai keluaran PixelLab milik tim dan menyertakan provenance pada ekspor. Aset produksi baru memerlukan sumber/akun dan ketentuan layanan yang sesuai; pertahankan catatan sumber/`CREDITS.txt`. Dependensi dan font memiliki pemberitahuan tersendiri. Belum ada kode/aset dua proyek ini yang dimasukkan ke source atau paket distribusi Jalasmara, sehingga keduanya belum dicatat sebagai integrasi aktif dalam `THIRD_PARTY_LICENSES.md`.

Nama **Jalasmara WorldKit** tetap merujuk pada adapter dan workflow kita. Nama tersebut tidak menggantikan atribusi Noxe atau PixelDoll ketika kode mereka benar-benar digunakan.

## Bukti penerimaan sebelum penggunaan produksi

- [ ] Ruang/bangunan terbaca bervolume pada kamera sebenarnya dan empat facing; pintu, tangga, footprint serta rute memakai transformasi yang sama.
- [ ] Pakaian dapat diganti tanpa mengganti identitas; tabung, tas dan alat dapat dilepas sendiri tanpa gambar dobel.
- [ ] Delapan arah Nala menjaga sisi tangan, grip, pivot dan kontak telapak; rekaman berjalan, berhenti serta tertahan collider ditinjau pada ukuran tampil.
- [ ] Layer memiliki frame/durasi yang lengkap, anchor sah, sumber berlisensi, dan hasil impor ulang yang konsisten.
- [ ] Siang/malam/hujan, HUD, profile Ringan dan anggaran render dibandingkan sebelum/sesudah. Windows/S23 fisik tetap memerlukan pengukuran tersendiri.
- [ ] Save lama, jam 36 menit, posisi server dan statistik perlengkapan tidak berubah karena adapter visual.

Validasi penelitian: dua checkout di lokasi diabaikan Git, pemeriksaan kode/manifest/lisensi dan gambar bawaan Studio/Cove/Godot slash. Tidak ada install, generasi, uji runtime kedua tool, benchmark perangkat atau round-trip ke Jalasmara dalam tahap ini.

Pemeriksaan dokumentasi: Hard Gate PASS, status riset dan sumber dipisahkan dari implementasi; Purpose-Gate PASS, tabel menghubungkan setiap alat dengan kebutuhan bangunan atau karakter; Liveliness PASS untuk dokumentasi, contoh memakai kontainer direktur/Nala dan tetap mengikuti arah comfy yang disepakati, tanpa membuat UI baru; Craftsmanship PASS, tautan lokal dan diff diperiksa. Gate tampilan dan interaksi baru dijalankan pada pilot, bukan diklaim lulus di sini.
