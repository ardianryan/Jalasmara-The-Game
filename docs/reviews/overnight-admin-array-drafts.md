# Draft array JSON pada editor pengelola

Status: **penerimaan browser lokal lulus 35/35** pada 10 November 2026 WIB. Source kandidat website belum dinyatakan dirilis. Tidak ada perubahan Godot, PCK, API, schema atau data pengelola.

## Masalah yang ditemukan

Pada `apps/web/src/admin.tsx`, kolom array `prices`, `values` dan `starMultipliers` semula memakai input uncontrolled dan baru mem-parsing JSON saat blur. Teks invalid hanya memanggil `setCustomValidity`/`reportValidity`; nilai catalog tetap lama dan `dirty` tidak berubah. Tombol Simpan/Tinjau berada di luar form dan handler tidak memeriksa validitas input. Karena itu validitas native input tidak melindungi aksi tersebut.

Reproduksi berdasarkan source: buka draft tersimpan, ketik `[0,` pada Harga per level, lalu isi alasan. Tinjau publikasi tetap dapat dibuka memakai catalog lama; jika sebelumnya ada perubahan field biasa, Simpan dapat mengirim perubahan itu bersama array lama. Bila hanya raw JSON invalid yang diketik, guard navigasi juga belum terdaftar. Bukti browser terhadap versi sebelum perbaikan belum dijalankan, sehingga laporan ini tidak mengklaim reproduksi browser lama.

## Perubahan

Raw JSON disimpan dalam state editor per kategori, indeks record dan nama field. Ketikan langsung menandai perubahan belum disimpan. JSON valid memperbarui catalog; JSON invalid mempertahankan teks dan menampilkan pesan di kolom dengan `aria-invalid`/`aria-describedby`. Berpindah record/kategori dan membatalkan navigasi tidak membuang raw draft. Simpan/Tinjau diblokir oleh tombol dan handler selama masih ada array invalid, termasuk pada record lain. Penghapusan record tidak boleh menggeser indeks buffer invalid. Setelah penyimpanan valid berhasil atau discard dikonfirmasi, buffer dibersihkan bersama dirty guard.

Editor dinonaktifkan selama request simpan agar respons tidak menimpa ketikan baru. Otoritas validasi schema/publikasi server tetap berlaku.

## Verifikasi

- `npm run typecheck`: lulus.
- `node --check scripts/website06-browser.mjs`: lulus.
- `npm run build -w @jalasmara/web` di worktree sendiri: lulus (Vite 6.4.5, 45 modul, 901 ms). `git diff --check`: lulus. Host/API preview 3111 tidak diubah.
- Harness `scripts/website06-browser.mjs` ditambah fixture dua kemampuan dan balance, serta assertion pada React UI sebenarnya: invalid raw saja mengaktifkan guard; kontrol dinonaktifkan dan Enter pada kolom invalid tidak menghasilkan request; raw dua record bertahan lintas kategori; satu array yang sudah diperbaiki tidak membuka Simpan selama record lain invalid; Enter pada Simpan sesudah semua valid mengirim persis array hasil perbaikan. Rute API diintersep fixture lokal; bukan transaksi server atau data owner.

Langkah berikutnya: integrator meninjau lalu menggabungkan source dan laporan ini. Tidak diperlukan export PCK untuk perubahan website. Transaksi admin server nyata dan perangkat fisik tidak termasuk pengujian fixture ini.


Peer-review follow-up: confirmed question import now clears only `questions:` buffers; other-category raw drafts remain protected. Export checks invalid raw buffers for its own question category before serializing. Current production Question has only the special controlled `options` array, so a `questions:` JSON buffer is not presently reachable through the production schema; no fictitious question field was added to fabricate that state. The prepared browser fixture instead checks real question import/cancel/confirm/export and preservation of a simultaneously invalid ability draft. It is an intercepted API/UI test, not proof of server schema acceptance.

CPU review caught and removed an invalid test technique before execution: clearing the DOM `disabled` attribute does not bypass React's disabled-prop click filtering. The harness now uses real keyboard/field interaction and verifies no write or publish modal while invalid; handler guards are source-reviewed defense, not a claimed dynamically invoked branch. No React internals or production QA API were introduced for this assertion.


## Penerimaan browser aktual

Source `5b3dbc4` + `e31f5a2` + `04f506e` beserta class error khusus diuji melalui build produksi worktree sendiri pada Vite preview `http://localhost:5176`. Perintah: `WEBSITE_TEST_ORIGIN=http://localhost:5176 node scripts/website06-browser.mjs`. Seluruh `/api/**` diintersep fixture, aset game diblokir; tidak ada akun nyata, koneksi Mongo/Redis, Godot, atau perubahan preview game 3111.

Hasil akhir **35 checks lulus, 0 JavaScript errors**. Viewport 1440×900, 667×375, 390×844 dan 320×740 tidak melebar di luar layar. Pemeriksaan lama tetap lulus: pencarian dari halaman kedua, respons filter terlambat, error/retry daftar, fokus setelah Escape, dirty guard/discard, akun/error logout, token reset/aktivasi hilang, dan batas role pemain. Regresi baru benar-benar menjalankan UI React: Enter saat JSON invalid tidak mengirim request; Simpan/Tinjau disabled; raw dua record bertahan lintas kategori dan navigasi yang dibatalkan; perbaikan satu record tidak membolehkan save selagi record lain invalid; keyboard Enter sesudah valid mengirim tepat tiga array hasil perbaikan. Import yang dibatalkan mempertahankan soal; import yang dikonfirmasi menampilkan opsi baru, mempertahankan raw invalid kemampuan, dan ekspor JSON unduhan cocok persis dengan soal impor.

Run pertama dev-server berhenti pada assertion font sebelum pengujian admin baru: `node_modules` symlink berada di luar Vite dev `fs.allow`, sehingga file font diblokir. Log `.runtime/overnight-admin-vite.log` dan `.runtime/overnight-admin-browser.log` dipertahankan; ini bukan kegagalan font pada build produksi. Tidak ada pengurangan assertion font. Host sendiri diganti Vite production preview; run berikutnya lulus 35/35.

Review PNG run tersebut menemukan baris pertama error inline terlalu dekat dengan outline fokus. Perbaikan hanya `.content-editor .array-field-error`: margin atas 8px, warna danger, font weight600; global focus tidak berubah. Run akhir mengulang seluruh 35 check, menambahkan assertion jarak aktual error ke input ≥8px pada desktop dan 390. Kedua PNG akhir sudah dilihat: pesan terbaca dan tidak menimpa bingkai fokus. Komponen yang diperiksa berupa fixture website, bukan UI game atau bukti performa perangkat fisik.

Bukti di worktree `Jalasmara-overnight-hud-perf`:

- Log final `.runtime/overnight-admin-browser-final.log`; build `.runtime/overnight-admin-web-build-final.log` (Vite6.4.5, 45modul,544ms).
- `artifacts/browser/website06/results.json` SHA256 `0b6828afb64d4cf7a82c6bce21cee548acbca4fa14c0290d835cc2bb73a34095`.
- `artifacts/browser/website06/admin-invalid-json-desktop.png` SHA256 `9fdb3e3726ac1ca092454505cdf1d0dbb4bbb20e54bb7b7463a1fc467775d684`.
- `artifacts/browser/website06/admin-invalid-json-mobile.png` SHA256 `18abc5918de3b7c5ca277c8933498e7a3740001beda6e21200a3df150f6b9940`.
- `imported-questions-export.json` memuat soal fixture saja. Screenshot login/settings/admin semua viewport tersedia di direktori yang sama.

Browser/context ditutup melalui `finally` pada setiap run, slot GPU dilepas sesudah run akhir. Server preview sendiri dihentikan setelah bukti diperiksa; server 3111 dan data owner tetap tidak disentuh. Tidak ada dependency/aset baru atau perubahan lisensi.
