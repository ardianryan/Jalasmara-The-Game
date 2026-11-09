# Draft array JSON pada editor pengelola

Status: perbaikan source lokal dan pemeriksaan CPU selesai; penerimaan browser masih menunggu slot setelah pengujian game lane lain. Tidak ada perubahan Godot, PCK, API, schema atau data pengelola.

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
- Harness `scripts/website06-browser.mjs` ditambah fixture dua kemampuan dan balance, serta assertion pada React UI sebenarnya: invalid raw saja mengaktifkan guard; tombol dan handler sama-sama menolak request; raw dua record bertahan lintas kategori; satu array yang sudah diperbaiki tidak membuka Simpan selama record lain invalid; Enter pada Simpan sesudah semua valid mengirim persis array hasil perbaikan. Rute API diintersep fixture lokal; bukan transaksi server atau data owner.

Langkah berikutnya: setelah slot browser diberikan, jalankan host Vite lokal terpisah pada worktree ini dan `WEBSITE_TEST_ORIGIN=http://localhost:<port> node scripts/website06-browser.mjs`. Jangan membangun ulang host/API preview 3111 saat harness game lain memakainya. Simpan hasil lulus/gagal serta screenshot error/field pada laporan ini sebelum menyatakan penerimaan selesai.


Peer-review follow-up: confirmed question import now clears only `questions:` buffers; other-category raw drafts remain protected. Export checks invalid raw buffers for its own question category before serializing. Current production Question has only the special controlled `options` array, so a `questions:` JSON buffer is not presently reachable through the production schema; no fictitious question field was added to fabricate that state. The prepared browser fixture instead checks real question import/cancel/confirm/export and preservation of a simultaneously invalid ability draft. It is an intercepted API/UI test, not proof of server schema acceptance.
