# Diagnosis startup publik setelah cleanup

9 November 2026. Paket aktif: runtime `f4fac83dffaa1b267ae76aedfc7580b030f3be9d`, image43bd, PCK `43df70a9c86d4feafd18daed16297a6c5b2cc02582daa1ee0b4d32605f56d19e`,64.307.804byte. Health serta PCK publik cocok. Pembersihan storage selesai dan tidak menghapus asset aktif. Dokumen ini memisahkan smoke gameplay publik dari keberhasilan health/build.

## Bukti aktual

| Jalur | Hasil |
| --- | --- |
| Local browser43df | Continuation10checks/305surfacePOST200/0error, cleanuptrue; lima dialog sisa dan permit sebenarnya |
| Default public Chromium | UUIDce0c4fb0-e7b4-42c0-b7a5-e0e35a2df48e: attach timeout240detik, loader57%/60,1MB dari103,8MB,0console/APIerror,fixturecleanuptrue. Hanyahealth/hash diterima, bukan gameplay |
| Default public CDP trace | WASM200/H2 selesai102,7detik; PCK200/H2 masih3,37MB setelah110detik. Tidak ada bodyreject/loadingFailed pada dua asset ini sebelum batas120detik. Fixture dibersihkan |
| Public curl H2 | Remote45.198.149.181:443; WASM gzip10.054.758byte/0,608detik; PCK64.307.804byte/1,616detik. Ini bukan pengukuran browser |
| Chromium `--disable-http2` diagnostik | RemoteIP sama, PCKhttp/1.1 selesai2,801detik; WASM selesai57,927detik; game ready/HUD/snapshot nyata sekitar70detik. Rute diagnostik mencapai hutan dengan407matrixpulse; berhenti pada assertion reveal target lama350,1250. Dua checks selesai,0console/APIerror,fixturecleanuptrue. Bukan smoke penuh yang lulus |

HTTP1 diagnostik tidak mengubah proxy atau membuktikan browser default lulus. COI/SABfalse terjadi ketika game berhasil ready pada export single-thread, sehingga nilainya sendiri tidak membuktikan kegagalan startup. Total103.822.558byte adalah decoded WASM39.514.754+PCK64.307.804, bukan total wire compressed. Angka progress tidak diubah untuk menyembunyikan download.

## Pemeriksaan proxy read-only

Hostmoodle-server, live public master `/www/server/nginx/sbin/nginx -c /www/server/nginx/conf/nginx.conf`. Hanya file domain diketahui serta include relevan dibaca; tidak ada `nginx -T` yang membocorkan seluruh konfigurasi, perubahan atau reload.

Vhost `/www/server/panel/vhost/nginx/staging-jalasmara.ardianryan.com.conf`, SHA `a11d4e298f74ce38c835050d70f30817960b74571b9fa07c61f100409ae84c96`: frontend443 ssl http2; upstreamHTTP1.1 ke10.1.0.8:3000; connect60/send600/read600detik. Tidak ditemukan rate limit atau kondisi User-Agent aktif pada file yang diperiksa. Global hanya mendefinisikan limit_conn zone, bukan penerapan domain ini. Buffer proxy32k/4×64k/busy128k/tempwrite128k dan proxy_cache cache_one tercatat; ini belum membuktikan penyebab perlambatan. File di disk juga bukan bukti generasi konfigurasi yang sedang loaded.

[Operasi proyek](../operations.md) menjaga proxy aaPanel terpisah dari deployment aplikasi. Tidak ada perubahan proxy/firewall/service untuk diagnosis ini. Jangan menonaktifkan flag listenHTTP2 secara sembarang pada socket443 bersama. [Dokumentasi resmi nginx](https://nginx.org/en/docs/http/ngx_http_v2_module.html#http2) menyatakan directive `http2 on|off` tersedia sejak1.25.1 pada kontekshttp/server; Binary live melaporkannginx/1.24.0, sehingga directive per-server itu tidak didukung versi standar terpasang. Backport belum dibuktikan. Jangan memasukkannya atau mengubahlisten bersama tanpa kajian dampak. Belum ada candidate config yang diuji atau diterapkan.

## Celah loader terpisah

Reviewer menemukan getTrackedResponse pada Preloader export Godot tidak meneruskan penolakan reader.read ke controller.error. Repro CPU memakai classPreloader aktual: stream normal4byte selesai; stream4byte lalu gagal menyebabkan promisepending500ms, satu unhandledRejection danfetchCalls1/tanpa retry. Publicindex.js byte-identik lokal. Ini celah penanganan error yang nyata, **bukan penyebab insiden H2 yang sudah dibuktikan**: trace saat ini justru memperlihatkan body terus berjalan dan tidak rejected.

[Helper export-time](06p-preloader-stream-errors.md) selesai sebagai kandidat `8833185` terisolasi dari main,10tes CPU lulus dan diulang integrator. Belum digabung/export/browser/dirilis. RawWASM juga mempunyai jalur promise Engine.init/instantiateStreaming lain; jangan mengklaim hardeningPCK otomatis memperbaiki seluruh errorWASM. Tidak ada patch runtime/generatedexport baru atau generator aset dalam paket aktif ini.

## Tindak lanjut

Rute HTTP1 UUID73395c21-276c-40ad-acbe-d0f9238d7e59 sudah berhenti dan fixture dibersihkan. Integrator meninjau failure.png: Nala terlihat di jalur tanpa tertutup kanopi. Nilai reveal0 pada target lama tidak membuktikan produk cutaway rusak; target assertion harus diturunkan dari proyeksi kamera kiri dan titik lantai yang dapat dicapai, bukan dihapus atau dilemahkan. Touch/save checks sesudahnya belum dijalankan.

Simpan trace tersanitasi dan perbaiki sasaran harness dengan bukti aktual, lalu lakukan perbandingan browser default dengan kondisi transport/perangkat yang sama sebelum menerima startup publik. Evaluasi hardening loader secara terpisah dengan error/retry tests dan export/browser baru. Alignment rumah layout10, restart Nala serta FPSperangkat tetap terbuka; jangan menggabungkannya untuk menyamarkan blocker startup.

Tool aktual: Playwright/Chromium+CDP, Node/Python, curl, SSHread-only, source export Godot4.7.2 dan dokumentasi resmi nginx. Tidak ada plugin/dependency baru, ownerfixture, proxyedit atau perubahan volume.

Status akhir sesi: semua browser/engine sudah dilepas. Perubahan HTTP1 hanya flag diagnostik Chromium; proxy, firewall, upstream dan runtime43df tidak diubah. Hasil yang gagal tetap gagal walaupun array errorAPI kosong.
