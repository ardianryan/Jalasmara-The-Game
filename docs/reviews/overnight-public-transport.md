# Overnight: pengiriman aset publik

Baseline tetap source `b5b459ea448bc8799bebb771e56df20ce5e8f039`, image `d60aab21ec405f85cd3c35b7c1cecd70b331142e280953364aa00de7f3e3e81b`, PCK `5f5baf243a3bf941cf34fab6c143bb9cf2bc8d65997ded6ed4e048b929353f96` (64.333.184 byte). Percobaan berikut adalah diagnosis transfer, bukan penerimaan gameplay.

## Hasil serial dan batasnya

| Percobaan | Hasil aktual |
| --- | --- |
| Curl biasa, identity, dua pengulangan | PCK lengkap 1,623 dan 1,365 detik |
| Curl dengan header browser/encoding yang diuji terpisah | Empat percobaan tidak selesai dalam batas 6 detik; HTTP200, panjang dan ETag sama |
| HTTPS loopback proxy, UA browser | PCK lengkap 0,590 detik; konfigurasi proxy tidak diubah |
| Browser Range `bytes=0-` | HTTP200; 1.948.135 byte dalam 20,006 detik, lalu pembatalan terencana |
| Browser PCK precompressed gzip | HTTP200/H2; 3.151.209 byte decoded dalam 20,008 detik, lalu pembatalan terencana. CDP encoded 3.115.652 byte |
| Range origin `0-1023` dari proxy | HTTP206, 1.024 byte dalam 0,004245 detik |
| Curl publik Range dengan query diagnostik | HTTP200 dan seluruh64.333.184 byte dalam 1,778 detik; bukan206. Percobaan tanpaquery sebelumnya timeout5detik tanpaheaders |

Variasi ini belum mengidentifikasi sebab. Hasil origin tidak membuktikan kecepatan internet klien. Range publik tidak memberi respons parsial pada pengamatan ini, sehingga tidak dipakai untuk mengimplementasikan unduhan potongan. Perbandingan UA/encoding bukan bukti adanya aturan UA pada aplikasi. Data startup default yang gagal tetap berada pada [laporan sebelumnya](06p-public-default-5f5-result.md).

## A/B gzip dibatalkan

Gzip dibuat dari PCK rilis yang sama, tanpa perubahan game, API, loader atau proxy. Gzip63.549.366 byte, SHA `c7e7d1fb18f36b950cba6b940da6cb1f1f97b5cb7622161a634e9930bdc5c804`; dekompresi pada lokal dan image sama-sama menghasilkan SHA5f5baf dan64.333.184 byte. Image diagnostik `1c01133752b9202bec83ae5df007d3a354866e32b7bb078cc057429a8fde079c` hanya menambah berkas `.gz` ke image rilis. Negosiasi `Content-Encoding:gzip` benar, tetapi browser tetap lambat. Tidak ada dasar untuk mengubah kebijakan ekspor demi hasil ini.

Aktivasi menggunakan compose `--no-build --no-deps app` dan selalu dikembalikan melalui blok `finally`. Sesudah percobaan, image d60aab21 aktif dan healthy; Mongo/Redis tidak direcreate, `.env`, volume dan konfigurasi proxy tetap. Semua browser ditutup, tidak ada fixture akun dibuat. Image diagnostik, layer perantaranya dan direktori transfer sementara dibuang setelah rollback; image aktif dan rollback43bd232 tetap. Prune image melaporkan63,58MB; ruang bebas VPS sesudahnya44.046.753.792 byte, bukan penjumlahan ukuran image bersama.

Bukti lokal: `.runtime/overnight-transfer-probes.json`, `overnight-proxy-loopback.jsonl`, `transport-gzip-manifest.json`, `transport-gzip-ab-result.json`, `transport-gzip-browser.log`, `transport-origin-range.json`; browser Range `artifacts/browser/transport-pck-e8444e70-e52c-4e9a-923a-b8c1249a8f74/results.json`, gzip `artifacts/browser/transport-pck-a898aeb1-07b8-40a0-9610-2ea56684b292/results.json`. Kegagalan/batas tidak dihapus dari bukti.

## Followup browser protokol dan buffering

Browser Chromium dengan flag diagnostik `--disable-http2` menyelesaikan64.333.184byte dalam1,606detik, CDP mengonfirmasi `http/1.1`, tanpa cache/serviceworker. Artefak `transport-pck-89471e15-f707-4529-948f-b0855fbba317`. Browser default setelahnya tetapH2 dan terhenti pada batas20detik dengan21.346.827decodedbyte (`transport-pck-6107836c-a863-4a9b-8f66-65c60c1bad7e`). Percobaan keduaH2 ini lebih cepat daripadaH2 sebelumnya, sehingga variasi throughput tetap nyata. Perbandingan ini menunjukkan perbedaan delivery protokol pada jalur pengujian; belum mengisolasi akar konfigurasi/TCP atau membuktikan bahwa pengguna lain mendapat hasil sama. Flag hanya pada harness diagnostik, tidak pada produk.

[Dokumentasi NGINX](https://nginx.org/en/docs/http/ngx_http_proxy_module.html#proxy_buffering) menjelaskan header respons `X-Accel-Buffering`. A/B kedua menambah header`no` hanya padaPCK melalui callback Fastify static, tanpa mengubah proxy. TesAPI tambahan memverifikasi byte identity/gzip,206range/HEAD dan isolasi respons lain; lulus. Image `f6357133e502cc13c1bf7fe40f8fb002ebbe6f101e95ce62b3d1a8d1173d316d` hanya mengganti app.js dengan setterheader tersebut, baselineappSHA33ea0834→candidateef77317e. Browser default tetapH2 dan hanya13.892.758decodedbyte/20,007detik, bukan unduhan lengkap. Artefak `transport-pck-a5d20acf-1fce-43b8-82b7-8f54dae7e877`, log/manifest `.runtime/transport-buffering-*.json`/`.log`.

Header tersebut ditolak dari source produk setelah hasil ini. Tes sementara disimpan sebagai `.runtime/rejected-transport-header.test.ts`, bukan tes fitur yang dirilis. Image baseline d60aab21 dipulihkanhealthy melalui`finally`; image diagnostik/layer/direktori sementara dibuang,15,54KB dilaporkan prune. Proxy tidak diubah atau direload. Tidak ada alasan menerapkan perubahan kualitas game, memaksa HTTP1 pada pengguna, atau menyebut startup publik sudah diterima.

Gzip lokal yang sudah tidak dipakai juga dihapus setelah hash diverifikasi:63.549.366logical/63.885.312allocatedbyte; ruang bebas PC teramati12.431.413.248→12.495.282.176byte. Source ekspor aktif, manifest, laporan dan bukti tetap. `.runtime/transport-gzip-cleanup.json` menyimpan hasilnya.

Tool aktual: curl, SSH, Docker/compose, Python gzip/hashlib, Playwright/Chromium/CDP dan pembacaan source Fastify static terpasang. Tidak ada layanan berbayar, token, data akun, migrasi database atau proxy reload.
