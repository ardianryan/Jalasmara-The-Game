# API Jalasmara

Semua endpoint memakai JSON. API dan frontend berbagi origin. Path berawalan `/api/` tidak di-cache. Definisi TypeScript dan validasi runtime di `packages/shared/src` serta `apps/api/src` merupakan sumber kontrak yang dijalankan.

## Sesi dan perubahan data

Panggil `GET /api/auth/session` terlebih dahulu; respons menyediakan `csrf` dan pengguna jika sudah login. Kirim cookie sesi, header `Origin` yang sama dengan `APP_ORIGIN`, serta `X-CSRF-Token` untuk semua operasi selain GET/HEAD/OPTIONS, termasuk login dan aktivasi. Cookie produksi memakai Secure, HttpOnly untuk sesi, dan SameSite=Lax.

Operasi transaksi game dan perubahan pemain/publikasi konten membutuhkan `Idempotency-Key` berformat UUID. Gunakan kembali key untuk retry payload yang sama; jangan gunakan key yang sama untuk aksi lain. Operasi admin pemain juga membawa `version` terbaru. Respons `409 VERSION_CONFLICT` mengharuskan memuat ulang pemain dan meninjau kembali perubahan.

Kesalahan memakai `{ "error": "pesan", "code": "kode" }`. Status yang digunakan meliputi 400 validasi, 401 sesi, 403 izin/CSRF, 404 resource, 409 konflik, 410 sesi berakhir, dan 429 pembatasan permintaan. Jangan menjadikan pesan manusia sebagai enum logika klien.

## Identitas

| Method/path                                  | Tujuan                                                   |
| -------------------------------------------- | -------------------------------------------------------- |
| `GET /api/auth/session`                      | Pengguna, CSRF, dan ketersediaan provider                |
| `POST /api/auth/login`                       | Email/password lokal                                     |
| `POST /api/auth/logout`                      | Mencabut sesi saat ini                                   |
| `POST /api/auth/reauth`                      | Konfirmasi password untuk tindakan sensitif              |
| `POST /api/auth/activate`                    | Token undangan, nama, password                           |
| `POST /api/auth/reset`                       | Token reset dan password baru                            |
| `GET /api/auth/oidc/start`                   | Memulai login atau penautan eksternal                    |
| `GET /api/auth/oidc/callback`                | Callback authorization code + PKCE                       |
| `POST /api/auth/oidc/unlink`                 | Melepas identitas setelah autentikasi ulang              |
| `POST /api/admin/invitations`                | Owner menerbitkan undangan dengan email dan alasan       |
| `POST /api/admin/players/:id/reset-password` | Owner menerbitkan reset pemain setelah autentikasi ulang |

Password minimal 12 karakter. Token undangan/reset berada pada fragmen URL saat diberikan ke pengguna sehingga tidak menjadi query log server. Token hanya ditampilkan ketika diterbitkan; server menyimpan hash, bukan token mentah. Tidak ada endpoint pendaftaran publik atau pengiriman email.

## Petualangan dan ekonomi

| Method/path                    | Tujuan                                                                |
| ------------------------------ | --------------------------------------------------------------------- |
| `GET /api/health`              | Status konektivitas database dan Redis                                |
| `GET /api/game/state`          | Profil, inventori, konten publik, dan sesi aktif                      |
| `GET /api/adventure/state`     | Konteks dunia untuk klien Godot                                       |
| `POST /api/game/appearance`    | Menyimpan pilihan penampilan pemain di permukaan                      |
| `POST /api/game/tutorial`      | Menandai tutorial selesai                                             |
| `POST /api/adventure/interact` | Interaksi NPC, temuan, dan tujuan cerita                              |
| `POST /api/dive/start`         | Memulai penyelaman atau arena boss                                    |
| `POST /api/dive/position`      | Sinkronisasi posisi dengan validasi gerak server                      |
| `POST /api/dive/reading`       | Mengatur pembacaan temuan saat bahaya berhenti                        |
| `POST /api/dive/net/start`     | Memulai ayunan/tahanan jala                                           |
| `POST /api/dive/collect`       | Menangkap target terjangkau dengan kualitas berdasarkan timing server |
| `POST /api/dive/challenge`     | Membuka tantangan kontekstual/boss                                    |
| `POST /api/dive/catch`         | Menjawab dengan `diveId`, `challengeId`, `selectedOption`             |
| `POST /api/dive/continue`      | Menutup pembahasan dan melanjutkan simulasi                           |
| `POST /api/dive/hazard`        | Melaporkan bahaya untuk validasi server                               |
| `POST /api/dive/extract`       | Menuntaskan penyelaman dan menyimpan hasil sah                        |
| `POST /api/kedai/start`        | Membuka giliran kedai                                                 |
| `POST /api/kedai/serve`        | Memilih resep dan fragmen untuk pelanggan                             |
| `POST /api/kedai/close-shift`  | Menutup malam dan menyimpan penghasilan server                        |
| `POST /api/game/upgrade`       | Membeli peningkatan melalui Beno                                      |

Klien tidak mengirim koin hasil perhitungan sendiri, kunci jawaban, atau waktu jawaban yang dipercaya server. Kunci dan pembahasan soal tidak muncul pada tantangan sebelum dijawab. Jawaban menghasilkan hasil serta penjelasan. Selama tantangan/pembacaan aktif, simulasi bahaya berhenti. Sesi terikat versi pemain dan konten; hasil sesi yang dibatalkan admin ditolak.

`POST /api/game/appearance` menerima `{ "appearance": "male_default" | "male_nusantara" | "female_default" | "female_nusantara" }` dan mengembalikan `{ "player": ... }`. Memerlukan sesi, CSRF, dan `Idempotency-Key`; perubahan menaikkan versi profil. Pilihan tersimpan pada akun dan tidak mengubah kemampuan, ekonomi, atau progres. Akun lama tanpa `appearance` diminta memilih oleh klien. Penyelaman atau giliran kedai aktif menghasilkan 409; properti target pengguna tidak diterima.

Posisi daratan dikembalikan melalui `surface` pada state petualangan. Hub dan hutan memakai pandangan miring dari atas dengan gerak dua arah pada bidang tanah; hutan merupakan wilayah terpisah berukuran 2400 × 1600. Server membatasi kecepatan sinkronisasi posisi, memeriksa jarak 220 piksel dari gerbang saat perjalanan, dan jarak 180 piksel untuk penemuan. Akses daratan ditolak selama penyelaman atau giliran kedai aktif. Perubahan versi biasa mempertahankan posisi sah; aksi admin yang tercatat audit tetap membatalkan posisi sementara lama. Penemuan tersimpan pada `adventure.discoveries`; transaksi idempoten mencegah hadiah berulang.

## Kalender, rumah, dan kebun Plan 03

`GET /api/adventure/state` dan `GET /api/homestead/state` menyertakan `calendar`, `homestead`, serta `homesteadDefinitions` di samping profil/dunia yang relevan. Definisi lokasi mengacu pada `WORLD.homestead`; klien tidak menetapkan sendiri koordinat pintu, petak atau furnitur.

| Method/path                    | Tujuan                                                                                       |
| ------------------------------ | -------------------------------------------------------------------------------------------- |
| `GET /api/homestead/state`     | Memuat kalender, rumah, stok, petak, dan definisi publik                                     |
| `POST /api/calendar/heartbeat` | Menyelesaikan interval waktu aktif untuk satu penulis tab/perangkat                          |
| `POST /api/homestead/position` | Memvalidasi gerak interior melalui lantai dan footprint furnitur                             |
| `POST /api/homestead/action`   | Masuk/keluar, tidur, transfer peti, izin, bibit, penanaman, penyiraman, panen dan stok kedai |

Heartbeat menerima `{sessionId, paused, focused}`; `sessionId` adalah UUID tab, bukan ID akun yang dapat dipilih klien. Klien memanggilnya sekitar lima detik. Redis memberi lease penulis 20 detik kepada pasangan sesi login/tab; tab lain menerima `writer:false` beserta snapshot. Server hanya menambahkan interval milik penulis yang sama ketika kedua heartbeat tidak dijeda dan jedanya paling banyak 15 detik. Jeda yang lebih panjang tidak dihitung; waktu offline tidak mengejar kalender. Pembacaan/tantangan penyelaman memaksa jeda di server. Satu hari permainan memerlukan 36 menit aktif; hujan harian berasal dari server. Akun lama menerima kalender/rumah awal secara idempoten saat state dimuat; kelayakan izin yang sudah dipenuhi tetap dipertahankan.

Posisi interior menerima `{x,y,path?}` dengan paling banyak 128 titik. Pemain harus benar-benar berada di rumah tanpa penyelaman/giliran aktif. Setiap ruas, panjang total dan waktu server diperiksa; lantai serta furnitur memakai `WORLD.homestead.interior`, radius 12 piksel dan sampling ruas 6 piksel. Respons menyediakan posisi yang diterima. Admin yang membatalkan state lama dapat menghasilkan `SESSION_CHANGED`; klien tidak boleh menimpa hasil tersebut dengan respons gerak yang terlambat.

Tindakan rumah memerlukan sesi, CSRF, `Idempotency-Key` UUID dan `expectedRevision` terbaru. Bentuk payload:

```json
{
  "action": "plant",
  "expectedRevision": 3,
  "plotId": "plot_1",
  "itemId": "benih_kangkung",
  "qty": 1
}
```

| `action`               | Syarat dan hasil server                                                                                                                          |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| `enter` / `exit`       | Dekat pintu luar atau titik keluar interior; portal hanya memindahkan ke titik pasangan yang ditetapkan                                          |
| `sleep`                | Di dekat dipan; tidur lebih awal memerlukan `confirmEarly:true`; pergantian kalender, pertumbuhan dan marker cerita diselesaikan dalam transaksi |
| `deposit` / `withdraw` | Di dekat peti; `itemId`, `stars` 1–3 dan `qty` mempertahankan jenis/kualitas fragmen; kapasitas peti 100 unit                                    |
| `permit`               | Di papan balai setelah misi `akar`; izin dan dua bibit awal hanya diberikan sekali                                                               |
| `buy_seed`             | Di pasar; `benih_kangkung` berharga 20 koin, paling banyak enam bibit per akun per hari kalender                                                 |
| `plant`                | Dekat `plot_1` atau `plot_2`, izin sah, petak kosong dan satu bibit yang dimiliki                                                                |
| `water`                | Dekat petak yang ditanami; perawatan ditandai untuk hari berjalan, bukan menambah pertumbuhan berulang                                           |
| `harvest`              | Tiga hari pertumbuhan yang dirawat telah selesai; menghasilkan tiga kangkung dan mengosongkan petak                                              |
| `stock_kedai`          | Dekat Mbah Wira; memindahkan hasil `kangkung` ke pantry kedai, bukan mengubahnya menjadi koin secara langsung                                    |

Tahap publik petak ialah `empty`, `seed`, `sprout`, `young` atau `ready`; `watered`, `needsCare`, dan `ready` merupakan field terpisah. Penyiraman atau hujan server pada hari yang diselesaikan memenuhi syarat pertumbuhan. Setiap batas hari diproses sekali. Hari kalender terpisah dari `progress.day`, sehingga tidur atau menanam tidak membuka siklus cerita berikutnya tanpa syarat.

`POST /api/kedai/serve` menerima opsi `gardenIngredient:true`. Server tetap memerlukan resep dan fragmen/kualitas yang benar, lalu mengonsumsi satu kangkung pantry untuk bonus lima koin. Menutup giliran yang selesai menyimpan `homestead.pendingStoryAdvance`; nomor siklus cerita atau tahap boss baru berubah ketika tidur yang sah diproses. Retry transaksi tidak menggandakan bonus, hasil panen, bibit awal atau kemajuan cerita.

Arsip dibaca dari penemuan yang dimiliki. Rak mengikuti `player.adventure.keyItems`; tidak ada endpoint yang mengarang hadiah hanya karena pemain membuka rumah. Pembaruan rumah yang berbenturan menghasilkan `409 HOMESTEAD_CHANGED`; muat ulang state sebelum membuat tindakan baru. Kunci retry hanya digunakan kembali untuk payload yang sama.

Status kontrak ini: 77 pengujian backend serta alur GUI rumah, kebun, pelayanan kedai dan tidur telah lulus secara lokal. Hasil CI dan staging mengikuti revisi sumber pada repository.

## Pengelolaan

| Method/path                                        | Tujuan                                          |
| -------------------------------------------------- | ----------------------------------------------- |
| `GET /api/admin/players?search=&status=all&page=1` | Pencarian pemain, 20 per halaman                |
| `GET /api/admin/players/:id`                       | Pemain, audit terakhir, dan sesi aktif          |
| `POST /api/admin/players/:id/change`               | Perubahan dengan versi, alasan, dan tindakan    |
| `GET /api/admin/audit`                             | Riwayat mutasi                                  |
| `GET /api/admin/content`                           | Daftar versi konten                             |
| `GET /api/admin/content/:id`                       | Isi versi lengkap dan hash                      |
| `POST /api/admin/content/draft`                    | Membuat draft                                   |
| `PUT /api/admin/content/:id`                       | Menyimpan katalog draft dengan pemeriksaan hash |
| `POST /api/admin/content/:id/publish`              | Validasi lalu publikasi versi                   |
| `POST /api/admin/content/:id/archive`              | Arsip versi yang memenuhi syarat                |
| `POST /api/admin/questions/validate`               | Validasi impor JSON bank soal sebelum disimpan  |

Contoh perubahan saldo, hanya untuk owner/admin:

```json
{
  "version": 7,
  "reason": "Kompensasi hasil penyelaman yang gagal tersimpan",
  "action": "coins",
  "mode": "add",
  "amount": 500
}
```

Tindakan lain: `inventory`, `ability`, `progress`, `reset`, `block`, `unblock`, `revoke`, dan `role`. Hanya owner boleh menetapkan peran `player`/`admin`; admin tidak dapat mengubah owner. Kemampuan memakai `oxygen`, `bag`, `speed`, atau `net` dengan level sesuai katalog. Fragmen membutuhkan `fragmentId`, `stars` 1–3, `mode`, dan `amount`.

Bypass tetap memvalidasi batas saldo, ID, level, dan konsistensi progres. Mutasi membatalkan sesi permainan lama dan menyimpan audit dalam transaksi yang sama. Konten terbit bersifat versi; pengarsipan mempertahankan data yang dirujuk sesi dan inventori. Publikasi menolak penghapusan ID fragmen, level kemampuan, atau resep yang dibutuhkan progres lama.

### Posisi daratan modular, hub layout 8 dan hutan layout 5

`WORLD.landMaps.hub` dan `.forest` menerbitkan poligon lantai, material/elevasi, footprint prop, serta konektor tangga yang sama untuk renderer, physics dan server. Air tidak dapat dilalui secara default. Overlay jalan dengan `walkable: false` hanya dekorasi/material dan tidak menciptakan lantai di atas sungai. Badan pemain memerlukan clearance 12 piksel; server memeriksa titik tengah dan delapan sampel keliling pada gabungan lantai, lalu menolak footprint prop beserta marginnya.

`POST /api/adventure/surface-position` menerima `{area, x, y, version?, fromPositionAt?, path?}`. `path` merupakan paling banyak 64 titik `{x,y}` sejak posisi terakhir yang diterima server, untuk mempertahankan belokan nyata ketika sinkronisasi tidak dilakukan setiap frame. Jika `path` diberikan, `fromPositionAt` wajib sama persis dengan `surface.positionAt` respons terakhir. Basis lama atau replay ditolak dengan `409 POSITION_CHANGED`. Klien mengirim satu request posisi pada satu waktu dan mengganti basis hanya setelah respons berhasil.

Server memeriksa setiap ruas dari posisi tersimpan, melalui breadcrumb, hingga endpoint; ruas tidak boleh memotong atap, prop, celah elevasi atau air. Jumlah panjang seluruh ruas diperiksa terhadap waktu server dan batas laju yang sama dengan gerak biasa, sehingga loop panjang tidak lolos hanya karena endpoint dekat. Tanpa `path`, endpoint divalidasi sebagai satu ruas lurus. Respons tetap `{surface}` dan `positionAt` selalu meningkat. Kegagalan tidak memindahkan posisi tersimpan.

Save daratan lama dimigrasikan ke versi layout area saat ini: hub 8 dan hutan 5. Koordinat yang masih sah dipertahankan; hanya koordinat tidak sah yang dipindahkan ke lantai aman terdekat dalam area yang sama. Migrasi posisi tidak menulis ulang koin, inventori, progres, penampilan atau versi akun.

Perubahan versi akun akibat upgrade, tutorial atau penampilan tidak lagi memindahkan pemain ke spawn: posisi sah, area dan basis `positionAt` dipertahankan. Server membedakannya dari perubahan admin melalui audit transaksi `player.*` dengan versi setelah posisi tersimpan. Pembatalan admin tetap mereset posisi/sesi sesuai semantik sebelumnya. Steering klien memakai margin 13 piksel secara konservatif, sementara API memvalidasi radius 12 piksel pada footprint yang sama; perbedaan ini mencegah ruas breadcrumb pendek memotong sudut karena aproksimasi gerakan.
