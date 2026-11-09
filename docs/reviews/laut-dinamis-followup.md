# Tindak lanjut laut dinamis

Cabang kerja: `work/laut-dinamis`, baseline `3d648e8`. Pekerjaan berada pada worktree laut tersendiri; HUD, daratan, akun, ekonomi dan progres tidak disentuh.

## Audit

Renderer hybrid sudah mempunyai batu karang3D, sambungan geologi belakang yang tertambat,48 kartu latar tiga lapisan dengan parallax X/Y, pembatasan latar di bawah permukaan, pencahayaan kedalaman, lampu selam, berkas cahaya yang dipotong kontur, caustics dan wake. Implementasi tersebut dipertahankan. Air pesisir/sungai dan buihnya telah dikerjakan pada handoff sebelumnya; tidak dibuat ulang atau dipindahkan menjadi efek ombak di dasar laut.

Kekurangan yang ditangani adalah jalur partikel pada `LivingWater.gd`: arus sebelumnya satu vektor global; wake dapat terdorong ke dalam batu; partikel diperiksa sebelum transformasi parallax sehingga posisi tampaknya masih dapat menimpa siluet karang; profil grafis hemat belum menurunkan anggaran partikel bawah air.

## Perubahan

`OceanCurrentField.gd` membangun indeks spasial dari tepi `terrainContours` satu kali setiap kontur berubah. Di dalam radius110satuan dari karang, arus visual yang menuju batu dibelokkan menuju garis singgung tepinya. Aliran yang menjauhi batu tetap mengikuti arah lingkungan. Kecepatannya dibatasi24satuan/detik dan tidak memperoleh dorongan tambahan saat membelok. Ini pendekatan visual2D, bukan solver fluida3D.

Partikel mempertahankan posisi antar-sampel dan bergerak mengikuti field tersebut. Segmen geraknya serta ujung wake dipotong pada kontur asli. Posisi setelah parallax juga diperiksa agar efek tidak digambar di atas batu. Origin wake yang tertutup batu dibuang. Tidak ada penambahan collider, gaya pada Nala, perubahan oksigen atau pemberian hadiah.

Profil balanced mempertahankan batas48motes/18wake/3shaft. Profil low menurunkannya menjadi16/8/2; reduced-motion juga membatasi motes16 dan menekan wake baru. Clock pause untuk membaca/menu membekukan waktu adveksi kosmetik; timer penyelaman server tidak disentuh. Efek dibersihkan ketika penyelaman tidak aktif. Tetap menggunakan gambar native2D terbatas di atas renderer hybrid; tidak memakai `CPUParticles3D` yang sebelumnya bermasalah pada WebGL.

## Verifikasi

Perintah terfokus setelah impor resource Godot:

```sh
GODOT --headless --path client-godot --script ../scripts/tests/ocean-current.gd
GODOT --headless --path client-godot --script ../scripts/tests/living-water.gd
GODOT --path client-godot --rendering-method gl_compatibility --script ../scripts/tests/ocean-current-render.gd
```

Tes pertama memeriksa pembelokan nyata di dinding, tidak ada percepatan, segmen besar berhenti sebelum batu,600 langkah adveksi aman, pemeriksaan parallax, anggaran low, pause, cleanup, serta data permainan tetap sama. Tes native memakai scene hybrid sebenarnya di reef, lorong dan kedalaman; hasil lokal berada di `artifacts/godot/ocean-current/` dan tidak dikemas ke game.

Hasil9November2026: empat pemeriksaan headless lulus tanpa script error: `ocean-current.gd`, regresi `living-water.gd`, `ocean-geology.gd` (10sambungan batu tertambat), dan `ocean-backdrop.gd` (tiga jarak atmosfer serta parallax X/Y aktual). Render native Compatibility pada AppleM2 lulus tanpa error shader. Keluaran yang diperiksa: `reef-159.png`, `passage-159.png`, dan `deep-159.png`.

Dalam selang simulasi6,95detik, seluruh partikel yang tetap terlacak berpindah: reef31/31, passage28/28, deep29/29. Pada frame akhir masing-masing1/4/6partikel membaca arah arus yang dibelokkan oleh karang. Adegan mempertahankan3lapisan atmosfer; shaft serta caustics berkurang menurut kedalaman seperti sebelumnya. Angka ini berasal dari posisi partikel sebelum/sesudah pada renderer aktif, bukan sekadar keberadaan node/debug flag. Screenshot tetap harus dibaca sebagai pemolesan efek halus; perubahan bukan rekonstruksi visual seluruh laut.

Cache aktual memuat159tepi dan488bucket pada fixture peta ini. Pengukuran tersebut membuktikan struktur indeks dibangun, bukan klaim FPS/performa perangkat seluler. Impor pertama pada worktree baru sempat menemukan cache font yang belum ada sebelum reimport menyelesaikannya; keempat pemeriksaan runtime dan render sesudah impor tidak menghasilkan error tersebut.

## Batas

Perubahan ini memoles arah dan penutupan efek kecil; tidak mengubah komposisi besar terrain, menambah seluruh biome, atau memperbarui aset batu. Field bergerak pada proyeksi kontur2D dan tidak mensimulasikan turbulensi volumetrik, buoyancy, tekanan air ataupun gaya gameplay. Kedalaman cahaya/parallax tetap memakai implementasi yang sudah ada. Anggaran tetap dan indeks spasial membatasi pekerjaan, tetapi angka FPS perangkat nyata belum diukur oleh cabang ini. Browser dan perangkat nyata tetap memerlukan verifikasi integrator setelah perubahan digabungkan.
