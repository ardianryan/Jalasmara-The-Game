# Pilot interior warga: Dalem Wirabhumi

Status: proposal CPU, belum diimplementasikan atau diterima. Dibaca terhadap integrasi `cca08d0` dan kontrak runtime ekspor `593dc79`/PCK `1315f346…ef5e0`. Preview dan paket aktif tidak diubah. Penugasan parent membatasi tahap ini pada proposal sambil menunggu uji browser induk keramba.

## Batas pilot

Satu ruang tamu/arsip rumah pribadi Ki Lurah, `rumah_lurah`, masuk melalui pintu kanonis `(192.5,310)` yang sudah tersambung ke rute desa. Balai publik `(940,310)` tetap layanan izin kebun. Griya Sasmita tetap rumah Nala; boolean `homestead.inside` tidak menjadi penanda rumah warga.

Fungsi ruang: berjalan di lantai yang sah, mendekati meja arsip, membaca catatan pengukuran pasang-surut melalui presenter dialog/buku yang sudah ada, lalu keluar. Arsip menggunakan materi dan lore proyek yang ditinjau, tanpa membuat hadiah, permit, mata uang, atau kemajuan cerita baru. Tidak ada tidur, deposit, atau akses pantry rumah Nala di sini. Tidak menggandakan Lurah sebagai aktor interior; jadwal warga di luar tetap. Kehadiran NPC indoor mengikuti paket lain bila nantinya diperlukan.

Ruang memakai satu renderer Godot yang sama, lantai kayu, dinding belakang/samping, pintu dengan ambang fisik, meja arsip dan lentera dari material/helper proyek. Sisi dekat kamera menjadi cutaway yang disengaja. Bukan scene kosong dengan tombol teleport, bukan salinan kamar Nala yang mengganti judul. Tidak memerlukan aset raster atau dependensi baru.

## Temuan source yang menentukan cakupan

- `WORLD.homestead.privateHomes` sudah membedakan rumah Lurah dan direktur, tetapi belum menunjuk interior. Pintu Lurah juga titik `activity.rest`; pilihan pintu dan percakapan harus tetap terjangkau saat keduanya berdekatan.
- `HomesteadState` hanya mempunyai `inside`, `position`, `interiorVersion` untuk Nala. `homePosition()` memakai Redis `home:<id>` dengan TTL1800; posisi baru pada endpoint posisi tidak selalu ditulis sebagai checkpoint Mongo. Jalur itu tidak cukup untuk janji reload setelah cache hilang pada interior warga baru.
- `LandMap.id` saat ini literal `hub|forest|home`. Identitas ruang baru harus eksplisit; memakai `home` lagi berisiko memicu furnishing dan semantik Griya. Manifest indoor terpisah tidak boleh dimasukkan ke daftar tujuan transisi outdoor.
- `HomesteadScene.gd` dan `HomesteadRenderer.gd` terikat pada entry/bed/chest Griya, angka ruang960×720, dan state rumah Nala. Reuse helper lantai/collision/Player/proyeksi dapat dilakukan; jangan menganggap subclass tanpa override sudah mendukung ruang berbeda.
- `adventure.ts:surfacePlayer`, `game.ts` guard rumah, dan `homestead.ts:outside/idle` harus mengenali kunjungan warga. Tanpa itu klien lain dapat menyelam, membuka kedai atau memakai layanan kebun sambil state interior aktif.
- `GameState.apply_result` menyaring versi player dan revision rumah. State ruang baru perlu penyaringan revision sendiri serta routing scene pada bootstrap dan refresh, bukan hanya callback tombol masuk.

## Kontrak minimal yang diusulkan

Definisi baru `packages/shared/src/resident-interiors.ts` memegang satu `ResidentInteriorId = "wirabhumi_archive"`, manifest lantai/collider/routes, doorId `rumah_lurah`, exterior area `hub`, entry, exitApproach, dan archiveApproach. Titik interaksi adalah titik berdiri yang sah di depan benda, bukan pusat collider meja. `LandMap.id` ditambah ID ruang eksplisit dengan audit consumer; union `LandAreaId`/portal outdoor tetap `hub|forest`.

Field player opsional yang dimigrasikan secara malas:

```ts
residentInterior?: {
  revision: number;
  interiorId: "wirabhumi_archive" | null;
  layoutVersion: number;
  position: { x: number; y: number } | null;
  returnTo: {
    area: "hub";
    doorId: "rumah_lurah";
    position: { x: number; y: number };
    layoutVersion: number;
  } | null;
};
```

`revision` naik pada perpindahan ruang dan checkpoint posisi yang diterima; `player.version` naik pada aksi masuk/keluar, tidak pada setiap langkah. Timestamp pembatas gerak dibuat server; klien tidak mengirim waktu tepercaya. Redis boleh mempercepat posisi, tetapi checkpoint Mongo harus cukup untuk melanjutkan setelah Redis hilang. Koordinat sumber kebenaran tetap koordinat logis manifest, bukan posisi mesh/kamera.

Rute baru di `apps/api/src/resident-interiors.ts`:

| Endpoint | Permintaan | Keputusan server |
| --- | --- | --- |
| GET `/api/resident-interior/state` | tanpa koordinat | visit kanonis + definisi; validasi/migrasi posisi sebelum dikembalikan |
| POST `/api/resident-interior/action` | `action: enter|exit|read_archive`, `interiorId`, `expectedRevision`, header idempotency UUID | lock akun, guard lokasi/mode/version, receipt berisi fingerprint penuh; respons player/visit dan surface bila keluar |
| POST `/api/resident-interior/position` | `interiorId`, `expectedRevision`, endpoint dan breadcrumbs terbatas | ID cocok, setiap segmen walkable/radius12, anggaran jarak/waktu server, checkpoint durable; stale revision ditolak |

Masuk hanya dari posisi outdoor kanonis hub dekat pintu yang terdaftar (usulan72unit, harus diuji terhadap fasad/ambang sebenarnya), tanpa dive aktif, shift aktif, atau `homestead.inside`. Payload tidak dapat memilih koordinat tujuan maupun rumah lain. Klien membilas breadcrumb luar sebelum aksi masuk; respons hilang diulang memakai key/body yang sama. Transisi scene menunggu ACK, input dibekukan selama operasi.

Keluar hanya dari pendekatan pintu interior. Server memilih return point dari manifest pintu terbaru dan memvalidasi koneksi ke graf desa; tidak menerima return point dari klien. Respons ACK menerapkan visit/surface secara bersama sebelum scene diganti. Pemanggilan ulang receipt tidak menambah version dua kali.

Jangan mengandalkan transaksi Mongo untuk menulis Redis secara atomik. Implementasi harus menyimpan marker return/checkpoint kanonis dengan transisi Mongo dan memperbaiki Redis surface secara idempoten sebelum surface dipakai kembali, atau mekanisme ekuivalen yang dibuktikan oleh fault test. Respons gagal setelah commit tidak boleh membuat save berada di luar tetapi Redis kembali ke titik jauh sebelum pintu. Lock akun yang sama wajib dipakai untuk semua guard/transisi terkait. Detail marker internal dipilih saat implementasi; ini syarat penerimaan, bukan klaim sudah tersedia.

`read_archive` memeriksa jarak terhadap archiveApproach dan mengembalikan entry materi yang sah untuk presenter. Tidak menulis discovery berhadiah pada pilot. Membaca berulang tidak mengubah ekonomi, kalender, kebun, keramba, atau cerita. Kalender tetap36menit aktif/server-owned; pause UI mengikuti aturan yang ada, tidak mempunyai mekanik pertumbuhan khusus.

## Save dan migrasi

1. Save lama tanpa field baru menjadi visit kosong/revision0. Semua byte/data bermakna `homestead`, inventory, progress dan calendar dipertahankan; `homestead.inside=true` tetap bootstrap Griya.
2. Kunjungan valid dilanjutkan pada posisi durable terakhir yang terhubung ke entry; reload klien, login ulang, restart API dan hilangnya Redis tidak mengembalikan pemain ke desa diam-diam.
3. Revisi manifest interior hanya memindahkan checkpoint yang tidak sah/terputus ke entry interior yang teruji. Titik sekadar walkable belum membuktikan koneksi. Posisi valid pada komponen entry dipertahankan.
4. ID interior yang dihapus/tidak dikenal atau state konflik dengan rumah Nala dipulihkan secara deterministik dan dicatat. Prioritas kompatibilitas: Griya lama yang aktif tetap dipertahankan; visit warga konflik dibersihkan. Bila tidak ada Griya aktif, recovery unknown ID memakai return door/hub component yang sah, tanpa memberi hadiah. Recovery menaikkan revision agar respons lama tidak menimpa posisi baru.
5. Layout luar tidak perlu naik bila footprint/pintu/rute tidak berubah. Versi interior sendiri dimulai1. Return point selalu divalidasi terhadap versi luar terbaru; migration tidak boleh menembus dinding, melompat ke komponen pulau terputus, atau mengubah posisi hutan yang tidak terkait.

## Kepemilikan berkas saat implementasi disetujui

| Pemilik | Berkas/hunk |
| --- | --- |
| Shelter/server | shared `resident-interiors.ts`, ekspor/type Player di `index.ts`, tambahan ID map di `land.ts` dan tautan manifest `world.ts`; API module baru, persistence/guard hunk `daily.ts`, `adventure.ts`, `game.ts`, `homestead.ts`; API migration/idempotency/route tests |
| Shelter/Godot setelah koordinasi | scene/script `ResidentInteriorScene.gd`, renderer baru `land/ResidentInteriorRenderer.gd` memakai helper existing; fixture kontak/ruang/keluar |
| Root integrator | registrasi route `app.ts`, hunk serialisasi player jika diperlukan `db.ts`, registrasi runner CI/world, penggabungan dan export/PCK baru; review guard API lintas modul sebelum merge |
| Website/UI dengan koordinasi | Main entrance/scene-routing hunk, `GameState` revision+bootstrap, kontrol/fokus layar sentuh, presenter arsip; pertahankan menu izin Balai dan percakapan Lurah |
| Character | Tidak ada perubahan Nala/rig/atlas yang diperlukan; gunakan karakter diterima saat berjalan di ruang baru |

Berkas bersama tetap satu penulis. Alternatif integrator dapat menyerahkan hunk Main/GameState setelah pekerjaan publik selesai; tidak menambal runtime preview saat uji keramba berjalan. Jangan reuse HomesteadUI `inside=true` untuk menyembunyikan state baru.

## Bukti wajib sebelum paket diterima

- API: save lama di luar/Griya; valid/invalid/unknown visit; setiap segmen collision dan speed; stale revision; ID palsu; enter jauh/forest/dive/shift/Griya; layanan outdoor ditolak saat visit aktif; read jauh; exit jauh; lost response/receipt replay/cross-body key; Redis hilang dan kegagalan setelah commit; logout/reload/admin invalidation. Semua memakai fixture UUID sendiri dan mempertahankan ekonomi/kalender.
- CPU graf: entry→meja→exit dan doorstep→rute desa dua arah, radius12; furniture tidak dapat dipotong; migration dari titik lama terputus dipulihkan, titik valid dipertahankan. Audit consumer untuk tambahan map ID dijalankan.
- Godot actual: scene boot dari save indoor, collision furnishing, mesh lantai dengan pijakan nyata, lighting siang/malam, cutaway tidak menghilangkan collider, input/proyeksi kiri konsisten; keluar tidak menggandakan player/NPC/renderer. Fixture ikut `check:world`, seluruh suite API/typecheck/build tetap lulus.
- Browser PCK baru: jalan dari desa ke pintu, pilihan masuk dan percakapan yang tumpang tindih dapat dipilih; masuk→jalan→arsip→tutup→reload indoor→keluar→reload outdoor. Keyboard serta joystick/fokus pada667×390 dan844×390; dialog minimum16px/target56px mengikuti kontrak produk. Fault respons enter/exit dan reset cache diuji terpisah dengan ledger/version/cleanup.
- Native/screenshots harus memperlihatkan lantai, dinding, ambang, perabot dan Nala pada zoom gameplay; gambar kosong atau hanya label modal tidak menerima interior. Belum ada bukti native/browser dari proposal ini.

Tidak memakai tool/library/aset baru. Pembacaan source dan penulisan proposal saja; tidak menjalankan Godot, browser, impor, export, atau migrasi. Langkah berikutnya setelah persetujuan scope dan browser induk selesai: satu commit shared/API+tests, review kontrak UI, baru scene/wiring terisolasi dan penerimaan PCK baru.
