# 06-D: ketahanan formulir akun dan pengelola

Tanggal: 9 November 2026. Baseline: `1f097cc`. Jalur ini memperbaiki website yang mengelilingi permainan. Renderer, HUD, pengunduhan aset, API, data akun, dan kontrak progres tidak diubah.

## Masalah dan perubahan

| Temuan pada source | Perilaku sesudah perubahan |
| --- | --- |
| Pencarian pada halaman kedua memanggil pemuat dengan nomor halaman lama, kemudian efek memuat ulang. Respons lama dapat menimpa hasil filter terbaru. | Teks pencarian yang sudah diajukan menjadi bagian query bersama halaman dan status. Pencarian baru meminta halaman pertama sekali. Nomor urut permintaan menolak hasil dan kesalahan dari permintaan yang sudah digantikan. |
| Daftar kosong muncul sebelum respons pertama, sedangkan kegagalan pemuatan tidak mempunyai pemulihan khusus daftar. | Status pemuatan dan status kosong dibedakan. Kegagalan mempunyai tombol Muat ulang pemain; tombol baris dan pagination menunggu pemuatan selesai. |
| Berpindah tab pengelola membuang perubahan draft tanpa bertanya. | Pindah tab meminta konfirmasi bila ada perubahan. Pembatalan mempertahankan isi dan tab. Navigasi keluar menggunakan perlindungan `beforeunload`; persetujuan membuang draft membersihkan status perubahan. |
| Halaman reset/aktivasi tanpa token tetap menawarkan formulir yang tidak dapat diselesaikan. | Halaman menjelaskan bahwa tautan tidak lengkap dan meminta pengguna membuka tautan pengelola atau meminta tautan baru. Formulir tidak ditampilkan tanpa token. Token tetap dibersihkan dari address bar oleh alur lama. |
| Kesalahan keluar akun pada header tidak ditangani; pesan sukses konfirmasi password dapat tetap tampil bersama kegagalan melepas identitas. | Header menampilkan kesalahan dan menyediakan percobaan ulang. Operasi akun membersihkan pesan lama sebelum memulai; state sibuk diumumkan oleh formulir. |
| Identitas panjang dapat memaksa lebar halaman; tautan navigasi website terlalu pendek sebagai sasaran sentuh. | Nama/email pada akun, sidebar, dan judul pengelola dapat membungkus. Navigasi mempunyai tinggi minimal 44 CSS px dan membungkus pada layar sempit. Tabel tetap mempunyai gulir internal dengan nama region, fokus keyboard, dan indikator fokus. |
| Dialog memakai satu ID judul tetap dan callback Escape dari render awal. | Judul memakai ID React yang unik. Escape membaca callback terbaru dan penutupan mengembalikan fokus ke elemen pemicu yang masih terpasang. |

Perubahan berada pada `apps/web/src/main.tsx`, `admin.tsx`, `components.tsx`, dan CSS terkait pada `style.css`. Tidak ada pustaka, gambar, font, ikon, halaman, atau endpoint baru. Pemilihan role, konfirmasi tindakan pengelola, alasan, audit, dan pemeriksaan izin server tetap memakai alur yang tersedia.

## Arah visual

Mode antislop **DURING** mengikuti pilihan pengguna. Arah tetap Jala Muara/Bahari pada `docs/brand/identity.md`: Lora untuk nama dan judul cerita, Nunito Sans untuk bacaan/formulir, tinta dan laut untuk teks/aksi, serta kertas untuk bidang kerja. Ini penyempurnaan permukaan operasional, bukan penggantian identitas.

Dials: **ENERGY 2 / RHYTHM 2 / MOTION 1**. Fokus layar tetap formulir atau daftar yang sedang dipakai. Pemisahan ruang menandai hubungan label, masukan, tindakan, dan kesalahan. Warna laut menandai tindakan utama; fokus kuning tanah membantu navigasi keyboard. Tidak ada gerak dekoratif baru. Motif merek dan gambar pesisir yang sudah tersedia dipertahankan.

## Verifikasi dan bukti

- `npm run typecheck`: lulus pada source akhir.
- `npm run build -w @jalasmara/web`: lulus. Pengujian browser menggunakan hasil build melalui Vite preview, bukan server development yang menghalangi font dari symlink worktree.
- `node scripts/website06-browser.mjs`: **31 pemeriksaan lulus, nol kesalahan JavaScript** pada Chromium. Seluruh endpoint API diintersep fixture lokal. Tidak ada akun nyata, transaksi server, MongoDB, Redis, atau Godot yang digunakan.
- Ukuran CSS: 1440×900, 667×375, 390×844, dan 320×740. Pemuatan Nunito Sans dan Lora diperiksa sebelum capture. Tidak ada overflow dokumen pada login, akun dengan email panjang, daftar pengelola, halaman reset/aktivasi tanpa token, atau halaman akses terbatas pemain.
- Regresi perilaku: pencarian dari halaman kedua hanya meminta halaman pertama; respons filter aktif yang sengaja diperlambat tidak menimpa filter diblokir yang lebih baru; pemuatan awal tidak menampilkan pesan kosong; kegagalan daftar dapat diulang; hasil kosong sah tetap ditampilkan; dialog Escape memulihkan fokus; pembatalan pindah tab mempertahankan draft; persetujuan pindah tab membuangnya; kesalahan akun/logout dapat dipulihkan; pemain tidak memperoleh antarmuka pengelola.
- Bukti lokal: `artifacts/browser/website06/results.json` dan 12 PNG `admin-*`, `settings-*`, `login-*`. Capture 390 px dan 320 px serta desktop diperiksa langsung. PNG tidak dimasukkan ke Git.
- Pasangan warna datar diperiksa memakai `antislop-human/contrast-check.py`: tinta/kertas **10,82:1**, teks sekunder/putih **6,06:1**, kesalahan/latar kesalahan **6,11:1**, dan putih/tombol laut **8,52:1**. Ini pengukuran pasangan warna UI, bukan audit setiap piksel ilustrasi login.

Harness dapat dijalankan terhadap server lokal melalui `WEBSITE_TEST_ORIGIN`. Ia menolak hostname nonlokal dan memblokir URL paket game. Semua fixture hidup di memori browser dan dibuang ketika context ditutup, sehingga tidak memerlukan pembersihan database atau kredensial pengelola.

## Delivery gate antislop

- **Hard Gate PASS:** tidak menambahkan aset atau klaim; halaman baru tidak dibuat; 31 pemeriksaan mencakup state sibuk, kosong, gagal, pemulihan, role, fokus dan empat viewport. Tidak ada overflow dokumen atau kesalahan JavaScript pada pengujian tersebut. Kontrol yang diubah mempunyai handler nyata dan pasangan warna datarnya melewati AA.
- **Purpose-Gate PASS:** area fokus kuning tanah membuat tabel dapat dikenali saat digulir dengan keyboard; wrapping mencegah identitas panjang mengubah lebar halaman; tinggi navigasi membantu sasaran sentuh. Tidak ada gradient, glow, dekorasi ikon, atau animasi baru.
- **Liveliness PASS:** arah Bahari dan dials dinyatakan di atas; brand Lora, tinta/laut, bidang kertas, dan ilustrasi pesisir tetap memberi identitas tanpa menambah dekorasi pada tugas pengelolaan.
- **Craftsmanship PASS:** typecheck, build, inspeksi capture, dan regresi interaksi sudah dijalankan. Input login dipertahankan saat gagal, draft bertahan saat perpindahan dibatalkan, serta daftar mempunyai state dan pemulihan yang berbeda.

## Batas penerimaan

Ini paket ketahanan website 06-D, bukan penerimaan seluruh backlog website. Pengujian menggunakan viewport emulasi dan API fixture; ia tidak membuktikan OIDC provider, pengiriman undangan/reset, mutasi pemain, publikasi konten, pembaca layar menyeluruh, atau perangkat Windows/S23 fisik. Dialog konfirmasi browser untuk menutup tab belum diuji terpisah. Pengelolaan konten dan data nyata tetap memerlukan regresi integrasi pada kandidat gabungan sebelum rilis.

## Verifikasi kandidat gabungan

Putaran ulang memakai build production pada worktree integrasi: mulai pada `3dd715d`, selesai pada `e27d613`. Commit di antaranya hanya menambahkan shelter; diff `apps/web/src` dan harness website kosong. Build berhasil dan harness terbaru lulus **32 pemeriksaan, nol kesalahan JavaScript** pada empat ukuran yang sama, dengan 12 PNG baru serta `results.json` pada `Jalasmara-06-integration/artifacts/browser/website06`.

Pemeriksaan tambahan membuktikan draft yang berubah mendaftarkan penjagaan `beforeunload`. Setelah tombol **Kembali ke versi** dan konfirmasi buang perubahan, daftar versi muncul dan penjagaan itu sudah hilang. Pengujian penjagaan memakai event cancelable sintetis, sedangkan dialog konfirmasi pembuangan draft merupakan dialog browser yang sebenarnya. Tidak menyamakan ini dengan pengujian menutup tab fisik.

Identitas build yang diuji: JavaScript `index-3BEtAxmh.js`, SHA-256 `35c28912572d2f25a12690be297f9a96790d6161573f7009e5341124f01ca10b`; CSS `index-D7EtCQ2g.css`, SHA-256 `063d234774eaf3f16a51a0bee07b5e7edf1729cf9cec96e588525a05ec61d056`. Capture pengelola 390 px diinspeksi ulang. Tidak ada kegagalan yang memerlukan perubahan source. Browser dan server preview ditutup setelah pengujian.
