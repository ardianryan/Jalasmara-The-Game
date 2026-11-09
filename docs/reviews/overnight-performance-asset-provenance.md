# Identitas aset pada laporan performa perangkat

Source lokal, belum diekspor atau dirilis. Laporan perangkat sebelumnya tidak diberi identitas secara retroaktif. [Peer desain dan kasus batas](overnight-performance-provenance-peer.md) serta lima tes independen menangkap masalah nyata sebelum perubahan ditutup.

Laporan JSON sebelumnya menyimpan perangkat/profil/metrik, tetapi tidak mengikatnya pada paket game yang selesai dimuat. Loader sekarang menyalin dan membekukan manifest yang telah divalidasi, lalu menyediakan identitas melalui getter read-only setelah seluruh bagian telah lolos hash dan diteruskan berurutan ke konsumen. Objek berisi schema1, SHA paket dari manifest, ukuran, jumlah bagian dan `all-parts-verified-manifest`. Ini bukan penghitungan ulang hash seluruh file, bukti Godot READY, tanda tangan atau attestasi keamanan. Tidak ada request tambahan, perubahan byte PCK, concurrency4, timeout30detik, retry, progress maupun jalur WASM.

Partial read/cancel, error, atau prefetch yang belum diteruskan tidak menerbitkan identitas. Generation guard mencegah stream lama mengisi identitas setelah upaya baru dimulai. Getter/objek membantu mencegah mutasi tidak sengaja; bukan perlindungan terhadap JavaScript same-origin yang bermusuhan. Target yang tidak dapat diperluas atau menolak property tetap dapat menerima seluruh gamebytes tanpa metadata.

Perekam menyalin hanya lima primitive yang lolos validasi, sekali pada awal dan akhir. Getter berubah/throw tidak dapat menyelundupkan nilai yang belum divalidasi atau data akun. Blok tambahan `assetProvenance` mempertahankan schema1 dan semantik metrik lama: `unavailable`, `incomplete`, `changed`, `changed-document` atau `unchanged-loader-pin`. Tidak ada fallback ke versi host, manifest terpisah, API atau laporan lama. URL/dokumen tidak diekspor. READY tetap prasyarat terpisah pada alur rekaman sebenarnya.

Identitas dokumen iframe dibandingkan secara internal. Bila dokumen berganti, callback frame/sampel berhenti sebelum mencampur metrik; pembatalan handle lama yang melempar tidak boleh mencegah pembersihan timer atau penyelesaian laporan. Peer mereproduksi kegagalan ini terhadap implementasi awal, lalu perbaikannya lulus tes permanen. Kasus ini bukan klaim bahwa game publik sekarang berpindah ke origin lain.

## Verifikasi source lokal

- 28tes stream/preloader/fault PASS, termasuk lima tes identitas baru dan actual pinned Godot preloader fixture dengan getter yang benar. Manifest caller yang diubah tidak lagi dapat mengganti pin atau hash bagian setelah adapter dibuat.
- 31tes performa CPU PASS, termasuk tujuh sanitizer/recorder boundary baru. Lima di antaranya ditulis peer dan dijalankan lagi di root: getter tidak stabil, metadata throw/rusak, stop setelah pergantian origin serta pencegahan frame/sampel dokumen baru.
- Typecheck API/web PASS. Vite6.4.5 build di memori `write:false` PASS,47modules/63output assets; dist/preview aktif tidak ditulis. Tidak ada klaim pengurangan payload atau peningkatan FPS dari penambahan provenance.
- Tes identitas stream terdaftar di CI; seluruh tes performa sudah termasuk glob existing. Tidak ada job CI baru yang dinyatakan PASS dan tidak ada perubahan runner/GitLab CE.

Log `.runtime/overnight-pck-provenance-tests.log`, `overnight-performance-provenance-all-tests.log`, `overnight-performance-provenance-typecheck.log`, `overnight-performance-provenance-web-build.log/json`. Kode original proyek memakai Web Streams/Node/TypeScript existing tanpa dependency atau lisensi baru. Berikutnya: satu ekspor koheren, actual startup/bilik dengan node nyata dan actual30detik rekaman UI pada hash baru; baru pertimbangkan rilis. Pengujian Windows/S23 fisik tetap membutuhkan hasil pengguna yang sudah bersedia membantu.
