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

Berikutnya: satu perbandingan browser HTTP1 diagnostik terisolasi, kemudian simpulkan batas yang terukur sebelum mengubah delivery. Ini bukan rencana mematikan HTTP2 pada browser pengguna atau proxy. [Dokumentasi NGINX](https://nginx.org/en/docs/http/ngx_http_proxy_module.html#proxy_buffering) menjelaskan buffering dan header respons `X-Accel-Buffering`; pemeriksaan source ini sendiri tidak membuktikan buffering menyebabkan masalah dan belum diterapkan.

Tool aktual: curl, SSH, Docker/compose, Python gzip/hashlib, Playwright/Chromium/CDP dan pembacaan source Fastify static terpasang. Tidak ada layanan berbayar, token, data akun, migrasi database atau proxy reload.
