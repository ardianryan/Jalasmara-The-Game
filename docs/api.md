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

Posisi daratan dikembalikan melalui `surface` pada state petualangan. Hub dan hutan memakai pandangan miring dari atas dengan gerak dua arah pada bidang tanah; hutan merupakan wilayah terpisah berukuran 2400 × 1600. Server membatasi kecepatan sinkronisasi posisi, memeriksa jarak 220 piksel dari gerbang saat perjalanan, dan jarak 180 piksel untuk penemuan. Akses daratan ditolak selama penyelaman atau giliran kedai aktif. Perubahan versi pemain membatalkan posisi sementara lama. Penemuan tersimpan pada `adventure.discoveries`; transaksi idempoten mencegah hadiah berulang.

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
