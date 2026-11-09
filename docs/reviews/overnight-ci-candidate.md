# Pemeriksaan CI kandidat overnight

Pipeline GitLab `3046248726`, branch `work/overnight-integration`, source5489bf4, gagal pada jobverify17871870447. Typecheck serta24tes performa CPU sebelumnya lulus di CI; tahap Godot/build/CodeQL belum berjalan. Jangan menyebut pipeline ini lulus.

Penyebab terukur: Pillow9.4.0 Debian memerlukan tuple untuk parameter `dest` pada `Image.alpha_composite`, sedangkan tes reproduksi piksel mengirim list dari metadata JSON. Pillow11.3.0 lokal menerima bentuk tersebut. Generator dan pemeriksaan kesamaan atlas runtime sudah lewat; kegagalan berada pada pemanggilan rekonstruksi dalam tes. Perbaikan hanya mengubah `bounds[:2]` menjadi `tuple(bounds[:2])`.

Root membuat environment sementara Python3.11/Pillow9.4.0 dan menjalankan tes asli:1tes lulus,6orang/84bagian, rekonstruksiRGBA dan metadata sama dengan runtime. Pillow11.3.0 juga lulus. Hash PNG terkompresi9.4 `1cd41135…` berbeda dari11.3 `34c0612c…`, tetapi piksel RGBA dan metadata identik; tes tetap memeriksa keduanya dan determinisme dua build dalam versi yang sama. Tidak mengganti artwork runtime, dependency produk, atau PCK1315f346.

Bukti: `.runtime/overnight-ci-verify-17871870447.log`, `overnight-pillow94-test.log` dan `overnight-pillow113-test.log`. Environment sementara dan bytecode buatan tes dihapus sesudah verifikasi; log dipertahankan. Pipeline berikutnya masih menunggu push/periksa hasil aktual.
