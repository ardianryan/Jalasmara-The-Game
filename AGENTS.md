# Petunjuk kerja agent Jalasmara

## Primary GitHub dan mirror source, keputusan terbaru (12 November 2026)

GitHub `https://github.com/ardianryan/Jalasmara-The-Game` kini memegang CI dan paket delivery. Gitea dan GitLab hanya mirror kode, dengan Actions/CI dinonaktifkan. Laporan ada sebagai artifact GitHub Actions; jangan menghidupkan ulang `ci-reports` atau menjalankan pipeline di mirror. Baca [operasi GitHub](docs/operations-github.md). Untuk commit yang siap direkam gunakan `npm run push:all -- <branch>`; helper mengirim SHA yang sama ke GitHub dahulu, lalu Gitea dan GitLab tanpa force. Push bukan bukti CI/art/physics diterima. Aktivasi staging tetap tahap terpisah. Keputusan ini menggantikan instruksi CI Gitea pada [operasi lama](docs/operations-gitea.md) dan [addendum Gemini historis](docs/plans/08c-gitea-ci-addendum.md).

## Delegasi Gemini satu hari, 10 November 2026 (historis, sudah ditutup)

Kontrak [day01](docs/plans/08-gemini-day01-handoff.md), [prompt](docs/plans/08-gemini-day01-prompt.md), dan [Imagen](docs/plans/08-gemini-day01-imagen.md) adalah catatan delegasi lama, bukan instruksi aktif. Branch/worktree tersebut sudah ditutup dalam [konsolidasi final](docs/reviews/branch-final-consolidation-2026-11-12.md). Jangan membuatnya kembali hanya karena laporan lama menyebut namanya.

## Baca sebelum mengubah source

1. [Handoff aktif](docs/agent-handoff.md): branch/worktree, paket yang benar-benar dirilis, pemeriksaan terakhir, dan pekerjaan berikutnya.
2. [PRD](docs/PRD.md): kebutuhan produk dan batas penerimaannya.
3. [Status pengembangan](docs/development-status.md), [Rencana 06](docs/plans/06-finishing-dunia-npc-dan-perluasan-desa.md), dan laporan paket yang dirujuk handoff.
4. [Arah visual](docs/art-direction-comfy.md), [integrasi referensi](docs/reference-integrations.md), [lisensi](THIRD_PARTY_LICENSES.md), dan [operasi](docs/operations.md) sesuai tugas.

Instruksi pengguna dalam sesi aktif mengatasi pedoman ini. Jangan mengulang permintaan izin yang sudah diberikan atau menghentikan tugas hanya untuk membuat rencana baru. Kerjakan paket inti yang belum selesai sebelum menambah dekorasi atau dependensi.

## Arsitektur dan arah yang dipertahankan

- Runtime game: Godot 4.7.2 Compatibility, ekspor Web single thread. React/Vite menjadi host, akun, dan admin; Fastify/MongoDB/Redis memegang state otoritatif. Contoh Phaser dalam referensi pengguna tidak memerintahkan migrasi engine.
- Daratan memakai terrain/mesh 3D nyata dan pixel upscale nearest. Kamera yang dituju dari kiri menghadap serong kanan, pandangan 3/4. Jangan mirror peta atau karakter untuk mengejarnya. Azimut −45° pada helper Z-up adalah kandidat; periksa handoff apakah baru fixture atau sudah gameplay.
- Rumah di atas dermaga harus mengikuti sumbu dek dalam ruang dunia. Jangan menumpuk skew isometrik pada footprint dengan rotasi kamera lalu menyebut hasilnya benar. Fasad, atap, serambi, tiang, pintu dan collider memakai transform yang sama.
- Untuk pijakan tangga gunakan `ground_point`/inverse lokal yang berbagi geometri tread; `map_point(p,ground_height(p))` dapat menggeser XY dan menanam kaki pada tread lain. Ramp/input/facing tetap memakai gradien kontinu. Terrain batu dan preview area harus bertumpu, bukan lembaran tanpa sisi; jangan memperluas lantai server hanya untuk menutup gap visual. Normal vertex tanah harus konsisten dengan shader warna agar shadow pass tidak menghasilkan garis diagonal.
- Tema comfy pesisir Nusantara: hijau tropis, tanah/kayu hangat, air teal, bayangan berwarna, kedalaman atmosfer. HUD ringkas terutama malam, teks kuis terbaca, joystick bulat analog, fullscreen dan loading byte asli tetap berfungsi.
- Kandidat delivery memakai manifest PCK terikat SHA dan stream bagian1MiB melalui loader yang dipatok; WASM/fetch lain tetap. Jangan mengganti sharedproxy, mencampur manifest/build, atau mengklaim startupgame lulus dari transferaset saja. Lihat [laporan unduhan](docs/reviews/overnight-segmented-pck.md) untuk status aktual.
- Satu hari kalender = 36 menit aktif nyata, server-owned. Kalender bukan hari progres cerita. Modal/pause tidak memberi hadiah atau pertumbuhan sendiri.
- Nala mempertahankan identitas dan pakaian harian, explorer serta diving; tabung/tas/alat terpisah. Fase langkah membaca perpindahan nyata. Jangan menerima kaki menggunting, slide telapak, pemanjangan tungkai, atau prostetik bertukar sisi hanya karena socket test lulus.
- Inspektur Raka tetap inspektur. Direktur PT mempunyai identitas dan rumah kontainer/RV terpisah; rumah pribadi lurah berbeda dari balai. Jangan menyebut bangunan/NPC itu tersedia sebelum terhubung ke rute dan interaksi.

## Pembagian kerja dan verifikasi

- Gunakan worktree terpisah dan tetapkan satu penulis tiap berkas bersama. Jumlah slot mencakup integrator; maksimalkan subagent hanya bila diminta dan sesuai kapasitas sesi.
- Semua import/export Godot, native render, browser WebGL dan benchmark GPU dijalankan bergantian lintas worktree. Umumkan pemilik slot dan pelepasannya; CPU/source independen boleh paralel.
- Commit subagent tidak berarti diterima. Integrator menggabungkan, menjalankan tes gabungan, dan meninjau gambar/gameplay sebenarnya. Jangan stage symlink `node_modules`, `.runtime`, artefak uji atau kredensial.
- Pemeriksaan umum: `npm run typecheck`, `npm test`, `npm run check:world`, `npm run build`. `GODOT_BIN` dapat menunjuk binary lokal. Periksa log Godot untuk `SCRIPT ERROR`/`ERROR`, bukan exit code saja. Tes baru yang diperlukan ikut runner CI.
- Gunakan database/UUID fixture tersendiri; bersihkan hanya data miliknya. Jangan menggunakan akun owner, reseed, atau menghapus volume. Uji migrasi harus membuktikan lantai terhubung, bukan hanya titik walkable.
- Bedakan bukti CPU, headless, native, browser, emulasi sentuh dan perangkat fisik. SwiftShader/RAF bukan FPS GPU Samsung S23 atau Windows. Jangan mengklaim natural walking lengkap dari still image.
- Ikuti operasi repo untuk rilis. Catat SHA source, PCK dan image, CI, backup, rollback serta smoke aktual. Kandidat lokal tidak boleh disebut sudah tampil di staging. Pertahankan data, `.env`, dan upstream proxy.

## Penyimpanan lokal dan VPS

Pengguna meminta penghematan storage berkelanjutan. Setelah paket digantikan, hapus cache dan hasil build yang terbukti tidak dipakai; pertahankan build aktif serta satu image rollback terverifikasi. Periksa proses/pemilik sebelum menghapus output worktree lain. Jangan menghapus source kandidat, `.git`, bukti pengujian, database/volume, `.env`, atau backup sebagai bagian pembersihan cache. Jangan mengikuti symlink dependency atau menghitungnya berulang. Installer yang telah selesai dipakai boleh dihapus setelah hasil instalasinya diverifikasi. Jalankan prune build Docker hanya setelah build selesai; jangan memakai prune volume. Catat path, byte aktual, ruang bebas sebelum/sesudah, dan health/hash aplikasi di laporan pembersihan.

## Tool dan lisensi

Gunakan aset library proyek dahulu. Raster baru boleh dibuat sesuai otorisasi pengguna, dengan source/prompt/provenance dan lisensi. Jangan memasukkan gambar moodboard sebagai aset distribusi. Tool bernama dalam chat belum tentu tersedia atau dipakai.

Port Noxe terbatas pada helper kamera saat ini; simpan pin dan notice MIT. Tidak ada runtime Three.js kedua. PixelDoll masih referensi authoring hingga adapter dan aset benar-benar diuji. WorldKit adalah adapter/workflow sendiri, bukan cara menghapus atribusi upstream. Jangan menyimpan key/API token dalam Markdown, command history, source atau laporan.

Tool authoring baru tersedia secara terpisah: [Cinetic](tools/cinetic/README.md) untuk trailer/cutscene pra-render dan [Xprite Pixelate](tools/xprite-pixelate/README.md) untuk pemulihan grid pixel art otomatis. Keduanya tidak terhubung ke runtime. Periksa lisensi renderer/musik Cinetic serta hasil visual Xprite sebelum mengangkat output menjadi aset game. [unfake.js dan TerrainGenerator](docs/reviews/offline-authoring-tools-2026-11-11.md) hanya referensi yang ditinjau, bukan tool yang dipasang atau pengganti terrain Godot.

[Fish Gen](docs/world/fish-gen-reference.md) dipatok pada `0faa79003ca50a7d422b618cb59179d9834094f1`. [Pilot overnight](docs/reviews/overnight-fishgen-pilot.md) menghasilkan atlas asli dan adapter runtime untuk tiga ikan dekoratif, dengan tes animasi dan native render; adapter masuk ekspor593/PCK1315 pada rilis798. Sepuluh spesies gameplay tetap. Pertahankan lisensi MIT/provenance, tool offline terisolasi dan batas populasi; jangan menyamakan ikan dekoratif dengan tangkapan atau spesies endemik.

## Wajib setelah tiap paket/progres bermakna

Perbarui laporan `docs/reviews/` dan [handoff aktif](docs/agent-handoff.md), walaupun pekerjaan baru selesai sebagian. Catat:

- Permintaan dan perubahan yang benar-benar dibuat; branch/commit serta status lokal/tergabung/dirilis.
- Tes yang dijalankan, hasil gagal maupun lulus, bukti/artifact path, dan batas pengujian.
- Tool yang benar-benar digunakan, revisi/versi, sumber aset, lisensi; pisahkan referensi yang baru diteliti.
- Pekerjaan tersisa dengan urutan, alasan, pemilik berkas dan langkah reproduksi/command berikutnya.
- Keputusan pengguna terbaru serta koreksi yang membatalkan asumsi lama.

Sinkronkan PRD/rencana/status bila cakupan atau penerimaan berubah. Simpan ringkasan singkat di log handoff setiap kali paket ditutup; jangan mengganti laporan lama seolah tes baru sudah dijalankan. Jawaban chat bukan satu-satunya tempat menyimpan progres.

## Galeri bukti di GitHub

Pengguna meminta artefak visual dapat dilihat sebagai dokumentasi pengembangan. Simpan pilihan screenshot/contact sheet yang berguna di `docs/visual/`, tautkan dari README dan laporan. Cantumkan source/PCK, asal gambar, hash, hasil pengujian serta status kandidat/rilis; pertahankan lisensi aset terpisah dari MIT kode. Gunakan bukti original proyek tanpa data akun/kredensial/moodboard. Kurasi ukuran agar repository tetap ringan; rekaman lengkap, cache, ekspor game dan dump pengujian tetap mengikuti aturan artefak yang sudah ada. WorldKit dapat merujuk contoh galeri tanpa mengubah screenshot game menjadi aset kit berlisensi MIT.
