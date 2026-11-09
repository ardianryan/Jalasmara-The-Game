# Unduhan PCK bertahap: hasil publik dan kandidat produksi

PCK baseline yang sama berhasil diunduh utuh melalui62respons1MiB pada browser Chromium default:64.333.184byte dalam1.545,5ms, SHA-256 `5f5baf243a3bf941cf34fab6c143bb9cf2bc8d65997ded6ed4e048b929353f96`. Seluruh respons memakaiHTTP/2, HTTP200, IP45.198.149.181 dan bukan diskcache. Konteks baru memakai layar844×390/sentuh, tanpa akun, game atau flagHTTP1. Empat permintaan paralel merakit dan menghash semua byte. Tidak ada error browser; browser ditutup.

Hasil ini membuktikan transfer aset lewat potongan pada jalur yang sebelumnya gagal menguras satu respons64MB selama20detik. Ia belum membuktikan startup Godot/gameplay atau performa Windows/S23. Penyebab rendah tingkat HTTP/2 belum dipastikan, sehingga tidak ada perubahan proxy atau klaim bahwa seluruhHTTP/2 rusak.

## Percobaan sementara dan pemulihan

Image diagnostik `74f0dce81c3a02a1ec3f013e149df027d3550ad80c222b2add13a767b18254c9` berasal dari image baseline d60 dan mengganti satu compiledapp.js untuk menambahkan route baca PCK berbatas; game, state/API gameplay dan database tetap baseline. File candidate SHA `c2a3e80532cf72f72c70dddb7d8f2d3121136d6cc2871c0896772b26732677c4`. Uji lokal sebelumnya membuktikan urutan, tail317byte, hash, penolakan indeks danHEAD. Orkestrator memakai blokfinally dan otomatis mengembalikan `jalasmara:06b2-b5b459e`, image d60, healthy. Tidak ada `.env`, volume, akun, proxy, firewall atau seed yang diubah.

Route `/__qa_pck_parts/` hanya terdapat pada image diagnostik yang kini dihapus. Direktori `/tmp/jalasmara-transport-parts-ab` juga dibuang setelah pemulihan; ruang bebas VPS44.040.187.904→44.040.282.112byte. Build aktif dan rollback tetap disimpan. Detail asli ada di `.runtime/transport-parts/{browser-result.json,ab-result.json,cleanup.json,run.log}` pada worktree integrator. Source diagnostik tetap sebagai bukti ignored, bukan endpoint produksi.

## Implementasi kandidat

Exporter menghasilkan manifest kecil dari PCK asli: ukuran, SHA seluruh file dan SHA tiap1MiB. Ia tidak menggandakan PCK atau menyimpan64file tambahan. Server memverifikasi ukuran/hash saat startup, kemudian menyediakan bagian dari file yang sama melalui `/game/pck/<sha>/<index>`. Path file tidak berasal dari input HTTP; indeks/versi dibatasi, respons maksimal1MiB dan cache immutable mengikuti hash. Export lama tanpa manifest mempertahankan jalur lama; manifest tidak cocok ditolak saat startup.

Loader Godot4.7.2 yang dipatok memakai stream khusus hanya untuk PCK origin/path yang sama. Empat bagian maksimal diprefetch, diperiksa panjang/offset/hash, lalu diteruskan berurutan ke preloader aslinya. Backpressure membatasi antrean; cancel/error membatalkan request tersisa. Timeout30detik perbagian memberi kegagalan yang dapat dicoba ulang; budget retry asli Godot tetap. WASM, font dan aset lain tetap menggunakan fetch biasa. Pelaporan loading tetap byte yang diterima preloader, bukan angka waktu buatan. Hash tiapbagian membutuhkan securecontextHTTPS/localhost.

Uji baru:12kasus client termasuk urutan respons, checksum korup, tail terputus, offset/panjang/status salah, timeout/cancel/backpressure, jalur WASM dan actual pinnedpreloader. Tujuh tes server membuktikan rekonstruksi,HEAD, invalid/staleversi serta manifest salah. Gabungan loader37kasus dan typecheck lulus. Full API kandidat **120/120 lulus**60,47detik; log `.runtime/overnight-api-segmented.log`. CI mendaftarkan suite baru. Godot/browser baru, cache/retry versi nyata dan startup publik tetap gate berikutnya; kandidat belum dirilis.

Tool: Node/TypeScript/tsx, Fastify yang sudah ada, WebCrypto/ReadableStream browser dan Playwright Chromium. Tidak ada layanan/tool pihak ketiga baru, dependensi baru, kredensial baru, atau perubahan lisensi. Lihat [diagnosis sebelumnya](overnight-public-transport.md) untuk dua A/B yang ditolak dan dipulihkan.
