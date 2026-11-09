# Pemeriksaan CI kandidat overnight

Pipeline GitLab `3046248726`, branch `work/overnight-integration`, source5489bf4, gagal pada jobverify17871870447. Typecheck serta24tes performa CPU sebelumnya lulus di CI; tahap Godot/build/CodeQL belum berjalan. Jangan menyebut pipeline ini lulus.

Penyebab terukur: Pillow9.4.0 Debian memerlukan tuple untuk parameter `dest` pada `Image.alpha_composite`, sedangkan tes reproduksi piksel mengirim list dari metadata JSON. Pillow11.3.0 lokal menerima bentuk tersebut. Generator dan pemeriksaan kesamaan atlas runtime sudah lewat; kegagalan berada pada pemanggilan rekonstruksi dalam tes. Perbaikan hanya mengubah `bounds[:2]` menjadi `tuple(bounds[:2])`.

Root membuat environment sementara Python3.11/Pillow9.4.0 dan menjalankan tes asli:1tes lulus,6orang/84bagian, rekonstruksiRGBA dan metadata sama dengan runtime. Pillow11.3.0 juga lulus. Hash PNG terkompresi9.4 `1cd41135…` berbeda dari11.3 `34c0612c…`, tetapi piksel RGBA dan metadata identik; tes tetap memeriksa keduanya dan determinisme dua build dalam versi yang sama. Tidak mengganti artwork runtime, dependency produk, atau PCK1315f346.

Bukti: `.runtime/overnight-ci-verify-17871870447.log`, `overnight-pillow94-test.log` dan `overnight-pillow113-test.log`. Environment sementara dan bytecode buatan tes dihapus sesudah verifikasi; log dipertahankan. Pipeline berikutnya masih menunggu push/periksa hasil aktual.


## CI3046266187 lulus pada480d27d

Empat job branch (verify, godot_web, build, codeql) lulus; jobpublikasiGitHub memang hanya untukmainprotected. Artefak diunduh selektif ke `.runtime/ci-3046266187/`, tanpa mengunduh salinanPCK64MB. Dunia61/61 dan tiga auditdependency total0 terverifikasi. CI menghasilkan PCK `bd78af3fd2eec99960c073997216be5624805408c38f3ec2d20f848dfae0a1d3`/64.491.320byte; ini bukan PCKMac1315f346 yang dipakai penerimaan browser/image kandidat. Pin keduanya tetap dipisahkan.

SARIF201aturan memuat5hasil, bukan noltemuan: prior HTTP-to-file pada penulisan bukti harness, file-system-race baru pada manifest, satu unused phase recorder, dan dua unused identifier fixtureupstream. Tidak ada inputHTTP yang menentukanpathmanifest di source; lokasi rootditentukan konfigurasi deployment. Peringatanrace ditutup sebagai perbaikan pembacaan bounded, tanpa klaim eksploit publik. Manifest sekarang dibuka sekali, dibaca maksimal40KiB+1 melalui descriptor yang sama, ditutup pada semua jalur, dan hanyaENOENT mempertahankan legacy. Regresi baru membuktikan batas40KiB diterima dan bytepertama berlebih ditolak;8tesPCK dan typecheck rootlulus. Assignmentphase yang tidak dibaca dihapus dari harness; fixtureupstreamdipatok tidak diubah untuk menghilangkan notes.

Hasil CI berikutnya masih harus diperiksa untuk perubahan ini dan perbaikan packagingDocker. Tidak ada pembuktian keamanan lewat serangan VPS/akun pengguna. Tinjauan sumber dibatasi pada peringatan tersebut; ini bukan audit keamanan menyeluruh.


Pemilik lane desa melakukan review sumber independen pada readerbaru: tidak menemukan blocker konkret pada batas/EOF/ENOENT/finallyclose. Ia tidak menjalankan tes atau membuat klaimSARIFclean. PengulanganCI tetap diperlukan.


## CI final3046335495

Source798a47b: empatjob sukses. Artefak selective `.runtime/ci-3046335495/summary.json` membuktikan61dunia lulus,120testcaseAPI/0failure/0error dan ketigaaudit0. PCKCI `1b65eb5c133517c6d3316a9e2e430d4d490c6db0f7ad76923c241232db0f9061`/64.491.320byte berbeda dari PCKMac1315 rilis. [SARIFfinal](overnight-final-ci-sarif-798a47b.md) diperiksa independen:201aturan,3hasil(1warning/2notes); race reader serta unusedphase hilang. Jobpublikasi khususmain tidak berjalan pada branch ini. Tidak mengklaim noltemuan.
