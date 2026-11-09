# Rumah, terrain, sambungan area dan warna

9 November 2026. Integrasi berada pada worktree `Jalasmara-06-buildings-gates`, branch `work/06b-buildings-gates`. Ini kandidat lokal, belum ekspor atau rilis baru. Staging tetap sourcef4fac83/PCK43df70. Permintaan pengguna terbaru mencakup rumah/gapura, tebing dan pulau yang terlalu kotak, pijakan tangga, hutan yang harus tampak dari desa, serta warna cerah seperti artwork login/loading.

## Perubahan aktual

- Tujuh rumah memakai rectangle fisik yang mempertahankan luas/rasio dan identitas; Griya tetap. Hub layout10 dan forest6 mempunyai gapura berbasis jalan fisik, collider tiang dan migrasi posisi lama.
- `LandAreaSeam3D` memotong geometri permukaan map tetangga dan memindahkannya melalui basis portal bersama. Bahu tanah tidak simetris dan jalan menyatu pada bidang portal; pohon hutan asli dalam jendela preview ikut terlihat dari hub. Preview dibatasi860unit/12pohon, visual saja. Loading/interaksi dan lantai server tidak diperluas. Trail dekoratif lama yang bergeser37px hanya dipertahankan untuk fixture layout lama tanpa metadata.
- NaturalTerrainEdges mengganti kulit tebing batu datar dengan cincin kontur yang menyambung, lapisan tanah, shoulder berfaset dan toe ke lantai bawah. Kayu tetap lurus. Hook integrator sudah terpasang; tidak ada perubahan rute, lantai atau collision untuk terrain kosmetik.
- Palet dasar tanah/kayu/rumput lebih cerah. Kontras microtexture dikurangi menjadi10%, atlas12%; butiran acak lebih besar dan lebih halus. Ambient siang lebih sejuk, matahari tetap hangat. Grade vibrance terbatas10% sebelum strength0,6. Resolusi/budget piksel tetap; source artwork karakter dan dedaunan belum digambar ulang.
- Helper tangga menghilangkan overlap XY antartread akibat embedding ketinggian lama. Support memakai XY kontinu dan Z tread aktual; sampling ramp tetap kontinu. Root sprite/shadow/NPC mengonsumsi support yang sama. Hook proyeksi/input/follow baru masih menunggu regresi gabungan dan sequence gerak. Ini belum membuktikan pose dua kaki Nala natural.

## Pemeriksaan yang sudah selesai

Typecheck dan94/94tes API lulus pada metadataeb58f3c. Termasuk416posisi lama rumah, kasus API save/move/reload,10posisi lama tiang forest dan penolakan stale/blocked; ekonomi/inventori/progres tidak diubah. Tes harness canopy/consumer/sanitizer12/12 lulus. Source QA gateway025ca5f menambah mode gerak fisik untuk crossing/postcollision/travel/ACK/reload, belum dijalankan di browser kandidat.

Pemeriksaan Godot gapura/seam186assertion lulus pada source integrasi sebelum hook tangga. Helper natural terrain juga lulus actualrenderer:7surface,493node,472cutout dan316support checks. Log `.runtime/06b2-gateway-seam.log` dan `06b2-natural.log`.

Native rumah sebelum warna dan sesudah warna masing-masing28frame lulus (7rumah, layout9/10, siang/malam). Root meninjau Kedai siang sebelum/sesudah dan malam: noise atap/kayu turun dan warna menjadi lebih cerah, lampu malam tetap hangat. Artifact `artifacts/godot/06b2-before-color-houses-complete/` dan `06b2-after-color-houses/`. Belum merupakan gerak browser, semua material/artwork atau perangkat fisik. Enam frame gapura/seam sebelum warna juga selesai; hub/forest approach ditinjau.

Kegagalan iterasi disimpan: fresh import sempat kekurangan fontdata sebelum importer selesai; import kedua bersih. Type inference `GatewayArchitecture3D.x`, `LandAreaSeam3D.height/at`, dan fixture `id` diperbaiki. Native rumah sempat menunggu `frame_post_draw` ketika window tidak menggambar; proses milik paket dihentikan, fixture memakai `RenderingServer.force_draw`, lalu28frame selesai. Fixture natural pertama gagal indent pada perubahan force_draw integrator; diperbaiki sebelum rerun. Tidak ada hasil gagal tersebut yang dihitung sebagai penerimaan.

## Masih terbuka dan urutan berikutnya

1. Regresi dunia gabungan, actual triangle/ray dan sequence naik/turun; native natural18frame serta preview/gapura warna final. Semua slot engine/browser serial.
2. Ekspor kandidat yang diterima lalu browser gateway/canopy dengan pin PCK baru: gerak aktual, postcollision, portal, saveACK/reload dan pause/touch. Kandidat belum tampil di staging.
3. Hardening loader body-stream8833185 dan raw-WASM rejection sedang dikerjakan lane website; masalah HTTP2 publik tetap terbuka. Tidak mengubah shared proxy atau mengklaim penyebab transport sudah ditemukan.
4. Restart artwork/gait Nala, empat arah penuh warga dan Saras grayquad tetap terbuka. Dukungan tread bukan bukti pose kaki lengkap. Variasi buku/kuis/dialog, HUD malam pada kandidat terbaru dan FPS Windows/S23 fisik belum dinyatakan selesai.
5. Rumah pribadi lurah, direktur terpisah di RV/container, Laskar Kognisi serta perluasan farming/keramba tetap antre setelah core. FishGen tersimpan sebagai referensi, belum dijalankan.

Tool aktual: Godot4.7.2 Compatibility/native/headless, Node/TypeScript, Git/worktree dan pembacaan screenshot lokal. Tidak ada generasi gambar, aset berbayar, runtime Three.js atau fullengine Noxe baru. Kode geometri/shader baru original proyek; material/art library dan seluruh notice upstream dipertahankan. Port Noxe tetap terbatas helper kamera.

## Checkpoint integrasi berikutnya

Pelataran atas/bawah kini rumput dengan37potongan jalur tanah72unit yang dipotong pada lantai aslinya dan dikurangi footprint batu/kayu/tangga/kebun. Batas lantai, route, obstacle dan collision tetap. Native28frame rumah final selesai; root meninjau Kedai siang dengan rumput/jalan, batu berfaset dan shadow yang bersih. Artifact `06b2-final-grass-houses/`.

Normal vertex tanah ternyata menghadap bawah sementara fragment shader memaksanya ke atas. Empat varian native bias/.035/.15/.40/shadows-off menunjukkan kenaikan bias tidak menghapus garis diagonal. Menyamakan normal vertex dengan normal shader menghapusnya tanpa mematikan castshadow; artifact `06b2-shadow-review/` versus `06b2-shadow-normals/`. Regresi mengukur9.642normal vertex dari top tanah map sebenarnya, bukan sisi bawah kotak. Klasifikasi awal tes sempat memasukkan underside garden box dan gagal, lalu diperbaiki dengan centroid pada polygon/elevasi surface yang benar; batas normal tidak dilonggarkan.

Iterasi terrain lebar2a343f8 lulus focused485node aktif/480cutout/237support dan18nativeframe. Root meninjau centralstep: dinding tipis kini bidang batu berfaset yang lebih lebar dan bertumpu. Seam mendapat kulit sisi/root yang sama; permukaan remote di bawah datum portal tidak dirender agar tidak tampak tenggelam di sungai. Pos kontainer pada ridge ikut tampak dari sisi forest. Enam native gapura finalrooted selesai. Artifact `06b2-natural-wide-normals/`, `06b2-gateways-rooted/`.

Nativeclean hybrid8kasus/99frame tangga selesai dan satuNala dikonfirmasi. Rawgait dan per-leg stair sync tetap batas terbuka. Fixture berikut mengatur immediatefollow hanya ketika berpindah kasus supaya frame awal tidak terpotong, lalu memakai follow biasa saat berjalan.

Typecheck dan100/100API final lulus;40tes harness lulus. Fullworld terakhir49/50lulus: actualtread868, normal9.642, camera/input2.304 dan controller60 lulus. Pemeriksaan terakhir Ujang menemukan8kontak ramp melewati batas pelvis8 (maksimum sekitar8,39) sesudah perubahan supporthook. Ini blocker rilis, bukan diabaikan sebagai toleransi. Lane character menerima slot engine untuk memperbaiki regression tersebut; root belum ekspor/rilis.

Kegagalan minimap pada fullsuite awal berasal dari triangle jalur sah di dunia tetapi luas hanya0,0001879pixel² setelah proyeksi minimap. GeoMap mengabaikan fill di bawah0,25pixel² sebelum triangulasi canvas; polygon dunia37potongan dipertahankan. GeoMap141pemeriksaan berikutnya lulus. Kegagalan API99/100 sebelumnya hanya snapshot material dua pelataran yang memang diminta berubah; expectedmaterial duaID tersebut diperbarui, seluruh polygon/elevasi/connector tetap dibandingkan persis. Rerun100/100lulus.

Hardening loader body-stream dan WASM/init rejection sudah digabung718ea09/138bca4. Root mengulang22tes loading bridge/preloader/init sebagai bagian40harness. Error/retry browser dan defaultpublicHTTP2 tetap belum diterima; perubahan ini tidak diklaim memperbaiki transfer lambat.

**Fullsuite berikutnya selesai:** fixbe114db mengembalikan inverse lateral pinggul ke bidang horizontal, sementara sole/body tetap memakai support tread. Ujang1.242kontak lulus, pelvis maksimum6,988868<8, drift0,000349; tidak mengubah panjang kaki atau batas tes. Root mengulang seluruh50/50pemeriksaan dunia, sepuluh spesies/722frame, tanpa SCRIPT ERROR/ERROR. Log `.runtime/06b2-world-accepted.log`, JSON `.runtime/world-check/world-checks.json`. Ekspor/build sedang tahap berikutnya; browser dan staging belum diklaim.

**Ekspor kandidat selesai:** `npm run build` lulus termasuk dua tahap import, Web export, patch body/WASM/init, Vite dan API. PCK`5f5baf243a3bf941cf34fab6c143bb9cf2bc8d65997ded6ed4e048b929353f96`,64.333.184byte. Log `.runtime/06b2-build.log`. Native final tangga mengulang8kasus/99frame dengan hybrid tunggal dan immediatefollow saat awal tiap kasus; `.runtime/06b2-native-stair-final.log`, artifact `06b2-final-stair-sequence/`. Preview3101 sudah dibangun/restart dari worktree kandidat; server lama71487 milik root dihentikan setelah cwd/command diverifikasi. Server baru sesi54712 sehat. Slot engine diserahkan ke website untuk browser gateway/canopy/faultloader; root mengerjakan source/report/CI saja. Belum staging baru.
