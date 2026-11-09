<p align="center"><img src="assets/brand/horizontal.svg" width="420" alt="Jalasmara"></p>

# Jalasmara · Menjaring Ingatan

Petualangan pixel art dengan daratan 3D tiga perempat dan penyelaman 2.5D di Kota Apung Bandar Hujung serta Palung Smara. Nala berenang, menjelajahi reruntuhan, menemukan pengetahuan, dan membantu warga melalui Kedai Waras. Pembelajaran hadir dari lingkungan, penemuan, dan tantangan kontekstual.

Dibangun dengan **Godot 4.7.2** untuk permainan, **React + Vite** untuk akun dan panel admin, **Fastify** untuk API, **MongoDB** untuk progres, dan **Redis** untuk sesi. Ekspor browser memakai renderer Compatibility dan single thread.

- Staging: https://staging-jalasmara.ardianryan.com
- Sumber dan CI: [GitLab](https://gitlab.com/ardianryan/jalasmara-the-game)
- Mirror sumber dan laporan: [GitHub](https://github.com/ardianryan/Jalasmara-The-Game)
- [Laporan CI GitLab yang dikirim ke GitHub](https://github.com/ardianryan/Jalasmara-The-Game/tree/ci-reports)

Lihat [status pengembangan dan bukti pengujian](docs/development-status.md). Versi ini masih prototipe; pemolesan visual, uji bermain manusia, dan pengujian HP fisik belum selesai.

Nala dapat memasuki Griya Sasmita, menyimpan fragmen, merawat dua petak kangkung, membeli bibit, dan membawa panen ke kedai. Kalender akun memakai satu hari selama 36 menit aktif; tidur menyelesaikan pagi berikutnya tanpa melewati syarat cerita. Tiga warga memakai animasi tubuh berlapis dengan alat terpisah. Rincian serta batas implementasi ada di [Rencana 03](docs/plans/03-desa-hidup-dan-siklus-harian.md).

## Menjalankan lokal

Prasyarat: Node.js 22.12+, npm, Docker Compose v2, Godot 4.7.2 dan template ekspor Web single-threaded. MongoDB harus berjalan sebagai replica set agar transaksi dan audit konsisten.

```sh
npm ci
cp .env.example .env
docker compose -f compose.dev.yml up -d
npm run seed
npm run owner
npm run build:game
npm run dev
```

Buka `http://localhost:5173`. Perintah `owner` meminta email, nama, dan password melalui terminal; tidak ada kredensial bawaan. Akun pemain diaktifkan melalui undangan owner.

```sh
npm run typecheck
npm test
npm run build
```

Jika Godot tidak ada di PATH, isi `GODOT_BIN` dengan path executable. Hasil ekspor di `apps/web/public/game/` diabaikan Git dan dibuat kembali saat build. Untuk pengujian integrasi, gunakan database lokal khusus melalui `TEST_MONGO_URL` dan `TEST_REDIS_URL`; jangan arahkan tes ke database produksi.

## Isi proyek

| Bagian                                          | Fungsi                                                           |
| ----------------------------------------------- | ---------------------------------------------------------------- |
| `client-godot/`                                 | Dunia permainan, karakter, gerakan, eksplorasi, dan HUD          |
| `apps/web/`                                     | Akun, undangan, pengaturan, serta panel admin                    |
| `apps/api/`                                     | Validasi permainan, autentikasi, ekonomi, dan audit              |
| `packages/shared/`                              | Kontrak data, konten awal, dan definisi wilayah                  |
| `assets/brand/`                                 | Kit identitas Jalasmara                                          |
| `ci/`                                           | Build Godot, CodeQL, dan pengiriman laporan                      |
| `tools/npc-rig/`                                | Generator bagian tubuh NPC dari artwork orisinal proyek          |
| `tools/worldkit/`                               | Adapter offline peta dan validator lantai, elevasi, serta portal |
| `tools/pixel-snapper/`, `tools/image-to-pixel/` | Persiapan grid dan palet aset offline dengan atribusi upstream   |

## Jalasmara WorldKit

Repositori alat terpisah (privat): [GitHub](https://github.com/ardianryan/jalasmara-worldkit) · [GitLab](https://gitlab.com/ardianryan/jalasmara-worldkit). Salinan integrasi di `tools/` tetap diuji terhadap kontrak geometri game.

WorldKit adalah lapisan authoring dan pipa aset milik proyek; Godot tetap runtime permainan. Adapter peta menghasilkan draft untuk ditinjau, bukan publikasi otomatis ke dunia atau database. Pixel Snapper memakai kode upstream berlisensi MIT yang dikunci versinya; Image-to-Pixel memakai paket npm terpisah dari dependensi game.

Lihat [panduan WorldKit](tools/worldkit/README.md), [Pixel Snapper](tools/pixel-snapper/README.md), [pengolah palet](tools/image-to-pixel/README.md), dan [backlog next-gen](docs/nextgen-world-authoring.md). Jalankan `npm run check:worldkit` untuk memeriksa adapter beserta kecocokan geometry server. `npm run check:worldkit-assets` membutuhkan instalasi/build alat sesuai README masing-masing.

## Akun dan pengelolaan

Login lokal adalah jalur utama. Owner dapat mengundang pemain, menerbitkan reset password, dan menetapkan admin. Admin dapat mengelola konten serta mengubah koin, fragmen, kemampuan, dan progres dengan alasan yang tercatat. Perubahan pemain membatalkan sesi permainan lama agar hasil sebelumnya tidak menimpa perubahan.

OIDC opsional melalui ZITADEL. Pemain menautkan identitas eksternal dari akun lokal setelah autentikasi ulang. Identitas yang belum ditautkan tidak membuat akun baru; kesamaan email tidak menggabungkan akun otomatis.

## Dokumentasi

- [Rencana 06: finishing hutan/laut, aktivitas NPC, dan perluasan desa](docs/plans/06-finishing-dunia-npc-dan-perluasan-desa.md): keterbacaan hutan/laut dan dasar rutinitas warga sudah dirilis serta diperiksa melalui HTTPS staging. [Laporan awal](docs/reviews/06a-delivery.md) mencatat bukti dan status rilis; pilot tubuh, perluasan desa, serta Windows/S23 fisik tetap terbuka.
- [Rencana 04: HUD, fullscreen, performa, dan gerak Nala](docs/plans/04-hud-fullscreen-performa-dan-gerak.md): implementasi aktif dari laporan Windows/Samsung S23, dengan bukti pengujian dan batas penerimaan.
- [Jalur paralel HUD, daratan, laut dan website](docs/plans/05-jalur-kerja-paralel.md), dengan [pemeriksaan HUD Bahari dan loading](docs/reviews/parallel-hud-loading-delivery.md). Persentase loading memakai byte aset engine; gambar panorama/foreground dan prompt sumber tersimpan dalam repo.
- [Rencana 03: desa hidup, rumah Nala, dan siklus harian](docs/plans/03-desa-hidup-dan-siklus-harian.md): animasi warga, Griya Sasmita, kalender, kebun, pasar/balai, dan finishing.
- [Referensi teknis dan status integrasi](docs/reference-integrations.md): Polyfork, Strata, Procedural Pixel Creatures, img2threejs, SpriteCook, Ark Pixel Font, dan Pixelbolt.
- [Operasi dan deployment](docs/operations.md), termasuk upstream reverse proxy **10.1.0.8:3000**.
- [Kontrak API](docs/api.md).
- [Identitas merek](docs/brand/identity.md) dan [arah budaya](docs/brand/cultural-direction.md).
- [Asal aset](docs/assets/provenance.md), [kontribusi](CONTRIBUTING.md), dan [pelaporan keamanan](SECURITY.md).

CI dijalankan di GitLab; GitHub Actions dinonaktifkan. JUnit, audit dependensi, dan CodeQL SARIF diterbitkan sebagai artefak GitLab dan disalin ke branch `ci-reports` GitHub. Pengiriman memakai deploy key khusus repository, bukan token pribadi pengguna.

Referensi Dave the Diver digunakan sebagai moodboard privat, bukan aset distribusi. Direktori `moodboard/` dan `references/private/` diabaikan Git. Kode asli mengikuti MIT; aset kreatif mengikuti ketentuan terpisah pada [LICENSE](LICENSE). Kode, fon, dan aset pihak ketiga tetap mengikuti lisensi serta atribusi masing-masing pada [THIRD_PARTY_LICENSES.md](THIRD_PARTY_LICENSES.md).
