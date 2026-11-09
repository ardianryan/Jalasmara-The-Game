# Perbaikan propagasi error pada stream ekspor Godot

9 November 2026. Cabang `work/06p-loader-stream-error`, worktree `Jalasmara-06-loader-stream`, basis main `2592bd8`. Ini perbaikan export-time terpisah dari pilot restart Nala. Tidak mengubah generated exports di main, menjalankan Godot/browser, atau mengganti image/PCK staging.

## Repro konkret dan batas penyebab

Ekspor Godot 4.7.2 membuat `ReadableStream` yang memanggil `onloadprogress(...).then(controller.close)` tanpa mengembalikan promise atau meneruskan kegagalan `reader.read()` ke controller. Jika body sudah mulai diterima lalu gagal dibaca, stream pembungkus tidak ditutup/error. Promise `arrayBuffer()` PCK dapat menggantung; retry/catch yang sudah ada tidak menerima kegagalannya.

Repro CPU memakai **Preloader asli** yang diekstrak dari ekspor, bukan tiruan algoritmenya: stream baik menyelesaikan 4 byte; stream dengan error sesudah chunk pertama tetap pending dan mengeluarkan satu unhandled rejection, dengan hanya satu fetch. Tes baseline menjalankan fixture asli pada child Node agar unhandled rejection yang memang sedang dibuktikan tidak mencemari proses test runner.

Ini **bukan penetapan penyebab** loader publik 57%. Website lane sedang mencatat transfer CDP; temuan awal justru menunjukkan data H2 masih bergerak tanpa body rejection. Root `curl` yang cepat, tracing browser yang lambat, compression dan multiplexing perlu dibandingkan sebagai bukti insiden terpisah. Tidak ada klaim patch ini menyelesaikan kecepatan download atau semua kegagalan startup.

## Perubahan terbatas

- `scripts/godot-preloader-stream.mjs` mengembalikan promise pembacaan dan meneruskan error lewat `controller.error(error)`. PCK `arrayBuffer()` lalu menolak sehingga retry/catch existing bekerja.
- Helper hanya menerima Preloader Godot 4.7.2 dengan hash source `5205574baa83a992d8fcc4e18e753f1fea2f37d0386d6863756e0f42719562bf`. Pattern harus muncul sekali; duplikat, perubahan pola atau perubahan implementasi lain membuat export gagal. Patch deterministik dan idempotent, dengan normalisasi patch balik untuk memeriksa hash saat dipanggil ulang.
- Exporter aktual `scripts/export-game.mjs` menjalankan helper setelah export/HTML bridge dan **sebelum gzip**, sehingga JS serta salinan gzip berasal dari kode yang sama. PCK/WASM, body bytes, header response, fileSizes dan phase host tidak diubah helper.
- `.gitlab-ci.yml` menambahkan tes CPU pada baris loading-bridge existing. Tidak ada dependency atau proses engine baru untuk tes ini.

Budget tetap empat fetch dan backoff 1000 ms. Tes memajukan backoff lewat microtask sambil memeriksa nilai 1000 ms yang dijadwalkan; tidak menambah retry baru. Raw WASM masih mengembalikan Response sebelum body dibaca. Patch memastikan consumer body itu mendapat error, tetapi tidak mengubah jalur raw menjadi retry otomatis. Upstream `Engine.init`/instantiateStreaming mempunyai alur penerusan rejection tersendiri yang **belum ditangani** oleh perubahan kecil ini; jangan menyebut seluruh startup WASM sudah mempunyai recovery.

## Pemeriksaan CPU

```sh
node --test scripts/godot-preloader-stream.test.mjs scripts/game-loading-bridge.test.mjs
node --check scripts/export-game.mjs
git diff --check
```

Hasil aktual: **10 tes PASS**, nol gagal; syntax exporter dan diff check lulus. Tes mencakup baseline asli yang menggantung, stream sukses/progress decoded bytes/header raw tetap, satu kegagalan parsial lalu sukses dengan hanya bytes attempt terakhir, empat kegagalan parsial yang menolak tanpa menggantung, raw Response yang menolak consumernya, serta deterministik/idempotent/unknown-source guard. Loading bridge host yang lama ikut diperiksa. Helper juga diterapkan pada seluruh export `index.js` root **hanya di memori**: guard/idempotence lulus, 279.815 → 279.878 byte, lalu dibuktikan berkas generated asli tetap identik. Tidak ada compile WASM, frame native, browser, FPS atau hasil deployment yang diwakili tes CPU ini.

Fixture `scripts/fixtures/godot-4.7.2-preloader.js` adalah salinan exact Preloader dari installed Web export. Whole export `index.js` yang diperiksa lokal dan publik identik, SHA256 `33c94cb3175f3333b82e2a3be5e8e86f77986f0aa2042b1631f6367a4e5bb6ba`. Copyright Godot Engine contributors/Juan Linietsky/Ariel Manzur dan SPDX MIT dicantumkan; teks MIT Godot existing tersedia pada [THIRD_PARTY_LICENSES.md](../../THIRD_PARTY_LICENSES.md). Tidak ada runtime library atau aset baru.

Tool aktual: Node.js built-ins untuk fixture streams/VM/child process, Python untuk mengekstrak source yang sudah tersedia, Git dan `apply_patch`. Header/hash publik diperiksa melalui HTTP read-only; tidak membaca kredensial atau mengubah proxy, cache, runtime generated file, service maupun data. Integrator meninjau kandidat source dan menentukan pemeriksaan export/runtime berikutnya.

Checkpoint integrator: kandidat source `88331854b2b6e5346902e8733a0d227c6b38e67c` tetap pada branch terpisah, **belum digabung**. Hanya laporan ini disalin ke main untuk handoff. Integrator mengulang10tes CPU dan semuanya lulus; tidak menjalankan export/browser untuk kandidat.
