# Adapter pandangan kiri untuk gameplay daratan

Status 9 November 2026: kandidat runtime pada `work/06b-view-projection`, base integration `e0d75b3`, memakai kamera kiri -45/35 pada hub dan Forest serta inverse input dan arah gambar yang sesuai. Helper576/2304, controller60, native shelter336, tool480+8 dan API82 telah lulus. Full world sebelum perbaikan swing adalah44/45; satu kegagalan Ujang sudah diperbaiki dan targeted1242 lulus. Full45 gabungan, ekspor/browser kamera kiri, serta penerimaan mobile masih menunggu root. Build stabil yang sedang diuji browser tetap terpisah.

## Kontrak koordinat yang dipertahankan

Server, collision 2D, breadcrumb, portal, rumah dan jadwal memakai koordinat logis `p = (x,y)`. Renderer existing menanamkannya pada ruang Z-up dengan tinggi `h`:

```text
c = cos(55°), t = tan(55°)
M(p,h) = (x, -y/c - h*t, h)
M_inverse(X,Y,Z) = (X, -(Y + Z*t)*c)
```

`h` memakai unit tinggi renderer, yaitu `elevation * LEVEL_HEIGHT` dengan `LEVEL_HEIGHT = 48`; nilai level 1/2/3 dari SurfaceTraversal bukan langsung 1/2/3 unit pada adapter. Interpolasi tinggi konektor juga memakai unit tersebut.

Ini pemetaan affine dengan regangan kedalaman dan kompensasi tinggi. Ia bukan rotasi sederhana atau koordinat Cartesian dengan panjang satu unit sama pada semua sumbu. Mempertahankannya menjaga semua posisi server dan geometri existing. Kamera tiga perempat kiri dapat dipakai di atas embedding ini, tetapi hasilnya tidak disebut grid isometrik murni.

Kamera lama azimut 0/elevasi 35 membuat proyeksi perubahan tinggi nol dan pemetaan gerak logis ke layar identitas. Pada azimut -45, perubahan tinggi mempunyai komponen kanan/atas di layar. Follow target harus memakai tinggi lantai kontinu yang sesuai, termasuk interpolasi pada konektor, agar karakter tidak bergeser dari pusat kamera ketika menaiki teras. Memberi kamera sudut baru dengan target `map_point(center,0)` saja tidak menyelesaikan kontrak ini.

## Tiga operasi yang berbeda

`LandViewProjection.gd` sengaja tidak memakai satu nama `ground_projection` untuk semua keadaan:

- `logical_from_world` membalik embedding menggunakan tinggi Z milik titik itu sendiri. Tepat untuk titik geometris, tetapi bukan untuk telapak billboard yang diberi offset kosmetik menuju kamera.
- `logical_on_height(world_point,height)` menelusuri ray kamera ke bidang tinggi yang diketahui, lalu membalik embedding. Offset billboard delapan unit sepanjang ray tidak menjadi perpindahan kaki.
- `logical_from_screen(pixel,height)` memakai ray Camera3D melalui titik layar menuju bidang tinggi yang diketahui. Memilih lantai yang benar pada beberapa teras adalah tanggung jawab pemanggil, bukan menebak ketinggian nol.

`foot_error_pixels` membandingkan proyeksi telapak visual dan kaki logis pada tinggi lantai yang benar. Angka error layar ini berbeda satuan dari error logis lama; diagnostik tidak boleh mengganti satuan diam-diam. Subclass pembanding kamera lama memakai satu ketinggian aktor yang diketahui untuk gambar statis. Pola itu belum menjadi pemilih lantai umum untuk seluruh warga/marker.

## Gerak keyboard dan joystick

Dengan `R` dan `U` berupa basis kanan dan atas kamera sebenarnya, proyeksi vektor dunia ialah `(dot(v,R),-dot(v,U))`. Kolom Jacobian tanah pada tinggi tetap:

```text
Jx = (R.x, -U.x)
Jy = (-R.y/c, U.y/c)
Jh = (-t*R.y, t*U.y - U.z)
J_local = [Jx + Jh*dh/dx, Jy + Jh*dh/dy]
```

Determinan tanah datar adalah `sin(camera_elevation)/c`, tidak bergantung pada azimut. Pada kiri -45/elevasi 30 nilainya sekitar 0,871723. Bukti CPU terhadap empat konektor authoring pada manifest b765587 menunjukkan rentang determinan 0,790362 sampai 0,871723. Pada kiri -45/elevasi 35,264 rentangnya 0,808826 sampai 1,006579. Seluruh bidang yang diperiksa dapat dibalik. Ini bukti matematika source, belum hasil menjalankan helper GDScript.

`logical_vector_from_view` membalik matriks 2×2 itu. `input_motion` membatasi magnitudo joystick menjadi satu, mengubah arah ke koordinat logis, lalu menormalisasi dengan magnitudo analog semula. Dengan demikian batas kecepatan logis 100 serta jarak yang diperiksa server tetap. Kecepatan proyeksi di layar dapat berbeda menurut arah karena embedding anisotropik; jangan diam-diam mempercepat gerak logis untuk menyamakan jumlah piksel.

Gradient konektor berasal dari `delta_height * (end-start) / length_squared`; hanya gunakan selama berada pada konektor yang benar. Teras rata memakai nol. Tinggi kontinu mengikuti data tangga/ramp yang sudah ada, bukan perbedaan sampel yang menyeberang tebing. Inverse menolak bidang yang tepat edge-on; jangan mengarang arah jika matriks singular.

## Fase tubuh dan arah gambar

Sebelum adapter, Player dan avatar khusus Forest sama-sama memberikan `moved_velocity` logis kepada `CharacterVisual.set_locomotion`. Fungsi itu sekaligus menghitung jarak/fase, kontak suara dan arah delapan atlas. Menggantinya dengan kecepatan layar mentah akan mengubah fase berjalan.

Adapter kini memakai dua masukan: perpindahan nyata untuk fase/jarak/kontak, serta `logical_motion_to_view(actual_velocity,actual_height_velocity)` untuk arah yang terlihat. Arah layar dapat dinormalisasi ke besar kecepatan nyata sebelum diteruskan ke parameter arah terpisah; jangan menjalankan clock gait kedua. Idle mempertahankan arah layar terakhir. Interaksi, pause dan gerak tertahan tetap memakai perpindahan yang benar-benar diterima collision. Kecepatan vertikal berasal dari selisih tinggi kontinu sebelum/sesudah, bukan gerak follow kamera.

Urutan nama atlas tetap `E, SE, S, SW, W, NW, N, NE`. Tank/jala/tas memakai nama arah layar yang sama dan satu fase tubuh. `CharacterEquipment3D` sudah mengambil basis Camera3D sebenarnya; layout tangan/depan/belakang tetap perlu dinilai pada semua arah. NPC empat arah serta tujuan kerja juga memerlukan arah pandang terhadap lokasi alat, terpisah dari jadwal logisnya.

## Kontrak penghubung kandidat

| Lokasi | Perubahan yang diperlukan sebelum aktivasi |
| --- | --- |
| LandWorld3D | Pose kiri; follow tinggi kontinu; adapter dikonfigurasi setelah pose/viewport final; camera_right/up/forward dari Camera3D sebenarnya. Inisialisasi sebelum physics pertama. |
| Player dan Forest | Keyboard/joystick melewati inverse yang sama, termasuk gradient konektor; collision, breadcrumb dan posisi server tetap logis. |
| CharacterVisual | Masukan arah visual terpisah dari jarak gait; delapan arah serta idle tidak terganti clock baru. |
| LandActors3D | Offset pusat/pivot memakai basis kamera; error telapak memakai ray ke tinggi tiap aktor atau error piksel dengan label satuan baru. |
| CanopyReadability3D | `relative.x` menjadi `dot(relative,camera_right)`; masker dan tes alpha tetap pada ruang billboard, kedalaman memakai forward sebenarnya. |
| Mesh daun/papan billboard | Offset horizontal yang masih `Vector3(relative.x,0,0)` harus memakai right kamera; geometri bangunan/terrain statis tetap dalam sumbu dunia. |
| VillageActivity3D | Offset tangan/alat yang masih world-X perlu dipetakan melalui right; titik kerja/floor tetap logis. |
| Main/Forest tracking UI | Posisi dunia diproyeksikan ke rect TextureRect/SubViewport sebenarnya; safe area dan CanvasLayer tetap dibedakan. Interaksi terdekat tetap menghitung jarak logis. |
| Efek 2D pemain | Wet marks/gelembung/lingkaran aksi yang digambar pada Canvas dunia lama perlu diproyeksikan atau dipindahkan ke renderer yang sesuai, tanpa muncul dobel. |
| Mini-map dan buku peta | Peta tetap north-up bila itu kontraknya; heading marker jangan mengambil arah layar untuk peta logis tanpa konversi. |
| Laut dan interior | Tidak diaktifkan otomatis. Reticle laut, proyeksi kedalaman, arus/parallax dan interior punya kontrak masing-masing yang harus diuji. |

Helper menyediakan konversi render-pixel ke rect host dan kebalikannya. Pemanggil menyerahkan rect display sebenarnya; adapter tidak menganggap seluruh jendela browser atau navbar adalah area game. Tidak ada renderer kedua, dependency baru, request jaringan, perubahan save, ataupun shader fullscreen.

Kontrak kamera helper ialah orthographic `KEEP_HEIGHT` seperti LandWorld3D existing, dengan basis orthonormal dan Z-up. `view_height` adalah ukuran vertikal kamera sebenarnya. Helper ini bukan inverse kamera perspektif atau kamera yang mewarisi scale/shear dari parent.

## Pengujian dan penerimaan tersisa

`scripts/tests/land-view-projection.gd` membandingkan helper langsung dengan Camera3D serta `LandWorld3D.map_point`: embedding/ray, offset telapak, host rect, arah joystick/keyboard, magnitudo analog, kemiringan konektor dan parity kamera lama. Pengujian Godot 4.7.2 headless lulus 576 sampel embedding/ray/kaki/host dan 2.304 sampel input/gradient pada tiga resolusi, empat sudut kamera dan kondisi pixel snap aktif/nonaktif. Log akhir `.runtime/view-projection-test.log` tidak memuat SCRIPT ERROR, Parse Error atau ERROR. Nama konstanta fixture awal `Projection` berbenturan dengan tipe bawaan Godot; diganti `ViewAdapter`, lalu tipe Vector2 input dinyatakan eksplisit sebelum pengujian akhir lulus. UID helper hasil impor dicatat bersama source. Tidak ada full-world/export atau aktivasi kamera global pada tahap ini.

Model referensi analitis CPU juga memeriksa 640 kasus arah/magnitudo pada tanah rata dan empat gradient konektor manifest: delapan arah, empat besar input dan empat pasangan azimut/elevasi. Arah layar serta batas magnitudo logis konsisten. Model ini tidak menjalankan GDScript dan tidak menggantikan regression Camera3D tersebut.

Kandidat terpisah memasang integrasi berikut; penerimaan browser penuh tetap diperlukan: Nala delapan arah, Forest, tangga/jembatan, marker, masker tajuk, alat modular, HUD 667/844/390, pause, save/reload dan migrasi lama. Satu preset kiri tidak otomatis menjadi fitur rotasi kamera bebas. Seluruh layanan desa, kalender 36 menit dan ekonomi tetap memakai kontrak server yang sudah ada. Perluasan rumah/warga dan dekorasi menunggu inti tersebut.

Coverage hujan diuji ulang dengan basis billboard kamera kiri, termasuk kepala warga di ujung serambi; bukaan atap visual tidak membuktikan tubuh berada di bawah roof plan. Batas follow kamera juga perlu ditinjau: rect limit Camera2D pada koordinat logis lama bukan rect batas layar setelah rotasi. Tinggi follow ketika kamera terjepit batas tidak boleh diambil dari lantai lain tanpa aturan yang jelas.

Pemeriksaan dokumen: Hard Gate PASS, hasil matematis dan runtime yang belum dijalankan dibedakan; Purpose Gate PASS, tiap helper dikaitkan ke koordinat/input/keterbacaan; Liveliness PASS untuk dokumen teknis, arah comfy dan kamera kiri berasal dari brief pengguna; Craftsmanship PASS untuk rancangan/source yang diperiksa, gate runtime dan gameplay global masih terbuka.

## Kandidat runtime kiri (integrasi e0d75b3)

Source kandidat kini menghubungkan kamera -45/35 pada LandWorld3D, callback input Player, inverse Forest, arah visual CharacterVisual terpisah dari jarak gait, ray kaki per aktor, basis tajuk aktual, dan proyeksi dampak hujan. Basis kamera dipasang sebelum konstruksi billboard. Follow target menggunakan posisi aktor beserta tinggi lantai kontinu; batas Camera2D lama tidak dipakai untuk menjepit kamera 3D ke lantai lain. Laut HybridOcean dan interior tetap memakai renderer/input sendiri. Quad air jauh memakai material air yang sama dan hanya menambah dua triangle di bawah mesh dekat; resolusi tessellation dekat tidak berubah. Wet marks darat memakai pool24 pada bidang lantai 3D, dan gambar Canvas lama dihentikan saat renderer daratan aktif.

Status bagian ini adalah implementasi kandidat, belum penerimaan global. Regresi runtime Player dan Forest baru akan menggerakkan controller sebenarnya dengan input analog/keyboard, membandingkan arah proyeksi dengan permintaan layar, memeriksa jarak gait dan pause, serta memakai gradient konektor yang benar. Tes lama yang memaksa proyeksi identitas pada semua tinggi diubah menjadi inverse ray Camera3D pada tinggi lantai masing-masing; ini perubahan kontrak yang disengaja, bukan melonggarkan batas error kaki.

Harness browser harus mempertahankan waypoint dalam koordinat logis. `scripts/land-view-navigation.mjs` membaca kontrak `land.view.motion` dari renderer pada snapshot terbaru. Delapan kombinasi tombol dievaluasi melalui inverse matriks itu untuk memilih arah logis paling sesuai; pulse dibatasi untuk mengurangi simpangan lateral dan dilepas sampai controller berhenti. Empat tes Node lulus untuk parity legacy, pilihan tombol kiri, batas prediksi drift serta penolakan matriks hilang/singular. Prediksi pulse ini bukan bukti collision atau rute browser. Gang sempit memerlukan pembacaan ulang posisi, titik belok presisi dan kombinasi pulse; satu pemetaan tombol tetap tidak dapat mengikuti setiap sumbu logis secara tepat. Alternatif input analog harus melalui joystick layar sungguhan, bukan mengubah velocity atau posisi lewat diagnostik.

Ownership kandidat: LandWorld3D, LandActors3D, CanopyReadability3D, Player, Forest, CharacterVisual, EnvironmentEffects dan backing LandWater3D. Main hanya dua callback input/arah; perbaikan jaringan Main dimiliki root pada hunk terpisah. VillageActivity3D, HubActor dan NpcBodyRig menunggu handoff perubahan karakter yang sedang diuji. Metadata stasiun hujan hanya akan digeser bila sampel tubuh di bawah bidang atap fisik gagal pada kamera kiri; atap tidak diperbesar untuk menyembunyikan kegagalan. Snapshot menyebut azimut, elevasi, kontrak input dan gradient aktual secara eksplisit. Build/PCK kandidat stabil yang sedang diuji browser tidak diganti oleh branch ini.

### Checkpoint pengujian kandidat runtime

Impor Godot4.7.2 tidak memuat error. Helper diulang dan lulus576/2304. `land-left-gameplay.gd` lulus60 pemeriksaan melalui controller Player dan Forest yang sebenarnya:16 input analog,4 keyboard,32 gradient konektor,8 arah Forest; jarak fase memakai perpindahan collision dan pause tidak menambah fase. `land-renderer.gd` lulus16 ray kaki pada empat tinggi serta batas batch/viewport, geometri jembatan, lampu, dan transisi selam. Parse awal fixture renderer membutuhkan tipe Vector3 eksplisit pada `floor_point`; sesudah diperbaiki tes lulus.

Regresi native shelter membuktikan sumbu Griya/dek tetap sejajar, kemudian dengan benar menolak kepala Ujang di anchor1430,1260 karena melampaui sisi booth pada kamera kiri. Anchor digeser6px ke1424,1260. Analisis bidang atap juga menemukan Darmi di1375,300 terlalu dekat tepi kanan; kandidat1365,280 (jarak dari Sari tetap lebih dari60px) tetap pada lantai dan tersambung lewat jalur existing. Kedua metadata dan titik akhir rute disamakan; tidak ada atap/lantai/post baru. Full API82/82 lulus setelah perubahan, termasuk coverage kepala/torso/kaki pada az0/-45, konektivitas semua stasiun dan portal,49 kandidat posisi lama,14 migrasi API lengkap dan5 posisi lama dek tetap. Native336 sampel setelah pergeseran kemudian lulus pada kamera kiri; log akhir shelter tidak memuat error.

Perubahan tool0517cef/8403665 telah digabung sebelum offsets kanan kamera diganti. Pemilihan arah lewat Camera3D yang sudah ada diperluas ke Darmi/Sari tanpa mengubah anatomi, footplant, anotasi grip atau toleransi. Tes tool menambah8 arah layar dari proyeksi nyata. Bagian fixture inspeksi authored rear Ujang kini secara eksplisit memakai kamera pembanding az0 dan mengembalikan kamera gameplay sesudahnya; arah logis north tidak berarti screen north pada kamera kiri. Tes rute/turn sebenarnya tetap memakai kamera0/-45. Perbaikan state ekstraksi roota1add52 juga tergabung pada hunk Main terpisah; dua callback view tidak mengubah perbaikan jaringan itu.


### Hasil akhir lane, batas penerimaan

Semua regresi pada runner kecuali satu Ujang lulus pada pemindaian penuh45, dan log Ujang mengisolasi fase swing pertama di910.4,1360: pelvis9.0749 melewati batas8. Kandidat karakterd3bbc19 memperbaiki konsumsi overshoot batas stance→swing; startup/turn, panjang limb dan toleransi tidak diubah. Sesudah digabung, targeted1242 lulus dengan168 sampel turn0/-45, drift sole0.000349, kneejoin0.000273, pelvis maksimum6.988868 dan26gripwest maksimum0.015357. Full45 berikutnya menunggu root sesudah penggabungan; laporan runner44/45 sebelum fix tidak diganti seolah-olah sudah merupakan run45/45.

Sembilan nativeframe ditulis dengan log akhir bersih. Root dan karakter memeriksa Griya siang/malam, sumbu rumah/dek, serta tiga worker. Garis pancing dan pelampung berada pada sisi kiri yang sama dan endpoint di WaterField basah; Darmi menghadap tanah setelah kembali dari commute; Sari beserta tangan/frame terlihat. Ini pemeriksaan komponen diam, bukan bukti empat artwork berbeda atau kualitas gait. Headtop Ujang/Sari sedikit terpotong pada fixturezoom3.

Audit tambahan mendapati dua frameForest menggunakan actorreviewSari yang belum direset sebelum `set_area`, sehingga `actors.player=0`: geometri benar tetapi belum dapat diterima sebagai bukti Nala terlihat. Sourcefixture sekarang mereset actor sebelum rebuild, mewajibkan `actors.player==1` dan memakai zoom2.4 untuk worker; perubahan fixture terakhir ini belum dirender ulang karena slot diberikan kepada browser. FrameForest sebelumnya hanya bukti geometri. ControllerForest nyata sudah lulus60 arah/input/gait bersama Player; dua bukti tersebut tidak dicampur.

Tidak ada proses engine/browser yang tersisa dari lane ini. Tidak ada benchmark Windows/SamsungS23, eksporPCK kiri, penerimaan touchbrowser, kamera bebas atau klaim semua stair telah dilalui. Jalur Ujang mencakup rampdock; central/westernfour-tread dan ridge3-tread belum tercakup ruteUjang. Native9 bukan screenshotgame lengkap denganHUD; penerimaan overlay/HUD dan rute pengguna pada kamera baru tetap tugas integrasi berikutnya.
