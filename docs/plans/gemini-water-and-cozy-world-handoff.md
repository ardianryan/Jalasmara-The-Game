# Handoff untuk Gemini: air hidup, audio pesisir, dan pemolesan dunia

Tanggal: 8 November 2026. Dokumen ini merupakan rencana implementasi; fitur yang diberi label rencana belum dinyatakan selesai.

## 1. Mandat dan hasil yang diminta

Lanjutkan proyek Jalasmara yang sudah ada. Prioritas berikutnya adalah membuat air pesisir Bandar Hujung dan sungai Wringin terlihat mengalir, berbuih, bereaksi terhadap penghalang, serta terdengar sesuai posisi pemain. Setelah air lulus penerimaan, lanjutkan pemolesan satu koridor dermaga → kampung → jembatan → hutan.

Target visual: petualangan Nusantara dengan tampilan pixel art yang nyaman, kamera tiga perempat, kedalaman nyata, cahaya hangat, dan lingkungan yang bergerak lembut. Referensi Dave the Diver dan contoh cozy dari pengguna digunakan untuk memahami komposisi, gerakan, serta skala; jangan menyalin aset atau susunan levelnya. Pertahankan arsitektur pesisir Nusantara, bambu, kayu, atap limasan/rumbia, tanaman tropis, dan identitas Jala Muara.

Gunakan kode, aset, dan generator yang sudah tersedia. Tidak perlu membuat gambar AI baru untuk animasi air, buih, hujan, atau variasi waktu.

## 2. Kondisi terakhir yang sudah diverifikasi

- Workspace: `/Users/ardianryan/Documents/Jalasmara`.
- Baseline commit: `f0e70803ea476775665e58973903a5d65acef0ca`, sudah ada pada kedua remote `main`. Periksa HEAD aktual sebelum bekerja; mungkin ada perubahan agen lain setelah dokumen ini dibuat.
- GitHub: `git@github.com:ardianryan/Jalasmara-The-Game.git`.
- GitLab: `git@gitlab.com:ardianryan/jalasmara-the-game.git`.
- CI/build/CodeQL dijalankan di GitLab. GitHub menerima source dan laporan pada `ci-reports`; GitHub Actions tetap nonaktif.
- Pipeline baseline hijau: <https://gitlab.com/ardianryan/jalasmara-the-game/-/pipelines/3041945144>.
- Staging: <https://staging-jalasmara.ardianryan.com>.
- VPS aplikasi: `ssh dev-jalasmara`, direktori `/opt/jalasmara`, upstream `10.1.0.8:3000`.
- Jangan mengubah `moodle-server`, aaPanel, domain, sertifikat, atau konfigurasi reverse proxy. Pengguna mengelolanya sendiri.
- SHA-256 PCK staging baseline: `cbc14eb8d0689a299b929e0ebf39329e873d357c20eff9e5814e18d1f7e9c7ac`.
- Baseline lulus 54 tes API, 13 pemeriksaan dunia Godot, 14 pemeriksaan audio pada CI, serta pengujian Chromium melalui HTTPS. Ini bukti regresi, bukan persetujuan kualitas seni akhir.
- Backup terakhir teruji restore: `/var/backups/jalasmara/jalasmara-20261108T130730Z.archive.gz`. Restore dilakukan ke database pemeriksaan terpisah. Setelah cleanup terdapat satu akun pemain yang merupakan owner; jangan menghapus akun tersebut.

### Mesin dan kontrak yang harus dipertahankan

Game aktif menggunakan **Godot 4.7.2**, Web Compatibility, ekspor single-threaded. Frontend web React/Vite dan backend Fastify/MongoDB/Redis sudah berjalan. Jangan memulai ulang game dengan Phaser atau mengganti engine.

Daratan aktif memakai `LandWorld3D`: geometri 3D, kamera ortografis pada elevasi pandang **35°**, SubViewport **480 × 270**, diperbesar dengan nearest filtering. Karakter merupakan billboard sprite. Laut memakai renderer hybrid tersendiri. Ini sudah benar-benar menggunakan 3D, bukan sekadar bitmap yang diberi nama terrain.

`packages/shared/src/land.ts` merupakan sumber lantai, footprint, rute dan elevasi. Layout hub/hutan versi **5**, ukuran logis **2400 × 1600**. Hub memiliki 19 pohon fisik, hutan 43. Dua jembatan hutan terpisah, dengan dek selebar 110 piksel, ketebalan 18 piksel dan pagar bambu ber-collider.

Koordinat dan validasi gerak tetap pada bidang dua sumbu. Jangan mengubah radius badan, collision, aturan oksigen, hadiah, inventori, akun, atau progres hanya untuk efek visual. Arus visual pada pekerjaan ini tidak otomatis berarti gaya fisika pada pemain.

Jam kosmetik: **24 jam game = 36 menit nyata**. Server tetap menentukan hari cerita dan progres. Pertahankan jeda membaca serta pengaturan pengurangan gerak yang sudah tersedia.

## 3. Audit perubahan lokal sebelum menyentuh kode

Jalankan `git status --short` dan baca diff. Saat handoff dibuat terdapat pekerjaan agen lain yang belum di-commit:

**Audio yang relevan dan boleh diintegrasikan setelah ditinjau:**

- `client-godot/autoloads/AudioManager.gd`.
- `scripts/generate_audio.py`.
- Empat WAV baru beserta `.import` di `client-godot/audio/sfx/`:
  - `coastal_wave_lap.wav`, 2,80 detik.
  - `coastal_wave_surge.wav`, 3,40 detik.
  - `wave_crash_rock.wav`, 1,90 detik.
  - `ambient_coastal_waves.wav`, stereo loop 12 detik.

**Pekerjaan lisensi yang harus dipertahankan dan dipisahkan dari commit air:**

- `package.json`, `apps/api/package.json`, `apps/web/package.json`.
- `apps/web/public/credits.html`, `docs/assets/provenance.md`.
- `LICENSE`, `THIRD_PARTY_LICENSES.md`.

Daftar ini adalah snapshot, bukan izin mengabaikan perubahan baru. Jangan `git reset --hard`, `git clean`, overwrite massal, atau `git add .`. Stage file/hunk yang benar-benar sudah ditinjau. Jangan membuang perubahan agen lain demi membuat working tree terlihat bersih.

## 4. Baca file ini terlebih dahulu

| File/direktori | Kegunaan |
| --- | --- |
| `docs/dynamic-environment-guidelines.md` | Arahan lingkungan dinamis pengguna; baca versi aktual |
| `docs/world/land-layering.md` | Kontrak daratan aktif dan arsip implementasi lama |
| `docs/world/environment.md` | Waktu, cuaca, pencahayaan, air dan batas efek |
| `docs/world/hybrid-terrain.md` | Renderer laut dan hubungan dengan daratan |
| `docs/reference-integrations.md` | Daftar library/referensi dan batas integrasinya |
| `docs/development-status.md` | Status serta keterbatasan yang sudah diakui |
| `moodboard/` | Referensi privat; tetap diabaikan Git, jangan ikut distribusi |
| `packages/shared/src/land.ts` | Manifest lantai/prop/jembatan/footprint bersama |
| `client-godot/scripts/land/LandWater3D.gd` | Mesh air daratan, mask pantai dan parameter cuaca |
| `client-godot/scripts/land/LandWater3D.gdshader` | Gelombang, arus visual, warna, buih dan riak hujan |
| `client-godot/scripts/land/LandWorld3D.gd` | Proyeksi, elevasi, geometri, pencahayaan dan jembatan |
| `client-godot/scripts/hybrid/LivingWater.gd` | Arus visual, wake, caustics dan partikel bawah air |
| `client-godot/scripts/SurfaceWater.gd` | Implementasi air pada jalur 2D; jangan keliru menganggap ini renderer aktif utama |
| `client-godot/autoloads/EnvironmentState.gd` | Sumber waktu, angin, hujan dan pengurangan gerak |
| `client-godot/autoloads/AudioManager.gd` | Resource audio, bus, mute, fokus, filter selam dan BGM |
| `client-godot/scripts/WorldFoley.gd` | Langkah, napas dan ambience gameplay yang sudah aktif |
| `scripts/verify-living-world.mjs` | Runner 13 pemeriksaan dunia saat baseline |
| `scripts/tests/land-water-3d.gd`, `world-foley.gd`, `land-renderer.gd` | Regresi yang relevan |
| `scripts/godot-browser.mjs` | Uji input keyboard, raster aktual, posisi server dan perjalanan antararea |

## 5. Apa yang sudah ada dan apa yang belum

### Sudah ada pada staging baseline

- Permukaan air berupa mesh dengan vertex waves, bukan gambar diam.
- Tekstur bergerak dengan arah sungai berbeda dari pesisir.
- Warna kedangkalan, kilau, buih tepian prosedural dan riak hujan.
- Pencahayaan air mengikuti lingkungan. Bawah air sudah mempunyai partikel arus dan wake.

### Kekurangan yang harus diselesaikan

- Arah sungai masih hampir seragam; belum membelok mengikuti tepi, batu dan tiang.
- Buih masih berupa efek shader tepi. Belum ada pecah ombak setempat yang menyatu dengan penghalang dan suara.
- Ombak maju–surut pantai masih sederhana, belum mempunyai siklus wash/recede yang jelas.
- Empat audio baru terdaftar pada AudioManager lokal, tetapi belum dipanggil otomatis oleh gameplay. Staging baseline belum memuat tambahan audio tersebut.
- `play_bgm("coastal_waves")` adalah contoh pemanggilan yang diberikan agen audio. Jangan menggunakannya sebagai implementasi ambience final karena dapat menggantikan musik yang sedang berjalan.

## 6. Rencana implementasi berurutan

### Tahap A — Field air bersama dan emitter yang jelas

1. Buat helper data air, misalnya `WaterField.gd`, dengan tanggung jawab terbatas: jarak ke pantai, normal pantai, arah/kecepatan arus visual, dan kedekatan penghalang air.
2. Perluas mask yang sekarang dibuat sekali oleh `LandWater3D._shoreline_texture()`. Mask saat ini 160 × 112; pertahankan dahulu, naikkan hanya jika bukti visual menunjukkan resolusinya tidak cukup.
3. Hitung jarak/normal dalam satuan dunia. Ukuran sel X dan Y berbeda; jangan memakai turunan tekstur tanpa koreksi rasio ukuran peta.
4. Pakai lantai daratan dan landmass untuk pantai. Dek dock/bridge tidak boleh menutup seluruh air di bawahnya. Bedakan footprint dek yang menghalangi pemain dari tiang yang benar-benar bersentuhan dengan air.
5. Tambahkan metadata emitter air eksplisit bila dibutuhkan: ID stabil, posisi/segmen, normal tepi, jenis `sand`/`rock`/`pile`, intensitas dan radius. Letakkan hanya pada posisi yang didukung geometri nyata.
6. Tiang di bawah jembatan berasal dari geometri renderer. Jika dibutuhkan bersama, refactor perhitungan posisinya ke helper yang dibaca renderer dan efek; jangan mengarang titik benturan hanya dari persegi collider pagar.
7. Simpan hasil sampling, cache dan spatial lookup. Jangan memindai semua poligon atau membuat ulang gambar mask setiap frame.
8. Field dan metadata baru tidak boleh membuat lantai berjalan baru atau collider tersembunyi.

### Tahap B — Gerakan air yang terbaca dan nyaman

1. Pertahankan palet air hijau-toska redup, bukan neon atau permukaan plastik mengilap.
2. Pesisir: gabungkan swell lebar dan detail kecil yang bergerak pada laju berbeda. Hindari satu pola sinus yang berulang jelas di seluruh layar.
3. Sungai: buat arah aliran mengikuti jalur sungai, lalu dibelokkan secara halus di dekat normal tepi/penghalang. Gunakan interpolasi stabil, bukan vektor acak per piksel.
4. Tambahkan pusaran kecil hanya di sisi hilir penghalang yang terpilih. Jangan mengisi seluruh sungai dengan spiral.
5. Shader, partikel dan event harus membaca sumber fase/arahan yang konsisten. Tidak boleh ada bunyi benturan ketika ombak visual sedang menjauh.
6. Semua animasi berdasarkan delta/waktu, bukan jumlah frame. Saat angin berubah, lerp parameter agar fase tidak meloncat.
7. Pertahankan pixel grid konsisten; hindari shimmer subpiksel pada kamera dan noise yang terlihat seperti televisi rusak.
8. Pengurangan gerak mengurangi amplitudo/partikel/kontras gerakan tanpa mematikan keterbacaan air. Ikuti kebijakan pause yang sudah ada; jangan membuat timer gameplay berhenti karena efek air.
9. Tetap gunakan Compatibility/WebGL. Jangan menambah compute shader, OS thread, atau simulasi fluida berat.

### Tahap C — Buih, sapuan pantai dan percikan benturan

1. Beri tiap segmen pantai fase swell yang bervariasi secara halus dan stabil dari ID/koordinat, bukan random ulang setiap frame.
2. Pada pasir: pita wash maju ke bibir pantai → berhenti sebentar → surut. Buih pecah menjadi fleck kecil lalu memudar, bukan satu outline putih permanen.
3. Pada batu/tiang: munculkan semburan kecil pada sisi datang gelombang, kemudian fleck bergerak mengikuti aliran. Besar efek mengikuti energi swell dan angin.
4. Pada sungai tenang: utamakan streak dan buih tipis di penghalang. Jangan memakai hempasan laut besar di setiap tiang jembatan.
5. Gunakan object pool/ring buffer untuk fleck/splash. Satu manager per area, bukan satu node aktif untuk setiap piksel air.
6. Buih dan percikan harus tunduk pada depth/occlusion. Jangan menggambar di atas dek, dinding, HUD, atau kaki pemain yang masih berdiri di lantai kering.
7. Bila perlu efek basah di pantai, gunakan strip terbatas sesuai metadata. Jangan mengubah seluruh terrain menjadi air yang bisa diinjak.
8. Sebagai anggaran awal, batasi sekitar 8 emitter dekat kamera, 24 splash aktif, dan 96 fleck. Ukur hasilnya sebelum menaikkan; angka ini anggaran desain, bukan klaim performa yang sudah terbukti.

### Tahap D — Hubungkan audio pesisir yang sudah tersedia

1. Tinjau WAV/import dan perubahan AudioManager dari agen audio. Jangan generate ulang aset jika file yang ada valid.
2. Tambahkan pemutar ambience tersendiri yang dapat berjalan bersama BGM, misalnya pada manager `WaterAmbience.gd` atau API ambience AudioManager. Gunakan environment bus yang sudah ada.
3. Loop `ambient_coastal_waves` hanya satu instance aktif per listener. Ubah gain dengan fade, bukan stop/play berulang pada setiap pergantian jarak.
4. Volume mengikuti jarak ke air dan jenis area. Pantai/dock hub memakai ambience pesisir; hutan sungai tidak otomatis memakai suara ombak laut besar.
5. Pada event wash dekat pemain, pilih `coastal_wave_lap`; saat swell/angin kuat pilih `coastal_wave_surge`; benturan pada batu/tiang memicu `wave_crash_rock`.
6. Event visual dan audio berasal dari satu event swell yang sama. Cegah pemutaran dua kali ketika fase melewati batas atau frame terlambat.
7. Batasi one-shot air awalnya maksimal dua suara bersamaan. Jangan menghabiskan delapan slot SFX bersama sehingga langkah, jala atau notifikasi hilang. Pertimbangkan pool khusus air bila dibutuhkan.
8. Terapkan attenuation, fade dan variasi pitch kecil yang masuk akal. `play_sfx` sudah menambahkan volume argumen pada gain dasar; jangan menghitung gain dua kali tanpa memeriksa implementasinya.
9. Hormati `can_play_environment()`, gesture unlock browser, mute, fokus tab, menu, transisi scene dan logout. Tidak boleh ada antrean deburan yang meledak setelah unmute/fokus kembali.
10. Saat menyelam, kurangi ambience permukaan dan ikuti filter bawah air. Napas, peringatan oksigen serta BGM harus tetap terdengar dan tidak dimulai ulang akibat update volume air.
11. Registrasi stream atau kenaikan penghitung debug bukan bukti suara sudah terdengar. Lakukan pemeriksaan pemutar aktual dan dengarkan hasilnya melalui speaker/headphone.

### Tahap E — Pemolesan koridor setelah air lulus

Kerjakan satu segmen sampai koheren sebelum memperluas map:

1. Dermaga: bentuk kelompok kerja yang masuk akal—tambatan/perahu, gulungan tali, jala dan peti—dengan ruang jalan tetap jelas. Prop besar memerlukan footprint; detail kecil yang diinjak tidak boleh terlihat seperti penghalang besar.
2. Kampung: pecah halaman tanah yang terlalu luas dengan kelompok tanaman, batas halaman dan detail setempat. Hindari pengulangan peti/batu pada grid.
3. Jalan: variasikan tepian dan peralihan tanah–rumput. Jalur tetap menuju POI, tangga dan pangkal jembatan yang benar.
4. Hutan: variasikan tinggi, siluet dan kelompok vegetasi, bukan sekadar mengulang tajuk identik. Pertahankan urutan kedalaman, pangkal batang dan penutupan pemain yang masuk akal.
5. Cahaya: warna tanah/air tetap terbaca pada malam hari; lentera hangat bersifat lokal. Hindari glow menyeluruh dan bayangan panjang yang mendominasi layar.
6. Pertahankan jembatan baru. Celah kecil antarplank pernah membesar menjadi garis air hijau saat raster 480 × 270 diperbesar. Solusi baseline: top plank rapat, tiga variasi material kayu halus, tanpa lubang fisik antarpapan.
7. Perubahan footprint/rute harus melalui manifest bersama, migrasi layout bila diperlukan, serta tes server/physics. Jangan memperbaiki gambar dengan mengizinkan pemain melayang di atas atap, batu atau air.

## 7. Pembagian kerja paralel yang disarankan

Gunakan satu integrator dan paling banyak tiga agen aktif pendamping bila tersedia. Bagi kepemilikan file sebelum bekerja.

| Peran | Tugas | Batas |
| --- | --- | --- |
| Integrator | Kontrak field/event, review visual, merge, build dan deploy | Satu pihak saja melakukan deploy dan commit akhir |
| Agen air | Field, shader, buih, emitter dan sampling | Tidak mengubah AudioManager atau ekonomi/physics |
| Agen audio | Integrasi WAV, loop terpisah, attenuation dan event audio | Jangan sekaligus mengedit shader atau mengganti BGM |
| Agen verifikasi | Tes perilaku, browser, video dan pengukuran | Jangan melonggarkan assert demi membuat tes hijau |

Sepakati kontrak event sebelum implementasi, misalnya `{id, area, position, normal, kind, energy, phase}`. Tetapkan normalisasi nilai, satuan koordinat, pemilik clock, cooldown dan lifecycle. Ini rancangan API baru; jangan menganggapnya sudah tersedia.

Jika hanya ada satu Gemini, kerjakan A → B → C → D → pengujian → E. Jangan membuka seluruh pekerjaan sekaligus lalu berhenti pada scaffolding.

## 8. Pengujian yang harus membuktikan hasil

### Perilaku dan regresi

- Field mengklasifikasikan tanah/air dengan benar, termasuk air di bawah dek; normal dan arah arus stabil serta terbatas.
- Arah aliran berubah masuk akal di dekat penghalang; sampel CPU dan parameter shader memakai konvensi yang sama.
- Event swell hanya terbit satu kali per siklus pada frame normal maupun delta besar.
- Batas pool dipatuhi; node/audio tidak terus bertambah setelah perpindahan hub–hutan–laut berulang.
- Tidak ada perubahan koin, oksigen, inventori, progres, collision atau akses zona akibat efek.
- Mute, fokus, gesture unlock, menu, reload, selam dan keluar scene tidak meninggalkan loop atau menumpuk event.
- Pemutar ambience berjalan bersama BGM tanpa mengambil alih nama track atau memulainya ulang.
- Jalankan tes yang relevan pada setiap tahap; setelah kandidat selesai jalankan typecheck, API suite, build Web dan pemeriksaan dunia. Perluas runner untuk pemeriksaan air/audio baru yang bermakna.

Perintah dasar dari root:

```sh
npm run typecheck
npm test
npm run check:world
npm run build
```

Jika Godot tidak ditemukan, set `GODOT_BIN` ke executable 4.7.2. Pada mesin asal tersedia `.runtime/godot/Godot.app/Contents/MacOS/Godot`. Periksa versi dan template Web terlebih dahulu. Cold import memakai `scripts/export-game.mjs`; jangan mengganti pipeline hanya untuk menghindari kegagalan import.

### Bukti visual dan audio

Sediakan cuplikan 10–15 detik pada kamera tetap untuk masing-masing:

1. Dermaga cerah: swell bergerak, buih menghantam tiang dan surut, suara tepat waktunya.
2. Pantai pasir: wash maju–surut, warna dangkal dan fleck yang memudar.
3. Jembatan Wringin: air lewat bawah dek, arus terbaca, buih kecil di penghalang, dek tetap kering.
4. Senja/malam: air mengikuti pencahayaan, lentera tetap lokal dan HUD terbaca.
5. Hujan/angin: perubahan intensitas halus; riak tidak menjadi grid lingkaran besar yang mendominasi.
6. Bergerak mendekat/menjauh dari pesisir, lalu menyelam: attenuation dan filter terdengar tanpa BGM terputus.

Gunakan tangkapan renderer aktif, bukan helper terisolasi saja. Jangan menyatakan efek berhasil hanya karena `debug_status().shoreFoam == true` atau clock bertambah. Periksa perubahan piksel pada region air, occlusion, dan tidak bocornya efek ke region darat. Tetap lakukan review manusia atas video dan suara.

Jalankan browser pada aplikasi nyata. Harness yang sudah ada:

```sh
APP_TEST_ORIGIN=http://localhost:3100 \
VERIFY_LAND=1 VERIFY_LIVING=1 VERIFY_HYBRID=1 VERIFY_BACKDROP=1 \
node scripts/godot-browser.mjs
```

Harness memerlukan akun fixture lokal melalui `.runtime/browser.json` atau `BROWSER_FIXTURE`. Jangan memasukkan kredensial owner ke fixture atau log. Buat pemain uji terpisah sesuai helper yang ditinjau dan hapus hanya data pemain uji itu setelah selesai.

Baseline Firefox baru terverifikasi pada cakupan tertentu dan cold startup dapat lambat. Jangan mengklaim Safari iOS/Android fisik telah diuji jika hanya memakai emulasi Chromium. Headless Godot tidak membuktikan shader berhasil pada GPU browser; periksa console WebGL dan render native/browser aktual.

Catat ukuran PCK, waktu startup, frame time sebelum/sesudah dan jumlah emitter/partikel. Sasaran awal 30 FPS pada perangkat target adalah target pengukuran, bukan janji. Jangan menambah full-screen pass berat atau readback GPU tiap frame.

## 9. Build, repository dan deployment

1. Tinjau diff dan stage eksplisit. Sertakan audio baru yang sudah diverifikasi; jangan ikut meng-commit pekerjaan lisensi yang belum disepakati agen pemiliknya.
2. Bila masih ada perubahan agen lain, buat snapshot kandidat terisolasi dari commit dasar lalu overlay hanya file yang disetujui. Export Godot dari snapshot itu. Jangan membuat PCK dari working tree campuran lalu mengklaimnya berasal dari commit bersih.
3. Periksa sumber kandidat cocok dengan commit akhir. Build web/API dari sumber kandidat yang sama.
4. Push source ke kedua remote. Tunggu GitLab untuk SHA yang tepat dan periksa laporan GitHub `ci-reports` juga menunjuk SHA tersebut. Jangan mengaktifkan GitHub Actions.
5. Sebelum mengganti aplikasi, simpan image rollback dari container/image aktif saat itu dan jalankan `bash scripts/backup.sh` pada VPS. Jangan menimpa satu tag rollback lama tanpa mengetahui isinya.
6. Salin release yang ditinjau ke `/opt/jalasmara`; lindungi `.env`, database, cache dan berkas privat. Jangan memakai penghapusan massal saat rsync.
7. Jalankan `docker compose build app`, lalu `docker compose up -d --no-deps app`. Jangan melakukan `down -v` atau mengganti Mongo/Redis yang sedang sehat.
8. Periksa `/api/health`, kesehatan container dan SHA-256 PCK melalui upstream serta HTTPS publik. Build lokal sukses tidak berarti staging sudah diperbarui.
9. Uji scene air serta alur darat–selam melalui domain publik. Pakai pemain uji sementara, bukan owner. Verifikasi cookie produksi tetap aman.
10. Hapus akun/sesi/data uji secara terbatas setelah browser selesai. Jalankan backup baru, lalu `scripts/verify-restore.sh` terhadap archive itu. Script memulihkan ke `jalasmara_restore_check`, membandingkan jumlah, lalu menghapus database pemeriksaan tersebut—jangan menggantinya dengan restore ke database live.
11. Catat commit, pipeline, checksum PCK, bukti video/gambar, backup dan keterbatasan. Jangan mengklaim seluruh map sudah final hanya karena tes lulus.

## 10. Kriteria selesai

Pekerjaan air selesai jika seluruh butir berikut terbukti:

- [ ] Ombak dan arus terlihat bergerak pada video renderer aktual.
- [ ] Pesisir, sungai, pasir dan penghalang mempunyai respons yang berbeda.
- [ ] Buih maju/pecah/surut, bukan outline putih statis atau motif berulang yang mencolok.
- [ ] Air tidak menutupi dek/daratan, dan pemain tidak memperoleh pijakan baru.
- [ ] Suara ombak otomatis terdengar dekat pesisir, melemah saat menjauh, serta sinkron dengan event visual.
- [ ] BGM, napas, langkah, mute, fokus dan transisi selam tetap benar.
- [ ] Tidak ada error shader/WebGL atau pertumbuhan node/audio tanpa batas.
- [ ] Tes, build dan pipeline untuk SHA final lulus; laporan GitHub sesuai.
- [ ] Staging benar-benar memakai paket final dan telah diuji melalui HTTPS.
- [ ] Akun uji dibersihkan dan backup berhasil diuji restore.
- [ ] Keterbatasan visual, perangkat yang belum diuji, dan pekerjaan koridor yang tersisa dilaporkan jujur.

## 11. Instruksi penutup untuk agen pelaksana

Mulai dengan membaca dokumen dan diff aktual, lalu kerjakan Tahap A. Lanjutkan sampai integrasi air/audio dapat dimainkan dan ditinjau melalui staging. Beri laporan kemajuan singkat yang menyebut temuan serta bukti. Jika memilih pendekatan berbeda, jelaskan alasan teknis dan pertahankan kontrak engine, budaya, kontrol server, sumber footprint, repository, serta deployment di atas.

Jangan berhenti pada pembuatan helper, registrasi audio, atau screenshot statis. Hasil yang diminta pengguna adalah lingkungan yang bergerak dan bereaksi secara koheren saat dimainkan.
