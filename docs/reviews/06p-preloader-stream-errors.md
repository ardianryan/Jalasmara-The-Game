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

## Tinjauan dan integrasi lane QA, sesudah525fb6a

Atas instruksi integrator, kandidat8833185 ditinjau lagi terhadap source gabungan layout10/6. Patch diterapkan pada branch QA sebagai `cfa63de`; konflik add/add pada laporan ini diselesaikan dengan mempertahankan checkpoint historis integrator, bukan menghapusnya. Sepuluh tes CPU lama diulang dan lulus. Ini integrasi di branch QA untuk review, belum klaim merged ke main, export atau rilis baru.

Tinjauan menemukan celah WASM yang konkret pada export asli yang sama: `getModuleConfig.instantiateWasm` memanggil `instantiateStreaming(...).then(done)` tanpa handler rejection; fallback body/instantiate sama. `Engine.init` membungkus loadPromise/Godot/initFS dalam `new Promise`, tetapi semua rejection nested tidak diteruskan ke `reject`. Body raw yang sekarang benar-benar error masih dapat membuat init tetap pending dan melewati `displayFailureNotice`.

Tambahan `godot-wasm-init-errors.mjs` menjaga wrapper `new Promise` serta urutan inisialisasi upstream, termasuk komentar kompatibilitas Mono. Callback `onError` privat diteruskan dari init ke moduleconfig; jalur streaming dan arrayBuffer/instantiate mengirim error ke callback tersebut. Guard kecil menangkap exception sinkron pada clone/config/initFS dan semua nested rejection diteruskan eksplisit. Tidak ada retry WASM otomatis baru, compile fallback baru, globalunhandled handler, pergantian header/byte/progress, request tambahan atau proxy berubah. Keberhasilan tetap memanggil initFS→assignrtenv→unload→resolve seperti upstream. Dukungan Mono aktual belum diuji; mempertahankan wrapper bukan hasil tes Mono.

Dua section upstream dipatok SHA256 sebelum patch: moduleconfig `392b8a4bb75bb67e173b0f51651587e63ed814e1663a9277273108426cb9cb6c`, init `0456398333f7777e52f2accef724b3731e63bdeaed9a04afe08059653216f283`. Patch deterministik/idempotent, duplicate/missing/changedimplementation membuat export gagal. Fixture `godot-4.7.2-engine-init.js` berisi section asli dengan copyright/SPDX MIT Godot, bukan runtime engine lain. Test mengevaluasi section asli dalam NodeVM, memakai Response/ReadableStream native dan stub consumer/instantiation/initFS; tidak compile WASM atau membuka browser. Baseline child Node membuktikan source asli tetap pending setelah rawbodyreject dengan satu unhandled error. Source patch menolak kasus yang sama.

Command aktual `node --test scripts/godot-wasm-init-errors.test.mjs scripts/godot-preloader-stream.test.mjs scripts/game-loading-bridge.test.mjs` memberi **22/22 PASS**. Dua belas tes baru meliputi baseline asli, sukses streaming/fallback dengan byte/config/progress/initFS/unload tetap, body dan compile reject kedua jalur, rawload/clone/Godot async/sinkron/FS async/sinkron gagal, serta guard idempotent/unknownsource. Tidak ada unhandled error yang bocor pada test process patched. Baris CPU CI existing ditambah test baru; itu belum hasil pipeline baru. `npm run typecheck` (API+web), syntax exporter/helper dan diffcheck lulus.

Kedua helper diterapkan pada **seluruh export lokal hanya di memori**, parse `vm.Script` dan idempotence lulus. Ukuran279.815→280.127byte; SHA original tetap `33c94cb3175f3333b82e2a3be5e8e86f77986f0aa2042b1631f6367a4e5bb6ba`, hasil patched dalam memori `a72d94cabd4b5cedcf66bebd84c97b6e8c3173c6b269f2fdfa887fd47597ad05`. Berkas generated asli dibaca lagi dan terbukti tidak berubah. Exporter memasang keduanya sebelum gzip, tetapi exporter/Godot tidak dijalankan karena slot milik integrator.

Host retry existing dibaca: `retryLoading` mereset readiness/progress lalu menaikkan `attempt`, dan iframe memakai key tersebut. Karena itu rejection init dapat mencapai errornotice/retry existing tanpa menambahkan tombol/alur UI baru; penerimaan browser error/retry aktual masih wajib setelah export. RawWASM body tidak diberi empat retry PCK secara palsu. Bukti H2 publik sebelumnya tetap menunjukkan transfer lambat yang bergerak tanpa bodyreject; hardening ini **bukan bukti penyebab atau penyelesaian masalah57%**.

Tool aktual tambahan: Node26.12.1 built-ins/VM/child process, TypeScript typecheck, Git cherry-pick dan pembacaan source lokal. Tidak ada network/public rerun, Godot/browser, instalasi paket, perubahan generatedfile aktif, akun/data atau konfigurasi VPS. Integrator memegang merge/export dan grant pengujian lokal berikutnya.
